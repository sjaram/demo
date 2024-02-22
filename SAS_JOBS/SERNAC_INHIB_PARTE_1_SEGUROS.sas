/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	SERNAC_INHIB_PARTE_1_SEGUROS================================*/
/* CONTROL DE VERSIONES
/* 2022--10-17-- V13 -- Sergio.J -- 
					 -- Se agrega sentencia NOERRORSTOP

/* 2022--01-07-- V12 -- Sergio.J -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- Agrega Validación par contar registros de entrada y salida para telefonos y emails.

/* 2021-12-30 -- V11 -- Sergio.J -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- Agrega Validación par ver si el archivo de inhibición está actualizado.

/* 2021-07-27 -- V10 -- Sergio.J -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- SE DEJA EL EMAIL EN MAYUSCULA

/* 2021-01-25 -- V9 -- Sergio.J -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- SE CREAN TABLAS EN DURO EN VEZ DE VISTAS

/* 2020-01-04 -- V8 -- Sergio.J -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- SE ELIMINAN RESPALDOS DIARIOS

/* 2020-11-30 -- V7 -- Sergio.J -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- SE CAMBIA LIBRERIA DE TABLAS DE PASO A "PUBLICIN"

/* 2020-11-27 -- V6 -- Sergio.J -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- SE CREA TABLA DE PASO EDP_CALL, EDP_SMS y EDP_EMAIL

/* 2020-11-16 -- V5 -- Sergio.J -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- SE ELIMINA TEST DEL ASUNTO

/* 2020-10-23 -- V4 -- Sergio.J -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- Se agrega el código "OPTIONS VALIDVARNAME= any"
					-- Para que el archivo de entrada se adapte al lenguaje SAS
					-- Cambia CHAR POR BEST

/* 2020-10-19 -- V3 -- Sergio.J -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- Crea vistas en el Paso a Libreria Final en vez de tablas
             		-- Las vistas son para CALL, SMS Y EMAIL

/* 2020-10-06 -- V2 -- David.V -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- Toma archivos desde FTP SAS
					-- Variable macro de librería final
					-- Toma Ruts de tablas publicin.fonos_SE (móvil y fijo)
					-- Registra en log tiempo de ejecución
					-- Envío de Mail notificando conversión y traspaso de archivos salidas a FTP
					-- Respaldo de Versiones día anterior y mensual
					-- Optimizar espacio campo email a 50 caracteres
/* INFORMACIÓN:
/* Tablas que actualiza el proceso
	- LNEGRO_CALL
	- LNEGRO_SMS
	- LNEGRO_EMAIL

 /* Archivos tomados y depositados en: /sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SEGUROS/ 
 	- Tomados
		- bloqueos_telefonos.csv
		- bloqueos_mails.csv
 	- Depositados
		- telefonos_'||fecha||'.csv
		- mails_'||fecha||'.csv'

*/
/*==================================================================================================*/

/*-----------------------------------------------------------------------------------------*/
/*--------------       PROCESO INHIBICION SERNAC - PORTAL NO MOLESTAR      ----------------*/
/*-----------------------------------------------------------------------------------------*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio = %sysfunc(datetime()); /* inicio del proceso de conteo*/


x cd /sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SEGUROS;
x ls -l bloqueos_mails.csv > actualizacion_bl_ml.txt;

data work.actualizacion;
   infile  "/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SEGUROS/actualizacion_bl_ml.txt" truncover;
    input variable  $2000.;   
run;

proc sql noprint; 
select input(scan(variable,7," ")||scan(variable,6," ")|| put(year(today()),best4.),date9.) format=date9.,
today() format=date9.
into: fecha_archivo,: fecha_hoy
from actualizacion;
quit;

%put &fecha_archivo;
%put &fecha_hoy;

%macro enviacorreo();
%if &fecha_archivo. ~= &fecha_hoy. %then %do;
%put noejecuta, &fecha_archivo <> &fecha_hoy;

