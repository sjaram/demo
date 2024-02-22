/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	DATA_MASTER_ONBOARDING		===================================*/

/* CONTROL DE VERSIONES
/* 2022-05-02 ---- V02 -- David V. -- Corrección a asunto correo y se incluye a Jefa de Campañas en mail de notificaicón.
/* 2022-04-27 ---- V01 -- David V. -- Inicialmente igual al DATA_MASTER pero desde base email sin filtros sernac y suprimidos

Descripcion:
Genera la información de contactabilidad de los clientes, es el input del proceso DATAMASTER, para ONBOARDING.
*/

/* Usuario que genera la campaña*/
%let USUARIO = USER_BI;/* FECHA de actualización con formato MM/DD/YYYY*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*	VARIABLE LIBRERÍA			*/
%let libreria_1  = PUBLICIN; /*PUBLICIN*/
options validvarname=any;

proc sql;
	create table UNICA_CARGA_DATA_MASTER_ONB (
		'APELLIDO'n CHAR(200),
		'DIRECCION'n CHAR(200),
		'EMAIL'n CHAR(200),
		/* 'FECHA_CAPTACION'n CHAR(38),*/
		'FECHA_FACTURACION'n CHAR(38),
		'FECHA_LIMITE_PAGO'n CHAR(38),
		'ID_USUARIO'n NUMERIC(38),
		'NOMBRE'n CHAR(200),
		'NOMBRE_TC'n CHAR(200),
		'NUM_TC'n NUMERIC(12),
		'RETIRO_PLASTICO'n NUMERIC(12),
		'TELEFONO_MOVIL'n CHAR(38),
		'DIRECCION_NUM'n CHAR(38),
		'REGION'n CHAR(200),
		'COMUNA'n CHAR(200),
		'VAR_DM_NUM_1'n NUMERIC(38),
		'VAR_DM_TXT_1'n CHAR(38),
		'SEGMENTO'n CHAR(38),
		'SALDORPUNTOS1'n CHAR(38),
		'FECHASALDO'n CHAR(38)
		)
		/*'SMS_CONSENT_STATUS'n CHAR(38)*/
	;
quit;

/* EJEMPLO DE INSERT DE DATOS DISPONIBLES PARA SER INSERTADOS EN TABLA “datamaster_user_tc” */
proc sql NOPRINT;
	INSERT INTO UNICA_CARGA_DATA_MASTER_ONB (
		'APELLIDO'n,
		'DIRECCION'n,
		'EMAIL'n,
		/* 'FECHA_CAPTACION'n,*/
		'FECHA_FACTURACION'n,
		'FECHA_LIMITE_PAGO'n,
		'ID_USUARIO'n,
		'NOMBRE'n,
		'NOMBRE_TC'n,
		'NUM_TC'n,
		'RETIRO_PLASTICO'n,
		'TELEFONO_MOVIL'n,
		'DIRECCION_NUM'n,
		'REGION'n,
		'COMUNA'n,
		'VAR_DM_NUM_1'n,
		'VAR_DM_TXT_1'n,
		'SEGMENTO'n,
		'SALDORPUNTOS1'n,
		'FECHASALDO'n)
		/*,*/

	/*'SMS_CONSENT_STATUS'n )*/
	SELECT
		APELLIDO,
		DIRECCION,
		EMAIL,
		'',
		/* "&fecha.",*/

		'',
		ID_USUARIO,
		NOMBRE,
		'',
		0,
		0,
		compress('569'||put(TELEFONO_MOVIL, best.)) as TELEFONO_MOVIL,
		DIRECCION_NUM,
		REGION,
		COMUNA,
		0,
		'',
		SEGMENTO,
		SALDORPUNTOS1,
		FECHASALDO
		FROM &libreria_1..BASE_DATA_MASTER_ONB;
quit;

/* EXPORT --> Generación archivo CSV - DATA MASTER */
PROC EXPORT DATA = UNICA_CARGA_DATA_MASTER_ONB
	OUTFILE="/sasdata/users94/user_bi/unica/input/INPUT-DataMasterOnb_User_TC-&USUARIO..csv"
	DBMS=dlm REPLACE;
	delimiter=',';
	PUTNAMES=YES;
RUN;

PROC SQL;
	create table query_data_master_onb as 
		SELECT /* COUNT_of_ID_USUARIO */
	(COUNT(t1.ID_USUARIO)) AS COUNT_of_ID_USUARIO, /* COUNT_of_EMAIL */
	(COUNT(t1.EMAIL)) AS COUNT_of_EMAIL, /* COUNT_of_TELEFONO_MOVIL */
	(COUNT(t1.TELEFONO_MOVIL)) AS COUNT_of_TELEFONO_MOVIL FROM UNICA_CARGA_DATA_MASTER_ONB t1;
QUIT;

proc sql noprint;
	select COUNT_of_ID_USUARIO as COUNT_ID_USUARIO into:COUNT_ID_USUARIO
		from query_data_master_onb;
	select COUNT_of_EMAIL as COUNT_EMAIL into:COUNT_EMAIL
		from query_data_master_onb;
	select COUNT_of_TELEFONO_MOVIL as COUNT_TELEFONO_MOVIL into:COUNT_TELEFONO_MOVIL
		from query_data_master_onb;
	;
QUIT;

/* UTILIZACIÓN VARIABLE TIEMPO / CUANTO SE DEMORÓ */
data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;

/*salida del proceso indicando el tiempo total */
DATA _null_;
	fgenera = compress(input(put(today(),mmddyy.),$10.),"-",);
	Call symput("fechaDIA",fgenera);
RUN;

%put &fechaDIA;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFATURA_CAMP';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;

data _null_;
	FILENAME OUTBOX EMAIL
		FROM = ("&EDP_BI")
		TO = ("&DEST_2","&DEST_1","&DEST_3")
		SUBJECT = ("MAIL_AUTOM: PROCESO DATA_MASTER_ONBOARDING");
	FILE OUTBOX;
	PUT "Estimados:";
	put "		Proceso DATA_MASTER_ONBOARDING, ejecutado con fecha: &fechaeDVN";
	put "		Tabla generada		: &libreria_1..BASE_DATA_MASTER_ONB";
	put "		Archivo de generado	: /sasdata/users94/user_bi/unica/input/INPUT-DataMasterOnb_User_TC-&USUARIO..csv";
	PUT;
	put "		FECHA			: &fechaDIA.";
	put "		COUNT_ID_USUARIO: &COUNT_ID_USUARIO.";
	put "		COUNT_EMAIL		: &COUNT_EMAIL.";
	put "		COUNT_TELEF_MOV	: &COUNT_TELEFONO_MOVIL.";
	PUT;
	PUT;
	put 'Proceso Vers. 02';
	PUT;
	PUT;
	PUT 'Atte.';
	Put 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;

FILENAME OUTBOX CLEAR;
