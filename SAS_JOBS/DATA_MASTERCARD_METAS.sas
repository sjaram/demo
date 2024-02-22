/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================    DATA_MASTERCARD_METAS			 ===============================*/

/* CONTROL DE VERSIONES
/* 2023-07-05 -- v05	-- Sergio J. --  Se agrega delete a AWS y se modifica export 
/* 2023-06-29 -- v03	-- Kevin G.	 --  Cambio en campo rut a ID_Usuario, + tabla de salida aws, 
										 de CAMPAIGN_INPUT_TR_TRX_ACUM a CAMPAIGN_INPUT_TR_TRX_DORMIDOS
/* 2023-06-20 -- v02	-- Kevin G.	 --  Modificacion, nuevas peticiones negocio.
/* 2023-04-25 -- v01	-- David V.	 --  Versionamiento, automatización, export aws.
/* 2023-04-21 -- v00	-- Kevin G.	 --  Versión Original

/* VARIABLE TIEMPO - INICIO */
%let tiempo_inicio= %sysfunc(datetime());
options validvarname=any;

/*==================================================================================================*/
/*==============================    DATA_MASTERCARD_METAS			 ===============================*/
%let n=0;
%let libreria=result;

DATA _NULL_;
	fecha = put(intnx('day',intnx('day', today(),-&n.-1,  'begin'), 1), yymmddn8.);
	periodo = input(put(intnx('month',today(),-&n.,'end'),yymmn6. ),$10.);
	periodo_ant = input(put(intnx('month',today(),-&n.-1,'end'),yymmn6. ),$10.);
	Call symput("fecha", fecha);
	Call symput("periodo", periodo);
	Call symput("periodo_ant", periodo_ant);
RUN;

%put &fecha;
%put &periodo;
%put &periodo_ant;

/*BASE 1*/
/* VENTA MES ACTUAL SPOS*/
proc sql;
	create table compras_spos1_MA AS SELECT
		RUT,
		SUM(VENTA_TARJETA) AS MONTO,
		'TAM' AS TIPO_TARJETA
	FROM PUBLICIN.SPOS_AUT_&PERIODO. 
		GROUP BY RUT, CALCULATED TIPO_TARJETA
	;
QUIT;

proc sql;
	create table compras_tda1_MA AS SELECT
		RUT,
		SUM(CAPITAL + PIE) AS MONTO,
		'TAM_TDA' AS TIPO_TARJETA
	FROM PUBLICIN.TDA_ITF_&PERIODO. 
		GROUP BY RUT, CALCULATED TIPO_TARJETA
	;
QUIT;

proc sql;
	create table compras_tda2_MA AS SELECT
		RUT,
		SUM(VENTA_TARJETA) AS MONTO,
		'MCD_TDA' AS TIPO_TARJETA
	FROM PUBLICIN.TDA_MCD_&PERIODO. 
		GROUP BY RUT, CALCULATED TIPO_TARJETA
	;
QUIT;

proc sql;
	create table compras_tda3_MA AS SELECT
		RUT,
		SUM(VENTA_TARJETA) AS MONTO,
		'CTACTE_TDA' AS TIPO_TARJETA
	FROM PUBLICIN.TDA_CTACTE_&PERIODO. 
		GROUP BY RUT, CALCULATED TIPO_TARJETA
	;
QUIT;

proc sql;
	create table compras_spos2_MA AS SELECT
		RUT,
		SUM(VENTA_TARJETA) AS MONTO,
		'MCD' AS TIPO_TARJETA
	FROM PUBLICIN.SPOS_MCD_&PERIODO. 
		GROUP BY RUT, CALCULATED TIPO_TARJETA
	;
QUIT;

proc sql;
	create table compras_spos3_MA AS SELECT
		RUT,
		SUM(VENTA_TARJETA) AS MONTO,
		'CTACTE' AS TIPO_TARJETA
	FROM PUBLICIN.SPOS_CTACTE_&PERIODO.
		GROUP BY RUT, CALCULATED TIPO_TARJETA
	;