/*=========================================================================================*/
/*========     FECHA PROCESO Y AVISO DE DESCACTUALIZACION POR EMAIL     ===================*/

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

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&DEST_1")
TO = ("&DEST_1", "&DEST_2","lmontalbab@bancoripley.com","asierrag@bancoripley.com")
SUBJECT = ("WARNING, ARCHIVO PROCESO SERNAC DESACTUALIZADO - SEGUROS");
FILE OUTBOX;
 PUT "Estimados, ¡Urgente!:";
 PUT " El proceso Sernac NO SE EJECUTA, &fecha_archivo ~= &fecha_hoy";
 put ; 
 put '    La Causa:'; 
 put '    Los archivos tomados desde: /sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SEGUROS/'; 
 put ;
 PUT "        bloqueos_telefonos.csv y bloqueos_mails.csv";
 PUT ;
 PUT "        ¡NO ESTAN ACTUALIZADOS!";
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 13'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
 
%end;
%else %do;

/*	DECLARACIÓN VARIABLE LIBRERIA	*/
%let libreria = PUBLICIN;

/*	DECLARACIÓN VARIABLE LIBRERIA	*/
%let EDP_LIBRERIA = PUBLICIN;

/* 	DECLARACIÓN VARIABLES FECHAS	*/
DATA _null_;
dateDIA	= compress(substr(put(today(),ddmmyy10.),7,4)||substr(put(today(),ddmmyy10.),4,2)||substr(put(today(),ddmmyy10.),1,2));
Call symput("VdateDIA", dateDIA);
dateMES	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.);
Call symput("VdateMES", dateMES);

RUN;
%put &VdateDIA;
%put &VdateMES;

/*-----------------------------------------------------------------------------------------*/
/*---------------------------------- INICIO: RESPALDOS DATOS ANTERIORES  ------------------*/

proc sql;
	create table RESULT.LNEGRO_EMAIL_&VdateMES AS
		SELECT * FROM &libreria..LNEGRO_EMAIL
;quit;


proc sql;
	create table RESULT.LNEGRO_CALL_&VdateMES AS
		SELECT * FROM &libreria..LNEGRO_CALL
;quit;

proc sql;
	create table RESULT.LNEGRO_SMS_&VdateMES AS
		SELECT * FROM &libreria..LNEGRO_SMS
;quit;
/*---------------------------------- FIN: RESPALDOS DATOS ANTERIORES  ---------------------*/
/*-----------------------------------------------------------------------------------------*/

/*---------------------------------- ADAPTACIÓN DATOS DE ENTRADA A LENGUAJE SAS  ---------------------*/

OPTIONS VALIDVARNAME=ANY;

/*	----------------------- IMPORTACION DE ARCHIVO CSV, TODAS LAS ENTRADAS -----------------	*/
DATA WORK.DATASTEP_BLOQUEOS;
INFILE '/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SEGUROS/bloqueos_telefonos.csv'
	DELIMITER=';'
	FIRSTOBS=2
	MISSOVER
	DSD
	LRECL=32767;

	FORMAT 'Id bloqueo'n best12.
	 Telefono best12.
	 'Canales bloqueados'n $30.
	 Correo $1.
	 'Fecha de solicitud'n DATETIME18.
	 'Dias transcurridos'n best12.
	 'Estado descarga'n $20.
	 'Ingrese resultado del bloqueo'n $1.
	 'Fecha asignación'n $1.
	 Respuesta $5.;
	 
INPUT 'Id bloqueo'n
	  Telefono
	  'Canales bloqueados'n $ 
      Correo
      'Fecha de solicitud'n : ?? ANYDTDTM19.
      'Dias transcurridos'n 
      'Estado descarga'n $
      'Ingrese resultado del bloqueo'n $
      'Fecha asignación'n $
      Respuesta $
;RUN;

/*Contar registros ingresados para teléfonos*/

proc sql;
create table q_entrada_telefonos as
select count(telefono) as telefonos_ingresados
from DATASTEP_BLOQUEOS;
quit;

