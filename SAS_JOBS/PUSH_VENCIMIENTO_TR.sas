/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PUSH_VENCIMIENTO_TR			================================*/
/* CONTROL DE VERSIONES
/* 2022-09-13 -- v03 -- David V.	--  Se cambia - por _ en nombre archivo para enviar correctamente.
/* 2022-09-13 -- v02 -- David V.	--  Actualización export to AWS
/* 2021-07-26 -- v01 -- David V.	--  Versión Original

/* INFORMACIÓN:
	Campaña PUSH 01 - Vencimiento Plastico

	(IN) Tablas requeridas o conexiones a BD:
	- RESULT.VENCIMIENTOS_&VdateHOY

	(OUT) Tablas de Salida o resultado:
 	- &libreria..PUSH_VENCIMIENTO_01
*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria=RESULT;

%let grupo1			= 1;
%let grupo2			= 2;
%let grupo3			= 3;
%let grupo4			= 4;

OPTIONS VALIDVARNAME=ANY;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/

DATA _null_;
/* Variables Fechas de Ejecución */
datePeriodoActual = input(put(intnx('month',today(),0,'end' ),yymmn6. ),$10.);
datehi	= compress(input(put(intnx('month',today(),0,'begin' ),yymmdd10.	),$20.),"-",c);
datehf	= compress(input(put(intnx('month',today(),0,'end'	),yymmdd10. 	),$20.),"-",c);
exec 	= compress(input(put(today()+1,yymmdd10.),$10.),"-",c);
fgenera	= compress(input(put(today(),yymmdd10.),$10.),"-",c);
datedN = YEAR(today())*10000+MONTH(today())*100+DAY(today());
hoy= compress(tranwrd(put(INTNX('DAY',today() , 0),mmddyy10.),"-",""));

Call symput("VdateHOY", datePeriodoActual);
Call symput("fechahi",datehi);
Call symput("fechahf",datehf);
Call symput("fechae",exec);
Call symput("fgen",fgenera);
Call symput("fechadN", datedN);
Call symput("fecha", hoy);

RUN;
%put &VdateHOY;
%put &fechahi;
%put &fechahf;
%put &fechae;
%put &fgen;
%put &fechadN;
%put &fecha;

/*==================================================================================================*/
/*===========================	Nuevo Flujo	Comunicaciones CAMP_1 ini	============================*/
%let USUARIO_1 = USER_BI_1;
%put &USUARIO;

proc sql;
Create table UNICA_CARGA_CAMP_PUSH_VENC1 (
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
	'CAMPANA-MARCA'n 			CHAR(200),	/* PUSH (Grupo al que pertenece Campaña de vencim)*/
	'CAMPANA-FECHA_VCTO_GC'n 	CHAR(200)	/* PUSH (Fecha caducudad tarjeta)*/
)
;quit;

/* INSERT CAMPAÑA --> PUSH */
proc sql NOPRINT;
INSERT INTO UNICA_CARGA_CAMP_PUSH_VENC1
('CAMPANA-CAMPCODE'n, 'CAMPANA-AREA'n, 'CAMPANA-PRODUCTO'n, 'CAMPANA-CAMPANA'n, 'CAMPANA-FECHA'n, 'CAMPANA-CUSTOMERID'n, 'CAMPANA-CANAL'n, 'CAMPANA-RUT_PUSH'n, 'CAMPANA-ID_USUARIO'n, 'CLIENTE-ID_USUARIO'n, 'CAMPANA-IND_RUT_DUP_CAMP'n, 'CAMPANA-MARCA'n, 'CAMPANA-FECHA_VCTO_GC'n)
SELECT DISTINCT compress(cats("&fechadN",'SGM','VNC')), 'SGM', 'VNC', 'VENCIMIENTO_GRUPO_1',  "&FECHA.", RUT, 'PUSH', compress(PUT(RUT,BEST8.)), RUT, RUT, 0, compress(PUT(grupo,BEST8.)), compress(PUT(feccadtar,BEST8.))
from &LIBRERIA..VENCIMIENTOS_&VdateHOY 
WHERE RUT > 0 AND grupo = &grupo1.;								/*	ACTUALIZAR */
;quit;

