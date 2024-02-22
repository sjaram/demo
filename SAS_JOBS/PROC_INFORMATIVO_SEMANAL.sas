/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROG_INFOMATIVO_SEMANAL		================================*/
/* CONTROL DE VERSIONES
/* 2022-04-04 -- V6 -- Esteban P. -- Se actualizan los correos: Se elimina a Ana Muñoz.

/* 2020-11-18 -- V5 -- David V. --
					-- Se decomenta código para única para subir al server sas
/* 2020-11-18 -- V4 -- David V. --
					-- Ajustes mínimos para dejar en servidor SAS
/* 2020-11-17 -- V3 -- Ana M. --  
					-- Quitar logs locales para subir a Servidor SAS
/* 2020-10-20 -- V2 -- David V. --  
					-- Ajustes mínimos para dejar en servidor SAS
/* 2020-10-20 -- V1 -- Ana Muñoz --  
					-- Versión Original
/* INFORMACIÓN:
	Programa carga masiva clienets TAM

	(IN) Tablas requeridas o conexiones a BD:
	- PUBLICIN.ACT_TR_AAAAMM
	- RESULT.CTAVTA1_STOCK

	(OUT) Tablas de Salida o resultado:
	- &libreria..EMAIL_INFO_AAAAMMDD

 Cliente : Paola Fuenzalida (Solicita y entrega las definiciones de negocio para crear proceso)
 Creado por : Alejandra Marinao
 Fecha : Marzo 2020   
 Descripción : Genera base email informativa  
 Modificado por : Ana Muñoz  M.
 Fecha : Abril2020  El proceso se deja automatico                           
 Fecha 26/08/26 Paola Fuenzalida pide cambiar vu por vu prime             
 Fecha 27/08/27 David Vasquez via mail solicita sacar filtros Higienicos 
 Debe solo filtrarse por Fallecidos  
 cambiar tabla PUBLICIN.BASE_TRABAJO_EMAIL por UBLICIN.PUBLICIN.BASE_TRABAJO_EMAIL_SE
    
*/

%let libreria=PUBLICIN;
%put====================================================;
%put [01]INICIO PROCESO;
%put====================================================;
%let cod_proceso= 100;

%put====================================================;
%put [02] Declaración variables tiempo;
%put====================================================;

Data _null_;
tiempo_inicio= %sysfunc(datetime());/* inicio del proceso de conteo*/
Call symput("tiempo_inicio",tiempo_inicio) ;
tiempo_inicio_c =  put(tiempo_inicio,NLDATML32.);
Call symput("ftiempo_inicio_c", tiempo_inicio_c);
periodo_c = compress(PUT(today(),yymmn6.)); 
Call symput("fperiodo_c", periodo_c) ;
periodo_n = INput(PUT(today(),yymmn6.),$10.); /*revisar*/
Call symput("periodo_n", periodo_n) ;
time_h =  time() ;
Call symput("ftime_h", time_h) ;
time_c = compress(put(time_h,Time10.));
Call symput("ftime_c", time_c) ;
exec_n = compress(input(put(today(),yymmdd10.),$10.),"-");
Call symput("fecha_n",exec_n);
/*exec_c = INPUT(compress(input(put(today(),yymmdd10.),$10.),"-",c),BEST.);*/
exec_n = compress(INPUT(compress(input(put(today(),yymmdd10.),$10.),"-"),BEST.));
Call symput("fecha_c",exec_n);
;run;

%PUT tiempo inicio: &ftiempo_inicio_c;
%PUT periodo: &fperiodo_c;


/*CREAR CARPETA LOG*/
/*
%let arch_log="/sasdata/users94/user_bi/LOGS_PROCESOS/INFORMATIVO_SEMANAL.txt/";
%PUT &arch_log;

data _null_;
x rm &arch_log;  
run;

PROC PRINTTO LOG=&arch_log;
RUN;

*/
%put======================================================;
%put[03] FECHA Inicio PROCESO: &fecha_n &ftime_c ;
%put======================================================;

%put===========================================;
%put[04] Carga   Bitacora;
%put===========================================;