/*-----------------------------------------------------------------------------------------*/
/*----------------------------------       FONOS      -------------------------------------*/
PROC SQL;
   CREATE TABLE input_sernac AS 
   SELECT t1.'Id bloqueo'n, 
          t1.Telefono, 
          t1.'Canales bloqueados'n, 
          t1.Correo length=50, 
          t1.'Fecha de solicitud'n, 
          t1.'Dias transcurridos'n, 
          t1.'Estado descarga'n, 
		  case when t1.Telefono >= 56900000000 then 'CE'
		       when t1.Telefono < 56300000000 then 'FIJO' 
			   else 'FIJO'  
               end as TIPO_FONO,
		  case when t1.Telefono >= 56900000000 then substr(put(t1.Telefono,best.),4,1)
		       when t1.Telefono < 56300000000 then substr(put(t1.Telefono,best.),4,1) 
			   else  substr(put(t1.Telefono,best.),4,2)  
               end as area,
          case when t1.Telefono >= 56900000000 then substr(put(t1.Telefono,best.),5,8)
		       when t1.Telefono < 56300000000 then substr(put(t1.Telefono,best.),5,8) 
			   else  substr(put(t1.Telefono,best.),6,7)  
               end as fono_normalizado,		 
		  case when t1.'Canales bloqueados'n like '%Llamada:1%' then 1 else 0 end as inhibir_call,
          case when t1.'Canales bloqueados'n like '%Sms:1%' then 1 else 0 end as inhibir_sms,
		  t1.'Ingrese resultado del bloqueo'n,
		  t1.'Fecha asignación'n,
		  t1.Respuesta
      FROM DATASTEP_BLOQUEOS t1;
QUIT;


PROC SQL;
   CREATE TABLE INPUT_SERNAC_FORM AS 
   SELECT t1.'Id bloqueo'n, 
          t1.Telefono, 
          t1.'Canales bloqueados'n, 
          t1.Correo length=50, 
          t1.'Fecha de solicitud'n, 
          t1.'Dias transcurridos'n, 
          t1.'Estado descarga'n, 
          t1.TIPO_FONO, 
          INPUT(t1.area,best.) AS AREA, 
          INPUT(t1.fono_normalizado,best.) AS FONO, 
          t1.inhibir_call, 
          t1.inhibir_sms,
		  t1.'Ingrese resultado del bloqueo'n,
		  t1.'Fecha asignación'n,
		  t1.Respuesta
      FROM INPUT_SERNAC t1;
QUIT;


PROC SQL;
   CREATE TABLE CRUCE_FONOS AS 
   SELECT t1.'Id bloqueo'n, 
          t1.Telefono, 
          t1.'Canales bloqueados'n, 
          t1.Correo length=50, 
          t1.'Fecha de solicitud'n, 
          t1.'Dias transcurridos'n, 
          t1.'Estado descarga'n, 
          t1.TIPO_FONO, 
          t1.area, 
          t1.FONO, 
          t1.inhibir_call, 
          t1.inhibir_sms,
		  t1.'Ingrese resultado del bloqueo'n,
		  t1.'Fecha asignación'n,
		  t1.Respuesta,
		  COALESCE(T2.CLIRUT, T3.CLIRUT, T4.RUT) AS RUT
      FROM INPUT_SERNAC_FORM t1
           LEFT JOIN PUBLICIN.FONOS_MOVIL_FINAL_SE t2 ON t1.area = t2.AREA AND t1.FONO = t2.TELEFONO
           LEFT JOIN PUBLICIN.FONOS_FIJOS_FINAL_SE t3 ON t1.area = t3.AREA AND t1.FONO = t3.TELEFONO
           LEFT JOIN PUBLICIN.REPOSITORIO_TELEFONOS t4 ON t1.FONO = t4.TELEFONO
;QUIT;


DATA _null_;
date = put(today(),date10.);
Call symput("fecha", date);
RUN;
%put &fecha;


PROC SQL;
   CREATE TABLE NUEVOS_LNEGRO_CALL AS 
  SELECT DISTINCT T1.RUT,
		          T1.AREA,
				  T1.FONO,
				  'SERNAC_SEGUROS' AS TIPO_INHIBICION,	
				  'PORTAL_SERNAC' AS CANAL_RECLAMO,
				  "&fecha"d FORMAT = DATE10. AS FECHA_INGRESO
	from CRUCE_FONOS t1
	WHERE inhibir_call=1
;QUIT;


