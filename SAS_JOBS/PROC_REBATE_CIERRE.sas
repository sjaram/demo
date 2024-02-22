
/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROC_REBATE_CIERRE	 		================================*/
/* CONTROL DE VERSIONES
/* 2022-04-05 -- Esteban P. -- Se actualizan los correos: Se elimina a MARIA_PAZ_GATICA y SEBASTIAN_BARRERA.
/* 2020-07-24 ---- Se agrega control de tiempo y envío de Correo
/* 2020-07-24 ---- Actualiza contraseña de usuario
/* 2020-05-13 ---- Original 
*/
/*==================================================================================================*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

DATA _null_;
datei 	= input(put(intnx('month',today(),-1,'begin' ),date9.	),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datef	= input(put(intnx('month',today(),-1,'end'	),date9. ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datex	= input(put(intnx('month',today(),-1,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/

Call symput("fechai", datei);
Call symput("fechaf", datef);
Call symput("fechax", datex);

RUN;
%put &fechai;  
%put &fechaf;  
%put &fechax; 
%let cod_promo1=132966;

LIBNAME EXCRT1 ORACLE PATH='EXCRT1' SCHEMA='TEST_BACK' USER='AMARINAOC' PASSWORD='AMA#0305'; 
LIBNAME credito ODBC  DATASRC=creditoprd  SCHEMA=GEDCRE_CREDITO  USER=CONSULTA_CREDITO  PASSWORD='CONSULTA_CREDITO';

PROC SQL;
CREATE TABLE CUPON_retencion AS 
SELECT A.*,
cat(BXMVC_COD_SUC_K,' ',BXMVC_FCH_TRN_K,' ',BXMVC_NRO_CAJ_K,' ',BXMVC_NRO_TRN_K) as BOLETA,
B.COD_ARTICULO,B.PRECIO_ARTICULO
FROM EXCRT1.BOBDTX_MOV_VTA_CRZ AS A
           LEFT JOIN EXCRT1.TRX_ARTICULOS B ON
A.BXMVC_FCH_TRN_K=B.FECHA_TRX AND 
A.BXMVC_COD_SUC_K=B.SUCURSAL AND
A.BXMVC_NRO_CAJ_K=B.NRO_CAJA AND
A.BXMVC_NRO_TRN_K=B.NRO_TRANSACCION AND 
A.BXMVC_NRO_ITM_K=B.NRO_ITEM
WHERE A.BXMVC_COD_PRM_K=&cod_promo1/*restriccion cantidad de codigos*/
AND   A.BXMVC_FCH_TRN_K BETWEEN "&fechai:00:00:00"dt AND "&fechaf:23:59:59"dt
AND BXMVC_MNT_DST>0
ORDER BY 1
;QUIT;

PROC SQL;
   CREATE TABLE WORK.CUPON_CAPTA_V2_OK AS 
   SELECT t1.BXMVC_COD_PRM_K AS PROMO, 
          t1.BXMVC_FCH_TRN_K AS FECHA, 
          t1.BXMVC_RUT_DST AS RUT, 
          t1.BXMVC_COD_SUC_K AS SUCURSAL, 
          t1.BXMVC_NRO_CAJ_K AS CAJA, 
          t1.BXMVC_NRO_TRN_K AS NRO_TRN, 
          t1.BOLETA, 
          t1.BXMVC_MNT_DST AS DESCUENTO, 
          t1.BXMVC_FCH_TRN_K, 
          t1.BXMVC_COD_SUC_K, 
          t1.BXMVC_NRO_CAJ_K, 
          t1.BXMVC_NRO_TRN_K, 
          t1.BXMVC_NRO_ITM_K, 
          t1.BXMVC_TIP_PRM_K, 
          t1.BXMVC_COD_PRM_K, 
          t1.BXMVC_COD_CUP_K, 
          t1.BXMVC_MNT_DST, 
          t1.BXMVC_MNT_LAN, 
          t1.BXMVC_MNT_PES, 
          t1.BXMVC_RUT_DST, 
          t1.COD_ARTICULO, 
            INPUT(t1.COD_ARTICULO,BEST32.) as SKU,
          t1.PRECIO_ARTICULO
      FROM CUPON_RETENCION t1
;QUIT;

