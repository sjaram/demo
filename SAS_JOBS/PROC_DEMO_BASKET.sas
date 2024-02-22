/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROC_DEMO_BASKET			================================*/
/* CONTROL DE VERSIONES
/* 2023-06-13 -- v11 -- Esteban P.	-- Se actualizan credenciales para conexión gedcre.
/* 2023-01-19 -- v10 -- Esteban P	-- Se elimina put de credenciales conexión a BOPERS.
/* 2022-12-07 -- v09 -- David V. 	-- Se actualiza nombre tabla para aws, con prefijo ctbl.
/* 2022-10-20 -- v08 -- AMARINAO 	-- Se cambia el GSE a GSE CORP
/* 2022-08-19 -- v07 -- SERGIO J. 	-- Se agrega código de exportación a aws
/* 2022-05-09 -- v03 -- David V.	-- Ajustes a ruts mínimo y máximo.
/* 2021-06-02 -- v02 -- Sergio J. 	-- Nueva Versión Automática Equipo Datos y Procesos BI
					 -- Llamado de variables user y password
/* 2020-08-11 ---- Actualizado uruario de BD + limpiar comentarios + controles fecha/hora + noprint
*/
/*==================================================================================================*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*	=========================================================================	*/
/*		INICIO PROCESO  BASKET                                      			*/
/*	=========================================================================	*/

PROC SQL OUTOBS=1 NOPRINT;
SELECT put(TODAY(),ddmmyy10.) as FECHA_INICIAL,
YEAR(TODAY())*10000+(MONTH(TODAY())*100)+DAY(TODAY()) AS FPROCESO_INI, /*FORMATO NUM */
put(TODAY(),Time10.) as HORA_INI,
input(put(intnx('month',today(),-1,'end'),yymmn6.),$10.) as PERIODO
INTO
:FECHA_INICIAL, 
:FPROCESO_INI, 
:HORA_INI,
:periodo
from sashelp.vmember
;quit;

%put===========================================================================================;
%put[01]  &FECHA_INICIAL &HORA_INI;
%put===========================================================================================;

LIBNAME bopers ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME MPDT  ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME GENERAL ORACLE PATH='REPORITF.WORLD' SCHEMA='BOTGEN_ADM' USER='AMARINAOC' PASSWORD='amarinaoc2017';

PROC SQL;
CREATE TABLE RESULT.RUTS_CON_CONTRATO AS 
SELECT DISTINCT PEMID_NRO_INN_IDE AS IDE_CTTO,
1 AS T_CTTO
FROM BOPERS.BOPERS_MAE_IDE A
INNER JOIN MPDT.MPDT007 B ON (INPUT((b.IDENTCLI),BEST32.))=a.PEMID_NRO_INN_IDE AND FECBAJA = '0001-01-01';
QUIT;

PROC SQL;
CREATE TABLE RESULT.RENTA_ACT_LAB AS 
SELECT PEMID_NRO_INN_IDE_K AS IDE, 
TGMDO_GLS_DOM AS TIPO_ACTIVIDAD,
SUM(PEMIE_MNT_RTA) AS RENTA, MAX(PEMIE_MNT_RTA) AS MAX_RENTA, MAX(PEMIE_FCH_ING_REG) AS MAX_FEC_REG
FROM BOPERS.BOPERS_MAE_ING_ECO C
INNER JOIN GENERAL.BOTGEN_MOV_DOM E ON C.PEMIE_COD_TIP_ACV = E.TGMDO_COD_DOM_K 
WHERE C.PEMIE_COD_NEG_ING_ECO=1 
AND PEMIE_COD_EST_ING<>3 /*DADO DE BAJA*/
AND TGMPA_COD_PAI_K = 152 
AND TGMMD_COD_MAC_DOM_K = 340
AND PEMID_NRO_INN_IDE_K >= 1000000 AND PEMID_NRO_INN_IDE_K <= 48999999
GROUP BY PEMID_NRO_INN_IDE_K
HAVING PEMIE_MNT_RTA= CALCULATED MAX_RENTA AND PEMIE_FCH_ING_REG=CALCULATED MAX_FEC_REG;
QUIT;

PROC SQL;
CREATE TABLE RESULT.RENTA_ACT_LAB2 AS 
SELECT DISTINCT IDE,TIPO_ACTIVIDAD,RENTA
FROM RESULT.RENTA_ACT_LAB;
QUIT;

PROC SORT DATA=RESULT.RENTA_ACT_LAB2; BY IDE; RUN;