PROC SQL;
CREATE TABLE LNEGRO_CALL_PRE AS
	SELECT *
	FROM NUEVOS_LNEGRO_CALL
UNION
   SELECT *
	FROM &libreria..LNEGRO_CALL
ORDER BY FECHA_INGRESO
;QUIT;


PROC SQL;
CREATE TABLE LNEGRO_CALL AS 
	SELECT DISTINCT RUT,AREA,FONO,TIPO_INHIBICION,CANAL_RECLAMO,
	       MIN(FECHA_INGRESO) FORMAT=DATE9. AS FECHA_INGRESO
	FROM LNEGRO_CALL_PRE
	GROUP BY RUT,AREA,FONO,TIPO_INHIBICION,CANAL_RECLAMO
	ORDER BY FECHA_INGRESO
;QUIT;


/*-----------------------------------------------------------------------------------------*/
/*----------------------------------       SMS      ---------------------------------------*/
PROC SQL;
	CREATE TABLE NUEVOS_LNEGRO_SMS AS 
		SELECT DISTINCT T1.RUT, 
					  T1.FONO,
					  'SERNAC_SEGUROS' AS TIPO_INHIBICION,
					  'PORTAL_SERNAC' AS CANAL_RECLAMO,
					  "&fecha"d  format=date10. AS FECHA_INGRESO
		FROM CRUCE_FONOS t1
		WHERE inhibir_sms=1	AND TIPO_FONO = 'CE'   
;QUIT;

PROC SQL;
CREATE TABLE LNEGRO_SMS_PRE AS
	SELECT *
	FROM NUEVOS_LNEGRO_SMS
UNION 
   SELECT *
	from &libreria..LNEGRO_SMS
ORDER BY FECHA_INGRESO
;QUIT;

PROC SQL;
CREATE TABLE LNEGRO_SMS AS	
	SELECT DISTINCT RUT,fono,TIPO_INHIBICION,CANAL_RECLAMO,
	       MIN(FECHA_INGRESO) FORMAT=DATE9. AS FECHA_INGRESO
	FROM LNEGRO_SMS_PRE
	GROUP BY RUT,fono,TIPO_INHIBICION,CANAL_RECLAMO
	ORDER BY FECHA_INGRESO
;QUIT;


/*-----------------------------------------------------------------------------------------*/
/*---------------------------------- INICIO: PASO LIBRERÍA FINAL  -------------------------*/
PROC SQL;
     CREATE TABLE &EDP_LIBRERIA..EDP_CALL AS
     SELECT *
     FROM LNEGRO_CALL
     ORDER BY FECHA_INGRESO
;QUIT;

PROC SQL NOERRORSTOP;
    CREATE TABLE &libreria..LNEGRO_CALL AS      /*VISTA*/
	SELECT *
	FROM &EDP_LIBRERIA..EDP_CALL
	ORDER BY FECHA_INGRESO DESC
;QUIT;

PROC SQL;
	CREATE TABLE &EDP_LIBRERIA..EDP_SMS AS
	SELECT *
	FROM LNEGRO_SMS
	ORDER BY FECHA_INGRESO
;QUIT;

PROC SQL NOERRORSTOP; 
	CREATE TABLE &libreria..LNEGRO_SMS AS      /*VISTA*/
	SELECT *
	FROM &EDP_LIBRERIA..EDP_SMS
	ORDER BY FECHA_INGRESO DESC
;QUIT;
/*----------------------------------  FIN: PASO LIBRERÍA FINAL  ---------------------------*/
/*-----------------------------------------------------------------------------------------*/


/*-----------------------------------------------------------------------------------------*/
/*-------------------------------    FORMATO PARA SALIDA  ---------------------------------*/
PROC SQL;
   CREATE TABLE SALIDA_TELEFONOS AS
   SELECT DISTINCT t1.'Id bloqueo'n, 
		  COMPRESS('+'||PUT(Telefono,BEST.)) AS Telefono,
          t1.'Canales bloqueados'n, 
          t1.Correo length=50, 
		  cat((put(intnx('month',datepart(t1.'Fecha de solicitud'n),0,'same'),yymmdd10.)),' ',(put(intnx('month',timepart(t1.'Fecha de solicitud'n),0,'same'),hhmm8.2))) AS 'Fecha de solicitud'n,
          t1.'Dias transcurridos'n, 
          t1.'Estado descarga'n, 
		  case when rut is null then COMPRESS(PUT(5,BEST.))
			   else COMPRESS(PUT(1,BEST.))
          end as 'Ingrese resultado del bloqueo'n,
          t1.'Fecha asignación'n,
          t1.Respuesta
    FROM CRUCE_FONOS t1;
