/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	SERNAC_INHIB_PARTE_2_AURIS	================================*/
/* CONTROL DE VERSIONES
/* 2022-03-30 -- V12 -- Sergio Jara -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- SE CAMBIA EL NOMBRE Y FORMA DE IMPORTACIÓN.

/* 2022-03-14 -- V11 -- Sergio Jara -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- SE CAMBIA EL NOMBRE Y LA EXTENSION DEL ARCHIVO A AURIS_Inhibicion_Contacto.csv

/* 2022-03-10 -- V10 -- Sergio Jara -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- SE AUTOMATIZA LA IMPORTACIÓN DEL ARCHIVO DESDE EL FTP 82.171

/* 2021-01-25 -- V9 -- Sergio Jara -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- SE CREAN TABLAS EN VES DE VISTAS

/* 2020-01-04 -- V8 -- Sergio Jara -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- ELIMINACIÓN DE RESPALDOS DIARIOS
					-- CAMBIO LIBRERIA DE PASO A EDP_"ENTIDAD CORRESPONDIENTE"

/* 2020-10-28 -- V7 -- Sergio Jara -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- CAMBIO DE INT y CHAR por BEST

/* 2020-10-21 -- V6 -- Sergio Jara -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- Correo Automático a todos los relacionados al proceso

/* 2020-10-21 -- V5 -- Sergio Jara -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- Libreria de respaldo RESULT
					-- Toma los archivos desde user_bi

/* 2020-10-20 -- V4 -- Sergio Jara -- Nueva Versión Automática Equipo Datos y Procesos BI
			        -- Ordena las vistas por FECHA_INGRESO y FECHA_INHIBICION en orden DESCENDENTE
					   (LAS MÁS NUEVAS PRIMERO).

/* 2020-10-16 -- V3 -- Sergio Jara -- Nueva Versión Automática Equipo Datos y Procesos BI
			        -- Genera vistas en vez de tablas.

/* 2020-10-16 -- V2 -- Sergio Jara -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- Toma archivos desde:

/* 2020-10-14 -- V1 -- Sergio Jara -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- Toma archivos desde:
				
/* INFORMACIÓN (AURIS):
	- Toma Libreriafinal y Libreriaresp como variables. 
	- Quedaran respaldadas en libreria RESULT
    - Se dejaran en la ruta sas de USER_BI

 /* (IN) Tablas requeridas o conexiones a BD: (/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/BANCO/)
 	- Tomados:
    - SALIDA_CALIDAD.XLSX

/*	(OUT) Tablas de Salida o resultado:
	- LNEGRO_CALL
	- LNEGRO_SMS
	- LNEGRO_EMAIL
    - LISTA_NEGRA_MAILING
    - LNEGRO_CAR
    

*/
/*==================================================================================================*/

/*-----------------------------------------------------------------------------------------*/
/*--------------       PROCESO INHIBICION AURIS      ----------------*/
/*-----------------------------------------------------------------------------------------*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio = %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*	DECLARACIÓN VARIABLE LIBRERIA	*/
%let libreriaFinal	= PUBLICIN;
%let libreriaResp 	= RESULT;

/* 	DECLARACIÓN VARIABLES FECHAS	*/
DATA _null_;
dateDIA	= compress(substr(put(today(),ddmmyy10.),7,4)||substr(put(today(),ddmmyy10.),4,2)||substr(put(today(),ddmmyy10.),1,2));
Call symput("VdateDIA", dateDIA);
dateMES	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.);
Call symput("VdateMES", dateMES);

RUN;
%put &VdateDIA;
%put &VdateMES;

/*	----------------------- IMPORTACION AUTOMÁTICA DEL ARCHIVO EXCEL, DESDE FTP 192.168.82.171 -----------------	*/

filename server ftp 'AURIS_Inhibicion_Contacto.txt' CD='/'
       HOST='192.168.82.171' user='194893337' pass='194893337' PORT=21;
data _null_;   infile server;
    file '/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/AURIS/AURIS_Inhibicion_Contacto.txt';
    input;
    put _infile_;
    run;

options validvarname=any;