%put======================================================;
%put[05] FECHA Inicio PROCESO  &ftiempo_inicio_c  ;
%put======================================================;

%put===========================================================;
%put [06] Determinar ultima fecha de tabla de actividad TR ;
%put============================================================;
%let Nombre_Tabla=%nrstr('PUBLICIN.ACT_TR_AAAAMM');

PROC SQL outobs=1 noprint;
	select max(anomes) as anomes
		into :anomes 
			from (
				select *,
					input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
				from (
					select 
						*,
						cat(trim(libname),.,trim(memname)) as Nombre_Tabla
					from sashelp.vmember
						) as a
					where upper(Nombre_Tabla) like 'PUBLICIN.ACT_TR_%' 
						and length(Nombre_Tabla)=length('PUBLICIN.ACT_TR_AAAAMM')
						) as x 
;QUIT;


/*Periodo a */
DATA _NULL_;
anomes=compress(put(&anomes, best.));
Call symput("anomes_c",anomes);
run;

%put publicin.act_tr_&anomes_c;

%put===========================================;
%put [07] Obtener Clientes  Credito ;
%put===========================================;


PROC SQL noprint; 
create table TMP_stock_TR_TAM as  
select distinct rut
from PUBLICIN.ACT_TR_&anomes_c
WHERE  VU_C_PRIMA = 'VU'  
;QUIT;


%put=============================================;
%put [08] Obtener  clientes Debito;
%put==============================================;

PROC SQL noprint; 
create table TMP_stock_CV as 
select distinct rut
FROM RESULT.CTAVTA1_STOCK
WHERE Estado_Cuenta='vigente'
;QUIT;

%put===========================================================;
%put [09] Determinar ultima fecha de tabla de Rebote suave ;
%put============================================================;
%let Nombre_Tabla=%nrstr('RESULT.SP_REBOTE_SUAVE_AAAAMM');

PROC SQL outobs=1 noprint;
	select max(anomes) as anomes
		into :anomes 
			from (
				select *,
					input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
				from (
					select 
						*,
						cat(trim(libname),.,trim(memname)) as Nombre_Tabla
					from sashelp.vmember
						) as a
					where upper(Nombre_Tabla) like 'RESULT.SP_REBOTE_SUAVE_%' 
						and length(Nombre_Tabla)=length('RESULT.SP_REBOTE_SUAVE_AAAAMM')
						) as x 
;QUIT;

/*Periodo a */
DATA _NULL_;
anomes=compress(put(&anomes, best.));
Call symput("anomes_c",anomes);
run;

%put RESULT.SP_REBOTE_SUAVE_&anomes_c;

%put==========================================;
%put [10] consolidar clientes Credito y Debito;
%put==========================================;

/**/
PROC SQL noprint;
CREATE TABLE TMP_RUTERO AS 
SELECT distinct RUT 
FROM (
	SELECT distinct t1.RUT 
	FROM TMP_stock_TR_TAM t1
	UNION
	SELECT distinct t2.RUT 
	FROM TMP_stock_CV t2) 
;QUIT;

%put================================================================;
%put [11] Pegar a datos consolidado nombre direccion email telefono ;
%put================================================================;

PROC SQL noprint;
CREATE TABLE TMP_DATA AS 
SELECT DISTINCT T1.RUT,
A.PRIMER_NOMBRE AS NOMBRE,A.PATERNO,
E.COD_REGION,E.REGION,E.COMUNA,
F.EMAIL, CASE WHEN F.RUT IS NOT MISSING THEN 1 ELSE 0 END AS T_EMAIL,
G.TELEFONO, CASE WHEN G.CLIRUT IS NOT MISSING THEN 1 ELSE 0 END AS T_FONO
FROM TMP_RUTERO T1 
LEFT JOIN PUBLICIN.BASE_NOMBRES A ON T1.RUT=A.RUT
/*LEFT JOIN PUBLICIN.BASE_TRABAJO_EMAIL F ON T1.RUT=F.RUT Fecha modif: 20200827*/
LEFT JOIN PUBLICIN.BASE_TRABAJO_EMAIL_SE F ON T1.RUT=F.RUT
LEFT JOIN PUBLICIN.FONOS_MOVIL_FINAL G ON (T1.RUT=G.CLIRUT)
LEFT JOIN PUBLICIN.DIRECCIONES E ON T1.RUT=E.RUT
;QUIT;


