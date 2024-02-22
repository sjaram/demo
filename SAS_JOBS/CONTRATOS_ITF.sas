/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	CONTRATOS_ITF	 ===============================*/

/* CONTROL DE VERSIONES
/* 2023-01-17 -- v01 -- David V.	- Se agrega en conjunto, productos MC Black y MC Cerrada (14 y 10)
/* 0000-00-00 -- v00 -- Original
/**/

/* VARIABLE TIEMPO - INICIO */
%let tiempo_inicio= %sysfunc(datetime());
options validvarname=any;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

LIBNAME MPDT  ORACLE PATH='REPORITF.WORLD'  SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME BOPERS ORACLE PATH='REPORITF.WORLD'  SCHEMA='BOPERS_ADM' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME R_SFRIES ORACLE PATH='REPORITF.WORLD'  SCHEMA='SFRIES_ADM'  USER='AMARINAOC' PASSWORD='amarinaoc2017';

proc sql noprint;
create table publicri.CONTRATOS_ITF_RESP AS 
SELECT * FROM publicri.CONTRATOS_ITF;

drop table publicri.CONTRATOS_ITF;
run;

DATA _null_;
	datei = input(put(intnx('month',today(),0,'begin'),yymmddn8.),$10.);
	datei2 = input(put(intnx('month',today(),0,'begin'),ddmmyyn8.),$10.);
	datef = input(put(intnx('month',today(),0,'end'),yymmddn8.),$10.);
	date9i = put(intnx('month',today(),0,'begin'),date9.);
	date9f = put(intnx('month',today(),0,'end'),date9.);
	datex = input(put(intnx('month',today(),0,'end'),yymmn6.),$10.);      /*cambiar 0 a -1 para ver cierre mes anterior*/
	datex1 = input(put(intnx('month',today(),-1,'end'),yymmn6.),$10.);      /*cambiar 0 a -1 para ver cierre mes anterior*/
	datex12 = input(put(intnx('month',today(),-12,'end'),yymmn6.),$10.);
	exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechai",datei);
	Call symput("fechai2",datei2);
	Call symput("fechaf",datef);
	Call symput("fec9i",date9i);
	Call symput("fec9f",date9f);
	Call symput("fechax", datex);
	Call symput("fechax1", datex1);
	Call symput("fechax12", datex12);
	Call symput("fechae",exec);
RUN;

%put &fechai;
%put &fechai2;
%put &fechaf;
%put &fec9i;
%put &fec9f;
%put &fechax;
%put &fechax1;
%put &fechax12;
%put &fechae;

PROC SQL noprint;
	SELECT MAX(EVAAM_FCH_PRO) INTO: MAX_FECHA
		FROM R_SFRIES.SFRIES_ALT_MOR;
QUIT;

PROC SQL;
	CREATE TABLE CON_SALDO AS 
		SELECT H.CODENT,H.CUENTA, H.CENTALTA
			FROM R_SFRIES.SFRIES_ALT_MOR AS A
				INNER JOIN MPDT.MPDT007 H ON SUBSTR(A.EVAAM_NRO_CTT,5,4)=H.CENTALTA AND SUBSTR(A.EVAAM_NRO_CTT,9,12)=H.CUENTA
					WHERE A.EVAAM_FCH_PRO = "&MAX_FECHA"DT
						AND EVAAM_SLD_TTL >=1
	;
QUIT;

PROC SQL;
	CONNECT TO ORACLE AS ITF (PATH="REPORITF.WORLD" USER='AMARINAOC' PASSWORD='amarinaoc2017');
	CREATE TABLE BLOQUEOS AS 
		SELECT * FROM CONNECTION TO ITF(
		SELECT A.CODENT, A.CENTALTA, A.CUENTA, A.CODBLQ,
			B.DESBLQ,B.DESBLQRED,B.INDAPLEMISOR,B.CONTCUR
		FROM MPDT178 A
			INNER JOIN MPDT060 B ON A.CODBLQ=B.CODBLQ 
			INNER JOIN (
				SELECT A.CODENT, A.CENTALTA, A.CUENTA, MAX(B.CONTCUR) MAX_FEC
					FROM MPDT178 A
						INNER JOIN MPDT060 B ON A.CODBLQ=B.CODBLQ
							WHERE A.LINEA = '0000'
								GROUP BY A.CODENT, A.CENTALTA, A.CUENTA
									) C ON A.CODENT=C.CODENT AND A.CENTALTA=C.CENTALTA AND A.CUENTA=C.CUENTA AND B.CONTCUR=C.MAX_FEC
								WHERE A.LINEA = '0000'
									)A
	;