/*	----------------------- IMPORTACION DE ARCHIVO TXT, DESDE FTP SAS -----------------	*/
DATA WORK.SALIDA_CALIDAD;
    INFILE '/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/AURIS/AURIS_Inhibicion_Contacto.txt'
        ENCODING="utf-8" delimiter=";" firstobs=2 MISSOVER DSD lrecl=32767;
 INFORMAT
        CANAL_DE_INGRESO $CHAR16.
        FECHA_CREACION_TRASLADO DATETIME18.
        AURIS            BEST9.
        RUT_SIN_DV       BEST8.
        DESCRIPCION_2    $CHAR29.
        DESCRIPCION_3    $CHAR9.
        GES_AVANCE_1     $CHAR9.
        FECHA_TERMINO    $CHAR19.
        Canal_a_Inhibir  $CHAR21.
        Nro_Telefonico_a_Inhibir $CHAR22.
        Domicilio_a_Inhibir $CHAR55.
        Email_a_Inhibir  $CHAR32. ;
    FORMAT
        CANAL_DE_INGRESO $CHAR16.
        FECHA_CREACION_TRASLADO DATETIME18.
        AURIS            BEST9.
        RUT_SIN_DV       BEST8.
        DESCRIPCION_2    $CHAR29.
        DESCRIPCION_3    $CHAR9.
        GES_AVANCE_1     $CHAR9.
        FECHA_TERMINO    $CHAR19.
        Canal_a_Inhibir  $CHAR21.
        Nro_Telefonico_a_Inhibir $CHAR22.
        Domicilio_a_Inhibir $CHAR55.
        Email_a_Inhibir  $CHAR32. ;

    INPUT
        CANAL_DE_INGRESO : $CHAR16.
        FECHA_CREACION_TRASLADO : ?? ANYDTDTM19.
        AURIS            : ?? BEST9.
        RUT_SIN_DV       : ?? BEST8.
        DESCRIPCION_2    : $CHAR29.
        DESCRIPCION_3    : $CHAR9.
        GES_AVANCE_1     : $CHAR9.
        FECHA_TERMINO    : $CHAR19.
        Canal_a_Inhibir  : $CHAR21.
        Nro_Telefonico_a_Inhibir : $CHAR22.
        Domicilio_a_Inhibir : $CHAR55.
        Email_a_Inhibir  : $CHAR32. ;
RUN;

PROC SQL;
	UPDATE SALIDA_CALIDAD
	SET Nro_Telefonico_a_Inhibir = COMPRESS(TRANWRD(Nro_Telefonico_a_Inhibir,'-',''))
;QUIT;

PROC SQL;
   CREATE TABLE WORK.SALIDA_CALIDAD_2
   AS 
   SELECT INPUT(t1.Nro_Telefonico_a_Inhibir,BEST.) AS Nro_Telefonico_a_Inhibir,
   			t1.*
      FROM SALIDA_CALIDAD t1;
QUIT;

/*				LECTURA CASOS				*/
PROC SQL;
   CREATE TABLE WORK.FORMATO AS
   SELECT t1.RUT_SIN_DV,
   			t1.Canal_a_Inhibir,
			t1.Nro_Telefonico_a_Inhibir,
          	t1.Domicilio_a_Inhibir AS DOMICILIO,
/*			t1.Email_a_Inhibir LIKE ('%@%') THEN 1 ELSE 0 END AS HC*/

          	t1.Email_a_Inhibir AS EMAIL, /*	  t1.EMAIL LIKE ('%@%')	  */
			case when t1.Nro_Telefonico_a_Inhibir >= 900000000 then substr(put(t1.Nro_Telefonico_a_Inhibir,best.),4,1)
			   when t1.Nro_Telefonico_a_Inhibir > 300000000 then substr(put(t1.Nro_Telefonico_a_Inhibir,best.),4,2)
		       when t1.Nro_Telefonico_a_Inhibir < 300000000 AND t1.Nro_Telefonico_a_Inhibir > 99999999 then substr(put(t1.Nro_Telefonico_a_Inhibir,best.),4,1)  
			   when t1.Nro_Telefonico_a_Inhibir < 99999999 AND t1.Nro_Telefonico_a_Inhibir > 0 then '9'
			   when t1.Nro_Telefonico_a_Inhibir = . then '.' /* CORREGIR */
               end as AREA,
			case when t1.Nro_Telefonico_a_Inhibir >= 900000000 then substr(put(t1.Nro_Telefonico_a_Inhibir,best.),5,8)
		       when t1.Nro_Telefonico_a_Inhibir < 300000000 then substr(put(t1.Nro_Telefonico_a_Inhibir,best.),5,8) 
			   else  substr(put(t1.Nro_Telefonico_a_Inhibir,best.),6,7)  
               end as FONO
      FROM WORK.SALIDA_CALIDAD_2 t1;