PROC SQL noprint;
CREATE TABLE ELIMINADOS AS
SELECT * FROM PUBLICIN.LNEGRO_CAR
WHERE TIPO_INHIBICION IN ('FALLECIDO','FALLECIDOS')
;QUIT;

PROC SQL noprint;
CREATE TABLE TMP_DATA2 AS 
SELECT A.*
FROM TMP_DATA as A
WHERE RUT NOT IN (SELECT RUT FROM ELIMINADOS)
and UPPER(EMAIL) NOT IN (SELECT UPPER(EMAIL) FROM RESULT.SP_REBOTE_SUAVE_&anomes_c)
and RUT NOT IN (SELECT RUT FROM RESULT.SP_REBOTE_SUAVE_&anomes_c)
;quit; 

proc sql noprint; 
select count(*) into :total_reg
from TMP_DATA2 a
;QUIT;
%put==========================================================================================;
%put [12] Genera base informativo semanal ;
%put==========================================================================================;


options cmplib=sbarrera.funcs;
PROC SQL noprint;
CREATE TABLE EMAIL_INFO AS 
SELECT A.*,B.SEGMENTO
FROM TMP_DATA2 A LEFT JOIN PUBLICIN.SEGMENTO_COMERCIAL B ON A.RUT=B.RUT
WHERE A.t_EMAIL=1
;quit;

data _null_;
  dur_c = SUBSTR(compress(put(datetime() - &tiempo_inicio,time13.2)),1,10);
  Call symput("dur_c", dur_c) ;
  dur_n = input(scan(compress(put(datetime() - &tiempo_inicio,time13.2)),1,":")||"."||scan(compress(put(datetime() - &tiempo_inicio,time13.2)),2,":") ,best32.  );
  
  Call symput("dur_n", dur_n) ;
  /*put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';*/
  tdur = datetime() - &tiempo_inicio;
   Call symput("tdur",tdur) ;
;run;

proc sql noprint; 
create table &libreria..EMAIL_INFO_&fecha_c. as  
select a.*,cats('',put(&fecha_c,best.),'CGMINF') as CAMPCODE,&fecha_c as periodo
from EMAIL_INFO a
;QUIT; 
              
%put===========================================;
%put [13] Calcula datos cargados ;
%put===========================================;

%let total_reg=0;
proc sql noprint; 
select count(*) into :total_reg
from &libreria..EMAIL_INFO_&fecha_c. a
;QUIT;
%put Registros cargados en tabla  &libreria..EMAIL_INFO_&fecha_c. : &total_reg;

%put==========================================================================================;
%put [14] Cargar base informativa semana en unica ;
%put==========================================================================================;

/*FORMATO PARA CARGAR EN UNICA AUTOMATICO*/
/*1-184.668*/

/* COMENTAR SI ES QUE SE QUIERE PROBAR EL PROCESO SIN INSERT A UNICA:*/

/*LIBNAME UNICA ORACLE SCHEMA='UNICACAR_ADM' USER='UNICACAR_USR' PASSWORD='usr_unicacar'*/
/*PATH="(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=10.0.148.146)(PORT=1521))(CONNECT_DATA=(SERVER=dedicated)(SERVICE_NAME=unicacar)))";*/
/*proc sql;*/
/*INSERT INTO UNICA.UNICA_CARGA_CAMP*/
/*(CAMPCODE, AREA, PRODUCTO, CAMPANA, FECHA, CUSTOMERID,NOMBRE, MODELO, EMAIL,CANAL) */
/*SELECT CAMPCODE, 'SEGMENTOS', 'INFORMATIVA', 'INFORMATIVA',PERIODO, RUT, NOMBRE,SEGMENTO, EMAIL,'EMAIL' */
/*from  &libreria..EMAIL_INFO_&fecha_c. AS A*/
/*;quit;*/




