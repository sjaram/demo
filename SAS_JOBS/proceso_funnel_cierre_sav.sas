/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROCESO_FUNNEL_CIERRE_SAV	================================*/
/* CONTROL DE VERSIONES
/* 2022-11-03 -- V05 -- Sergio J. -- Se actualizar export a AWS, según nuevas definiciones a RAW.
/* 2022-08-24 -- V04 -- Sergio J. -- Se añade sentencia include para borrar y exportar data a RAW
/* 2022-07-13 -- V02 -- Sergio J. -- Se agrega código de exportación para alimentar a Tableau
/* 2021-02-25 -- V01 -- José A. --  
*/


/* 1RA PARTE VISITAS */

/********************************** MES -1  ********************************************/



DATA _null_;
V_inicioActual  = input(put(intnx('month',today(),-1,'begin' ),Date9.  ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
V_terminoActual = input(put(intnx('month',today(),-1,'end' ),Date9.  ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datex	= input(put(intnx('month',today(),-1,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes Actual*/
datey	= input(put(intnx('month',today(),-2,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes Actual*/
datexx	= input(put(intnx('month',today(),-3,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes Actual*/
dateyy	= input(put(intnx('month',today(),-4,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes Actual*/
exec	= compress(input(put(today(),yymmdd10.),$10.),"-",c);
exec1	= compress(input(put(intnx('month',today(),-1,'begin' ),yymmdd10.  ),$10.),"-",c);
exec2	= compress(input(put(intnx('month',today(),-1,'end' ),yymmdd10.  ),$10.),"-",c);
Call symput("visitainicio",V_inicioActual);
Call symput("visitatermino",V_terminoActual);
Call symput("fechax", datex);
Call symput("fechay", datey);
Call symput("fechaxx", datexx);
Call symput("fechayy", dateyy);
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

/*OFERTA_APROBADA*/

PROC SQL;
   CREATE TABLE SAV_APROBADO_&fechax AS 
   SELECT t1.RUT_REAL, 
          t1.SAV_APROBADO_FINAL, 
          t1.MONTO_PARA_CANON AS OFERTA_SAV_APROBADO,
          t1.MONTO_OFERTA_SAV 
      FROM JABURTOM.SAV_FIN_&fechax t1
      WHERE t1.SAV_APROBADO_FINAL = 1
;
QUIT;

/*
PROC SQL;
   CREATE TABLE SAV_APROBADO_INCREM_&fechax AS 
   SELECT t1.RUT_REAL, 
          t1.SAV_APROBADO_FINAL, 
          t1.MONTO_PARA_CANON AS OFERTA_SAV_APROBADO,
          t1.MONTO_OFERTA_SAV 
      FROM JABURTOM.SAV_CAR_INCREM_&fechax t1
      WHERE t1.SAV_APROBADO_FINAL = 1
;
QUIT;

*/
PROC SQL;
CREATE TABLE SAV_APROBADO_FINAL_&fechax AS
SELECT * FROM SAV_APROBADO_&fechax
/*OUTER UNION CORR
SELECT * FROM SAV_APROBADO_INCREM_&fechax*/

;
QUIT;

/*OFERTA_PRE_APROBADA*/

PROC SQL;
   CREATE TABLE SAV_PREA_&fechax AS 
   SELECT t1.RUT_REAL, 
          t1.MONTO_OFERTA_SAV 
      FROM JABURTOM.SAV_FIN_&fechax t1
      WHERE t1.MONTO_OFERTA_SAV >= 500000
;
QUIT;

/*
PROC SQL;
   CREATE TABLE SAV_PREA_INCREM_&fechax AS 
   SELECT t1.RUT_REAL, 
          t1.MONTO_OFERTA_SAV 
      FROM JABURTOM.SAV_CAR_INCREM_&fechax t1
      WHERE t1.MONTO_OFERTA_SAV >= 500000
;
QUIT;
*/

PROC SQL;
CREATE TABLE SAV_PREA_FINAL_&fechax AS
SELECT * FROM SAV_PREA_&fechax
/*OUTER UNION CORR
SELECT * FROM SAV_PREA_INCREM_&fechax*/
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


/**************************************** VIA TV **********************************************/

/**/

PROC SQL;
   CREATE TABLE VISITAS_TV_NEW_&fechax AS 
   SELECT DISTINCT RUT_CLIENTE,
   (COUNT(RUT_CLIENTE)) AS CANTIDAD,
   CASE WHEN (RUT_CLIENTE BETWEEN 1000000 AND 50000000) AND RUT_CLIENTE NOT IN (1111111,2222222,3333333,4444444,5555555,
   6666666,7777777,8888888,9999999,11111111,22222222,33333333,44444444) THEN 1 ELSE 0 END AS HUMANO
      FROM WORK.UNIVERSO_VIS_&fechax t1
WHERE NOMB_ORIGEN = 'TV'
AND sucursal NOT = 39
GROUP BY RUT_CLIENTE
;QUIT;


/* ================================================================================================== ;
                          /* FUNNEL TV, UOF Y OFERTA DE CREDITO */
/* ================================================================================================== ;

/**/

PROC SQL;
   CREATE TABLE VISITAS_TV_NEW2_&fechax AS 
   SELECT A.*,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/ 
   /* MONTO_OFERTA */
   (SUM(B2.OFERTA_SAV_APROBADO)) FORMAT=BEST32. AS MONTO_OFERTA
      FROM VISITAS_TV_NEW_&fechax AS A
           LEFT JOIN SAV_APROBADO_FINAL_&fechax AS B2 ON (A.RUT_CLIENTE = B2.RUT_REAL)
      GROUP BY A.RUT_CLIENTE,
               A.CANTIDAD,
               A.HUMANO
;
QUIT;


/* ================================================================================================== */
                              /* FUNNEL TV, TRX TV */
/* ================================================================================================== */

DATA _null_;

inicioAntes  = input(put(intnx('month',today(),-1,'begin' ),yymmdd10.  ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
terminoAntes = input(put(intnx('month',today(),-1,'end' ),yymmdd10.  ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datex	= input(put(intnx('month',today(),-1,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
exec	= compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechainiciox",inicioAntes);/*mes anterior*/
Call symput("fechaterminox",terminoAntes);
Call symput("fechax", datex);
Call symput("fechae",exec);

RUN;
%put &fechainiciox; 
%put &fechaterminox;
%put &fechax; 
%put &fechae;

PROC SQL;
   CREATE TABLE TRANSACCIONES_TV_&fechax AS 
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
	  WHERE VIA_FINAL IN ('TV')
      GROUP BY t1.RUT,
	           t2.ACTIVIDAD_TR,
               t3.RANGO_PROB,
               t1.VIA_FINAL,
			   t1.PERIODO
;
QUIT;


PROC SQl;
CREATE TABLE VISITAS_TV_NEW3_&fechax AS 
SELECT
today() format=date9. as FEC_EJE,
'TV' as CANAL,
A.*,
CASE WHEN  B.RUT IS NOT NULL THEN 1 ELSE 0 END AS CURSE,
B.RUT,
B.TRX AS TRX,
B.MONTO_CURSE,
B.OFERTA_SAV_APROBADO,
B.VIA_FINAL
FROM VISITAS_TV_NEW2_&fechax AS A
LEFT JOIN TRANSACCIONES_TV_&fechax AS B ON(A.RUT_CLIENTE = B.RUT)
;
quit;

PROC SQL noprint;
UPDATE VISITAS_TV_NEW3_&fechax
SET RUT_CLIENTE = RUT
WHERE CURSE = 1
AND RUT NOT IS MISSING
AND RUT_CLIENTE IS MISSING
;
UPDATE VISITAS_TV_NEW3_&fechax
SET MONTO_OFERTA = OFERTA_SAV_APROBADO
WHERE CURSE = 1
AND OFERTA_SAV_APROBADO NOT IS MISSING
AND MONTO_OFERTA IS MISSING
; 
QUIT;


PROC SQL;
   CREATE TABLE ANEXA_VTA_TV_&fechax AS 
   SELECT t1.RUT,
          t1.RUT AS RUT_CLIENTE,
		  'TV' AS CANAL,
          1 AS CANTIDAD,
          1 AS HUMANO,
          1 AS VIS_OFE_APROB,
          1 AS TRX,
          1 AS CURSE, 
          t1.MONTO_CURSE, 
          t1.OFERTA_SAV_APROBADO AS MONTO_OFERTA,
          t1.OFERTA_SAV_APROBADO, 
          t1.VIA_FINAL 
      FROM WORK.TRANSACCIONES_TV_&fechax t1
           LEFT JOIN WORK.VISITAS_TV_NEW3_&fechax t2 ON (t1.RUT = t2.RUT_CLIENTE)
      WHERE t2.RUT_CLIENTE IS MISSING;
QUIT;


PROC SQl;
CREATE TABLE VISITAS_TV_NEW4_&fechax AS 
SELECT * FROM VISITAS_TV_NEW3_&fechax
OUTER UNION CORR
SELECT * FROM ANEXA_VTA_TV_&fechax
; QUIT;


PROC SQL;
UPDATE VISITAS_TV_NEW4_&fechax
SET FEC_EJE = FEC_EJE
WHERE FEC_EJE IS MISSING
;
QUIT;


/* ================================================================================================== */
           /* FUNNEL TV, DEJAR EN DURO FUNNEL ORIGEN TERMINAL DE VENTAS (TIENDA)*/
/* ================================================================================================== */


PROC SQL;
   CREATE TABLE FUNNEL_TV_NEW_&fechax AS 
   SELECT t1.*
      FROM VISITAS_TV_NEW4_&fechax t1
;
QUIT;




/**************************************** VIA TF **********************************************/

/*NOMB_ORIGEN	NOMB_TIPO	COUNT_of_RUT
ADM	TDA	2
CCSS	CALL	1
CCSS	TDA	15
HB PRIVADO	APP	15
HB PUBLICO	HB PUBLICO	8
RPOS	RPOS	1
TF	TF	7
TV	COMPRA OMP	7
TV	PAGOS	3*/

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
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/ 
   /* MONTO_OFERTA */
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
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/ 
   /* MONTO_OFERTA */
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
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/ 
   /* MONTO_OFERTA */
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




/**************************************** VIA MOVIL **********************************************/
/**/


PROC SQL;
   CREATE TABLE VISITAS_MOVIL_NEW_&fechax AS 
   SELECT DISTINCT RUT_CLIENTE,
   (COUNT(RUT_CLIENTE)) AS CANTIDAD,
   CASE WHEN (RUT_CLIENTE BETWEEN 1000000 AND 50000000) AND RUT_CLIENTE NOT IN (1111111,2222222,3333333,4444444,5555555,
   6666666,7777777,8888888,9999999,11111111,22222222,33333333,44444444) THEN 1 ELSE 0 END AS HUMANO
      FROM WORK.UNIVERSO_VIS_&fechax t1
WHERE NOMB_ORIGEN = 'MOVIL'
/* WHERE VIA IN ('CCSS')/*= 'CCSS'*/
GROUP BY RUT_CLIENTE
;QUIT;


/* ================================================================================================== ;
                          /* FUNNEL MOVIL, UOF Y OFERTA DE CREDITO */
/* ================================================================================================== ;

/**/


PROC SQL;
   CREATE TABLE VISITAS_MOVIL_NEW2_&fechax AS 
   SELECT A.*,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/ 
   /* MONTO_OFERTA */
   (SUM(B2.MONTO_oferta_SAV)) FORMAT=BEST32. AS MONTO_OFERTA
      FROM VISITAS_MOVIL_NEW_&fechax AS A
           LEFT JOIN SAV_PREA_FINAL_&fechax AS B2 ON (A.RUT_CLIENTE = B2.RUT_REAL)
      GROUP BY A.RUT_CLIENTE,
               A.CANTIDAD,
               A.HUMANO
;
QUIT;


/* ================================================================================================== */
                              /* FUNNEL TV, TRX TV */
/* ================================================================================================== */

PROC SQL;
   CREATE TABLE TRANSACCIONES_MOVIL_&fechax AS 
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
	  WHERE VIA_FINAL = 'MOVIL'
      GROUP BY t1.RUT,
	           t2.ACTIVIDAD_TR,
               t3.RANGO_PROB,
               t1.VIA_FINAL,
			   t1.PERIODO
;
QUIT;

PROC SQl;
CREATE TABLE VISITAS_MOVIL_NEW3_&fechax AS 
SELECT
today() format=date9. as FEC_EJE,
'MOVIL' as CANAL,
A.*,
CASE WHEN  B.RUT IS NOT NULL THEN 1 ELSE 0 END AS CURSE,
B.RUT,
B.TRX AS TRX,
B.MONTO_CURSE,
B.OFERTA_SAV_APROBADO,
B.VIA_FINAL
FROM VISITAS_MOVIL_NEW2_&fechax AS A
FULL JOIN TRANSACCIONES_MOVIL_&fechax AS B ON(A.RUT_CLIENTE = B.RUT)
;
quit;

PROC SQL;
UPDATE VISITAS_MOVIL_NEW3_&fechax
SET RUT_CLIENTE = RUT
WHERE CURSE = 1
AND RUT NOT IS MISSING
AND RUT_CLIENTE IS MISSING
;
UPDATE VISITAS_MOVIL_NEW3_&fechax
SET MONTO_OFERTA = OFERTA_SAV_APROBADO
WHERE CURSE = 1
AND OFERTA_SAV_APROBADO NOT IS MISSING
AND MONTO_OFERTA IS MISSING
; 
QUIT;

PROC SQL;
   CREATE TABLE ANEXA_VTA_MOVIL_&fechax AS 
   SELECT t1.RUT,
          t1.RUT AS RUT_CLIENTE,
		  'MOVIL' AS CANAL,
          1 AS CANTIDAD,
          1 AS HUMANO,
          1 AS VIS_OFE_APROB,
          1 AS TRX,
          1 AS CURSE, 
          t1.MONTO_CURSE, 
          t1.OFERTA_SAV_APROBADO AS MONTO_OFERTA,
          t1.OFERTA_SAV_APROBADO, 
          t1.VIA_FINAL 
      FROM WORK.TRANSACCIONES_MOVIL_&fechax t1
           LEFT JOIN WORK.VISITAS_MOVIL_NEW3_&fechax t2 ON (t1.RUT = t2.RUT_CLIENTE)
      WHERE t2.RUT_CLIENTE IS MISSING;
QUIT;


PROC SQl;
CREATE TABLE VISITAS_MOVIL_NEW4_&fechax AS 
SELECT * FROM VISITAS_MOVIL_NEW3_&fechax
OUTER UNION CORR
SELECT * FROM ANEXA_VTA_MOVIL_&fechax
; QUIT;


PROC SQL;
UPDATE VISITAS_MOVIL_NEW4_&fechax
SET FEC_EJE = FEC_EJE
WHERE FEC_EJE IS MISSING
;
QUIT;


/* ================================================================================================== */
           /* FUNNEL BCO, DEJAR EN DURO FUNNEL ORIGEN TERMINAL DE VENTAS (TIENDA)*/
/* ================================================================================================== */

PROC SQL;
   CREATE TABLE FUNNEL_MOVIL_NEW_&fechax AS 
   SELECT t1.*
      FROM VISITAS_MOVIL_NEW4_&fechax t1
;
QUIT;


PROC SQL;
CREATE TABLE FUNNEL_NEW_SAV_&fechax AS

SELECT * FROM FUNNEL_TV_NEW_&fechax
OUTER UNION CORR
SELECT * FROM FUNNEL_TF_NEW_&fechax
OUTER UNION CORR
SELECT * FROM FUNNEL_CIS_NEW_&fechax
OUTER UNION CORR
SELECT * FROM FUNNEL_BCO_NEW_&fechax
OUTER UNION CORR
SELECT * FROM FUNNEL_MOVIL_NEW_&fechax
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



/* 1RA PARTE VISITAS */

/********************************** MES - 2 ********************************************/


DATA _null_;
V_inicioAntes  = input(put(intnx('month',today(),-2,'begin' ),Date9.  ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
V_terminoAntes = input(put(intnx('month',today()-2,-1,'end' ),Date9.  ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datey	= input(put(intnx('month',today(),-2,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
dateyy	= input(put(intnx('month',today(),-4,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
exec	= compress(input(put(today(),yymmdd10.),$10.),"-",c);
exec3	= compress(input(put(intnx('month',today(),-2,'begin' ),yymmdd10.  ),$10.),"-",c);
exec4	= compress(input(put(intnx('month',today(),-2,'end' ),yymmdd10.  ),$10.),"-",c);
Call symput("visitainicio_1",V_inicioAntes); /*mes anterior*/
Call symput("visitatermino_1",V_terminoAntes);
Call symput("fechay", datey);
Call symput("fechayy", dateyy);
Call symput("fechae",exec);
Call symput("fechae3",exec3);
Call symput("fechae4",exec4);
 
RUN;

%put &visitainicio_1;
%put &visitatermino_1;
%put &fechay;
%put &fechayy;
%put &fechae;
%put &fechae3;
%put &fechae4;

RUN;


PROC SQL;
   CREATE TABLE VISITAS_&fechay AS 
   SELECT t1.*,
          t1.RUT AS RUT_CLIENTE, 
          t2.NOMB_ORIGEN, 
          t2.NOMB_TIPO
      FROM PUBLICIN.TABLON_VISITAS_&fechay t1
           LEFT JOIN PMUNOZ.PARAMETROS_TABLON_VISITAS t2 ON (t1.origen = t2.COD_ORIGEN) AND (t1.tipo = t2.COD_TIPO)
		   WHERE t1.fecha BETWEEN "&visitainicio_1"d AND "&visitatermino_1"d

;
QUIT;

/*OFERTA_APROBADA*/

PROC SQL;
   CREATE TABLE SAV_APROBADO_&fechay AS 
   SELECT t1.RUT_REAL, 
          t1.SAV_APROBADO_FINAL, 
          t1.MONTO_PARA_CANON AS OFERTA_SAV_APROBADO,
          t1.MONTO_OFERTA_SAV 
      FROM JABURTOM.SAV_FIN_&fechay t1
      WHERE t1.SAV_APROBADO_FINAL = 1
;
QUIT;

/*
PROC SQL;
   CREATE TABLE SAV_APROBADO_INCREM_&fechay AS 
   SELECT t1.RUT_REAL, 
          t1.SAV_APROBADO_FINAL, 
          t1.MONTO_PARA_CANON AS OFERTA_SAV_APROBADO,
          t1.MONTO_OFERTA_SAV 
      FROM JABURTOM.SAV_CAR_INCREM_&fechay t1
      WHERE t1.SAV_APROBADO_FINAL = 1
;
QUIT;

*/

PROC SQL;
CREATE TABLE SAV_APROBADO_FINAL_&fechay AS
SELECT * FROM SAV_APROBADO_&fechay
/*OUTER UNION CORR
SELECT * FROM SAV_APROBADO_INCREM_&fechay*/
;
QUIT;

/*OFERTA_PRE_APROBADA*/

PROC SQL;
   CREATE TABLE SAV_PREA_&fechay AS 
   SELECT t1.RUT_REAL, 
          t1.MONTO_OFERTA_SAV 
      FROM JABURTOM.SAV_FIN_&fechay t1
      WHERE t1.MONTO_OFERTA_SAV >= 500000
;
QUIT;

/*
PROC SQL;
   CREATE TABLE SAV_PREA_INCREM_&fechay AS 
   SELECT t1.RUT_REAL, 
          t1.MONTO_OFERTA_SAV 
      FROM JABURTOM.SAV_CAR_INCREM_&fechay t1
      WHERE t1.MONTO_OFERTA_SAV >= 500000
;
QUIT;

*/

PROC SQL;
CREATE TABLE SAV_PREA_FINAL_&fechay AS
SELECT * FROM SAV_PREA_&fechay
/*OUTER UNION CORR
SELECT * FROM SAV_PREA_INCREM_&fechay*/
;
QUIT;


PROC SQL;
   CREATE TABLE UNIVERSO_VIS_&fechay AS 
   SELECT t1.*,
          &fechay AS PERIODO,
          t2.ACTIVIDAD_TR, 
          t3.RANGO_PROB, 
          t4.Decil_Sav,
		  CASE WHEN  t5.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
          CASE WHEN  t6.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB 
		 /*CASE WHEN  t5.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
         CASE WHEN  t6.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB*/
      FROM WORK.VISITAS_&fechay t1
           LEFT JOIN PUBLICIN.ACT_TR_&fechayy t2 ON (t1.RUT_CLIENTE = t2.RUT)
           LEFT JOIN RSEPULV.SCORE_&fechay t3 ON (t1.RUT_CLIENTE = t3.RUT)
           LEFT JOIN MALMENDR.SCORE_SAV_ADVA_&fechay t4 ON (t1.RUT_CLIENTE = t4.RUT)
		   LEFT JOIN SAV_APROBADO_FINAL_&fechay AS t5 ON(t1.RUT_CLIENTE = t5.RUT_REAL)
		   LEFT JOIN SAV_PREA_FINAL_&fechay AS t6 ON(t1.RUT_CLIENTE = t6.RUT_REAL)
;
QUIT;


/**************************************** VIA TV **********************************************/

/**/

PROC SQL;
   CREATE TABLE VISITAS_TV_NEW_&fechay AS 
   SELECT DISTINCT RUT_CLIENTE,
   (COUNT(RUT_CLIENTE)) AS CANTIDAD,
   CASE WHEN (RUT_CLIENTE BETWEEN 1000000 AND 50000000) AND RUT_CLIENTE NOT IN (1111111,2222222,3333333,4444444,5555555,
   6666666,7777777,8888888,9999999,11111111,22222222,33333333,44444444) THEN 1 ELSE 0 END AS HUMANO
      FROM WORK.UNIVERSO_VIS_&fechay t1
WHERE NOMB_ORIGEN = 'TV'
AND sucursal NOT = 39
GROUP BY RUT_CLIENTE
;QUIT;


/* ================================================================================================== ;
                          /* FUNNEL TV, UOF Y OFERTA DE CREDITO */
/* ================================================================================================== ;

/**/

PROC SQL;
   CREATE TABLE VISITAS_TV_NEW2_&fechay AS 
   SELECT A.*,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/ 
   /* MONTO_OFERTA */
   (SUM(B2.OFERTA_SAV_APROBADO)) FORMAT=BEST32. AS MONTO_OFERTA
      FROM VISITAS_TV_NEW_&fechay AS A
           LEFT JOIN SAV_APROBADO_FINAL_&fechay AS B2 ON (A.RUT_CLIENTE = B2.RUT_REAL)
      GROUP BY A.RUT_CLIENTE,
               A.CANTIDAD,
               A.HUMANO
;
QUIT;


/* ================================================================================================== */
                              /* FUNNEL TV, TRX TV */
/* ================================================================================================== */

DATA _null_;

inicioAntes  = input(put(intnx('month',today(),-2,'begin' ),yymmdd10.  ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
terminoAntes = input(put(intnx('month',today()-2,-1,'end' ),yymmdd10.  ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datey	= input(put(intnx('month',today(),-2,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
exec	= compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechainicioy",inicioAntes);/*mes anterior*/
Call symput("fechaterminoy",terminoAntes);
Call symput("fechay", datey);
Call symput("fechae",exec);

RUN;
%put &fechainicioy; 
%put &fechaterminoy;
%put &fechay; 
%put &fechae;


PROC SQL;
   CREATE TABLE TRANSACCIONES_TV_&fechay AS 
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
		  &fechay AS PERIODO,
		 CASE WHEN t2.ACTIVIDAD_TR IN('ACTIVO','DORMIDO BLANDO','OTROS CON SALDO','SEMIACTIVO') 
         AND t3.RANGO_PROB IN ('0.4 - 0.5','0.5 - 0.6','0.6 - 0.7','0.7 - 0.8','0.8 - 0.9','0.9 - 1.0')THEN 'VERDES' ELSE 'NO_VERDES' END AS MARCA_VERDES
      FROM PUBLICIN.TRX_SAV_&fechay t1
	  LEFT JOIN PUBLICIN.ACT_TR_&fechayy t2 ON (t1.RUT = t2.RUT)
      LEFT JOIN RSEPULV.SCORE_&fechay t3 ON (t1.RUT = t3.RUT)
	  LEFT JOIN SAV_APROBADO_FINAL_&fechay AS t4 ON (t1.RUT = t4.RUT_REAL)
      WHERE t1.FECFAC BETWEEN "&fechainicioy" AND "&fechaterminoy" 
	  AND VIA_FINAL IN ('TV')
      GROUP BY t1.RUT,
	           t2.ACTIVIDAD_TR,
               t3.RANGO_PROB,
               t1.VIA_FINAL,
			   t1.PERIODO
;
QUIT;

PROC SQl;
CREATE TABLE VISITAS_TV_NEW3_&fechay AS 
SELECT
today() format=date9. as FEC_EJE,
'TV' as CANAL,
A.*,
CASE WHEN  B.RUT IS NOT NULL THEN 1 ELSE 0 END AS CURSE,
B.RUT,
B.TRX AS TRX,
B.MONTO_CURSE,
B.OFERTA_SAV_APROBADO,
B.VIA_FINAL
FROM VISITAS_TV_NEW2_&fechay AS A
LEFT JOIN TRANSACCIONES_TV_&fechay AS B ON(A.RUT_CLIENTE = B.RUT)
;
quit;

PROC SQL;
UPDATE VISITAS_TV_NEW3_&fechay
SET RUT_CLIENTE = RUT
WHERE CURSE = 1
AND RUT NOT IS MISSING
AND RUT_CLIENTE IS MISSING
;
UPDATE VISITAS_TV_NEW3_&fechay
SET MONTO_OFERTA = OFERTA_SAV_APROBADO
WHERE CURSE = 1
AND OFERTA_SAV_APROBADO NOT IS MISSING
AND MONTO_OFERTA IS MISSING
; 
QUIT;


PROC SQL;
   CREATE TABLE ANEXA_VTA_TV_&fechay AS 
   SELECT t1.RUT,
          t1.RUT AS RUT_CLIENTE,
		  'TV' AS CANAL,
          1 AS CANTIDAD,
          1 AS HUMANO,
          1 AS VIS_OFE_APROB,
          1 AS TRX,
          1 AS CURSE, 
          t1.MONTO_CURSE, 
          t1.OFERTA_SAV_APROBADO AS MONTO_OFERTA,
          t1.OFERTA_SAV_APROBADO, 
          t1.VIA_FINAL 
      FROM WORK.TRANSACCIONES_TV_&fechay t1
           LEFT JOIN WORK.VISITAS_TV_NEW3_&fechay t2 ON (t1.RUT = t2.RUT_CLIENTE)
      WHERE t2.RUT_CLIENTE IS MISSING;
QUIT;


PROC SQl;
CREATE TABLE VISITAS_TV_NEW4_&fechay AS 
SELECT * FROM VISITAS_TV_NEW3_&fechay
OUTER UNION CORR
SELECT * FROM ANEXA_VTA_TV_&fechay
; QUIT;


PROC SQL;
UPDATE VISITAS_TV_NEW4_&fechay
SET FEC_EJE = FEC_EJE
WHERE FEC_EJE IS MISSING
;
QUIT;


/* ================================================================================================== */
           /* FUNNEL TV, DEJAR EN DURO FUNNEL ORIGEN TERMINAL DE VENTAS (TIENDA)*/
/* ================================================================================================== */


PROC SQL;
   CREATE TABLE FUNNEL_TV_NEW_&fechay AS 
   SELECT t1.*
      FROM VISITAS_TV_NEW4_&fechay t1
;
QUIT;


/**************************************** VIA TF **********************************************/

PROC SQL;
   CREATE TABLE VISITAS_TF_NEW_&fechay AS 
   SELECT DISTINCT RUT_CLIENTE,
   (COUNT(RUT_CLIENTE)) AS CANTIDAD,
   CASE WHEN (RUT_CLIENTE BETWEEN 1000000 AND 50000000) AND RUT_CLIENTE NOT IN (1111111,2222222,3333333,4444444,5555555,
   6666666,7777777,8888888,9999999,11111111,22222222,33333333,44444444) THEN 1 ELSE 0 END AS HUMANO
      FROM WORK.UNIVERSO_VIS_&fechay t1
WHERE NOMB_ORIGEN IN ( 'TF') 
AND sucursal NOT = 39
GROUP BY RUT_CLIENTE
;QUIT;


/* ================================================================================================== ;
                          /* FUNNEL TF, UOF Y OFERTA DE CREDITO */
/* ================================================================================================== ;

/**/

PROC SQL;
   CREATE TABLE VISITAS_TF_NEW2_&fechay AS 
   SELECT A.*,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/ 
   /* MONTO_OFERTA */
   (SUM(B2.OFERTA_SAV_APROBADO)) FORMAT=BEST32. AS MONTO_OFERTA
      FROM VISITAS_TF_NEW_&fechay AS A
           LEFT JOIN SAV_APROBADO_FINAL_&fechay AS B2 ON (A.RUT_CLIENTE = B2.RUT_REAL)
      GROUP BY A.RUT_CLIENTE,
               A.CANTIDAD,
               A.HUMANO
;
QUIT;


/* ================================================================================================== */
                              /* FUNNEL TF, TRX TF */
/* ================================================================================================== */

PROC SQL;
   CREATE TABLE TRANSACCIONES_TF_&fechay AS 
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
		  &fechay AS PERIODO,
		 CASE WHEN t2.ACTIVIDAD_TR IN('ACTIVO','DORMIDO BLANDO','OTROS CON SALDO','SEMIACTIVO') 
         AND t3.RANGO_PROB IN ('0.4 - 0.5','0.5 - 0.6','0.6 - 0.7','0.7 - 0.8','0.8 - 0.9','0.9 - 1.0')THEN 'VERDES' ELSE 'NO_VERDES' END AS MARCA_VERDES
      FROM PUBLICIN.TRX_SAV_&fechay t1
	  LEFT JOIN PUBLICIN.ACT_TR_&fechayy t2 ON (t1.RUT = t2.RUT)
      LEFT JOIN RSEPULV.SCORE_&fechay t3 ON (t1.RUT = t3.RUT)
	  LEFT JOIN SAV_APROBADO_FINAL_&fechay AS t4 ON (t1.RUT = t4.RUT_REAL)
      WHERE t1.FECFAC BETWEEN "&fechainicioy" AND "&fechaterminoy" 
	  AND VIA_FINAL IN ('TF')
      GROUP BY t1.RUT,
	           t2.ACTIVIDAD_TR,
               t3.RANGO_PROB,
               t1.VIA_FINAL,
			   t1.PERIODO
;
QUIT;

PROC SQl;
CREATE TABLE VISITAS_TF_NEW3_&fechay AS 
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
FROM VISITAS_TF_NEW2_&fechay AS A
LEFT JOIN TRANSACCIONES_TF_&fechay AS B ON(A.RUT_CLIENTE = B.RUT)
;
quit;

PROC SQL;
UPDATE VISITAS_TF_NEW3_&fechay
SET RUT_CLIENTE = RUT
WHERE CURSE = 1
AND RUT NOT IS MISSING
AND RUT_CLIENTE IS MISSING
;
UPDATE VISITAS_TF_NEW3_&fechay
SET MONTO_OFERTA = OFERTA_SAV_APROBADO
WHERE CURSE = 1
AND OFERTA_SAV_APROBADO NOT IS MISSING
AND MONTO_OFERTA IS MISSING
; 
QUIT;


PROC SQL;
   CREATE TABLE ANEXA_VTA_TF_&fechay AS 
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
      FROM WORK.TRANSACCIONES_TF_&fechay t1
           LEFT JOIN WORK.VISITAS_TF_NEW3_&fechay t2 ON (t1.RUT = t2.RUT_CLIENTE)
      WHERE t2.RUT_CLIENTE IS MISSING;
QUIT;


PROC SQl;
CREATE TABLE VISITAS_TF_NEW4_&fechay AS 
SELECT * FROM VISITAS_TF_NEW3_&fechay
OUTER UNION CORR
SELECT * FROM ANEXA_VTA_TF_&fechay
; QUIT;


PROC SQL;
UPDATE VISITAS_TF_NEW4_&fechay
SET FEC_EJE = FEC_EJE
WHERE FEC_EJE IS MISSING
;
QUIT;


/* ================================================================================================== */
           /* FUNNEL TF, DEJAR EN DURO FUNNEL ORIGEN TERMINAL DE VENTAS (TIENDA)*/
/* ================================================================================================== */

PROC SQL;
   CREATE TABLE FUNNEL_TF_NEW_&fechay AS 
   SELECT t1.*
      FROM VISITAS_TF_NEW4_&fechay t1
;
QUIT;


/**************************************** VIA CCSS **********************************************/
/**/

PROC SQL;
   CREATE TABLE VISITAS_CIS_NEW_&fechay AS 
   SELECT DISTINCT RUT_CLIENTE,
   (COUNT(RUT_CLIENTE)) AS CANTIDAD,
   CASE WHEN (RUT_CLIENTE BETWEEN 1000000 AND 50000000) AND RUT_CLIENTE NOT IN (1111111,2222222,3333333,4444444,5555555,
   6666666,7777777,8888888,9999999,11111111,22222222,33333333,44444444) THEN 1 ELSE 0 END AS HUMANO
      FROM WORK.UNIVERSO_VIS_&fechay t1
WHERE NOMB_ORIGEN IN ( 'CCSS','ADM')
/* WHERE VIA IN ('CCSS')/*= 'CCSS'*/
GROUP BY RUT_CLIENTE
;QUIT;


/* ================================================================================================== ;
                          /* FUNNEL CIS, UOF Y OFERTA DE CREDITO */
/* ================================================================================================== ;

/**/

PROC SQL;
   CREATE TABLE VISITAS_CIS_NEW2_&fechay AS 
   SELECT A.*,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/ 
   /* MONTO_OFERTA */
   (SUM(B2.MONTO_oferta_SAV)) FORMAT=BEST32. AS MONTO_OFERTA
      FROM VISITAS_CIS_NEW_&fechay AS A
           LEFT JOIN SAV_PREA_FINAL_&fechay AS B2 ON (A.RUT_CLIENTE = B2.RUT_REAL)
      GROUP BY A.RUT_CLIENTE,
               A.CANTIDAD,
               A.HUMANO
;
QUIT;

/* ================================================================================================== */
                              /* FUNNEL CIS, TRX CIS */
/* ================================================================================================== */



PROC SQL;
   CREATE TABLE TRANSACCIONES_CIS_&fechay AS 
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
		  &fechay AS PERIODO,
		 CASE WHEN t2.ACTIVIDAD_TR IN('ACTIVO','DORMIDO BLANDO','OTROS CON SALDO','SEMIACTIVO') 
         AND t3.RANGO_PROB IN ('0.4 - 0.5','0.5 - 0.6','0.6 - 0.7','0.7 - 0.8','0.8 - 0.9','0.9 - 1.0')THEN 'VERDES' ELSE 'NO_VERDES' END AS MARCA_VERDES
      FROM PUBLICIN.TRX_SAV_&fechay t1
	  LEFT JOIN PUBLICIN.ACT_TR_&fechayy t2 ON (t1.RUT = t2.RUT)
      LEFT JOIN RSEPULV.SCORE_&fechay t3 ON (t1.RUT = t3.RUT)
	  LEFT JOIN SAV_PREA_FINAL_&fechay AS t4 ON (t1.RUT = t4.RUT_REAL)
      WHERE t1.FECFAC BETWEEN "&fechainicioy" AND "&fechaterminoy" 
	  AND VIA_FINAL IN ('CIS','TEF')
      GROUP BY t1.RUT,
	           t2.ACTIVIDAD_TR,
               t3.RANGO_PROB,
               t1.VIA_FINAL,
			   t1.PERIODO
;
QUIT;

PROC SQl;
CREATE TABLE VISITAS_CIS_NEW3_&fechay AS 
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
FROM VISITAS_CIS_NEW2_&fechay AS A
FULL JOIN TRANSACCIONES_CIS_&fechay AS B ON(A.RUT_CLIENTE = B.RUT)
;
quit;

PROC SQL;
UPDATE VISITAS_CIS_NEW3_&fechay
SET RUT_CLIENTE = RUT
WHERE CURSE = 1
AND RUT NOT IS MISSING
AND RUT_CLIENTE IS MISSING
;
UPDATE VISITAS_CIS_NEW3_&fechay
SET MONTO_OFERTA = MONTO_OFERTA_SAV
WHERE CURSE = 1
AND MONTO_OFERTA_SAV NOT IS MISSING
AND MONTO_OFERTA IS MISSING
; 
QUIT;

PROC SQL;
   CREATE TABLE ANEXA_VTA_CIS_&fechay AS 
   SELECT t1.RUT,
          t1.RUT AS RUT_CLIENTE,
		  'CIS' AS CANAL,
          1 AS CANTIDAD,
          1 AS HUMANO,
          1 AS VIS_OFE_APROB,
          1 AS TRX,
          1 AS CURSE, 
          t1.MONTO_CURSE, 
          t1.MONTO_oferta_SAV AS MONTO_OFERTA,
          t1.MONTO_oferta_SAV, 
          t1.VIA_FINAL 
      FROM WORK.TRANSACCIONES_CIS_&fechay t1
           LEFT JOIN WORK.VISITAS_CIS_NEW3_&fechay t2 ON (t1.RUT = t2.RUT_CLIENTE)
      WHERE t2.RUT_CLIENTE IS MISSING;
QUIT;


PROC SQl;
CREATE TABLE VISITAS_CIS_NEW4_&fechay AS 
SELECT * FROM VISITAS_CIS_NEW3_&fechay
OUTER UNION CORR
SELECT * FROM ANEXA_VTA_CIS_&fechay
; QUIT;


PROC SQL;
UPDATE VISITAS_CIS_NEW4_&fechay
SET FEC_EJE = FEC_EJE
WHERE FEC_EJE IS MISSING
;
QUIT;


/* ================================================================================================== */
           /* FUNNEL CIS, DEJAR EN DURO FUNNEL ORIGEN TERMINAL DE VENTAS (TIENDA)*/
/* ================================================================================================== */

PROC SQL;
   CREATE TABLE FUNNEL_CIS_NEW_&fechay AS 
   SELECT t1.*
      FROM VISITAS_CIS_NEW4_&fechay t1
;
QUIT;




/**************************************** VIA BCO **********************************************/
/**/



PROC SQL;
   CREATE TABLE VISITAS_BCO_NEW_&fechay AS 
   SELECT DISTINCT RUT_CLIENTE,
   (COUNT(RUT_CLIENTE)) AS CANTIDAD,
   CASE WHEN (RUT_CLIENTE BETWEEN 1000000 AND 50000000) AND RUT_CLIENTE NOT IN (1111111,2222222,3333333,4444444,5555555,
   6666666,7777777,8888888,9999999,11111111,22222222,33333333,44444444) THEN 1 ELSE 0 END AS HUMANO
      FROM WORK.UNIVERSO_VIS_&fechay t1
WHERE NOMB_ORIGEN = 'BANCO'
GROUP BY RUT_CLIENTE
;QUIT;


/* ================================================================================================== ;
                          /* FUNNEL BCO, UOF Y OFERTA DE CREDITO */
/* ================================================================================================== ;

/**/


PROC SQL;
   CREATE TABLE VISITAS_BCO_NEW2_&fechay AS 
   SELECT A.*,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/ 
   /* MONTO_OFERTA */
   (SUM(B2.MONTO_oferta_SAV)) FORMAT=BEST32. AS MONTO_OFERTA
      FROM VISITAS_BCO_NEW_&fechay AS A
           LEFT JOIN SAV_PREA_FINAL_&fechay AS B2 ON (A.RUT_CLIENTE = B2.RUT_REAL)
      GROUP BY A.RUT_CLIENTE,
               A.CANTIDAD,
               A.HUMANO
;
QUIT;


/* ================================================================================================== */
                              /* FUNNEL BCO, TRX BCO */
/* ================================================================================================== */


PROC SQL;
   CREATE TABLE TRANSACCIONES_BCO_&fechay AS 
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
		  &fechay AS PERIODO,
		 CASE WHEN t2.ACTIVIDAD_TR IN('ACTIVO','DORMIDO BLANDO','OTROS CON SALDO','SEMIACTIVO') 
         AND t3.RANGO_PROB IN ('0.4 - 0.5','0.5 - 0.6','0.6 - 0.7','0.7 - 0.8','0.8 - 0.9','0.9 - 1.0')THEN 'VERDES' ELSE 'NO_VERDES' END AS MARCA_VERDES
      FROM PUBLICIN.TRX_SAV_&fechay t1
	  LEFT JOIN PUBLICIN.ACT_TR_&fechayy t2 ON (t1.RUT = t2.RUT)
      LEFT JOIN RSEPULV.SCORE_&fechay t3 ON (t1.RUT = t3.RUT)
	  LEFT JOIN SAV_APROBADO_FINAL_&fechay AS t4 ON (t1.RUT = t4.RUT_REAL)
      WHERE t1.FECFAC BETWEEN "&fechainicioy" AND "&fechaterminoy" 
	  AND VIA_FINAL IN ('BCO')
      GROUP BY t1.RUT,
	           t2.ACTIVIDAD_TR,
               t3.RANGO_PROB,
               t1.VIA_FINAL,
			   t1.PERIODO
;
QUIT;

PROC SQl;
CREATE TABLE VISITAS_BCO_NEW3_&fechay AS 
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
FROM VISITAS_BCO_NEW2_&fechay AS A
FULL JOIN TRANSACCIONES_BCO_&fechay AS B ON(A.RUT_CLIENTE = B.RUT)
;
quit;

PROC SQL;
UPDATE VISITAS_BCO_NEW3_&fechay
SET RUT_CLIENTE = RUT
WHERE CURSE = 1
AND RUT NOT IS MISSING
AND RUT_CLIENTE IS MISSING
;
UPDATE VISITAS_BCO_NEW3_&fechay
SET MONTO_OFERTA = OFERTA_SAV_APROBADO
WHERE CURSE = 1
AND OFERTA_SAV_APROBADO NOT IS MISSING
AND MONTO_OFERTA IS MISSING
; 
QUIT;

PROC SQL;
   CREATE TABLE ANEXA_VTA_BCO_&fechay AS 
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
      FROM WORK.TRANSACCIONES_BCO_&fechay t1
           LEFT JOIN WORK.VISITAS_BCO_NEW3_&fechay t2 ON (t1.RUT = t2.RUT_CLIENTE)
      WHERE t2.RUT_CLIENTE IS MISSING;
QUIT;


PROC SQl;
CREATE TABLE VISITAS_BCO_NEW4_&fechay AS 
SELECT * FROM VISITAS_BCO_NEW3_&fechay
OUTER UNION CORR
SELECT * FROM ANEXA_VTA_BCO_&fechay
; QUIT;


PROC SQL;
UPDATE VISITAS_BCO_NEW4_&fechay
SET FEC_EJE = FEC_EJE
WHERE FEC_EJE IS MISSING
;
QUIT;


/* ================================================================================================== */
           /* FUNNEL BCO, DEJAR EN DURO FUNNEL ORIGEN TERMINAL DE VENTAS (TIENDA)*/
/* ================================================================================================== */

PROC SQL;
   CREATE TABLE FUNNEL_BCO_NEW_&fechay AS 
   SELECT t1.*
      FROM VISITAS_BCO_NEW4_&fechay t1
;
QUIT;





/**************************************** VIA MOVIL **********************************************/
/**/


PROC SQL;
   CREATE TABLE VISITAS_MOVIL_NEW_&fechay AS 
   SELECT DISTINCT RUT_CLIENTE,
   (COUNT(RUT_CLIENTE)) AS CANTIDAD,
   CASE WHEN (RUT_CLIENTE BETWEEN 1000000 AND 50000000) AND RUT_CLIENTE NOT IN (1111111,2222222,3333333,4444444,5555555,
   6666666,7777777,8888888,9999999,11111111,22222222,33333333,44444444) THEN 1 ELSE 0 END AS HUMANO
      FROM WORK.UNIVERSO_VIS_&fechay t1
WHERE NOMB_ORIGEN = 'MOVIL'
/* WHERE VIA IN ('CCSS')/*= 'CCSS'*/
GROUP BY RUT_CLIENTE
;QUIT;


/* ================================================================================================== ;
                          /* FUNNEL MOVIL, UOF Y OFERTA DE CREDITO */
/* ================================================================================================== ;

/**/

PROC SQL;
   CREATE TABLE VISITAS_MOVIL_NEW2_&fechay AS 
   SELECT A.*,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/ 
   /* MONTO_OFERTA */
   (SUM(B2.MONTO_oferta_SAV)) FORMAT=BEST32. AS MONTO_OFERTA
      FROM VISITAS_MOVIL_NEW_&fechay AS A
           LEFT JOIN SAV_PREA_FINAL_&fechay AS B2 ON (A.RUT_CLIENTE = B2.RUT_REAL)
      GROUP BY A.RUT_CLIENTE,
               A.CANTIDAD,
               A.HUMANO
;
QUIT;


/* ================================================================================================== */
                              /* FUNNEL MOVIL, TRX MOVIL */
/* ================================================================================================== */



PROC SQL;
   CREATE TABLE TRANSACCIONES_MOVIL_&fechay AS 
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
		  &fechay AS PERIODO,
		 CASE WHEN t2.ACTIVIDAD_TR IN('ACTIVO','DORMIDO BLANDO','OTROS CON SALDO','SEMIACTIVO') 
         AND t3.RANGO_PROB IN ('0.4 - 0.5','0.5 - 0.6','0.6 - 0.7','0.7 - 0.8','0.8 - 0.9','0.9 - 1.0')THEN 'VERDES' ELSE 'NO_VERDES' END AS MARCA_VERDES
      FROM PUBLICIN.TRX_SAV_&fechay t1
	  LEFT JOIN PUBLICIN.ACT_TR_&fechayy t2 ON (t1.RUT = t2.RUT)
      LEFT JOIN RSEPULV.SCORE_&fechay t3 ON (t1.RUT = t3.RUT)
	  LEFT JOIN SAV_APROBADO_FINAL_&fechay AS t4 ON (t1.RUT = t4.RUT_REAL)
      WHERE t1.FECFAC BETWEEN "&fechainicioy" AND "&fechaterminoy" 
	  AND VIA_FINAL = 'MOVIL'
      GROUP BY t1.RUT,
	           t2.ACTIVIDAD_TR,
               t3.RANGO_PROB,
               t1.VIA_FINAL,
			   t1.PERIODO
;
QUIT;


PROC SQl;
CREATE TABLE VISITAS_MOVIL_NEW3_&fechay AS 
SELECT
today() format=date9. as FEC_EJE,
'MOVIL' as CANAL,
A.*,
CASE WHEN  B.RUT IS NOT NULL THEN 1 ELSE 0 END AS CURSE,
B.RUT,
B.TRX AS TRX,
B.MONTO_CURSE,
B.OFERTA_SAV_APROBADO,
B.VIA_FINAL
FROM VISITAS_MOVIL_NEW2_&fechay AS A
FULL JOIN TRANSACCIONES_MOVIL_&fechay AS B ON(A.RUT_CLIENTE = B.RUT)
;
quit;


PROC SQL;
UPDATE VISITAS_MOVIL_NEW3_&fechay
SET RUT_CLIENTE = RUT
WHERE CURSE = 1
AND RUT NOT IS MISSING
AND RUT_CLIENTE IS MISSING
;
UPDATE VISITAS_MOVIL_NEW3_&fechay
SET MONTO_OFERTA = OFERTA_SAV_APROBADO
WHERE CURSE = 1
AND OFERTA_SAV_APROBADO NOT IS MISSING
AND MONTO_OFERTA IS MISSING
; 
QUIT;


PROC SQL;
   CREATE TABLE ANEXA_VTA_MOVIL_&fechay AS 
   SELECT t1.RUT,
          t1.RUT AS RUT_CLIENTE,
		  'MOVIL' AS CANAL,
          1 AS CANTIDAD,
          1 AS HUMANO,
          1 AS VIS_OFE_APROB,
          1 AS TRX,
          1 AS CURSE, 
          t1.MONTO_CURSE, 
          t1.OFERTA_SAV_APROBADO AS MONTO_OFERTA,
          t1.OFERTA_SAV_APROBADO, 
          t1.VIA_FINAL 
      FROM WORK.TRANSACCIONES_MOVIL_&fechay t1
           LEFT JOIN WORK.VISITAS_MOVIL_NEW3_&fechay t2 ON (t1.RUT = t2.RUT_CLIENTE)
      WHERE t2.RUT_CLIENTE IS MISSING;
QUIT;


PROC SQl;
CREATE TABLE VISITAS_MOVIL_NEW4_&fechay AS 
SELECT * FROM VISITAS_MOVIL_NEW3_&fechay
OUTER UNION CORR
SELECT * FROM ANEXA_VTA_MOVIL_&fechay
; QUIT;


PROC SQL;
UPDATE VISITAS_MOVIL_NEW4_&fechay
SET FEC_EJE = FEC_EJE
WHERE FEC_EJE IS MISSING
;
QUIT;


/* ================================================================================================== */
           /* FUNNEL MOVIL, DEJAR EN DURO FUNNEL ORIGEN TERMINAL DE VENTAS (TIENDA)*/
/* ================================================================================================== */

PROC SQL;
   CREATE TABLE FUNNEL_MOVIL_NEW_&fechay AS 
   SELECT t1.*
      FROM VISITAS_MOVIL_NEW4_&fechay t1
;
QUIT;


PROC SQL;
CREATE TABLE FUNNEL_NEW_SAV_&fechay AS

SELECT * FROM FUNNEL_TV_NEW_&fechay
OUTER UNION CORR
SELECT * FROM FUNNEL_TF_NEW_&fechay
OUTER UNION CORR
SELECT * FROM FUNNEL_CIS_NEW_&fechay
OUTER UNION CORR
SELECT * FROM FUNNEL_BCO_NEW_&fechay
OUTER UNION CORR
SELECT * FROM FUNNEL_MOVIL_NEW_&fechay
;
QUIT;



PROC SQL;
   CREATE TABLE FUNNEL_NEW_SAV_F_&fechay AS 
   SELECT t1.*,
          t2.ACTIVIDAD_TR, 
          t3.RANGO_PROB,
		  CASE WHEN t2.ACTIVIDAD_TR IN('ACTIVO','DORMIDO BLANDO','OTROS CON SALDO','SEMIACTIVO') 
           AND t3.RANGO_PROB IN ('0.4 - 0.5','0.5 - 0.6','0.6 - 0.7','0.7 - 0.8','0.8 - 0.9','0.9 - 1.0')THEN 'VERDES' ELSE 'NO_VERDES' END AS MARCA_VERDES 
      FROM FUNNEL_NEW_SAV_&fechay t1
           LEFT JOIN PUBLICIN.ACT_TR_&fechayy t2 ON (t1.RUT_CLIENTE = t2.RUT)
           LEFT JOIN RSEPULV.SCORE_&fechay t3 ON (t1.RUT_CLIENTE = t3.RUT)
;
QUIT;







/* 1RA PARTE VISITAS */

/********************************** MES - 12 ********************************************/


DATA _null_;
V_inicioAntes_12  = input(put(intnx('month',today(),-13,'begin' ),Date9.  ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
V_terminoAntes_12 = input(put(intnx('month',today(),-13,'end' ),Date9.  ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datez	= input(put(intnx('month',today(),-13,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datezz	= input(put(intnx('month',today(),-15,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
exec	= compress(input(put(today(),yymmdd10.),$10.),"-",c);
exec5	= compress(input(put(intnx('month',today(),-13,'begin' ),yymmdd10.  ),$10.),"-",c);
exec6	= compress(input(put(intnx('month',today(),-13,'end' ),yymmdd10.  ),$10.),"-",c);
Call symput("visitainicio_12",V_inicioAntes_12); /*mes anterior*/
Call symput("visitatermino_12",V_terminoAntes_12);
Call symput("fechaz", datez);
Call symput("fechazz", datezz);
Call symput("fechae",exec);
Call symput("fechae5",exec5);
Call symput("fechae6",exec6);
 
RUN;

%put &visitainicio_12;
%put &visitatermino_12;
%put &fechaz;
%put &fechazz;
%put &fechae;
%put &fechae5;
%put &fechae6;

RUN;


PROC SQL;
   CREATE TABLE VISITAS_&fechaz AS 
   SELECT t1.*,
          t1.RUT AS RUT_CLIENTE, 
          t2.NOMB_ORIGEN, 
          t2.NOMB_TIPO
      FROM PUBLICIN.TABLON_VISITAS_&fechaz t1
           LEFT JOIN PMUNOZ.PARAMETROS_TABLON_VISITAS t2 ON (t1.origen = t2.COD_ORIGEN) AND (t1.tipo = t2.COD_TIPO)
		   WHERE t1.fecha BETWEEN "&visitainicio_12"d AND "&visitatermino_12"d

;
QUIT;


/*OFERTA_APROBADA*/

PROC SQL;
   CREATE TABLE SAV_APROBADO_&fechaz AS 
   SELECT t1.RUT_REAL, 
          t1.SAV_APROBADO_FINAL, 
          t1.MONTO_PARA_CANON AS OFERTA_SAV_APROBADO,
          t1.MONTO_OFERTA_SAV 
      FROM JABURTOM.SAV_FIN_&fechaz t1
      WHERE t1.SAV_APROBADO_FINAL = 1
;
QUIT;

/*
PROC SQL;
   CREATE TABLE SAV_APROBADO_INCREM_&fechaz AS 
   SELECT t1.RUT_REAL, 
          t1.SAV_APROBADO_FINAL, 
          t1.MONTO_PARA_CANON AS OFERTA_SAV_APROBADO,
          t1.MONTO_OFERTA_SAV 
      FROM JABURTOM.SAV_CAR_INCREM_&fechaz t1
      WHERE t1.SAV_APROBADO_FINAL = 1
;
QUIT;

*/

PROC SQL;
CREATE TABLE SAV_APROBADO_FINAL_&fechaz AS
SELECT * FROM SAV_APROBADO_&fechaz
/*OUTER UNION CORR
SELECT * FROM SAV_APROBADO_INCREM_&fechaz*/

QUIT;

/*OFERTA_PRE_APROBADA*/

PROC SQL;
   CREATE TABLE SAV_PREA_&fechaz AS 
   SELECT t1.RUT_REAL, 
          t1.MONTO_OFERTA_SAV 
      FROM JABURTOM.SAV_FIN_&fechaz t1
      WHERE t1.MONTO_OFERTA_SAV >= 500000
;
QUIT;

/*
PROC SQL;
   CREATE TABLE SAV_PREA_INCREM_&fechaz AS 
   SELECT t1.RUT_REAL, 
          t1.MONTO_OFERTA_SAV 
      FROM JABURTOM.SAV_CAR_INCREM_&fechaz t1
      WHERE t1.MONTO_OFERTA_SAV >= 500000
;
QUIT;

*/

PROC SQL;
CREATE TABLE SAV_PREA_FINAL_&fechaz AS
SELECT * FROM SAV_PREA_&fechaz
/*OUTER UNION CORR
SELECT * FROM SAV_PREA_INCREM_&fechaz*/
;
QUIT;


PROC SQL;
   CREATE TABLE UNIVERSO_VIS_&fechaz AS 
   SELECT t1.*,
          &fechay AS PERIODO,
          t2.ACTIVIDAD_TR, 
          t3.RANGO_PROB, 
          t4.Decil_Sav,
		  CASE WHEN  t5.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
          CASE WHEN  t6.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB 
		 /*CASE WHEN  t5.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
         CASE WHEN  t6.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB*/
      FROM WORK.VISITAS_&fechaz t1
           LEFT JOIN PUBLICIN.ACT_TR_&fechazz t2 ON (t1.RUT_CLIENTE = t2.RUT)
           LEFT JOIN RSEPULV.SCORE_&fechaz t3 ON (t1.RUT_CLIENTE = t3.RUT)
           LEFT JOIN MALMENDR.SCORE_SAV_ADVA_&fechaz t4 ON (t1.RUT_CLIENTE = t4.RUT)
		   LEFT JOIN SAV_APROBADO_FINAL_&fechaz AS t5 ON(t1.RUT_CLIENTE = t5.RUT_REAL)
		   LEFT JOIN SAV_PREA_FINAL_&fechaz AS t6 ON(t1.RUT_CLIENTE = t6.RUT_REAL)
;
QUIT;


/**************************************** VIA TV **********************************************/

/**/

PROC SQL;
   CREATE TABLE VISITAS_TV_NEW_&fechaz AS 
   SELECT DISTINCT RUT_CLIENTE,
   (COUNT(RUT_CLIENTE)) AS CANTIDAD,
   CASE WHEN (RUT_CLIENTE BETWEEN 1000000 AND 50000000) AND RUT_CLIENTE NOT IN (1111111,2222222,3333333,4444444,5555555,
   6666666,7777777,8888888,9999999,11111111,22222222,33333333,44444444) THEN 1 ELSE 0 END AS HUMANO
      FROM WORK.UNIVERSO_VIS_&fechaz t1
WHERE NOMB_ORIGEN = 'TV'
AND sucursal NOT = 39
GROUP BY RUT_CLIENTE
;QUIT;


/* ================================================================================================== ;
                          /* FUNNEL TV, UOF Y OFERTA DE CREDITO */
/* ================================================================================================== ;

/**/

PROC SQL;
   CREATE TABLE VISITAS_TV_NEW2_&fechaz AS 
   SELECT A.*,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/ 
   /* MONTO_OFERTA */
   (SUM(B2.OFERTA_SAV_APROBADO)) FORMAT=BEST32. AS MONTO_OFERTA
      FROM VISITAS_TV_NEW_&fechaz AS A
           LEFT JOIN SAV_APROBADO_FINAL_&fechaz AS B2 ON (A.RUT_CLIENTE = B2.RUT_REAL)
      GROUP BY A.RUT_CLIENTE,
               A.CANTIDAD,
               A.HUMANO
;
QUIT;


/* ================================================================================================== */
                              /* FUNNEL TV, TRX TV */
/* ================================================================================================== */

DATA _null_;

inicioAntes_12  = input(put(intnx('month',today(),-13,'begin' ),yymmdd10.  ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
terminoAntes_12 = input(put(intnx('month',today(),-13,'end' ),yymmdd10.  ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datez	= input(put(intnx('month',today(),-13,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
exec	= compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechainicioz",inicioAntes_12);/*mes anterior*/
Call symput("fechaterminoz",terminoAntes_12);
Call symput("fechaz", datez);
Call symput("fechae",exec);

RUN;
%put &fechainicioz; 
%put &fechaterminoz;
%put &fechaz; 
%put &fechae;


PROC SQL;
   CREATE TABLE TRANSACCIONES_TV_&fechaz AS 
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
		  &fechaz AS PERIODO,
		 CASE WHEN t2.ACTIVIDAD_TR IN('ACTIVO','DORMIDO BLANDO','OTROS CON SALDO','SEMIACTIVO') 
         AND t3.RANGO_PROB IN ('0.4 - 0.5','0.5 - 0.6','0.6 - 0.7','0.7 - 0.8','0.8 - 0.9','0.9 - 1.0')THEN 'VERDES' ELSE 'NO_VERDES' END AS MARCA_VERDES
      FROM PUBLICIN.TRX_SAV_&fechaz t1
	  LEFT JOIN PUBLICIN.ACT_TR_&fechazz t2 ON (t1.RUT = t2.RUT)
      LEFT JOIN RSEPULV.SCORE_&fechaz t3 ON (t1.RUT = t3.RUT)
	  LEFT JOIN SAV_APROBADO_FINAL_&fechaz AS t4 ON (t1.RUT = t4.RUT_REAL)
      WHERE t1.FECFAC BETWEEN "&fechainicioz" AND "&fechaterminoz" 
	  AND VIA_FINAL IN ('TV')
      GROUP BY t1.RUT,
	           t2.ACTIVIDAD_TR,
               t3.RANGO_PROB,
               t1.VIA_FINAL,
			   t1.PERIODO
;
QUIT;

PROC SQl;
CREATE TABLE VISITAS_TV_NEW3_&fechaz AS 
SELECT
today() format=date9. as FEC_EJE,
'TV' as CANAL,
A.*,
CASE WHEN  B.RUT IS NOT NULL THEN 1 ELSE 0 END AS CURSE,
B.RUT,
B.TRX AS TRX,
B.MONTO_CURSE,
B.OFERTA_SAV_APROBADO,
B.VIA_FINAL
FROM VISITAS_TV_NEW2_&fechaz AS A
LEFT JOIN TRANSACCIONES_TV_&fechaz AS B ON(A.RUT_CLIENTE = B.RUT)
;
quit;

PROC SQL;
UPDATE VISITAS_TV_NEW3_&fechaz
SET RUT_CLIENTE = RUT
WHERE CURSE = 1
AND RUT NOT IS MISSING
AND RUT_CLIENTE IS MISSING
;
UPDATE VISITAS_TV_NEW3_&fechaz
SET MONTO_OFERTA = OFERTA_SAV_APROBADO
WHERE CURSE = 1
AND OFERTA_SAV_APROBADO NOT IS MISSING
AND MONTO_OFERTA IS MISSING
; 
QUIT;


PROC SQL;
   CREATE TABLE ANEXA_VTA_TV_&fechaz AS 
   SELECT t1.RUT,
          t1.RUT AS RUT_CLIENTE,
		  'TV' AS CANAL,
          1 AS CANTIDAD,
          1 AS HUMANO,
          1 AS VIS_OFE_APROB,
          1 AS TRX,
          1 AS CURSE, 
          t1.MONTO_CURSE, 
          t1.OFERTA_SAV_APROBADO AS MONTO_OFERTA,
          t1.OFERTA_SAV_APROBADO, 
          t1.VIA_FINAL 
      FROM WORK.TRANSACCIONES_TV_&fechaz t1
           LEFT JOIN WORK.VISITAS_TV_NEW3_&fechaz t2 ON (t1.RUT = t2.RUT_CLIENTE)
      WHERE t2.RUT_CLIENTE IS MISSING;
QUIT;


PROC SQl;
CREATE TABLE VISITAS_TV_NEW4_&fechaz AS 
SELECT * FROM VISITAS_TV_NEW3_&fechaz
OUTER UNION CORR
SELECT * FROM ANEXA_VTA_TV_&fechaz
; QUIT;


PROC SQL;
UPDATE VISITAS_TV_NEW4_&fechaz
SET FEC_EJE = FEC_EJE
WHERE FEC_EJE IS MISSING
;
QUIT;


/* ================================================================================================== */
           /* FUNNEL TV, DEJAR EN DURO FUNNEL ORIGEN TERMINAL DE VENTAS (TIENDA)*/
/* ================================================================================================== */


PROC SQL;
   CREATE TABLE FUNNEL_TV_NEW_&fechaz AS 
   SELECT t1.*
      FROM VISITAS_TV_NEW4_&fechaz t1
;
QUIT;


/**************************************** VIA TF **********************************************/

PROC SQL;
   CREATE TABLE VISITAS_TF_NEW_&fechaz AS 
   SELECT DISTINCT RUT_CLIENTE,
   (COUNT(RUT_CLIENTE)) AS CANTIDAD,
   CASE WHEN (RUT_CLIENTE BETWEEN 1000000 AND 50000000) AND RUT_CLIENTE NOT IN (1111111,2222222,3333333,4444444,5555555,
   6666666,7777777,8888888,9999999,11111111,22222222,33333333,44444444) THEN 1 ELSE 0 END AS HUMANO
      FROM WORK.UNIVERSO_VIS_&fechaz t1
WHERE NOMB_ORIGEN IN ( 'TF') 
AND sucursal NOT = 39
GROUP BY RUT_CLIENTE
;QUIT;


/* ================================================================================================== ;
                          /* FUNNEL TF, UOF Y OFERTA DE CREDITO */
/* ================================================================================================== ;

/**/

PROC SQL;
   CREATE TABLE VISITAS_TF_NEW2_&fechaz AS 
   SELECT A.*,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/ 
   /* MONTO_OFERTA */
   (SUM(B2.OFERTA_SAV_APROBADO)) FORMAT=BEST32. AS MONTO_OFERTA
      FROM VISITAS_TF_NEW_&fechaz AS A
           LEFT JOIN SAV_APROBADO_FINAL_&fechaz AS B2 ON (A.RUT_CLIENTE = B2.RUT_REAL)
      GROUP BY A.RUT_CLIENTE,
               A.CANTIDAD,
               A.HUMANO
;
QUIT;


/* ================================================================================================== */
                              /* FUNNEL TF, TRX TF */
/* ================================================================================================== */

PROC SQL;
   CREATE TABLE TRANSACCIONES_TF_&fechaz AS 
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
		  &fechaz AS PERIODO,
		 CASE WHEN t2.ACTIVIDAD_TR IN('ACTIVO','DORMIDO BLANDO','OTROS CON SALDO','SEMIACTIVO') 
         AND t3.RANGO_PROB IN ('0.4 - 0.5','0.5 - 0.6','0.6 - 0.7','0.7 - 0.8','0.8 - 0.9','0.9 - 1.0')THEN 'VERDES' ELSE 'NO_VERDES' END AS MARCA_VERDES
      FROM PUBLICIN.TRX_SAV_&fechaz t1
	  LEFT JOIN PUBLICIN.ACT_TR_&fechazz t2 ON (t1.RUT = t2.RUT)
      LEFT JOIN RSEPULV.SCORE_&fechaz t3 ON (t1.RUT = t3.RUT)
	  LEFT JOIN SAV_APROBADO_FINAL_&fechaz AS t4 ON (t1.RUT = t4.RUT_REAL)
      WHERE t1.FECFAC BETWEEN "&fechainicioz" AND "&fechaterminoz" 
	  AND VIA_FINAL IN ('TF')
      GROUP BY t1.RUT,
	           t2.ACTIVIDAD_TR,
               t3.RANGO_PROB,
               t1.VIA_FINAL,
			   t1.PERIODO
;
QUIT;

PROC SQl;
CREATE TABLE VISITAS_TF_NEW3_&fechaz AS 
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
FROM VISITAS_TF_NEW2_&fechaz AS A
LEFT JOIN TRANSACCIONES_TF_&fechaz AS B ON(A.RUT_CLIENTE = B.RUT)
;
quit;

PROC SQL;
UPDATE VISITAS_TF_NEW3_&fechaz
SET RUT_CLIENTE = RUT
WHERE CURSE = 1
AND RUT NOT IS MISSING
AND RUT_CLIENTE IS MISSING
;
UPDATE VISITAS_TF_NEW3_&fechaz
SET MONTO_OFERTA = OFERTA_SAV_APROBADO
WHERE CURSE = 1
AND OFERTA_SAV_APROBADO NOT IS MISSING
AND MONTO_OFERTA IS MISSING
; 
QUIT;


PROC SQL;
   CREATE TABLE ANEXA_VTA_TF_&fechaz AS 
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
      FROM WORK.TRANSACCIONES_TF_&fechaz t1
           LEFT JOIN WORK.VISITAS_TF_NEW3_&fechaz t2 ON (t1.RUT = t2.RUT_CLIENTE)
      WHERE t2.RUT_CLIENTE IS MISSING;
QUIT;


PROC SQl;
CREATE TABLE VISITAS_TF_NEW4_&fechaz AS 
SELECT * FROM VISITAS_TF_NEW3_&fechaz
OUTER UNION CORR
SELECT * FROM ANEXA_VTA_TF_&fechaz
; QUIT;


PROC SQL;
UPDATE VISITAS_TF_NEW4_&fechaz
SET FEC_EJE = FEC_EJE
WHERE FEC_EJE IS MISSING
;
QUIT;


/* ================================================================================================== */
           /* FUNNEL TF, DEJAR EN DURO FUNNEL ORIGEN TERMINAL DE VENTAS (TIENDA)*/
/* ================================================================================================== */

PROC SQL;
   CREATE TABLE FUNNEL_TF_NEW_&fechaz AS 
   SELECT t1.*
      FROM VISITAS_TF_NEW4_&fechaz t1
;
QUIT;


/**************************************** VIA CCSS **********************************************/
/**/

PROC SQL;
   CREATE TABLE VISITAS_CIS_NEW_&fechaz AS 
   SELECT DISTINCT RUT_CLIENTE,
   (COUNT(RUT_CLIENTE)) AS CANTIDAD,
   CASE WHEN (RUT_CLIENTE BETWEEN 1000000 AND 50000000) AND RUT_CLIENTE NOT IN (1111111,2222222,3333333,4444444,5555555,
   6666666,7777777,8888888,9999999,11111111,22222222,33333333,44444444) THEN 1 ELSE 0 END AS HUMANO
      FROM WORK.UNIVERSO_VIS_&fechaz t1
WHERE NOMB_ORIGEN IN ( 'CCSS','ADM')
/* WHERE VIA IN ('CCSS')/*= 'CCSS'*/
GROUP BY RUT_CLIENTE
;QUIT;


/* ================================================================================================== ;
                          /* FUNNEL CIS, UOF Y OFERTA DE CREDITO */
/* ================================================================================================== ;

/**/

PROC SQL;
   CREATE TABLE VISITAS_CIS_NEW2_&fechaz AS 
   SELECT A.*,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/ 
   /* MONTO_OFERTA */
   (SUM(B2.MONTO_oferta_SAV)) FORMAT=BEST32. AS MONTO_OFERTA
      FROM VISITAS_CIS_NEW_&fechaz AS A
           LEFT JOIN SAV_PREA_FINAL_&fechaz AS B2 ON (A.RUT_CLIENTE = B2.RUT_REAL)
      GROUP BY A.RUT_CLIENTE,
               A.CANTIDAD,
               A.HUMANO
;
QUIT;

/* ================================================================================================== */
                              /* FUNNEL CIS, TRX CIS */
/* ================================================================================================== */



PROC SQL;
   CREATE TABLE TRANSACCIONES_CIS_&fechaz AS 
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
		  &fechaz AS PERIODO,
		 CASE WHEN t2.ACTIVIDAD_TR IN('ACTIVO','DORMIDO BLANDO','OTROS CON SALDO','SEMIACTIVO') 
         AND t3.RANGO_PROB IN ('0.4 - 0.5','0.5 - 0.6','0.6 - 0.7','0.7 - 0.8','0.8 - 0.9','0.9 - 1.0')THEN 'VERDES' ELSE 'NO_VERDES' END AS MARCA_VERDES
      FROM PUBLICIN.TRX_SAV_&fechaz t1
	  LEFT JOIN PUBLICIN.ACT_TR_&fechazz t2 ON (t1.RUT = t2.RUT)
      LEFT JOIN RSEPULV.SCORE_&fechaz t3 ON (t1.RUT = t3.RUT)
	  LEFT JOIN SAV_PREA_FINAL_&fechaz AS t4 ON (t1.RUT = t4.RUT_REAL)
      WHERE t1.FECFAC BETWEEN "&fechainicioz" AND "&fechaterminoz" 
	  AND VIA_FINAL IN ('CIS','TEF')
      GROUP BY t1.RUT,
	           t2.ACTIVIDAD_TR,
               t3.RANGO_PROB,
               t1.VIA_FINAL,
			   t1.PERIODO
;
QUIT;

PROC SQl;
CREATE TABLE VISITAS_CIS_NEW3_&fechaz AS 
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
FROM VISITAS_CIS_NEW2_&fechaz AS A
FULL JOIN TRANSACCIONES_CIS_&fechaz AS B ON(A.RUT_CLIENTE = B.RUT)
;
quit;

PROC SQL;
UPDATE VISITAS_CIS_NEW3_&fechaz
SET RUT_CLIENTE = RUT
WHERE CURSE = 1
AND RUT NOT IS MISSING
AND RUT_CLIENTE IS MISSING
;
UPDATE VISITAS_CIS_NEW3_&fechaz
SET MONTO_OFERTA = MONTO_OFERTA_SAV
WHERE CURSE = 1
AND MONTO_OFERTA_SAV NOT IS MISSING
AND MONTO_OFERTA IS MISSING
; 
QUIT;

PROC SQL;
   CREATE TABLE ANEXA_VTA_CIS_&fechaz AS 
   SELECT t1.RUT,
          t1.RUT AS RUT_CLIENTE,
		  'CIS' AS CANAL,
          1 AS CANTIDAD,
          1 AS HUMANO,
          1 AS VIS_OFE_APROB,
          1 AS TRX,
          1 AS CURSE, 
          t1.MONTO_CURSE, 
          t1.MONTO_oferta_SAV AS MONTO_OFERTA,
          t1.MONTO_oferta_SAV, 
          t1.VIA_FINAL 
      FROM WORK.TRANSACCIONES_CIS_&fechaz t1
           LEFT JOIN WORK.VISITAS_CIS_NEW3_&fechaz t2 ON (t1.RUT = t2.RUT_CLIENTE)
      WHERE t2.RUT_CLIENTE IS MISSING;
QUIT;


PROC SQl;
CREATE TABLE VISITAS_CIS_NEW4_&fechaz AS 
SELECT * FROM VISITAS_CIS_NEW3_&fechaz
OUTER UNION CORR
SELECT * FROM ANEXA_VTA_CIS_&fechaz
; QUIT;


PROC SQL;
UPDATE VISITAS_CIS_NEW4_&fechaz
SET FEC_EJE = FEC_EJE
WHERE FEC_EJE IS MISSING
;
QUIT;


/* ================================================================================================== */
           /* FUNNEL CIS, DEJAR EN DURO FUNNEL ORIGEN TERMINAL DE VENTAS (TIENDA)*/
/* ================================================================================================== */

PROC SQL;
   CREATE TABLE FUNNEL_CIS_NEW_&fechaz AS 
   SELECT t1.*
      FROM VISITAS_CIS_NEW4_&fechaz t1
;
QUIT;




/**************************************** VIA BCO **********************************************/
/**/



PROC SQL;
   CREATE TABLE VISITAS_BCO_NEW_&fechaz AS 
   SELECT DISTINCT RUT_CLIENTE,
   (COUNT(RUT_CLIENTE)) AS CANTIDAD,
   CASE WHEN (RUT_CLIENTE BETWEEN 1000000 AND 50000000) AND RUT_CLIENTE NOT IN (1111111,2222222,3333333,4444444,5555555,
   6666666,7777777,8888888,9999999,11111111,22222222,33333333,44444444) THEN 1 ELSE 0 END AS HUMANO
      FROM WORK.UNIVERSO_VIS_&fechaz t1
WHERE NOMB_ORIGEN = 'BANCO'
GROUP BY RUT_CLIENTE
;QUIT;


/* ================================================================================================== ;
                          /* FUNNEL BCO, UOF Y OFERTA DE CREDITO */
/* ================================================================================================== ;

/**/


PROC SQL;
   CREATE TABLE VISITAS_BCO_NEW2_&fechaz AS 
   SELECT A.*,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/ 
   /* MONTO_OFERTA */
   (SUM(B2.MONTO_oferta_SAV)) FORMAT=BEST32. AS MONTO_OFERTA
      FROM VISITAS_BCO_NEW_&fechaz AS A
           LEFT JOIN SAV_PREA_FINAL_&fechaz AS B2 ON (A.RUT_CLIENTE = B2.RUT_REAL)
      GROUP BY A.RUT_CLIENTE,
               A.CANTIDAD,
               A.HUMANO
;
QUIT;


/* ================================================================================================== */
                              /* FUNNEL BCO, TRX BCO */
/* ================================================================================================== */


PROC SQL;
   CREATE TABLE TRANSACCIONES_BCO_&fechaz AS 
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
		  &fechaz AS PERIODO,
		 CASE WHEN t2.ACTIVIDAD_TR IN('ACTIVO','DORMIDO BLANDO','OTROS CON SALDO','SEMIACTIVO') 
         AND t3.RANGO_PROB IN ('0.4 - 0.5','0.5 - 0.6','0.6 - 0.7','0.7 - 0.8','0.8 - 0.9','0.9 - 1.0')THEN 'VERDES' ELSE 'NO_VERDES' END AS MARCA_VERDES
      FROM PUBLICIN.TRX_SAV_&fechaz t1
	  LEFT JOIN PUBLICIN.ACT_TR_&fechazz t2 ON (t1.RUT = t2.RUT)
      LEFT JOIN RSEPULV.SCORE_&fechaz t3 ON (t1.RUT = t3.RUT)
	  LEFT JOIN SAV_APROBADO_FINAL_&fechaz AS t4 ON (t1.RUT = t4.RUT_REAL)
      WHERE t1.FECFAC BETWEEN "&fechainicioz" AND "&fechaterminoz" 
	  AND VIA_FINAL IN ('BCO')
      GROUP BY t1.RUT,
	           t2.ACTIVIDAD_TR,
               t3.RANGO_PROB,
               t1.VIA_FINAL,
			   t1.PERIODO
;
QUIT;

PROC SQl;
CREATE TABLE VISITAS_BCO_NEW3_&fechaz AS 
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
FROM VISITAS_BCO_NEW2_&fechaz AS A
FULL JOIN TRANSACCIONES_BCO_&fechaz AS B ON(A.RUT_CLIENTE = B.RUT)
;
quit;

PROC SQL;
UPDATE VISITAS_BCO_NEW3_&fechaz
SET RUT_CLIENTE = RUT
WHERE CURSE = 1
AND RUT NOT IS MISSING
AND RUT_CLIENTE IS MISSING
;
UPDATE VISITAS_BCO_NEW3_&fechaz
SET MONTO_OFERTA = OFERTA_SAV_APROBADO
WHERE CURSE = 1
AND OFERTA_SAV_APROBADO NOT IS MISSING
AND MONTO_OFERTA IS MISSING
; 
QUIT;

PROC SQL;
   CREATE TABLE ANEXA_VTA_BCO_&fechaz AS 
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
      FROM WORK.TRANSACCIONES_BCO_&fechaz t1
           LEFT JOIN WORK.VISITAS_BCO_NEW3_&fechaz t2 ON (t1.RUT = t2.RUT_CLIENTE)
      WHERE t2.RUT_CLIENTE IS MISSING;
QUIT;


PROC SQl;
CREATE TABLE VISITAS_BCO_NEW4_&fechaz AS 
SELECT * FROM VISITAS_BCO_NEW3_&fechaz
OUTER UNION CORR
SELECT * FROM ANEXA_VTA_BCO_&fechaz
; QUIT;


PROC SQL;
UPDATE VISITAS_BCO_NEW4_&fechaz
SET FEC_EJE = FEC_EJE
WHERE FEC_EJE IS MISSING
;
QUIT;


/* ================================================================================================== */
           /* FUNNEL BCO, DEJAR EN DURO FUNNEL ORIGEN TERMINAL DE VENTAS (TIENDA)*/
/* ================================================================================================== */

PROC SQL;
   CREATE TABLE FUNNEL_BCO_NEW_&fechaz AS 
   SELECT t1.*
      FROM VISITAS_BCO_NEW4_&fechaz t1
;
QUIT;





/**************************************** VIA MOVIL **********************************************/
/**/


PROC SQL;
   CREATE TABLE VISITAS_MOVIL_NEW_&fechaz AS 
   SELECT DISTINCT RUT_CLIENTE,
   (COUNT(RUT_CLIENTE)) AS CANTIDAD,
   CASE WHEN (RUT_CLIENTE BETWEEN 1000000 AND 50000000) AND RUT_CLIENTE NOT IN (1111111,2222222,3333333,4444444,5555555,
   6666666,7777777,8888888,9999999,11111111,22222222,33333333,44444444) THEN 1 ELSE 0 END AS HUMANO
      FROM WORK.UNIVERSO_VIS_&fechaz t1
WHERE NOMB_ORIGEN = 'MOVIL'
/* WHERE VIA IN ('CCSS')/*= 'CCSS'*/
GROUP BY RUT_CLIENTE
;QUIT;


/* ================================================================================================== ;
                          /* FUNNEL MOVIL, UOF Y OFERTA DE CREDITO */
/* ================================================================================================== ;

/**/

PROC SQL;
   CREATE TABLE VISITAS_MOVIL_NEW2_&fechaz AS 
   SELECT A.*,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/ 
   /* MONTO_OFERTA */
   (SUM(B2.MONTO_oferta_SAV)) FORMAT=BEST32. AS MONTO_OFERTA
      FROM VISITAS_MOVIL_NEW_&fechaz AS A
           LEFT JOIN SAV_PREA_FINAL_&fechaz AS B2 ON (A.RUT_CLIENTE = B2.RUT_REAL)
      GROUP BY A.RUT_CLIENTE,
               A.CANTIDAD,
               A.HUMANO
;
QUIT;


/* ================================================================================================== */
                              /* FUNNEL MOVIL, TRX MOVIL */
/* ================================================================================================== */



PROC SQL;
   CREATE TABLE TRANSACCIONES_MOVIL_&fechaz AS 
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
		  &fechaz AS PERIODO,
		 CASE WHEN t2.ACTIVIDAD_TR IN('ACTIVO','DORMIDO BLANDO','OTROS CON SALDO','SEMIACTIVO') 
         AND t3.RANGO_PROB IN ('0.4 - 0.5','0.5 - 0.6','0.6 - 0.7','0.7 - 0.8','0.8 - 0.9','0.9 - 1.0')THEN 'VERDES' ELSE 'NO_VERDES' END AS MARCA_VERDES
      FROM PUBLICIN.TRX_SAV_&fechaz t1
	  LEFT JOIN PUBLICIN.ACT_TR_&fechazz t2 ON (t1.RUT = t2.RUT)
      LEFT JOIN RSEPULV.SCORE_&fechaz t3 ON (t1.RUT = t3.RUT)
	  LEFT JOIN SAV_APROBADO_FINAL_&fechaz AS t4 ON (t1.RUT = t4.RUT_REAL)
      WHERE t1.FECFAC BETWEEN "&fechainicioz" AND "&fechaterminoz" 
	  AND VIA_FINAL = 'MOVIL'
      GROUP BY t1.RUT,
	           t2.ACTIVIDAD_TR,
               t3.RANGO_PROB,
               t1.VIA_FINAL,
			   t1.PERIODO
;
QUIT;


PROC SQl;
CREATE TABLE VISITAS_MOVIL_NEW3_&fechaz AS 
SELECT
today() format=date9. as FEC_EJE,
'MOVIL' as CANAL,
A.*,
CASE WHEN  B.RUT IS NOT NULL THEN 1 ELSE 0 END AS CURSE,
B.RUT,
B.TRX AS TRX,
B.MONTO_CURSE,
B.OFERTA_SAV_APROBADO,
B.VIA_FINAL
FROM VISITAS_MOVIL_NEW2_&fechaz AS A
FULL JOIN TRANSACCIONES_MOVIL_&fechaz AS B ON(A.RUT_CLIENTE = B.RUT)
;
quit;


PROC SQL;
UPDATE VISITAS_MOVIL_NEW3_&fechaz
SET RUT_CLIENTE = RUT
WHERE CURSE = 1
AND RUT NOT IS MISSING
AND RUT_CLIENTE IS MISSING
;
UPDATE VISITAS_MOVIL_NEW3_&fechaz
SET MONTO_OFERTA = OFERTA_SAV_APROBADO
WHERE CURSE = 1
AND OFERTA_SAV_APROBADO NOT IS MISSING
AND MONTO_OFERTA IS MISSING
; 
QUIT;


PROC SQL;
   CREATE TABLE ANEXA_VTA_MOVIL_&fechaz AS 
   SELECT t1.RUT,
          t1.RUT AS RUT_CLIENTE,
		  'MOVIL' AS CANAL,
          1 AS CANTIDAD,
          1 AS HUMANO,
          1 AS VIS_OFE_APROB,
          1 AS TRX,
          1 AS CURSE, 
          t1.MONTO_CURSE, 
          t1.OFERTA_SAV_APROBADO AS MONTO_OFERTA,
          t1.OFERTA_SAV_APROBADO, 
          t1.VIA_FINAL 
      FROM WORK.TRANSACCIONES_MOVIL_&fechaz t1
           LEFT JOIN WORK.VISITAS_MOVIL_NEW3_&fechaz t2 ON (t1.RUT = t2.RUT_CLIENTE)
      WHERE t2.RUT_CLIENTE IS MISSING;
QUIT;


PROC SQl;
CREATE TABLE VISITAS_MOVIL_NEW4_&fechaz AS 
SELECT * FROM VISITAS_MOVIL_NEW3_&fechaz
OUTER UNION CORR
SELECT * FROM ANEXA_VTA_MOVIL_&fechaz
; QUIT;


PROC SQL;
UPDATE VISITAS_MOVIL_NEW4_&fechaz
SET FEC_EJE = FEC_EJE
WHERE FEC_EJE IS MISSING
;
QUIT;


/* ================================================================================================== */
           /* FUNNEL MOVIL, DEJAR EN DURO FUNNEL ORIGEN TERMINAL DE VENTAS (TIENDA)*/
/* ================================================================================================== */

PROC SQL;
   CREATE TABLE FUNNEL_MOVIL_NEW_&fechaz AS 
   SELECT t1.*
      FROM VISITAS_MOVIL_NEW4_&fechaz t1
;
QUIT;


PROC SQL;
CREATE TABLE FUNNEL_NEW_SAV_&fechaz AS

SELECT * FROM FUNNEL_TV_NEW_&fechaz
OUTER UNION CORR
SELECT * FROM FUNNEL_TF_NEW_&fechaz
OUTER UNION CORR
SELECT * FROM FUNNEL_CIS_NEW_&fechaz
OUTER UNION CORR
SELECT * FROM FUNNEL_BCO_NEW_&fechaz
OUTER UNION CORR
SELECT * FROM FUNNEL_MOVIL_NEW_&fechaz
;
QUIT;



PROC SQL;
   CREATE TABLE FUNNEL_NEW_SAV_F_&fechaz AS 
   SELECT t1.*,
          t2.ACTIVIDAD_TR, 
          t3.RANGO_PROB,
		  CASE WHEN t2.ACTIVIDAD_TR IN('ACTIVO','DORMIDO BLANDO','OTROS CON SALDO','SEMIACTIVO') 
           AND t3.RANGO_PROB IN ('0.4 - 0.5','0.5 - 0.6','0.6 - 0.7','0.7 - 0.8','0.8 - 0.9','0.9 - 1.0')THEN 'VERDES' ELSE 'NO_VERDES' END AS MARCA_VERDES 
      FROM FUNNEL_NEW_SAV_&fechaz t1
           LEFT JOIN PUBLICIN.ACT_TR_&fechazz t2 ON (t1.RUT_CLIENTE = t2.RUT)
           LEFT JOIN RSEPULV.SCORE_&fechaz t3 ON (t1.RUT_CLIENTE = t3.RUT)
;
QUIT;




PROC SQL;
DROP TABLE BORRADO
,VISITAS_TOTALES_TDA_&fechax
,VISITAS_TOTALES_OMP_&fechax
,VISITAS_TOTAL_TDA_F_&fechax
,SAV_APROBADO_&fechax
,SAV_APROBADO_INCREM_&fechax
,VISITAS_TDA_OFERTAS_&fechax
,VISITAS_CIS_ADM_TOT_&fechax
,VISITAS_BCO_S_&fechax
,VISITAS_TOTAL_ADM_BCO_F_&fechax

,VISITAS_TOTALES_TDA_&fechay
,VISITAS_TOTALES_OMP_&fechay
,VISITAS_TOTAL_TDA_F_&fechay
,SAV_APROBADO_&fechay
,SAV_APROBADO_INCREM_&fechay
,VISITAS_TDA_OFERTAS_&fechay
,VISITAS_CIS_ADM_TOT_&fechay
,VISITAS_BCO_S_&fechay
,VISITAS_TOTAL_ADM_BCO_F_&fechay

,SAV_PREA_&fechax
,SAV_PREA_FINAL_&fechax
,SAV_APROBADO_FINAL_&fechax
,VISITAS_CIS_NEW_&fechax
,VISITAS_CIS_NEW2_&fechax
,VISITAS_CIS_NEW3_&fechax
,VISITAS_TF_NEW2_&fechax
,VISITAS_TF_NEW3_&fechax
,VISITAS_TF_NEW_&fechax
,VISITAS_TV_&fechax
,VISITAS_TV_NEW_&fechax
,VISITAS_TV_NEW2_&fechax
,VISITAS_TV_NEW3_&fechax
,VISITAS_TV_NEW4_&fechax
,VISITAS_TV_NEW4_&fechay
,VISITAS_BCO_NEW_&fechax
,VISITAS_BCO_NEW2_&fechax
,VISITAS_BCO_NEW3_&fechax
,VISITAS_MOVIL_NEW2_&fechax
,VISITAS_MOVIL_NEW3_&fechax
,VISITAS_MOVIL_NEW4_&fechax
,VISITAS_MOVIL_NEW2_&fechay
,VISITAS_MOVIL_NEW3_&fechay
,VISITAS_MOVIL_NEW4_&fechay
,SAV_PREA_&fechay
,SAV_PREA_FINAL_&fechay
,SAV_APROBADO_FINAL_&fechay
,UNIVERSO_VIS_BCO_CIS_&fechay
,UNIVERSO_VIS_BCO_CIS_1_&fechay
,VISITAS_CIS_&fechay
,VISITAS_CIS_NEW_&fechay
,VISITAS_CIS_NEW_&fechax
,VISITAS_CIS_NEW2_&fechay
,VISITAS_CIS_NEW3_&fechay
,VISITAS_CIS_NEW4_&fechay
,VISITAS_CIS_NEW4_&fechax

,VISITAS_TF_NEW2_&fechay
,VISITAS_TF_NEW3_&fechay
,VISITAS_TF_NEW4_&fechay
,VISITAS_TF_NEW4_&fechax
,VISITAS_TF_NEW_&fechay
,VISITAS_TV_NEW_&fechay
,VISITAS_TV_NEW2_&fechay
,VISITAS_TV_NEW3_&fechay
,VISITAS_TV_NEW4_&fechay
,VISITAS_TV_NEW4_&fechax
,VISITAS_BCO_NEW4_&fechay
,VISITAS_BCO_NEW4_&fechax
,VISITAS_BCO_NEW_&fechay
,VISITAS_BCO_NEW2_&fechay
,VISITAS_BCO_NEW3_&fechay
,VISITAS_MOVIL_NEW_&fechay
,VISITAS_MOVIL_NEW_&fechax
,UNIVERSO_VIS_&fechax
,UNIVERSO_VIS_&fechay
,UNIVERSO_VIS_BCO_CIS_&fechax
,UNIVERSO_VIS_BCO_CIS_1_&fechax
,FUNNEL_BCO_NEW_&fechax
,FUNNEL_CIS_NEW_&fechax
,FUNNEL_SAV_NEW_&fechax
,FUNNEL_TF_NEW_&fechax
,FUNNEL_TV_NEW_&fechax
,TRANSACCIONES_BCO_&fechax
,TRANSACCIONES_CIS_&fechax
,TRANSACCIONES_TF_&fechax
,TRANSACCIONES_TV_&fechax
,RESUMEN_VIS_&fechax
,FUNEL_SAV_PRUEBA

,FUNNEL_BCO_NEW_&fechay
,FUNNEL_CIS_NEW_&fechay
,FUNNEL_SAV_NEW_&fechay
,FUNNEL_TF_NEW_&fechay
,FUNNEL_TV_NEW_&fechay
,FUNNEL_MOVIL_NEW_&fechay
,FUNNEL_MOVIL_NEW_&fechax
,VISITAS_&fechax
,VISITAS_&fechay

,TRANSACCIONES_BCO_&fechay
,TRANSACCIONES_CIS_&fechay
,TRANSACCIONES_TF_&fechay
,TRANSACCIONES_TV_&fechay
,TRANSACCIONES_MOVIL_&fechay
,TRANSACCIONES_MOVIL_&fechax
,RESUMEN_VIS_&fechay

,ANEXA_VTA_BCO_&fechay
,ANEXA_VTA_BCO_&fechax
,ANEXA_VTA_CIS_&fechay
,ANEXA_VTA_CIS_&fechax
,ANEXA_VTA_MOVIL_&fechay
,ANEXA_VTA_MOVIL_&fechax
,ANEXA_VTA_TF_&fechay
,ANEXA_VTA_TF_&fechax
,ANEXA_VTA_TV_&fechay
,ANEXA_VTA_TV_&fechax

,VISITAS_TOTALES_TDA_&fechaz
,VISITAS_TOTALES_OMP_&fechaz
,VISITAS_TOTAL_TDA_F_&fechaz
,SAV_APROBADO_&fechaz
,SAV_APROBADO_INCREM_&fechaz
,VISITAS_TDA_OFERTAS_&fechaz
,VISITAS_CIS_ADM_TOT_&fechaz
,VISITAS_BCO_S_&fechaz
,VISITAS_TOTAL_ADM_BCO_F_&fechaz

,VISITAS_TOTALES_TDA_&fechaz
,VISITAS_TOTALES_OMP_&fechaz
,VISITAS_TOTAL_TDA_F_&fechaz
,SAV_APROBADO_&fechaz
,SAV_APROBADO_INCREM_&fechaz
,VISITAS_TDA_OFERTAS_&fechaz
,VISITAS_CIS_ADM_TOT_&fechaz
,VISITAS_BCO_S_&fechaz
,VISITAS_TOTAL_ADM_BCO_F_&fechaz

,SAV_PREA_&fechaz
,SAV_PREA_FINAL_&fechaz
,SAV_APROBADO_FINAL_&fechaz
,VISITAS_CIS_NEW_&fechaz
,VISITAS_CIS_NEW2_&fechaz
,VISITAS_CIS_NEW3_&fechaz
,VISITAS_TF_NEW2_&fechaz
,VISITAS_TF_NEW3_&fechaz
,VISITAS_TF_NEW_&fechaz
,VISITAS_TV_&fechaz
,VISITAS_TV_NEW_&fechaz
,VISITAS_TV_NEW2_&fechaz
,VISITAS_TV_NEW3_&fechaz
,VISITAS_TV_NEW4_&fechaz
,VISITAS_TV_NEW4_&fechaz
,VISITAS_BCO_NEW_&fechaz
,VISITAS_BCO_NEW2_&fechaz
,VISITAS_BCO_NEW3_&fechaz
,VISITAS_MOVIL_NEW2_&fechaz
,VISITAS_MOVIL_NEW3_&fechaz
,VISITAS_MOVIL_NEW4_&fechaz
,VISITAS_MOVIL_NEW2_&fechaz
,VISITAS_MOVIL_NEW3_&fechaz
,VISITAS_MOVIL_NEW4_&fechaz

,SAV_PREA_&fechaz
,SAV_PREA_FINAL_&fechaz
,SAV_APROBADO_FINAL_&fechaz
,UNIVERSO_VIS_BCO_CIS_&fechaz
,UNIVERSO_VIS_BCO_CIS_1_&fechaz
,VISITAS_CIS_&fechaz
,VISITAS_CIS_NEW_&fechaz
,VISITAS_CIS_NEW_&fechaz
,VISITAS_CIS_NEW2_&fechaz
,VISITAS_CIS_NEW3_&fechaz
,VISITAS_CIS_NEW4_&fechaz
,VISITAS_CIS_NEW4_&fechaz

,VISITAS_TF_NEW2_&fechaz
,VISITAS_TF_NEW3_&fechaz
,VISITAS_TF_NEW4_&fechaz
,VISITAS_TF_NEW4_&fechaz
,VISITAS_TF_NEW_&fechaz
,VISITAS_TV_NEW_&fechaz
,VISITAS_TV_NEW2_&fechaz
,VISITAS_TV_NEW3_&fechaz
,VISITAS_TV_NEW4_&fechaz
,VISITAS_TV_NEW4_&fechaz
,VISITAS_BCO_NEW4_&fechaz
,VISITAS_BCO_NEW4_&fechaz
,VISITAS_BCO_NEW_&fechaz
,VISITAS_BCO_NEW2_&fechaz
,VISITAS_BCO_NEW3_&fechaz
,VISITAS_MOVIL_NEW_&fechaz
,UNIVERSO_VIS_&fechaz
,UNIVERSO_VIS_BCO_CIS_&fechaz
,UNIVERSO_VIS_BCO_CIS_1_&fechaz
,FUNNEL_BCO_NEW_&fechaz
,FUNNEL_CIS_NEW_&fechaz
,FUNNEL_SAV_NEW_&fechaz
,FUNNEL_TF_NEW_&fechaz
,FUNNEL_TV_NEW_&fechaz
,TRANSACCIONES_BCO_&fechaz
,TRANSACCIONES_CIS_&fechaz
,TRANSACCIONES_TF_&fechaz
,TRANSACCIONES_TV_&fechaz
,RESUMEN_VIS_&fechaz
,FUNEL_SAV_PRUEBA

,FUNNEL_BCO_NEW_&fechaz
,FUNNEL_CIS_NEW_&fechaz
,FUNNEL_SAV_NEW_&fechaz
,FUNNEL_TF_NEW_&fechaz
,FUNNEL_MOVIL_NEW_&fechaz
,VISITAS_&fechaz

,TRANSACCIONES_BCO_&fechaz
,TRANSACCIONES_TF_&fechaz
,TRANSACCIONES_MOVIL_&fechaz
,RESUMEN_VIS_&fechaz

,ANEXA_VTA_BCO_&fechaz
,ANEXA_VTA_CIS_&fechaz
,ANEXA_VTA_MOVIL_&fechaz
,ANEXA_VTA_TF_&fechaz
,ANEXA_VTA_TV_&fechaz


;
QUIT;




/************** CREAR  RESUMEN PARA TABLEAU Y ADD IN SAS ****************************/

/************************************************************************************/


/* MES ACTUAL RESUMEN ADD IN*/


/* ============================================================================================== */
                                      /* Resumen TV */
/* ============================================================================================== */


proc sql;
create table TV_TV_&fechax as  
select
'01.TV' as CANAL,
'01.TV' AS SEGUIMIENTO, 
&fechax as periodo,
MARCA_VERDES,
VIS_OFE_APROB AS OFERTA_A, 
VIS_OFE_PRE_APROB AS OFERTA_PREA, 
sum(CANTIDAD) AS VISITAS_TOTALES,
count(CANTIDAD)AS VISITAS_UNICAS, 
count(case when HUMANO=1 and VIS_OFE_APROB  in (1) then RUT_CLIENTE end) as OFERTA_UNICA,
/*COUNT(RUT_CLIENTE)) AS OFERTA_UNICA,*/
/*count(case when HUMANO=1 and VIS_OFE_PRE_APROB  in ('CON_OFERTA','SIN OFERTA') then RUT_CLIENTE end) as oferta_RIESGO_PREA,*/
SUM(case when humano IN (1,.)  AND VIS_OFE_APROB IN (1,0,.) AND CURSE = 1 AND VIA_FINAL IN ('TV') THEN  CURSE END ) AS CURSE,
SUM(MONTO_CURSE) AS MTO_CURSE,
SUM(case when CURSE = 1 AND VIA_FINAL IN ('TV') THEN MONTO_OFERTA END ) AS MTO_OFERTA 
FROM FUNNEL_NEW_SAV_F_&fechax
WHERE CANAL = 'TV'
GROUP BY 
CANAL,
SEGUIMIENTO, 
periodo,
MARCA_VERDES,
VIS_OFE_APROB, 
VIS_OFE_PRE_APROB 
/*CON_OFERTA_APROB,
CON_OFERTA_PRE_APROB*/
;
QUIT;



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
/* count(case when HUMANO=1 and CON_OFERTA_PRE_APROB  in ('CON_OFERTA','SIN OFERTA') then RUT_CLIENTE end) as oferta_RIESGO_PREA,*/
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
/*CON_OFERTA_APROB,
CON_OFERTA_PRE_APROB*/ 
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
/* count(case when HUMANO=1 and CON_OFERTA_APROB  in ('CON_OFERTA','SIN OFERTA') then RUT_CLIENTE end) as oferta_RIESGO_A,*/
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
/*CON_OFERTA_APROB,
CON_OFERTA_PRE_APROB */
;
QUIT;


/* ============================================================================================== */
                                      /* Resumen BCO */
/* ============================================================================================== */

/*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/


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
/* count(case when HUMANO=1 and CON_OFERTA_APROB  in ('CON_OFERTA','SIN OFERTA') then RUT_CLIENTE end) as OFERTA_RIESGO,*/
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
/*CON_OFERTA_APROB,
CON_OFERTA_PRE_APROB*/ 
;
QUIT;



/* ============================================================================================== */
                                      /* Resumen MOVIL */
/* ============================================================================================== */

/*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/


proc sql;
create table MOVIL_MOVIL_&fechax as  
select
'05.MOVIL' as CANAL,
'05.MOVIL' AS SEGUIMIENTO, 
&fechax as periodo,
MARCA_VERDES,
VIS_OFE_APROB AS OFERTA_A, 
VIS_OFE_PRE_APROB AS OFERTA_PREA,  
sum(CANTIDAD) as VISITAS_TOTALES,
COUNT(CANTIDAD)AS VISITAS_UNICAS, 
/* count(case when HUMANO=1 and CON_OFERTA_APROB  in ('CON_OFERTA','SIN OFERTA') then RUT_CLIENTE end) as OFERTA_RIESGO,*/
count(case when HUMANO=1 and VIS_OFE_PRE_APROB  in (1,0) then RUT_CLIENTE end) as OFERTA_UNICA,
SUM(case when humano IN (1,.)  AND VIS_OFE_APROB IN (1,0,.) AND CURSE = 1 AND VIA_FINAL = 'MOVIL' THEN  CURSE END ) AS CURSE,
SUM(MONTO_CURSE) AS MTO_CURSE,
SUM(case when CURSE = 1 AND VIA_FINAL = 'MOVIL' THEN MONTO_OFERTA END ) AS MTO_OFERTA 
FROM FUNNEL_NEW_SAV_F_&fechax
WHERE CANAL = 'MOVIL'
GROUP BY 
CANAL,
SEGUIMIENTO, 
periodo,
MARCA_VERDES,
VIS_OFE_APROB, 
VIS_OFE_PRE_APROB 
/*CON_OFERTA_APROB,
CON_OFERTA_PRE_APROB*/ 
;
QUIT;


PROC SQL;
CREATE TABLE FUNNEL_SAV_RESUMEN_&fechax AS
SELECT * FROM TV_TV_&fechax
OUTER UNION CORR
SELECT * FROM TF_TF_&fechax
OUTER UNION CORR 
SELECT * FROM CIS_CIS_&fechax
OUTER UNION CORR 
SELECT * FROM BCO_BCO_&fechax
OUTER UNION CORR 
SELECT * FROM MOVIL_MOVIL_&fechax
;
QUIT; 



/* MES -1 */

/* ============================================================================================== */
                                      /* Resumen TV */
/* ============================================================================================== */


proc sql;
create table TV_TV_&fechay as  
select
'01.TV' as CANAL,
'01.TV' AS SEGUIMIENTO, 
&fechay as periodo,
MARCA_VERDES,
VIS_OFE_APROB AS OFERTA_A, 
VIS_OFE_PRE_APROB AS OFERTA_PREA, 
sum(CANTIDAD) AS VISITAS_TOTALES,
count(CANTIDAD)AS VISITAS_UNICAS, 
count(case when HUMANO=1 and VIS_OFE_APROB  in (1) then RUT_CLIENTE end) as OFERTA_UNICA,
/*COUNT(RUT_CLIENTE)) AS OFERTA_UNICA,*/
/*count(case when HUMANO=1 and VIS_OFE_PRE_APROB  in ('CON_OFERTA','SIN OFERTA') then RUT_CLIENTE end) as oferta_RIESGO_PREA,*/
SUM(case when humano IN (1,.)  AND VIS_OFE_APROB IN (1,0,.) AND CURSE = 1 AND VIA_FINAL IN ('TV') THEN  CURSE END ) AS CURSE,
SUM(MONTO_CURSE) AS MTO_CURSE,
SUM(case when CURSE = 1 AND VIA_FINAL IN ('TV') THEN MONTO_OFERTA END ) AS MTO_OFERTA 
FROM FUNNEL_NEW_SAV_F_&fechay
WHERE CANAL = 'TV'
GROUP BY 
CANAL,
SEGUIMIENTO, 
periodo,
MARCA_VERDES,
VIS_OFE_APROB, 
VIS_OFE_PRE_APROB 
/*CON_OFERTA_APROB,
CON_OFERTA_PRE_APROB*/
;
QUIT;



/* ============================================================================================== */
                                      /* Resumen TF */
/* ============================================================================================== */

proc sql;
create table TF_TF_&fechay as  
select
'02.TF' as CANAL,
'02.TF' AS SEGUIMIENTO, 
&fechay as periodo,
MARCA_VERDES,
VIS_OFE_APROB AS OFERTA_A, 
VIS_OFE_PRE_APROB AS OFERTA_PREA,  
sum(CANTIDAD) as VISITAS_TOTALES,
COUNT(CANTIDAD)AS VISITAS_UNICAS,  
count(case when HUMANO=1 and VIS_OFE_APROB  in (1) then RUT_CLIENTE end) as OFERTA_UNICA,
/* count(case when HUMANO=1 and CON_OFERTA_PRE_APROB  in ('CON_OFERTA','SIN OFERTA') then RUT_CLIENTE end) as oferta_RIESGO_PREA,*/
SUM(case when humano IN (1,.)  AND VIS_OFE_APROB IN (1,0,.) AND CURSE = 1 AND VIA_FINAL IN ('TF') THEN  CURSE END ) AS CURSE,
SUM(MONTO_CURSE) AS MTO_CURSE,
SUM(case when CURSE = 1 AND VIA_FINAL IN ('TF') THEN MONTO_OFERTA END ) AS MTO_OFERTA  
FROM FUNNEL_NEW_SAV_F_&fechay
WHERE CANAL = 'TF'
GROUP BY 
CANAL,
SEGUIMIENTO, 
periodo,
MARCA_VERDES,
VIS_OFE_APROB, 
VIS_OFE_PRE_APROB 
/*CON_OFERTA_APROB,
CON_OFERTA_PRE_APROB*/ 
;
QUIT;




/* ============================================================================================== */
                                      /* Resumen CIS */
/* ============================================================================================== */


proc sql;
create table CIS_CIS_&fechay as  
select
'03.CIS' as CANAL,
'03.CIS' AS SEGUIMIENTO, 
&fechay as periodo,
MARCA_VERDES,
VIS_OFE_APROB AS OFERTA_A, 
VIS_OFE_PRE_APROB AS OFERTA_PREA,  
sum(CANTIDAD) as VISITAS_TOTALES,
COUNT(CANTIDAD)AS VISITAS_UNICAS, 
/* count(case when HUMANO=1 and CON_OFERTA_APROB  in ('CON_OFERTA','SIN OFERTA') then RUT_CLIENTE end) as oferta_RIESGO_A,*/
count(case when HUMANO=1 and VIS_OFE_PRE_APROB  in (1) then RUT_CLIENTE end) as OFERTA_UNICA,
SUM(case when humano IN (1,.)  AND VIS_OFE_PRE_APROB IN (1,0,.) AND CURSE = 1 AND VIA_FINAL IN ('CIS','TEF') THEN  CURSE END ) AS CURSE,
SUM(MONTO_CURSE) AS MTO_CURSE,
SUM(case when CURSE = 1 AND VIA_FINAL IN ('CIS','TEF') THEN MONTO_OFERTA END ) AS MTO_OFERTA 
FROM FUNNEL_NEW_SAV_F_&fechay
WHERE CANAL = 'CCSS'
GROUP BY 
CANAL,
SEGUIMIENTO, 
periodo,
MARCA_VERDES,
VIS_OFE_APROB, 
VIS_OFE_PRE_APROB 
/*CON_OFERTA_APROB,
CON_OFERTA_PRE_APROB */
;
QUIT;


/* ============================================================================================== */
                                      /* Resumen BCO */
/* ============================================================================================== */

/*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/


proc sql;
create table BCO_BCO_&fechay as  
select
'04.BCO' as CANAL,
'04.BCO' AS SEGUIMIENTO, 
&fechay as periodo,
MARCA_VERDES,
VIS_OFE_APROB AS OFERTA_A, 
VIS_OFE_PRE_APROB AS OFERTA_PREA,  
sum(CANTIDAD) as VISITAS_TOTALES,
COUNT(CANTIDAD)AS VISITAS_UNICAS, 
/* count(case when HUMANO=1 and CON_OFERTA_APROB  in ('CON_OFERTA','SIN OFERTA') then RUT_CLIENTE end) as OFERTA_RIESGO,*/
count(case when HUMANO=1 and VIS_OFE_PRE_APROB  in (1) then RUT_CLIENTE end) as OFERTA_UNICA,
SUM(case when humano IN (1,.)  AND VIS_OFE_APROB IN (1,0,.) AND CURSE = 1 AND VIA_FINAL IN ('BCO') THEN  CURSE END ) AS CURSE,
SUM(MONTO_CURSE) AS MTO_CURSE,
SUM(case when CURSE = 1 AND VIA_FINAL IN ('BCO') THEN MONTO_OFERTA END ) AS MTO_OFERTA 
FROM FUNNEL_NEW_SAV_F_&fechay
WHERE CANAL = 'BCO'
GROUP BY 
CANAL,
SEGUIMIENTO, 
periodo,
MARCA_VERDES,
VIS_OFE_APROB, 
VIS_OFE_PRE_APROB 
/*CON_OFERTA_APROB,
CON_OFERTA_PRE_APROB*/ 
;
QUIT;


proc sql;
create table MOVIL_MOVIL_&fechay as  
select
'05.MOVIL' as CANAL,
'05.MOVIL' AS SEGUIMIENTO, 
&fechay as periodo,
MARCA_VERDES,
VIS_OFE_APROB AS OFERTA_A, 
VIS_OFE_PRE_APROB AS OFERTA_PREA,  
sum(CANTIDAD) as VISITAS_TOTALES,
COUNT(CANTIDAD)AS VISITAS_UNICAS, 
/* count(case when HUMANO=1 and CON_OFERTA_APROB  in ('CON_OFERTA','SIN OFERTA') then RUT_CLIENTE end) as OFERTA_RIESGO,*/
count(case when HUMANO=1 and VIS_OFE_PRE_APROB  in (1) then RUT_CLIENTE end) as OFERTA_UNICA,
SUM(case when humano IN (1,.)  AND VIS_OFE_APROB IN (1,0,.) AND CURSE = 1 AND VIA_FINAL IN ('MOVIL') THEN  CURSE END ) AS CURSE,
SUM(MONTO_CURSE) AS MTO_CURSE,
SUM(case when CURSE = 1 AND VIA_FINAL IN ('MOVIL') THEN MONTO_OFERTA END ) AS MTO_OFERTA 
FROM FUNNEL_NEW_SAV_F_&fechay
WHERE CANAL = 'MOVIL'
GROUP BY 
CANAL,
SEGUIMIENTO, 
periodo,
MARCA_VERDES,
VIS_OFE_APROB, 
VIS_OFE_PRE_APROB 
/*CON_OFERTA_APROB,
CON_OFERTA_PRE_APROB*/ 
;
QUIT;


PROC SQL;
CREATE TABLE FUNNEL_SAV_RESUMEN_&fechay AS
SELECT * FROM TV_TV_&fechay
OUTER UNION CORR
SELECT * FROM TF_TF_&fechay
OUTER UNION CORR 
SELECT * FROM CIS_CIS_&fechay
OUTER UNION CORR 
SELECT * FROM BCO_BCO_&fechay
OUTER UNION CORR 
SELECT * FROM MOVIL_MOVIL_&fechay
;
QUIT;




/* MES -12 */

/* ============================================================================================== */
                                      /* Resumen TV */
/* ============================================================================================== */


proc sql;
create table TV_TV_&fechaz as  
select
'01.TV' as CANAL,
'01.TV' AS SEGUIMIENTO, 
&fechaz as periodo,
MARCA_VERDES,
VIS_OFE_APROB AS OFERTA_A, 
VIS_OFE_PRE_APROB AS OFERTA_PREA, 
sum(CANTIDAD) AS VISITAS_TOTALES,
count(CANTIDAD)AS VISITAS_UNICAS, 
count(case when HUMANO=1 and VIS_OFE_APROB  in (1) then RUT_CLIENTE end) as OFERTA_UNICA,
/*COUNT(RUT_CLIENTE)) AS OFERTA_UNICA,*/
/*count(case when HUMANO=1 and VIS_OFE_PRE_APROB  in ('CON_OFERTA','SIN OFERTA') then RUT_CLIENTE end) as oferta_RIESGO_PREA,*/
SUM(case when humano IN (1,.)  AND VIS_OFE_APROB IN (1,0,.) AND CURSE = 1 AND VIA_FINAL IN ('TV') THEN  CURSE END ) AS CURSE,
SUM(MONTO_CURSE) AS MTO_CURSE,
SUM(case when CURSE = 1 AND VIA_FINAL IN ('TV') THEN MONTO_OFERTA END ) AS MTO_OFERTA 
FROM FUNNEL_NEW_SAV_F_&fechaz
WHERE CANAL = 'TV'
GROUP BY 
CANAL,
SEGUIMIENTO, 
periodo,
MARCA_VERDES,
VIS_OFE_APROB, 
VIS_OFE_PRE_APROB 
/*CON_OFERTA_APROB,
CON_OFERTA_PRE_APROB*/
;
QUIT;



/* ============================================================================================== */
                                      /* Resumen TF */
/* ============================================================================================== */

proc sql;
create table TF_TF_&fechaz as  
select
'02.TF' as CANAL,
'02.TF' AS SEGUIMIENTO, 
&fechaz as periodo,
MARCA_VERDES,
VIS_OFE_APROB AS OFERTA_A, 
VIS_OFE_PRE_APROB AS OFERTA_PREA,  
sum(CANTIDAD) as VISITAS_TOTALES,
COUNT(CANTIDAD)AS VISITAS_UNICAS,  
count(case when HUMANO=1 and VIS_OFE_APROB  in (1) then RUT_CLIENTE end) as OFERTA_UNICA,
/* count(case when HUMANO=1 and CON_OFERTA_PRE_APROB  in ('CON_OFERTA','SIN OFERTA') then RUT_CLIENTE end) as oferta_RIESGO_PREA,*/
SUM(case when humano IN (1,.)  AND VIS_OFE_APROB IN (1,0,.) AND CURSE = 1 AND VIA_FINAL IN ('TF') THEN  CURSE END ) AS CURSE,
SUM(MONTO_CURSE) AS MTO_CURSE,
SUM(case when CURSE = 1 AND VIA_FINAL IN ('TF') THEN MONTO_OFERTA END ) AS MTO_OFERTA  
FROM FUNNEL_NEW_SAV_F_&fechaz
WHERE CANAL = 'TF'
GROUP BY 
CANAL,
SEGUIMIENTO, 
periodo,
MARCA_VERDES,
VIS_OFE_APROB, 
VIS_OFE_PRE_APROB 
/*CON_OFERTA_APROB,
CON_OFERTA_PRE_APROB*/ 
;
QUIT;




/* ============================================================================================== */
                                      /* Resumen CIS */
/* ============================================================================================== */


proc sql;
create table CIS_CIS_&fechaz as  
select
'03.CIS' as CANAL,
'03.CIS' AS SEGUIMIENTO, 
&fechaz as periodo,
MARCA_VERDES,
VIS_OFE_APROB AS OFERTA_A, 
VIS_OFE_PRE_APROB AS OFERTA_PREA,  
sum(CANTIDAD) as VISITAS_TOTALES,
COUNT(CANTIDAD)AS VISITAS_UNICAS, 
/* count(case when HUMANO=1 and CON_OFERTA_APROB  in ('CON_OFERTA','SIN OFERTA') then RUT_CLIENTE end) as oferta_RIESGO_A,*/
count(case when HUMANO=1 and VIS_OFE_PRE_APROB  in (1) then RUT_CLIENTE end) as OFERTA_UNICA,
SUM(case when humano IN (1,.)  AND VIS_OFE_PRE_APROB IN (1,0,.) AND CURSE = 1 AND VIA_FINAL IN ('CIS','TEF') THEN  CURSE END ) AS CURSE,
SUM(MONTO_CURSE) AS MTO_CURSE,
SUM(case when CURSE = 1 AND VIA_FINAL IN ('CIS','TEF') THEN MONTO_OFERTA END ) AS MTO_OFERTA 
FROM FUNNEL_NEW_SAV_F_&fechaz
WHERE CANAL = 'CCSS'
GROUP BY 
CANAL,
SEGUIMIENTO, 
periodo,
MARCA_VERDES,
VIS_OFE_APROB, 
VIS_OFE_PRE_APROB 
/*CON_OFERTA_APROB,
CON_OFERTA_PRE_APROB */
;
QUIT;


/* ============================================================================================== */
                                      /* Resumen BCO */
/* ============================================================================================== */

/*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 1 ELSE 0 END AS VIS_OFE_PRE_APROB,
   /*CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_APROB,
   CASE WHEN  B2.RUT_REAL IS NOT NULL THEN 'CON_OFERTA' ELSE 'SIN OFERTA' END AS CON_OFERTA_PRE_APROB,*/


proc sql;
create table BCO_BCO_&fechaz as  
select
'04.BCO' as CANAL,
'04.BCO' AS SEGUIMIENTO, 
&fechaz as periodo,
MARCA_VERDES,
VIS_OFE_APROB AS OFERTA_A, 
VIS_OFE_PRE_APROB AS OFERTA_PREA,  
sum(CANTIDAD) as VISITAS_TOTALES,
COUNT(CANTIDAD)AS VISITAS_UNICAS, 
/* count(case when HUMANO=1 and CON_OFERTA_APROB  in ('CON_OFERTA','SIN OFERTA') then RUT_CLIENTE end) as OFERTA_RIESGO,*/
count(case when HUMANO=1 and VIS_OFE_PRE_APROB  in (1) then RUT_CLIENTE end) as OFERTA_UNICA,
SUM(case when humano IN (1,.)  AND VIS_OFE_APROB IN (1,0,.) AND CURSE = 1 AND VIA_FINAL IN ('BCO') THEN  CURSE END ) AS CURSE,
SUM(MONTO_CURSE) AS MTO_CURSE,
SUM(case when CURSE = 1 AND VIA_FINAL IN ('BCO') THEN MONTO_OFERTA END ) AS MTO_OFERTA 
FROM FUNNEL_NEW_SAV_F_&fechaz
WHERE CANAL = 'BCO'
GROUP BY 
CANAL,
SEGUIMIENTO, 
periodo,
MARCA_VERDES,
VIS_OFE_APROB, 
VIS_OFE_PRE_APROB 
/*CON_OFERTA_APROB,
CON_OFERTA_PRE_APROB*/ 
;
QUIT;


proc sql;
create table MOVIL_MOVIL_&fechaz as  
select
'05.MOVIL' as CANAL,
'05.MOVIL' AS SEGUIMIENTO, 
&fechaz as periodo,
MARCA_VERDES,
VIS_OFE_APROB AS OFERTA_A, 
VIS_OFE_PRE_APROB AS OFERTA_PREA,  
sum(CANTIDAD) as VISITAS_TOTALES,
COUNT(CANTIDAD)AS VISITAS_UNICAS, 
/* count(case when HUMANO=1 and CON_OFERTA_APROB  in ('CON_OFERTA','SIN OFERTA') then RUT_CLIENTE end) as OFERTA_RIESGO,*/
count(case when HUMANO=1 and VIS_OFE_PRE_APROB  in (1) then RUT_CLIENTE end) as OFERTA_UNICA,
SUM(case when humano IN (1,.)  AND VIS_OFE_APROB IN (1,0,.) AND CURSE = 1 AND VIA_FINAL IN ('MOVIL') THEN  CURSE END ) AS CURSE,
SUM(MONTO_CURSE) AS MTO_CURSE,
SUM(case when CURSE = 1 AND VIA_FINAL IN ('MOVIL') THEN MONTO_OFERTA END ) AS MTO_OFERTA 
FROM FUNNEL_NEW_SAV_F_&fechaz
WHERE CANAL = 'MOVIL'
GROUP BY 
CANAL,
SEGUIMIENTO, 
periodo,
MARCA_VERDES,
VIS_OFE_APROB, 
VIS_OFE_PRE_APROB 
/*CON_OFERTA_APROB,
CON_OFERTA_PRE_APROB*/ 
;
QUIT;


PROC SQL;
CREATE TABLE FUNNEL_SAV_RESUMEN_&fechaz AS
SELECT * FROM TV_TV_&fechaz
OUTER UNION CORR
SELECT * FROM TF_TF_&fechaz
OUTER UNION CORR 
SELECT * FROM CIS_CIS_&fechaz
OUTER UNION CORR 
SELECT * FROM BCO_BCO_&fechaz
OUTER UNION CORR 
SELECT * FROM MOVIL_MOVIL_&fechaz
;
QUIT;



PROC SQL;
CREATE TABLE  PUBLICIN.FUNNEL_SAV_RESUMEN_CIERRE_UNIF AS
SELECT * FROM FUNNEL_SAV_RESUMEN_&fechax
OUTER UNION CORR
SELECT * FROM FUNNEL_SAV_RESUMEN_&fechay
OUTER UNION CORR
SELECT * FROM FUNNEL_SAV_RESUMEN_&fechaz

;
QUIT; 


/*RESPALDO*/

PROC SQL;
   CREATE TABLE PUBLICIN.FUNNEL_SAV_CIERRE_UNIF_&fechax AS 
   SELECT t1.*
      FROM PUBLICIN.FUNNEL_SAV_RESUMEN_CIERRE_UNIF t1
;
QUIT;

/********************************* SUBIR  A TABLEAU  ********************************/

/************************************************************************************/

%let lib=PUBLICIN;

%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(ppff_funnel_sav_res_c_unif,raw,oracloud,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(ppff_funnel_sav_res_c_unif,publicin.funnel_sav_resumen_cierre_unif,raw,oracloud,0);



%put==================================================================================================;
%put                                   EMAIL AUTOMATICO ;
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
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';

SELECT EMAIL into :DEST_3 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'CLAUDIA_PAREDES';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;


data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_2","&DEST_3","rlaizh@bancoripley.com")
CC = ("&DEST_1")
SUBJECT="MAIL_AUTOM: PROCESO Funnel SAV %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso Funnel SAV Diario, ejecutado con fecha: &fechaeDVN";  
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