QUIT;

proc sql;
	create table compras_spos4_MA AS SELECT
		RUT,
		SUM(monto_recaudado) AS MONTO,
		'SEG' AS TIPO_TARJETA
	from publicin.TRX_SEGUROS_&periodo.
		where CODCONREC not in ('S201','S083','S170')
			and TIPO_SEGURO<>'SEGUROS TARJETA'
			and ( monto_recaudado<>476454338)
		GROUP BY RUT, CALCULATED TIPO_TARJETA
	;
QUIT;

PROC SQL;
	CREATE TABLE COMPRAS_SPOS_MA AS SELECT * FROM compras_spos1_MA OUTER UNION CORR SELECT 
		* FROM compras_spos2_MA OUTER UNION CORR SELECT * FROM compras_spos3_MA 
	OUTER UNION CORR SELECT * FROM compras_spos4_MA
	OUTER UNION CORR SELECT * FROM compras_TDA1_MA
	OUTER UNION CORR SELECT * FROM compras_TDA2_MA
	OUTER UNION CORR SELECT * FROM compras_TDA3_MA

	;
QUIT;

PROC SQL;
	CREATE TABLE BASE1 AS SELECT 
		A.RUT,
		SUM(A.MONTO) AS VENTA_TOTAL,
		B.MONTO AS VENTA_TAM,
		C.MONTO AS VENTA_MCD,
		D.MONTO AS VENTA_CTACTE,
		E.MONTO AS VENTA_SEG,
		F.MONTO AS VENTA_TAM_TDA,
		G.MONTO AS VENTA_MCD_TDA,
		H.MONTO AS VENTA_CTACTE_TDA,
	CASE 
		WHEN B.RUT IS NOT NULL THEN 1 
		ELSE 0 
	END 
AS TAM,
	CASE 
		WHEN C.RUT IS NOT NULL THEN 1 
		ELSE 0 
	END 
AS MCD,
	CASE 
		WHEN D.RUT IS NOT NULL THEN 1 
		ELSE 0 
	END 
AS CTACTE,
	CASE 
		WHEN E.RUT IS NOT NULL THEN 1 
		ELSE 0 
	END 
AS SEG,
	CASE 
		WHEN F.RUT IS NOT NULL THEN 1 
		ELSE 0 
	END 
AS TAM_TDA,
	CASE 
		WHEN G.RUT IS NOT NULL THEN 1 
		ELSE 0 
	END 
AS MCD_TDA,
	CASE 
		WHEN H.RUT IS NOT NULL THEN 1 
		ELSE 0 
	END 
AS CTACTE_TDA
	FROM COMPRAS_SPOS_MA AS A
		LEFT JOIN compras_spos1_MA AS B ON A.RUT=B.RUT
		LEFT JOIN compras_spos2_MA AS C ON A.RUT=C.RUT
		LEFT JOIN compras_spos3_MA AS D ON A.RUT=D.RUT
		LEFT JOIN compras_spos4_MA AS E  ON A.RUT=E.RUT
		LEFT JOIN compras_TDA1_MA AS F  ON A.RUT=F.RUT
		LEFT JOIN compras_TDA2_MA AS G  ON A.RUT=G.RUT
		LEFT JOIN compras_TDA3_MA AS H  ON A.RUT=H.RUT
			GROUP BY
				A.RUT, 
				CALCULATED TAM,
				CALCULATED MCD ,
				CALCULATED CTACTE,
				CALCULATED SEG,
				CALCULATED TAM_TDA,
				CALCULATED MCD_TDA,
				CALCULATED CTACTE_TDA,
				B.MONTO,
				C.MONTO, 
				D.MONTO,
				E.MONTO,
				F.MONTO,
				G.MONTO,
				H.MONTO
	;