QUIT;

/*Count Telefonos inhibidos para respuesta a SERNAC*/
proc sql;
create table q_salida_telefonos as
select count(telefono) as salida_telefonos
from salida_telefonos;
quit;

/*-----------------------------------------------------------------------------------------*/
/*----------------------------------  INICIO: EXPORT	-----------------------------------*/
DATA _null_;
  %let _EFIERR_ = 0;	/* set the ERROR detection macro variable 	*/
  %let _EFIREC_ = 0;	/* clear export record count macro variable */

 fecha = put(today(),yymmdd10.);
 salida = COMPRESS('/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SEGUROS/telefonos_'||fecha||'.csv');
 FILE phod filevar = SALIDA notitles

 delimiter=';'
 DSD
 DROPOVER
 ENCODING=UTF8
 lrecl=32767;
             if _n_ = 1 then        /* write column names or labels */
              do;
                put
                "Id bloqueo"
                ';'
                 "Telefono"
                ';'
                "Canales bloqueados"
                ';'
                "Correo"
                ';'
                "Fecha de solicitud"
                ';'
                "Dias transcurridos"
                ';'
                "Estado descarga"
                ';'
                "Ingrese resultado del bloqueo [1 para Bloqueado, 2 para En trámite de bloqueo, 3 para Contacto por cobranza, 4 para Contacto no publicitario y 5 para No registrado en base de datos]"
                ';'
                "Fecha asignación"
                ';'
                "Respuesta"
              ;end;
            set  WORK.SALIDA_TELEFONOS   end=EFIEOD;
                format "Id bloqueo"N best12. ;
                format Telefono $13. ;
                format "Canales bloqueados"N $30. ;
                format Correo $1. ;
                format "Fecha de solicitud"N $200. ;
                format "Dias transcurridos"N best12. ;
                format "Estado descarga"N $20. ;
                format "Ingrese resultado del bloqueo"N $1. ;
                format "Fecha asignación"N $1. ;
                format Respuesta $5. ;
              do;
                EFIOUT + 1;
                put "Id bloqueo"N @;
                put Telefono $ @;
                put "Canales bloqueados"N $ @;
                put Correo $ @;
                put "Fecha de solicitud"N $ @;
                put "Dias transcurridos"N @;
                put "Estado descarga"N $ @;
                put "Ingrese resultado del bloqueo"N $ @;
                put "Fecha asignación"N $ @;
                put Respuesta $ ;
              ;end;
  if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
  if EFIEOD then call symputx('_EFIREC_',EFIOUT);
  REPLACE;
RUN;
/*----------------------------------	FIN: EXPORT		-----------------------------------*/
/*-----------------------------------------------------------------------------------------*/


/*-----------------------------------------------------------------------------------------*/
/*----------------------------------       EMAIL    ---------------------------------------*/

/*	-------------------		IMPORTACION DE ARCHIVO CSV, TODAS LAS ENTRADAS		-----------*/
DATA WORK.IMPORT_MAILS;
INFILE '/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SEGUROS/bloqueos_mails.csv'

	DELIMITER=';'
	FIRSTOBS=2
	MISSOVER
	DSD
	LRECL=32767;

	FORMAT 'Id bloqueo'n best12.
	 Telefono best12.
	 'Canales bloqueados'n $30.
	 Correo $50.
	 'Fecha de solicitud'n DATETIME18.
	 'Dias transcurridos'n best12.
	 'Estado descarga'n $20.
	 'Ingrese resultado del bloqueo'n $1.
	 'Fecha asignación'n $1.
	 Respuesta $5.;
	 