DATA RESULT.RENTA_ACT_LAB2;
SET  RESULT.RENTA_ACT_LAB2;
IF IDE=LAG(IDE) THEN FILTRO =1; 
ELSE FILTRO=0; 
RUN;

PROC SQL;
DELETE * FROM RESULT.RENTA_ACT_LAB2 WHERE FILTRO =1;
QUIT;

PROC SQL;
CREATE TABLE RESULT.TMP_DEMO_ITF AS 
SELECT PEMID_NRO_INN_IDE AS IDE,
(INPUT((A.PEMID_GLS_NRO_DCT_IDE_K ),BEST32.))AS RUT,
A.PEMID_DVR_NRO_DCT_IDE AS DV,
B.T_CTTO,
TIPO_ACTIVIDAD length=50,RENTA,
CASE WHEN PEMNB_COD_SEX=1 THEN 'M' WHEN PEMNB_COD_SEX=2 THEN 'F' END AS SEXO,
D.PEMNB_FCH_NAC AS FEC_NACI,
(YEAR(TODAY())-YEAR(DATEPART(PEMNB_FCH_NAC))) AS EDAD,
CASE WHEN (YEAR(TODAY())-YEAR(DATEPART(PEMNB_FCH_NAC))) BETWEEN 18 AND 25 THEN '18 - 25'
	WHEN (YEAR(TODAY())-YEAR(DATEPART(PEMNB_FCH_NAC))) BETWEEN 26 AND 33 THEN '26 - 33'
	WHEN (YEAR(TODAY())-YEAR(DATEPART(PEMNB_FCH_NAC))) BETWEEN 34 AND 41 THEN '34 - 41'
	WHEN (YEAR(TODAY())-YEAR(DATEPART(PEMNB_FCH_NAC))) BETWEEN 42 AND 49 THEN '42 - 49'
	WHEN (YEAR(TODAY())-YEAR(DATEPART(PEMNB_FCH_NAC))) BETWEEN 50 AND 57 THEN '50 - 57'
	WHEN (YEAR(TODAY())-YEAR(DATEPART(PEMNB_FCH_NAC))) BETWEEN 58 AND 65 THEN '58 - 65'
	WHEN (YEAR(TODAY())-YEAR(DATEPART(PEMNB_FCH_NAC))) > 65 AND (YEAR(TODAY())-YEAR(DATEPART(PEMNB_FCH_NAC)))<=100 THEN '65 o mas' 
	END AS RANGO_EDAD
FROM BOPERS.BOPERS_MAE_IDE A
LEFT JOIN RESULT.RUTS_CON_CONTRATO B ON A.PEMID_NRO_INN_IDE=IDE_CTTO
LEFT JOIN RESULT.RENTA_ACT_LAB2 C ON a.PEMID_NRO_INN_IDE = C.IDE
LEFT JOIN BOPERS.BOPERS_MAE_NAT_BSC D ON a.PEMID_NRO_INN_IDE = D.PEMID_NRO_INN_IDE_K;
QUIT;

%let mz_connect_credito=CONNECT TO ODBC as CREDITO(datasrc="creditoprd" user="CONSULTA_CREDITO" password="crdt#0806");
PROC SQL;
&mz_connect_credito;
CREATE TABLE RESULT.TMP_DEMO_CR2000_1 AS
SELECT * from  connection to credito(

SELECT *
from (

SELECT DISTINCT DDMCL_RUT_CLI AS RUT, 
DDMCL_FCH_NAC AS FEC_NAC, 
DDMCL_COC_SEX_CLI AS SEXO, 
DDMCL_MNT_RMN_CLI AS RENTA, 
DDMCL_COC_ACV_CLI AS COD_ACT,
CASE WHEN DDMCL_COC_ACV_CLI IN (18,29) THEN 'CESANTE'
WHEN DDMCL_COC_ACV_CLI IN (1,2,7,8,9,10,12,21,22,23,24,25,26,27,28,30,39,41,42,43,44,48,
     49,50,51,52,55,56,58,59,61,68) THEN 'DEPENDIENTE'
WHEN DDMCL_COC_ACV_CLI IN (6) THEN 'DUEÑA DE CASA'
WHEN DDMCL_COC_ACV_CLI IN (62,63,64,65) THEN 'ESTUDIANTE'
WHEN DDMCL_COC_ACV_CLI IN (3,4,11,13,14,15,16,17,19,20,31,32,33,34,35,36,37,38,45,46,47,
     53,54,57,60) THEN 'INDEPENDIENTE'
WHEN DDMCL_COC_ACV_CLI IN (5,40) THEN 'JUBILADO'
WHEN DDMCL_COC_ACV_CLI IN (66) THEN 'RETENCION JUDICIAL'
WHEN DDMCL_COC_ACV_CLI IN (0) THEN 'SIN INFORMACION'
END AS TIPO_ACTIVIDAD
FROM "GEDCRE_CREDITO"."DCRM_DIM_MAE_CLI"
WHERE DDMCL_RUT_CLI >= 1000000 AND DDMCL_RUT_CLI <= 48999999
)A 
) B
;QUIT;

