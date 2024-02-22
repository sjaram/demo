/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	ONB_PAGOS_FOR_PAGOS_new		================================*/
/* CONTROL DE VERSIONES
/* 2022-11-08 -- v05 -- Sergio J .	--  Cambio de directorio a campaign
/* 2022-10-28 -- v04 -- Sergio J.	-- New delete and export code to aws
/* 2022-10-03 -- v03 -- Sergio J.	--  Actualización Delete AWS
/* 2022-09-13 -- v02 -- David V.	--  Actualización export to AWS
/* 2021-05-05 -- V01 -- Valentina M.-- Versión Original +  EDP.

/* INFORMACIÓN:
	Proceso parte del proyecto ONBOARDING.

	(IN) Tablas requeridas o conexiones a BD:
	- 

	(OUT) Tablas de Salida o resultado:
	- /sasdata/users94/user_bi/unica/INPUT-TR_PAGOS_TC-&USUARIO..csv

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio	= %sysfunc(datetime());

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/

/* Usuario que genera el archivo */
%let USUARIO	=	USER_BI;

DATA _null;
INI = put(intnx('month',today(),-3,'same'),date9.);
DESDE=input(put(intnx('month',today(),-3,'same'),yymmdd10.),$10.);
HASTA=input(put(intnx('day',today(),-1,'same'    ),yymmdd10.   ),$10.);
Call symput("INI", INI);
Call symput("DESDE", DESDE);
Call symput("HASTA", HASTA);

RUN;
%put &INI;
%put &DESDE;
%put &HASTA;

LIBNAME MPDT  ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017'; /*REVISAR CONEXION*/
LIBNAME BOPERS ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='SAS_USR_BI' PASSWORD='SAS_23072020';

PROC SQL;
CREATE TABLE ONB_PAGOS_BASE AS 
SELECT A.RUT_CLIENTE as ID_USUARIO, 
A.PRODUCTO AS TIPO_TC, 
A.FECHA AS FECHA_CAPTACION
FROM RESULT.CAPTA_SALIDA as A
WHERE A.PRODUCTO IN( 'TR', 'TAM') AND 
A.FECHA >= "&INI"d ;
QUIT;


/*CONVERTIR A NUMÉRICO*/


PROC SQL  NOERRORSTOP ;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table ONB_PAGOS  as 
select 
*
from connection to ORACLE( 
select 
CODENT, 
CENTALTA, 
CUENTA,
IMPAPL AS MONTO_PAGADO, 
FECAPL AS FECHA_PAGO,
FECEMIMOV AS FECHA_FACTURACION, 
FECVENMOV AS FECHA_VENCIMIENTO_PAGO
FROM GETRONICS.MPDT072 
where FECAPL between %str(%')&desde.%str(%') and %str(%')&hasta.%str(%')
) A
;QUIT;

proc sqL;
create table ONB_PAGOS_DVN AS
SELECT 
CODENT, 
CENTALTA, 
CUENTA,
MONTO_PAGADO, 
FECHA_PAGO,
FECHA_VENCIMIENTO_PAGO, 
FECHA_FACTURACION,
input(cat((SUBSTR(FECHA_FACTURACION,1,4)),(SUBSTR(FECHA_FACTURACION,6,2)),(SUBSTR(FECHA_FACTURACION,9,2))) ,BEST10.) AS FECHA_TRUNC3,
input(cat((SUBSTR(FECHA_VENCIMIENTO_PAGO,1,4)),(SUBSTR(FECHA_VENCIMIENTO_PAGO,6,2)),(SUBSTR(FECHA_VENCIMIENTO_PAGO,9,2))) ,BEST10.) AS FECHA_TRUNC2,
input(cat((SUBSTR(FECHA_PAGO,1,4)),(SUBSTR(FECHA_PAGO,6,2)),(SUBSTR(FECHA_PAGO,9,2))) ,BEST10.) AS FECHA_TRUNC1
FROM ONB_PAGOS 

;QUIT;

/*EL NUMÉRICO PASARLO AL FORMATO REQEURIDO*/
proc sqL;
create table ONB_PAGOS_DVN_2 AS
SELECT 
*,
MDY(INPUT(SUBSTR(PUT(FECHA_TRUNC1,BEST8.),5,2),BEST4.),
                  INPUT(SUBSTR(PUT(FECHA_TRUNC1,BEST8.),7,2),BEST4.),
                  INPUT(SUBSTR(PUT(FECHA_TRUNC1,BEST8.),1,4),BEST4.)) 
