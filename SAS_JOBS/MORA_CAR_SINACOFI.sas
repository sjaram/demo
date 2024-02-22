/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	MORA_CAR_SINACOFI				 ===============================*/
/* CONTROL DE VERSIONES
/* 2023-06-08 -- v05 -- Esteban P.	-- Se agrega noprint a proc sql que provocaba la caída del proceso.
/* 2023-05-29 -- v04 -- David V.	-- Se actualiza conexión a la bd por cambio en producción banco.
/* 2023-05-26 -- v03 -- Sergio J. 	-- Se agrega exportación a AWS.
/* 2023-02-28 -- v02 -- Esteban P.  -- Se fixean credenciales y se utiliza código para mantenerlas ocultas.
/* 0000-00-00 -- v01 -- David V. 	-- Versión Original

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

/*=== FECHAS ========================================================================================================================*/
DATA NULL_;
	datex = input(put(intnx('month',today(),0,'end'),yymmn6.),$10.);      /*cambiar 0 a -1 para ver cierre mes anterior*/
	exec = put(datetime(),datetime20.);
	Call symput("fechax", datex);
	Call symput("fechae",exec);
RUN;

%put &fechax;
%put &fechae;

/*=== CONEXIONES ========================================================================================================================*/
LIBNAME MPDT  	 ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME R_bopers ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME R_sfries ORACLE PATH='REPORITF.WORLD' SCHEMA='SFRIES_ADM'  USER='AMARINAOC' PASSWORD='amarinaoc2017';

/*=== PROCESOS ========================================================================================================================*/
proc sql noprint;
	select MAX(EVAAM_FCH_PRO) into: MAX_FECHA
		from R_SFRIES.SFRIES_ALT_MOR;
quit;

/*324770*/
PROC SQL;
	CREATE TABLE PUBLICIN.MORA_CAR AS 
		SELECT INPUT(PEMID_GLS_NRO_DCT_IDE_K, BEST.) AS RUT, EVAAM_SLD_TTL AS SALDO_TOTAL, EVAAM_SLD_MOR AS SALDO_MORA,
			EVAAM_DIA_MOR AS DIAS_MORA , "&fechae" as FEC_EX
		FROM R_SFRIES.SFRIES_ALT_MOR AS A
			INNER JOIN MPDT.MPDT007 H ON SUBSTR(A.EVAAM_NRO_CTT,5,4)=H.CENTALTA AND SUBSTR(A.EVAAM_NRO_CTT,9,12)=H.CUENTA AND H.FECBAJA='0001-01-01'
			INNER JOIN R_BOPERS.BOPERS_MAE_IDE I ON INPUT(H.IDENTCLI, BEST.)=I.PEMID_NRO_INN_IDE
				WHERE A.EVAAM_FCH_PRO = "&MAX_FECHA"DT 
					AND EVAAM_DIA_MOR>1
	;
QUIT;

/*===========================================================================================================================*/
/*      MORA SINACOFI */
/*===========================================================================================================================*/
proc sql NOPRINT;
	SELECT USUARIO into :USER 
		FROM sasdyp.user_pass WHERE SCHEMA = 'BODEU_ADM';
	SELECT PASSWORD into :PASSWORD 
		FROM sasdyp.user_pass WHERE SCHEMA = 'BODEU_ADM';
quit;

LIBNAME SINACOFI ORACLE SCHEMA='BODEU_ADM'  USER=&USER. PASSWORD=&PASSWORD.
	PATH="  (DESCRIPTION =
	(ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.84.20)(PORT = 1521))
	(CONNECT_DATA =
	(SERVER = DEDICATED)
	(SERVICE_NAME = itfhis)
		)
		)";

PROC SQL;
	CREATE TABLE CONSULTA_FEC AS
		SELECT * FROM SINACOFI.BODEU_AUX_VRS_ACV;
QUIT;

PROC SQL;
	CREATE TABLE CONSOLIDADO_A AS
		SELECT CMOR_RUT_K AS RUT, 
			(CMOR_MNT_DCT_MTR1+CMOR_MNT_DCT_MTR2+CMOR_MNT_DCT_MTR3+CMOR_MNT_DCT_MTR4) AS MORA_CONSOLIDADA
		FROM SINACOFI.BODEU_MAE_CNS_MOR_A;
QUIT;

PROC SQL;
	CREATE TABLE BOLETIN_A AS 
		SELECT PBLN_RUT_K AS RUT, 
			(PBLN_MNT_PTT_MTR1+PBLN_MNT_PTT_MTR2+PBLN_MNT_PTT_MTR3+PBLN_MNT_PTT_MTR4) AS PROTESTO_BOLETIN
		FROM SINACOFI.BODEU_MAE_PTT_BLN_A;
QUIT;

PROC SQL;
	CREATE TABLE CONSOLIDADO_B AS
		SELECT CMOR_RUT_K AS RUT, 
			(CMOR_MNT_DCT_MTR1+CMOR_MNT_DCT_MTR2+CMOR_MNT_DCT_MTR3+CMOR_MNT_DCT_MTR4) AS MORA_CONSOLIDADA
		FROM SINACOFI.BODEU_MAE_CNS_MOR_B;
QUIT;

PROC SQL;
	CREATE TABLE BOLETIN_B AS 
		SELECT PBLN_RUT_K AS RUT, 
			(PBLN_MNT_PTT_MTR1+PBLN_MNT_PTT_MTR2+PBLN_MNT_PTT_MTR3+PBLN_MNT_PTT_MTR4) AS PROTESTO_BOLETIN
		FROM SINACOFI.BODEU_MAE_PTT_BLN_B;
QUIT;

PROC SQL;
	CREATE TABLE SINACOFI AS
		SELECT * FROM CONSOLIDADO_A
			WHERE MORA_CONSOLIDADA > 10000
				UNION
			SELECT * FROM BOLETIN_A
				WHERE PROTESTO_BOLETIN > 2;
QUIT;

PROC SQL;
	CREATE TABLE SINACOFIB AS
		SELECT * 
			FROM CONSOLIDADO_B
				WHERE MORA_CONSOLIDADA > 10000
					UNION
				SELECT *  FROM BOLETIN_B
					WHERE PROTESTO_BOLETIN > 2;
QUIT;

proc sql;
	create table PUBLICIN.MORA_SINACOFI AS
		SELECT *, "&fechax" AS FEC_EX
			FROM SINACOFIB
	;
QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(SAS_PPFF_MORA_SINACOFI,raw,sasdata,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(SAS_PPFF_MORA_SINACOFI,PUBLICIN.MORA_SINACOFI,raw,sasdata,0);

/*	=========================================================================	*/
/*			FIN : MEJORA PARA LA EDAD DE LOS DATOS - OBTENIDO DE BOPERS			*/
/*	=========================================================================	*/

/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;