PROC SQL;
   CREATE TABLE RESULT.TMP_DEMO_CR2000 AS 
   SELECT t1.RUT, 
          t1.FEC_NAC, (YEAR(TODAY())-YEAR(DATEPART(FEC_NAC))) AS EDAD,
CASE WHEN (YEAR(TODAY())-YEAR(DATEPART(FEC_NAC))) BETWEEN 18 AND 25 THEN '18 - 25'
WHEN (YEAR(TODAY())-YEAR(DATEPART(FEC_NAC))) BETWEEN 26 AND 33 THEN '26 - 33'
WHEN (YEAR(TODAY())-YEAR(DATEPART(FEC_NAC))) BETWEEN 34 AND 41 THEN '34 - 41'
WHEN (YEAR(TODAY())-YEAR(DATEPART(FEC_NAC))) BETWEEN 42 AND 49 THEN '42 - 49'
WHEN (YEAR(TODAY())-YEAR(DATEPART(FEC_NAC))) BETWEEN 50 AND 57 THEN '50 - 57'
WHEN (YEAR(TODAY())-YEAR(DATEPART(FEC_NAC))) BETWEEN 58 AND 65 THEN '58 - 65'
WHEN (YEAR(TODAY())-YEAR(DATEPART(FEC_NAC))) > 65 AND (YEAR(TODAY())-YEAR(DATEPART(FEC_NAC)))<=100 THEN '65 o mas' END AS RANGO_EDAD,
          t1.SEXO, 
          t1.RENTA, 
          t1.COD_ACT, 
          t1.TIPO_ACTIVIDAD
      FROM RESULT.TMP_DEMO_CR2000_1 t1;
QUIT;

PROC SQL;
CREATE TABLE RESULT.RUTS AS
SELECT RUT, MIN(PRIORI) AS PRIORIDAD
FROM (
SELECT RUT, 1 AS PRIORI FROM RESULT.TMP_DEMO_ITF WHERE T_CTTO=1
UNION 
SELECT RUT, 2 AS PRIORI FROM RESULT.TMP_DEMO_CR2000
UNION 
SELECT RUT, 3 AS PRIORI FROM RESULT.TMP_DEMO_ITF WHERE T_CTTO=.
) A
GROUP BY RUT
HAVING PRIORI=CALCULATED PRIORIDAD
;QUIT;

PROC SQL;
CREATE TABLE RESULT.DEMO_TOT AS
SELECT A.RUT,A.RENTA,A.TIPO_ACTIVIDAD,A.SEXO,DATEPART(A.FEC_NACI) FORMAT=DATE9. AS FECH_NAC,A.EDAD, A.RANGO_EDAD  
FROM RESULT.TMP_DEMO_ITF A INNER JOIN RESULT.RUTS B ON A.RUT=B.RUT AND B.PRIORIDAD IN (1,3)
UNION
SELECT A.RUT,A.RENTA,A.TIPO_ACTIVIDAD,A.SEXO,DATEPART(A.FEC_NAC) FORMAT=DATE9. AS FECH_NAC,A.EDAD, A.RANGO_EDAD  
FROM RESULT.TMP_DEMO_CR2000 A INNER JOIN RESULT.RUTS B ON A.RUT=B.RUT AND B.PRIORIDAD IN (2)
;QUIT;

PROC SQL;
UPDATE RESULT.DEMO_TOT
SET TIPO_ACTIVIDAD = 'DUEÑA DE CASA'
WHERE TIPO_ACTIVIDAD = 'DUE?A DE CASA'
;QUIT;

