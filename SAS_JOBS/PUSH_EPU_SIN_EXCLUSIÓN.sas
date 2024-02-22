/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PUSH_EPU_SIN_EXCLUSION		================================*/
/* CONTROL DE VERSIONES
/* 2023-01-19 -- V14 -- Esteban P.	-- Se añade script para utilizar credenciales ocultas.
/* 2022-11-09 -- V13 -- Esteban P.	-- Se cambia la sentencia include a incremental
/* 2022-11-03 -- V12 -- Esteban P.	-- Se añade nueva sentencia include para exportar a RAW.
/* 2022-09-13 -- V11 -- Sergio J.    -- Se añade exportación a aws
/* 2022-05-24 -- V10 -- Sergio J. --
					 -- Se Agrega la lógica para particionar el archivo de salida si los 
						registros son mayores a 10000.
/* 2022-02-25 -- V9 -- Sergio J. --
-- Se cambia la composición de fecha_vencimiento, en vez de usar el campo vencimiento se usa dia_de_pago
	compress(cats("&fechamy0",t1.DIA_DE_PAGO)) AS FECHA_DE_VENCIMIENTO
Para que el formato fecha de los primeros días del mes venga con el formato 20220305,
en vez de 2022035, pues esa fecha da error al cargar la data a firebase
/* 2021-09-22 -- V8 -- Constanza C. --  
					-- Se agrega fecha vencimiento en nombre del archivo y cambios formato rut solicitado por Claudia.
/* 2021-09-07 -- V7 -- David V. --  
					-- Se agrega statement para adjuntar campaña push por correo al equipo de campañas.
/* 2021-06-24 -- V6 -- David V. --  
					-- Se agrega campo 'CAMPANA-IND_RUT_DUP_CAMP'n para nuevo formato de transferencia de archivos.
/* 2021-04-26 -- V5 -- David V. --  
					-- Se agrega sentencia para permitir guión medio en columna
/* 2021-04-20 -- V4 -- David V. --  
					-- Agregar envío de tabla a archivo .csv para nuevo flujo de comunicaciones (Aaraos)
/* 2021-02-12 -- V3 -- Edmundo P. --  
					-- Cambios por Edmundo
/* 2021-01-28 -- V2 -- Sergio J. --  
					-- Cmabio char por best
/* 2021-01-15 -- V1 -- David V. --  
					-- Versión Original
/* INFORMACIÓN:
	Programa tipo con comentarios e instrucciones básicas para ser estandarizadas al equipo.

	(IN) Tablas requeridas o conexiones a BD:
	- PUBLICIN.LOGEO_INT_&fechamy0 (DESDE 0 HASTA &fechamy6)
	- PUBLICIN.CONTRATOS_ITF
	- BD REPORITF 	(user EPIELH)
		- SFRIES_ADM

	(OUT) Tablas de Salida o resultado:
	- PUBLICIN.tmp_push_internet_2
	- ORACLOUD
*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria=PUBLICIN;

OPTIONS VALIDVARNAME=ANY;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/

		DATA _null_;
		datemy0 = input(put(intnx('month',today(),0,'BEGIN'),yymmn6. ),$10.);
		datemy1 = input(put(intnx('month',today(),-1,'BEGIN'),yymmn6. ),$10.);
		datemy2 = input(put(intnx('month',today(),-2,'BEGIN'),yymmn6. ),$10.);
		datemy3 = input(put(intnx('month',today(),-3,'BEGIN'),yymmn6. ),$10.);
		datemy4 = input(put(intnx('month',today(),-4,'BEGIN'),yymmn6. ),$10.);
		datemy5 = input(put(intnx('month',today(),-5,'BEGIN'),yymmn6. ),$10.);
		datemy6 = input(put(intnx('month',today(),-6,'BEGIN'),yymmn6. ),$10.);
	    dated0 = input(put(intnx('day',today(),-3,'SAME'),date9. ),$10.) ;
	    datedx = input(put(intnx('day',today(),0,'SAME'),date9. ),$10.) ;
	    datedN = YEAR(today())*10000+MONTH(today())*100+DAY(today());

		Call symput("fechamy0", datemy0);
		Call symput("fechamy1", datemy1);
		Call symput("fechamy2", datemy2);
		Call symput("fechamy3", datemy3);
		Call symput("fechamy4", datemy4);
		Call symput("fechamy5", datemy5);
		Call symput("fechamy6", datemy6);
	    Call symput("fechad0", dated0);
	    Call symput("fechadx", datedx);
	    Call symput("fechadN", datedN);
		RUN;

		%put &fechamy0;
		%put &fechad0;
		%put &fechadx;
		%put &fechadN;


		/*	1.	CALCULO DIAS MORA*/

