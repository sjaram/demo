/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROCESO_REENGANCHE_SAV		================================*/
/* CONTROL DE VERSIONES
/* 2022-11-07 -- V04 -- Sergio J. 
					 -- Se actualizar export a AWS, según nuevas definiciones a RAW.
/* 2022-08-24 -- V03 -- Sergio J. 
					 -- Se añade sentencia include para borrar y exportar data a RAW
/* 2022-07-13 -- V02 -- Sergio J. 
					 -- Se agrega código de exportación para alimentar a Tableau
/* 2021-02-25 -- V01 -- José A. --  
				  	 -- Versión Original
/* INFORMACIÓN:
Monitorea la productividad de los canales presenciales (cuantos clientes entran a las sucursales presenciales
en relacion a las ofertas que reciben).
Especificamente para un subconjunto de clientes 

	(IN) Tablas requeridas o conexiones a BD:


	(OUT) Tablas de Salida o resultado: */

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria=PUBLICIN;

/********************************** MES ACTUAL ********************************************/

DATA _null_;
V_inicioActual  = input(put(intnx('month',today(),0,'begin' ),yymmdd10.  ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
/*V_terminoActual = input(put(intnx('month',today() 0,'end' ),yymmdd10.  ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
V_terminoActual = input(put(today()-1,yymmdd10.),$10.);
datex	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes Actual*/
datexx	= input(put(intnx('month',today(),-2,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes Actual*/
datey	= input(put(intnx('month',today(),-1,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes Actual*/
exec	= compress(input(put(today(),yymmdd10.),$10.),"-",c);
exec1	= compress(input(put(intnx('month',today(),0,'begin' ),yymmdd10.  ),$10.),"-",c);
exec2	= compress(input(put(intnx('month',today(),0,'end' ),yymmdd10.  ),$10.),"-",c);
Call symput("visitainicio",V_inicioActual);
Call symput("visitatermino",V_terminoActual);
Call symput("fechax", datex);
Call symput("fechaxx", datexx);
Call symput("fechay", datey);
Call symput("fechae",exec);
Call symput("fechae1",exec1);
Call symput("fechae2",exec2);
RUN;

%put &visitainicio; 
%put &visitatermino;
%put &fechax;
%put &fechaxx;
%put &fechay;
%put &fechayy;
%put &fechae;
%put &fechae1;
%put &fechae2;
RUN;


PROC SQL;
   CREATE TABLE VISITAS_&fechax AS 
   SELECT t1.*,
          t1.RUT AS RUT_CLIENTE, 
          t2.NOMB_ORIGEN, 
          t2.NOMB_TIPO
      FROM PUBLICIN.TABLON_VISITAS_&fechax t1
           LEFT JOIN PMUNOZ.PARAMETROS_TABLON_VISITAS t2 ON (t1.origen = t2.COD_ORIGEN) AND (t1.tipo = t2.COD_TIPO);
QUIT;

PROC SQL;
   CREATE TABLE SAV_APROBADO_&fechax AS 
   SELECT t1.RUT_REAL,
          t1.SAV_APROBADO_FINAL,
		  t1.MONTO_PARA_CANON AS OFERTA_SAV_APROBADO,
          t1.MONTO_OFERTA_SAV
      FROM JABURTOM.SAV_FIN_&fechax t1
      WHERE t1.BASE_SAV = 'REENGANCHE'
;
QUIT;

PROC SQL;
CREATE TABLE SAV_APROBADO_FINAL_&fechax AS
SELECT * FROM SAV_APROBADO_&fechax

;
QUIT;

/*OFERTA_PRE_APROBADA*/

PROC SQL;
   CREATE TABLE SAV_PREA_&fechax AS 
   SELECT t1.RUT_REAL,
		  t1.MONTO_OFERTA_SAV
      FROM JABURTOM.SAV_FIN_&fechax t1
      WHERE t1.MONTO_OFERTA_SAV >= 500000
	  AND t1.BASE_SAV = 'REENGANCHE'
;
QUIT;

PROC SQL;
CREATE TABLE SAV_PREA_FINAL_&fechax AS
SELECT * FROM SAV_PREA_&fechax
;
QUIT;

PROC SQL;
   CREATE TABLE UNIVERSO_VIS_&fechax AS 
   SELECT t1.*,
          &fechax AS PERIODO,
          t2.ACTIVIDAD_TR, 
          t3.RANGO_PROB, 
          t4.Decil_Sav,
		  CASE WHEN  t5.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
          CASE WHEN  t6.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB 
		 /*CASE WHEN  t5.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
         CASE WHEN  t6.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB*/
      FROM WORK.VISITAS_&fechax t1
           LEFT JOIN PUBLICIN.ACT_TR_&fechaxx t2 ON (t1.RUT_CLIENTE = t2.RUT)
           LEFT JOIN RSEPULV.SCORE_&fechax t3 ON (t1.RUT_CLIENTE = t3.RUT)
           LEFT JOIN MALMENDR.SCORE_SAV_ADVA_&fechax t4 ON (t1.RUT_CLIENTE = t4.RUT)
		   LEFT JOIN SAV_APROBADO_FINAL_&fechax AS t5 ON(t1.RUT_CLIENTE = t5.RUT_REAL)
		   LEFT JOIN SAV_PREA_FINAL_&fechax AS t6 ON(t1.RUT_CLIENTE = t6.RUT_REAL)
;
QUIT;


/**************************************** VIA TF **********************************************/

PROC SQL;
   CREATE TABLE VISITAS_TF_NEW_&fechax AS 
   SELECT DISTINCT RUT_CLIENTE,
   (COUNT(RUT_CLIENTE)) AS CANTIDAD,
   CASE WHEN (RUT_CLIENTE BETWEEN 1000000 AND 50000000) AND RUT_CLIENTE NOT IN (1111111,2222222,3333333,4444444,5555555,
   6666666,7777777,8888888,9999999,11111111,22222222,33333333,44444444) THEN 1 ELSE 0 END AS HUMANO
      FROM WORK.UNIVERSO_VIS_&fechax t1
WHERE NOMB_ORIGEN IN ( 'TF') 
AND sucursal NOT = 39
GROUP BY RUT_CLIENTE
;QUIT;


/* ================================================================================================== ;
                          /* FUNNEL TF, UOF Y OFERTA DE CREDITO */
/* ================================================================================================== ;

/**/

PROC SQL;
   CREATE TABLE VISITAS_TF_NEW2_&fechax AS 
   SELECT A.*,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   (SUM(B2.OFERTA_SAV_APROBADO)) FORMAT=BEST32. AS MONTO_OFERTA
      FROM VISITAS_TF_NEW_&fechax AS A
           LEFT JOIN SAV_APROBADO_FINAL_&fechax AS B2 ON (A.RUT_CLIENTE = B2.RUT_REAL)
      GROUP BY A.RUT_CLIENTE,
               A.CANTIDAD,
               A.HUMANO
;
QUIT;

/* ================================================================================================== */
                              /* FUNNEL TF, TRX TF */
/* ================================================================================================== */

PROC SQL;
   CREATE TABLE TRANSACCIONES_TF_&fechax AS 
   SELECT t1.RUT,
          t2.ACTIVIDAD_TR,
          t3.RANGO_PROB,
           /* COUNT_of_RUT */
            (COUNT(t1.RUT)) AS TRX, 
          /* SUM_of_CAPITAL */
            (SUM(t1.CAPITAL)) FORMAT=BEST32. AS MONTO_CURSE,
          t4.OFERTA_SAV_APROBADO, 
          t1.VIA_FINAL,
		  t1.PERIODO AS FEC_NUM,
		  &fechax AS PERIODO,
		 CASE WHEN t2.ACTIVIDAD_TR IN('ACTIVO','DORMIDO BLANDO','OTROS CON SALDO','SEMIACTIVO') 
         AND t3.RANGO_PROB IN ('0.4 - 0.5','0.5 - 0.6','0.6 - 0.7','0.7 - 0.8','0.8 - 0.9','0.9 - 1.0')THEN 'VERDES' ELSE 'NO_VERDES' END AS MARCA_VERDES
      FROM PUBLICIN.TRX_SAV_&fechax t1
	  LEFT JOIN PUBLICIN.ACT_TR_&fechaxx t2 ON (t1.RUT = t2.RUT)
      LEFT JOIN RSEPULV.SCORE_&fechax t3 ON (t1.RUT = t3.RUT)
      LEFT JOIN SAV_APROBADO_FINAL_&fechax AS t4 ON (t1.RUT = t4.RUT_REAL) 
	  WHERE VIA_FINAL IN ('TF')
	  AND t1.FECFAC BETWEEN "&visitainicio" AND "&visitatermino"
      GROUP BY t1.RUT,
	           t2.ACTIVIDAD_TR,
               t3.RANGO_PROB,
               t1.VIA_FINAL,
			   t1.PERIODO
;
QUIT;

PROC SQl;
CREATE TABLE VISITAS_TF_NEW3_&fechax AS 
SELECT
today() format=date9. as FEC_EJE,
'TF' as CANAL,
A.*,
CASE WHEN  B.RUT IS NOT NULL THEN 1 ELSE 0 END AS CURSE,
B.RUT,
B.TRX AS TRX,
B.MONTO_CURSE,
B.OFERTA_SAV_APROBADO,
B.VIA_FINAL
FROM VISITAS_TF_NEW2_&fechax AS A
LEFT JOIN TRANSACCIONES_TF_&fechax AS B ON(A.RUT_CLIENTE = B.RUT)
;
quit;

PROC SQL;
UPDATE VISITAS_TF_NEW3_&fechax
SET RUT_CLIENTE = RUT
WHERE CURSE = 1
AND RUT NOT IS MISSING
AND RUT_CLIENTE IS MISSING
;
UPDATE VISITAS_TF_NEW3_&fechax
SET MONTO_OFERTA = OFERTA_SAV_APROBADO
WHERE CURSE = 1
AND OFERTA_SAV_APROBADO NOT IS MISSING
AND MONTO_OFERTA IS MISSING
; 
QUIT;

PROC SQL;
   CREATE TABLE ANEXA_VTA_TF_&fechax AS 
   SELECT t1.RUT,
          t1.RUT AS RUT_CLIENTE,
		  'TF' AS CANAL,
          1 AS CANTIDAD,
          1 AS HUMANO,
          1 AS VIS_OFE_APROB,
          1 AS TRX,
          1 AS CURSE, 
          t1.MONTO_CURSE, 
          t1.OFERTA_SAV_APROBADO AS MONTO_OFERTA,
          t1.OFERTA_SAV_APROBADO, 
          t1.VIA_FINAL 
      FROM WORK.TRANSACCIONES_TF_&fechax t1
           LEFT JOIN WORK.VISITAS_TF_NEW3_&fechax t2 ON (t1.RUT = t2.RUT_CLIENTE)
      WHERE t2.RUT_CLIENTE IS MISSING;
QUIT;

PROC SQl;
CREATE TABLE VISITAS_TF_NEW4_&fechax AS 
SELECT * FROM VISITAS_TF_NEW3_&fechax
OUTER UNION CORR
SELECT * FROM ANEXA_VTA_TF_&fechax
; QUIT;

PROC SQL;
UPDATE VISITAS_TF_NEW4_&fechax
SET FEC_EJE = FEC_EJE
WHERE FEC_EJE IS MISSING
;
QUIT;


/* ================================================================================================== */
           /* FUNNEL TF, DEJAR EN DURO FUNNEL ORIGEN TERMINAL DE VENTAS (TIENDA)*/
/* ================================================================================================== */

PROC SQL;
   CREATE TABLE FUNNEL_TF_NEW_&fechax AS 
   SELECT t1.*
      FROM VISITAS_TF_NEW4_&fechax t1
;
QUIT;

/**************************************** VIA CCSS **********************************************/
/**/

PROC SQL;
   CREATE TABLE VISITAS_CIS_NEW_&fechax AS 
   SELECT DISTINCT RUT_CLIENTE,
   (COUNT(RUT_CLIENTE)) AS CANTIDAD,
   CASE WHEN (RUT_CLIENTE BETWEEN 1000000 AND 50000000) AND RUT_CLIENTE NOT IN (1111111,2222222,3333333,4444444,5555555,
   6666666,7777777,8888888,9999999,11111111,22222222,33333333,44444444) THEN 1 ELSE 0 END AS HUMANO
      FROM WORK.UNIVERSO_VIS_&fechax t1
WHERE NOMB_ORIGEN IN ( 'CCSS','ADM')
/* WHERE VIA IN ('CCSS')/*= 'CCSS'*/
GROUP BY RUT_CLIENTE
;QUIT;

/* ================================================================================================== ;
                          /* FUNNEL TV, UOF Y OFERTA DE CREDITO */
/* ================================================================================================== ;

/**/
PROC SQL;
   CREATE TABLE VISITAS_CIS_NEW2_&fechax AS 
   SELECT A.*,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   (SUM(B2.MONTO_oferta_SAV)) FORMAT=BEST32. AS MONTO_OFERTA
      FROM VISITAS_CIS_NEW_&fechax AS A
           LEFT JOIN SAV_PREA_FINAL_&fechax AS B2 ON (A.RUT_CLIENTE = B2.RUT_REAL)
      GROUP BY A.RUT_CLIENTE,
               A.CANTIDAD,
               A.HUMANO
;
QUIT;

/* ================================================================================================== */
                              /* FUNNEL CIS, TRX CIS */
/* ================================================================================================== */

PROC SQL;
   CREATE TABLE TRANSACCIONES_CIS_&fechax AS 
   SELECT t1.RUT,
          t2.ACTIVIDAD_TR,
          t3.RANGO_PROB,
           /* COUNT_of_RUT */
            (COUNT(t1.RUT)) AS TRX, 
          /* SUM_of_CAPITAL */
            (SUM(t1.CAPITAL)) FORMAT=BEST32. AS MONTO_CURSE,
          t4.MONTO_OFERTA_SAV, 
          t1.VIA_FINAL,
		  t1.PERIODO AS FEC_NUM,
		  &fechax AS PERIODO,
		 CASE WHEN t2.ACTIVIDAD_TR IN('ACTIVO','DORMIDO BLANDO','OTROS CON SALDO','SEMIACTIVO') 
         AND t3.RANGO_PROB IN ('0.4 - 0.5','0.5 - 0.6','0.6 - 0.7','0.7 - 0.8','0.8 - 0.9','0.9 - 1.0')THEN 'VERDES' ELSE 'NO_VERDES' END AS MARCA_VERDES
      FROM PUBLICIN.TRX_SAV_&fechax t1
	  LEFT JOIN PUBLICIN.ACT_TR_&fechaxx t2 ON (t1.RUT = t2.RUT)
      LEFT JOIN RSEPULV.SCORE_&fechax t3 ON (t1.RUT = t3.RUT)
      LEFT JOIN SAV_PREA_FINAL_&fechax AS t4 ON (t1.RUT = t4.RUT_REAL) 
	  WHERE VIA_FINAL IN ('CIS','TEF'/*,'MOVIL'*/)
	  AND t1.FECFAC BETWEEN "&visitainicio" AND "&visitatermino"
      GROUP BY t1.RUT,
	           t2.ACTIVIDAD_TR,
               t3.RANGO_PROB,
               t1.VIA_FINAL,
			   t1.PERIODO
;
QUIT;

PROC SQl;
CREATE TABLE VISITAS_CIS_NEW3_&fechax AS 
SELECT
today() format=date9. as FEC_EJE,
'CCSS' as CANAL,
A.*,
CASE WHEN  B.RUT IS NOT NULL THEN 1 ELSE 0 END AS CURSE,
B.RUT,
B.TRX AS TRX,
B.MONTO_CURSE,
B.MONTO_OFERTA_SAV,
B.VIA_FINAL
FROM VISITAS_CIS_NEW2_&fechax AS A
FULL JOIN TRANSACCIONES_CIS_&fechax AS B ON(A.RUT_CLIENTE = B.RUT)
;
quit;

PROC SQL;
UPDATE VISITAS_CIS_NEW3_&fechax
SET RUT_CLIENTE = RUT
WHERE CURSE = 1
AND RUT NOT IS MISSING
AND RUT_CLIENTE IS MISSING
;
UPDATE VISITAS_CIS_NEW3_&fechax
SET MONTO_OFERTA = MONTO_OFERTA_SAV
WHERE CURSE = 1
AND MONTO_OFERTA_SAV NOT IS MISSING
AND MONTO_OFERTA IS MISSING
; 
QUIT;

PROC SQL;
   CREATE TABLE ANEXA_VTA_CIS_&fechax AS 
   SELECT t1.RUT,
          t1.RUT AS RUT_CLIENTE,
		  'CIS' AS CANAL,
          1 AS CANTIDAD,
          1 AS HUMANO,
          1 AS VIS_OFE_APROB,
          1 AS TRX,
          1 AS CURSE, 
          t1.MONTO_CURSE, 
          t1.MONTO_OFERTA_SAV AS MONTO_OFERTA,
          t1.MONTO_OFERTA_SAV, 
          t1.VIA_FINAL 
      FROM WORK.TRANSACCIONES_CIS_&fechax t1
           LEFT JOIN WORK.VISITAS_CIS_NEW3_&fechax t2 ON (t1.RUT = t2.RUT_CLIENTE)
      WHERE t2.RUT_CLIENTE IS MISSING;
QUIT;

PROC SQl;
CREATE TABLE VISITAS_CIS_NEW4_&fechax AS 
SELECT * FROM VISITAS_CIS_NEW3_&fechax
OUTER UNION CORR
SELECT * FROM ANEXA_VTA_CIS_&fechax
; QUIT;

PROC SQL;
UPDATE VISITAS_CIS_NEW4_&fechax
SET FEC_EJE = FEC_EJE
WHERE FEC_EJE IS MISSING
;
QUIT;

/* ================================================================================================== */
           /* FUNNEL CIS, DEJAR EN DURO FUNNEL ORIGEN TERMINAL DE VENTAS (TIENDA)*/
/* ================================================================================================== */

PROC SQL;
   CREATE TABLE FUNNEL_CIS_NEW_&fechax AS 
   SELECT t1.*
      FROM VISITAS_CIS_NEW4_&fechax t1
;
QUIT;

/**************************************** VIA BCO **********************************************/
/**/

PROC SQL;
   CREATE TABLE VISITAS_BCO_NEW_&fechax AS 
   SELECT DISTINCT RUT_CLIENTE,
   (COUNT(RUT_CLIENTE)) AS CANTIDAD,
   CASE WHEN (RUT_CLIENTE BETWEEN 1000000 AND 50000000) AND RUT_CLIENTE NOT IN (1111111,2222222,3333333,4444444,5555555,
   6666666,7777777,8888888,9999999,11111111,22222222,33333333,44444444) THEN 1 ELSE 0 END AS HUMANO
      FROM WORK.UNIVERSO_VIS_&fechax t1
WHERE NOMB_ORIGEN = 'BANCO'
GROUP BY RUT_CLIENTE
;QUIT;

/* ================================================================================================== ;
                          /* FUNNEL BCO, UOF Y OFERTA DE CREDITO */
/* ================================================================================================== ;

/**/
PROC SQL;
   CREATE TABLE VISITAS_BCO_NEW2_&fechax AS 
   SELECT A.*,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   (SUM(B2.MONTO_oferta_SAV)) FORMAT=BEST32. AS MONTO_OFERTA
      FROM VISITAS_BCO_NEW_&fechax AS A
           LEFT JOIN SAV_PREA_FINAL_&fechax AS B2 ON (A.RUT_CLIENTE = B2.RUT_REAL)
      GROUP BY A.RUT_CLIENTE,
               A.CANTIDAD,
               A.HUMANO
;
QUIT;


/* ================================================================================================== */
                              /* FUNNEL BCO, TRX BCO */
/* ================================================================================================== */

PROC SQL;
   CREATE TABLE TRANSACCIONES_BCO_&fechax AS 
   SELECT t1.RUT,
          t2.ACTIVIDAD_TR,
          t3.RANGO_PROB,
           /* COUNT_of_RUT */
            (COUNT(t1.RUT)) AS TRX, 
          /* SUM_of_CAPITAL */
            (SUM(t1.CAPITAL)) FORMAT=BEST32. AS MONTO_CURSE,
          t4.OFERTA_SAV_APROBADO, 
          t1.VIA_FINAL,
		  t1.PERIODO AS FEC_NUM,
		  &fechax AS PERIODO,
		 CASE WHEN t2.ACTIVIDAD_TR IN('ACTIVO','DORMIDO BLANDO','OTROS CON SALDO','SEMIACTIVO') 
         AND t3.RANGO_PROB IN ('0.4 - 0.5','0.5 - 0.6','0.6 - 0.7','0.7 - 0.8','0.8 - 0.9','0.9 - 1.0')THEN 'VERDES' ELSE 'NO_VERDES' END AS MARCA_VERDES
      FROM PUBLICIN.TRX_SAV_&fechax t1
	  LEFT JOIN PUBLICIN.ACT_TR_&fechaxx t2 ON (t1.RUT = t2.RUT)
      LEFT JOIN RSEPULV.SCORE_&fechax t3 ON (t1.RUT = t3.RUT)
      LEFT JOIN SAV_APROBADO_FINAL_&fechax AS t4 ON (t1.RUT = t4.RUT_REAL) 
	  WHERE VIA_FINAL IN ('BCO')
	  AND t1.FECFAC BETWEEN "&visitainicio" AND "&visitatermino"
      GROUP BY t1.RUT,
	           t2.ACTIVIDAD_TR,
               t3.RANGO_PROB,
               t1.VIA_FINAL,
			   t1.PERIODO
;
QUIT;

PROC SQl;
CREATE TABLE VISITAS_BCO_NEW3_&fechax AS 
SELECT
today() format=date9. as FEC_EJE,
'BCO' as CANAL,
A.*,
CASE WHEN  B.RUT IS NOT NULL THEN 1 ELSE 0 END AS CURSE,
B.RUT,
B.TRX AS TRX,
B.MONTO_CURSE,
B.OFERTA_SAV_APROBADO,
B.VIA_FINAL
FROM VISITAS_BCO_NEW2_&fechax AS A
FULL JOIN TRANSACCIONES_BCO_&fechax AS B ON(A.RUT_CLIENTE = B.RUT)
;
quit;

PROC SQL;
UPDATE VISITAS_BCO_NEW3_&fechax
SET RUT_CLIENTE = RUT
WHERE CURSE = 1
AND RUT NOT IS MISSING
AND RUT_CLIENTE IS MISSING
;
UPDATE VISITAS_BCO_NEW3_&fechax
SET MONTO_OFERTA = OFERTA_SAV_APROBADO
WHERE CURSE = 1
AND OFERTA_SAV_APROBADO NOT IS MISSING
AND MONTO_OFERTA IS MISSING
; 
QUIT;

PROC SQL;
   CREATE TABLE ANEXA_VTA_BCO_&fechax AS 
   SELECT t1.RUT,
          t1.RUT AS RUT_CLIENTE,
		  'BCO' AS CANAL,
          1 AS CANTIDAD,
          1 AS HUMANO,
          1 AS VIS_OFE_APROB,
          1 AS TRX,
          1 AS CURSE, 
          t1.MONTO_CURSE, 
          t1.OFERTA_SAV_APROBADO AS MONTO_OFERTA,
          t1.OFERTA_SAV_APROBADO, 
          t1.VIA_FINAL 
      FROM WORK.TRANSACCIONES_BCO_&fechax t1
           LEFT JOIN WORK.VISITAS_BCO_NEW3_&fechax t2 ON (t1.RUT = t2.RUT_CLIENTE)
      WHERE t2.RUT_CLIENTE IS MISSING;
QUIT;

PROC SQl;
CREATE TABLE VISITAS_BCO_NEW4_&fechax AS 
SELECT * FROM VISITAS_BCO_NEW3_&fechax
OUTER UNION CORR
SELECT * FROM ANEXA_VTA_BCO_&fechax
; QUIT;

PROC SQL;
UPDATE VISITAS_BCO_NEW4_&fechax
SET FEC_EJE = FEC_EJE
WHERE FEC_EJE IS MISSING
;
QUIT;


/* ================================================================================================== */
           /* FUNNEL BCO, DEJAR EN DURO FUNNEL ORIGEN TERMINAL DE VENTAS (TIENDA)*/
/* ================================================================================================== */

PROC SQL;
   CREATE TABLE FUNNEL_BCO_NEW_&fechax AS 
   SELECT t1.*
      FROM VISITAS_BCO_NEW4_&fechax t1
;
QUIT;

PROC SQL;
CREATE TABLE FUNNEL_NEW_SAV_&fechax AS

SELECT * FROM FUNNEL_TF_NEW_&fechax
OUTER UNION CORR
SELECT * FROM FUNNEL_CIS_NEW_&fechax
OUTER UNION CORR
SELECT * FROM FUNNEL_BCO_NEW_&fechax
;
QUIT;

PROC SQL;
   CREATE TABLE FUNNEL_NEW_SAV_F_&fechax AS 
   SELECT t1.*,
          t2.ACTIVIDAD_TR, 
          t3.RANGO_PROB,
		  CASE WHEN t2.ACTIVIDAD_TR IN('ACTIVO','DORMIDO BLANDO','OTROS CON SALDO','SEMIACTIVO') 
           AND t3.RANGO_PROB IN ('0.4 - 0.5','0.5 - 0.6','0.6 - 0.7','0.7 - 0.8','0.8 - 0.9','0.9 - 1.0')THEN 'VERDES' ELSE 'NO_VERDES' END AS MARCA_VERDES 
      FROM FUNNEL_NEW_SAV_&fechax t1
           LEFT JOIN PUBLICIN.ACT_TR_&fechaxx t2 ON (t1.RUT_CLIENTE = t2.RUT)
           LEFT JOIN RSEPULV.SCORE_&fechax t3 ON (t1.RUT_CLIENTE = t3.RUT)
;
QUIT;

PROC SQL;
   CREATE TABLE &libreria..REENGANCHE_VISITAS_&fechax AS 
   SELECT t1.FEC_EJE, 
          t1.CANAL, 
          t1.RUT_CLIENTE, 
          t1.CANTIDAD, 
          t1.HUMANO, 
          t1.VIS_OFE_APROB, 
          t1.VIS_OFE_PRE_APROB, 
          t1.MONTO_OFERTA, 
          t1.CURSE, 
          t1.RUT, 
          t1.TRX, 
          t1.MONTO_CURSE, 
          t1.OFERTA_SAV_APROBADO, 
          t1.VIA_FINAL, 
          t1.MONTO_oferta_SAV, 
          t1.ACTIVIDAD_TR, 
          t1.RANGO_PROB, 
          t1.MARCA_VERDES
      FROM WORK.FUNNEL_NEW_SAV_F_&fechax t1
;
QUIT;




/*********************************** RESUMEN REENGANCHE *************************************/

/* MES ACTUAL*/


/* ============================================================================================== */
                                      /* Resumen TF */
/* ============================================================================================== */

proc sql;
create table TF_TF_&fechax as  
select
'02.TF' as CANAL,
'02.TF' AS SEGUIMIENTO, 
&fechax as periodo,
MARCA_VERDES,
VIS_OFE_APROB AS OFERTA_A, 
VIS_OFE_PRE_APROB AS OFERTA_PREA,  
sum(CANTIDAD) as VISITAS_TOTALES,
COUNT(CANTIDAD)AS VISITAS_UNICAS,  
count(case when HUMANO=1 and VIS_OFE_APROB  in (1) then RUT_CLIENTE end) as OFERTA_UNICA,
SUM(case when humano IN (1,.)  AND VIS_OFE_APROB IN (1,0,.) AND CURSE = 1 AND VIA_FINAL IN ('TF') THEN  CURSE END ) AS CURSE,
SUM(MONTO_CURSE) AS MTO_CURSE,
SUM(case when CURSE = 1 AND VIA_FINAL IN ('TF') THEN MONTO_OFERTA END ) AS MTO_OFERTA  
FROM FUNNEL_NEW_SAV_F_&fechax
WHERE CANAL = 'TF'
GROUP BY 
CANAL,
SEGUIMIENTO, 
periodo,
MARCA_VERDES,
VIS_OFE_APROB, 
VIS_OFE_PRE_APROB 
;
QUIT;


/* ============================================================================================== */
                                      /* Resumen CIS */
/* ============================================================================================== */


proc sql;
create table CIS_CIS_&fechax as  
select
'03.CIS' as CANAL,
'03.CIS' AS SEGUIMIENTO, 
&fechax as periodo,
MARCA_VERDES,
VIS_OFE_APROB AS OFERTA_A, 
VIS_OFE_PRE_APROB AS OFERTA_PREA,  
sum(CANTIDAD) as VISITAS_TOTALES,
COUNT(CANTIDAD)AS VISITAS_UNICAS, 
count(case when HUMANO=1 and VIS_OFE_PRE_APROB  in (1) then RUT_CLIENTE end) as OFERTA_UNICA,
SUM(case when humano IN (1,.)  AND VIS_OFE_PRE_APROB IN (1,0,.) AND CURSE = 1 AND VIA_FINAL IN ('CIS','TEF') THEN  CURSE END ) AS CURSE,
SUM(MONTO_CURSE) AS MTO_CURSE,
SUM(case when CURSE = 1 AND VIA_FINAL IN ('CIS','TEF') THEN MONTO_OFERTA END ) AS MTO_OFERTA 
FROM FUNNEL_NEW_SAV_F_&fechax
WHERE CANAL = 'CCSS'
GROUP BY 
CANAL,
SEGUIMIENTO, 
periodo,
MARCA_VERDES,
VIS_OFE_APROB, 
VIS_OFE_PRE_APROB 
;
QUIT;


/* ============================================================================================== */
                                      /* Resumen BCO */
/* ============================================================================================== */

proc sql;
create table BCO_BCO_&fechax as  
select
'04.BCO' as CANAL,
'04.BCO' AS SEGUIMIENTO, 
&fechax as periodo,
MARCA_VERDES,
VIS_OFE_APROB AS OFERTA_A, 
VIS_OFE_PRE_APROB AS OFERTA_PREA,  
sum(CANTIDAD) as VISITAS_TOTALES,
COUNT(CANTIDAD)AS VISITAS_UNICAS, 
count(case when HUMANO=1 and VIS_OFE_PRE_APROB  in (1) then RUT_CLIENTE end) as OFERTA_UNICA,
SUM(case when humano IN (1,.)  AND VIS_OFE_APROB IN (1,0,.) AND CURSE = 1 AND VIA_FINAL IN ('BCO') THEN  CURSE END ) AS CURSE,
SUM(MONTO_CURSE) AS MTO_CURSE,
SUM(case when CURSE = 1 AND VIA_FINAL IN ('BCO') THEN MONTO_OFERTA END ) AS MTO_OFERTA 
FROM FUNNEL_NEW_SAV_F_&fechax
WHERE CANAL = 'BCO'
GROUP BY 
CANAL,
SEGUIMIENTO, 
periodo,
MARCA_VERDES,
VIS_OFE_APROB, 
VIS_OFE_PRE_APROB 
;
QUIT;

PROC SQL;
CREATE TABLE &libreria..SEGUIM_SAV_REENGANCHE_&fechax AS

SELECT * FROM TF_TF_&fechax
OUTER UNION CORR 
SELECT * FROM CIS_CIS_&fechax
OUTER UNION CORR 
SELECT * FROM BCO_BCO_&fechax
;
QUIT;


%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(ppff_seguim_reenganche,raw,oracloud,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ppff_seguim_reenganche,&libreria..SEGUIM_SAV_REENGANCHE_&fechax.,raw,oracloud,0);

%put==================================================================================================;
%put EMAIL AUTOMATICO ;
%put==================================================================================================;

/*	Fecha ejecución del proceso	*/
data _null_;
execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechaeDVN", execDVN) ;
RUN;
%put &fechaeDVN;/*fecha ejecucion proceso */

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDUARDO_DIAZ';

SELECT EMAIL into :DEST_3 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JOSE_ABURTO';

SELECT EMAIL into :DEST_4
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

SELECT EMAIL into :DEST_6 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JOSE_VALDEBENITO';

SELECT EMAIL into :DEST_7
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDUARDO_DIAZ';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;
%put &=DEST_6;
%put &=DEST_7;


data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_2","&DEST_3","&DEST_4","&DEST_6","&DEST_7")
CC = ("&DEST_1")
SUBJECT="MAIL_AUTOM: PROCESO REENGANCHE SAV %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso REENGANCHE SAV, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put ; 
 put ; 
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

