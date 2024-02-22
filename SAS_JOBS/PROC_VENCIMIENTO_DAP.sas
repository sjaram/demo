/*==========================================================================================*/
/*=============================	EQUIPO DATOS Y PROCESOS		================================*/
/*=============================	PROC_VENCIMIENTO_DAP 		================================*/
/* CONTROL DE VERSIONES
/* 2022-04-05 -- V2 -- Esteban P. -- Se actualizan los correos: Se elimina a SEBASTIAN_BARRERA.
/* 2020-06-19 ---- Primera versión, con envío de Email
*/
/*==========================================================================================*/
/*
--- Tablas FROM Utilizadas
	kmartine.ZONAS_SUCURSAL_BANCO
	RESULT.DETALLE_STOCK_DAP_&periodo2
	TGEN_TIPO
	PUBLICIN.FONOS_FIJOS_FINAL
	PUBLICIN.LNEGRO_CALL
	PUBLICIN.FONOS_MOVIL_FINAL

--- Tablas de Paso a Eliminar
	work.BASE_vcto_STOCK_DAP_&periodo2
	work.SALIDA_DAP_XVENCER_PRESENCIAL
	work.SALIDA_DAP_XVENCER_NOPRESEN
	work.BASE_vcto_STOCK_DAP_&periodo2
---
/*==========================================================================================*/

/*===============================================================================================================================================================*/
/*=== MACRO FECHAS MES ==============================================================================================================================================*/
/*===============================================================================================================================================================*/

data _null_;
exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);
date0 = input(put(intnx('month',today(),0,'same'),yymmn6. ),$10.);
date2 = compress(input(put(today(),yymmdd10.),$10.),"-",c);
dated = input(put(intnx('day',today(),3,'begin'),date9. ),$10.);
datef = input(put(intnx('day',today(),9,'begin'),date9. ),$10.);

Call symput("fechae", exec) ;
Call symput("periodo", date0);
Call symput("periodo2", date2);
Call symput("fechainicio", dated);
Call symput("fechafin", datef);

/*UTILIZAR FECHA DIA HORA*/
proc format;
   picture cust_dt other = '%0Y%0m%0d%0H%0M%0S' (datatype=datetime);
RUN;
data test;
    dt = datetime();
    call symputx("dt",strip(put(dt,cust_dt.)));

RUN;
%put &dt.;
%put &fechae;/*fecha ejecucion proceso */
%put &periodo; /*periodo actual */
%put &periodo2; /*periodo dia actual */
%put &fechainicio;/*fecha inicio Lunes prox semana*/
%put &fechafin;/*fecha fin Domingo prox semana*/


/*===============================================================================================================================================================*/
/*=== Extrae vencimientos próx semana ==============================================================================================================================================*/
/*===============================================================================================================================================================*/

/* Luego de la ejecución de  proceso STOCK DAP- Tabla DETALLE Stock result - libros negros */

PROC SQL;
CREATE TABLE DETALLE_STOCK_DAP_&periodo AS
SELECT *
FROM RESULT.DETALLE_STOCK_DAP_&periodo2
WHERE  FECHA_VENCIMIENTO BETWEEN "&fechainicio:00:00:00"dt AND "&fechafin:23:59:59"dt
;QUIT;


/*===============================================================================================================================================================*/
/*=== Extrae descripcion Tipo Dap  ==============================================================================================================================================*/
/*===============================================================================================================================================================*/

%let mz_connect_BANCO=CONNECT TO ORACLE as BANCO(USER='RIPLEYC' PASSWORD='ri99pley'
PATH="  (DESCRIPTION = 
    (ADDRESS_LIST = 
      (ADDRESS = 
        (PROTOCOL = TCP)
        (Host = 192.168.10.31)
        (Port = 1521)
      )
    )
    (CONNECT_DATA = 
      (SID = ripleyc)
    )
  )
");


proc sql;
&mz_connect_BANCO;
create table work.Tipo_DAP as
SELECT *
from  connection to BANCO(
select *
from TGEN_TIPO
where TIP_MOD =5
) as X
;QUIT;


/*===============================================================================================================================================================*/
/*=== Se excluyen dap tipo funcionario +  Dap Personas Juridicas + Dap dolar  ==============================================================================================================================================*/
/*===============================================================================================================================================================*/


Proc sql;
create table vcto_STOCK_DAP_&periodo as 
SELECT t1.RUT_CLIENTE, 
          t1.NOMBRE_CLIENTE, 
          t1.CODIGO_OPERACION, 
          t1.NOMBRE_EJECUTIVO, 
          t1.CARGO_EJECUTIVO, 
          t1.CAPITAL_VIGENTE, 
          t1.FECHA_APERTURA, 
          t1.FECHA_VENCIMIENTO, 