PROC SQL;
CREATE TABLE RESULT.DEMO_BASKET AS 
SELECT A.*,
CASE WHEN RENTA = 0 THEN ' 0 ' 
WHEN RENTA BETWEEN 1 AND 200000 THEN '1 - 200'
WHEN RENTA BETWEEN 200001 AND 300000 THEN '200 - 300'
WHEN RENTA BETWEEN 300001 AND 400000 THEN '300 - 400'
WHEN RENTA BETWEEN 400001 AND 500000 THEN '400 - 500'
WHEN RENTA BETWEEN 500001 AND 1000000 THEN '500 - 1MM'
WHEN RENTA > 1000000 THEN '1MM o mas' END AS TRAMO_RENTA,
CASE WHEN TIPO_ACTIVIDAD IN ('DEPENDIENTE','INDEPENDIENTE') AND SEXO='F' AND RENTA>400000 THEN 'A'
WHEN TIPO_ACTIVIDAD IN ('DEPENDIENTE','INDEPENDIENTE') AND SEXO='F' AND RENTA<=400000 AND RENTA IS NOT MISSING THEN 'B'
WHEN TIPO_ACTIVIDAD IN ('DEPENDIENTE') AND SEXO='M' AND RENTA>300000 AND RENTA IS NOT MISSING THEN 'C'
WHEN (TIPO_ACTIVIDAD IN ('INDEPENDIENTE') AND SEXO='M' AND RENTA>300000 AND RENTA IS NOT MISSING) OR TIPO_ACTIVIDAD IN ('JUBILADO','DUEÑA DE CASA') THEN 'D'
WHEN (TIPO_ACTIVIDAD IN ('DEPENDIENTE','INDEPENDIENTE') AND SEXO='M' AND RENTA<=300000 AND RENTA IS NOT MISSING) OR TIPO_ACTIVIDAD IN ('ESTUDIANTE') THEN 'E'
END AS GRUPO,
t2.categoria_gse as GSE
FROM RESULT.DEMO_TOT AS A 
LEFT JOIN RSEPULV.GSE_CORP AS t2 ON (A.RUT = t2.RUT);
QUIT;

PROC SQL;
   CREATE TABLE RESULT.DEMO_BASKET_FIN AS 
   SELECT t1.RUT, 
          t1.RENTA, 
          t1.TIPO_ACTIVIDAD, 
          t1.SEXO, 
          t1.FECH_NAC, 
          t1.EDAD, 
          t1.RANGO_EDAD, 
          t1.TRAMO_RENTA, 
          t1.GRUPO, 
          t1.GSE
      FROM RESULT.DEMO_BASKET t1
where t1.RUT >= 1000000 AND t1.RUT <= 48999999
;
QUIT;

DATA _null_;
datex = input(put(intnx('month',today(),-1,'end'),yymmn6.),$10.);
Call symput("fechax", datex);
RUN;
%put &fechax;

/* 
  fecha: 20-07-2020 
   modificacion: PUBLICIN.DEMO_BASKET_&fechax por RESULT.DEMO_BASKET2_&fechax
 
PROC SQL;
   CREATE TABLE PUBLICIN.DEMO_BASKET_&fechax AS 
   SELECT t1.*
      FROM RESULT.DEMO_BASKET_FIN AS t1;
QUIT;
*/

PROC SQL;
   CREATE TABLE RESULT.DEMO_BASKET_PRE_&fechax AS 
   SELECT t1.*
      FROM RESULT.DEMO_BASKET_FIN AS t1
;QUIT;

PROC SQL;
CREATE INDEX RUT ON RESULT.DEMO_BASKET_PRE_&fechax (RUT);
QUIT;


/*	=========================================================================	*/
/*			MEJORA PARA LA EDAD DE LOS DATOS - OBTENIDO DE BOPERS				*/
/*	=========================================================================	*/
DATA _null_;
datex0 = put(intnx('DAY',today(),0,'same'),yymmn6. );
Call symput("fechax0", datex0);

dateHOY	= compress(substr(put(today(),ddmmyy10.),7,4)||substr(put(today(),ddmmyy10.),4,2)||substr(put(today(),ddmmyy10.),1,2));
Call symput("VdateHOY", dateHOY);
call symput('fechafx',"TO_DATE('"||input(put(intnx('month',today(),0,'end'),DDMMYYD10. ),$10.)||"','DD-MM-YYYY')");

datePeriodoANT	= input(put(intnx('month',today(),-1,'end'	),yymmn6.   ),$10.);
Call symput("VdatePeriodoANT", datePeriodoANT);
run;

proc sql NOPRINT;                              
SELECT USUARIO into :USER 
	FROM sasdyp.user_pass WHERE SCHEMA = 'BOPERS_ADM';
