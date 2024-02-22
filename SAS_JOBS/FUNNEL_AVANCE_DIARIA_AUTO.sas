/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	FUNNEL_AVANCE_DIARIA_AUTO	================================*/

/* CONTROL DE VERSIONES
/* 2022-12-15 -- v05 -- David V. 	-- Cambio en el campo Canal por Origen y campo rut.
/* 2022-07-22 -- v04 -- René F. 	-- Actualización
/* 2022-07-22 -- v03 -- Sergio J. 	-- Modificación de conexión a Segcom.
/* 2022-04-21 -- v02 -- David V.	-- Versión para server SAS, comentarios, no prints, tiempo y mail final. 
/* 2022-04-21 -- v01 -- René F. 	-- Versión Original

/* INFORMACIÓN:
Proceso que 

(IN) Tablas requeridas o conexiones a BD:
	

(OUT) Tablas de Salida o resultado:
*/
/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria  = PUBLICIN;
options validvarname=any;

/********************************************************/
/*********************FUNNEL AVANCE*********************/
/*===============================================================================================================================================================*/
/*=== MACRO FECHAS MES ==============================================================================================================================================*/
/*===============================================================================================================================================================*/
DATA _null_;
	dated = input(put(intnx('month',today(),0,'begin'),date9. ),$10.);
	date0 = input(put(intnx('month',today(),0,'same'),yymmn6. ),$10.);
	datef = input(put(intnx('day',today(),0,'same'),date9. ),$10.);
	Call symput("periodo", date0);
	Call symput("fechad", dated);
	Call symput("fechaf", datef);
RUN;

%put &periodo; /*periodo actual */
%put &fechad;/*fecha inicio actual   */
%put &fechaf;/*fecha fin actual */
/********************************************************************************************/
/***************************VISITAS POR CANAL***********************************************/
%put==================================================================================================;
%put [01.00] Extrae visitas para los canales TERMINAL DE VENTA;
%put==================================================================================================;

PROC SQL;
	CREATE TABLE WORK.VISITAS_TOTALES_TV AS 
		SELECT t1.rut AS RUT_CLIENTE , 
			t1.rut_real , 
			t1.n_vis AS VISITA, 
			t1.fecha, 
			t1.sucursal, 
			t1.origen, 
			t1.tipo, 
			t2.NOMB_ORIGEN as VIA , 
			t2.NOMB_TIPO
		FROM PUBLICIN.TABLON_VISITAS_&periodo t1, PMUNOZ.PARAMETRICA_VISITAS t2
			WHERE (t1.origen = t2.COD_ORIGEN AND t1.tipo = t2.COD_TIPO)
				AND T2.NOMB_ORIGEN='TV'
				AND T1.SUCURSAL NOT = 39 /* no considera INTERNET */
	AND t1.fecha >= "&fechad"d  
	AND t1.fecha <  "&fechaf"d
	AND  t1.rut_real =1  /* que exista el rut */;
QUIT;

PROC SQL noprint;
	/*CREATE TABLE WORK.QUERY_FOR_VISITAS_TOTALES_TDA_20 AS */
	SELECT /* MAX_of_FECHA_TRUNC */
		(MAX(t1.fecha)) FORMAT=DDMMYY20. AS fecha_max_tv FROM WORK.VISITAS_TOTALES_TV t1;
QUIT;

/*VISITAS CON MARCA DE OFERTA */
PROC SQL;
	CREATE TABLE VISITAS_TOT_MARCA_CON_OF AS 
		SELECT t1.RUT_CLIENTE,
			/*1 AS*/
	t1.VISITA, 
	t1.VIA,
	t2.RUT_REGISTRO_CIVIL,
	CASE 
		WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
		ELSE 0 
	END 
	AS VIS_CON_OFERTA, 
		t2.AVANCE_FINAL, 
		t2.DISPOFINAL,
		T2.RANGO_PROB,
		T2.ACTIVIDAD_TR
		FROM WORK.VISITAS_TOTALES_TV t1
			LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT_CLIENTE = t2.RUT_REGISTRO_CIVIL) 
	;
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOT_MATRIZ_TV AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA, T1.RANGO_PROB, T1.ACTIVIDAD_TR FROM WORK.VISITAS_TOT_MARCA_CON_OF t1 WHERE VIS_CON_OFERTA >=1 GROUP BY t1.VIA, T1.RANGO_PROB, T1.ACTIVIDAD_TR;
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOTALES_TV AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA FROM WORK.VISITAS_TOT_MARCA_CON_OF t1 GROUP BY t1.VIA;
QUIT;

%put==================================================================================================;
%put [02.00] Extrae visitas para los canales SUCURSAL BANCO;
%put==================================================================================================;

PROC SQL;
	CREATE TABLE WORK.VISITAS_TOTALES_BCO AS 
		SELECT t1.rut AS RUT_CLIENTE , 
			t1.rut_real , 
			t1.n_vis AS VISITA, 
			t1.fecha, 
			t1.sucursal, 
			t1.origen, 
			t1.tipo, 
			'BCO' AS /*t2.NOMB_ORIGEN*/
	VIA , 
	t2.NOMB_TIPO
	FROM PUBLICIN.TABLON_VISITAS_&periodo t1, 
		PMUNOZ.PARAMETRICA_VISITAS t2
		WHERE (t1.origen = t2.COD_ORIGEN AND t1.tipo = t2.COD_TIPO)
			AND t1.fecha >= "&fechad"d  
			AND t1.fecha <  "&fechaf"d
			AND t1.rut_real =1  /* que exista el rut */
	AND T2.NOMB_ORIGEN='BANCO'
	AND t2.NOMB_TIPO IN ('PAGO EPU','PAGO CONSUMO')/* CONSIDERA SOLO PAGOS EN CAJA , VISITAS CCSS NO SE CONSIDERA PORQUE NO SE PUEDE CURSAR AV*/

	/*AND t1.origen = 0*/
	/*BANCO */
	/*and t1.tipo in(3,4)*/
	/* ('PAGO EPU','PAGO CONSUMO')*/
	;
QUIT;

PROC SQL noprint;
	/*CREATE TABLE WORK.QUERY_FOR_VISITAS_TOTALES_TDA_20 AS */
	SELECT /* MAX_of_FECHA_TRUNC */
		(MAX(t1.fecha)) FORMAT=DDMMYY20. AS fecha_max_bco FROM VISITAS_TOTALES_BCO t1;
QUIT;

PROC SQL;
	CREATE TABLE VISITAS_TOT_MARCA_CON_OF_BCO AS 
		SELECT t1.RUT_CLIENTE,
			T1.VISITA, 
			t1.VIA,
			t2.RUT_REGISTRO_CIVIL,
		CASE 
			WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
			ELSE 0 
		END 
	AS VIS_CON_OFERTA, 
		t2.AVANCE_FINAL, 
		t2.DISPOFINAL,
		T2.RANGO_PROB,
		T2.ACTIVIDAD_TR
	FROM WORK.VISITAS_TOTALES_BCO t1
		LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT_CLIENTE = t2.RUT_REGISTRO_CIVIL);
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOT_MATRIZ_BCO AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA, T1.RANGO_PROB, T1.ACTIVIDAD_TR FROM WORK.VISITAS_TOT_MARCA_CON_OF_BCO t1 WHERE VIS_CON_OFERTA >=1 GROUP BY t1.VIA, T1.RANGO_PROB, T1.ACTIVIDAD_TR;
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOTALES_BCO AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA FROM WORK.VISITAS_TOT_MARCA_CON_OF_BCO t1 GROUP BY t1.VIA;
QUIT;

%put==================================================================================================;
%put [03.00] Extrae visitas para los canal TERMINAL FINANCIERO;
%put==================================================================================================;

PROC SQL;
	CREATE TABLE WORK.VISITAS_TOTALES_TF AS 
		SELECT t1.rut AS RUT_CLIENTE , 
			t1.rut_real , 
			t1.n_vis AS VISITA, 
			t1.fecha, 
			t1.sucursal, 
			t1.origen, 
			t1.tipo, 
			t2.NOMB_ORIGEN as VIA , 
			t2.NOMB_TIPO
		FROM PUBLICIN.TABLON_VISITAS_&periodo t1, PMUNOZ.PARAMETRICA_VISITAS t2
			WHERE (t1.origen = t2.COD_ORIGEN AND t1.tipo = t2.COD_TIPO)
				AND T2.NOMB_ORIGEN='TF'
				AND t1.fecha >= "&fechad"d  
				AND t1.fecha <  "&fechaf"d
				AND t1.rut_real =1  /* que exista el rut */
	;
QUIT;

PROC SQL noprint;
	/*CREATE TABLE WORK.QUERY_FOR_VISITAS_TOTALES_TDA_20 AS */
	SELECT /* MAX_of_FECHA_TRUNC */
		(MAX(t1.fecha)) FORMAT=DDMMYY20. AS fecha_max_tf FROM VISITAS_TOTALES_TF t1;
QUIT;

/*3019977*/
PROC SQL;
	CREATE TABLE VISITAS_TOT_MARCA_CON_OF_TF AS 
		SELECT t1.RUT_CLIENTE,
			T1.VISITA, 
			t1.VIA,
			t2.RUT_REGISTRO_CIVIL,
		CASE 
			WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
			ELSE 0 
		END 
	AS VIS_CON_OFERTA, 
		t2.AVANCE_FINAL, 
		t2.DISPOFINAL,
		T2.RANGO_PROB,
		T2.ACTIVIDAD_TR
	FROM WORK.VISITAS_TOTALES_TF t1
		LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT_CLIENTE = t2.RUT_REGISTRO_CIVIL);
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOT_MATRIZ_TF AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA, T1.RANGO_PROB, T1.ACTIVIDAD_TR FROM WORK.VISITAS_TOT_MARCA_CON_OF_TF t1 WHERE VIS_CON_OFERTA >=1 GROUP BY t1.VIA, T1.RANGO_PROB, T1.ACTIVIDAD_TR;
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOTALES_TF AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA FROM WORK.VISITAS_TOT_MARCA_CON_OF_TF t1 GROUP BY t1.VIA;
QUIT;

%put==================================================================================================;
%put [04.00] Extrae visitas para los canales MOVIL ( blue Bird );
%put==================================================================================================;

/* VISITA UNICA POR DIA Y RUT

proc sql;
create table VISITAS_TOTALES_MOVIL as 
select DISTINCT  
rut AS RUT_CLIENTE,
datepart(fecha) format=date9. as FECHA_TRUNC ,
case when (rut between 1000000 and 50000000) and rut not in (1111111,2222222,3333333,4444444,5555555,
6666666,7777777,8888888,9999999,11111111,22222222,33333333,44444444) then 1 else 0 end as HUMANO,
'MOVIL' AS VIA 
from TRANSACCIONES_CAMP_&PERIODO
WHERE CANAL=9
AND CALCULATED HUMANO=1
ORDER BY rut
;quit;*/
PROC SQL;
	CREATE TABLE WORK.VISITAS_TOTALES_MOVIL AS 
		SELECT t1.rut AS RUT_CLIENTE , 
			t1.rut_real , 
			t1.n_vis AS VISITA, 
			t1.fecha, 
			t1.sucursal, 
			t1.origen, 
			t1.tipo, 
			t2.NOMB_ORIGEN as VIA , 
			t2.NOMB_TIPO
		FROM PUBLICIN.TABLON_VISITAS_&periodo t1, PMUNOZ.PARAMETRICA_VISITAS t2
			WHERE (t1.origen = t2.COD_ORIGEN AND t1.tipo = t2.COD_TIPO)
				AND T2.NOMB_ORIGEN='MOVIL'
				AND t1.fecha >= "&fechad"d  
				AND t1.fecha <  "&fechaf"d
				AND t1.rut_real =1  /* que exista el rut */
	;
QUIT;

PROC SQL noprint;
	/*CREATE TABLE WORK.QUERY_FOR_VISITAS_TOTALES_TDA_20 AS */
	SELECT /* MAX_of_FECHA_TRUNC */
		(MAX(t1.fecha)) FORMAT=DDMMYY20. AS fecha_max_movil FROM VISITAS_TOTALES_MOVIL t1 ;
QUIT;

PROC SQL;
	CREATE TABLE VISITAS_TOT_MARCA_CON_OF_MOVIL AS 
		SELECT t1.RUT_CLIENTE,
			1 as VISITA, 
			t1.VIA,
			t2.RUT_REGISTRO_CIVIL,
		CASE 
			WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
			ELSE 0 
		END 
	AS VIS_CON_OFERTA, 
		t2.AVANCE_FINAL, 
		t2.DISPOFINAL,
		T2.RANGO_PROB,
		T2.ACTIVIDAD_TR
	FROM WORK.VISITAS_TOTALES_MOVIL t1
		LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT_CLIENTE = t2.RUT_REGISTRO_CIVIL);
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOT_MATRIZ_MOVIL AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA, T1.RANGO_PROB, T1.ACTIVIDAD_TR FROM WORK.VISITAS_TOT_MARCA_CON_OF_MOVIL t1 WHERE VIS_CON_OFERTA >=1 GROUP BY t1.VIA, T1.RANGO_PROB, T1.ACTIVIDAD_TR;
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOTALES_MOVIL AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA FROM WORK.VISITAS_TOT_MARCA_CON_OF_MOVIL t1 GROUP BY t1.VIA;
QUIT;

/*
3069044	1	HB PRIVADO	APP
720448	2	HB PRIVADO	HB PRIVADO
12481254	1	HB PUBLICO	HB PUBLICO*/

/*VISITAS*/
/*CANAL HB*/
/*838320*/
%put======================================================================================================;
%put [05.00] Extrae visitas para los canale HB ( NO SE ESTA CONSIDERANDO , OFICIAL ES EL FUNNEL DIGITAL );
%put======================================================================================================;

PROC SQL;
	CREATE TABLE WORK.VISITA_HB AS 
		SELECT t1.rut AS RUT_CLIENTE , 
			t1.rut_real , 
			t1.n_vis AS VISITA, 
			t1.fecha, 
			t1.sucursal, 
			t1.origen, 
			t1.tipo, 
			/*t2.NOMB_ORIGEN*/

	'HB'  as VIA , 
	t2.NOMB_TIPO
