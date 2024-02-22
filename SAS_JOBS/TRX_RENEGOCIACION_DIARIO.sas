/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	TRX_RENEGOCIACION_DIARIO	================================*/
/* CONTROL DE VERSIONES
/* 2023-05-05 -- v04 -- David V.    -- Se quitan "control de errores" antiguo. 
/* 2022-10-28 -- v03 -- Sergio J.	-- New delete and export code to aws
/* 2022-10-07 -- V02 -- Sergio J.	-- Se agregan exportación a raw
/* 2021-01-15 -- V01 -- David V. --  
					-- Versión Original + Comentarios y correo notificación
/* INFORMACIÓN:
	Descripción pendiente

	(IN) Tablas requeridas o conexiones a BD:
	- XX

	(OUT) Tablas de Salida o resultado:
	- PUBLICIN.TRX_RENE_&fechax

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria=RESULT;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/

%LET NOMBRE_PROCESO = 'TRX_RENEGOCIACION_DIARIO';

LIBNAME replica ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='SAS_USR_BI' PASSWORD='SAS_23072020';


DATA _null_;

datei = input(put(intnx('month',today(),0,'begin'),yymmdd10. ),$10.);
datef = input(put(intnx('month',today(),0,'end'),yymmdd10. ),$10.);
datex = input(put(intnx('month',today(),0,'end'),yymmn6.),$10.);
Call symput("fechai", datei);
Call symput("fechaf", datef);
Call symput("fechax", datex);
RUN;
%put &fechai;
%put &fechaf;
%put &fechax;

PROC SQL;
   CREATE TABLE REF_ITF_PRUEBA AS 
   SELECT t1.CENTALTA, 
          t1.CUENTA, 
          t1.CODTIPC, 
          t1.LINEA, 
          t1.FECFAC,
          t1.ESTCOMPRA,
          t1.SUCURSAL,
		  t1.TIPOFAC,  
          t2.TOTCUOTAS, 
          t2.PORINT AS TASA, 
          t1.IMPFAC LABEL="CAPITAL" AS CAPITAL, 
          t2.IMPCUOTA LABEL="CUOTA" AS CUOTA, 
          t2.IMPINTTOTAL LABEL="INTERES" AS INTERES, 
          t2.IMPIMPTOTOT LABEL="IMPUESTO" AS IMPUESTO
      FROM REPLICA.MPDT205 AS t1, REPLICA.MPDT206 AS t2
      WHERE (t1.CODENT = t2.CODENT AND t1.CENTALTA = t2.CENTALTA AND 
			t1.CUENTA = t2.CUENTA AND t1.CLAMON = t2.CLAMON AND
            t1.CODTIPC = t2.CODTIPC AND t1.NUMOPECUO = t2.NUMOPECUO) AND 
			(t1.LINEA = '0057' /* AND t1.ORIGENOPE = 'CCUO'*/ AND 
			t1.FECFAC >= "&fechai" AND t1.FECFAC <= "&fechaf");
QUIT;


PROC SQL;
   CREATE TABLE REF_ITF_PRUEBA1 AS 
   SELECT A.*,
          B.DESTIPC
      FROM WORK.REF_ITF_PRUEBA AS A
      INNER JOIN REPLICA.MPDT737 AS B ON (A.CODTIPC = B.CODTIPC)
        WHERE A.CODTIPC = '0070';/*AL DIA*//*0070*/
QUIT;


PROC SQL;
   CREATE TABLE REF_ITF_PRUEBA2 AS 
   SELECT A.*,
          B.IDENTCLI,
            INPUT(B.IDENTCLI,BEST32.) AS IDE,
            input(cat((SUBSTR(A.FECFAC,1,4)),(SUBSTR(A.FECFAC,6,2)),(SUBSTR(A.FECFAC,9,2))) ,BEST10.) AS FECHA_TRUNC
      FROM WORK.REF_ITF_PRUEBA1 AS A
      INNER JOIN REPLICA.MPDT007 AS B
      ON (A.CENTALTA = B.CENTALTA AND A.CUENTA = B.CUENTA)
;QUIT;


LIBNAME R_bopers ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM'  USER='SAS_USR_BI' PASSWORD='SAS_23072020';


PROC SQL;
   CREATE TABLE REF_ITF_PRUEBA3 AS 
   SELECT t1.CENTALTA, 
          t1.CUENTA, 
          t1.CODTIPC, 
          t1.LINEA, 
          t1.FECFAC,
		  t1.ESTCOMPRA,
          t1.FECHA_TRUNC,
          (MDY(INPUT(SUBSTR(PUT(t1.FECHA_TRUNC,BEST8.),5,2),BEST4.),
          INPUT(SUBSTR(PUT(t1.FECHA_TRUNC,BEST8.),7,2),BEST4.),
          INPUT(SUBSTR(PUT(t1.FECHA_TRUNC,BEST8.),1,4),BEST4.)) ) FORMAT=DDMMYY10. AS FECHA_OK,
          t1.TOTCUOTAS, 
          t1.TASA, 
          t1.CAPITAL, 
          t1.CUOTA, 
          t1.INTERES, 
          t1.IMPUESTO, 
          t1.SUCURSAL,
		  t1.TIPOFAC,
          SUBSTR(t1.SUCURSAL, 1, 4 )AS SUCURSALES, 
          t1.DESTIPC, 
          t1.IDENTCLI, 
          t1.IDE, 
          t2.PEMID_GLS_NRO_DCT_IDE_K AS RUT, 
          t2.PEMID_DVR_NRO_DCT_IDE AS DV
      FROM WORK.REF_ITF_PRUEBA2 AS t1 INNER JOIN R_bopers.BOPERS_MAE_IDE AS t2 ON (t1.IDE = t2.PEMID_NRO_INN_IDE);