SELECT PASSWORD into :PASSWORD 
	FROM sasdyp.user_pass WHERE SCHEMA = 'BOPERS_ADM';
quit;


LIBNAME R_bopers ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=BOPERS_ADM  USER=&USER. PASSWORD=&PASSWORD.;

/*CALCULAR EDAD*/
PROC SQL;
CREATE TABLE RUT_BOPERS_DE_VU AS	/*DICE VU PERO ES DE DEMO_BASKET SOLO SE QUEDO DE LO ANTERIOR*/
SELECT T1.RUT AS RUT, T2.PEMID_NRO_INN_IDE AS ID_BOPERS,
		  t1.RENTA, 
          t1.TIPO_ACTIVIDAD, 
          t1.SEXO, 
          t1.TRAMO_RENTA, 
          t1.GRUPO, 
          t1.GSE
	FROM RESULT.DEMO_BASKET_PRE_&VdatePeriodoANT T1 
		LEFT JOIN bopers.BOPERS_MAE_IDE T2
		ON (T1.RUT = input(T2.PEMID_GLS_NRO_DCT_IDE_K,best.))
ORDER BY 2
;QUIT;

PROC SQL;
CREATE TABLE VU_TRAMOS_EDAD__FECHA_NAC AS
SELECT T1.RUT AS RUT, T2.PEMNB_FCH_NAC AS FECHA_NACIMIENTO,
	input(put(datepart(T2.PEMNB_FCH_NAC),yymmddn8.),best.)  as FECHA_NAC_NUM,
		  t1.RENTA, 
          t1.TIPO_ACTIVIDAD, 
          t1.SEXO, 
          t1.TRAMO_RENTA, 
          t1.GRUPO, 
          t1.GSE 
	FROM RUT_BOPERS_DE_VU T1 
		LEFT JOIN bopers.BOPERS_MAE_NAT_BSC T2
			ON (T1.ID_BOPERS = T2.PEMID_NRO_INN_IDE_K)
ORDER BY 1 
;QUIT;

options cmplib=sbarrera.funcs;

PROC SQL;
CREATE TABLE VU_TRAMOS_EDAD__edad AS
SELECT T1.RUT AS RUT, T1.FECHA_NACIMIENTO, t1.FECHA_NAC_NUM,
		  t1.RENTA, 
          t1.TIPO_ACTIVIDAD, 
          t1.SEXO, 
          t1.TRAMO_RENTA, 
          t1.GRUPO, 
          t1.GSE,
	case when t1.FECHA_NAC_NUM > 0 then INPUT(SB_Ahora('AAAAMM'),BEST.)-INPUT(SUBSTR(PUT(t1.FECHA_NAC_NUM,BEST.),1,10),BEST.) 
			else 0 end as EDAD_NUM
	FROM VU_TRAMOS_EDAD__FECHA_NAC T1 
ORDER BY EDAD_NUM  
;QUIT;

PROC SQL;
CREATE TABLE VU_TRAMOS_EDAD__edad2 AS
SELECT T1.RUT AS RUT, T1.FECHA_NACIMIENTO, t1.FECHA_NAC_NUM,
		  t1.RENTA, 
          t1.TIPO_ACTIVIDAD, 
          t1.SEXO, 
          t1.TRAMO_RENTA, 
          t1.GRUPO, 
          t1.GSE,
		  INPUT(SUBSTR(PUT(t1.EDAD_NUM,BEST4.),1,2),BEST.)  as EDAD
	FROM VU_TRAMOS_EDAD__edad T1  
;QUIT;