FROM PUBLICIN.TABLON_VISITAS_&periodo t1, PMUNOZ.PARAMETRICA_VISITAS t2
	WHERE (t1.origen = t2.COD_ORIGEN AND t1.tipo = t2.COD_TIPO)
		AND T2.NOMB_ORIGEN='HB PRIVADO'
		AND T2.NOMB_TIPO = 'HB PRIVADO'
		AND t1.fecha >= "&fechad"d  
		AND t1.fecha <  "&fechaf"d
		AND t1.rut_real =1  /* que exista el rut */
	;
QUIT;

PROC SQL noprint;
	/*CREATE TABLE WORK.QUERY_FOR_VISITAS_TOTALES_TDA_20 AS */
	SELECT /* MAX_of_FECHA_TRUNC */
		(MAX(t1.FECHA)) FORMAT=DDMMYY20. AS fecha_max_hb FROM VISITA_HB t1;
QUIT;

/*3019977*/
PROC SQL;
	CREATE TABLE VISITAS_TOT_HB_CON_OF AS 
		SELECT t1.RUT_CLIENTE,
			T1.VISITA, 
			t1.VIA,
			t2.RUT_REGISTRO_CIVIL,
		CASE 
			WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
			ELSE 0 
		END 
	AS VIS_CON_OFERTA, 
		t2.AVANCE_FINAL, 
		t2.DISPOFINAL
	FROM WORK.VISITA_HB t1
		LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT_CLIENTE = t2.RUT_REGISTRO_CIVIL) 
	;
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOTALES_HB AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA FROM WORK.VISITAS_TOT_HB_CON_OF t1 GROUP BY t1.VIA;
QUIT;

%put======================================================================================================;
%put [05.00] Extrae visitas para los canale APP ( NO SE ESTA CONSIDERANDO , OFICIAL ES EL FUNNEL DIGITAL );
%put======================================================================================================;

PROC SQL;
	CREATE TABLE WORK.VISITA_APP AS 
		SELECT t1.rut AS RUT_CLIENTE , 
			t1.rut_real , 
			t1.n_vis AS VISITA, 
			t1.fecha, 
			t1.sucursal, 
			t1.origen, 
			t1.tipo, 
			/*t2.NOMB_ORIGEN*/

	'APP'  as VIA , 
	t2.NOMB_TIPO
FROM PUBLICIN.TABLON_VISITAS_&periodo t1, PMUNOZ.PARAMETRICA_VISITAS t2
	WHERE (t1.origen = t2.COD_ORIGEN AND t1.tipo = t2.COD_TIPO)
		AND T2.NOMB_ORIGEN='HB PRIVADO'
		AND T2.NOMB_TIPO = 'APP'
		AND t1.fecha >= "&fechad"d  
		AND t1.fecha <  "&fechaf"d
		AND t1.rut_real =1  /* que exista el rut */
	;
QUIT;

PROC SQL noprint;
	/*CREATE TABLE WORK.QUERY_FOR_VISITAS_TOTALES_TDA_20 AS */
	SELECT /* MAX_of_FECHA_TRUNC */
		(MAX(t1.FECHA)) FORMAT=DDMMYY20. AS fecha_max_app FROM VISITA_APP t1;
QUIT;

/*3019977*/
PROC SQL;
	CREATE TABLE VISITAS_TOT_APP_CON_OF AS 
		SELECT t1.RUT_CLIENTE,
			T1.VISITA, 
			t1.VIA,
			t2.RUT_REGISTRO_CIVIL,
		CASE 
			WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
			ELSE 0 
		END 
	AS VIS_CON_OFERTA, 
		t2.AVANCE_FINAL, 
		t2.DISPOFINAL
	FROM WORK.VISITA_APP t1
		LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT_CLIENTE = t2.RUT_REGISTRO_CIVIL) 
	;
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOTALES_APP AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA FROM WORK.VISITAS_TOT_APP_CON_OF t1 GROUP BY t1.VIA;
QUIT;

%put======================================================================================================;
%put [06.00] Consolida resumen visitas y ofertas funnel;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE &libreria..FUNNELAV_VIS_MES_MATRIZ_ACTUAL AS
		SELECT * FROM ( SELECT *,3 as n
			FROM resumen_VISITAS_TOT_MATRIZ_TF
				UNION SELECT *,2 as n
			FROM resumen_VISITAS_TOT_MATRIZ_BCO
				UNION SELECT *,1 as n
			FROM resumen_VISITAS_TOT_MATRIZ_TV
				/*UNION SELECT *,4 as n
			FROM resumen_VISITAS_TOT_MATRIZ_HB
				UNION SELECT *,5 as n
			FROM resumen_VISITAS_TOT_MATRIZ_APP*/
				UNION SELECT *,6 as n
			FROM resumen_VISITAS_TOT_MATRIZ_MOVIL)
				ORDER BY N
	;
QUIT;

PROC SQL;
	CREATE TABLE &libreria..FUNNELAV_VISITA_MES_ACTUAL AS
		SELECT * FROM ( SELECT *,3 as n
			FROM resumen_VISITAS_TOTALES_TF
				UNION SELECT *,2 as n
			FROM resumen_VISITAS_TOTALES_BCO
				UNION SELECT *,1 as n
			FROM resumen_VISITAS_TOTALES_TV
				/*UNION SELECT *,4 as n
			FROM resumen_VISITAS_TOTALES_HB
				UNION SELECT *,5 as n
			FROM resumen_VISITAS_TOTALES_APP*/
				UNION SELECT *,6 as n
			FROM resumen_VISITAS_TOTALES_MOVIL)
				ORDER BY N
	;
QUIT;

/********************************************************************************************/
/***************************TRANSACCIONES POR CANAL*****************************************/
%put======================================================================================================;
%put [07.00] arma transacciones canales;
%put======================================================================================================;
%put======================================================================================================;
%put [07.01] trx canales digitales ( no se ocupa );
%put======================================================================================================;

/*LIBNAME QANEWHB ORACLE  PATH="QANEW.WORLD"  SCHEMA=HBPRI_ADM  USER=RIPLEYC  PASSWORD='ri99pley';

PROC SQL;
 CREATE TABLE TRX_HB_APP AS 
 SELECT  iNPUT((SUBSTR(HDVOU_NOM_NOM_USR,1,(LENGTH(HDVOU_NOM_NOM_USR)-1))),BEST.) as rut,
HDVOU_NOM_NOM_USR,
HDVOU_MNT_MNT_PAG as CAPITAL,
HDVOU_COC_CNL,
CASE when t1.HDVOU_COC_CNL NOT LIKE ('85') then 'HB'
      WHEN t1.HDVOU_COC_CNL= '85' then 'APP' END AS VIA,HDVOU_COC_TOP_IDE,HDVOU_FCH_CPR
    FROM QANEWHB.HBPRI_HIS_DET_VOU t1
WHERE 'x'='x'
and t1.HDVOU_FCH_CPR  >= "&fechad"d  
and  t1.HDVOU_FCH_CPR < "&fechaf"d
AND t1.HDVOU_COC_TOP_IDE = 'CASH_ADVANCE'
;QUIT;*/

/* correccion de trx mal ingresadas en parametria */
proc sql;
	create table TRX_AV_ok_&periodo as
		select *, 
			case 
				when sucursal=4 and N_CAJA =1 then 1 
				else 0 
			end 
		as eliminar
			from PUBLICIN.TRX_AV_&periodo
				/*where calculated eliminar not =1*/
	;
quit;

PROC SQL;
	CREATE TABLE TRX_AV_&periodo AS 
		SELECT t1.*,1 AS TRX,
			CASE 
				WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
				ELSE 0 
			END 
		AS T_OFERTA,
			CASE 
				WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN T1.CAPITAL 
				ELSE 0 
			END 
		AS CAPITAL_OF,
			CASE 
				WHEN t3.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
				ELSE 0 
			END 
		AS T_OFERTA_AD /*debieses ser pwa debe cambiar*/
	FROM (SELECT RUT,CAPITAL,VIA  FROM TRX_AV_ok_&periodo /*PUBLICIN.TRX_AV_&periodo */ /* error en parametria al salir pwa*/
		/*WHERE VIA NOT IN ('APP','HB')
		AND (input(compress(fecfac,"-"),yymmdd10.))  >= "&fechad"d 
		and (input(compress(fecfac,"-"),yymmdd10.)) < "&fechaf"d 
	OUTER UNION CORR SELECT RUT,CAPITAL,VIA FROM  TRX_HB_APP */)t1
		LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT = t2.RUT_REGISTRO_CIVIL)
		LEFT JOIN KMARTINE.AVANCE_&periodo t3 ON (t1.RUT = t3.RUT_REGISTRO_CIVIL)/*	
			WHERE (input(compress(t1.fecfac,"-"),yymmdd10.))  >= "&fechad"d 
				and (input(compress(t1.fecfac,"-"),yymmdd10.)) < "&fechaf"d  AND T1.VIA NOT ='APP'*/
	;
QUIT;

PROC SQL;
	CREATE TABLE &libreria..FUNNELAV_TRX_MES_ACTUAL AS 
		SELECT /* SUM_of_TRX */
	&periodo AS PERIODO,
	(SUM(t1.TRX)) AS N_TRX, 
	/* SUM_of_T_OFERTA */
	(SUM(t1.T_OFERTA)) AS N_TRX_OFERTA, /* COUNT_DISTINCT_of_RUT */
	(COUNT(DISTINCT(t1.RUT))) AS CLIENTES, /* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST32. AS VENTA, /* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL_OF)) FORMAT=BEST32. AS VENTA_OFERTA, VIA FROM WORK.TRX_AV_&periodo t1 WHERE T1.VIA NOT IN ('TLMK',' ') GROUP BY VIA ;
QUIT;

/********************************************************************************************/
/************************************* USO AVANCE *******************************************/
/********************************************************************************************/
/***************************TRANSACCIONES POR CANAL*****************************************/
%put======================================================================================================;
%put [08.00] Arma USO canales;
%put======================================================================================================;
%put======================================================================================================;
%put [08.01] USO canal TV;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE TRX_AV_TV AS 
		SELECT t1.RUT, 
			/* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST. AS CAPITAL, /* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS TRX FROM TRX_AV_&periodo t1 WHERE /*t1.FECFAC <= '2018-04-30' AND */
	t1.VIA = 'TV'
	GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE TRX_AV_TV_OF AS
		SELECT A.*, B.DISPOFINAL
			FROM TRX_AV_TV AS A
				INNER JOIN KMARTINE.AVANCE_&periodo B ON (A.RUT = B.RUT_REGISTRO_CIVIL)
					/*WHERE B.DISPOFINAL NOT IS MISSING */
	;
QUIT;

PROC SQL;
	CREATE TABLE RESUMEN_USO_TV AS 
		SELECT &periodo AS PERIODO,(SUM(t1.CAPITAL)) AS CAPITAL,(SUM(t1.DISPOFINAL))  AS DISPOFINAL ,
			(SUM(t1.CAPITAL))  / (SUM(t1.DISPOFINAL))FORMAT=PERCENTN6. AS USO,
			'TV' AS VIA
		FROM WORK.TRX_AV_TV_OF t1
			WHERE T1.DISPOFINAL NOT IS MISSING
				AND T1.DISPOFINAL >= 5000
	;
QUIT;

%put======================================================================================================;
%put [08.02] USO canal TF;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE TRX_AV_TF AS 
		SELECT t1.RUT, 
			/* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST. AS CAPITAL, /* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS TRX FROM TRX_AV_&periodo t1 WHERE /*t1.FECFAC <= '2018-04-30' AND */
	t1.VIA = 'TF'
	GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE TRX_AV_TF_OF AS
		SELECT A.*, B.DISPOFINAL
			FROM TRX_AV_TF AS A
				INNER JOIN KMARTINE.AVANCE_&periodo B ON (A.RUT = B.RUT_REGISTRO_CIVIL)
					/*WHERE B.DISPOFINAL NOT IS MISSING */
	;
QUIT;

PROC SQL;
	CREATE TABLE RESUMEN_USO_TF AS 
		SELECT &periodo AS PERIODO,(SUM(t1.CAPITAL)) AS CAPITAL,(SUM(t1.DISPOFINAL))  AS DISPOFINAL ,
			(SUM(t1.CAPITAL))  / (SUM(t1.DISPOFINAL))FORMAT=PERCENTN6. AS USO,
			'TF' AS VIA
		FROM WORK.TRX_AV_TF_OF t1
			WHERE T1.DISPOFINAL NOT IS MISSING
	;
QUIT;

%put======================================================================================================;
%put [08.03] USO canal BANCO;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE TRX_AV_BCO AS 
		SELECT t1.RUT, 
			/* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST. AS CAPITAL, /* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS TRX FROM TRX_AV_&periodo t1 WHERE /*t1.FECFAC <= '2018-04-30' AND */
	t1.VIA = 'BCO'
	GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE TRX_AV_BCO_OF AS
		SELECT A.*, B.DISPOFINAL
			FROM TRX_AV_BCO AS A
				INNER JOIN KMARTINE.AVANCE_&periodo B ON (A.RUT = B.RUT_REGISTRO_CIVIL)
					/*WHERE B.DISPOFINAL NOT IS MISSING */
	;
QUIT;

PROC SQL;
	CREATE TABLE RESUMEN_USO_BCO AS 
		SELECT &periodo AS PERIODO,(SUM(t1.CAPITAL)) AS CAPITAL,(SUM(t1.DISPOFINAL))  AS DISPOFINAL ,
			(SUM(t1.CAPITAL))  / (SUM(t1.DISPOFINAL))FORMAT=PERCENTN6. AS USO,
			'BCO' AS VIA
		FROM WORK.TRX_AV_BCO_OF t1
			WHERE T1.DISPOFINAL NOT IS MISSING
				AND T1.DISPOFINAL >= 5000
	;
QUIT;

%put======================================================================================================;
%put [08.04] USO canal HB;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE TRX_AV_HB AS 
		SELECT t1.RUT, 
			/* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST. AS CAPITAL, /* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS TRX FROM TRX_AV_&periodo t1 WHERE /*t1.FECFAC <= '2018-04-30' AND */
	t1.VIA = 'HB'
	GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE TRX_AV_HB_OF AS
		SELECT A.*, B.DISPOFINAL
			FROM TRX_AV_HB AS A
				INNER JOIN KMARTINE.AVANCE_&periodo B ON (A.RUT = B.RUT_REGISTRO_CIVIL)
					/*WHERE B.DISPOFINAL NOT IS MISSING */
	;
