/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	SERNAC_INHIB_PARTE_1_ECCSA	================================*/
/* CONTROL DE VERSIONES

/* 2021-07-27 -- V11 -- Sergio.J -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- SE DEJA EL EMAIL EN MAYUSCULA

/* 2021-04-22 -- V10 -- Sergio.J -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- SE AGREGA AL CORREO LOS ARCHIVOS INHIBIDOS

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

 /* Archivos tomados y depositados en: /sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/ECCSA/ 
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
INFILE '/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/ECCSA/bloqueos_telefonos.csv'
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
				  'SERNAC_ECSSA' AS TIPO_INHIBICION,
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
					  'SERNAC_ECSSA' AS TIPO_INHIBICION,
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

PROC SQL;
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

PROC SQL; 
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


/*-----------------------------------------------------------------------------------------*/
/*----------------------------------  INICIO: EXPORT	-----------------------------------*/
DATA _null_;
  %let _EFIERR_ = 0;	/* set the ERROR detection macro variable 	*/
  %let _EFIREC_ = 0;	/* clear export record count macro variable */

 fecha = put(today(),yymmdd10.);
 salida = COMPRESS('/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/ECCSA/telefonos_'||fecha||'.csv');
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
INFILE '/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/ECCSA/bloqueos_mails.csv'

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
		  'SERNAC_ECCSA' AS MOTIVO,
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

PROC SQL;
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


/*-----------------------------------------------------------------------------------------*/
/*----------------------------------       EXPORT      ------------------------------------*/
DATA _null_;
  %let _EFIERR_ = 0;	/* set the ERROR detection macro variable	*/
  %let _EFIREC_ = 0;    /* clear export record count macro variable */

 fecha = put(today(),yymmdd10.);
 salida = COMPRESS('/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/ECCSA/mails_'||fecha||'.csv');
  
call symput("date",fecha);
%put &date;

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

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_2","&DEST_1","jgarridoq@ripley.com","plopezc@ripley.com","g-canalsernac@ripley.com","asierrag@bancoripley.com")
CC = ("drodrigueza@ripley.com")
ATTACH	= "/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/ECCSA/telefonos_&date..csv"
ATTACH	= "/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/ECCSA/mails_&date..csv"
SUBJECT = ("MAIL_AUTOM - PROCESO SERNAC - PARTE 1 - ECCSA");
FILE OUTBOX;
 PUT "Estimados:";
 put "    Proceso SERNAC, Parte 1, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put '    Detalle:'; 
 put '    Archivos tomados y depositados en: /sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/ECCSA/'; 
 put ;
 PUT "        Tomados		: bloqueos_telefonos.csv y bloqueos_mails.csv";
 PUT ;
 PUT "        Depositados	: telefonos_&fecha..csv y mails_&fecha..csv";
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 11'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
