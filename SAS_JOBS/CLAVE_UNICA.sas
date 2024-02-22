/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	CLAVE_UNICA						 ===============================*/
/* CONTROL DE VERSIONES
/* 2023-05-29 -- v03 -- David V.	-- Se actualiza conexión a la bd por cambio en producción banco.
/* 2022-01-24 -- v02 -- David V. 	-- Se cambia librería DVASQUEZ por WORK para automatizar en server SAS
/* 2021-11-05 -- v01 -- David V. 	-- Versión Original

/* INFORMACIÓN:
	Información de clave unica de cara a los clientes

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria1=WORK;
%let libreria2=PUBLICIN;

DATA _null_;
	/* DECLARACIÓN VARIABLES FECHAS*/
	dateDIA	= compress(substr(put(today(),ddmmyy10.),7,4)||substr(put(today(),ddmmyy10.),4,2)||substr(put(today(),ddmmyy10.),1,2));
	Call symput("VdateDIA", dateDIA);
	dateMES	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
	Call symput("VdateMES", dateMES);
RUN;

%put &VdateDIA;
%put &VdateMES;
LIBNAME REPITFH ORACLE SCHEMA='CLAVEUNICA_ADM'  USER='USR_BI_G' PASSWORD='usrpass2021'
	PATH="  (DESCRIPTION =
	(ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.84.20)(PORT = 1521))
	(CONNECT_DATA =
	(SERVER = DEDICATED)
	(SERVICE_NAME = itfhis)
		)
		)";

PROC SQL;
	CREATE TABLE users AS
		SELECT group_id, 
			user_id, 
			user_number, 
			psswd_lastchngdate, 
			password_expdate, 
			lastauthdate, 
			lastauthtype, 
			lastfailedauthdate, 
			lastfailedauthtype 
		FROM REPITFH.USERS t1
			order by user_number;
QUIT;

PROC SQL;
	CREATE TABLE WORK.UNICA_1 AS 
		SELECT 
			input(COMPRESS(SUBSTRN(user_id,1,(LENGTH(user_id)-1))),BEST.) AS  RUT,
			input(put(datepart(psswd_lastchngdate),yymmddn8.),best.) as FECHA_NUM
		FROM WORK.users t1;
QUIT;

PROC SQL;
	CREATE TABLE WORK.UNICA_2 AS 
		SELECT 
			t1.RUT, 
			MDY(
			input(substr(compress(put(FECHA_NUM,best.)),5,2),best.),
			input(substr(compress(put(FECHA_NUM,best.)),7,2),best.),
			input(substr(compress(put(FECHA_NUM,best.)),1,4),best.)
			) format=date9. as FECHA
		FROM WORK.UNICA_1 t1
	;
QUIT;

PROC SQL;
	CREATE TABLE WORK.UNICA_3 AS 
		SELECT 
			t1.RUT, 
			t1.FECHA
		FROM WORK.UNICA_2 t1
			WHERE t1.RUT NOT = . 
				AND t1.FECHA NOT = .
				AND t1.RUT > 99999
				AND t1.RUT < 99999999
	;
QUIT;

PROC SQL;
	CREATE TABLE &libreria2..CLAVE_UNICA_&VdateMES AS
		SELECT t1.RUT, 
			(MAX(t1.FECHA)) FORMAT=DATE9. AS FECHA_ACTUALIZACION 
		FROM WORK.UNICA_3 t1 
			GROUP BY t1.RUT
	;
QUIT;

/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;