QUIT;

PROC SQL;
	CREATE TABLE RESUMEN_USO_HB AS 
		SELECT &periodo AS PERIODO,(SUM(t1.CAPITAL)) AS CAPITAL,(SUM(t1.DISPOFINAL))  AS DISPOFINAL ,
			(SUM(t1.CAPITAL))  / (SUM(t1.DISPOFINAL))FORMAT=PERCENTN6. AS USO,
			'HB' AS VIA
		FROM WORK.TRX_AV_HB_OF t1
			WHERE T1.DISPOFINAL NOT IS MISSING
				AND T1.DISPOFINAL >= 5000
	;
QUIT;

/*USO*/
/*CANAL APP*/
PROC SQL;
	CREATE TABLE TRX_AV_APP AS 
		SELECT t1.RUT, 
			/* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST. AS CAPITAL, /* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS TRX FROM TRX_AV_&periodo t1 WHERE /*t1.FECFAC <= '2018-04-30' AND */
	t1.VIA = 'APP'
	GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE TRX_AV_APP_OF AS
		SELECT A.*, B.DISPOFINAL
			FROM TRX_AV_APP AS A
				INNER JOIN KMARTINE.AVANCE_&periodo B ON (A.RUT = B.RUT_REGISTRO_CIVIL)
					/*WHERE B.DISPOFINAL NOT IS MISSING */
	;
QUIT;

PROC SQL;
	CREATE TABLE RESUMEN_USO_APP AS 
		SELECT &periodo AS PERIODO,(SUM(t1.CAPITAL)) AS CAPITAL,(SUM(t1.DISPOFINAL))  AS DISPOFINAL ,
			(SUM(t1.CAPITAL))  / (SUM(t1.DISPOFINAL))FORMAT=PERCENTN6. AS USO,
			'APP' AS VIA
		FROM WORK.TRX_AV_APP_OF t1
			WHERE T1.DISPOFINAL NOT IS MISSING
				AND T1.DISPOFINAL >= 5000
	;
QUIT;

%put======================================================================================================;
%put [08.05] USO canal MOVIL;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE TRX_AV_MOVIL AS 
		SELECT t1.RUT, 
			/* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST. AS CAPITAL, /* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS TRX FROM TRX_AV_&periodo t1 WHERE /*t1.FECFAC <= '2018-04-30' AND */
	t1.VIA = 'MOVIL'
	GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE TRX_AV_MOVIL_OF AS
		SELECT A.*, B.DISPOFINAL
			FROM TRX_AV_MOVIL AS A
				INNER JOIN KMARTINE.AVANCE_&periodo B ON (A.RUT = B.RUT_REGISTRO_CIVIL)
					/*WHERE B.DISPOFINAL NOT IS MISSING */
	;
QUIT;

PROC SQL;
	CREATE TABLE RESUMEN_USO_MOVIL AS 
		SELECT &periodo AS PERIODO,(SUM(t1.CAPITAL)) AS CAPITAL,(SUM(t1.DISPOFINAL))  AS DISPOFINAL ,
			(SUM(t1.CAPITAL))  / (SUM(t1.DISPOFINAL))FORMAT=PERCENTN6. AS USO,
			'MOVIL' AS VIA
		FROM WORK.TRX_AV_MOVIL_OF t1
			WHERE T1.DISPOFINAL NOT IS MISSING
				AND T1.DISPOFINAL >= 5000
	;
QUIT;

/*CREA TABLA USO*/
PROC SQL;
	CREATE TABLE &libreria..FUNNELAV_TRX_USO_MES_ACTUAL  AS
		SELECT * FROM ( SELECT *,3 as n
			FROM RESUMEN_USO_TV
				UNION SELECT *,2 as n
			FROM RESUMEN_USO_TF
				UNION SELECT *,1 as n
			FROM RESUMEN_USO_BCO
				/*UNION SELECT *,4 as n
			FROM RESUMEN_USO_HB
				UNION SELECT *,5 as n
			FROM RESUMEN_USO_APP*/
				UNION SELECT *,6 as n
			FROM RESUMEN_USO_MOVIL)
				ORDER BY N
					/*UNION SELECT **/

	/*FROM RESUMEN_USO_ATM*/
	;
QUIT;

%put======================================================================================================;
%put [09.00] AVANCE MARCA CLIENTES VERDES;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE WORK.marca_verdes AS 
		SELECT &periodo AS PERIODO, 
			t1.RUT_REGISTRO_CIVIL AS RUT,  
			t1.RANGO_PROB,
			t1.ACTIVIDAD_TR,
		CASE 
			WHEN (t1.ACTIVIDAD_TR IN(
			'ACTIVO',
			'SEMIACTIVO',
			'DORMIDO BLANDO',
			'OTROS CON SALDO',) 
			AND t1.RANGO_PROB IN ('0.9 - 1.0','0.8 - 0.9','0.7 - 0.8','0.6 - 0.7','0.5 - 0.6','0.4 - 0.5')) THEN 1 
			ELSE 0 
		END 
	AS VERDE,
		CASE 
			WHEN (t1.ACTIVIDAD_TR IN(
			'ACTIVO',
			'SEMIACTIVO') 
			AND t1.RANGO_PROB IN ('0.9 - 1.0','0.8 - 0.9','0.7 - 0.8','0.6 - 0.7','0.5 - 0.6')) THEN 1 
			ELSE 0 
		END 
	AS VERDISIMO
		FROM kmartine.AVANCE_&periodo t1;
QUIT;

PROC SQL;
	CREATE TABLE &libreria..FUNNELAV_VERDES_MES_ACTUAL  AS 
		SELECT t1.PERIODO, 
			/* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS Ofertados, /* SUM_of_VERDE */
	(SUM(t1.VERDE)) AS VERDE, /* SUM_of_VERDISIMO */
	(SUM(t1.VERDISIMO)) AS VERDISIMO FROM WORK.MARCA_VERDES t1 GROUP BY t1.PERIODO;
QUIT;

/*===============================================================================================================================================================*/
/*=== MACRO FECHAS MES ANTERIOR ==============================================================================================================================================*/
/*===============================================================================================================================================================*/
DATA _null_;
	dated = input(put(intnx('month',today(),-1,'begin'),date9. ),$10.);
	date0 = input(put(intnx('month',today(),-1,'same'),yymmn6. ),$10.);
	datef = input(put(intnx('month',today(),-1,'same'),date9. ),$10.);
	Call symput("periodo", date0);
	Call symput("fechad", dated);
	Call symput("fechaf", datef);
RUN;

%put &periodo; /*periodo mes anterior*/
%put &fechad;/*fecha inicio  mes anterior*/
%put &fechaf;/*fecha fin mes anterior*/
%put==================================================================================================;
%put [10.00] Extrae visitas para los canales TERMINAL DE VENTA;
%put==================================================================================================;

PROC SQL;
	CREATE TABLE WORK.VISITAS_TOTALES_TV AS 
		SELECT t1.rut AS RUT_CLIENTE , 
			t1.rut_real , 
			t1.n_vis AS VISITA, 
			t1.fecha, 
			t1.sucursal, 
			t1.origen, 
			t1.tipo, 
			t2.NOMB_ORIGEN as VIA , 
			t2.NOMB_TIPO
		FROM PUBLICIN.TABLON_VISITAS_&periodo t1, PMUNOZ.PARAMETRICA_VISITAS t2
			WHERE (t1.origen = t2.COD_ORIGEN AND t1.tipo = t2.COD_TIPO)
				AND T2.NOMB_ORIGEN='TV'
				AND T1.SUCURSAL NOT = 39 /* no considera INTERNET */
	AND t1.fecha >= "&fechad"d  
	AND t1.fecha <  "&fechaf"d
	AND  t1.rut_real =1  /* que exista el rut */;
QUIT;

PROC SQL noprint;
	/*CREATE TABLE WORK.QUERY_FOR_VISITAS_TOTALES_TDA_20 AS */
	SELECT /* MAX_of_FECHA_TRUNC */
		(MAX(t1.fecha)) FORMAT=DDMMYY20. AS fecha_max_tv FROM WORK.VISITAS_TOTALES_TV t1;
QUIT;

/*3019977*/
PROC SQL;
	CREATE TABLE VISITAS_TOT_MARCA_CON_OF AS 
		SELECT t1.RUT_CLIENTE,
			t1.VISITA, 
			t1.VIA,
			t2.RUT_REGISTRO_CIVIL,
		CASE 
			WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
			ELSE 0 
		END 
	AS VIS_CON_OFERTA, 
		t2.AVANCE_FINAL, 
		t2.DISPOFINAL,
		T2.RANGO_PROB,
		T2.ACTIVIDAD_TR
	FROM WORK.VISITAS_TOTALES_TV t1
		LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT_CLIENTE = t2.RUT_REGISTRO_CIVIL) 
	;
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOT_MATRIZ_TV AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA, T1.RANGO_PROB, T1.ACTIVIDAD_TR FROM WORK.VISITAS_TOT_MARCA_CON_OF t1 WHERE VIS_CON_OFERTA >=1 GROUP BY t1.VIA, T1.RANGO_PROB, T1.ACTIVIDAD_TR;
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOTALES_TV AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA FROM WORK.VISITAS_TOT_MARCA_CON_OF t1 GROUP BY t1.VIA;
QUIT;

%put==================================================================================================;
%put [11.00] Extrae visitas para los canales SUCURSAL BANCO;
%put==================================================================================================;

PROC SQL;
	CREATE TABLE WORK.VISITAS_TOTALES_BCO AS 
		SELECT t1.rut AS RUT_CLIENTE , 
			t1.rut_real , 
			t1.n_vis AS VISITA, 
			t1.fecha, 
			t1.sucursal, 
			t1.origen, 
			t1.tipo, 
			'BCO' AS /*t2.NOMB_ORIGEN*/
	VIA , 
	t2.NOMB_TIPO
	FROM PUBLICIN.TABLON_VISITAS_&periodo t1, PMUNOZ.PARAMETRICA_VISITAS t2
		WHERE (t1.origen = t2.COD_ORIGEN AND t1.tipo = t2.COD_TIPO)
			AND T2.NOMB_ORIGEN='BANCO'
			AND t1.fecha >= "&fechad"d  
			AND t1.fecha <  "&fechaf"d
			AND t1.rut_real =1  /* que exista el rut */
	AND t2.NOMB_TIPO IN ('PAGO EPU',
	'PAGO CONSUMO')/* CONSIDERA SOLO PAGOS EN CAJA , VISITAS CCSS NO SE CONSIDERA PORQUE NO SE PUEDE CURSAR AV*/;
QUIT;

PROC SQL noprint;
	/*CREATE TABLE WORK.QUERY_FOR_VISITAS_TOTALES_TDA_20 AS */
	SELECT /* MAX_of_FECHA_TRUNC */
		(MAX(t1.fecha)) FORMAT=DDMMYY20. AS fecha_max_bco FROM VISITAS_TOTALES_BCO t1;
QUIT;

/*3019977*/
PROC SQL;
	CREATE TABLE VISITAS_TOT_MARCA_CON_OF_BCO AS 
		SELECT t1.RUT_CLIENTE,
			T1.VISITA, 
			t1.VIA,
			t2.RUT_REGISTRO_CIVIL,
		CASE 
			WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
			ELSE 0 
		END 
	AS VIS_CON_OFERTA, 
		t2.AVANCE_FINAL, 
		t2.DISPOFINAL,
		T2.RANGO_PROB,
		T2.ACTIVIDAD_TR
	FROM WORK.VISITAS_TOTALES_BCO t1
		LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT_CLIENTE = t2.RUT_REGISTRO_CIVIL);
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOT_MATRIZ_BCO AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA, T1.RANGO_PROB, T1.ACTIVIDAD_TR FROM WORK.VISITAS_TOT_MARCA_CON_OF_BCO t1 WHERE VIS_CON_OFERTA >=1 GROUP BY t1.VIA, T1.RANGO_PROB, T1.ACTIVIDAD_TR;
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOTALES_BCO AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA FROM WORK.VISITAS_TOT_MARCA_CON_OF_BCO t1 GROUP BY t1.VIA;
QUIT;

%put==================================================================================================;
%put [12.00] Extrae visitas para los canal TERMINAL FINANCIERO;
%put==================================================================================================;

PROC SQL;
	CREATE TABLE WORK.VISITAS_TOTALES_TF AS 
		SELECT t1.rut AS RUT_CLIENTE , 
			t1.rut_real , 
			t1.n_vis AS VISITA, 
			t1.fecha, 
			t1.sucursal, 
			t1.origen, 
			t1.tipo, 
			t2.NOMB_ORIGEN as VIA , 
			t2.NOMB_TIPO
		FROM PUBLICIN.TABLON_VISITAS_&periodo t1, PMUNOZ.PARAMETRICA_VISITAS t2
			WHERE (t1.origen = t2.COD_ORIGEN AND t1.tipo = t2.COD_TIPO)
				AND T2.NOMB_ORIGEN='TF'
				AND t1.fecha >= "&fechad"d  
				AND t1.fecha <  "&fechaf"d
				AND t1.rut_real =1  /* que exista el rut */
	;
QUIT;

PROC SQL noprint;
	/*CREATE TABLE WORK.QUERY_FOR_VISITAS_TOTALES_TDA_20 AS */
	SELECT /* MAX_of_FECHA_TRUNC */
		(MAX(t1.fecha)) FORMAT=DDMMYY20. AS fecha_max_tf FROM VISITAS_TOTALES_TF t1;
QUIT;

/*3019977*/
PROC SQL;
	CREATE TABLE VISITAS_TOT_MARCA_CON_OF_TF AS 
		SELECT t1.RUT_CLIENTE,
			T1.VISITA, 
			t1.VIA,
			t2.RUT_REGISTRO_CIVIL,
		CASE 
			WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
			ELSE 0 
		END 
	AS VIS_CON_OFERTA, 
		t2.AVANCE_FINAL, 
		t2.DISPOFINAL,
		T2.RANGO_PROB,
		T2.ACTIVIDAD_TR
	FROM WORK.VISITAS_TOTALES_TF t1
		LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT_CLIENTE = t2.RUT_REGISTRO_CIVIL);
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOT_MATRIZ_TF AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA, T1.RANGO_PROB, T1.ACTIVIDAD_TR FROM WORK.VISITAS_TOT_MARCA_CON_OF_TF t1 WHERE VIS_CON_OFERTA >=1 GROUP BY t1.VIA, T1.RANGO_PROB, T1.ACTIVIDAD_TR;
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOTALES_TF AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA FROM WORK.VISITAS_TOT_MARCA_CON_OF_TF t1 GROUP BY t1.VIA;
QUIT;

