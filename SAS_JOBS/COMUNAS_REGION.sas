/*==================================================================================================*/
/*==================================	EQUIPO ARQ.DATOS Y AUTOM.	================================*/
/*==================================			COMUNAS_REGION		================================*/

/* CONTROL DE VERSIONES
/* 2022-05-02 ---- V01 -- Ale Marinao -- Original
 */

/*==================================================================================================*/
/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*	VARIABLE LIBRERÍA			*/
%let libreria_1  = RESULT;
options validvarname=any;
LIBNAME bopers ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME MPDT  ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME GENERAL ORACLE PATH='REPORITF.WORLD' SCHEMA='BOTGEN_ADM' USER='AMARINAOC' PASSWORD='amarinaoc2017';

PROC SQL;
	CREATE TABLE WORK.REGIONES AS 
		SELECT t1.TGMPA_COD_PAI_K, 
			t1.TGMDP_COD_DVS_K, 
			t1.TGMUG_COD_UBC_GEO_K, 
			t1.TGMUG_NOM_UBC_GEO, 
			t1.TGMUG_COD_UBC_GEO_PAD
		FROM GENERAL.BOTGEN_MAE_UBC_GEO T1
			WHERE TGMPA_COD_PAI_K=152 and TGMDP_COD_DVS_K=1
	;
QUIT;

PROC SQL;
	CREATE TABLE WORK.COMUNAS AS 
		SELECT t1.TGMPA_COD_PAI_K , 
			t1.TGMDP_COD_DVS_K, 
			t1.TGMUG_COD_UBC_GEO_K, 
			t1.TGMUG_NOM_UBC_GEO, 
			t1.TGMUG_COD_UBC_GEO_PAD
		FROM GENERAL.BOTGEN_MAE_UBC_GEO t1
			WHERE t1.TGMPA_COD_PAI_K=152 AND t1.TGMDP_COD_DVS_K=4 
	;
QUIT;

/*CRUCE*/
PROC SQL;
	CREATE TABLE &libreria_1..COMUNAS AS 
		SELECT t1.TGMPA_COD_PAI_K, 
			t1.TGMUG_COD_UBC_GEO_K, 
			t1.TGMUG_NOM_UBC_GEO, 
			T2.TGMUG_COD_UBC_GEO_K AS COD_REGION,
			T2.TGMUG_NOM_UBC_GEO AS REGION
		FROM WORK.COMUNAS T1 LEFT JOIN REGIONES T2
			ON T1.TGMUG_COD_UBC_GEO_PAD=T2.TGMUG_COD_UBC_GEO_K
	;
QUIT;

/* VARIABLE TIEMPO - FIN */
data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;

/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN);
RUN;

%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;

data _null_;
	FILENAME OUTBOX EMAIL
		FROM = ("&EDP_BI")
		TO = ("&DEST_1", "&DEST_2")
		SUBJECT = ("MAIL_AUTOM: Proceso COMUNAS_REGION");
	FILE OUTBOX;
	PUT "Estimados:";
	put "		Proceso COMUNAS_REGION, ejecutado con fecha: &fechaeDVN";
	put "		Tabla generada: &libreria_1..COMUNAS";
	PUT;
	PUT;
	put 'Proceso Vers. 01';
	PUT;
	PUT;
	PUT 'Atte.';
	Put 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;

FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO ARQ.DATOS Y AUTOM.	================================*/