QUIT;

PROC SQL;
	CONNECT TO ORACLE as ITF (PATH="REPORITF.WORLD" USER='AMARINAOC' PASSWORD='amarinaoc2017');
	CREATE TABLE TODO_CONTRATOS AS 
		SELECT  A.*,
			CASE 
				WHEN B.CUENTA IS NOT MISSING THEN 1 
				ELSE 0 
			END 
		AS T_SALDO,
			CASE 
				WHEN C.CUENTA IS NOT MISSING THEN 1 
				ELSE 0 
			END 
		AS T_BLQ,
			C.CODBLQ,C.DESBLQ,C.DESBLQRED,
		CASE 
			WHEN FECBAJA='0001-01-01' AND T_PAN=1 THEN 1 
			ELSE 0 
		END 
	AS CCTO_VIGENTE
		FROM CONNECTION TO ITF(
			SELECT DISTINCT A.CODENT,A.CUENTA,A.CENTALTA, A.CODENT||A.CENTALTA||A.CUENTA CONTRATO,
				A.FECALTA,A.FECBAJA,A.PRODUCTO,A.GRUPOLIQ,
				CAST(B.PEMID_GLS_NRO_DCT_IDE_K AS INT) RUT,
			CASE 
				WHEN B.PEMID_GLS_NRO_DCT_IDE_K>0 THEN 1 
				ELSE 0 
			END 
			T_RUT,
		CASE 
			WHEN C.CUENTA IS NOT NULL THEN 1 
			ELSE 0 
		END 
		T_PAN,
		A.MOTBAJA,D.DESMOT,D.DESMOTRED,
		B.PEMID_NRO_INN_IDE AS ID,
		E.CONPROD,E.DESCON,E.DESCONRED,
		F.VERSION,F.CLAMON,
		G.DESCRED DIA_DE_PAGO,G.DESCRIPCION
	FROM MPDT007 A 
		LEFT JOIN BOPERS_MAE_IDE B ON B.PEMID_NRO_INN_IDE=CAST(A.IDENTCLI AS INT)
		LEFT JOIN MPDT008 C ON A.CODENT=C.CODENT AND A.CENTALTA=C.CENTALTA AND A.CUENTA=C.CUENTA AND C.FECACUSER <> '0001-01-01'
		LEFT JOIN MPDT028 D ON A.MOTBAJA=D.MOTBAJA
		LEFT JOIN MPDT167 E ON A.CODENT=E.CODENT AND A.PRODUCTO=E.PRODUCTO AND A.SUBPRODU=E.SUBPRODU AND A.CONPROD=E.CONPROD
		LEFT JOIN MPDT494 F ON A.CODENT=F.CODENT AND A.CENTALTA=F.CENTALTA AND A.CUENTA=F.CUENTA 
		LEFT JOIN MPDT086 G ON A.GRUPOLIQ=G.CODGRUPO AND G.CODPROCESO = 1
			WHERE A.PRODUCTO NOT IN ('08','12','13') 
				/*('01','02','03','04','05','06','07')  */
				/*<>'08'  excluye contratos de cuenta vista*/
				/*<>'12'  excluye contratos de MC Chek*/
				/*<>'13'  excluye contratos de cuenta corriente*/
				)A
			LEFT JOIN CON_SALDO B ON A.CODENT=B.CODENT AND A.CENTALTA=B.CENTALTA AND A.CUENTA=B.CUENTA
			LEFT JOIN BLOQUEOS C ON A.CODENT=C.CODENT AND A.CENTALTA=C.CENTALTA AND A.CUENTA=C.CUENTA AND C.DESBLQ <>('MOROSIDAD RIESGO')
				WHERE PRODUCTO NOT IN ('08','12','13') 
	;