/*FORMATO PARA CARGAR EN UNICA MANUAL*/
/*
LIBNAME UNICA ORACLE SCHEMA='UNICACAR_ADM' USER='UNICACAR_USR' PASSWORD='usr_unicacar'
PATH="(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=10.0.148.146)(PORT=1521))(CONNECT_DATA=(SERVER=dedicated)(SERVICE_NAME=unicacar)))";
proc sql;
INSERT INTO UNICA.UNICA_CARGA_CAMP
(CAMPCODE, AREA, PRODUCTO, CAMPANA, FECHA, CUSTOMERID,NOMBRE, MODELO, EMAIL,CANAL) 
SELECT DISTINCT '20201002CGMINF' , 'SEGMENTOS', 'INFORMATIVA', 'INFORMATIVA',20201002, RUT, NOMBRE,SEGMENTO, EMAIL,'EMAIL' 
from  amunoz.EMAIL_INFO_20201002
;quit;
*/

%put==============================================;
%put[15] declaracion variables  Bitacora;
%put==============================================;

Data _null_;
  tiempo_fin= %sysfunc(datetime());/* inicio del proceso de conteo*/
  Call symput("tiempo_fin",tiempo_fin) ;
  tiempo_fin_c =  put(tiempo_fin,NLDATML32.);
  Call symput("ftiempo_fin_c", tiempo_fin_c) ;
  time_h =  time() ;
  Call symput("ftime_h", time_h) ;
  time_c = put(time_h,Time10.); /*time_h_x = put(time(),IS8601TM8.);*/
  Call symput("ftime_c", time_c) ;
  /*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
  dur_c = compress(put(datetime() - &tiempo_inicio,time13.2));
  Call symput("dur_c", dur_c) ;

 dur_n = input(scan(compress(put(datetime() - &tiempo_inicio,time13.2)),1,":")||"."||scan(compress(put(datetime() - &tiempo_inicio,time13.2)),2,":") ,best32.  );
   Call symput("dur_n", dur_n) ;
  /*put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';*/
  tdur = datetime() - &tiempo_inicio;
   Call symput("tdur",tdur) ;

  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
  execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
  Call symput("fechaeDVN", execDVN) ;

;RUN;


%put &fechaeDVN;/*fecha ejecucion proceso */

%put==============================================================;
%put[16] FECHA FIN PROCESO  &ftiempo_fin_c;
%put==============================================================;


/*
data _null_;
  dur_c = compress(put(datetime() - &tiempo_inicio,time13.2));
  Call symput("dur_c", dur_c) ;
  dur_n = input(scan(compress(put(datetime() - &tiempo_inicio,time13.2)),1,":")||"."||scan(compress(put(datetime() - &tiempo_inicio,time13.2)),2,":") ,best32.  );
  
  Call symput("dur_n", dur_n) ;
  /*put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';*/
  /*tdur = datetime() - &tiempo_inicio;
   Call symput("tdur",tdur) ;
;run;*/

%put============================================;
%put [17] eliminar datos tEmporales ;
%put============================================;

/*Eliminar tablas de paso*/

proc sql noprint;
drop table work.TMP_stock_TR_TAM
;quit;
/**/
proc sql noprint;
drop table work.TMP_RUTERO
;quit;
/**/
proc sql noprint;
drop table work.TMP_DATA
;quit;
/**/
proc sql noprint;
drop table work.TMP_DATA2
;quit;

%put=============================================;
%put[18] ENVÍO DE CORREO CON MAIL VARIABLE ; 
%put============================================;

/*			FIN : CONTROL ANA MUÑOZ			*/
/*	=========================================================================	*/


/*	=========================================================================	*/
/*			INI : CONTROL TIEMPO Y CORREO			*/

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/

proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

quit;

%put &=EDP_BI;
%put &=DEST_1;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
/*TO = ("&DEST_1")*/
TO = ("&DEST_1")
SUBJECT="MAIL_AUTOM: PROCESO INFORMATIVO_SEMANAL" ;
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso INFORMATIVO SEMANAL, ejecutado con fecha: &fechaeDVN";  
 put ; 
 PUT "  Total de Registros Cargados &TOTAL_REG";
 put ; 
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 05'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
%put===========================================;
%put[19] FIN PROCESO ;
%put============================================;