proc sql NOPRINT;                              
SELECT USUARIO into :USER 
	FROM sasdyp.user_pass WHERE SCHEMA = 'SFRIES_ADM';
SELECT PASSWORD into :PASSWORD 
	FROM sasdyp.user_pass WHERE SCHEMA = 'SFRIES_ADM';
quit;

LIBNAME R_sfries ORACLE PATH='REPORITF.world' SCHEMA='SFRIES_ADM' USER=&USER. PASSWORD=&PASSWORD.;

PROC SQL;
   CREATE TABLE BASE_SALDO_ITF AS 
   SELECT t1.EVAAM_CIF_ID, 
          t1.EVAAM_NRO_CTT, 
          t1.EVAAM_FCH_PRO,
          SUBSTR(t1.EVAAM_NRO_CTT, 9, 12 )AS CUENTA,
          SUBSTR(t1.EVAAM_NRO_CTT, 5, 4 )AS CENTALTA, 
          t1.EVAAM_SLD_TTL, /*SALDO TOTAL*/
          t1.EVAAM_DIA_MOR /*DIAS MORA A LA FECHA*/
      FROM R_SFRIES.SFRIES_ALT_MOR AS t1
	  WHERE t1.EVAAM_FCH_PRO = "&fechad0:0:0:0"dt /*Ejecutar Validación_de_Saldo*/
;QUIT;

/*	2.	CALCULO DIA DE PAGO*/


PROC SQL;
   CREATE TABLE saldo_epu AS 
   SELECT t2.RUT,t2.DIA_DE_PAGO
      FROM WORK.BASE_SALDO_ITF t1, PUBLICIN.CONTRATOS_ITF t2
      WHERE (input(t1.CUENTA,best.) = input(t2.CUENTA,best.) AND t1.CENTALTA = t2.CENTALTA)

and t1.EVAAM_SLD_TTL>=1
;QUIT;

/*	3.	CLIENTES QUE USAN LA APP*/

PROC SQL;
   CREATE TABLE WORK.LOG_APP AS
   SELECT t1.RUT  FROM PUBLICIN.LOGEO_INT_&fechamy0 t1  WHERE t1.TIPO_LOGUEO = 'APP' UNION 
   
   SELECT t1.RUT  FROM PUBLICIN.LOGEO_INT_&fechamy1 t1  WHERE t1.TIPO_LOGUEO = 'APP' UNION 
   
   SELECT t1.RUT  FROM PUBLICIN.LOGEO_INT_&fechamy2 t1  WHERE t1.TIPO_LOGUEO = 'APP' UNION 
   
   SELECT t1.RUT  FROM PUBLICIN.LOGEO_INT_&fechamy3 t1  WHERE t1.TIPO_LOGUEO = 'APP' UNION 

   SELECT t1.RUT  FROM PUBLICIN.LOGEO_INT_&fechamy4 t1  WHERE t1.TIPO_LOGUEO = 'APP' UNION 
      
   SELECT t1.RUT  FROM PUBLICIN.LOGEO_INT_&fechamy5 t1  WHERE t1.TIPO_LOGUEO = 'APP' UNION 

   SELECT t1.RUT  FROM PUBLICIN.LOGEO_INT_&fechamy6 t1  WHERE t1.TIPO_LOGUEO = 'APP' 
;
QUIT;

/*	4.	CALCULO CLIENTES QUE CORRESPONDE MAIL PAGO EPU + FILTROS*/

PROC SQL;
   CREATE TABLE base_push_epu_app AS 
   SELECT distinct t1.RUT,
   case           
   		  when day("&fechadx"D) in (1,2,3,4,5) then 15
          when day("&fechadx"D) in (6,7,8,9,10) then 20
		  when day("&fechadx"D) in (11,12,13,14,15) then 25
  		  when day("&fechadx"D) in (16,17,18,19,20) then 30
		  when day("&fechadx"D) in (21,22,23,24,25) then 05
                  when day("&fechadx"D) in (26,27,28,29,30) then 10
		  END AS VENCIMIENTO,
	t1.DIA_DE_PAGO
	FROM saldo_epu t1
 	where  t1.RUT IN (SELECT RUT FROM WORK.LOG_APP)
	AND t1.RUT NOT  IN (SELECT RUT FROM PUBLICIN.LNEGRO_CAR)
              HAVING INPUT(t1.DIA_DE_PAGO,BEST.)= VENCIMIENTO
;
QUIT;

/*	5.	SUBO PUSH*/

options cmplib=sbarrera.funcs;