QUIT;

PROC SQL;
	CREATE TABLE DISTINTOS_RUTS AS
		SELECT RUT, MAX(CCTO_VIGENTE) AS CCTO_VIGENTE 
			FROM TODO_CONTRATOS
				WHERE RUT IS NOT MISSING
					GROUP BY RUT
	;
QUIT;

PROC SQL;
	CREATE TABLE TODO_CONTRATOS2 AS
		SELECT *,
			CASE 
				WHEN CCTO_VIGENTE=1 AND T_SALDO=1 AND PRODUCTO IN ('07','06','05','10','14')THEN 1
				WHEN CCTO_VIGENTE=1 AND T_SALDO=0 AND PRODUCTO IN ('07','06','05','10','14') THEN 2
				WHEN CCTO_VIGENTE=1 AND T_SALDO=1 AND PRODUCTO NOT IN ('07','06','05','10','14')THEN 3
				WHEN CCTO_VIGENTE=1 AND T_SALDO=0 AND PRODUCTO NOT IN ('07','06','05','10','14') THEN 4 
			END 
		AS PRIORIDAD_VIG,
			CASE 
				WHEN CCTO_VIGENTE=0 AND FECBAJA='0001-01-01' AND T_PAN=0 AND T_SALDO=1 AND PRODUCTO IN ('07','06','05','10','14') THEN 1
				WHEN CCTO_VIGENTE=0 AND FECBAJA='0001-01-01' AND T_PAN=0 AND T_SALDO=1 AND PRODUCTO NOT IN ('07','06','05','10','14') THEN 2
				WHEN CCTO_VIGENTE=0 AND FECBAJA='0001-01-01' AND T_PAN=0 AND T_SALDO=0 AND PRODUCTO IN ('07','06','05','10','14') THEN 3
				WHEN CCTO_VIGENTE=0 AND FECBAJA='0001-01-01' AND T_PAN=0 AND T_SALDO=0 AND PRODUCTO NOT IN ('07','06','05','10','14') THEN 4
				WHEN CCTO_VIGENTE=0 AND FECBAJA<>'0001-01-01' AND T_PAN=1 AND T_SALDO=1 AND PRODUCTO IN ('07','06','05','10','14') THEN 5
				WHEN CCTO_VIGENTE=0 AND FECBAJA<>'0001-01-01' AND T_PAN=1 AND T_SALDO=1 AND PRODUCTO NOT IN ('07','06','05','10','14') THEN 6
				WHEN CCTO_VIGENTE=0 AND FECBAJA<>'0001-01-01' AND T_PAN=1 AND T_SALDO=0 AND PRODUCTO IN ('07','06','05','10','14') THEN 7
				WHEN CCTO_VIGENTE=0 AND FECBAJA<>'0001-01-01' AND T_PAN=1 AND T_SALDO=0 AND PRODUCTO NOT IN ('07','06','05','10','14') THEN 8
				WHEN CCTO_VIGENTE=0 AND FECBAJA<>'0001-01-01' AND T_PAN=0 AND T_SALDO=1 AND PRODUCTO IN ('07','06','05','10','14') THEN 9
				WHEN CCTO_VIGENTE=0 AND FECBAJA<>'0001-01-01' AND T_PAN=0 AND T_SALDO=1 AND PRODUCTO NOT IN ('07','06','05','10','14') THEN 10
				WHEN CCTO_VIGENTE=0 AND FECBAJA<>'0001-01-01' AND T_PAN=0 AND T_SALDO=0 AND PRODUCTO IN ('07','06','05','10','14') THEN 11
				WHEN CCTO_VIGENTE=0 AND FECBAJA<>'0001-01-01' AND T_PAN=0 AND T_SALDO=0 AND PRODUCTO NOT IN ('07','06','05','10','14') THEN 12
			END 
		AS PRIORIDAD_NO_VIG
			FROM TODO_CONTRATOS
	;