QUIT;

PROC SQL;
	CREATE TABLE BASE1_FINAL AS SELECT
		RUT, 
		VENTA_TOTAL, 
		SUM(VENTA_TAM,VENTA_SEG, VENTA_TAM_TDA) AS VENTA_TC,
		SUM(VENTA_MCD,VENTA_CTACTE, VENTA_MCD_TDA ,VENTA_CTACTE_TDA) AS VENTA_TD

	FROM BASE1 
		GROUP BY RUT, VENTA_TOTAL
	;
QUIT;

PROC SQL;
	CREATE TABLE DATA_MASTERCARD_METAS AS SELECT distinct
		A.RUT as ID_Usuario,
		A.META,
		A.PREMIO,
		A.CONTROL,
		A.GRUPO,
		COALESCE(B.VENTA_TOTAL,0) AS TOTAL_MES_ACTUAL,
		COALESCE(B.VENTA_TC,0) AS TC_MES_ACTUAL,
		COALESCE(B.VENTA_TD,0) AS TD_MES_ACTUAL

	FROM KGONZALE.BASE_MC_JULIO AS A
		LEFT JOIN BASE1_FINAL AS B ON A.RUT=B.RUT
	;
QUIT;

PROC SQL;
	CREATE TABLE PROGRESO AS SELECT
		*,
	CASE 
		WHEN GRUPO='DB_A' THEN (META- TC_MES_ACTUAL)
		when GRUPO='DB_B' THEN (META- TD_MES_ACTUAL) 
		ELSE . 
	END 
AS PROGRESO
	FROM DATA_MASTERCARD_METAS
	;
QUIT;

PROC SQL;
	CREATE TABLE CUMPLE AS SELECT 
		*,
	CASE 
		WHEN PROGRESO<=0 AND PROGRESO IS NOT NULL THEN 1 
		ELSE 0 
	END 
AS CUMPLE_META,
	put(progreso,commax10.) as FALTA_META,
	put(META,commax10.) as META2,
	put(PREMIO,commax10.) as PREMIO2
FROM PROGRESO
	;
QUIT;

proc sql;
	create table &libreria..DATA_MASTERCARD_METAS AS SELECT * FROM CUMPLE
	;
QUIT;

/*borrar todas las tablas del work, tener cuidado con tablas internas si no borrara toda la libreria*/

proc datasets library=WORK kill noprint;
run;

quit;

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================    Export personalizado para AWS    ===============================*/

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(CAMPAIGN_INPUT_TR_TRX_DORMIDOS,raw,campaign,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/CAMPAIGN.sas";
%CAMPAIGN(CAMPAIGN_INPUT_TR_TRX_DORMIDOS,&libreria..DATA_MASTERCARD_METAS,raw,campaign,0);

/*==================================================================================================*/
/*==================================   ENVÍO AUTOMATICO CORREO NOTIF.    ===========================*/
data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;

data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN);
RUN;

%put &fechaeDVN;

/*==================================   EMAIL CON CASILLA VARIABLE ================================*/
proc sql noprint;
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_SPOS_2';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;
%put &=DEST_5;

data _null_;
	FILENAME OUTBOX EMAIL
		FROM = ("&EDP_BI")
		TO = ("&DEST_4","&DEST_5")
		CC = ("&DEST_1", "&DEST_2", "&DEST_3")
		SUBJECT = ("MAIL_AUTOM: Proceso DATA_MASTERCARD_METAS");
	FILE OUTBOX;
	PUT "Estimados:";
	PUT "      Proceso DATA_MASTERCARD_METAS, ejecutado con fecha: &fechaeDVN";
	PUT "      Tabla Disponible en SAS: &libreria..DATA_MASTERCARD_METAS";
	PUT;
	PUT;
	PUT;
	PUT 'Proceso Vers. 05';
	PUT;
	PUT;
	PUT 'Atte.';
	PUT 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;

FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