%put==================================================================================================;
%put [13.00] Extrae visitas para los canales MOVIL ( blue Bird );
%put==================================================================================================;

PROC SQL;
	CREATE TABLE WORK.VISITAS_TOTALES_MOVIL AS 
		SELECT t1.rut AS RUT_CLIENTE , 
			t1.rut_real , 
			t1.n_vis AS VISITA, 
			t1.fecha, 
			t1.sucursal, 
			t1.origen, 
			t1.tipo, 
			t2.NOMB_ORIGEN as VIA , 
			t2.NOMB_TIPO
		FROM PUBLICIN.TABLON_VISITAS_&periodo t1, PMUNOZ.PARAMETRICA_VISITAS t2
			WHERE (t1.origen = t2.COD_ORIGEN AND t1.tipo = t2.COD_TIPO)
				AND T2.NOMB_ORIGEN='MOVIL'
				AND t1.fecha >= "&fechad"d  
				AND t1.fecha <  "&fechaf"d
				AND t1.rut_real =1  /* que exista el rut */
	;
QUIT;

PROC SQL noprint;
	/*CREATE TABLE WORK.QUERY_FOR_VISITAS_TOTALES_TDA_20 AS */
	SELECT /* MAX_of_FECHA_TRUNC */
		(MAX(t1.fecha)) FORMAT=DDMMYY20. AS fecha_max_movil FROM VISITAS_TOTALES_MOVIL t1 ;
QUIT;

PROC SQL;
	CREATE TABLE VISITAS_TOT_MARCA_CON_OF_MOVIL AS 
		SELECT t1.RUT_CLIENTE,
			1 as VISITA, 
			t1.VIA,
			t2.RUT_REGISTRO_CIVIL,
		CASE 
			WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
			ELSE 0 
		END 
	AS VIS_CON_OFERTA, 
		t2.AVANCE_FINAL, 
		t2.DISPOFINAL,
		T2.RANGO_PROB,
		T2.ACTIVIDAD_TR
	FROM WORK.VISITAS_TOTALES_MOVIL t1
		LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT_CLIENTE = t2.RUT_REGISTRO_CIVIL);
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOT_MATRIZ_MOVIL AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA, T1.RANGO_PROB, T1.ACTIVIDAD_TR FROM WORK.VISITAS_TOT_MARCA_CON_OF_MOVIL t1 WHERE VIS_CON_OFERTA >=1 GROUP BY t1.VIA, T1.RANGO_PROB, T1.ACTIVIDAD_TR;
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOTALES_MOVIL AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA FROM WORK.VISITAS_TOT_MARCA_CON_OF_MOVIL t1 GROUP BY t1.VIA;
QUIT;

%put======================================================================================================;
%put [14.00] Extrae visitas para los canale HB ( NO SE ESTA CONSIDERANDO , OFICIAL ES EL FUNNEL DIGITAL );
%put======================================================================================================;

PROC SQL;
	CREATE TABLE WORK.VISITA_HB AS 
		SELECT t1.rut AS RUT_CLIENTE , 
			t1.rut_real , 
			t1.n_vis AS VISITA, 
			t1.fecha, 
			t1.sucursal, 
			t1.origen, 
			t1.tipo, 
			/*t2.NOMB_ORIGEN*/

	'HB'  as VIA , 
	t2.NOMB_TIPO
FROM PUBLICIN.TABLON_VISITAS_&periodo t1, PMUNOZ.PARAMETRICA_VISITAS t2
	WHERE (t1.origen = t2.COD_ORIGEN AND t1.tipo = t2.COD_TIPO)
		AND T2.NOMB_ORIGEN='HB PRIVADO'
		AND T2.NOMB_TIPO = 'HB PRIVADO'
		AND t1.fecha >= "&fechad"d  
		AND t1.fecha <  "&fechaf"d
		AND t1.rut_real =1  /* que exista el rut */
	;
QUIT;

PROC SQL noprint;
	/*CREATE TABLE WORK.QUERY_FOR_VISITAS_TOTALES_TDA_20 AS */
	SELECT /* MAX_of_FECHA_TRUNC */
		(MAX(t1.FECHA)) FORMAT=DDMMYY20. AS fecha_max_hb FROM VISITA_HB t1;
QUIT;

/*3019977*/
PROC SQL;
	CREATE TABLE VISITAS_TOT_HB_CON_OF AS 
		SELECT t1.RUT_CLIENTE,
			T1.VISITA, 
			t1.VIA,
			t2.RUT_REGISTRO_CIVIL,
		CASE 
			WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
			ELSE 0 
		END 
	AS VIS_CON_OFERTA, 
		t2.AVANCE_FINAL, 
		t2.DISPOFINAL
	FROM WORK.VISITA_HB t1
		LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT_CLIENTE = t2.RUT_REGISTRO_CIVIL) 
	;
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOTALES_HB AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA FROM WORK.VISITAS_TOT_HB_CON_OF t1 GROUP BY t1.VIA;
QUIT;

%put======================================================================================================;
%put [15.00] Extrae visitas para los canale APP ( NO SE ESTA CONSIDERANDO , OFICIAL ES EL FUNNEL DIGITAL );
%put======================================================================================================;

PROC SQL;
	CREATE TABLE WORK.VISITA_APP AS 
		SELECT t1.rut AS RUT_CLIENTE , 
			t1.rut_real , 
			t1.n_vis AS VISITA, 
			t1.fecha, 
			t1.sucursal, 
			t1.origen, 
			t1.tipo, 
			/*t2.NOMB_ORIGEN*/

	'APP'  as VIA , 
	t2.NOMB_TIPO
FROM PUBLICIN.TABLON_VISITAS_&periodo t1, PMUNOZ.PARAMETRICA_VISITAS t2
	WHERE (t1.origen = t2.COD_ORIGEN AND t1.tipo = t2.COD_TIPO)
		AND T2.NOMB_ORIGEN='HB PRIVADO'
		AND T2.NOMB_TIPO = 'APP'
		AND t1.fecha >= "&fechad"d  
		AND t1.fecha <  "&fechaf"d
		AND t1.rut_real =1  /* que exista el rut */
	;
QUIT;

PROC SQL noprint;
	/*CREATE TABLE WORK.QUERY_FOR_VISITAS_TOTALES_TDA_20 AS */
	SELECT /* MAX_of_FECHA_TRUNC */
		(MAX(t1.FECHA)) FORMAT=DDMMYY20. AS fecha_max_app FROM VISITA_APP t1;
QUIT;

/*3019977*/
PROC SQL;
	CREATE TABLE VISITAS_TOT_APP_CON_OF AS 
		SELECT t1.RUT_CLIENTE,
			T1.VISITA, 
			t1.VIA,
			t2.RUT_REGISTRO_CIVIL,
		CASE 
			WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
			ELSE 0 
		END 
	AS VIS_CON_OFERTA, 
		t2.AVANCE_FINAL, 
		t2.DISPOFINAL
	FROM WORK.VISITA_APP t1
		LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT_CLIENTE = t2.RUT_REGISTRO_CIVIL) 
	;
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOTALES_APP AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA FROM WORK.VISITAS_TOT_APP_CON_OF t1 GROUP BY t1.VIA;
QUIT;

%put======================================================================================================;
%put [16.00] Consolida resumen visitas y ofertas funnel MES ANTERIOR;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE &libreria..FUNNELAV_VIS_MES_MATRIZ_ANTERIOR AS
		SELECT * FROM ( SELECT *,3 as n
			FROM resumen_VISITAS_TOT_MATRIZ_TF
				UNION SELECT *,2 as n
			FROM resumen_VISITAS_TOT_MATRIZ_BCO
				UNION SELECT *,1 as n
			FROM resumen_VISITAS_TOT_MATRIZ_TV
				/*UNION SELECT *,4 as n
			FROM resumen_VISITAS_TOT_MATRIZ_HB
				UNION SELECT *,5 as n
			FROM resumen_VISITAS_TOT_MATRIZ_APP*/
				UNION SELECT *,6 as n
			FROM resumen_VISITAS_TOT_MATRIZ_MOVIL)
				ORDER BY N
	;
QUIT;

PROC SQL;
	CREATE TABLE &libreria..FUNNELAV_VISITA_MES_ANTERIOR AS
		SELECT * FROM ( SELECT *,3 as n
			FROM resumen_VISITAS_TOTALES_TF
				UNION SELECT *,2 as n
			FROM resumen_VISITAS_TOTALES_BCO
				UNION SELECT *,1 as n
			FROM resumen_VISITAS_TOTALES_TV
				UNION SELECT *,4 as n
			FROM resumen_VISITAS_TOTALES_HB
				UNION SELECT *,5 as n
			FROM resumen_VISITAS_TOTALES_APP
				UNION SELECT *,6 as n
			FROM resumen_VISITAS_TOTALES_MOVIL)
				ORDER BY N
	;
QUIT;

/********************************************************************************************/
/***************************TRANSACCIONES POR CANAL*****************************************/
%put======================================================================================================;
%put [17.00] arma transacciones canales;
%put======================================================================================================;
%put======================================================================================================;
%put [17.01] trx canales digitales ( no se ocupa );
%put======================================================================================================;

/*
LIBNAME QANEWHB ORACLE  PATH="QANEW.WORLD"  SCHEMA=HBPRI_ADM  USER=RIPLEYC  PASSWORD='ri99pley';

PROC SQL;
 CREATE TABLE TRX_HB_APP AS 
 SELECT  iNPUT((SUBSTR(HDVOU_NOM_NOM_USR,1,(LENGTH(HDVOU_NOM_NOM_USR)-1))),BEST.) as rut,
HDVOU_NOM_NOM_USR,
HDVOU_MNT_MNT_PAG as CAPITAL,
HDVOU_COC_CNL,
CASE when t1.HDVOU_COC_CNL NOT LIKE ('85') then 'HB'
      WHEN t1.HDVOU_COC_CNL= '85' then 'APP' END AS VIA,HDVOU_COC_TOP_IDE,HDVOU_FCH_CPR
    FROM QANEWHB.HBPRI_HIS_DET_VOU t1
WHERE 'x'='x'
and t1.HDVOU_FCH_CPR  >= "&fechad"d  
and  t1.HDVOU_FCH_CPR < "&fechaf"d
AND t1.HDVOU_COC_TOP_IDE = 'CASH_ADVANCE'
;QUIT;*/
PROC SQL;
	CREATE TABLE TRX_AV_&periodo AS 
		SELECT t1.*,1 AS TRX,
			CASE 
				WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
				ELSE 0 
			END 
		AS T_OFERTA,
			CASE 
				WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN T1.CAPITAL 
				ELSE 0 
			END 
		AS CAPITAL_OF,
			CASE 
				WHEN t3.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
				ELSE 0 
			END 
		AS T_OFERTA_AD
			FROM (SELECT RUT,CAPITAL,VIA FROM PUBLICIN.TRX_AV_&periodo 
				/*WHERE VIA NOT IN ('APP','HB','PWA')*/
			WHERE (input(compress(fecfac,"-"),yymmdd10.))  >= "&fechad"d 
				and (input(compress(fecfac,"-"),yymmdd10.)) < "&fechaf"d 
				/*OUTER UNION CORR SELECT RUT,CAPITAL,VIA FROM  TRX_HB_APP*/ )t1
			LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT = t2.RUT_REGISTRO_CIVIL)
			LEFT JOIN KMARTINE.AVANCE_&periodo t3 ON (t1.RUT = t3.RUT_REGISTRO_CIVIL)/*	
				WHERE (input(compress(t1.fecfac,"-"),yymmdd10.))  >= "&fechad"d 
					and (input(compress(t1.fecfac,"-"),yymmdd10.)) < "&fechaf"d  AND T1.VIA NOT ='APP'*/
	;
QUIT;

PROC SQL;
	CREATE TABLE &libreria..FUNNELAV_TRX_MES_ANTERIOR AS 
		SELECT /* SUM_of_TRX */
	&periodo AS PERIODO,
	(SUM(t1.TRX)) AS N_TRX, 
	/* SUM_of_T_OFERTA */
	(SUM(t1.T_OFERTA)) AS N_TRX_OFERTA, /* COUNT_DISTINCT_of_RUT */
	(COUNT(DISTINCT(t1.RUT))) AS CLIENTES, /* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST32. AS VENTA, /* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL_OF)) FORMAT=BEST32. AS VENTA_OFERTA, VIA FROM WORK.TRX_AV_&periodo t1 WHERE T1.VIA NOT IN ('TLMK',' ') GROUP BY VIA ;
QUIT;

/********************************************************************************************/
/************************************* USO AVANCE *******************************************/
%put======================================================================================================;
%put [18.00] Arma USO canales;
%put======================================================================================================;
%put======================================================================================================;
%put [18.01] USO canal TV;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE TRX_AV_TV AS 
		SELECT t1.RUT, 
			/* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST. AS CAPITAL, /* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS TRX FROM TRX_AV_&periodo t1 WHERE /*t1.FECFAC <= '2018-04-30' AND */
	t1.VIA = 'TV'
	GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE TRX_AV_TV_OF AS
		SELECT A.*, B.DISPOFINAL
			FROM TRX_AV_TV AS A
				INNER JOIN KMARTINE.AVANCE_&periodo B ON (A.RUT = B.RUT_REGISTRO_CIVIL)
					/*WHERE B.DISPOFINAL NOT IS MISSING */
	;
QUIT;

PROC SQL;
	CREATE TABLE RESUMEN_USO_TV AS 
		SELECT &periodo AS PERIODO,(SUM(t1.CAPITAL)) AS CAPITAL,(SUM(t1.DISPOFINAL))  AS DISPOFINAL ,
			(SUM(t1.CAPITAL))  / (SUM(t1.DISPOFINAL))FORMAT=PERCENTN6. AS USO,
			'TV' AS VIA
		FROM WORK.TRX_AV_TV_OF t1
			WHERE T1.DISPOFINAL NOT IS MISSING
				AND T1.DISPOFINAL >= 5000
	;
QUIT;

