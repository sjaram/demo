/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	TRX_REFINANCIAMIENTO_CIERRE 	================================*/
/* CONTROL DE VERSIONES
/* 2022-10-07 -- V03 -- Sergio J.	-- Se agregan exportación a raw
/* 2021-01-15 -- V02 -- Sergio.J -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- 

*/

options validvarname=any; 
LIBNAME replica ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='SAS_USR_BI' PASSWORD='SAS_23072020';



DATA _null_;

datei = input(put(intnx('month',today(),-1,'begin'),yymmdd10. ),$10.);
datef = input(put(intnx('month',today(),-1,'end'),yymmdd10. ),$10.);
datex = input(put(intnx('month',today(),-1,'end'),yymmn6.),$10.);
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
        WHERE A.CODTIPC = '0060';/*AL DIA*//*0070*/
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



LIBNAME R_bopers ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='SAS_USR_BI' PASSWORD='SAS_23072020';


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






PROC SQL;
 CREATE TABLE   PUBLICIN.TRX_REF_&fechax as
   SELECT t1.CENTALTA, 
          t1.CUENTA, 
          t1.FECFAC,
          t1.ESTCOMPRA, 
          t1.FECHA_TRUNC, 
          t1.TOTCUOTAS, 
          t1.TASA FORMAT=best3.2, 
          t1.CAPITAL FORMAT=BEST32., 
          t1.CUOTA FORMAT=BEST32., 
          t1.INTERES FORMAT=BEST32., 
          t1.IMPUESTO FORMAT=BEST32.,
		  t1.TIPOFAC,
          /*t1.SUCURSALES,*/
          INPUT(t1.SUCURSALES,BEST.)AS SUCURSAL,  
          t1.DESTIPC, 
		  input(t1.RUT, best.) AS RUT,
 CASE WHEN INPUT(t1.SUCURSALES,BEST.) = 60 THEN 'CALL CENTER OPC'
WHEN INPUT(t1.SUCURSALES,BEST.) = 61 THEN 'CALL  CENTER COB VALPARAISO'
WHEN INPUT(t1.SUCURSALES,BEST.) IN (801,802) THEN 	'CALL CENTER EXTERNO'
ELSE 'TDA' END AS Origen_venta,
 CASE WHEN  INPUT(t1.SUCURSALES,BEST.)  IN (60,61,801,802) THEN 'CALL'
WHEN INPUT(t1.SUCURSALES,BEST.) = 120 THEN 'INTERNET'
ELSE 'CCSS' END AS VIA
      FROM REF_ITF_PRUEBA4 AS t1 
	  ORDER BY t1.FECFAC DESCENDING;
QUIT;


%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_ppff_trx_ref,raw,sasdata,-1);

/*Exportación a AWS*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_ppff_trx_ref,publicin.TRX_REF_&fechax.,raw,sasdata,-1);





PROC SQL NOPRINT;
   /*CREATE TABLE WORK.QUERY_FOR_TRX_REF_20 AS*/ 
   SELECT /* COUNT_of_RUT */
            (COUNT(t1.RUT)) AS COUNT_of_RUT, 
          /* SUM_of_CAPITAL */
            (SUM(t1.CAPITAL)) FORMAT=BEST32. AS SUM_of_CAPITAL
      FROM PUBLICIN.TRX_REF_&fechax t1;
QUIT;


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
SUBJECT = ("MAIL_AUTOM: Proceso TRX_REFINANCIAMIENTO");
FILE OUTBOX;
 PUT "Estimados:";
 put "    Proceso TRX_REFINANCIAMIENTO_CIERRE, ejecutado Exitosamente con fecha: &fechaeDVN";  
 put ; 
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 03'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/