PROC SQL;
CREATE TABLE EDAD_RUTS_DEMO_BASKET_A_&VdatePeriodoANT AS
SELECT 	  T1.RUT, T1.FECHA_NACIMIENTO, t1.FECHA_NAC_NUM, 
		  t1.EDAD, 
		  case when t1.edad = 0  then 'sin_fechas'                     
		       when t1.edad < 18 then 'menorDe18'                       
		       when t1.edad >= 18 and t1.edad <= 25 then '18 - 25'     
		       when t1.edad >= 26 and t1.edad <= 30 then '26 - 30'     
		       when t1.edad >= 31 and t1.edad <= 35 then '31 - 35'     
		       when t1.edad >= 36 and t1.edad <= 40 then '36 - 40'     
		       when t1.edad >= 41 and t1.edad <= 45 then '41 - 45'     
		       when t1.edad >= 46 and t1.edad <= 50 then '46 - 50'     
		       when t1.edad >= 51 and t1.edad <= 55 then '51 - 55'     
		       when t1.edad >= 56 and t1.edad <= 60 then '56 - 60'     
		       when t1.edad >= 61 and t1.edad <= 65 then '61 - 65'     
		       when t1.edad >= 66 and t1.edad <= 70 then '66 - 70'     
		       when t1.edad >= 71 and t1.edad <= 75 then '71 - 75'     
		       when t1.edad >= 76 and t1.edad <= 80 then '76 - 80'     
		       when t1.edad >= 81 and t1.edad <= 85 then '81 - 85'     
		       when t1.edad >= 86 and t1.edad <= 90 then '86 - 90'     
		       when t1.edad >= 91 and t1.edad <= 95 then '91 - 95'     
		       when t1.edad >= 96 and t1.edad <= 100 then '96 - 100'   
		       when t1.edad >= 101 then 'MayorDe100' END AS RANGO_EDAD,
		  t1.RENTA, 
          t1.TIPO_ACTIVIDAD, 
          t1.SEXO, 
          t1.TRAMO_RENTA, 
          t1.GRUPO, 
          t1.GSE
	FROM VU_TRAMOS_EDAD__edad2 t1
	WHERE T1.EDAD > 0
;QUIT;

PROC SQL;
CREATE TABLE RESULT.EDAD_RUTS_DEMO_BASKET_&VdatePeriodoANT AS
SELECT * from EDAD_RUTS_DEMO_BASKET_A_&VdatePeriodoANT
where rut >= 1000000 and rut <= 48999999
order by rut
;QUIT;

PROC SQL;
CREATE TABLE PUBLICIN.DEMO_BASKET_&VdatePeriodoANT AS
	SELECT * 
		from RESULT.EDAD_RUTS_DEMO_BASKET_&VdatePeriodoANT
;QUIT;

PROC SQL;
CREATE INDEX RUT ON PUBLICIN.DEMO_BASKET_&VdatePeriodoANT (RUT);
QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_ctbl_demo_basket,raw,sasdata,-1);

/*Exportación a AWS*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_ctbl_demo_basket,PUBLICIN.DEMO_BASKET_&VdatePeriodoANT.,raw,sasdata,-1);

/*	=========================================================================	*/
/*			FIN : MEJORA PARA LA EDAD DE LOS DATOS - OBTENIDO DE BOPERS			*/
/*	=========================================================================	*/


/*	=========================================================================	*/
/*			INI : CONTROL ANA MUÑOZ			*/
PROC SQL NOPRINT;
SELECT COUNT(*) AS TOTAL_REG
INTO :TOTAL_REG
FROM PUBLICIN.DEMO_BASKET_&VdatePeriodoANT
;QUIT;

PROC SQL OUTOBS=1 NOPRINT;
SELECT 
put(TODAY(),ddmmyy10.) as FECHA_FINAL,
YEAR(TODAY())*10000+(MONTH(TODAY())*100)+DAY(TODAY()) AS FPROCESO_FIN, /*FORMATO NUM */
put(TODAY(),Time10.) as HORA_FIN,
input(put(intnx('month',today(),-1,'end'),yymmn6.),$10.) as PERIODO
INTO
:FECHA_FINAL, 
:FPROCESO_FIN, 
:HORA_FIN,
:PERIODO
from sashelp.vmember
;quit;


%put====================================================================;
%put[02] FIN PROCESO  &FECHA_FINAL &HORA_FIN &TOTAL_REG;
%put=====================================================================;

/*			FIN : CONTROL ANA MUÑOZ			*/
/*	=========================================================================	*/


/*	=========================================================================	*/
/*			INI : CONTROL TIEMPO Y CORREO			*/

/*	Fecha ejecución del proceso	*/
data _null_;
execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechaeDVN", execDVN) ;
RUN;
%put &fechaeDVN;/*fecha ejecucion proceso */

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CONTACTABILIDAD';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4")
CC = ("&DEST_1","&DEST_2","&DEST_3")
SUBJECT="MAIL_AUTOM: PROCESO DEMO_BASKET %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
	PUT 'Estimados:'; 
	PUT "		Proceso DEMO_BASKET, ejecutado con fecha: &fechaeDVN";  
	PUT ; 
	PUT ; 
	PUT ; 
	PUT "Total de Registros Cargados &TOTAL_REG";
	PUT;
	PUT 'Proceso Vers. 11';
	PUT;
	PUT;
	PUT 'Atte.';
	Put 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */
