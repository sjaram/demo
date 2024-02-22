/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	PLANES_IMPORT_AWS	 		 	 ===============================*/

/* CONTROL DE VERSIONES
/* 2023-11-09 -- V04 -- David V. 	-- Se actualiza conexión para ahora apuntar a SEGCOM_NEW.
/* 2023-10-17 -- V03 -- David V. 	-- Se actualiza password de usuario dswitchp por cambio en bd.
/* 2022-11-25 -- v02 -- David V.	-- Se agregan dos nuevas tablas requeridas por Thomas.
/* 2022-11-22 -- v01 -- David V.	-- Correos de notificación y librería publicin para automatizar.
/* 2022-11-18 -- v00 -- David V.	-- Original
/*

/* VARIABLE TIEMPO - INICIO */
%let tiempo_inicio= %sysfunc(datetime());
options validvarname=any;
%let LIBRERIA=publicin;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
proc sql noprint;
	SELECT USUARIO into :USER 
		FROM sasdyp.user_pass WHERE SCHEMA = 'SEGCOM';
	SELECT PASSWORD into :PASSWORD 
		FROM sasdyp.user_pass WHERE SCHEMA = 'SEGCOM';
quit;

%let mz_connect_BANCO=CONNECT TO ORACLE as BANCO(USER=&USER. PASSWORD=&PASSWORD.
PATH="(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.84.167)(PORT = 1521))(CONNECT_DATA=(SERVER = DEDICATED)(SERVICE_NAME = segcom)))"); 

PROC SQL NOERRORSTOP;
	&mz_connect_BANCO;
	create table &LIBRERIA..PLANES_TBL_PLAN  as 
		select * 
			from connection to BANCO( 
				select * from PLANES_ADM.PLANES_TBL_PLAN
				order by 1 desc
					) A
	;
QUIT;

PROC SQL NOERRORSTOP;
	&mz_connect_BANCO;
	create table &LIBRERIA..PLANES_TBL_PLAN_CLIENTE  as 
		select * 
			from connection to BANCO( 
				select * from PLANES_ADM.PLANES_TBL_PLAN_CLIENTE
				order by 1 desc
					) A
	;
QUIT;


PROC SQL NOERRORSTOP;
	&mz_connect_BANCO;
	create table &LIBRERIA..PLANES_TBL_PLAN_PROD  as 
		select * 
			from connection to BANCO( 
				select * from PLANES_ADM.PLANES_TBL_PLAN_PROD
				order by 1 desc
					) A
	;
QUIT;

PROC SQL NOERRORSTOP;
	&mz_connect_BANCO;
	create table &LIBRERIA..PLANES_TBL_PLAN_SEG  as 
		select * 
			from connection to BANCO( 
				select * from PLANES_ADM.PLANES_TBL_PLAN_SEG
				order by 1 desc
					) A
	;
QUIT;
/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*	FECHA DEL PROCESO	*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN);
RUN;

%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SUBG_GOBIERNO_DAT';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_CLIENTES';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;

/* VARIABLE TIEMPO - FIN */
data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;

data _null_;
	FILENAME OUTBOX EMAIL
		FROM = ("&EDP_BI")
/*		TO = ("&DEST_1")*/
		TO = ("&DEST_4","&DEST_5")
		CC = ("&DEST_1", "&DEST_2", "&DEST_3")
	SUBJECT = ("MAIL_AUTOM: Proceso PLANES_IMPORT_AWS");
	FILE OUTBOX;
	PUT "Estimados:";
	PUT "		Proceso PLANES_IMPORT_AWS, ejecutado con fecha: &fechaeDVN";
	PUT "  		Información disponible en SAS:";
	PUT "  							- &LIBRERIA..PLANES_TBL_PLAN";
	PUT "  							- &LIBRERIA..PLANES_TBL_PLAN_CLIENTE";
	PUT "  							- &LIBRERIA..PLANES_TBL_PLAN_PROD";
	PUT "  							- &LIBRERIA..PLANES_TBL_PLAN_SEG";
	PUT;
	PUT;
	PUT;
	PUT 'Proceso Vers. 04';
	PUT;
	PUT;
	PUT 'Atte.';
	PUT 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;

FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