QUIT;

PROC SQL;
	CREATE TABLE VIGENTES AS
		SELECT *
			FROM TODO_CONTRATOS2
				WHERE CCTO_VIGENTE=1
					ORDER BY RUT,PRIORIDAD_VIG,FECALTA DESC
	;
QUIT;

DATA VIGENTES2;
	SET VIGENTES;

	IF RUT=LAG(RUT) THEN
		FILTRO =1;
	ELSE FILTRO=0;
RUN;

PROC SQL;
	CREATE TABLE POR_ELIMINAR AS
		SELECT * FROM VIGENTES2
			WHERE FILTRO =1
				ORDER BY RUT
	;
QUIT;

PROC SQL noprint;
	DELETE * FROM VIGENTES2 WHERE FILTRO=1
	;
QUIT;

PROC SQL;
	CREATE TABLE NO_VIGENTES AS
		SELECT A.*
			FROM TODO_CONTRATOS2 A
				LEFT JOIN VIGENTES2 B ON A.RUT=B.RUT
					WHERE A.CCTO_VIGENTE=0
						AND B.RUT IS MISSING
					ORDER BY A.RUT,A.PRIORIDAD_NO_VIG,A.FECALTA DESC,A.FECBAJA DESC
	;
QUIT;

DATA NO_VIGENTES2;
	SET NO_VIGENTES;

	IF RUT=LAG(RUT) THEN
		FILTRO =1;
	ELSE FILTRO=0;
RUN;

PROC SQL;
	CREATE TABLE POR_ELIMINAR2 AS
		SELECT * FROM NO_VIGENTES2
			WHERE FILTRO =1
				ORDER BY RUT
	;
QUIT;

PROC SQL noprint;
	DELETE * FROM NO_VIGENTES2 WHERE FILTRO=1
	;
QUIT;

PROC SQL;
	CREATE TABLE PUBLICIN.CONTRATOS_ITF AS
		SELECT *,today() format = date9. as FECHA_ACT FROM VIGENTES2
	;
QUIT;

PROC SQL;
	CREATE TABLE PUBLICIN.CONTRATOS_ITF_RIESGO_&fechai2 AS 
		SELECT *,today() format = date9. as FECHA_ACT FROM VIGENTES2
			UNION
		SELECT *,today() format = date9. as FECHA_ACT FROM NO_VIGENTES2
	;
QUIT;

PROC SQL noprint;
	SELECT CCTO_VIGENTE,COUNT(DISTINCT RUT) FROM DISTINTOS_RUTS GROUP BY CCTO_VIGENTE
		OUTER UNION CORR
			SELECT CCTO_VIGENTE,COUNT(DISTINCT RUT) FROM PUBLICIN.CONTRATOS_ITF_RIESGO_&fechai2 GROUP BY CCTO_VIGENTE
	;
QUIT;

PROC SQL;
	CREATE TABLE PUBLICRI.CONTRATOS_ITF_RIESGO_&fechai2 AS
		SELECT *
			FROM PUBLICIN.CONTRATOS_ITF_RIESGO_&fechai2
	;
QUIT;

PROC SQL;
	CREATE TABLE PUBLICRI.CONTRATOS_ITF AS
		SELECT *
			FROM PUBLICIN.CONTRATOS_ITF
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
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_GOBIERNO_DAT_1';
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
/*	TO = ("&DEST_1")*/
	TO = ("&DEST_4","&DEST_5")
	CC = ("&DEST_1", "&DEST_2", "&DEST_3", "fjnorambuena@bancoripley.com")
	SUBJECT = ("MAIL_AUTOM: Proceso CONTRATOS_ITF");
	FILE OUTBOX;
	PUT "Estimados:";
	PUT "		Proceso CONTRATOS_ITF, ejecutado con fecha: &fechaeDVN";
	PUT "  		Información disponible en SAS: PUBLICIN.CONTRATOS_ITF";
	PUT;
	PUT;
	PUT;
	PUT 'Proceso Vers. 01';
	PUT;
	PUT;
	PUT 'Atte.';
	PUT 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;

FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
