



/*========================================= MES EN CURSO ========================================================*/
/**/
/*proc printto log='/sasdata/users94/jaburtom/logs/log_Trx_SAV.txt'; */
/*run;*/


DATA _null_;
datehi     = compress(input(put(intnx('month',today(),-1,'begin' ),yymmdd10.     ),$20.),"-",c); /*cambiar 0 a -1 para ver cierre mes anterior*/
datehf     = compress(input(put(intnx('month',today(),-1,'end'    ),yymmdd10.      ),$20.),"-",c); /*cambiar 0 a -1 para ver cierre mes anterior*/
datei      = input(put(intnx('month',today(),-1,'begin' ),yymmdd10.    ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datef = input(put(intnx('month',today(),-1,'end'  ),yymmdd10. ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datex = input(put(intnx('month',today(),-1,'end'  ),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechahi",datehi);
Call symput("fechahf",datehf);
Call symput("fechai", datei);
Call symput("fechaf", datef);
Call symput("fechax", datex);
Call symput("fechae",exec);
RUN;
%put &fechahi; 
%put &fechahf; 
%put &fechai;  
%put &fechaf;  
%put &fechax; 
%put &fechae;


/*======================================= CONEXIONES =====================================================================*/
LIBNAME SFA     ORACLE PATH='REPORITF.WORLD' SCHEMA='SFADMI_ADM' USER='JABURTOM'  PASSWORD='JABU#_1107' /*dbmax_text=7025*/;
LIBNAME R_bopers ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='JABURTOM' PASSWORD='JABU#_1107';
LIBNAME R_get  ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='JABURTOM'  PASSWORD='JABU#_1107';
/*========================================================================================================================*/

PROC SQL; 
   CREATE TABLE OFERTAS AS  
   SELECT t1.OFE_COD_NRO_SOL_K, 
          t1.OFE_COD_PRD_OFE_K,  
          t1.OFE_VLR_RTA_OFE, 
          t1.OFE_VLR_CUP_OFE,  
          t1.OFE_VLR_CUP_RCA, 
          t1.OFE_CAC_NRO_CTT, 
          t1.OFE_COD_IND_OFE,
          t1.OFE_COD_IND_SOL, 
          t1.OFE_VLR_CUP_SOL, 
          t1.OFE_FCH_INI_VIG, 
          t1.OFE_FCH_FIN_VIG, 
          t1.OFE_CAC_COD_CPS, 
          t1.OFE_GLS_DES_CPS, 
          t1.OFE_GLS_DES_OFE 
      FROM SFA.SFADMI_BCO_OFE t1 
       WHERE t1.OFE_COD_PRD_OFE_K = '050001' AND OFE_COD_IND_SOL = 1 
;QUIT; 

PROC SQL; 
   CREATE TABLE OFERTADOS_CURSE AS  
   SELECT t1.*,  
          t2.SOL_COD_EST_SOL, 
            t2.SOL_FCH_CRC_SOL, 
          t2.SOL_FCH_ALT_SOL, 
            t2.SOL_NRO_SUC_ORE AS NRO_SUCURSAL_ORIGEN, 
            t2.SOL_CAC_SUC_ADM AS SUCURSAL_ADMISION, 
            t2.SOL_COD_CLL_ADM, 
            t2.SOL_COD_CLL_SOL 
      FROM WORK.OFERTAS t1 
      INNER JOIN SFA.SFADMI_BCO_SOL t2 ON (t1.OFE_COD_NRO_SOL_K = t2.SOL_COD_NRO_SOL_K) 
;QUIT;

/*=========================================== PRE-APROBADOS ==========================================*/
PROC SQL; 
   CREATE TABLE CURSE_SAV_PA AS  
   SELECT t1.* 
   FROM WORK.OFERTADOS_CURSE t1 
   WHERE t1.SOL_COD_EST_SOL = 11 
;QUIT; 

PROC SQL; 
   CREATE TABLE CURSE_SAV_PA_1 AS  
   SELECT t1.*,  
          t2.PER_COD_IDE_CLI_K AS RUT 
   FROM WORK.CURSE_SAV_PA t1 
   INNER JOIN SFA.SFADMI_BCO_DAT_PER t2 ON (t1.OFE_COD_NRO_SOL_K = t2.PER_COD_NRO_SOL_K) 
;QUIT; 

PROC SQL; 
   CREATE TABLE CURSE_SAV_PA_2 AS  
   SELECT t1.*,  
          t2.PRD_VLR_CUP_SOL , input(compress(put(DATEPART(SOL_FCH_ALT_SOL),yymmdd10.),"-"),best.) AS FECHA_NUM
   FROM WORK.CURSE_SAV_PA_1 t1, SFA.SFADMI_BCO_PRD_SOL t2 
   WHERE (t1.OFE_COD_NRO_SOL_K = t2.PRD_COD_NRO_SOL_K AND t1.OFE_COD_PRD_OFE_K = t2.PRD_COD_TIP_PRD_K) 
;QUIT; 

PROC SQL;
CREATE TABLE CURSE_SAV_&fechax AS 
SELECT *
FROM WORK.CURSE_SAV_PA_2 t1
WHERE FECHA_NUM BETWEEN &fechahi AND &fechahf
;QUIT;

/*===================================================================================================*/
PROC SQL;
   CREATE TABLE TRX_ADM_0 AS 
   SELECT t1.RUT,
          INPUT( t1.RUT,BEST.) AS RUT_REAL,
          t1.OFE_COD_NRO_SOL_K, 
          t1.OFE_VLR_CUP_OFE FORMAT=BEST32., 
          t1.OFE_VLR_CUP_RCA FORMAT=BEST32.,  
          t1.PRD_VLR_CUP_SOL FORMAT=BEST32.,
            t1.SOL_FCH_ALT_SOL,
            t1.NRO_SUCURSAL_ORIGEN, 
          t1.SUCURSAL_ADMISION 
      FROM WORK.CURSE_SAV_&fechax t1;
QUIT;

PROC SQL;
   CREATE TABLE TRX_ADM_1 AS 
   SELECT t1.RUT, 
          t1.RUT_REAL, 
          t1.OFE_COD_NRO_SOL_K, 
          t1.OFE_VLR_CUP_OFE, 
          t1.OFE_VLR_CUP_RCA, 
          t1.PRD_VLR_CUP_SOL,
           t1.SOL_FCH_ALT_SOL,
          t1.NRO_SUCURSAL_ORIGEN, 
          t1.SUCURSAL_ADMISION,  
          t2.PRD_COD_TIP_PRD_K, 
          t2.PRD_CAC_DET_PRD, 
          t2.PRD_GLS_DES_PLN, 
          t2.PRD_GLS_DES_AFI
      FROM WORK.TRX_ADM_0 t1
           LEFT JOIN SFA.SFADMI_BCO_PRD_SOL t2 ON (t1.OFE_COD_NRO_SOL_K = t2.PRD_COD_NRO_SOL_K) AND (t1.PRD_VLR_CUP_SOL 
          = t2.PRD_VLR_CUP_SOL);
QUIT;

PROC SQL;
CREATE TABLE TRX_ADM_2 AS
SELECT t1.*, 
CASE  WHEN t1.PRD_CAC_DET_PRD CONTAINS 'EFECTIVO' THEN 'EFECTIVO'
      WHEN t1.PRD_CAC_DET_PRD CONTAINS 'TRANSFERENCIA EXTERNA MISMO RUT' THEN 'TRANSFERENCIA'
      ELSE 'TRANSFERENCIA' END AS TIPO_DESEMBOLSO

       FROM TRX_ADM_1 as t1
;
QUIT;

PROC SQL;
CREATE TABLE TRX_ADM_3 AS
SELECT t1.*,
(DATEPART(SOL_FCH_ALT_SOL))FORMAT=DDMMYY10. AS FECHA

FROM TRX_ADM_2 as t1
;
QUIT;

PROC SQL;
   CREATE TABLE PUBLICIN.TRX_ADMISION_&fechax AS /**/
   SELECT t1.*,
          t2.TGMSU_NOM_SUC,
            CASE  WHEN t1.SUCURSAL_ADMISION > 100 THEN 'BANCO_R' ELSE 'T_RIPLEY' END AS TIPO_SUC,
            CASE  WHEN t1.TIPO_DESEMBOLSO = 'EFECTIVO' THEN 'CIS' ELSE 'TEF' END AS VIA
      FROM WORK.TRX_ADM_3 t1
           INNER JOIN JABURTOM.BOTGEN_MAE_SUC t2 ON (t1.SUCURSAL_ADMISION = t2.TGMSU_COD_SUC_K)
;
QUIT;

PROC SQL;
   CREATE TABLE TRX_ADM_AUT AS /*DURO*/
   SELECT t1.*,
          t2.TGMSU_NOM_SUC,
            CASE  WHEN t1.SUCURSAL_ADMISION > 100 THEN 'BANCO_R' ELSE 'T_RIPLEY' END AS TIPO_SUC,
            CASE  WHEN t1.TIPO_DESEMBOLSO = 'EFECTIVO' THEN 'CIS' ELSE 'TEF' END AS VIA
      FROM WORK.TRX_ADM_3 t1
           INNER JOIN JABURTOM.BOTGEN_MAE_SUC t2 ON (t1.SUCURSAL_ADMISION = t2.TGMSU_COD_SUC_K)
;
QUIT;


/* 01_TRX_SAV_MPDT ( GETRONICS ) */
/****************************************** GETRONIC SAV *********************************************/

PROC SQL;
        CREATE TABLE TMP_SAV_TRX AS 
        SELECT DISTINCT t1.CENTALTA, 
               t1.CUENTA, 
               t1.CODTIPC,
                t1.TIPOFAC, 
               t1.LINEA, 
               t1.FECFAC, 
               t2.TOTCUOTAS, 
               t2.PORINT AS TASA_CAR,
               t2.PORINTCAR AS TASA_DIFERIDO,
               t2.NUMMESCAR AS DIFERIDO, 
               t1.IMPFAC LABEL="CAPITAL" AS CAPITAL, 
               t2.IMPCUOTA LABEL="CUOTA" AS CUOTA, 
               t2.IMPINTTOTAL LABEL="INTERES" AS INTERES, 
               t2.IMPIMPTOTOT LABEL="IMPUESTO" AS IMPUESTO, 
               t1.SUCURSAL,
               T1.ESTCOMPRA,
               T1.NUMBOLETA,
               T1.NUMREFFAC
           FROM R_get.MPDT205 AS t1, R_get.MPDT206 AS t2
           WHERE (t1.CODENT = t2.CODENT AND t1.CENTALTA = t2.CENTALTA AND t1.CUENTA = t2.CUENTA AND t1.CLAMON = t2.CLAMON AND
                 t1.CODTIPC = t2.CODTIPC AND t1.NUMOPECUO = t2.NUMOPECUO) AND (t1.LINEA = '0052'  
     AND input(compress(t1.FECFAC,"-"),best.) between &fechahi and &fechahf )
     AND T1.ESTCOMPRA IN (1,3,7,6)/*COD VIGENTES */
    AND t1.CODTIPC NOT = '0031' /* PRORROGA LINEA SAV*/ 
    AND t1.TIPOFAC NOT = 1952 /* PRORROGA CUOTA SAV COVID19*/
    AND t1.SUCURSAL NOT = '0991020000' /* SUCURSAL ASOCIADA A PRORROGA */
     ;
QUIT;



PROC SQL;
        CREATE TABLE CONTRATO_RUT AS 
        SELECT DISTINCT A.ID,A.CODENT,A.CUENTA, A.CENTALTA,A.FECALTA,INPUT(B.PEMID_GLS_NRO_DCT_IDE_K,BEST.) AS RUT,A.GRUPOLIQ,A.PRODUCTO,
          C.CONPROD,C.DESCON,C.DESCONRED
        FROM ( SELECT input(t1.IDENTCLI,best.) as ID , 
                                     t1.CUENTA,
                                          T1.CENTALTA,
                                          T1.GRUPOLIQ,
                                          T1.PRODUCTO,
                                          T1.FECALTA,
                                          t1.CODENT,
                                          T1.SUBPRODU,
                                          T1.CONPROD
                                          FROM R_GET.MPDT007 AS t1
                                          ) A 
        INNER JOIN R_BOPERS.BOPERS_MAE_IDE AS B ON  B.PEMID_NRO_INN_IDE =A.ID
        INNER JOIN R_GET.MPDT167 AS C ON A.CODENT=C.CODENT AND A.PRODUCTO=C.PRODUCTO AND A.SUBPRODU=C.SUBPRODU AND A.CONPROD=C.CONPROD ;
     QUIT;

PROC SQL;
     CREATE TABLE TMP_SAV_TRX2 AS
     SELECT T1.*,T2.ID,T2.RUT,T2.PRODUCTO
     FROM TMP_SAV_TRX T1
     LEFT JOIN CONTRATO_RUT T2 ON T1.CUENTA=T2.CUENTA AND T1.CENTALTA=T2.CENTALTA
     ;QUIT;

PROC SQL;
        CREATE TABLE TRX_SAV_&fechax AS 
        SELECT t1.*
           FROM TMP_SAV_TRX2 AS t1;
     QUIT;

     PROC SQL;
     CREATE TABLE WORK.TRX_3 AS
     SELECT t1.CENTALTA, 
               t1.CUENTA, 
               t1.CODTIPC,
              t1.TIPOFAC,
              t1.PRODUCTO, 
               t1.LINEA, 
               t1.FECFAC, 
               t1.TOTCUOTAS,
                  t1.DIFERIDO,
                  t1.TASA_DIFERIDO FORMAT=COMMAX4.3,
                  t1.TASA_CAR FORMAT=COMMAX4.3,
                  ROUND(T1.CAPITAL) FORMAT=BEST32.0 AS CAPITAL1,
                  ROUND(T1.CUOTA) FORMAT=BEST32.0 AS CUOTA1, 
                  ROUND(T1.INTERES) FORMAT=BEST32.0 AS INTERES1, 
                  ROUND(T1.IMPUESTO) FORMAT=BEST32.0 AS IMPUESTO1, 
                  INPUT(SUBSTR(t1.SUCURSAL,1,4),BEST.) AS SUCURSAL1, 
                  INPUT(SUBSTR(t1.SUCURSAL,5,4),BEST.) AS CAJA1,
               t1.ESTCOMPRA, 
               t1.NUMBOLETA, 
               t1.NUMREFFAC, 
               t1.ID, 
               t1.RUT,
                  INPUT (CAT((SUBSTR(FECFAC,1,4)),(SUBSTR(FECFAC,6,2)),(SUBSTR(FECFAC,9,2))),BEST.) AS PERIODO /*FECHA TRX*/ 
     FROM TRX_SAV_&fechax T1
     ;QUIT;

     PROC SQL;
        CREATE TABLE WORK.TRX_4 AS 
        SELECT t1.CENTALTA, 
               t1.CUENTA, 
               t1.CODTIPC,
              t1.TIPOFAC,
              t1.PRODUCTO, 
               t1.LINEA, 
               t1.FECFAC, 
               t1.TOTCUOTAS, 
               t1.DIFERIDO, 
               t1.TASA_DIFERIDO, 
               t1.TASA_CAR, 
               t1.CAPITAL1 AS CAPITAL, 
               t1.CUOTA1 AS CUOTA, 
               t1.INTERES1 AS INTERES, 
               t1.IMPUESTO1 AS IMPUESTO, 
               t1.SUCURSAL1  AS SUCURSAL, 
               t1.CAJA1 AS CAJA, 
               t1.ESTCOMPRA, 
               t1.NUMBOLETA, 
               t1.NUMREFFAC, 
               t1.ID, 
               t1.RUT, 
               t1.PERIODO
           FROM WORK.TRX_3 AS t1;
     QUIT;

          PROC SQL;
             CREATE TABLE WORK.TRX_5 AS 
             SELECT A.*,
             CASE WHEN CODTIPC = '0030' AND CAJA >=200 AND SUCURSAL NOT IN (1,63,900,6) THEN 'TF'
                  WHEN CODTIPC = '0030' AND CAJA < 200 AND SUCURSAL NOT IN (1,63,900,6)THEN 'TV'
                  WHEN CODTIPC = '0035' AND SUCURSAL = 0 AND CAJA = 1 THEN 'TEF' /*CLIENTE VA A LA TIENDA Y LE TRASFIERE*/
                     WHEN CODTIPC = '0035' AND SUCURSAL = 1 AND CAJA = 1 THEN 'HOME_B' /*HOME BANKING*/
                     WHEN CODTIPC = '0035' AND SUCURSAL = 300 AND CAJA = 1 THEN 'HOME_B' /*HOME BANKING*/
                     WHEN CODTIPC = '0035' AND SUCURSAL = 400 AND CAJA = 1 THEN 'APP' /*HOME BANKING*/
                     WHEN CODTIPC = '0036' AND SUCURSAL = 100 AND CAJA = 1 THEN 'SAV_CENTER' /*SAV_CENTER*/
                     WHEN CODTIPC = '0035' AND SUCURSAL = 200 AND CAJA = 1 AND TIPOFAC = 1652 THEN 'MOVIL' /*MOVIL TDA*/
                 WHEN SUCURSAL IN (6,900) THEN 'TLMK' /*CCR TRANFERENCIA*/
                  WHEN SUCURSAL = 63 THEN 'BCO' END  AS VIA          

          FROM WORK.TRX_4 AS A
          ;
          QUIT;

     PROC SQL;
        CREATE TABLE PUBLICIN.TRX_SAV_&fechax AS 
        SELECT t1.*
           FROM TRX_5 AS t1;
     QUIT;

     PROC SQL;
     CREATE TABLE TRX_SAV AS
     SELECT t1.*,
	 input(cat((SUBSTR(t1.FECFAC,1,4)),(SUBSTR(t1.FECFAC,6,2)),(SUBSTR(t1.FECFAC,9,2))) ,BEST10.) AS FECHA1

     FROM publicin.TRX_SAV_&fechax as t1
     ;
     QUIT;

     PROC SQL;
     CREATE TABLE TRX_SAV1 AS
     SELECT t1.*,
     (MDY(INPUT(SUBSTR(PUT(t1.FECHA1,BEST8.),5,2),BEST4.),
                       INPUT(SUBSTR(PUT(t1.FECHA1,BEST8.),7,2),BEST4.),
                       INPUT(SUBSTR(PUT(t1.FECHA1,BEST8.),1,4),BEST4.)) ) FORMAT=DDMMYY10. AS FECHA

     FROM TRX_SAV as t1
     ;
     QUIT;

     PROC SQL;
        CREATE TABLE TRX_SAV2 AS 
        SELECT t1.CENTALTA, 
               t1.CUENTA, 
               t1.CODTIPC,
              t1.TIPOFAC,
              t1.PRODUCTO, 
               t1.LINEA, 
               t1.FECFAC, 
               t1.TOTCUOTAS, 
               t1.DIFERIDO, 
               t1.TASA_DIFERIDO, 
               t1.TASA_CAR, 
               t1.CAPITAL, 
               t1.CUOTA, 
               t1.INTERES, 
               t1.IMPUESTO, 
               t1.SUCURSAL, 
               t1.CAJA, 
               t1.ESTCOMPRA, 
               t1.NUMBOLETA, 
               t1.NUMREFFAC, 
               t1.ID, 
               t1.RUT, 
               t1.PERIODO, 
               t1.VIA, 
               t1.FECHA
           FROM WORK.TRX_SAV1 t1;
     QUIT;

     PROC SQL;
        CREATE TABLE PUBLICIN.TRX_SAV_&fechax AS 
        SELECT t1.*
           FROM TRX_SAV2 AS t1;
     QUIT;

     PROC SQL;
        CREATE TABLE CRUCE_SAV AS 
        SELECT DISTINCT t1.*,
               t2.PRD_VLR_CUP_SOL,
               t2.OFE_VLR_CUP_OFE,
              t2.OFE_VLR_CUP_RCA, 
               t2.SOL_FCH_ALT_SOL, 
               t2.SUCURSAL_ADMISION, 
               t2.TIPO_DESEMBOLSO, 
               t2.TIPO_SUC, 
               t2.VIA AS VIA1
           FROM publicin.TRX_SAV_&fechax t1
                LEFT JOIN TRX_ADM_AUT t2 ON (t1.FECHA = t2.FECHA) AND (t1.RUT = t2.RUT_REAL);
     QUIT;

PROC SQL;
        CREATE TABLE CRUCE_SAV1 AS 
        SELECT t1.*,
               t1.VIA AS VIA_FINAL
           FROM WORK.CRUCE_SAV t1;
     QUIT;

PROC SQL;
     UPDATE CRUCE_SAV1
     SET VIA_FINAL = 'CIS'
     WHERE VIA1 = 'CIS'
     AND VIA_FINAL = 'TF'
     ;
     UPDATE CRUCE_SAV1
     SET VIA_FINAL = 'CIS'
     WHERE VIA1 = 'CIS'
     AND VIA_FINAL = 'BCO'
     ;
     UPDATE CRUCE_SAV1
     SET VIA_FINAL = 'CIS'
     WHERE VIA1 = 'CIS'
     AND VIA_FINAL = 'TLMK'
     ;
     QUIT;

     PROC SQL;
     UPDATE CRUCE_SAV1
     SET VIA_FINAL = 'TEF'
     WHERE VIA1 = 'TEF'
     AND VIA_FINAL = 'TF'
     ;
     UPDATE CRUCE_SAV1
     SET VIA_FINAL = 'TEF'
     WHERE VIA1 = 'TEF'
     AND VIA_FINAL = 'TF'
     ;
     QUIT;

     PROC SQL;
     UPDATE CRUCE_SAV1
     SET VIA_FINAL = 'TEF'
     WHERE VIA1 = 'TEF'
     AND VIA_FINAL = 'HOME_B'
     AND VIA = 'HOME_B'
     ;
     QUIT;

PROC SQL;
        CREATE TABLE PUBLICIN.TRX_SAV_&fechax AS 
        SELECT t1.*
           FROM WORK.CRUCE_SAV1 t1;
     QUIT;

PROC SQL;
     UPDATE publicin.TRX_SAV_&fechax
     SET VIA_FINAL = 'BCO'
     WHERE SUCURSAL IN (0,63) 
     AND SUCURSAL_ADMISION > 100
     AND VIA_FINAL IN ('CIS','TEF')
     ;
     QUIT;

PROC SQL;
     UPDATE publicin.TRX_SAV_&fechax
     SET VIA_FINAL = 'BCO'
     WHERE SUCURSAL = 63 
     AND VIA_FINAL = 'CIS'
     ;
     QUIT;
          
PROC SQL;
   CREATE TABLE SAV_APROBADO_&fechax AS 
   SELECT t1.RUT_REAL, 
          t1.SAV_APROBADO_FINAL, 
          t1.MONTO_PARA_CANON AS OFERTA_SAV_APROBADO,
          'FUSION' AS MARCA_OFERTA,
          t1.CUENTA,
          t1.CENTALTA 
      FROM JABURTOM.SAV_CAR_&fechax t1
      WHERE t1.SAV_APROBADO_FINAL = 1
;
QUIT;

PROC SQL;
   CREATE TABLE SAV_APROBADO_INCREM_&fechax AS 
   SELECT t1.RUT_REAL, 
          t1.SAV_APROBADO_FINAL, 
          t1.MONTO_PARA_CANON AS OFERTA_SAV_APROBADO,
          'INCREMENTALES' AS MARCA_OFERTA,
          t1.CUENTA,
          t1.CENTALTA 
      FROM JABURTOM.SAV_CAR_INCREM_&fechax t1
      WHERE t1.SAV_APROBADO_FINAL = 1
;
QUIT;

PROC SQL;
CREATE TABLE SAV_APROBADO_FINAL_&fechax AS
SELECT * FROM SAV_APROBADO_&fechax
OUTER UNION CORR
SELECT * FROM SAV_APROBADO_INCREM_&fechax
;
QUIT;

PROC SQL;
CREATE TABLE TRX_SAV_1_&fechax AS 
SELECT t1.*,
        t2.OFERTA_SAV_APROBADO, 
        t3.SAVT_OFERTA AS OFERTA_SAV_TELEMAR
        FROM JABURTOM.TRX_SAV_&fechax t1
        LEFT JOIN SAV_APROBADO_FINAL_&fechax t2 ON (t1.CUENTA = t2.CUENTA) AND (t1.RUT = t2.RUT_REAL) AND (t1.CENTALTA = t2.CENTALTA)
        LEFT JOIN PUBLICRI.SAV_TELEMARKETING_202001_F t3 ON  (t1.RUT = t3.RUT)
     ;QUIT;


     PROC SQL;
     UPDATE TRX_SAV_1_&fechax
     SET VIA_FINAL = 'CIS'
     WHERE VIA_FINAL = 'TF'
     AND CAPITAL > 1120000
     ;
     QUIT;

     PROC SQL;
        CREATE TABLE PUBLICIN.TRX_SAV_&fechax AS 
        SELECT t1.*
           FROM WORK.TRX_SAV_1_&fechax t1;
     QUIT;

     PROC SQL;
     UPDATE publicin.TRX_SAV_&fechax
     SET VIA_FINAL = 'BCO'
     WHERE VIA_FINAL is missing
     AND SUCURSAL = 1 
     AND CAJA = 1
     ;
     QUIT;


/************************************************ HOME BANKING ***************************************************/

DATA _null_;
datehi     = compress(input(put(intnx('month',today(),-1,'begin' ),yymmdd10.     ),$20.),"-",c); /*cambiar 0 a -1 para ver cierre mes anterior*/
datehf     = compress(input(put(intnx('month',today(),-1,'end'    ),yymmdd10.      ),$20.),"-",c); /*cambiar 0 a -1 para ver cierre mes anterior*/
datei      = input(put(intnx('month',today(),-1,'begin' ),date9.  ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datef = input(put(intnx('month',today(),-1,'end'  ),date9. ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datex = input(put(intnx('month',today(),-1,'end'  ),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechahi",datehi);
Call symput("fechahf",datehf);
Call symput("fechai", datei);
Call symput("fechaf", datef);
Call symput("fechax", datex);
Call symput("fechae",exec);
RUN;
%put &fechahi; 
%put &fechahf; 
%put &fechai;  
%put &fechaf;  
%put &fechax; 
%put &fechae; 

LIBNAME HB ORACLE SCHEMA='hbpri_adm' USER='RIPLEYC' PASSWORD='ri99pley'
PATH="  (DESCRIPTION = 
    (ADDRESS_LIST = 
      (ADDRESS = 
        (PROTOCOL = TCP)
        (Host = 192.168.10.31)
        (Port = 1521)
      )
    )
    (CONNECT_DATA = 
      (SID = ripleyc)
    )
  )
";
     
PROC SQL;
   CREATE TABLE SUPER_AVANCE_INTERNET AS 
   SELECT t1.*,
        (PUT(DATEPART( t1.HDVOU_FCH_CPR),DDMMYY10.)) AS FECHA,
          input(compress(put(DATEPART(HDVOU_FCH_CPR),yymmdd10.),"-"),best.) AS FECHA_NUM,
          CASE WHEN t1.HDVOU_COC_TOP_IDE = 'SUPER_CASH_ADVANCE' THEN 'SAV' END AS PRODUCTO,
          CASE WHEN t1.HDVOU_COC_CNL NOT LIKE ('85') THEN 'HB'
               WHEN t1.HDVOU_COC_CNL = '85' THEN 'APP' END AS CANAL 
      FROM HB.HBPRI_HIS_DET_VOU t1
      WHERE t1.HDVOU_COC_CNL CONTAINS ('homebanking')
      AND t1.HDVOU_COC_TOP_IDE = 'SUPER_CASH_ADVANCE'
       AND t1.HDVOU_FCH_CPR BETWEEN "&fechai:00:00:00"dt AND "&fechaf:00:00:00"dt
;
QUIT;
     
PROC SQL;
   CREATE TABLE SUPER_AVANCE_INTERNET_APP AS 
   SELECT t1.*,
        (PUT(DATEPART( t1.HDVOU_FCH_CPR),DDMMYY10.)) AS FECHA,
          input(compress(put(DATEPART(HDVOU_FCH_CPR),yymmdd10.),"-"),best.) AS FECHA_NUM,
          CASE WHEN t1.HDVOU_COC_TOP_IDE = 'SUPER_CASH_ADVANCE' THEN 'SAV' END AS PRODUCTO,
          CASE WHEN t1.HDVOU_COC_CNL NOT LIKE ('85') THEN 'HB'
               WHEN t1.HDVOU_COC_CNL = '85' THEN 'APP' END AS CANAL 
      FROM HB.HBPRI_HIS_DET_VOU t1
      WHERE t1.HDVOU_COC_CNL CONTAINS ('85')
      AND t1.HDVOU_COC_TOP_IDE = 'SUPER_CASH_ADVANCE'
       AND t1.HDVOU_FCH_CPR BETWEEN "&fechai:00:00:00"dt AND "&fechaf:00:00:00"dt
;
QUIT;

PROC SQL;
CREATE TABLE SUPER_AVANCE_INTERNET_APP_F AS

SELECT * FROM SUPER_AVANCE_INTERNET
OUTER UNION CORR
SELECT * FROM SUPER_AVANCE_INTERNET_APP
;
QUIT; 

PROC SQL;
CREATE TABLE SUPER_AVANCE_INTERNET_1 AS
SELECT *,
INPUT((SUBSTR(HDVOU_NOM_NOM_USR,1,(LENGTH(HDVOU_NOM_NOM_USR)-1))),BEST.) AS RUT

FROM SUPER_AVANCE_INTERNET_APP_F 
;
QUIT;

PROC SQL;
   CREATE TABLE PUBLICIN.TRX_SAV_HB_&fechax AS 
   SELECT t1.RUT, 
          t1.FECHA, 
          t1.FECHA_NUM,
            t1.HDVOU_FCH_CRC_AUD,
            put(TIMEPART(t1.HDVOU_FCH_CRC_AUD),time4.) AS HORA,
/*          T(SUBSTR(PUT(HDVOU_FCH_CRC_AUD,DATETIME16.)),9)) AS HORA,*/
          t1.PRODUCTO, 
          t1.CANAL, 
          t1.HDVOU_MNT_MNT_PAG, &fechae as FEC_EX,
CASE WHEN HDVOU_MNT_MNT_PAG BETWEEN 200000 AND 500000 THEN 'A.200 - 500'
     WHEN HDVOU_MNT_MNT_PAG BETWEEN 500001 AND 999999 THEN 'B.501 - 999'
     WHEN HDVOU_MNT_MNT_PAG = 1000000 THEN 'C.1000'
     WHEN HDVOU_MNT_MNT_PAG BETWEEN 1000001 AND 2000000 THEN 'D.1001 - 2000'
     WHEN HDVOU_MNT_MNT_PAG BETWEEN 2000001 AND 3000000 THEN 'E.2001 - 3000'
     WHEN HDVOU_MNT_MNT_PAG BETWEEN 3000001 AND 4000000 THEN 'F.3001 - 4000'
     WHEN HDVOU_MNT_MNT_PAG BETWEEN 4000001 AND 5000000 THEN 'G.4001 - 5000'
     WHEN HDVOU_MNT_MNT_PAG BETWEEN 5000001 AND 6000000 THEN 'H.5001 - 6000'
     WHEN HDVOU_MNT_MNT_PAG > 6000000 THEN 'I.>6000' END  AS TRAMO_GIRO 
      FROM WORK.SUPER_AVANCE_INTERNET_1 t1
WHERE FECHA_NUM BETWEEN &fechahi AND &fechahf
;
QUIT;

PROC SQL;
   CREATE TABLE OFERTAS AS 
   SELECT t1.*,
          t2.ACTIVIDAD_TR, 
          t2.RANGO_PROB_INICIAL, 
          t2.SAV_APROBADO_FINAL, 
          t2.MONTO_PARA_CANON,
     CASE WHEN t2.MONTO_PARA_CANON BETWEEN 200000 AND 500000 THEN '1.200 - 500'
               WHEN t2.MONTO_PARA_CANON BETWEEN 500001 AND 999999 THEN '2.501 - 999'
                   WHEN t2.MONTO_PARA_CANON = 1000000 THEN '3.1000'
               WHEN t2.MONTO_PARA_CANON BETWEEN 1000001 AND 2000000 THEN '4.1001 - 2000'
               WHEN t2.MONTO_PARA_CANON BETWEEN 2000001 AND 3000000 THEN '5.2001 - 3000'
               WHEN t2.MONTO_PARA_CANON BETWEEN 3000001 AND 4000000 THEN '6.3001 - 4000'
               WHEN t2.MONTO_PARA_CANON BETWEEN 4000001 AND 5000000 THEN '7.4001 - 5000'
               WHEN t2.MONTO_PARA_CANON BETWEEN 5000001 AND 6000000 THEN '8.5001 - 6000' END  AS TRAMO_OFERTA_APROBADO
      FROM JABURTOM.TRX_SAV_HB_&fechax t1
           LEFT JOIN JABURTOM.SAV_202001_FIN t2 ON (t1.RUT = t2.RUT_REAL)
;
QUIT;

PROC SQL;
   CREATE TABLE PUBLICIN.TRX_SAV_HB_&fechax AS
   SELECT *
   FROM OFERTAS
   ;
   QUIT;


PROC SQL;
DROP TABLE SAV_TRXCC
,OFERTAS
,OFERTADOS_CURSE
,CURSE_SAV_PA
,CURSE_SAV_PA_1
,CURSE_SAV_PA_2
,CURSE_SAV_&fechax
,TRX_ADM_0
,TRX_ADM_1
,TRX_ADM_2
,TRX_ADM_3
,TRX_ADM_AUT
,TMP_SAV_TRX
,CONTRATO_RUT
,TMP_SAV_TRX2
,TRX_SAV_&fechax
,TRX_3
,TRX_4
,TRX_5
,TRX_SAV
,TRX_SAV1
,TRX_SAV2
,CRUCE_SAV
,CRUCE_SAV1
,SAV_APROBADO_&fechax
,SAV_APROBADO_INCREM_&fechax
,SAV_APROBADO_FINAL_&fechax
,TRX_SAV_1_&fechax
,SUPER_AVANCE_INTERNET
,SUPER_AVANCE_INTERNET_APP
,SUPER_AVANCE_INTERNET_APP_F
,SUPER_AVANCE_INTERNET_1
,OFERTAS
;
QUIT;


/**/
/*proc printto; */
/*run;*/
/**/

