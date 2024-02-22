* Inicio del código EG generado (no editar esta línea);
*
*  Procedimiento almacenado registrado por
*  Enterprise Guide Stored Process Manager V7.1
*
*  ====================================================================
*  Nombre del proceso almacenado: TD_ITF
*  ====================================================================
*;


*ProcessBody;

* Start before STPBEGIN code [226334a4d28540f280fa2c6c1e0a2284];/* Insertar código personalizado ejecutado delante de la macro STPBEGIN */
%global _ODSDEST;
%let _ODSDEST=none;
* End before STPBEGIN code [226334a4d28540f280fa2c6c1e0a2284];

%STPBEGIN;

* Fin del código EG generado (no editar esta línea);


/*========================================================================================================================*/
/*=== MACRO FECHAS =====================================================================================================================*/
/*========================================================================================================================*/
DATA _null_;
datehi	= compress(input(put(intnx('month',today(),-1,'begin' ),yymmdd10.	),$20.),"-",c); /*cambiar 0 a -1 para ver cierre mes anterior*/
datehf	= compress(input(put(intnx('month',today(),-1,'end'	),yymmdd10. 	),$20.),"-",c); /*cambiar 0 a -1 para ver cierre mes anterior*/
datei 	= input(put(intnx('month',today(),-1,'begin' ),yymmdd10.	),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datef	= input(put(intnx('month',today(),-1,'end'	),yymmdd10. ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datex	= input(put(intnx('month',today(),-1,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
exec	= compress(input(put(today(),yymmdd10.),$10.),"-",c);
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

/*========================================================================================================================*/
/*=== CONEXIONES =====================================================================================================================*/
/*========================================================================================================================*/
LIBNAME MPDT  		ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' 	USER='PMANRIQUEZD' PASSWORD='PMAN#_1407';
LIBNAME R_BOPERS 	ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' 	USER='PMANRIQUEZD' PASSWORD='PMAN#_1407';

/*========================================================================================================================*/
/*=== EXTRACCION =====================================================================================================================*/
/*========================================================================================================================*/

/*=== SIN CUOTAS =====================================================================================================================*/

PROC SQL;
CREATE TABLE PRIM_ULT_COM_SIN_CUOTAS AS
SELECT A.PAN, A.CODENT,A.CENTALTA,A.CUENTA,
INPUT(PEMID_GLS_NRO_DCT_IDE_K,BEST.) AS RUT,
(INPUT(CAT(SIGNO,IMPFAC),BEST32.)) AS CAPITAL,
0 AS PIE,
0 AS CUOTAS,
(INPUT(COMPRESS(FECFAC,"-"),YYMMDD10.)) FORMAT=YYMMDD10. AS FECHA,
INPUT(NUMBOLETA,BEST.) AS DCTO,
INPUT(CODCOM,BEST.) AS COMERCIO,
INPUT(SUBSTR(LEFT(SUCURSAL),1,4),BEST.) AS SUCURSAL,
INPUT(SUBSTR(LEFT(SUCURSAL),5,4),BEST.) AS CAJA,
0 AS DIFERIDO,
0 AS MGFIN,
0 AS TASA,
0 AS TASA_DIF
FROM MPDT.MPDT012 AS  A
INNER JOIN MPDT.MPDT044 D ON (A.TIPOFAC = D.TIPOFAC) AND (A.INDNORCOR=D.INDNORCOR)
LEFT JOIN MPDT.MPDT007 B ON (A.CODENT=B.CODENT
                                               AND A.CENTALTA=B.CENTALTA
                                               AND A.CUENTA=B.CUENTA)
LEFT JOIN R_BOPERS.BOPERS_MAE_IDE C ON (INPUT(B.IDENTCLI,BEST.) = C.PEMID_NRO_INN_IDE)
WHERE A.LINEA="0050"    AND CODCOM="000000000000001" AND INDMOVANU = 0
AND A.TIPOFAC IN (3050,2050,3010)
AND INPUT(COMPRESS(FECFAC,"-"),BEST.) BETWEEN &fechahi AND &fechahf 
;QUIT;



/*=== CON CUOTAS =====================================================================================================================*/

PROC SQL;
CREATE TABLE PRIM_ULT_CON_CUOTAS AS
SELECT A.PAN,A.CODENT,A.CENTALTA,A.CUENTA,
INPUT(PEMID_GLS_NRO_DCT_IDE_K,BEST.) AS RUT,
IMPFAC AS CAPITAL,
ENTRADA AS PIE,
TOTCUOTAS AS CUOTAS,
(INPUT(COMPRESS(FECFAC,"-"),YYMMDD10.)) FORMAT=DATE9. AS FECHA,
INPUT(NUMBOLETA,BEST.) AS DCTO,
INPUT(CODCOM,BEST.) AS COMERCIO,
INPUT(SUBSTR(LEFT(SUCURSAL),1,4),BEST.) AS SUCURSAL,
INPUT(SUBSTR(LEFT(SUCURSAL),5,4),BEST.) AS CAJA,
NUMMESCAR AS DIFERIDO,
IMPINTTOTAL AS MGFIN,
PORINT AS TASA,
PORINTCAR AS TASA_DIF
FROM MPDT.MPDT205 AS  A
INNER JOIN MPDT.MPDT206 D
      ON(A.CODENT=D.CODENT AND A.CENTALTA=D.CENTALTA AND A.CUENTA=D.CUENTA AND
            A.CODTIPC = D.CODTIPC AND A.NUMOPECUO =D.NUMOPECUO) 
LEFT JOIN MPDT.MPDT007 B ON (A.CODENT=B.CODENT
                                               AND A.CENTALTA=B.CENTALTA
                                               AND A.CUENTA=B.CUENTA)
LEFT JOIN R_BOPERS.BOPERS_MAE_IDE C ON (INPUT(B.IDENTCLI,BEST.) = C.PEMID_NRO_INN_IDE)
WHERE LINEA="0050"      AND CODCOM="000000000000001" 
AND INPUT(COMPRESS(FECFAC,"-"),BEST.) BETWEEN &fechahi AND &fechahf 
;QUIT;


/*========================================================================================================================*/
/*=== HARD DATA =====================================================================================================================*/
/*========================================================================================================================*/

PROC SQL;
CREATE TABLE TDA_TR_ITF AS
SELECT * FROM PRIM_ULT_COM_SIN_CUOTAS
UNION
SELECT * FROM PRIM_ULT_CON_CUOTAS
;QUIT;

PROC SQL;
CREATE TABLE PUBLICIN.TDA_ITF_&fechax AS
SELECT &fechae AS FEC_EX , * 
FROM TDA_TR_ITF;
QUIT;

* Inicio del código EG generado (no editar esta línea);
;*';*";*/;quit;
%STPEND;

* Fin del código EG generado (no editar esta línea);