INPUT 'Id bloqueo'n
	  Telefono
	  'Canales bloqueados'n $ 
      Correo
      'Fecha de solicitud'n : ?? ANYDTDTM19.
      'Dias transcurridos'n 
      'Estado descarga'n $
      'Ingrese resultado del bloqueo'n $
      'Fecha asignación'n $
      Respuesta $
;RUN;


/*Count entrada emails*/

proc sql;
create table q_entrada_emails as
select count(correo) as emails_ingresados
from IMPORT_MAILS;
quit;

/*	AGREGAR LOS OTROS CAMPOS DE ARCHIVO ORIGINAL	*/
PROC SQL;
   CREATE TABLE cruce_email AS 
   SELECT DISTINCT t1.*,
          t1.Correo AS EMAIL_SERNAC length=50, 
          t2.rut, 
          t2.EMAIL
      FROM IMPORT_MAILS t1
           LEFT JOIN RESULT.EMAIL_UNIDOS t2 ON (UPCASE(COMPRESS(t1.Correo)) = UPCASE(COMPRESS(t2.EMAIL)));
QUIT;

DATA _null_;
date = put(today(),date10.);
Call symput("fecha", date);
RUN;
%put &fecha;

PROC SQL;
	CREATE TABLE NUEVOS_LNEGRO_EMAIL AS
	SELECT t1.RUT, 
          t1.EMAIL_SERNAC AS EMAIL length=50,
		  'SERNAC_SEGUROS' AS MOTIVO,
		  "&fecha"D FORMAT=DATE9. AS FECHA_INHIBICION
	FROM cruce_email T1
UNION
	SELECT *
	FROM &libreria..LNEGRO_EMAIL
ORDER BY FECHA_INHIBICION
;QUIT;

PROC SQL;
CREATE TABLE LNEGRO_EMAIL AS
	SELECT DISTINCT RUT,
					upcase(EMAIL) as EMAIL,
					MOTIVO,
	  			    MIN(FECHA_INHIBICION) FORMAT=DATE9. AS FECHA_INHIBICION
	FROM NUEVOS_LNEGRO_EMAIL
	GROUP BY RUT,EMAIL,MOTIVO
	ORDER BY FECHA_INHIBICION
;QUIT;

/*-----------------------------------------------------------------------------------------*/
/*---------------------------------- INICIO: PASO LIBRERÍA FINAL  -------------------------*/
PROC SQL;
	CREATE TABLE &EDP_LIBRERIA..EDP_EMAIL AS
	SELECT *
	FROM LNEGRO_EMAIL
	ORDER BY FECHA_INHIBICION;
;QUIT;

PROC SQL NOERRORSTOP;
     CREATE TABLE &libreria..LNEGRO_EMAIL AS          /*(vista)*/
     SELECT *
     FROM &EDP_LIBRERIA..EDP_EMAIL
     ORDER BY FECHA_INHIBICION DESC
;QUIT;
/*----------------------------------  FIN: PASO LIBRERÍA FINAL  ---------------------------*/
/*-----------------------------------------------------------------------------------------*/


/*-----------------------------------------------------------------------------------------*/
/*-------------------------------    FORMATO PARA SALIDA  ---------------------------------*/
PROC SQL;
   CREATE TABLE SALIDA_MAILS AS
   SELECT DISTINCT t1.'Id bloqueo'n, 
		  t1.Telefono,
          t1.'Canales bloqueados'n, 
          t1.EMAIL_SERNAC as Correo length=50, 
		  cat((put(intnx('month',datepart(t1.'Fecha de solicitud'n),0,'same'),yymmdd10.)),' ',(put(intnx('month',timepart(t1.'Fecha de solicitud'n),0,'same'),hhmm8.2))) AS 'Fecha de solicitud'n,
          t1.'Dias transcurridos'n, 
          t1.'Estado descarga'n, 
		  case when t1.rut is null then COMPRESS(PUT(5,BEST.))
			   when t1.rut is not null then COMPRESS(PUT(1,BEST.))
          end as 'Ingrese resultado del bloqueo'n,
          t1.'Fecha asignación'n,
          t1.Respuesta
    FROM WORK.cruce_email t1;