/*INCORPORACION DEPARTAMENTOS*/
PROC SQL;
   CREATE TABLE WORK.DEPTOS_DIV AS 
   SELECT t1.PROMO, 
          t1.FECHA, 
          t1.RUT, 
          t1.SUCURSAL, 
          t1.CAJA, 
          t1.NRO_TRN, 
          t1.BOLETA, 
          t1.DESCUENTO, 
          t1.BXMVC_FCH_TRN_K, 
          t1.BXMVC_COD_SUC_K, 
          t1.BXMVC_NRO_CAJ_K, 
          t1.BXMVC_NRO_TRN_K, 
          t1.BXMVC_NRO_ITM_K, 
          t1.BXMVC_TIP_PRM_K, 
          t1.BXMVC_COD_PRM_K, 
          t1.BXMVC_COD_CUP_K, 
          t1.BXMVC_MNT_DST, 
          t1.BXMVC_MNT_LAN, 
          t1.BXMVC_MNT_PES, 
          t1.BXMVC_RUT_DST, 
          t1.COD_ARTICULO, 
          t1.SKU, 
          t1.PRECIO_ARTICULO, 
          t2.DDMAR_COD_SKU_ART, 
          t2.DDMAR_COD_DPT
      FROM WORK.CUPON_CAPTA_V2_OK t1
           LEFT JOIN CREDITO.DCRM_DIM_MAE_ART_RTL t2 ON (t1.SKU = t2.DDMAR_COD_SKU_ART);
QUIT;

PROC SQL;
CREATE TABLE CON_BOLETA AS
SELECT *,
CATS(BXMVC_COD_SUC_K , '-' , BXMVC_FCH_TRN_K , '-' , BXMVC_NRO_CAJ_K , '-' ,BXMVC_NRO_TRN_K) AS BOLETA2
FROM DEPTOS_DIV
order by 2
;QUIT;

PROC SQL;
CREATE TABLE WORK.RESUMEN1_&fechax AS 
SELECT T1.PROMO, (COUNT(DISTINCT(T1.BOLETA2))) AS CUPONES, 
(SUM(T1.BXMVC_MNT_DST)) FORMAT=BEST32. AS DESCUENTO
FROM CON_BOLETA T1
WHERE DATEPART(FECHA) BETWEEN "&fechai"d AND "&fechaf"d
GROUP BY T1.PROMO;
QUIT;


/*[2.2] Se debe PRORRATEAR MONTO DE DEPTOS EN BLANCO 
(Pegar en hoja 'Hoja oculta para prorrateo')*/
PROC SQL;
CREATE TABLE PUBLICIN.REBATE_&fechax AS 
SELECT t1.DDMAR_COD_DPT, 
(SUM(t1.BXMVC_MNT_DST)) FORMAT=BEST32. AS DESCUENTO
FROM CON_BOLETA t1
WHERE DATEPART(FECHA) BETWEEN "&fechai"d AND "&fechaf"d
GROUP BY t1.DDMAR_COD_DPT;
QUIT;


/*ELIMINAR TABLAS DE PASO*/
PROC SQL;
DROP TABLE
	WORK.CON_BOLETA,
	WORK.CUPON_CAPTA_V2_OK,
	WORK.CUPON_RETENCION,
	WORK.DEPTOS_DIV,
	WORK.RESUMEN1_&fechax
;
QUIT;
     



/*	OBTENER EL PRIMER REGISTRO DE LA TABLA GENERADA PARA INCORPORAR AL EMIAL*/
PROC SQL;
CREATE TABLE COUNT_DE_TABLA_TMP AS
	SELECT COUNT(DESCUENTO) AS CANTIDAD_DE_REGISTROS
		from PUBLICIN.REBATE_&fechax
;QUIT;

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */


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
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'NICOLE_LAGOS';

SELECT EMAIL into :DEST_2 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_3 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'VALENTIN_TRONCOSO';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;

FILENAME output EMAIL
SUBJECT="MAIL_AUTOM: PROCESO REBATE %sysfunc(date(),yymmdd10.)" 
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_3")
CC = ("&DEST_2")
CT= "text/html"  ;
ODS HTML 
BODY=output 
style=sasweb; 
ods escapechar='~'; 

title1  "Estimados:";
title2 font='helvetica/italic' height=10pt 
		" Proceso REBATE, ejecutado con fecha: &fechaeDVN 
		~n 
		~n
		~n 
		Tabla en SAS: PUBLICIN.REBATE_&fechax
		~n 
		~n
		~n 
		~n
		Atte.
		~n
		Equipo Datos y Procesos BI
		~n
";
PROC REPORT DATA=COUNT_DE_TABLA_TMP NOWD
STYLE(REPORT)=[PREHTML="<hr>"] /*Inserts a rule between title & body*/;
RUN;
ODS HTML CLOSE;