QUIT;

/*		------------------------------		NUEVOS LN		--------------------------		*/

DATA _null_;
date = put(today(),date10.);
date2 = put(today(),ddmmyy10.);
Call symput("fecha", date);
Call symput("fecha2", date2);
RUN;
%put &fecha;


/*============================================================================================*/
/*	----------------	INICIO: LNEGRO_CALL		-----------------	*/

/*	----------------	INI: RESPALDO DE LA BASE		-----------------	*/
proc sql;
create table &libreriaResp..LNEGRO_CALL_RESPALDO_&VdateMES AS
SELECT *
FROM &libreriaFinal..LNEGRO_CALL
;QUIT;

/*	----------------	FIN: RESPALDO DE LA BASE		-----------------	*/

PROC SQL;
   CREATE TABLE WORK.NUEVOS_LNEGRO_CALL AS 
   SELECT DISTINCT t1.RUT_SIN_DV AS RUT,
		          INPUT(COMPRESS(t1.area),BEST.) AS AREA,
				  INPUT(COMPRESS(t1.FONO),BEST.) as FONO,
				  'LISTA_NEGRA_CALL' AS TIPO_INHIBICION,
				  'AURIS' AS CANAL_RECLAMO,
				  "&fecha"d FORMAT = DATE10. AS FECHA_INGRESO
	FROM WORK.FORMATO t1
		WHERE t1.Canal_a_Inhibir = 'Gestiones Telefónicas'
;QUIT;

proc sql;
create table LNEGRO_CALL2 AS
SELECT *
FROM &libreriaFinal..LNEGRO_CALL
;QUIT;

PROC SQL;
	INSERT INTO LNEGRO_CALL2
	SELECT *
	FROM WORK.NUEVOS_LNEGRO_CALL
;QUIT;

PROC SQL;
CREATE TABLE &libreriaFinal..EDP_CALL AS
	SELECT RUT,AREA,FONO,TIPO_INHIBICION,CANAL_RECLAMO,
	       MIN(FECHA_INGRESO) FORMAT=DATE9. AS FECHA_INGRESO /*VERIFICAR*/
	FROM LNEGRO_CALL2
	GROUP BY RUT,FONO,TIPO_INHIBICION,CANAL_RECLAMO
	ORDER BY FECHA_INGRESO
;QUIT;

PROC SQL;
    CREATE TABLE &libreriaFinal..LNEGRO_CALL AS      /*VISTA*/
	SELECT *
	FROM &libreriaFinal..EDP_CALL
	ORDER BY FECHA_INGRESO DESC
;QUIT;

/*	----------------	FIN: LNEGRO_CALL	-----------------	*/
/*============================================================================================*/


/*============================================================================================*/
/*	----------------	INICIO: LNEGRO_SMS		-----------------	*/
/*	----------------	INI: RESPALDO DE LA BASE		-----------------	*/
proc sql;
create table &libreriaResp..LNEGRO_SMS_RESPALDO_&VdateMES AS
SELECT *
FROM &libreriaFinal..LNEGRO_SMS
;QUIT;


/*	----------------	FIN: RESPALDO DE LA BASE		-----------------	*/

PROC SQL;
   CREATE TABLE WORK.NUEVOS_LNEGRO_SMS AS 
   SELECT DISTINCT t1.RUT_SIN_DV AS RUT,
				  INPUT(COMPRESS(t1.FONO),BEST.) as FONO,
				  'LISTA_NEGRA_SMS' AS TIPO_INHIBICION,
				  'AURIS' AS CANAL_RECLAMO,
				  "&fecha"d FORMAT = DATE10. AS FECHA_INGRESO
	FROM WORK.FORMATO t1
	WHERE t1.Canal_a_Inhibir = 'SMS'
;QUIT;

proc sql;
create table LNEGRO_SMS2 AS
SELECT *
FROM &libreriaFinal..LNEGRO_SMS
;QUIT;

PROC SQL;
	INSERT INTO LNEGRO_SMS2
	SELECT *
	FROM NUEVOS_LNEGRO_SMS
;QUIT;

PROC SQL;
CREATE TABLE &libreriaFinal..EDP_SMS AS
	SELECT RUT,FONO,TIPO_INHIBICION,CANAL_RECLAMO,
	       MIN(FECHA_INGRESO) FORMAT=DATE9. AS FECHA_INGRESO
	FROM LNEGRO_SMS2
	GROUP BY RUT,FONO,TIPO_INHIBICION,CANAL_RECLAMO
	ORDER BY FECHA_INGRESO