%put======================================================================================================;
%put [18.02] USO canal TF;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE TRX_AV_TF AS 
		SELECT t1.RUT, 
			/* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST. AS CAPITAL, /* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS TRX FROM TRX_AV_&periodo t1 WHERE /*t1.FECFAC <= '2018-04-30' AND */
	t1.VIA = 'TF'
	GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE TRX_AV_TF_OF AS
		SELECT A.*, B.DISPOFINAL
			FROM TRX_AV_TF AS A
				INNER JOIN KMARTINE.AVANCE_&periodo B ON (A.RUT = B.RUT_REGISTRO_CIVIL)
					/*WHERE B.DISPOFINAL NOT IS MISSING */
	;
QUIT;

PROC SQL;
	CREATE TABLE RESUMEN_USO_TF AS 
		SELECT &periodo AS PERIODO,(SUM(t1.CAPITAL)) AS CAPITAL,(SUM(t1.DISPOFINAL))  AS DISPOFINAL ,
			(SUM(t1.CAPITAL))  / (SUM(t1.DISPOFINAL))FORMAT=PERCENTN6. AS USO,
			'TF' AS VIA
		FROM WORK.TRX_AV_TF_OF t1
			WHERE T1.DISPOFINAL NOT IS MISSING
	;
QUIT;

%put======================================================================================================;
%put [18.03] USO canal BANCO;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE TRX_AV_BCO AS 
		SELECT t1.RUT, 
			/* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST. AS CAPITAL, /* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS TRX FROM TRX_AV_&periodo t1 WHERE /*t1.FECFAC <= '2018-04-30' AND */
	t1.VIA = 'BCO'
	GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE TRX_AV_BCO_OF AS
		SELECT A.*, B.DISPOFINAL
			FROM TRX_AV_BCO AS A
				INNER JOIN KMARTINE.AVANCE_&periodo B ON (A.RUT = B.RUT_REGISTRO_CIVIL)
					/*WHERE B.DISPOFINAL NOT IS MISSING */
	;
QUIT;

PROC SQL;
	CREATE TABLE RESUMEN_USO_BCO AS 
		SELECT &periodo AS PERIODO,(SUM(t1.CAPITAL)) AS CAPITAL,(SUM(t1.DISPOFINAL))  AS DISPOFINAL ,
			(SUM(t1.CAPITAL))  / (SUM(t1.DISPOFINAL))FORMAT=PERCENTN6. AS USO,
			'BCO' AS VIA
		FROM WORK.TRX_AV_BCO_OF t1
			WHERE T1.DISPOFINAL NOT IS MISSING
				AND T1.DISPOFINAL >= 5000
	;
QUIT;

%put======================================================================================================;
%put [18.04] USO canal HB;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE TRX_AV_HB AS 
		SELECT t1.RUT, 
			/* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST. AS CAPITAL, /* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS TRX FROM TRX_AV_&periodo t1 WHERE /*t1.FECFAC <= '2018-04-30' AND */
	t1.VIA = 'HB'
	GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE TRX_AV_HB_OF AS
		SELECT A.*, B.DISPOFINAL
			FROM TRX_AV_HB AS A
				INNER JOIN KMARTINE.AVANCE_&periodo B ON (A.RUT = B.RUT_REGISTRO_CIVIL)
					/*WHERE B.DISPOFINAL NOT IS MISSING */
	;
QUIT;

PROC SQL;
	CREATE TABLE RESUMEN_USO_HB AS 
		SELECT &periodo AS PERIODO,(SUM(t1.CAPITAL)) AS CAPITAL,(SUM(t1.DISPOFINAL))  AS DISPOFINAL ,
			(SUM(t1.CAPITAL))  / (SUM(t1.DISPOFINAL))FORMAT=PERCENTN6. AS USO,
			'HB' AS VIA
		FROM WORK.TRX_AV_HB_OF t1
			WHERE T1.DISPOFINAL NOT IS MISSING
				AND T1.DISPOFINAL >= 5000
	;
QUIT;

%put======================================================================================================;
%put [18.05] USO canal MOVIL;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE TRX_AV_APP AS 
		SELECT t1.RUT, 
			/* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST. AS CAPITAL, /* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS TRX FROM TRX_AV_&periodo t1 WHERE /*t1.FECFAC <= '2018-04-30' AND */
	t1.VIA = 'APP'
	GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE TRX_AV_APP_OF AS
		SELECT A.*, B.DISPOFINAL
			FROM TRX_AV_APP AS A
				INNER JOIN KMARTINE.AVANCE_&periodo B ON (A.RUT = B.RUT_REGISTRO_CIVIL)
					/*WHERE B.DISPOFINAL NOT IS MISSING */
	;
QUIT;

PROC SQL;
	CREATE TABLE RESUMEN_USO_APP AS 
		SELECT &periodo AS PERIODO,(SUM(t1.CAPITAL)) AS CAPITAL,(SUM(t1.DISPOFINAL))  AS DISPOFINAL ,
			(SUM(t1.CAPITAL))  / (SUM(t1.DISPOFINAL))FORMAT=PERCENTN6. AS USO,
			'APP' AS VIA
		FROM WORK.TRX_AV_APP_OF t1
			WHERE T1.DISPOFINAL NOT IS MISSING
				AND T1.DISPOFINAL >= 5000
	;
QUIT;

/* USO*
/CANAL MOVIL */
PROC SQL;
	CREATE TABLE TRX_AV_MOVIL AS 
		SELECT t1.RUT, 
			/* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST. AS CAPITAL, /* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS TRX FROM TRX_AV_&periodo t1 WHERE /*t1.FECFAC <= '2018-04-30' AND */
	t1.VIA = 'MOVIL'
	GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE TRX_AV_MOVIL_OF AS
		SELECT A.*, B.DISPOFINAL
			FROM TRX_AV_MOVIL AS A
				INNER JOIN KMARTINE.AVANCE_&periodo B ON (A.RUT = B.RUT_REGISTRO_CIVIL)
					/*WHERE B.DISPOFINAL NOT IS MISSING */
	;
QUIT;

PROC SQL;
	CREATE TABLE RESUMEN_USO_MOVIL AS 
		SELECT &periodo AS PERIODO,(SUM(t1.CAPITAL)) AS CAPITAL,(SUM(t1.DISPOFINAL))  AS DISPOFINAL ,
			(SUM(t1.CAPITAL))  / (SUM(t1.DISPOFINAL))FORMAT=PERCENTN6. AS USO,
			'MOVIL' AS VIA
		FROM WORK.TRX_AV_MOVIL_OF t1
			WHERE T1.DISPOFINAL NOT IS MISSING
				AND T1.DISPOFINAL >= 5000
	;
QUIT;

/*USO*/
PROC SQL;
	CREATE TABLE &libreria..FUNNELAV_TRX_USO_MES_ANTERIOR  AS
		SELECT * FROM ( SELECT *,3 as n
			FROM RESUMEN_USO_TV
				UNION SELECT *,2 as n
			FROM RESUMEN_USO_TF
				UNION SELECT *,1 as n
			FROM RESUMEN_USO_BCO
				UNION SELECT *,4 as n
			FROM RESUMEN_USO_HB
				UNION SELECT *,5 as n
			FROM RESUMEN_USO_APP
				UNION SELECT *,6 as n
			FROM RESUMEN_USO_MOVIL)
				ORDER BY N
					/*UNION SELECT **/

	/*FROM RESUMEN_USO_ATM*/
	;
QUIT;

/**************************** DETALLE VERDES **************************/
%put======================================================================================================;
%put [19.00] AVANCE MARCA CLIENTES VERDES;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE WORK.marca_verdes AS 
		SELECT &periodo AS PERIODO, 
			t1.RUT_REGISTRO_CIVIL AS RUT,  
			t1.RANGO_PROB,
			t1.ACTIVIDAD_TR,
		CASE 
			WHEN (t1.ACTIVIDAD_TR IN(
			'ACTIVO',
			'SEMIACTIVO',
			'DORMIDO BLANDO',
			'OTROS CON SALDO',) 
			AND t1.RANGO_PROB IN ('0.9 - 1.0','0.8 - 0.9','0.7 - 0.8','0.6 - 0.7','0.5 - 0.6','0.4 - 0.5')) THEN 1 
			ELSE 0 
		END 
	AS VERDE,
		CASE 
			WHEN (t1.ACTIVIDAD_TR IN(
			'ACTIVO',
			'SEMIACTIVO') 
			AND t1.RANGO_PROB IN ('0.9 - 1.0','0.8 - 0.9','0.7 - 0.8','0.6 - 0.7','0.5 - 0.6')) THEN 1 
			ELSE 0 
		END 
	AS VERDISIMO
		FROM kmartine.AVANCE_&periodo t1;
QUIT;

PROC SQL;
	CREATE TABLE &libreria..FUNNELAV_VERDES_MES_ANTERIOR  AS 
		SELECT t1.PERIODO, 
			/* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS Ofertados, /* SUM_of_VERDE */
	(SUM(t1.VERDE)) AS VERDE, /* SUM_of_VERDISIMO */
	(SUM(t1.VERDISIMO)) AS VERDISIMO FROM WORK.MARCA_VERDES t1 GROUP BY t1.PERIODO;
QUIT;

/*===============================================================================================================================================================*/
/*=== MACRO FECHAS AÑO ANTERIOR ==============================================================================================================================================*/
/*===============================================================================================================================================================*/
DATA _null_;
	dated = input(put(intnx('month',today(),-12,'begin'),date9. ),$10.);
	date0 = input(put(intnx('year',today(),-1,'same'),yymmn6. ),$10.);
	datef = input(put(intnx('month',today(),-12,'same'),date9. ),$10.);
	Call symput("periodo", date0);
	Call symput("fechad", dated);
	Call symput("fechaf", datef);
RUN;

%put &periodo; /*periodo año anterior*/
%put &fechad;/*fecha inicio año anterior*/
%put &fechaf;/*fecha fin año anterior*/

/********************************************************/
/*********************FUNNEL AVANCE*********************/
%put==================================================================================================;
%put [21.00] Extrae visitas para los canales TERMINAL DE VENTA;
%put==================================================================================================;

PROC SQL;
	CREATE TABLE WORK.VISITAS_TOTALES_TV AS 
		SELECT t1.rut AS RUT_CLIENTE , 
			t1.rut_real , 
			t1.n_vis AS VISITA, 
			t1.fecha, 
			t1.sucursal, 
			t1.origen, 
			t1.tipo, 
			t2.NOMB_ORIGEN as VIA , 
			t2.NOMB_TIPO
		FROM PUBLICIN.TABLON_VISITAS_&periodo t1, PMUNOZ.PARAMETRICA_VISITAS t2
			WHERE (t1.origen = t2.COD_ORIGEN AND t1.tipo = t2.COD_TIPO)
				AND T2.NOMB_ORIGEN='TV'
				AND T1.SUCURSAL NOT = 39 /* no considera INTERNET */
	AND t1.fecha >= "&fechad"d  
	AND t1.fecha <  "&fechaf"d
	AND  t1.rut_real =1  /* que exista el rut */;
QUIT;

PROC SQL noprint;
	/*CREATE TABLE WORK.QUERY_FOR_VISITAS_TOTALES_TDA_20 AS */
	SELECT /* MAX_of_FECHA_TRUNC */
		(MAX(t1.fecha)) FORMAT=DDMMYY20. AS fecha_max_tv FROM WORK.VISITAS_TOTALES_TV t1;
QUIT;

/*3019977*/
PROC SQL;
	CREATE TABLE VISITAS_TOT_MARCA_CON_OF AS 
		SELECT t1.RUT_CLIENTE,
			t1.VISITA, 
			t1.VIA,
			t2.RUT_REGISTRO_CIVIL,
		CASE 
			WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
			ELSE 0 
		END 
	AS VIS_CON_OFERTA, 
		t2.AVANCE_FINAL, 
		t2.DISPOFINAL
	FROM WORK.VISITAS_TOTALES_TV t1
		LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT_CLIENTE = t2.RUT_REGISTRO_CIVIL) 
	;
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOTALES_TV AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA FROM WORK.VISITAS_TOT_MARCA_CON_OF t1 GROUP BY t1.VIA;
QUIT;

%put==================================================================================================;
%put [22.00] Extrae visitas para los canales SUCURSAL BANCO;
%put==================================================================================================;

PROC SQL;
	CREATE TABLE WORK.VISITAS_TOTALES_BCO AS 
		SELECT t1.rut AS RUT_CLIENTE , 
			t1.rut_real , 
			t1.n_vis AS VISITA, 
			t1.fecha, 
			t1.sucursal, 
			t1.origen, 
			t1.tipo, 
			'BCO' AS /*t2.NOMB_ORIGEN*/
	VIA , 
	t2.NOMB_TIPO
	FROM PUBLICIN.TABLON_VISITAS_&periodo t1, PMUNOZ.PARAMETRICA_VISITAS t2
		WHERE (t1.origen = t2.COD_ORIGEN AND t1.tipo = t2.COD_TIPO)
			AND T2.NOMB_ORIGEN='BANCO'
			AND t1.fecha >= "&fechad"d  
			AND t1.fecha <  "&fechaf"d
			AND t1.rut_real =1  /* que exista el rut */
	AND t2.NOMB_TIPO IN ('PAGO EPU',
	'PAGO CONSUMO')/* CONSIDERA SOLO PAGOS EN CAJA , VISITAS CCSS NO SE CONSIDERA PORQUE NO SE PUEDE CURSAR AV*/;
QUIT;

PROC SQL noprint;
	/*CREATE TABLE WORK.QUERY_FOR_VISITAS_TOTALES_TDA_20 AS */
	SELECT /* MAX_of_FECHA_TRUNC */
		(MAX(t1.fecha)) FORMAT=DDMMYY20. AS fecha_max_bco FROM VISITAS_TOTALES_BCO t1;
QUIT;

/*3019977*/
PROC SQL;
	CREATE TABLE VISITAS_TOT_MARCA_CON_OF_BCO AS 
		SELECT t1.RUT_CLIENTE,
			T1.VISITA, 
			t1.VIA,
			t2.RUT_REGISTRO_CIVIL,
		CASE 
			WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
			ELSE 0 
		END 
	AS VIS_CON_OFERTA, 
		t2.AVANCE_FINAL, 
		t2.DISPOFINAL
	FROM WORK.VISITAS_TOTALES_BCO t1
		LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT_CLIENTE = t2.RUT_REGISTRO_CIVIL);
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOTALES_BCO AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA FROM WORK.VISITAS_TOT_MARCA_CON_OF_BCO t1 GROUP BY t1.VIA;
QUIT;