FORMAT=MMDDYY10. 
AS FECHA_PAGO_OK,

MDY(INPUT(SUBSTR(PUT(FECHA_TRUNC2,BEST8.),5,2),BEST4.),
                  INPUT(SUBSTR(PUT(FECHA_TRUNC2,BEST8.),7,2),BEST4.),
                  INPUT(SUBSTR(PUT(FECHA_TRUNC2,BEST8.),1,4),BEST4.)) 
FORMAT=MMDDYY10. 
AS FECHA_VENCIMIENTO_PAGO_OK,


MDY(INPUT(SUBSTR(PUT(FECHA_TRUNC3,BEST8.),5,2),BEST4.),
                  INPUT(SUBSTR(PUT(FECHA_TRUNC3,BEST8.),7,2),BEST4.),
                  INPUT(SUBSTR(PUT(FECHA_TRUNC3,BEST8.),1,4),BEST4.)) 
FORMAT=MMDDYY10. 
AS FECHA_FACTURACION_OK

FROM ONB_PAGOS_DVN 
;QUIT;


proc sql;
create table ONB_PAGOS_RUTS as 
select 
a.codent,
a.centalta,
a.cuenta,
B.PEMID_GLS_NRO_DCT_IDE_K AS RUT
from MPDT.MPDT007 a 
INNER JOIN bopers.BOPERS_MAE_IDE AS B 
ON INPUT(A.IDENTCLI,BEST.)=B.PEMID_NRO_INN_IDE
;QUIT;

PROC SQL;
CREATE TABLE ONB_PAGOS_FOR_PAGOS AS 
SELECT
B.RUT AS ID_Usuario,
A.MONTO_PAGADO, 
A.FECHA_PAGO_OK AS FECHA_PAGO, 
A.FECHA_VENCIMIENTO_PAGO_OK AS FECHA_LIMITE_PAGO, 
A.FECHA_FACTURACION_OK AS FECHA_FACTURACION
FROM ONB_PAGOS_DVN_2  AS A 
LEFT JOIN ONB_PAGOS_RUTS AS B
ON (A.CODENT = B.CODENT) AND (A.CENTALTA=B.CENTALTA) AND (A.CUENTA = B.CUENTA)
;QUIT;


PROC SQL;
CREATE TABLE ONB_PAGOS_FOR_FOR_PAGOS AS 
SELECT
INPUT(A.ID_USUARIO, BEST.) AS ID_USUARIO,
INPUT(PUT(A.MONTO_PAGADO,BEST.),BEST.) AS MONTO_PAGADO, 
A.FECHA_PAGO, 
A.FECHA_LIMITE_PAGO as FECHA_VENCIMIENTO_PAGO, 
A.FECHA_FACTURACION
FROM ONB_PAGOS_FOR_PAGOS AS A 
INNER JOIN ONB_PAGOS_BASE AS B 
ON (input(A.ID_Usuario,best.) = B.ID_USUARIO)
ORDER BY A.ID_Usuario,A.FECHA_PAGO
;QUIT;


/*Aplicar "ROW_NUMBER" de SAS*/

data ONB_PAGOS_FOR_FOR_PAGOS; /*Nombre de nueva tabla*/

  set ONB_PAGOS_FOR_FOR_PAGOS; /*Nombre de actual tabla*/

  by ID_Usuario FECHA_PAGO notsorted; /*variables por las que se quiere aplicar el correlativo*/

  NUM_TRANSACCION + 1; /*regla del correlativo*/

  if first.ID_USUARIO then NUM_TRANSACCION=1; /*regla del correlativo*/

run;

 proc sql; 
 create table prueba_bi_pagos as 
 select *
 from ONB_PAGOS_FOR_FOR_PAGOS
 ;quit; 

 PROC EXPORT DATA = prueba_bi_pagos
OUTFILE="/sasdata/users94/user_bi/unica/input/INPUT-TR_PAGOS_TC-&USUARIO..csv"
DBMS=dlm REPLACE;
delimiter=',';
PUTNAMES=YES;
RUN;



/*DELETE AND EXPORT TO AWS*/

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(INPUT_TR_PAGOS_TC,raw,oracloud/campaign,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(INPUT_TR_PAGOS_TC,work.prueba_bi_pagos,raw,oracloud/campaign,0);

/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/

/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