/*	EXPORT --> Generación archivo CSV */
PROC EXPORT DATA = UNICA_CARGA_CAMP_PUSH_VENC1
OUTFILE="/sasdata/users94/user_bi/unica/input/INPUT-FIREBASE_PUSH_VENC-&USUARIO_1..csv"
DBMS=dlm REPLACE;
delimiter=',';
PUTNAMES=YES;
RUN; 

proc sql NOPRINT;
	select count('CLIENTE-ID_USUARIO'n) INTO :COUNT_ruts1
	from UNICA_CARGA_CAMP_PUSH_VENC1;
quit;

%put &=COUNT_ruts1;


/* INSERT A LA TABLA PARA RESUMEN Y ENVÍO DE EMAIL POSTERIOR */
proc sql NOPRINT;
	insert into &libreria..GCO_CAMP_DVN_PUSH_&VdateHOY 
		values("INPUT-FIREBASE_PUSH_VENC-&USUARIO_1..csv","&COUNT_ruts1.")
;quit;

/*EXPORT TO AWS RAW*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_CAMPAIGN/AWS_RAW_CAMPAIGN_EXPORT.sas";
%ExportacionCampaignRaw(INPUT_FIREBASE_VENCIMIENTO_1,UNICA_CARGA_CAMP_PUSH_VENC1);
/* Tabla disponible en AWS, tabla salida proceso SAS */

/*===========================	Nuevo Flujo	Comunicaciones CAMP_1 fin	============================*/
/*==================================================================================================*/

/*==================================================================================================*/
/*===========================	Nuevo Flujo	Comunicaciones CAMP_2 ini	============================*/
%let USUARIO_2 = USER_BI_2;
%put &USUARIO;

proc sql;
Create table UNICA_CARGA_CAMP_PUSH_VENC2 (
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
	'CAMPANA-MARCA'n 			CHAR(200),	/* PUSH (Grupo al que pertenece Campaña de vencim)*/
	'CAMPANA-FECHA_VCTO_GC'n 	CHAR(200)	/* PUSH (Fecha caducudad tarjeta)*/
)
;quit;

/* INSERT CAMPAÑA --> PUSH */
proc sql NOPRINT;
INSERT INTO UNICA_CARGA_CAMP_PUSH_VENC2
('CAMPANA-CAMPCODE'n, 'CAMPANA-AREA'n, 'CAMPANA-PRODUCTO'n, 'CAMPANA-CAMPANA'n, 'CAMPANA-FECHA'n, 'CAMPANA-CUSTOMERID'n, 'CAMPANA-CANAL'n, 'CAMPANA-RUT_PUSH'n, 'CAMPANA-ID_USUARIO'n, 'CLIENTE-ID_USUARIO'n, 'CAMPANA-IND_RUT_DUP_CAMP'n, 'CAMPANA-MARCA'n, 'CAMPANA-FECHA_VCTO_GC'n)
SELECT DISTINCT compress(cats("&fechadN",'SGM','VNC')), 'SGM', 'VNC', 'VENCIMIENTO_GRUPO_2',  "&FECHA.", RUT, 'PUSH', compress(PUT(RUT,BEST8.)), RUT, RUT, 0, compress(PUT(grupo,BEST8.)), compress(PUT(feccadtar,BEST8.))
from &LIBRERIA..VENCIMIENTOS_&VdateHOY 
WHERE RUT > 0 AND grupo = &grupo2.;								/*	ACTUALIZAR */
;quit;

/*	EXPORT --> Generación archivo CSV */
PROC EXPORT DATA = UNICA_CARGA_CAMP_PUSH_VENC2
OUTFILE="/sasdata/users94/user_bi/unica/input/INPUT-FIREBASE_PUSH_VENC-&USUARIO_2..csv"
DBMS=dlm REPLACE;
delimiter=',';
PUTNAMES=YES;
RUN; 