%put==================================================================================================;
%put [23.00] Extrae visitas para los canal TERMINAL FINANCIERO;
%put==================================================================================================;

PROC SQL;
	CREATE TABLE WORK.VISITAS_TOTALES_TF AS 
		SELECT t1.rut AS RUT_CLIENTE , 
			t1.rut_real , 
			t1.n_vis AS VISITA, 
			t1.fecha, 
			t1.sucursal, 
			t1.origen, 
			t1.tipo, 
			t2.NOMB_ORIGEN as VIA , 
			t2.NOMB_TIPO
		FROM PUBLICIN.TABLON_VISITAS_&periodo t1, PMUNOZ.PARAMETRICA_VISITAS t2
			WHERE (t1.origen = t2.COD_ORIGEN AND t1.tipo = t2.COD_TIPO)
				AND T2.NOMB_ORIGEN='TF'
				AND t1.fecha >= "&fechad"d  
				AND t1.fecha <  "&fechaf"d
				AND t1.rut_real =1  /* que exista el rut */
	;
QUIT;

PROC SQL noprint;
	/*CREATE TABLE WORK.QUERY_FOR_VISITAS_TOTALES_TDA_20 AS */
	SELECT /* MAX_of_FECHA_TRUNC */
		(MAX(t1.fecha)) FORMAT=DDMMYY20. AS fecha_max_tf FROM VISITAS_TOTALES_TF t1;
QUIT;

/*3019977*/
PROC SQL;
	CREATE TABLE VISITAS_TOT_MARCA_CON_OF_TF AS 
		SELECT t1.RUT_CLIENTE,
			T1.VISITA, 
			t1.VIA,
			t2.RUT_REGISTRO_CIVIL,
		CASE 
			WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
			ELSE 0 
		END 
	AS VIS_CON_OFERTA, 
		t2.AVANCE_FINAL, 
		t2.DISPOFINAL
	FROM WORK.VISITAS_TOTALES_TF t1
		LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT_CLIENTE = t2.RUT_REGISTRO_CIVIL);
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOTALES_TF AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA FROM WORK.VISITAS_TOT_MARCA_CON_OF_TF t1 GROUP BY t1.VIA;
QUIT;

%put==================================================================================================;
%put [24.00] Extrae visitas para los canales MOVIL ( blue Bird );
%put==================================================================================================;


PROC SQL;
CREATE TABLE WORK.VISITAS_TOTALES_MOVIL AS 
SELECT t1.rut AS RUT_CLIENTE , 
      t1.rut_real , 
      t1.n_vis AS VISITA, 
      t1.fecha, 
      t1.sucursal, 
      t1.origen, 
      t1.tipo, 
      t2.NOMB_ORIGEN as VIA , 
      t2.NOMB_TIPO
  FROM PUBLICIN.TABLON_VISITAS_&periodo t1, PMUNOZ.PARAMETRICA_VISITAS t2
  WHERE (t1.origen = t2.COD_ORIGEN AND t1.tipo = t2.COD_TIPO)
AND T2.NOMB_ORIGEN='MOVIL'
AND t1.fecha >= "&fechad"d  
AND t1.fecha <  "&fechaf"d
AND t1.rut_real =1  
;QUIT;

/*
%let path_ora = '(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.84.167)(PORT = 1521))(CONNECT_DATA=(SERVER = DEDICATED)(SERVICE_NAME = segcom)))';
%let user_ora = 'VMARTINEZF';
%let pass_ora = 'VMAR09072021';
%let conexion_ora = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.;
%put &conexion_ora.;
LIBNAME DBLIBORA &conexion_ora. insertbuff=10000 readbuff=10000;*/

/* 30/08 historica sin datos  para año anterior  solo desde 28/07/2020 hacia atras */

/*PROC SQL ;
CONNECT TO ORACLE AS CAMPANAS (PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.);
CREATE TABLE TRANSACCIONES_CAMP_&PERIODO AS
SELECT * FROM CONNECTION TO CAMPANAS(
SELECT
a.*
from CAMPHIS_ADM.CBCAMP_MOV_TRX_OFE_HIST a
where
TRUNC(a.CAMP_MOV_FCH_HOR) between to_date(%str(%')&FECHAd.%str(%'),'dd/mm/yyyy') and
to_date(%str(%')&FECHAf.%str(%'),'dd/mm/yyyy')

and a.CAMP_MOV_COD_CANAL in (9)
order by a.CAMP_MOV_ID_K
)A
;QUIT;*/
/*
proc sql noprint;                              
SELECT USUARIO into :USER 
	FROM sasdyp.user_pass WHERE SCHEMA = 'SEGCOM';
SELECT PASSWORD into :PASSWORD 
	FROM sasdyp.user_pass WHERE SCHEMA = 'SEGCOM';
quit;
%put &USER;
%put &PASSWORD;

%let path_ora       = '(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.84.167)(PORT = 1521))(CONNECT_DATA=(SERVER = DEDICATED)(SERVICE_NAME = segcom)))';
%let conexion_ora   = ORACLE PATH=&path_ora. USER=&USER. PASSWORD=&PASSWORD.;
%put &conexion_ora.;

LIBNAME DBLIBORA     &conexion_ora. insertbuff=10000 readbuff=10000;  
*/
/* tabla actual de campñas conexion mas rapida */
/*
PROC SQL; 
	CONNECT TO ORACLE AS CAMPANAS (PATH=&path_ora. USER=&USER. PASSWORD=&PASSWORD.);
	CREATE TABLE TRANSACCIONES_CAMP_&PERIODO AS 
		SELECT * FROM CONNECTION TO CAMPANAS(
		SELECT 
			A.CAMP_MOV_ID_K AS IDENTIFICADOR,
			A.CAMP_MOV_RUT_CLI as RUT,
			A.CAMP_MOV_EST_ACT as EST_OFERTA,
			A.CAMP_MOV_COD_CANAL AS CANAL,
			A.CAMP_MOV_COD_SUC AS SUCURSAL,
			A.CAMP_MOV_FCH_HOR AS FECHA
		from CBCAMP_MOV_TRX_OFE  a
			where 
				TRUNC(a.CAMP_MOV_FCH_HOR) between to_date(%str(%')&FECHAd.%str(%'),'dd/mm/yyyy') and 
				to_date(%str(%')&FECHAf.%str(%'),'dd/mm/yyyy')
				and a.CAMP_MOV_COD_CANAL in (9)
			order by a.CAMP_MOV_ID_K
				)A
	;
QUIT;
*/
/* query directo del origen mas lenta */
/*
LIBNAME CAMP ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="BRTEFGESTIONP.WORLD"  SCHEMA=CAMP_ADM  USER='CAMP_COMERCIAL'  PASSWORD='ccomer2409' ;

PROC SQL ;
CREATE TABLE TRANSACCIONES_CAMP_&PERIODO AS
SELECT 
A.CAMP_MOV_ID_K AS IDENTIFICADOR,
A.CAMP_MOV_RUT_CLI as RUT,
A.CAMP_MOV_EST_ACT as EST_OFERTA,
A.CAMP_MOV_COD_CANAL AS CANAL,
A.CAMP_MOV_COD_SUC AS SUCURSAL,
A.CAMP_MOV_FCH_HOR AS FECHA
from camp.CBCAMP_MOV_TRX_OFE as A
where 
A.CAMP_MOV_COD_CANAL IN (9)
and A.CAMP_MOV_FCH_HOR between "&fechad:00:00:00"dt and "&fechaf:00:00:00"dt
;QUIT; 
*/

/* VISITA UNICA POR DIA Y RUT*/
proc sql;
	create table VISITAS_TOTALES_MOVIL as 
		select DISTINCT  
			RUT_CLIENTE,
			datepart(fecha) format=date9. as FECHA_TRUNC,
			FECHA,
		case 
			when (RUT_CLIENTE between 1000000 and 50000000) and RUT_CLIENTE not in (1111111,2222222,3333333,4444444,5555555,
			6666666,7777777,8888888,9999999,11111111,22222222,33333333,44444444) then 1 
			else 0 
		end 
	as HUMANO,
		'MOVIL' AS VIA 
FROM VISITAS_TOTALES_MOVIL
/*from TRANSACCIONES_CAMP_&PERIODO*/
		WHERE ORIGEN=9
			AND CALCULATED HUMANO=1
		ORDER BY RUT_CLIENTE
	;
quit;

PROC SQL noprint;
	/*CREATE TABLE WORK.QUERY_FOR_VISITAS_TOTALES_TDA_20 AS */
	SELECT /* MAX_of_FECHA_TRUNC */
		(MAX(t1.FECHA_TRUNC/*fecha*/)) FORMAT=DDMMYY20. AS fecha_max_movil FROM VISITAS_TOTALES_MOVIL t1 ;
QUIT;

PROC SQL;
	CREATE TABLE VISITAS_TOT_MARCA_CON_OF_MOVIL AS 
		SELECT t1.RUT_CLIENTE,
			1 AS VISITA, 
			t1.VIA,
			t2.RUT_REGISTRO_CIVIL,
		CASE 
			WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
			ELSE 0 
		END 
	AS VIS_CON_OFERTA, 
		t2.AVANCE_FINAL, 
		t2.DISPOFINAL
	FROM WORK.VISITAS_TOTALES_MOVIL t1
		LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT_CLIENTE = t2.RUT_REGISTRO_CIVIL);
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOTALES_MOVIL AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA FROM WORK.VISITAS_TOT_MARCA_CON_OF_MOVIL t1 GROUP BY t1.VIA;
QUIT;

%put======================================================================================================;
%put [25.00] Extrae visitas para los canale HB ( NO SE ESTA CONSIDERANDO , OFICIAL ES EL FUNNEL DIGITAL );
%put======================================================================================================;

PROC SQL;
	CREATE TABLE WORK.VISITA_HB AS 
		SELECT t1.rut AS RUT_CLIENTE , 
			t1.rut_real , 
			t1.n_vis AS VISITA, 
			t1.fecha, 
			t1.sucursal, 
			t1.origen, 
			t1.tipo, 
			/*t2.NOMB_ORIGEN*/

	'HB'  as VIA , 
	t2.NOMB_TIPO
FROM PUBLICIN.TABLON_VISITAS_&periodo t1, PMUNOZ.PARAMETRICA_VISITAS t2
	WHERE (t1.origen = t2.COD_ORIGEN AND t1.tipo = t2.COD_TIPO)
		AND T2.NOMB_ORIGEN='HB PRIVADO'
		AND T2.NOMB_TIPO = 'HB PRIVADO'
		AND t1.fecha >= "&fechad"d  
		AND t1.fecha <  "&fechaf"d
		AND t1.rut_real =1  /* que exista el rut */
	;
QUIT;

PROC SQL noprint;
	/*CREATE TABLE WORK.QUERY_FOR_VISITAS_TOTALES_TDA_20 AS */
	SELECT /* MAX_of_FECHA_TRUNC */
		(MAX(t1.FECHA)) FORMAT=DDMMYY20. AS fecha_max_hb FROM VISITA_HB t1;
QUIT;

/*3019977*/
PROC SQL;
	CREATE TABLE VISITAS_TOT_HB_CON_OF AS 
		SELECT t1.RUT_CLIENTE,
			T1.VISITA, 
			t1.VIA,
			t2.RUT_REGISTRO_CIVIL,
		CASE 
			WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
			ELSE 0 
		END 
	AS VIS_CON_OFERTA, 
		t2.AVANCE_FINAL, 
		t2.DISPOFINAL
	FROM WORK.VISITA_HB t1
		LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT_CLIENTE = t2.RUT_REGISTRO_CIVIL) 
	;
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOTALES_HB AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA FROM WORK.VISITAS_TOT_HB_CON_OF t1 GROUP BY t1.VIA;
QUIT;

%put======================================================================================================;
%put [05.00] Extrae visitas para los canale APP ( NO SE ESTA CONSIDERANDO , OFICIAL ES EL FUNNEL DIGITAL );
%put======================================================================================================;

PROC SQL;
	CREATE TABLE WORK.VISITA_APP AS 
		SELECT t1.rut AS RUT_CLIENTE , 
			t1.rut_real , 
			t1.n_vis AS VISITA, 
			t1.fecha, 
			t1.sucursal, 
			t1.origen, 
			t1.tipo, 
			/*t2.NOMB_ORIGEN*/

	'APP'  as VIA , 
	t2.NOMB_TIPO
FROM PUBLICIN.TABLON_VISITAS_&periodo t1, PMUNOZ.PARAMETRICA_VISITAS t2
	WHERE (t1.origen = t2.COD_ORIGEN AND t1.tipo = t2.COD_TIPO)
		AND T2.NOMB_ORIGEN='HB PRIVADO'
		AND T2.NOMB_TIPO = 'APP'
		AND t1.fecha >= "&fechad"d  
		AND t1.fecha <  "&fechaf"d
		AND t1.rut_real =1  /* que exista el rut */
	;
QUIT;

PROC SQL noprint;
	/*CREATE TABLE WORK.QUERY_FOR_VISITAS_TOTALES_TDA_20 AS */
	SELECT /* MAX_of_FECHA_TRUNC */
		(MAX(t1.FECHA)) FORMAT=DDMMYY20. AS fecha_max_app FROM VISITA_APP t1;
QUIT;

/*3019977*/
PROC SQL;
	CREATE TABLE VISITAS_TOT_APP_CON_OF AS 
		SELECT t1.RUT_CLIENTE,
			T1.VISITA, 
			t1.VIA,
			t2.RUT_REGISTRO_CIVIL,
		CASE 
			WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
			ELSE 0 
		END 
	AS VIS_CON_OFERTA, 
		t2.AVANCE_FINAL, 
		t2.DISPOFINAL
	FROM WORK.VISITA_APP t1
		LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT_CLIENTE = t2.RUT_REGISTRO_CIVIL) 
	;
QUIT;