;QUIT;

PROC SQL;
    CREATE TABLE &libreriaFinal..LNEGRO_SMS AS      /*VISTA*/
	SELECT *
	FROM &libreriaFinal..EDP_SMS
	ORDER BY FECHA_INGRESO DESC
;QUIT;
/*	----------------	FIN: LNEGRO_SMS	-----------------	*/
/*============================================================================================*/


/*============================================================================================*/
/*	----------------	INICIO: LNEGRO_EMAIL	-----------------	*/

/*	----------------	INI: RESPALDO DE LA BASE		-----------------	*/
proc sql;
create table &libreriaResp..LNEGRO_EMAIL_RESPALDO_&VdateMES AS
SELECT *
FROM &libreriaFinal..LNEGRO_EMAIL
;QUIT;


/*	----------------	FIN: RESPALDO DE LA BASE		-----------------	*/

PROC SQL;
   CREATE TABLE WORK.NUEVOS_LNEGRO_EMAIL AS 
   SELECT DISTINCT t1.RUT_SIN_DV,
				   UPCASE(COMPRESS(t1.EMAIL)) AS EMAIL,
				   'AURIS' AS MOTIVO,
				   "&fecha"d FORMAT = DATE10. AS FECHA_INHIBICION
	FROM WORK.FORMATO t1
	WHERE t1.Canal_a_Inhibir = 'Email'
	AND UPCASE(COMPRESS(T1.EMAIL)) NOT IN (SELECT EMAIL FROM PUBLICIN.LNEGRO_EMAIL)
;QUIT;

PROC SQL;
create table LNEGRO_EMAIL2 AS
SELECT *
FROM &libreriaFinal..LNEGRO_EMAIL
;QUIT;

PROC SQL;
	INSERT INTO LNEGRO_EMAIL2
	SELECT *
	FROM WORK.NUEVOS_LNEGRO_EMAIL
;QUIT;

PROC SQL;
CREATE TABLE &libreriaFinal..EDP_EMAIL AS
	SELECT RUT,EMAIL,MOTIVO,
	       MIN(FECHA_INHIBICION) FORMAT=DATE9. AS FECHA_INHIBICION /*VERIFICAR*/
	FROM LNEGRO_EMAIL2
	GROUP BY RUT,EMAIL,MOTIVO
	ORDER BY FECHA_INHIBICION
;QUIT;

PROC SQL;
    CREATE TABLE &libreriaFinal..LNEGRO_EMAIL AS      /*VISTA*/
	SELECT *
	FROM &libreriaFinal..EDP_EMAIL
	ORDER BY FECHA_INHIBICION DESC
;QUIT;
/*	----------------	FIN: LNEGRO_EMAIL	-----------------	*/
/*============================================================================================*/


/*============================================================================================*/
/*	----------------	INICIO: LNEGRO_MAILING	-----------------	*/

/*	----------------	INI: RESPALDO DE LA BASE		-----------------	*/
proc sql;
create table &libreriaResp..LISTA_NEGRA_MAILING_&VdateMES AS
SELECT *
FROM &libreriaFinal..LISTA_NEGRA_MAILING
;QUIT;


/*	----------------	FIN: RESPALDO DE LA BASE		-----------------	*/

PROC SQL;
   CREATE TABLE WORK.NUEVOS_LNEGRO_MAILING AS 
   SELECT DISTINCT t1.RUT_SIN_DV,
				  'LISTA_NEGRA_MAILING' AS TIPO_INHIBICION,
				  'AURIS' AS CANAL_RECLAMO,
				  "&fecha"d FORMAT = DATE10. AS FECHA_INGRESO
	FROM WORK.FORMATO t1
	WHERE t1.Canal_a_Inhibir = 'Domicilio'
	AND T1.RUT_SIN_DV NOT IN (SELECT RUT FROM PUBLICIN.LISTA_NEGRA_MAILING)
;QUIT;

proc sql;
create table LISTA_NEGRA_MAILING2 AS
SELECT *
FROM &libreriaFinal..LISTA_NEGRA_MAILING
;QUIT;


PROC SQL;
	INSERT INTO LISTA_NEGRA_MAILING2
	SELECT *
	FROM NUEVOS_LNEGRO_MAILING