/*        t1.FECHA_RENOVACION, */
          t1.PLAZO, 
          t1.TASA, 
CATS('DEPOSITOS A PLAZO, ', T2.TIP_DESCRIP) AS Descripcion_Producto,
input(cat(put(t1.PDA_PRO,2.),put(t1.PDA_TIP,1.)),best.) as Cod_tip_producto,
t1.PDA_PRO,
t1.PDA_TIP,
T1.CODIGO_SUCURSAL,
input(put(datepart(t1.FECHA_VENCIMIENTO),yymmddn8.),best.) as fec_num
FROM DETALLE_STOCK_DAP_&periodo T1
LEFT JOIN Tipo_DAP T2 ON T1.PDA_MOD=T2.TIP_MOD AND t1.PDA_PRO=T2.TIP_PRO AND T1.PDA_TIP=T2.TIP_TIP
WHERE t1.PDA_PRO NOT >=60 /*filtro funcionario*/
AND input(cat(put(t1.PDA_PRO,2.),put(t1.PDA_TIP,1.)),best.) not  in (523,
527,
535,
575,
577,
621,
622,
625,
626,
631,
634,
672) /* filtro rol juridico y dap en dolar*/ 
;QUIT;



/*===============================================================================================================================================================*/
/*=== Se agrega contactabilidad  ==============================================================================================================================================*/
/*===============================================================================================================================================================*/


PROC SQL;
   CREATE TABLE WORK.fonos_fijos AS 
   SELECT t1.CLIRUT, 
          t1.AREA, 
          t1.TELEFONO, 
          t1.FECHA_ULT_ACTUALIZACION, 
          t1.NOTA, 
          t1.MANDANTE, 
          t1.TIPO
      FROM PUBLICIN.FONOS_FIJOS_FINAL t1
      WHERE t1.TIPO = 'PA'
and t1.telefono not in (select fono from PUBLICIN.LNEGRO_CALL) ;
QUIT;

PROC SQL;
   CREATE TABLE WORK.fonos_movil AS 
   SELECT t1.CLIRUT, 
          t1.AREA, 
          t1.TELEFONO, 
          t1.FECHA_ULT_ACTUALIZACION, 
          t1.NOTA, 
          t1.MANDANTE, 
          t1.TIPO
      FROM PUBLICIN.FONOS_MOVIL_FINAL t1
/*      WHERE t1.TIPO = 'PA'*/
where t1.telefono not in (select fono from PUBLICIN.LNEGRO_CALL) ;
QUIT;


data _null_;
exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechae", exec) ;
%put &fechae;/*fecha ejecucion proceso */


PROC SQL;
   CREATE TABLE work.BASE_vcto_STOCK_DAP_&periodo2 AS 
   SELECT distinct INPUT((SUBSTR(t1.RUT_CLIENTE,1,(LENGTH(t1.RUT_CLIENTE)-1))),BEST.) AS RUT2 ,t1.*,
/*case when t1.FECHA_RENOVACION not is missing then 'Renovable' else 'Fijo' end as  tipo, */
          CASE WHEN T3.RUT NOT IS MISSING THEN 'Si' else 'No' end as LNEGRO_CALL,
		  CASE WHEN T4.RUT NOT IS MISSING THEN 'Si' else 'No' end as LNEGRO_CAR,
	      t5.AREA, 
          t5.TELEFONO,
		  T6.AREA AS AREA_PA, 
          t6.TELEFONO AS TELEFONO_PA,
		   t7.DESCRIPCION, 
          t7.ZONA,
		  &fechae as FECHA_EJECUCION/*,
		  T7.AREA AS AREA_RF, 
          t7.TELEFONO AS TELEFONO_RF*/
      FROM vcto_STOCK_DAP_&periodo t1
	       LEFT JOIN PUBLICIN.LNEGRO_CALL t3 ON (INPUT((SUBSTR(t1.RUT_CLIENTE,1,(LENGTH(t1.RUT_CLIENTE)-1))),BEST.) = t3.RUT)
           LEFT JOIN PUBLICIN.LNEGRO_CAR t4 ON (INPUT((SUBSTR(t1.RUT_CLIENTE,1,(LENGTH(t1.RUT_CLIENTE)-1))),BEST.) = t4.rut)
           LEFT JOIN /*PUBLICIN*/fonos_movil t5 ON (INPUT((SUBSTR(t1.RUT_CLIENTE,1,(LENGTH(t1.RUT_CLIENTE)-1))),BEST.) = t5.CLIRUT)
		   LEFT JOIN fonos_fijos T6 ON (INPUT((SUBSTR(t1.RUT_CLIENTE,1,(LENGTH(t1.RUT_CLIENTE)-1))),BEST.) = t6.CLIRUT)
	       LEFT JOIN kmartine.ZONAS_SUCURSAL_BANCO t7 ON (t1.CODIGO_SUCURSAL = t7.CODIGO)
		  WHERE T3.RUT IS MISSING 
	      AND T4.RUT IS MISSING  
		  AND t5.TELEFONO > 1