QUIT;

/* Count salida emails*/

proc sql;
create table q_salida_emails as 
select count(Correo) as salida_emails
from SALIDA_MAILS;
quit;

/*-----------------------------------------------------------------------------------------*/
/*----------------------------------       EXPORT      ------------------------------------*/
DATA _null_;
  %let _EFIERR_ = 0;	/* set the ERROR detection macro variable	*/
  %let _EFIREC_ = 0;    /* clear export record count macro variable */

 fecha = put(today(),yymmdd10.);
 salida = COMPRESS('/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SEGUROS/mails_'||fecha||'.csv');
  
 FILE phod filevar = SALIDA notitles
 delimiter=';'
 DSD
 DROPOVER
 ENCODING=UTF8
 lrecl=32767;
             if _n_ = 1 then        /* write column names or labels */
              do;
                put
                "Id bloqueo"
                ';'
                 "Telefono"
                ';'
                "Canales bloqueados"
                ';'
                "Correo"
                ';'
                "Fecha de solicitud"
                ';'
                "Dias transcurridos"
                ';'
                "Estado descarga"
                ';'
                "Ingrese resultado del bloqueo [1 para Bloqueado, 2 para En trámite de bloqueo, 3 para Contacto por cobranza, 4 para Contacto no publicitario y 5 para No registrado en base de datos]"
                ';'
                "Fecha asignación"
                ';'
                "Respuesta"
              ;end;
            set  WORK.SALIDA_MAILS   end=EFIEOD;
                format "Id bloqueo"N best12. ;
                format Telefono $13. ;
                format "Canales bloqueados"N $30. ;
                format Correo $50. ;
                format "Fecha de solicitud"N $200. ;
                format "Dias transcurridos"N best12. ;
                format "Estado descarga"N $20. ;
                format "Ingrese resultado del bloqueo"N $1. ;
                format "Fecha asignación"N $1. ;
                format Respuesta $5. ;
              do;
                EFIOUT + 1;
                put "Id bloqueo"N @;
                put Telefono $ @;
                put "Canales bloqueados"N $ @;
                put Correo $ @;
                put "Fecha de solicitud"N $ @;
                put "Dias transcurridos"N @;
                put "Estado descarga"N $ @;
                put "Ingrese resultado del bloqueo"N $ @;
                put "Fecha asignación"N $ @;
                put Respuesta $ ;
              ;end;
  if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
  if EFIEOD then call symputx('_EFIREC_',EFIOUT);
  REPLACE;
RUN;

proc sql noprint;
select telefonos_ingresados as COUNT_telefonos_ingresados into:COUNT_telefonos_in
from q_entrada_telefonos;
select salida_telefonos as COUNT_salida_telefonos into:COUNT_telefonos_out
from q_salida_telefonos;
select emails_ingresados as COUNT_emails_ingresados into:COUNT_email_in
from q_entrada_emails;
select salida_emails as COUNT_emails_ingresados into: COUNT_email_out
from q_salida_emails
;QUIT;


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

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_2","&DEST_1","asierrag@bancoripley.com")
/*CC = ("&DEST_2")*/
SUBJECT = ("MAIL_AUTOM: - PROCESO SERNAC - PARTE 1 - SEGUROS");
FILE OUTBOX;
 PUT "Estimados:";
 put "    Proceso SERNAC, Parte 1, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put '    Detalle:'; 
 put '    Archivos tomados y depositados en: /sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SEGUROS/'; 
 put ;
 PUT "        Tomados		: bloqueos_telefonos.csv y bloqueos_mails.csv";
 PUT ;
 PUT "        Depositados	: telefonos_&fecha..csv y mails_&fecha..csv";
 PUT;
 put "TELEFONOS INGRESADOS: &COUNT_telefonos_in.";
 put "TELEFONOS INHIBIDOS: &COUNT_telefonos_out.";
 put "EMAILS INGRESADOS: &COUNT_email_in.";
 put "EMAILS INHIBIDOS: &COUNT_email_out.";
 PUT ;
 put 'Proceso Vers. 13'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
  ;
%end;
%mend; 
%enviacorreo();

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 