QUIT;


PROC SQL;
   CREATE TABLE REF_ITF_PRUEBA4 AS 
   SELECT t1.CENTALTA, 
          t1.CUENTA, 
          t1.CODTIPC, 
          t1.LINEA, 
          t1.FECFAC,
          t1.ESTCOMPRA, 
          t1.FECHA_TRUNC, 
          t1.FECHA_OK, 
          t1.TOTCUOTAS, 
          t1.TASA, 
          t1.CAPITAL, 
          t1.CUOTA, 
          t1.INTERES, 
          t1.IMPUESTO, 
          t1.SUCURSAL,
          t1.TIPOFAC, 
          t1.SUCURSALES, 
          t1.DESTIPC, 
          t1.IDENTCLI, 
          t1.IDE, 
          t1.RUT, 
          t1.DV
      FROM WORK.REF_ITF_PRUEBA3 AS t1
      WHERE t1.FECFAC BETWEEN "&fechai" AND "&fechaf";
QUIT;


PROC SQL NOPRINT;
  /* CREATE TABLE WORK.QUERY_FOR_REF_ITF_PRUEBA4 AS */
   SELECT /* MIN_of_FECFAC */
            (MIN(t1.FECFAC)) AS MIN_of_FECFAC, 
          /* MAX_of_FECFAC */
            (MAX(t1.FECFAC)) AS MAX_of_FECFAC
      FROM WORK.REF_ITF_PRUEBA4 t1;
QUIT;


PROC SQL NOPRINT;
  /* CREATE TABLE WORK.QUERY_FOR_REF_ITF_PRUEBA4 AS */
   SELECT /* MIN_of_FECFAC */
            (MIN(t1.FECFAC)) AS MIN_of_FECFAC, 
          /* MAX_of_FECFAC */
            (MAX(t1.FECFAC)) AS MAX_of_FECFAC
      FROM REF_ITF_PRUEBA4 t1;
QUIT;


PROC SQL;
 CREATE TABLE PUBLICIN.TRX_RENE_&fechax as
   SELECT t1.CENTALTA, 
          t1.CUENTA, 
          t1.FECFAC,
          t1.ESTCOMPRA, 
          t1.FECHA_TRUNC, 
          t1.TOTCUOTAS, 
          t1.TASA FORMAT=COMMAX3.2, 
          t1.CAPITAL FORMAT=BEST32., 
          t1.CUOTA FORMAT=BEST32., 
          t1.INTERES FORMAT=BEST32., 
          t1.IMPUESTO FORMAT=BEST32.,
		  t1.TIPOFAC,
          /*t1.SUCURSALES,*/
          INPUT(t1.SUCURSALES,BEST.)AS SUCURSAL,  
          t1.DESTIPC, 
		  input(t1.RUT, best.) AS RUT
      FROM REF_ITF_PRUEBA4 AS t1 
	  ORDER BY t1.FECFAC DESCENDING;
QUIT;


%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_ppff_trx_rene,raw,sasdata,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_ppff_trx_rene,publicin.trx_rene_&fechax,raw,sasdata,0);


PROC SQL NOPRINT;
   /*CREATE TABLE WORK.QUERY_FOR_TRX_REF_20 AS*/ 
   SELECT /* COUNT_of_RUT */
            (COUNT(t1.RUT)) AS COUNT_of_RUT, 
          /* SUM_of_CAPITAL */
            (SUM(t1.CAPITAL)) FORMAT=BEST32. AS SUM_of_CAPITAL
      FROM PUBLICIN.TRX_REF_&fechax t1;
QUIT;


/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*=========================================================================================*/
/*=======================       FECHA PROCESO Y ENVÍO DE EMAIL      =======================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*preparacion envio correo*/
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_PPFF';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_1';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_2';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;	
%put &=DEST_6;


/*envio correo y adjunto archivo*/
data _null_;
FILENAME OUTBOX EMAIL
FROM	= ("&EDP_BI")
TO 		= ("&DEST_4","&DEST_5","&DEST_6")
CC 		= ("&DEST_1","&DEST_2","&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso TRX_RENEGOCIACION_CIERRE");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso TRX_RENEGOCIACION_DIARIO, ejecutado con fecha: &fechaeDVN";  
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 04'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