/*		  OR t6.TELEFONO NOT IS MISSING*/
          ;QUIT;


		  /*** salida para consulta excel add in ***/

PROC SQL;
   CREATE TABLE work.SALIDA_DAP_XVENCER_PRESENCIAL AS 
   SELECT 
/*RUT2*/
RUT2 AS RUT,
NOMBRE_CLIENTE ,
CODIGO_OPERACION,
NOMBRE_EJECUTIVO,
CARGO_EJECUTIVO,
CAPITAL_VIGENTE ,
FECHA_APERTURA,
/*FECHA_APERTURA,*/
FECHA_VENCIMIENTO,
PLAZO,
TASA,
Descripcion_Producto,
AREA,
TELEFONO,
CODIGO_SUCURSAL,
DESCRIPCION AS SUCURSAL,
ZONA,
FECHA_EJECUCION
      FROM work.BASE_vcto_STOCK_DAP_&periodo2 
	  WHERE CODIGO_SUCURSAL NOT =70
;QUIT;

		  /*** salida para consulta excel add in ***/

PROC SQL;
   CREATE TABLE work.SALIDA_DAP_XVENCER_NOPRESEN AS 
   SELECT 
/*RUT2*/
RUT2 AS RUT,
NOMBRE_CLIENTE ,
CODIGO_OPERACION,
NOMBRE_EJECUTIVO,
CARGO_EJECUTIVO,
CAPITAL_VIGENTE ,
FECHA_APERTURA,
/*FECHA_APERTURA,*/
FECHA_VENCIMIENTO,
PLAZO,
TASA,
Descripcion_Producto,
AREA,
TELEFONO,
CODIGO_SUCURSAL,
DESCRIPCION AS SUCURSAL,
ZONA,
FECHA_EJECUCION
      FROM work.BASE_vcto_STOCK_DAP_&periodo2 
	  WHERE CODIGO_SUCURSAL  =70
;QUIT;

/*   UNIFICAR TABLAS DE SALIDA ANTERIORES   */
PROC SQL;
   CREATE TABLE work.DAP_XVENCER_&dt. AS 
   SELECT 	a.*,
   			'NO_PRESENCIAL' AS TIPO
		FROM WORK.SALIDA_DAP_XVENCER_NOPRESEN AS A
   UNION 
   SELECT 	B.*,
			'PRESENCIAL' AS TIPO
		FROM WORK.SALIDA_DAP_XVENCER_PRESENCIAL AS B
;QUIT;


/*   EXPORTAR SALIDA A FTP DE SAS   */
PROC EXPORT DATA=work.DAP_XVENCER_&dt.
   OUTFILE="/sasdata/users94/user_bi/para_mail/SALIDA_DAP_XVENCER_PRESYNO_&dt..csv"
   DBMS=dlm;
   delimiter=';';
   PUTNAMES=YES;
RUN;


/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'KARINA_MARTINEZ';

SELECT EMAIL into :DEST_2 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_3 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'RODRIGO_LAIZ';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_2","&DEST_3","mperezt@bancoripley.com","ivivancom@bancoripley.com")
ATTACH="/sasdata/users94/user_bi/para_mail/SALIDA_DAP_XVENCER_PRESYNO_&dt..csv"
SUBJECT = ("MAIL_AUTOM: Vencimientos DAP");
FILE OUTBOX;
PUT "Estimados:";
PUT ; 
 put "Se adjunta archivo de Vencimientos,  con fecha: &fechae";  
 put ; 
 put ; 
 put ; 
 PUT '** Este correo no debe ser reenviado **';
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

/*	ELIMINAR TABLAS DE PASO	*/
proc sql;
	drop table	work.BASE_vcto_STOCK_DAP_&periodo2;
	drop table	work.SALIDA_DAP_XVENCER_PRESENCIAL;
	drop table	work.SALIDA_DAP_XVENCER_NOPRESEN;
	drop table	work.BASE_vcto_STOCK_DAP_&periodo2;
;quit;