proc sql;
	create table &LIBRERIA..tmp_push_internet_3 as 
		select t1.RUT,
			CATS(put(t1.RUT,commax10.),'-',SB_DV(t1.RUT)) AS RUT_DV,
			t1.VENCIMIENTO,
			t1.DIA_DE_PAGO,
			compress(cats("&fechamy0",t1.DIA_DE_PAGO)) AS FECHA_DE_VENCIMIENTO
		from base_push_epu_app t1
;quit;

proc sql;
	create table &LIBRERIA..tmp_push_internet_2 as 
		select RUT,
			RUT_DV,
			VENCIMIENTO,
			SUBSTR(LEFT(COMPRESS(COMPRESS(RUT_DV,'.'),'-')),1,LENGTH(LEFT(COMPRESS(COMPRESS(RUT_DV,'.'),'-')))) AS RUT_PUSH,
			DIA_DE_PAGO,
			FECHA_DE_VENCIMIENTO
		from &LIBRERIA..tmp_push_internet_3
	;quit;


/*	================================================================== */
/*	==========================	Nuevo Flujo	========================== */
%let USUARIO = sjara;
%put &USUARIO;

DATA _null_;
hoy= compress(tranwrd(put(INTNX('DAY',today() , 0),mmddyy10.),"-",""));
Call symput("fecha", hoy);
RUN;
%put &fecha;

proc sql;
	Create table UNICA_CARGA_CAMP_PUSH_SE (
		'CAMPANA-CAMPCODE'n 	CHAR(200), 		/* OBLIGATORIO SMS / PUSH / EMAIL */
		'CAMPANA-AREA'n 		CHAR(200), 		/* SMS / PUSH / EMAIL */
		'CAMPANA-PRODUCTO'n 	CHAR(200), 		/* SMS / PUSH / EMAIL */
		'CAMPANA-CAMPANA'n 		CHAR(200), 		/* OBLIGATORIO SMS / PUSH / EMAIL */
		'CAMPANA-FECHA'n 		CHAR(38), 		/* SMS / PUSH / EMAIL */
		'CAMPANA-CUSTOMERID'n 	NUMERIC(38),	/* SMS / PUSH / EMAIL */
		'CAMPANA-CANAL'n 		CHAR(50), 		/* SMS / PUSH / EMAIL */
		'CAMPANA-RUT_PUSH'n 	CHAR(200), 		/* PUSH */
		'CAMPANA-ID_USUARIO'n 	NUMERIC(38),	/* OBLIGATORIO SMS / PUSH / EMAIL */
		'CLIENTE-ID_USUARIO'n 	NUMERIC(38),	/* OBLIGATORIO SMS / PUSH / EMAIL */
		'CAMPANA-IND_RUT_DUP_CAMP'n NUMERIC(38),/* OBLIGATORIO SMS / PUSH / EMAIL */
		'CAMPANA-VAR_CAMP_TXT_1'n CHAR(5),		/*DIA_DE_PAGO*/
		'CAMPANA-VAR_CAMP_TXT_2'n CHAR(10)		/*FECHA_DE_VENCIMIENTO*/
		)
	;
quit;

/* INSERT CAMPAÑA --> PUSH */
proc sql NOPRINT;
INSERT INTO UNICA_CARGA_CAMP_PUSH_SE
('CAMPANA-CAMPCODE'n, 'CAMPANA-AREA'n, 'CAMPANA-PRODUCTO'n, 'CAMPANA-CAMPANA'n, 'CAMPANA-FECHA'n, 'CAMPANA-CUSTOMERID'n, 'CAMPANA-CANAL'n, 'CAMPANA-RUT_PUSH'n, 'CAMPANA-ID_USUARIO'n, 'CLIENTE-ID_USUARIO'n, 'CAMPANA-IND_RUT_DUP_CAMP'n , 'CAMPANA-VAR_CAMP_TXT_1'n, 'CAMPANA-VAR_CAMP_TXT_2'n)
SELECT DISTINCT compress(cats("&fechadN",'EPU',PUT(VENCIMIENTO,BEST.))), 'INT', 'EPU', 'PAGO INTERNET',  "&FECHA.", RUT, 'PUSH', RUT_PUSH, RUT, RUT, 0, DIA_DE_PAGO, FECHA_DE_VENCIMIENTO
from &LIBRERIA..tmp_push_internet_2 
;quit;

/* AWS */
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_INCREMENTAL_DIARIO.sas";
%INCREMENTAL(input_firebase_epu_se,work.unica_carga_camp_push_se,pre-raw,oracloud/campaign,0);
/*Macro y lógica para separar los datos si son mayores a 10000*/
proc sql noprint;
select count('CAMPANA-CUSTOMERID'n) into: nruts
from UNICA_CARGA_CAMP_PUSH_SE ;
quit;
%put &nruts;