PROC SQL;
	CREATE TABLE WORK.resumen_VISITAS_TOTALES_APP AS 
		SELECT /* SUM_of_VISITA */
	&periodo AS PERIODO,
	(SUM(t1.VISITA)) AS N_VISITAS, 
	/* COUNT_DISTINCT_of_RUT_CLIENTE */
	(COUNT(DISTINCT(t1.RUT_CLIENTE))) AS VISITAS_RUT_DISTINTOS, /* SUM_of_VIS_CON_OFERTA */
	(SUM(t1.VIS_CON_OFERTA)) AS N_VISITAS_CON_OF, /* COUNT_DISTINCT_of_RUT_REGISTRO_C */
	(COUNT(DISTINCT(t1.RUT_REGISTRO_CIVIL))) AS VISITAS_RUT_DISTINTOS_CON_OF, t1.VIA FROM WORK.VISITAS_TOT_APP_CON_OF t1 GROUP BY t1.VIA;
QUIT;

%put======================================================================================================;
%put [26.00] Consolida resumen visitas y ofertas funnel;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE &libreria..FUNNELAV_VISITA_MES_AACTUAL AS
		SELECT * FROM ( SELECT *,3 as n
			FROM resumen_VISITAS_TOTALES_TF
				UNION SELECT *,2 as n
			FROM resumen_VISITAS_TOTALES_BCO
				UNION SELECT *,1 as n
			FROM resumen_VISITAS_TOTALES_TV
				/*UNION SELECT *,4 as n
			FROM resumen_VISITAS_TOTALES_HB
				UNION SELECT *,5 as n
			FROM resumen_VISITAS_TOTALES_APP*/
				UNION SELECT *,6 as n
			FROM resumen_VISITAS_TOTALES_MOVIL)
				ORDER BY N
	;
QUIT;

/********************************************************************************************/
/***************************TRANSACCIONES POR CANAL*****************************************/
%put======================================================================================================;
%put [27.00] arma transacciones canales;
%put======================================================================================================;
%put======================================================================================================;
%put [27.01] trx canales digitales ( no se ocupa );
%put======================================================================================================;

/*
LIBNAME QANEWHB ORACLE  PATH="QANEW.WORLD"  SCHEMA=HBPRI_ADM  USER=RIPLEYC  PASSWORD='ri99pley';

PROC SQL;
 CREATE TABLE TRX_HB_APP AS 
 SELECT  iNPUT((SUBSTR(HDVOU_NOM_NOM_USR,1,(LENGTH(HDVOU_NOM_NOM_USR)-1))),BEST.) as rut,
HDVOU_NOM_NOM_USR,
HDVOU_MNT_MNT_PAG as CAPITAL,
HDVOU_COC_CNL,
CASE when t1.HDVOU_COC_CNL NOT LIKE ('85') then 'HB'
      WHEN t1.HDVOU_COC_CNL= '85' then 'APP' END AS VIA,HDVOU_COC_TOP_IDE,HDVOU_FCH_CPR
    FROM QANEWHB.HBPRI_HIS_DET_VOU t1
WHERE 'x'='x'
and t1.HDVOU_FCH_CPR  >= "&fechad"d  
and  t1.HDVOU_FCH_CPR < "&fechaf"d
AND t1.HDVOU_COC_TOP_IDE = 'CASH_ADVANCE'
;QUIT;*/
PROC SQL;
	CREATE TABLE TRX_AV_&periodo AS 
		SELECT t1.*,1 AS TRX,
			CASE 
				WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
				ELSE 0 
			END 
		AS T_OFERTA,
			CASE 
				WHEN t2.RUT_REGISTRO_CIVIL NOT IS MISSING THEN T1.CAPITAL 
				ELSE 0 
			END 
		AS CAPITAL_OF,
			CASE 
				WHEN t3.RUT_REGISTRO_CIVIL NOT IS MISSING THEN 1 
				ELSE 0 
			END 
		AS T_OFERTA_AD
			FROM (SELECT RUT,CAPITAL,VIA FROM PUBLICIN.TRX_AV_&periodo 
				/*WHERE VIA NOT IN ('APP','HB','PWA')*/
			WHERE (input(compress(fecfac,"-"),yymmdd10.))  >= "&fechad"d 
				and (input(compress(fecfac,"-"),yymmdd10.)) < "&fechaf"d 
				/*OUTER UNION CORR SELECT RUT,CAPITAL,VIA FROM  TRX_HB_APP */)t1
			LEFT JOIN KMARTINE.AVANCE_&periodo t2 ON (t1.RUT = t2.RUT_REGISTRO_CIVIL)
			LEFT JOIN KMARTINE.AVANCE_&periodo t3 ON (t1.RUT = t3.RUT_REGISTRO_CIVIL)/*	
				WHERE (input(compress(t1.fecfac,"-"),yymmdd10.))  >= "&fechad"d 
					and (input(compress(t1.fecfac,"-"),yymmdd10.)) < "&fechaf"d  AND T1.VIA NOT ='APP'*/
	;
QUIT;

PROC SQL;
	CREATE TABLE &libreria..FUNNELAV_TRX_MES_AACTUAL AS 
		SELECT /* SUM_of_TRX */
	&periodo AS PERIODO,
	(SUM(t1.TRX)) AS N_TRX, 
	/* SUM_of_T_OFERTA */
	(SUM(t1.T_OFERTA)) AS N_TRX_OFERTA, /* COUNT_DISTINCT_of_RUT */
	(COUNT(DISTINCT(t1.RUT))) AS CLIENTES, /* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST32. AS VENTA, /* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL_OF)) FORMAT=BEST32. AS VENTA_OFERTA, VIA FROM WORK.TRX_AV_&periodo t1 WHERE T1.VIA NOT IN ('TLMK',' ') GROUP BY VIA ;
QUIT;

/********************************************************************************************/
/************************************* USO AVANCE *******************************************/
%put======================================================================================================;
%put [28.00] Arma USO canales;
%put======================================================================================================;
%put======================================================================================================;
%put [28.01] USO canal TV;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE TRX_AV_TV AS 
		SELECT t1.RUT, 
			/* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST. AS CAPITAL, /* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS TRX FROM TRX_AV_&periodo t1 WHERE /*t1.FECFAC <= '2018-04-30' AND */
	t1.VIA = 'TV'
	GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE TRX_AV_TV_OF AS
		SELECT A.*, B.DISPOFINAL
			FROM TRX_AV_TV AS A
				INNER JOIN KMARTINE.AVANCE_&periodo B ON (A.RUT = B.RUT_REGISTRO_CIVIL)
					/*WHERE B.DISPOFINAL NOT IS MISSING */
	;
QUIT;

PROC SQL;
	CREATE TABLE RESUMEN_USO_TV AS 
		SELECT &periodo AS PERIODO,(SUM(t1.CAPITAL)) AS CAPITAL,(SUM(t1.DISPOFINAL))  AS DISPOFINAL ,
			(SUM(t1.CAPITAL))  / (SUM(t1.DISPOFINAL))FORMAT=PERCENTN6. AS USO,
			'TV' AS VIA
		FROM WORK.TRX_AV_TV_OF t1
			WHERE T1.DISPOFINAL NOT IS MISSING
				AND T1.DISPOFINAL >= 5000
	;
QUIT;

%put======================================================================================================;
%put [28.02] USO canal TF;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE TRX_AV_TF AS 
		SELECT t1.RUT, 
			/* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST. AS CAPITAL, /* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS TRX FROM TRX_AV_&periodo t1 WHERE /*t1.FECFAC <= '2018-04-30' AND */
	t1.VIA = 'TF'
	GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE TRX_AV_TF_OF AS
		SELECT A.*, B.DISPOFINAL
			FROM TRX_AV_TF AS A
				INNER JOIN KMARTINE.AVANCE_&periodo B ON (A.RUT = B.RUT_REGISTRO_CIVIL)
					/*WHERE B.DISPOFINAL NOT IS MISSING */
	;
QUIT;

PROC SQL;
	CREATE TABLE RESUMEN_USO_TF AS 
		SELECT &periodo AS PERIODO,(SUM(t1.CAPITAL)) AS CAPITAL,(SUM(t1.DISPOFINAL))  AS DISPOFINAL ,
			(SUM(t1.CAPITAL))  / (SUM(t1.DISPOFINAL))FORMAT=PERCENTN6. AS USO,
			'TF' AS VIA
		FROM WORK.TRX_AV_TF_OF t1
			WHERE T1.DISPOFINAL NOT IS MISSING
	;
QUIT;

%put======================================================================================================;
%put [28.03] USO canal BANCO;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE TRX_AV_BCO AS 
		SELECT t1.RUT, 
			/* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST. AS CAPITAL, /* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS TRX FROM TRX_AV_&periodo t1 WHERE /*t1.FECFAC <= '2018-04-30' AND */
	t1.VIA = 'BCO'
	GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE TRX_AV_BCO_OF AS
		SELECT A.*, B.DISPOFINAL
			FROM TRX_AV_BCO AS A
				INNER JOIN KMARTINE.AVANCE_&periodo B ON (A.RUT = B.RUT_REGISTRO_CIVIL)
					/*WHERE B.DISPOFINAL NOT IS MISSING */
	;
QUIT;

PROC SQL;
	CREATE TABLE RESUMEN_USO_BCO AS 
		SELECT &periodo AS PERIODO,(SUM(t1.CAPITAL)) AS CAPITAL,(SUM(t1.DISPOFINAL))  AS DISPOFINAL ,
			(SUM(t1.CAPITAL))  / (SUM(t1.DISPOFINAL))FORMAT=PERCENTN6. AS USO,
			'BCO' AS VIA
		FROM WORK.TRX_AV_BCO_OF t1
			WHERE T1.DISPOFINAL NOT IS MISSING
				AND T1.DISPOFINAL >= 5000
	;
QUIT;

%put======================================================================================================;
%put [28.04] USO canal HB;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE TRX_AV_HB AS 
		SELECT t1.RUT, 
			/* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST. AS CAPITAL, /* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS TRX FROM TRX_AV_&periodo t1 WHERE /*t1.FECFAC <= '2018-04-30' AND */
	t1.VIA = 'HB'
	GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE TRX_AV_HB_OF AS
		SELECT A.*, B.DISPOFINAL
			FROM TRX_AV_HB AS A
				INNER JOIN KMARTINE.AVANCE_&periodo B ON (A.RUT = B.RUT_REGISTRO_CIVIL)
					/*WHERE B.DISPOFINAL NOT IS MISSING */
	;
QUIT;

PROC SQL;
	CREATE TABLE RESUMEN_USO_HB AS 
		SELECT &periodo AS PERIODO,(SUM(t1.CAPITAL)) AS CAPITAL,(SUM(t1.DISPOFINAL))  AS DISPOFINAL ,
			(SUM(t1.CAPITAL))  / (SUM(t1.DISPOFINAL))FORMAT=PERCENTN6. AS USO,
			'HB' AS VIA
		FROM WORK.TRX_AV_HB_OF t1
			WHERE T1.DISPOFINAL NOT IS MISSING
				AND T1.DISPOFINAL >= 5000
	;
QUIT;

/*USO*/
/*CANAL APP*/
PROC SQL;
	CREATE TABLE TRX_AV_APP AS 
		SELECT t1.RUT, 
			/* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST. AS CAPITAL, /* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS TRX FROM TRX_AV_&periodo t1 WHERE /*t1.FECFAC <= '2018-04-30' AND */
	t1.VIA = 'APP'
	GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE TRX_AV_APP_OF AS
		SELECT A.*, B.DISPOFINAL
			FROM TRX_AV_APP AS A
				INNER JOIN KMARTINE.AVANCE_&periodo B ON (A.RUT = B.RUT_REGISTRO_CIVIL)
					/*WHERE B.DISPOFINAL NOT IS MISSING */
	;
QUIT;

PROC SQL;
	CREATE TABLE RESUMEN_USO_APP AS 
		SELECT &periodo AS PERIODO,(SUM(t1.CAPITAL)) AS CAPITAL,(SUM(t1.DISPOFINAL))  AS DISPOFINAL ,
			(SUM(t1.CAPITAL))  / (SUM(t1.DISPOFINAL))FORMAT=PERCENTN6. AS USO,
			'APP' AS VIA
		FROM WORK.TRX_AV_APP_OF t1
			WHERE T1.DISPOFINAL NOT IS MISSING
				AND T1.DISPOFINAL >= 5000
	;
QUIT;

%put======================================================================================================;
%put [28.05] USO canal MOVIL;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE TRX_AV_MOVIL AS 
		SELECT t1.RUT, 
			/* SUM_of_CAPITAL */
	(SUM(t1.CAPITAL)) FORMAT=BEST. AS CAPITAL, /* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS TRX FROM TRX_AV_&periodo t1 WHERE /*t1.FECFAC <= '2018-04-30' AND */
	t1.VIA = 'MOVIL'
	GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE TRX_AV_MOVIL_OF AS
		SELECT A.*, B.DISPOFINAL
			FROM TRX_AV_MOVIL AS A
				INNER JOIN KMARTINE.AVANCE_&periodo B ON (A.RUT = B.RUT_REGISTRO_CIVIL)
					/*WHERE B.DISPOFINAL NOT IS MISSING */
	;
QUIT;

PROC SQL;
	CREATE TABLE RESUMEN_USO_MOVIL AS 
		SELECT &periodo AS PERIODO,(SUM(t1.CAPITAL)) AS CAPITAL,(SUM(t1.DISPOFINAL))  AS DISPOFINAL ,
			(SUM(t1.CAPITAL))  / (SUM(t1.DISPOFINAL))FORMAT=PERCENTN6. AS USO,
			'MOVIL' AS VIA
		FROM WORK.TRX_AV_MOVIL_OF t1
			WHERE T1.DISPOFINAL NOT IS MISSING
				AND T1.DISPOFINAL >= 5000
	;
QUIT;

/*USO*/
PROC SQL;
	CREATE TABLE &libreria..FUNNELAV_TRX_USO_MES_AACTUAL  AS
		SELECT * FROM ( SELECT *,3 as n
			FROM RESUMEN_USO_TV
				UNION SELECT *,2 as n
			FROM RESUMEN_USO_TF
				UNION SELECT *,1 as n
			FROM RESUMEN_USO_BCO
				UNION SELECT *,4 as n
			FROM RESUMEN_USO_HB
				UNION SELECT *,5 as n
			FROM RESUMEN_USO_APP
				UNION SELECT *,6 as n
			FROM RESUMEN_USO_MOVIL)
				ORDER BY N
					/*UNION SELECT **/

	/*FROM RESUMEN_USO_ATM*/
	;
QUIT;