proc sql NOPRINT;
	select count('CLIENTE-ID_USUARIO'n) INTO :COUNT_ruts2
	from UNICA_CARGA_CAMP_PUSH_VENC2;
quit;

%put &=COUNT_ruts2;


/* INSERT A LA TABLA PARA RESUMEN Y ENVÍO DE EMAIL POSTERIOR */
proc sql NOPRINT;
	insert into &libreria..GCO_CAMP_DVN_PUSH_&VdateHOY 
		values("INPUT-FIREBASE_PUSH_VENC-&USUARIO_2..csv","&COUNT_ruts2.")
;quit;

/*EXPORT TO AWS RAW*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_CAMPAIGN/AWS_RAW_CAMPAIGN_EXPORT.sas";
%ExportacionCampaignRaw(INPUT_FIREBASE_VENCIMIENTO_2,UNICA_CARGA_CAMP_PUSH_VENC2);
/* Tabla disponible en AWS, tabla salida proceso SAS */

/*===========================	Nuevo Flujo	Comunicaciones CAMP_2 fin	============================*/
/*==================================================================================================*/

/*==================================================================================================*/
/*===========================	Nuevo Flujo	Comunicaciones CAMP_3 ini	============================*/
%let USUARIO_3 = USER_BI_3;
%put &USUARIO;

proc sql;
Create table UNICA_CARGA_CAMP_PUSH_VENC3 (
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
	'CAMPANA-MARCA'n 			CHAR(200),	/* PUSH (Grupo al que pertenece Campaña de vencim)*/
	'CAMPANA-FECHA_VCTO_GC'n 	CHAR(200)	/* PUSH (Fecha caducudad tarjeta)*/
)
;quit;

/* INSERT CAMPAÑA --> PUSH */
proc sql NOPRINT;
INSERT INTO UNICA_CARGA_CAMP_PUSH_VENC3
('CAMPANA-CAMPCODE'n, 'CAMPANA-AREA'n, 'CAMPANA-PRODUCTO'n, 'CAMPANA-CAMPANA'n, 'CAMPANA-FECHA'n, 'CAMPANA-CUSTOMERID'n, 'CAMPANA-CANAL'n, 'CAMPANA-RUT_PUSH'n, 'CAMPANA-ID_USUARIO'n, 'CLIENTE-ID_USUARIO'n, 'CAMPANA-IND_RUT_DUP_CAMP'n, 'CAMPANA-MARCA'n, 'CAMPANA-FECHA_VCTO_GC'n)
SELECT DISTINCT compress(cats("&fechadN",'SGM','VNC')), 'SGM', 'VNC', 'VENCIMIENTO_GRUPO_3',  "&FECHA.", RUT, 'PUSH', compress(PUT(RUT,BEST8.)), RUT, RUT, 0, compress(PUT(grupo,BEST8.)), compress(PUT(feccadtar,BEST8.))
from &LIBRERIA..VENCIMIENTOS_&VdateHOY 
WHERE RUT > 0 AND grupo = &grupo3.;								/*	ACTUALIZAR */
;quit;

/*	EXPORT --> Generación archivo CSV */
PROC EXPORT DATA = UNICA_CARGA_CAMP_PUSH_VENC3
OUTFILE="/sasdata/users94/user_bi/unica/input/INPUT-FIREBASE_PUSH_VENC-&USUARIO_3..csv"
DBMS=dlm REPLACE;
delimiter=',';
PUTNAMES=YES;
RUN; 

proc sql NOPRINT;
	select count('CLIENTE-ID_USUARIO'n) INTO :COUNT_ruts3
	from UNICA_CARGA_CAMP_PUSH_VENC3;
quit;

%put &=COUNT_ruts3;


/* INSERT A LA TABLA PARA RESUMEN Y ENVÍO DE EMAIL POSTERIOR */
proc sql NOPRINT;
	insert into &libreria..GCO_CAMP_DVN_PUSH_&VdateHOY 
		values("INPUT-FIREBASE_PUSH_VENC-&USUARIO_3..csv","&COUNT_ruts3.")