%macro datasplit();
%if &nruts. LE 10000 %then %do;

/*	PARA OBTENER LA FECHA DE VENCIMIENTO Y AGREGAR DESPUES AL NOMBRE DEL ARCHIVO	*/
proc sql noprint;
	select FECHA_DE_VENCIMIENTO INTO :fecha_venc_nombre_arch
	from &LIBRERIA..tmp_push_internet_2;
quit;

%put &=fecha_venc_nombre_arch;

data _null_;
VAR = COMPRESS('INPUT-FIREBASE_epuDisponibleSE_'||&fecha_venc_nombre_arch.||'_1030.csv'," ",);
call symput("archivo",VAR);
run;

%put &archivo;

/*	EXPORT --> Generación archivo CSV */
PROC EXPORT DATA = UNICA_CARGA_CAMP_PUSH_SE
	/*	OUTFILE="/sasdata/users94/user_bi/unica/input/INPUT-FIREBASE-PAGO_INTERNET_SE-&USUARIO..csv" Esto no deberia ir*/
	OUTFILE="/sasdata/users94/user_bi/unica/input/&archivo."
		DBMS=dlm REPLACE;
	delimiter=',';
	PUTNAMES=YES;
RUN;

/*	EXPORT --> Generación archivo CSV Para enviarselo por correo a equipo de campañas*/
PROC EXPORT DATA = UNICA_CARGA_CAMP_PUSH_SE
	OUTFILE="/sasdata/users94/user_bi/unica/&archivo."
	DBMS=dlm REPLACE;
	delimiter=',';
	PUTNAMES=YES;
RUN;

/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

SELECT EMAIL into :DEST_3
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFATURA_CAMP';

SELECT EMAIL into :DEST_4
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CAMP_1';

SELECT EMAIL into :DEST_5
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CAMP_2';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;
%put &=DEST_5;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_3","&DEST_4","&DEST_5")
CC = ("&DEST_1", "&DEST_2")
SUBJECT = ("MAIL_AUTOM: Proceso PUSH_EPU_SIN_EXCLUSION");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso PUSH_EPU_SIN_EXCLUSION, ejecutado con fecha: &fechaeDVN";  
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT 'El Archivo viene correcto, la cantidad de registros es: &nruts < 10000';
 put 'Proceso Vers. 11 '; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/

%end;
%else %do;

/*Partición de la tabla en 4 partes iguales*/
data push_1 push_2 push_3 push_4;
set UNICA_CARGA_CAMP_PUSH_SE nobs=nobs;
if _N_/nobs <= .25 then output push_1;
else if .25 < _N_/nobs <= .50 then output push_2;
else if .50 < _N_/nobs <= .75 then output push_3;
else output push_4;
run;

/*%put El archivo es muy grande se divide en 4 particiones porque  &nruts. >= 10000;*/

%macro ciclos();
%do i=1 %to 4;

/*	PARA OBTENER LA FECHA DE VENCIMIENTO Y AGREGAR DESPUES AL NOMBRE DEL ARCHIVO	*/
proc sql noprint;
	select FECHA_DE_VENCIMIENTO INTO :fecha_venc_nombre_arch
	from &LIBRERIA..tmp_push_internet_2;
quit;
%put &=fecha_venc_nombre_arch;

/*Variable del archivo de exportación*/
data _null_;
out = COMPRESS('INPUT-FIREBASE_epuDisponibleSE_'||&fecha_venc_nombre_arch.||'_103'||&i.||'.csv'," ",);
call symput("out",out);
run;
%put &out;

/*	EXPORT --> Generación archivo CSV */
PROC EXPORT DATA = push_&i.
	OUTFILE="/sasdata/users94/user_bi/unica/input/&out."
		DBMS=dlm REPLACE;
	delimiter=',';
	PUTNAMES=YES;
RUN;

%end;
%mend ciclos();
%ciclos();


/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

SELECT EMAIL into :DEST_3
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFATURA_CAMP';

SELECT EMAIL into :DEST_4
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CAMP_1';

SELECT EMAIL into :DEST_5
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CAMP_2';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;
%put &=DEST_5;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_3","&DEST_4","&DEST_5")
CC = ("&DEST_1", "&DEST_2")
SUBJECT = ("MAIL_AUTOM: Proceso PUSH_EPU_SIN_EXCLUSION");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso PUSH_EPU_SIN_EXCLUSION, ejecutado con fecha: &fechaeDVN";  
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT 'El archivo es muy grande, se particionó en 4 dado que &nruts > 10000';
 put 'Proceso Vers. 14'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/

%end;
%mend datasplit();
%datasplit();