/**************************** DETALLE VERDES **************************/
%put======================================================================================================;
%put [29.00] AVANCE MARCA CLIENTES VERDES;
%put======================================================================================================;

PROC SQL;
	CREATE TABLE WORK.marca_verdes AS 
		SELECT &periodo AS PERIODO, 
			t1.RUT_REGISTRO_CIVIL AS RUT,  
			t1.RANGO_PROB,
			t1.ACTIVIDAD_TR,
		CASE 
			WHEN (t1.ACTIVIDAD_TR IN(
			'ACTIVO',
			'SEMIACTIVO',
			'DORMIDO BLANDO',
			'OTROS CON SALDO',) 
			AND t1.RANGO_PROB IN ('0.9 - 1.0','0.8 - 0.9','0.7 - 0.8','0.6 - 0.7','0.5 - 0.6','0.4 - 0.5')) THEN 1 
			ELSE 0 
		END 
	AS VERDE,
		CASE 
			WHEN (t1.ACTIVIDAD_TR IN(
			'ACTIVO',
			'SEMIACTIVO') 
			AND t1.RANGO_PROB IN ('0.9 - 1.0','0.8 - 0.9','0.7 - 0.8','0.6 - 0.7','0.5 - 0.6')) THEN 1 
			ELSE 0 
		END 
	AS VERDISIMO
		FROM kmartine.AVANCE_&periodo t1;
QUIT;

PROC SQL;
	CREATE TABLE &libreria..FUNNELAV_VERDES_MES_AACTUAL  AS 
		SELECT t1.PERIODO, 
			/* COUNT_of_RUT */
	(COUNT(t1.RUT)) AS Ofertados, /* SUM_of_VERDE */
	(SUM(t1.VERDE)) AS VERDE, /* SUM_of_VERDISIMO */
	(SUM(t1.VERDISIMO)) AS VERDISIMO FROM WORK.MARCA_VERDES t1 GROUP BY t1.PERIODO;
QUIT;

%put======================================================================================================;
%put [3O.00] SE CONSOLIDAN RESUMEN;
%put======================================================================================================;

/* VISITAS */
PROC SQL;
	CREATE TABLE TMP_FUNNELAV_VISITA_MES AS
		SELECT 
			case 
				when periodo-floor(periodo/100)*100 between 1 and 9 then 
				cat(floor(periodo/100),'-',
				cat('0',periodo-floor(periodo/100)*100),'-',
				'01')
				else 
				cat(floor(periodo/100),'-',
				periodo-floor(periodo/100)*100,'-',
				'01') 
			end  
		as periodo2
			,*
		FROM (
			SELECT * FROM &libreria..FUNNELAV_VISITA_MES_ACTUAL /* MES ACTUAL */
				UNION SELECT * FROM &libreria..FUNNELAV_VISITA_MES_ANTERIOR /* MES ANTERIOR */
				UNION SELECT * FROM &libreria..FUNNELAV_VISITA_MES_AACTUAL) /* MES AÑO ANTERIOR */
	;
QUIT;

/* TRX */
PROC SQL;
	CREATE TABLE FUNNELAV_TRX_MES AS
		SELECT 
			case 
				when periodo-floor(periodo/100)*100 between 1 and 9 then 
				cat(floor(periodo/100),'-',
				cat('0',periodo-floor(periodo/100)*100),'-',
				'01')
				else 
				cat(floor(periodo/100),'-',
				periodo-floor(periodo/100)*100,'-',
				'01') 
			end  
		as periodo2
			,*
		FROM (SELECT * FROM &libreria..FUNNELAV_TRX_MES_ACTUAL
			UNION SELECT * FROM &libreria..FUNNELAV_TRX_MES_ANTERIOR
			UNION SELECT * FROM &libreria..FUNNELAV_TRX_MES_AACTUAL)
	;
QUIT;

/* USO */
PROC SQL;
	CREATE TABLE FUNNELAV_TRX_US AS
		SELECT 
			case 
				when periodo-floor(periodo/100)*100 between 1 and 9 then 
				cat(floor(periodo/100),'-',
				cat('0',periodo-floor(periodo/100)*100),'-',
				'01')
				else 
				cat(floor(periodo/100),'-',
				periodo-floor(periodo/100)*100,'-',
				'01') 
			end  
		as periodo2
			,*
		FROM (SELECT * FROM &libreria..FUNNELAV_TRX_USO_MES_ACTUAL
			UNION SELECT * FROM &libreria..FUNNELAV_TRX_USO_MES_ANTERIOR
			UNION SELECT * FROM &libreria..FUNNELAV_TRX_USO_MES_AACTUAL)
	;
QUIT;

/* VERDES  */
PROC SQL;
	CREATE TABLE FUNNELAV_VERDES AS
		SELECT 
			case 
				when periodo-floor(periodo/100)*100 between 1 and 9 then 
				cat(floor(periodo/100),'-',
				cat('0',periodo-floor(periodo/100)*100),'-',
				'01')
				else 
				cat(floor(periodo/100),'-',
				periodo-floor(periodo/100)*100,'-',
				'01') 
			end  
		as periodo2
			,*
		FROM (SELECT * FROM &libreria..FUNNELAV_VERDES_MES_ACTUAL
			UNION SELECT * FROM &libreria..FUNNELAV_VERDES_MES_ANTERIOR
			UNION SELECT * FROM &libreria..FUNNELAV_VERDES_MES_AACTUAL )
	;
QUIT;

data _null_;
	exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechae", exec);
	%put &fechae;/*fecha ejecucion proceso */

	/* BASE SALIDA SAS ADD-IN EDUARDO DIAZ */
proc sql;
	create table &libreria..TMP_FUNNELAV_RESUMEN  as
		select t1.*,
			t2.N_TRX,t2.N_TRX_OFERTA,t2.CLIENTES,t2.VENTA,t2.VENTA_OFERTA,
			t3.CAPITAL,t3.DISPOFINAL,t3.USO format =best.,
			t4.Ofertados,t4.VERDE,t4.VERDISIMO,&fechae as FEC_ACTUALIZACION
		from TMP_FUNNELAV_VISITA_MES t1
			left join  FUNNELAV_TRX_MES t2 on t1.periodo=t2.periodo and t1.via=t2.via
			left join  FUNNELAV_TRX_US t3 on t1.periodo=t3.periodo and t1.via=t3.via
			left join  FUNNELAV_VERDES t4 on t1.periodo=t4.periodo 
	;
quit;

/* BASE SALIDA SAS ADDIN  POR DIA */
proc sql noprint;
	INSERT INTO &libreria..TMP_FUNNELAV_RESUMEN_DIA
		(periodo2, 
		PERIODO, 
		N_VISITAS, 
		VISITAS_RUT_DISTINTOS, 
		N_VISITAS_CON_OF, 
		VISITAS_RUT_DISTINTOS_CON_OF, 
		VIA, 
		n, 
		N_TRX, 
		N_TRX_OFERTA, 
		CLIENTES, 
		VENTA, 
		VENTA_OFERTA, 
		CAPITAL, 
		DISPOFINAL, 
		USO, 
		Ofertados, 
		VERDE, 
		VERDISIMO, 
		FEC_ACTUALIZACION)
	SELECT periodo2, 
		PERIODO, 
		N_VISITAS, 
		VISITAS_RUT_DISTINTOS, 
		N_VISITAS_CON_OF, 
		VISITAS_RUT_DISTINTOS_CON_OF, 
		VIA, 
		n, 
		N_TRX, 
		N_TRX_OFERTA, 
		CLIENTES, 
		VENTA, 
		VENTA_OFERTA, 
		CAPITAL, 
		DISPOFINAL, 
		USO, 
		Ofertados, 
		VERDE, 
		VERDISIMO, 
		FEC_ACTUALIZACION
	from &libreria..TMP_FUNNELAV_RESUMEN
	;
quit;

proc sql;
	create table &libreria..TMP_FUNNELAV_RESUMEN_MATRIZ as
		SELECT *,&fechae as FEC_ACTUALIZACION
			FROM &libreria..FUNNELAV_VIS_MES_MATRIZ_ACTUAL
				UNION SELECT *,&fechae as FEC_ACTUALIZACION
			FROM &libreria..FUNNELAV_VIS_MES_MATRIZ_ANTERIOR
	;
quit;

/* LIMPIAR WORK */
proc sqL noprint;
	drop table TMP_FUNNELAV_VISITA_MES;
	drop table FUNNELAV_TRX_MES;
	drop table FUNNELAV_TRX_US;
	drop table FUNNELAV_VERDES;
	drop table MARCA_VERDES;
	drop table RESUMEN_USO_APP;
	drop table RESUMEN_USO_BCO;
	drop table RESUMEN_USO_HB;
	drop table RESUMEN_USO_MOVIL;
	drop table RESUMEN_USO_TF;
	drop table RESUMEN_USO_TV;
	drop table RESUMEN_VISITAS_TOT_MATRIZ_BCO;
	drop table RESUMEN_VISITAS_TOT_MATRIZ_MOVIL;
	drop table RESUMEN_VISITAS_TOT_MATRIZ_TF;
	drop table RESUMEN_VISITAS_TOT_MATRIZ_TV;
	drop table RESUMEN_VISITAS_TOTALES_APP;
	drop table RESUMEN_VISITAS_TOTALES_BCO;
	drop table RESUMEN_VISITAS_TOTALES_HB;
	drop table RESUMEN_VISITAS_TOTALES_MOVIL;
	drop table RESUMEN_VISITAS_TOTALES_TF;
	drop table RESUMEN_VISITAS_TOTALES_TV;
	drop table TF_TARJETA;
	drop table TRX_AV_APP;
	drop table TRX_AV_APP_OF;
	drop table TRX_AV_BCO;
	drop table TRX_AV_BCO_OF;
	drop table TRX_AV_HB;
	drop table TRX_AV_HB_OF;
	drop table TRX_AV_MOVIL;
	drop table TRX_AV_MOVIL_OF;
	drop table TRX_AV_TF;
	drop table TRX_AV_TF_OF;
	drop table TRX_AV_TV;
	drop table TRX_AV_TV_OF;
	drop table TRX_HB_APP;
	drop table TV_OMP;
	drop table TV_TARJETA;
	drop table VISITA_APP;
	drop table VISITA_HB;
	drop table VISITAS_TOT_APP_CON_OF;
	drop table VISITAS_TOT_HB_CON_OF;
	drop table VISITAS_TOT_MARCA_CON_OF;
	drop table VISITAS_TOT_MARCA_CON_OF_BCO;
	drop table VISITAS_TOT_MARCA_CON_OF_MOVIL;
	drop table VISITAS_TOT_MARCA_CON_OF_TF;
	drop table VISITAS_TOTALES_BCO;
	drop table VISITAS_TOTALES_MOVIL;
	drop table VISITAS_TOTALES_TF;
	drop table VISITAS_TOTALES_TV;
	;
QUIT;

/* SE SUBE AL ORACLOUD TABLEAU

LIBNAME ORACLOUD ORACLE sql_functions=all  READBUFF=1000  INSERTBUFF=1000  PATH="REPORTSAS.WORLD"  SCHEMA=SAS_ADM authdomain=DBOracleCloud_Auth;

proc sql ;
connect using oracloud;
execute by oracloud ( drop table KMARTINE_FUNNEL_AV2);
disconnect from oracloud;
run;


proc sql;
connect using oracloud;
create table  oracloud.KMARTINE_FUNNEL_AV2 as 
select monotonic () as F1, * from kmartine.TMP_FUNNELAV_RESUMEN;
disconnect from oracloud;run; */

/*******************************************************************************************/
/*** envio email aviso actualizacion *******************************************************/
/*******************************************************************************************/
/*Filename myEmail EMAIL*/
/*	Subject = "Funnel Avance " */
/*	From    = "rfonsecaa@bancoripley.com"*/
/*	To      = "ediazl@bancoripley.com"*/
/*	CC      = ("jvaldebenito@ripley.com","rfonsecaa@bancoripley.com","jaburtom@bancoripley.com","jgonzalezma@bancoripley.com")*/
/*	Type    = 'Text/Plain';*/
/**/
/*Data _null_;*/
/*	File myEmail;*/
/*	PUT "Finalizó actualización Funnel Avance";*/
/*	PUT " ";*/
/*	PUT "Disponible en Tableau https://tableau1.bancoripley.cl/t/BI_Lab/views/Funnel_Avance/Historia1?iframeSizedToWindow=true&:embed=y&:showAppBanner=false&:display_count=no&:showVizHome=no ";*/
/*	PUT " ";*/
/*	PUT "Disponible en SAS add-in  &libreria..TMP_FUNNELAV_RESUMEN ";*/
/*	PUT " ";*/
/*	PUT "René Fonseca Álvarez";*/
/*	PUT "Product Manager Senior Inteligencia de Negocios";*/
/*	PUT " ";*/
/*	PUT " "*/
/*	;*/
/*RUN;*/

/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*	VARIABLE TIEMPO	- FIN	*/
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
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_1';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JOSE_VALDEBENITO';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDUARDO_DIAZ';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_PPFF';
	SELECT EMAIL into :DEST_7 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SUBG_BI';
	SELECT EMAIL into :DEST_8 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PPFF_PM_AVANCE';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;
%put &=DEST_5;
%put &=DEST_6;
%put &=DEST_7;
%put &=DEST_8;


data _null_;
	FILENAME OUTBOX EMAIL
		FROM = ("&EDP_BI")
		TO = ("&DEST_5")
		CC = ("&DEST_1", "&DEST_2", "&DEST_3", "&DEST_4", "&DEST_6", "&DEST_7", "&DEST_8")
		SUBJECT = ("MAIL_AUTOM: Proceso FUNNEL_AVANCE_DIARIA_AUTO");
	FILE OUTBOX;
	PUT "Estimados:";
	put "  	Proceso FUNNEL_AVANCE_DIARIA_AUTO, ejecutado con fecha: &fechaeDVN";
	PUT;
	PUT "	Disponible en Tableau https://tableau1.bancoripley.cl/t/BI_Lab/views/Funnel_Avance/Historia1?iframeSizedToWindow=true&:embed=y&:showAppBanner=false&:display_count=no&:showVizHome=no ";
	PUT "	Disponible en SAS add-in  &libreria..TMP_FUNNELAV_RESUMEN ";
	PUT;
	PUT;
	put 'Proceso Vers. 05';
	PUT;
	PUT;
	PUT 'Atte.';
	Put 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;

FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