;quit;

/*EXPORT TO AWS RAW*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_CAMPAIGN/AWS_RAW_CAMPAIGN_EXPORT.sas";
%ExportacionCampaignRaw(INPUT_FIREBASE_VENCIMIENTO_3,UNICA_CARGA_CAMP_PUSH_VENC3);
/* Tabla disponible en AWS, tabla salida proceso SAS */

/*===========================	Nuevo Flujo	Comunicaciones CAMP_3 fin	============================*/
/*==================================================================================================*/

/*==================================================================================================*/
/*===========================	Nuevo Flujo	Comunicaciones CAMP_4 ini	============================*/
%let USUARIO_4 = USER_BI_4;
%put &USUARIO;

proc sql;
Create table UNICA_CARGA_CAMP_PUSH_VENC4 (
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
	'CAMPANA-MARCA'n 			CHAR(200),	/* PUSH (Grupo al que pertenece Campaña de vencim)*/
	'CAMPANA-FECHA_VCTO_GC'n 	CHAR(200)	/* PUSH (Fecha caducudad tarjeta)*/
)
;quit;

/* INSERT CAMPAÑA --> PUSH */
proc sql NOPRINT;
INSERT INTO UNICA_CARGA_CAMP_PUSH_VENC4
('CAMPANA-CAMPCODE'n, 'CAMPANA-AREA'n, 'CAMPANA-PRODUCTO'n, 'CAMPANA-CAMPANA'n, 'CAMPANA-FECHA'n, 'CAMPANA-CUSTOMERID'n, 'CAMPANA-CANAL'n, 'CAMPANA-RUT_PUSH'n, 'CAMPANA-ID_USUARIO'n, 'CLIENTE-ID_USUARIO'n, 'CAMPANA-IND_RUT_DUP_CAMP'n, 'CAMPANA-MARCA'n, 'CAMPANA-FECHA_VCTO_GC'n)
SELECT DISTINCT compress(cats("&fechadN",'SGM','VNC')), 'SGM', 'VNC', 'VENCIMIENTO_GRUPO_4',  "&FECHA.", RUT, 'PUSH', compress(PUT(RUT,BEST8.)), RUT, RUT, 0, compress(PUT(grupo,BEST8.)), compress(PUT(feccadtar,BEST8.))
from &LIBRERIA..VENCIMIENTOS_&VdateHOY 
WHERE RUT > 0 AND grupo = &grupo4.;								/*	ACTUALIZAR */
;quit;

/*	EXPORT --> Generación archivo CSV */
PROC EXPORT DATA = UNICA_CARGA_CAMP_PUSH_VENC4
OUTFILE="/sasdata/users94/user_bi/unica/input/INPUT-FIREBASE_PUSH_VENC-&USUARIO_4..csv"
DBMS=dlm REPLACE;
delimiter=',';
PUTNAMES=YES;
RUN; 

proc sql NOPRINT;
	select count('CLIENTE-ID_USUARIO'n) INTO :COUNT_ruts4
	from UNICA_CARGA_CAMP_PUSH_VENC4;
quit;

%put &=COUNT_ruts4;


/* INSERT A LA TABLA PARA RESUMEN Y ENVÍO DE EMAIL POSTERIOR */
proc sql NOPRINT;
	insert into &libreria..GCO_CAMP_DVN_PUSH_&VdateHOY 
		values("INPUT-FIREBASE_PUSH_VENC-&USUARIO_4..csv","&COUNT_ruts4.")
;quit;

/*EXPORT TO AWS RAW*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_CAMPAIGN/AWS_RAW_CAMPAIGN_EXPORT.sas";
%ExportacionCampaignRaw(INPUT_FIREBASE_VENCIMIENTO_4,UNICA_CARGA_CAMP_PUSH_VENC4);
/* Tabla disponible en AWS, tabla salida proceso SAS */

/*===========================	Nuevo Flujo	Comunicaciones CAMP_4 fin	============================*/
/*==================================================================================================*/

/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 