;QUIT;


PROC SQL;
CREATE TABLE &libreriaFinal..EDP_MAILING AS
	SELECT RUT,TIPO_INHIBICION,CANAL_RECLAMO,
	       MIN(FECHA_INHIBICION) FORMAT=DATE9. AS FECHA_INHIBICION /*VERIFICAR*/
	FROM LISTA_NEGRA_MAILING2
	GROUP BY RUT,TIPO_INHIBICION,CANAL_RECLAMO
	ORDER BY FECHA_INHIBICION
;QUIT;

PROC SQL;
    CREATE TABLE &libreriaFinal..LISTA_NEGRA_MAILING AS      /*VISTA*/
	SELECT *
	FROM &libreriaFinal..EDP_MAILING
	ORDER BY FECHA_INHIBICION DESC
;QUIT;
/*	----------------	FIN: LNEGRO_MAILING	-----------------	*/
/*============================================================================================*/


/*============================================================================================*/
/*	----------------	INICIO: LNEGRO_CAR	-----------------	*/

/*	----------------	INI: RESPALDO DE LA BASE		-----------------	*/
proc sql;
create table &libreriaResp..LNEGRO_CAR_RESPALDO_&VdateMES AS
SELECT *
FROM &libreriaFinal..LNEGRO_CAR
;QUIT;


/*	----------------	FIN: RESPALDO DE LA BASE		-----------------	*/
PROC SQL;
   CREATE TABLE NUEVOS_LNEGRO_CAR AS 
   SELECT DISTINCT t1.RUT_SIN_DV,
				  'LISTA_NEGRA_CAR' AS TIPO_INHIBICION,
				  'AURIS' AS CANAL_RECLAMO,
				  "&fecha"d FORMAT = DATE10. AS FECHA_INGRESO
	FROM WORK.FORMATO t1
	WHERE t1.Canal_a_Inhibir = 'Todas las anteriores'
	AND T1.RUT_SIN_DV NOT IN (SELECT RUT FROM PUBLICIN.LNEGRO_CAR)
;QUIT;

proc sql;
create table LNEGRO_CAR2 AS
SELECT *
FROM &libreriaFinal..LNEGRO_CAR
;QUIT;

PROC SQL;
	INSERT INTO LNEGRO_CAR2
	SELECT *
	FROM NUEVOS_LNEGRO_CAR
;QUIT;

PROC SQL;
CREATE TABLE &libreriaFinal..EDP_CAR AS
	SELECT RUT,TIPO_INHIBICION,CANAL_RECLAMO,
	       MIN(FECHA_INGRESO) FORMAT=DATE9. AS FECHA_INGRESO /*VERIFICAR*/
	FROM LNEGRO_CAR2
	GROUP BY RUT,TIPO_INHIBICION,CANAL_RECLAMO
	ORDER BY FECHA_INGRESO
;QUIT;

PROC SQL;
    CREATE TABLE &libreriaFinal..LNEGRO_CAR AS      /*VISTA*/
	SELECT *
	FROM &libreriaFinal..EDP_CAR
	ORDER BY FECHA_INGRESO DESC
;QUIT;
/*	----------------	FIN: LNEGRO_CAR	-----------------	*/
/*============================================================================================*/


/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
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

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

SELECT EMAIL into :DEST_2 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_3 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'MARCELO_ANTONELLI';

SELECT EMAIL into :DEST_4 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JOSE_RIVEROS';

SELECT EMAIL into :DEST_5 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'RODRIGO_PEREZ';

SELECT EMAIL into :DEST_6 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'GABRIELA_PARRAGUEZ';

SELECT EMAIL into :DEST_7 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'CRISTIAN_VILLAREAL';

SELECT EMAIL into :DEST_8 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PAOLA_FUENZALIDA';

;quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;
%put &=DEST_5;
%put &=DEST_6;
%put &=DEST_7;
%put &=DEST_8;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_2","&DEST_3","&DEST_4","&DEST_5","&DEST_6","&DEST_7","&DEST_8")
/*CC = ("&DEST_2")*/
SUBJECT = ("MAIL_AUTOM: PROCESO AURIS ");
FILE OUTBOX;
 PUT "Estimados:";
 put "    Proceso AURIS, ejecutado con fecha: &fechaeDVN";  
 put ; 
 PUT ;
 put ; 
 PUT ;
 put 'Proceso Vers. 12'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
