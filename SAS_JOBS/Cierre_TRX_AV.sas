/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	CIERRE_TRX_AV				 	 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-08-01 -- V01 -- David V.	-- Se agregan comentarios, versionamiento y correo + igualar a proceso diario con lo de Chek
/* 0000-00-00 -- V00 --    			-- Original

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

options validvarname=any;
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

/*  se agrega canal de venta CHEK y MasterCard Cerrada 15-07-2022 */

*ProcessBody;

* Start before STPBEGIN code [61d14dd8d18d40bcbdb4fbf9545cd4fd];/* Insertar código personalizado ejecutado delante de la macro STPBEGIN */
%global _ODSDEST;
%let _ODSDEST=none;
* End before STPBEGIN code [61d14dd8d18d40bcbdb4fbf9545cd4fd];

%STPBEGIN;

* Fin del código EG generado (no editar esta línea);


/*===========================================*/
/*============== FECHAS =====================*/
/*===========================================*/


%macro principal();
 
%LET NOMBRE_PROCESO = 'CIERRE_TRX_AV';



DATA _null_;

datei = input(put(intnx('month',today(),-1,'begin'),yymmdd10. ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datef = input(put(intnx('month',today(),-1,'end'),yymmdd10. ),$10.);   /*cambiar 0 a -1 para ver cierre mes anterior*/
datex = input(put(intnx('month',today(),-1,'end'),yymmn6.),$10.);      /*cambiar 0 a -1 para ver cierre mes anterior*/
exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechai", datei);
Call symput("fechaf", datef);
Call symput("fechax", datex);
Call symput("fechae", exec) ;
RUN;
%put &fechai;
%put &fechaf;
%put &fechax;
%put &fechae;

/*========================================================================================================================*/
/*======================================== CON CUOTAS ======================================================================*/
/*========================================================================================================================*/


/**************************REPLICA ITF****************************/

LIBNAME MPDT ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='KMARTINEZ' PASSWORD='kmar2102';
LIBNAME R_bopers ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='KMARTINEZ' PASSWORD='kmar2102';


PROC SQL;
CREATE TABLE AV_TRXCC AS 
        SELECT t1.CODENT,
               t1.CENTALTA, 
               t1.CUENTA, 
               t1.LINEA, 
               t1.FECFAC, 
               t1.CODTIPC, 
               t2.TOTCUOTAS, 
               t2.PORINT AS TASA_CAR,
               t2.PORINTCAR AS TASA_DIFERIDO,
               t2.NUMMESCAR AS DIFERIDO,/* CONFIRMAR EN PLATAFORMA*/
               t1.IMPFAC LABEL="CAPITAL" AS CAPITAL, 
               t2.IMPCUOTA LABEL="CUOTA" AS CUOTA, 
               t2.IMPINTTOTAL LABEL="INTERES" AS INTERES, 
               t2.IMPIMPTOTOT LABEL="IMPUESTO" AS IMPUESTO, 
               t1.SUCURSAL,
                  SUBSTR (t1.SUCURSAL, 5, 4)AS N_CAJA,
                  SUBSTR (t1.SUCURSAL, 1, 4)AS SUCURSAL1,
               T1.ESTCOMPRA,
               T1.NUMBOLETA,
               T1.NUMREFFAC,
			   t1.CODCOM,
			   T1.NUMAUT
 FROM MPDT.MPDT205 AS t1,MPDT.MPDT206 AS t2
 WHERE t1.CODENT = t2.CODENT AND t1.CENTALTA = t2.CENTALTA AND t1.CUENTA = t2.CUENTA 
       AND t1.CLAMON = t2.CLAMON AND t1.CODTIPC = t2.CODTIPC AND t1.NUMOPECUO = t2.NUMOPECUO 
       AND t1.LINEA = '0051'  
       AND t1.FECFAC BETWEEN "&fechai" AND "&fechaf"
       AND T1.ESTCOMPRA IN (1,3,6,7)/*COD VIGENTES */
	   AND T1.TIPOFAC NOT IN  (2951,1950,1951,1952,1957,1954,19,56)
     /*AND t1.ORIGENOPE = 'CCUO'*/
     ;
     QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

    PROC SQL;
        CREATE TABLE BASE_MPDT007 AS 
        SELECT A.*, 
               input(A.IDENTCLI,best.) as ID  
        FROM MPDT.MPDT007 AS A
     ;
     QUIT;


     PROC SQL;
     CREATE TABLE BASE_RUT AS
     SELECT A.*,
            B.PEMID_GLS_NRO_DCT_IDE_K AS RUT, 
            B.PEMID_DVR_NRO_DCT_IDE AS DV
     FROM BASE_MPDT007 AS A
     INNER JOIN R_BOPERS.BOPERS_MAE_IDE AS B ON (A.ID = B.PEMID_NRO_INN_IDE);
     QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

     /* CAMBIAR AL MES SOLICITADO*/


     PROC SQL;
        CREATE TABLE TRX_AV_CC AS 
        SELECT A.*, 
               B.RUT, 
               B.DV,
                  B.PRODUCTO,
                  input(B.RUT,best.) as RUT_1,
                  input(A.SUCURSAL1,best.) as SUCURSAL2,
                  input(A.N_CAJA,best.) as N_CAJA2,
                  input(A.NUMBOLETA,BEST32.)AS DOCUMENTO
         FROM AV_TRXCC AS A
         INNER JOIN BASE_RUT AS B ON A.CENTALTA = B.CENTALTA AND A.CUENTA = B.CUENTA;
            QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

     PROC SQL;
        CREATE TABLE TRX_AV_CC1 AS 
        SELECT A.*,
        CASE WHEN N_CAJA2 is MISSING AND SUCURSAL2 NOT IN (1,63) THEN 'ATM'
             WHEN SUCURSAL2 = 1 AND N_CAJA2=1 THEN 'HB' 
			 WHEN SUCURSAL2 = 300 AND N_CAJA2=1 THEN 'HB' 
			 WHEN SUCURSAL2 = 400 AND N_CAJA2=1 THEN 'APP'
			 WHEN SUCURSAL2 = 1 AND N_CAJA2=2000 THEN 'PF'
			 WHEN SUCURSAL2 = 200 THEN 'MOVIL'
             WHEN SUCURSAL2 = 63 THEN 'BCO'
			 WHEN SUCURSAL2 = 500 THEN 'CHEK'
			 WHEN N_CAJA2 =201 AND SUCURSAL2 = 6 THEN 'TLMK'/*NUEVO CANAL 25_06_2019 */
             WHEN N_CAJA2 >=200 AND SUCURSAL2 NOT IN (6,1,63,300,400) THEN 'TF'
             WHEN N_CAJA2 < 200 AND SUCURSAL2 NOT IN (6,1,63,300,400)THEN 'TV' 

	          END AS VIA
     FROM TRX_AV_CC AS A
     ;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SQL;
        CREATE TABLE TRX_AV_CC2 AS 
        SELECT t1.RUT_1 AS RUT, 
               t1.DV, 
			   t1.CODENT,
               t1.CENTALTA, 
               t1.CUENTA,
               t1.PRODUCTO, 
               t1.CODTIPC, 
               t1.LINEA, 
               t1.FECFAC, 
               t1.TOTCUOTAS, 
               t1.TASA_CAR FORMAT=COMMAX4.3,
               t1.TASA_DIFERIDO FORMAT=COMMAX4.3, 
               t1.DIFERIDO, 
               t1.CAPITAL FORMAT= BEST., 
               t1.CUOTA FORMAT= BEST., 
               t1.INTERES FORMAT= BEST., 
               t1.IMPUESTO FORMAT= BEST., 
               t1.SUCURSAL2 AS SUCURSAL, 
               t1.N_CAJA2 AS N_CAJA,
               t1.DOCUMENTO, 
               t1.VIA, 
			   t1.CODCOM,
			   T1.NUMAUT
           FROM WORK.TRX_AV_CC1 AS t1
	 WHERE SUCURSAL2 <> 901
     ORDER BY t1.FECFAC DESCENDING;
     QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
CREATE TABLE TRX_AV_CC3 AS
SELECT *, 
		CASE WHEN PRODUCTO IN ('01', '03') THEN 'TR CERRADA'
			 WHEN PRODUCTO IN ('05', '06') THEN 'TAM'
			 WHEN PRODUCTO IN ('10') THEN 'TAM CERRADA'
			 WHEN PRODUCTO ='07' THEN 'TAM CHIP'
			 END AS TIPO_PDTO
FROM TRX_AV_CC2
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

 PROC SQL;
	 CREATE TABLE TRX_AV_CON_CUOTAS_&fechax AS
	 SELECT *
     FROM TRX_AV_CC3;
	 QUIT;


%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


/*========================================================================================================================*/
/*======================================== SIN CUOTAS ======================================================================*/
/*========================================================================================================================*/

	
PROC SQL;
   CREATE TABLE AV_TRXSC AS 
   SELECT t1.CODENT, 
   		  t1.CENTALTA,
          t1.CUENTA, 
          t1.LINEA, 
          t1.FECFAC, 
          t1.TIPOFAC, 
          t1.IMPFAC LABEL="CAPITAL" AS CAPITAL, 
          t1.NUMAUT, 
          t1.DESCUENTO, 
          t1.NUMBOLETA, 
          t1.CODCOM, 
          t1.NOMCOMRED, 
          t1.SUCURSAL,
                  SUBSTR(t1.SUCURSAL, 5, 4)AS N_CAJA,
                  SUBSTR (t1.SUCURSAL, 1, 4)AS SUCURSAL1,
          t1.NUMCUOTA, 
          t1.TOTCUOTAS, 
          t1.NUMFINAN
      FROM MPDT.MPDT012 t1
      WHERE t1.FECFAC BETWEEN "&fechai" AND "&fechaf" 
      AND t1.LINEA = '0051'
	  AND TIPOFAC IN (2051, 6051, 6551, 2851);
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;
   


     /* CAMBIAR AL MES SOLICITADO*/


     PROC SQL;
        CREATE TABLE TRX_AV_SC AS 
        SELECT A.*, 
               B.RUT, 
               B.DV,
                  B.PRODUCTO,
                  input(B.RUT,best.) as RUT_1,
                  input(A.SUCURSAL1,best.) as SUCURSAL2,
                  input(A.N_CAJA,best.) as N_CAJA2,
                  input(A.NUMBOLETA,BEST32.)AS DOCUMENTO
         FROM AV_TRXSC AS A
         INNER JOIN BASE_RUT AS B ON A.CENTALTA = B.CENTALTA AND A.CUENTA = B.CUENTA
          ;QUIT;
%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


     PROC SQL;
        CREATE TABLE TRX_AV_SC1 AS 
        SELECT A.*,
       CASE WHEN N_CAJA2 is MISSING AND SUCURSAL2 NOT IN (1,63) THEN 'ATM'
             WHEN SUCURSAL2 = 1 AND N_CAJA2=1 THEN 'HB' 
			 WHEN SUCURSAL2 = 300 AND N_CAJA2=1 THEN 'HB' 
			 WHEN SUCURSAL2 = 400 AND N_CAJA2=1 THEN 'APP'
			 WHEN SUCURSAL2 = 1 AND N_CAJA2=2000 THEN 'PF'
			 WHEN SUCURSAL2 = 200 THEN 'MOVIL'
             WHEN SUCURSAL2 = 63 THEN 'BCO'
			 WHEN SUCURSAL2 = 500 THEN 'CHEK'
			 WHEN N_CAJA2 =201 AND SUCURSAL2 = 6 THEN 'TLMK'/*NUEVO CANAL 25_06_2019 */
             WHEN N_CAJA2 >=200 AND SUCURSAL2 NOT IN (6,1,63,300,400) THEN 'TF'
             WHEN N_CAJA2 < 200 AND SUCURSAL2 NOT IN (6,1,63,300,400)THEN 'TV' 
	          END AS VIA
     FROM TRX_AV_SC AS A
     ;
     QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SQL;
        CREATE TABLE TRX_AV_SC2 AS 
        SELECT t1.RUT_1 AS RUT, 
               t1.DV, 
			   t1.CODENT,
               t1.CENTALTA, 
               t1.CUENTA,
               t1.PRODUCTO, 
               t1.LINEA, 
               t1.FECFAC, 
               t1.TOTCUOTAS, 
               t1.CAPITAL FORMAT= BEST.,        
               t1.SUCURSAL2 AS SUCURSAL, 
               t1.N_CAJA2 AS N_CAJA,
               t1.DOCUMENTO, 
               t1.VIA
           FROM WORK.TRX_AV_SC1 AS t1
	 WHERE t1.SUCURSAL2 <> 901
     ORDER BY t1.FECFAC DESCENDING;
     QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SQL;
CREATE TABLE TRX_AV_SC3 AS
SELECT *, 
		CASE WHEN PRODUCTO IN ('01', '03') THEN 'TR CERRADA'
			 WHEN PRODUCTO IN ('05', '06') THEN 'TAM'
			 WHEN PRODUCTO IN ('10') THEN 'TAM CERRADA'
			 WHEN PRODUCTO ='07' THEN 'TAM CHIP'
			 END AS TIPO_PDTO
FROM TRX_AV_SC2
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

 PROC SQL;
	 CREATE TABLE TRX_AV_SIN_CUOTA_&fechax AS
	 SELECT *
     FROM TRX_AV_SC3;
	 QUIT;


%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


/*========================================================================================================*/
/*======================================= AGREGAR LAS TRX ================================================*/
/*========================================================================================================*/

PROC SQL;
CREATE TABLE TRX_MES AS
SELECT DISTINCT RUT, 
       DV, 
       CODENT,
       CENTALTA, 
       CUENTA, 
       PRODUCTO, 
	   TIPO_PDTO,
       LINEA, 
       FECFAC, 
       TOTCUOTAS, 
       CAPITAL, 
       SUCURSAL, 
       N_CAJA, 
       DOCUMENTO, 
       VIA,
	   TASA_CAR,
	   TASA_DIFERIDO,
	   CUOTA,
	   INTERES,
	  'CON_CUOTA' AS BASE,
      DIFERIDO
FROM TRX_AV_CON_CUOTAS_&fechax 
OUTER UNION CORR
SELECT RUT, 
       DV, 
       CODENT,
       CENTALTA, 
       CUENTA, 
       PRODUCTO, 
	   TIPO_PDTO,
       LINEA, 
       FECFAC, 
       TOTCUOTAS, 
       CAPITAL, 
       SUCURSAL, 
       N_CAJA, 
       DOCUMENTO, 
       VIA,
       /* tasa_car */
       (0) FORMAT=COMMAX4.3 AS tasa_car,
	   /* tasa_diferido */
       (0) FORMAT=COMMAX4.3 AS tasa_diferido,
	   0 as CUOTA,
	   0 as INTERES,
	   'SIN_CUOTA' AS BASE,
	   0 AS DIFERIDO
 FROM TRX_AV_SIN_CUOTA_&fechax 
 ;QUIT;

 %if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SQL;
 CREATE TABLE publicin.TRX_AV_&fechax AS
 SELECT *, &fechae as FEC_EX
 FROM TRX_MES
 ;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SQL;
DROP TABLE AV_TRXCC
,BASE_MPDT007
,BASE_RUT
,TRX_AV_CC
,TRX_AV_CC1
,TRX_AV_CC2
,TRX_AV_CC3
,TRX_AV_CON_CUOTAS_&fechax
,AV_TRXSC
,TRX_AV_SC
,TRX_AV_SC1
,TRX_AV_SC2
,TRX_AV_SC3
,TRX_AV_SIN_CUOTA_&fechax
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

%exit:

%put &syserr;
%put &FECHA_DETALLE; 
%let error = &syserr;
%put &error;

data _null_;
FECHA_PROCESO=cat((put(intnx('month',TODAY(),0,'same'),yymmdd10.)) ,"  " , (put(intnx('month',timepart(TIME()),0,'same'),hhmm8.2)) );
call symput("FECHA_DETALLE",FECHA_PROCESO);
run;


proc sql ;
select infoerr 
into : infoerr 
from result.TBL_DESC_ERRORES
where error=&error;
quit;

%let FEC_DET = "&FECHA_DETALLE";
%LET DESC = "&infoerr";  


	  proc sql ;
	  INSERT INTO result.tbl_estado_proceso
	  VALUES ( &error, &DESC, &FEC_DET , &NOMBRE_PROCESO );
	  quit;
   %put inserta el valor syserr &syserr y error &error;


%mend;

%principal();



* Inicio del código EG generado (no editar esta línea);
;*';*";*/;quit;
%STPEND;

* Fin del código EG generado (no editar esta línea);


/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */

/*fecha proceso*/
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
SUBJECT = ("MAIL_AUTOM: Proceso CIERRE_TRX_AV");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "		Proceso CIERRE_TRX_AV, ejecutado automáticamente con fecha: &fechaeDVN";  
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 01'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
