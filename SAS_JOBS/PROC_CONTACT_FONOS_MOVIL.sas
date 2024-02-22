/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	PROC_CONTACT_FONOS_MOVIL		 ===============================*/
/* CONTROL DE VERSIONES
/* 2023-04-04 -- v11 -- Andrea S. --  Se modifica nombre de fuentes informadas en base REPOSITORIO TELEFONOS para la separación por canal
								  --  Corrección campo fecha base Sinacofi y modificación formato fecha base QSC_HB_F_NEW
								  --  Se agrega consulta a base de simulaciones realizadas a través de Sitio público. 
/* 2023-03-21 -- v10 -- Sergio J. --  Se elimina t1 de varios campos, ya que no eran necesarios y producían error en la ejecución del proceso
/* 2023-02-21 -- v09 -- Andrea S.	-- Se agrega consulta a base CONTACT_QSC_NEW y se modifica fuente de datos QSC en línea 354 para que utilice base de datos histórica (info ex HB en FISA)
/* 2022-12-07 -- v08 -- David V.	-- Se agrega export to AWS a RAW
/* 2022-07-27 -- v07 -- Se agrega canal PWA en clasificación de actualizaciones registradas en Bopers
/* 2022-03-30 -- v06 -- Se desvincula el correo de Osvaldo y Pía, se asigna el contacto de PM_CONTACTABILIDAD
/* 2021-06-10 -- v05 -- Se quitan tablas asociadas a librería DVASQUEZ 
/* 2021-04-19 -- v04 -- Pia O. se arregla base QSC_paso , se dejan solo los nombres de las comunas que vienen de la base original de publicin. 
/* 2021-01-11 -- v03 -- Pia O. se agrega base, para comunicaciones informativas fonos_movil_final_se_info --
/* 2020-11-30 -- v02 -- David V. --  
					 -- Corrección a error con orgien QSC
					 -- Agregadas variables librerías
					 -- Homologados campos en union de tablas (&libreria2..FONOS_CELULARES) línea 350 aprox. 
/* 2020-06-23 -- v01 -- David V. --
					 -- Filtros Libros Negros aplicados 

/* INFORMACIÓN:
	Programa que genera la contactabilidad para teléfonos móviles, toma información de diferentes origenes
	los agrupa, y selecciona un dato por cliente para dejar disponible al área BI.

	(IN) Tablas requeridas o conexiones a BD:
		RESULT.SIMULACIONES_HB_201911
		PUBLICIN.REPOSITORIO_TELEFONOS
		RESULT.FONOS_COMPRA_SINACOFI
		RESULT.SIMULACIONES_HB_NEW_F
		PUBLICIN.QUIERO_SER_CLIENTE_HB_F
		PUBLICIN.QSC_HB_F_NEW
		PUBLICIN.CHEK_F
		result.FONOS_CELULARES
		BOPERS.BOPERS_MAE_IDE
		BOPERS.BOPERS_MAE_FON
		result.FONOS_MOVIL_FINAL_REP_OK

	(OUT) Tablas de Salida o resultado:
		PUBLICIN.FONOS_MOVIL_FINAL
		PUBLICIN.FONOS_MOVIL_FINAL_SE
        PUBLICIN.SP_SMS_&fechax0
        
*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria  = PUBLICIN;
%let libreria2 = RESULT;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/


/*=============================================================================================*/
/* CONTACTABILIDAD - TELEFONOS INFORMADOS MENOS LOS RUTS QUE EXCEDEN EL LARGO 				   */
/*=============================================================================================*/

DATA _null_;
/* Variables Fechas de Ejecución */
datePeriodo1	= compress(substr(put(today(),ddmmyy10.),7,4)||substr(put(today(),ddmmyy10.),4,2)||substr(put(today(),ddmmyy10.),1,2));
Call symput("VdatePeriodo1", datePeriodo1);

datePeriodo2	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.);
Call symput("VdatePeriodo2", datePeriodo2);

RUN;
%put &VdatePeriodo1;
%put &VdatePeriodo2; 

PROC SQL;
   CREATE TABLE &libreria2..REPOSITORIO_TELEFONOS_&VdatePeriodo2 AS 
   SELECT RUT, 
          TELEFONO, 
          FECHA, 
          NOTA, 
          FUENTE
      FROM &libreria..REPOSITORIO_TELEFONOS
      WHERE rut < 99999999
	ORDER BY RUT;
QUIT;


/*=========================================================================================*/
/* CONTACTABILIDAD - RESPALDO TABLA FONOS_MOVIL_FINAL ANTERIOR */
/*=========================================================================================*/
proc sql;
	create table &libreria2..FONOS_MOVIL_FINAL_SE_&VdatePeriodo2 AS
		SELECT * FROM &libreria..FONOS_MOVIL_FINAL_SE
;quit;

proc sql;
	create table &libreria2..FONOS_MOVIL_FINAL_&VdatePeriodo2 AS
		SELECT * FROM &libreria..FONOS_MOVIL_FINAL
;quit;

/*proc sql;*/
/*	create table RESULT.FONOS_MOVIL_FINAL_SE_&VdatePeriodo1 AS*/
/*		SELECT * FROM PUBLICIN.FONOS_MOVIL_FINAL_SE*/
/*;quit;*/

/*proc sql;
	create table RESULT.FONOS_MOVIL_FINAL_&VdatePeriodo1 AS
		SELECT * FROM PUBLICIN.FONOS_MOVIL_FINAL
;quit;*/

/*=========================================================================================*/
/* CONTACTABILIDAD - PROCESO */
/*=========================================================================================*/
/*SE EXTRAE NOTA MAXIMA DE FONOS*/
PROC SQL;
   CREATE TABLE MAXIMO AS 
   SELECT RUT, 
          (MAX(NOTA)) AS NOTA
      FROM &libreria..REPOSITORIO_TELEFONOS
      WHERE NOTA >= 0 AND TELEFONO >= 900000000
      GROUP BY RUT;
QUIT;


PROC SQL;
   CREATE TABLE FONOS_CELU AS 
   SELECT DISTINCT t1.RUT, T1.TELEFONO, t1.FECHA, t2.NOTA, T1.FUENTE
      FROM &libreria..REPOSITORIO_TELEFONOS t1 
                    INNER JOIN MAXIMO T2
						ON (t1.RUT=t2.RUT AND t1.NOTA=t2.NOTA)
      WHERE t1.NOTA >= 0 AND t1.TELEFONO >= 900000000

;QUIT;

/*=========================================================================================*/
/*	1.- SE ORDENA POR CANAL*/
PROC SQL;
   CREATE TABLE PLATAFORMA AS 
   SELECT RUT, 
          TELEFONO, 
          FECHA,
          NOTA, 
          FUENTE
      FROM WORK.FONOS_CELU
      WHERE FUENTE = 'PLAT COMER';
QUIT;

PROC SQL;
   CREATE TABLE ADMISION AS 
   SELECT RUT, 
          TELEFONO, 
          FECHA,
          NOTA, 
          FUENTE
      FROM WORK.FONOS_CELU
      WHERE FUENTE = 'VENTA ADMI'
      AND RUT NOT IN (SELECT RUT FROM PLATAFORMA)
;QUIT;  

PROC SQL;
   CREATE TABLE BANCO AS 
   SELECT RUT, 
          TELEFONO, 
          FECHA, 
          NOTA, 
          FUENTE
      FROM WORK.FONOS_CELU
      WHERE FUENTE = 'REPTEL'
       AND RUT NOT IN (SELECT RUT FROM ADMISION)
       AND RUT NOT IN (SELECT RUT FROM PLATAFORMA)
;QUIT;

PROC SQL;
   CREATE TABLE CCR AS 
   SELECT RUT, 
          TELEFONO, 
          FECHA,
          NOTA, 
          FUENTE
      FROM WORK.FONOS_CELU
      WHERE FUENTE = 'SCORE CCR'
       AND RUT NOT IN (SELECT RUT FROM ADMISION)
       AND RUT NOT IN (SELECT RUT FROM PLATAFORMA)
       AND RUT NOT IN (SELECT RUT FROM BANCO)
;QUIT;

PROC SQL;
   CREATE TABLE IVR AS 
   SELECT RUT, 
          TELEFONO, 
          FECHA, 
          NOTA, 
          FUENTE
      FROM WORK.FONOS_CELU
      WHERE FUENTE = 'IVR'
       AND RUT NOT IN (SELECT RUT FROM ADMISION)
       AND RUT NOT IN (SELECT RUT FROM PLATAFORMA)
       AND RUT NOT IN (SELECT RUT FROM BANCO)
       AND RUT NOT IN (SELECT RUT FROM CCR)
;QUIT;

PROC SQL;
   CREATE TABLE CYBER AS 
   SELECT RUT, 
          TELEFONO, 
          FECHA, 
          NOTA, 
          FUENTE
      FROM WORK.FONOS_CELU
      WHERE FUENTE = 'CYBER'
       AND RUT NOT IN (SELECT RUT FROM ADMISION)
       AND RUT NOT IN (SELECT RUT FROM PLATAFORMA)
       AND RUT NOT IN (SELECT RUT FROM BANCO)
       AND RUT NOT IN (SELECT RUT FROM CCR)
       AND RUT NOT IN (SELECT RUT FROM IVR)
;QUIT;

PROC SQL;
   CREATE TABLE HB AS 
   SELECT RUT, 
          TELEFONO, 
          FECHA, 
          NOTA, 
          FUENTE
      FROM WORK.FONOS_CELU 
      WHERE FUENTE = 'HOME BANKI'
       AND RUT NOT IN (SELECT RUT FROM ADMISION)
       AND RUT NOT IN (SELECT RUT FROM PLATAFORMA)
       AND RUT NOT IN (SELECT RUT FROM BANCO)
     AND RUT NOT IN (SELECT RUT FROM CCR)
       AND RUT NOT IN (SELECT RUT FROM IVR)
       AND RUT NOT IN (SELECT RUT FROM CYBER)
;QUIT;

PROC SQL;
   CREATE TABLE BUF AS 
   SELECT RUT, 
          TELEFONO, 
          FECHA, 
          NOTA, 
          FUENTE
      FROM WORK.FONOS_CELU
      WHERE FUENTE = 'BUF'
            AND RUT NOT IN (SELECT RUT FROM ADMISION)
       AND RUT NOT IN (SELECT RUT FROM PLATAFORMA)
       AND RUT NOT IN (SELECT RUT FROM BANCO)
       AND RUT NOT IN (SELECT RUT FROM CCR)
       AND RUT NOT IN (SELECT RUT FROM IVR)
       AND RUT NOT IN (SELECT RUT FROM CYBER)
       AND RUT NOT IN (SELECT RUT FROM HB)
;QUIT;

PROC SQL;
   CREATE TABLE DGC AS 
   SELECT RUT, 
          TELEFONO, 
          FECHA, 
          NOTA, 
          FUENTE
      FROM WORK.FONOS_CELU
      WHERE FUENTE = 'REPO UNICO'
       AND RUT NOT IN (SELECT RUT FROM ADMISION)
       AND RUT NOT IN (SELECT RUT FROM PLATAFORMA)
       AND RUT NOT IN (SELECT RUT FROM BANCO)
       AND RUT NOT IN (SELECT RUT FROM CCR)
       AND RUT NOT IN (SELECT RUT FROM IVR)
       AND RUT NOT IN (SELECT RUT FROM CYBER)
       AND RUT NOT IN (SELECT RUT FROM HB)
       AND RUT NOT IN (SELECT RUT FROM BUF)
;QUIT;

PROC SQL;
   CREATE TABLE OTROS AS 
   SELECT RUT, 
          TELEFONO, 
          FECHA, 
          NOTA, 
          FUENTE
      FROM WORK.FONOS_CELU
      WHERE RUT NOT IN (SELECT RUT FROM ADMISION)
       	AND RUT NOT IN (SELECT RUT FROM PLATAFORMA)
       	AND RUT NOT IN (SELECT RUT FROM BANCO)
       	AND RUT NOT IN (SELECT RUT FROM CCR)
       	AND RUT NOT IN (SELECT RUT FROM IVR)
       	AND RUT NOT IN (SELECT RUT FROM CYBER)
       	AND RUT NOT IN (SELECT RUT FROM HB)
        AND RUT NOT IN (SELECT RUT FROM BUF)
        AND RUT NOT IN (SELECT RUT FROM DGC)
;QUIT;


DATA _null_;
datex0 = put(intnx('month',today(),0,'same'),yymmn6. );
Call symput("fechax0", datex0);

run;
%put &fechax0;

proc sql;
create table SIMULACIONES_INI AS
SELECT	DISTINCT input(rut,best.) as RUT, 
		case when length (CELULAR) = 9 then INPUT(substr (CELULAR, 2,9),BEST.)
			when length (CELULAR) = 8 then INPUT(CELULAR,BEST.) else 0 end as TELEFONO,
        FECHA FORMAT = DATETIME20. AS FECHA,
        1 AS NOTA,
        ORIGEN AS FUENTE
    FROM RESULT.SIMULACIONES_HB_201911		/* últimos registros en BD, luego Firebase */
	ORDER BY 1
;quit;

proc sql;
create table SIMULACIONES_MAX AS
SELECT	DISTINCT input(rut,best.) as RUT, 
		MAX(FECHA) FORMAT = DATETIME20. AS FECHA
    FROM RESULT.SIMULACIONES_HB_201911		/* últimos registros en BD, luego Firebase */
	GROUP BY RUT HAVING RUT > 100 AND RUT < 99999999
;quit;

proc sql;
create table SIMULACIONES_INI_MAX AS
SELECT	DISTINCT T2.RUT, 
        T1.TELEFONO, 
        T2.FECHA,
        T1.NOTA,
        T1.FUENTE
    FROM SIMULACIONES_INI T1 INNER JOIN SIMULACIONES_MAX t2
	ON (T1.RUT = T2.RUT AND T1.FECHA = T2.FECHA)
;quit;

proc sql;
create table SIMULACIONES_DE_PASO AS
SELECT	RUT, 
        TELEFONO, 
        FECHA,
		input(put(datepart(FECHA),yymmddn8.),best.) as FECHA_NUM,
        NOTA,
        FUENTE
    FROM SIMULACIONES_INI_MAX
;quit;

proc sql;
create table SIMULACIONES_BD_2019 AS
SELECT	T1.RUT, 
        T1.TELEFONO, 
        MDY(INPUT(SUBSTR(PUT(t1.FECHA_NUM,BEST8.),5,2),BEST4.),
                  INPUT(SUBSTR(PUT(t1.FECHA_NUM,BEST8.),7,2),BEST4.),
                  INPUT(SUBSTR(PUT(t1.FECHA_NUM,BEST8.),1,4),BEST4.)) FORMAT=YYMMDD10. AS FECHA,
        T1.NOTA,
        T1.FUENTE
    FROM SIMULACIONES_DE_PASO T1
;quit;

proc sql;
create table FONOS_COMPRA_SINACOFI as
		SELECT 	RUT, TELEFONO,
				FECHA1 as FECHA,
				NOTA,
				FUENTE 
				FROM RESULT.FONOS_COMPRA_SINACOFI
;quit;


proc sql;
create table QSC_HB_F_NEW as
		SELECT 	RUT, TELEFONO,
				DATEPART(FECHA) FORMAT= YYMMDD10. AS FECHA,
				NOTA,
				FUENTE 
				FROM &libreria..QSC_HB_F_NEW
;quit;

proc sql;
create table SIMULACIONES_SP as
select rut,TELEFONO,
	MDY(INPUT(SUBSTR(PUT(FECHA_ACT,BEST8.),5,2),BEST4.),
                  INPUT(SUBSTR(PUT(FECHA_ACT,BEST8.),7,2),BEST4.),
                  INPUT(SUBSTR(PUT(FECHA_ACT,BEST8.),1,4),BEST4.)) FORMAT=YYMMDD10. AS FECHA,
	1 AS NOTA,
	ORIGEN AS FUENTE
from POLAVARR.SIMULACIONES_SP
WHERE TELEFONO IS NOT NULL
;QUIT;


PROC SQL;
   CREATE TABLE &libreria2..FONOS_CELULARES AS 
   		SELECT RUT,	TELEFONO,	FECHA,	NOTA,	FUENTE FROM PLATAFORMA	outer UNION corr
       	SELECT RUT,	TELEFONO,	FECHA,	NOTA,	FUENTE FROM ADMISION  	outer UNION corr
       	SELECT RUT,	TELEFONO,	FECHA,	NOTA,	FUENTE FROM BANCO	outer UNION corr
       	SELECT RUT,	TELEFONO,	FECHA,	NOTA,	FUENTE FROM CCR  	outer UNION corr
       	SELECT RUT,	TELEFONO,	FECHA,	NOTA,	FUENTE FROM IVR  	outer UNION corr
       	SELECT RUT,	TELEFONO,	FECHA,	NOTA,	FUENTE FROM CYBER  	outer UNION corr
       	SELECT RUT,	TELEFONO,	FECHA,	NOTA,	FUENTE FROM HB  	outer UNION corr
       	SELECT RUT,	TELEFONO,	FECHA,	NOTA,	FUENTE FROM BUF 	outer UNION corr
	    SELECT RUT,	TELEFONO,	FECHA,	NOTA,	FUENTE FROM DGC 	outer UNION corr
       	SELECT RUT,	TELEFONO,	FECHA,	NOTA,	FUENTE FROM OTROS	outer UNION corr
		SELECT * FROM  	SIMULACIONES_BD_2019	outer UNION corr		
		SELECT * FROM 	FONOS_COMPRA_SINACOFI 	 outer UNION corr
		SELECT * FROM  	RESULT.SIMULACIONES_HB_NEW_F	 outer UNION corr
		SELECT * FROM	&libreria..QSC_FISA_HIST_F outer UNION corr
		SELECT * FROM	QSC_HB_F_NEW outer UNION corr
		SELECT * FROM	&libreria..CHEK_F outer UNION corr
		SELECT * FROM	SIMULACIONES_SP 
;QUIT;
/*	FIN 1.- SE ORDENA POR CANAL*/
/*=========================================================================================*/

/*=========================================================================================*/
/*	2.- SE PRIORIZA EL MÁS ACTUALIZADO */
PROC SQL;
   CREATE TABLE MAXIMO_FECHA AS 
   SELECT RUT, 
            (MAX(FECHA)) AS MAX_of_FECHA
      FROM &libreria2..FONOS_CELULARES
      GROUP BY RUT;
QUIT;



/*=========================================================================================*/
/*	3.- MEJOR FONO CELULARES DE FUENTES ANTERIORES */
PROC SQL;
   CREATE TABLE FONOS_MOVIL_FINAL_REP AS 
   SELECT t1.RUT AS CLIRUT,
   		  0 as SEQ,
          T1.FUENTE AS MANDANTE,
          '9' AS AREA,
          COMPRESS(PUT(t1.TELEFONO-100000000* Floor(t1.TELEFONO/100000000),BEST.)) AS TELEFONO, 
          t1.FECHA FORMAT=date9. AS FECHA_ULT_ACTUALIZACION,
          'CE' AS TIPO,
          t1.NOTA,
          'ALL' AS USO,
		  0 as ESTADO
      FROM &libreria2..FONOS_CELULARES t1 INNER JOIN MAXIMO_FECHA T2 ON (T1.RUT=T2.RUT AND T1.FECHA=T2.MAX_of_FECHA)
;quit;

/*MEJOR FONO DEL REPORISORIO - 4MM APROX*/
PROC SQL;
   CREATE TABLE &libreria2..FONOS_MOVIL_FINAL_REP_OK AS 
   SELECT CLIRUT,
   		  SEQ,
          MANDANTE,
          AREA,
		  input(TELEFONO,best.) AS TELEFONO,
          FECHA_ULT_ACTUALIZACION,
          TIPO,
          NOTA,
          USO,
		  ESTADO
      FROM FONOS_MOVIL_FINAL_REP
;quit;

/*=========================================================================================*/
/*	FONOS DESDE BOPERS*/
LIBNAME bopers ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=BOPERS_ADM  USER='SAS_USR_BI' PASSWORD='SAS_23072020';

PROC SQL;
   CREATE TABLE FONOS_SMS_BOPERS AS 
   SELECT 	input(t1.PEMID_GLS_NRO_DCT_IDE_K,best.) AS CLIRUT,
			t2.PEMFO_NRO_SEQ_FON_K as SEQ,
/*        	'BOPERS' as MANDANTE,*/
		CASE 	WHEN t2.PEMFO_GLS_USR_FIN_ACL = 'HB-APP' then 'BOPERS_HB'
				WHEN t2.PEMFO_GLS_USR_FIN_ACL = 'APP' then 'BOPERS_APP' 
				WHEN t2.PEMFO_GLS_USR_FIN_ACL = 'PWA' then 'BOPERS_PWA'
				ELSE 'BOPERS_CCSS' END as MANDANTE,
          	'9' AS AREA,
          	t2.PEMFO_NRO_FON as TELEFONO, 
          	t2.PEMFO_FCH_FIN_ACL  AS FECHA_ULT_ACTUALIZACION,
            'CE' AS TIPO,
/*            0 AS NOTA,*/
		CASE 	WHEN t2.PEMFO_COD_EST_LCL = 1 then 5
				WHEN t2.PEMFO_COD_EST_LCL = 2 then 10 
				ELSE 1 END as NOTA,
            'SMS' AS USO,
            T2.PEMFO_COD_EST_LCL as ESTADO
      FROM BOPERS.BOPERS_MAE_IDE t1
           INNER JOIN BOPERS.BOPERS_MAE_FON t2 ON (t1.PEMID_NRO_INN_IDE = t2.PEMID_NRO_INN_IDE_K)
      WHERE t2.PEMFO_COD_TIP_FON = 4 AND T2.PEMFO_COD_EST_LCL <> 6
	  AND T2.PEMFO_NRO_FON>=30000000 and T1.PEMID_GLS_NRO_DCT_IDE_K not LIKE ('49999%') 
;
QUIT;


/*=========================================================================================*/
/*	MAXIMO O ULTIMO FONO ACTUALIZADO EN BOPERS*/
PROC SQL;
   CREATE TABLE MAXIMO_FONO_BOPERS AS 
   SELECT CLIRUT, 
          (MAX(FECHA_ULT_ACTUALIZACION)) FORMAT=DATETIME20. AS MAX_of_FECHA_ULT_ACTUALIZACION
      FROM FONOS_SMS_BOPERS
      GROUP BY CLIRUT;
QUIT;

/*=========================================================================================*/
/*	MAXIMO O ULTIMO FONO ACTUALIZADO EN BOPERS SEGÚN SU SEQ*/
PROC SQL;
   CREATE TABLE MAXIMO_FONO_BOPERS_SEQ AS 
   SELECT CLIRUT, 
          (max(SEQ)) as max_seq,
		  TELEFONO
      FROM WORK.FONOS_SMS_BOPERS
      GROUP BY CLIRUT;
QUIT;

/*=========================================================================================*/
/*	MEJOR FONO DESDE BOPERS */
PROC SQL;
   CREATE TABLE FONOS_SMS_MEJOR_BOPERS AS 
   SELECT distinct t1.clirut, 
   		  t1.SEQ,
          t1.MANDANTE,
          t1.AREA,
 		  t1.telefono,
          input(put(datepart(t1.FECHA_ULT_ACTUALIZACION),date9.) ,date9.) format=date9. as FECHA_ULT_ACTUALIZACION, 
          t1.TIPO, 
          t1.NOTA,
		  'SMS' as USO,
          t1.ESTADO
      FROM WORK.FONOS_SMS_BOPERS t1 inner join MAXIMO_FONO_BOPERS t2 
			on (t1.CLIRUT=t2.CLIRUT 
				and t1.FECHA_ULT_ACTUALIZACION=t2.MAX_of_FECHA_ULT_ACTUALIZACION)
WHERE t1.TELEFONO BETWEEN 30000000 AND 99999999
and t1.TELEFONO not in (99999999,88888888,77777777,66666666,55555555,44444444,33333333,22222222,11111111,00000000,
                        98989898,89898989,88889999,99998888)
;QUIT;

/*=========================================================================================*/
/*	MEJOR FONO DESDE BOPERS SI ES MISMA FECHA */
PROC SQL;
   CREATE TABLE FONOS_SMS_MEJOR_BOPERS_B AS 
   SELECT distinct t1.CLIRUT, 
   		  t1.SEQ,
          t1.MANDANTE, 
          t1.AREA, 
		  t1.telefono, 
          t1.FECHA_ULT_ACTUALIZACION, 
          t1.TIPO, 
          t1.NOTA,
		  t1.USO,
          t1.ESTADO
      FROM FONOS_SMS_MEJOR_BOPERS t1 inner join MAXIMO_FONO_BOPERS_SEQ t2 
			on (t1.CLIRUT=t2.CLIRUT	and t1.seq=t2.MAX_SEQ)
;QUIT;

/*=========================================================================================*/
PROC SQL;
CREATE TABLE UNION_MEJOR_BOPERS_FECH_SEQ AS
	SELECT * FROM FONOS_SMS_MEJOR_BOPERS_B T1
		UNION ALL
	SELECT * FROM FONOS_SMS_MEJOR_BOPERS T2 WHERE t2.CLIRUT NOT IN (SELECT CLIRUT FROM FONOS_SMS_MEJOR_BOPERS_B)
;QUIT;

PROC SQL;
CREATE TABLE REGISTROS_MAX_SEQ AS
	SELECT DISTINCT(CLIRUT), 
		  (MAX(SEQ)) AS SEQ,
          MANDANTE, 
          AREA, 
          telefono, 
          FECHA_ULT_ACTUALIZACION, 
          TIPO, 
          NOTA,
		  USO,
          ESTADO
	FROM UNION_MEJOR_BOPERS_FECH_SEQ
	GROUP BY CLIRUT 
;QUIT;

PROC SQL;
CREATE TABLE SOLO_UNICOS AS
	SELECT T1.*
	FROM UNION_MEJOR_BOPERS_FECH_SEQ T1 WHERE T1.SEQ IN (SELECT SEQ FROM REGISTROS_MAX_SEQ)
;QUIT;

/*solo control*/
PROC SQL;
   CREATE TABLE &libreria2..FONOS_SMS_MEJOR_BOPERS_&fechax0 as /*&VdatePeriodo1 AS */
   SELECT CLIRUT,
		SEQ,
		MANDANTE,
		AREA,
		TELEFONO,
		FECHA_ULT_ACTUALIZACION,
		TIPO,
		NOTA,
		USO,
		ESTADO
      FROM SOLO_UNICOS
;
QUIT;


/* Corregido para privilegias fonos desde bopers antes del repositorio telefonos (201911)*/
PROC SQL;
   CREATE TABLE FONOS_MOVIL_PRE_FINAL AS 
   SELECT *
      FROM &libreria2..FONOS_SMS_MEJOR_BOPERS_&fechax0 t1
       union
    SELECT * 
      from &libreria2..FONOS_MOVIL_FINAL_REP_OK where clirut not in (select clirut from SOLO_UNICOS)
;
QUIT;

/*=========================================================================================*/
/*SE ARMA TABLA FINAL*/
/*QUITA DUPLICADOS*/
proc sort data=FONOS_MOVIL_PRE_FINAL out=&libreria2..FONOS_MOVIL_PRE_FINAL nodupkeys dupout=duplicados;
by CLIRUT;
run;


/*=========================================================================================*/
/*	CUENTA TELEFONOS QUE NO ESTAN DUPLICADOS PARA EL MISMO RUT MAS DE TRES VECES */
PROC SQL;
   CREATE TABLE veces AS 
   SELECT TELEFONO, 
          (COUNT(TELEFONO)) AS COUNT_of_TELEFONO
      FROM &libreria2..FONOS_MOVIL_PRE_FINAL       
      GROUP BY TELEFONO
       having COUNT_of_TELEFONO<3
;QUIT;

/*DE LOS REPETIDOS, TOMAR EL TELEFONO CON LA FECHA MÁS RECIENTE*/
PROC SQL;
   CREATE TABLE mejor_de_veces_2 AS 
   SELECT t1.TELEFONO, MAX(T1.FECHA_ULT_ACTUALIZACION) format=date9. as FECHA_ULT_ACTUALIZACION,
			max(t1.seq) as seq
		FROM &libreria2..FONOS_MOVIL_PRE_FINAL t1
		  	LEFT JOIN VECES T2 ON (T1.TELEFONO = T2.TELEFONO)
		where t2.COUNT_of_TELEFONO = 2
		GROUP BY t1.TELEFONO
;QUIT;

/*=========================================================================================*/
/*MEJORES FONOS SIN FILTRO SERNAC Y LISTAS NEGRAS - mismo anterior */
/*TELEFONO UNICO PARA RUT UNICO*/
PROC SQL;
   CREATE TABLE FONOS_MOVIL_FINAL_SFSLN_2 AS 
   SELECT t1.CLIRUT,
 		  t1.SEQ,
          t1.MANDANTE, 
          input(T1.AREA,best.) as AREA, 
          t1.TELEFONO, 
          t1.FECHA_ULT_ACTUALIZACION, 
          t1.TIPO, 
          t1.NOTA, 
          t1.USO,
		  t1.ESTADO
      FROM &libreria2..FONOS_MOVIL_PRE_FINAL t1
			inner join veces t2 on (t1.telefono = t2.telefono and t2.COUNT_of_TELEFONO = 1)
;
QUIT;

/*DE DOS RUTS PARA UN MISMO TELEFONO, SELECCIONO EL MÁS RECIENTE POR FECHA */
PROC SQL;
   CREATE TABLE FONOS_MOVIL_FINAL_SFSLN_3 AS 
   SELECT t1.CLIRUT,
		  t1.SEQ, 
          t1.MANDANTE, 
          input(T1.AREA,best.) as AREA,
          t1.TELEFONO, 
          t1.FECHA_ULT_ACTUALIZACION, 
          t1.TIPO, 
          t1.NOTA, 
          t1.USO,
		  t1.ESTADO
      FROM mejor_de_veces_2 t2
			left join &libreria2..FONOS_MOVIL_PRE_FINAL t1 
			on (t1.telefono = t2.telefono 
				and t1.FECHA_ULT_ACTUALIZACION = t2.FECHA_ULT_ACTUALIZACION
				)
;
QUIT;

PROC SQL;
   CREATE TABLE veces_SEQ AS 
   SELECT t1.TELEFONO, 
          (COUNT(t1.TELEFONO)) AS COUNT_of_TELEFONO
      FROM FONOS_MOVIL_FINAL_SFSLN_3 t1       
      GROUP BY t1.TELEFONO
       having COUNT_of_TELEFONO<3
;QUIT;

/*DE LOS REPETIDOS, TOMAR EL TELEFONO CON LA FECHA MÁS RECIENTE*/
PROC SQL;
   CREATE TABLE mejor_de_veces_2_SEQ AS 
   SELECT t1.TELEFONO, T1.FECHA_ULT_ACTUALIZACION,
			max(t1.seq) as SEQ
		FROM &libreria2..FONOS_MOVIL_PRE_FINAL t1
		  	LEFT JOIN veces_SEQ T2 ON (T1.TELEFONO = T2.TELEFONO)
		where t2.COUNT_of_TELEFONO = 2
		GROUP BY t1.TELEFONO
;QUIT;

/*EL MEJOR TELEFONO CON LA MISMA FECHA DE ACTUALIZACIÓN - MAYOR SECUENCIA */
PROC SQL;
   CREATE TABLE FONOS_MOVIL_FINAL_SFSLN_4 AS 
   SELECT DISTINCT t1.CLIRUT,
		  t1.SEQ, 
          t1.MANDANTE, 
          input(T1.AREA,best.) as AREA,
          t1.TELEFONO, 
          t1.FECHA_ULT_ACTUALIZACION, 
          t1.TIPO, 
          t1.NOTA, 
          t1.USO,
		  t1.ESTADO
      FROM mejor_de_veces_2_SEQ t2
			left join &libreria2..FONOS_MOVIL_PRE_FINAL t1 
			on (t1.telefono = t2.telefono 
				and t1.FECHA_ULT_ACTUALIZACION = t2.FECHA_ULT_ACTUALIZACION
				and t1.seq = t2.seq
				)
;
QUIT;

PROC SQL;
   CREATE TABLE veces_SEQ_REPETIDA AS 
   SELECT t1.TELEFONO, 
          (COUNT(t1.TELEFONO)) AS COUNT_of_TELEFONO
      FROM FONOS_MOVIL_FINAL_SFSLN_4 t1       
      GROUP BY t1.TELEFONO
       having COUNT_of_TELEFONO=2
order by 1
;QUIT;

/*FONO BUENOS MEJOR SECUENCIA Y NO REPETIDOS*/
PROC SQL;
   CREATE TABLE &libreria2..REMANENTE_FINAL_SIN_FILTROS AS 
   	SELECT * FROM FONOS_MOVIL_FINAL_SFSLN_4 T1
   				WHERE T1.TELEFONO NOT IN (SELECT TELEFONO FROM veces_SEQ_REPETIDA)
	UNION ALL
	SELECT * FROM FONOS_MOVIL_FINAL_SFSLN_3 T2
				WHERE 	T2.TELEFONO NOT IN (SELECT TELEFONO FROM veces_SEQ_REPETIDA)
					AND T2.TELEFONO NOT IN (SELECT TELEFONO FROM FONOS_MOVIL_FINAL_SFSLN_4)
	UNION ALL
	SELECT * FROM FONOS_MOVIL_FINAL_SFSLN_2 T3
;QUIT;

proc sql;
create table &libreria..FONOS_MOVIL_FINAL_SE_INFO as 
select 
t1.*
from publicin.fonos_movil_final_se t1
left join publicin.lnegro_car t2
on (t1.clirut=t2.rut)
where /*(tipo_inhibicion=lista_negra_car and canal_reclamo=auris) and */
t2.tipo_inhibicion not in ('FALLECIDO','FALLECIDOS',) ;
quit ; 


PROC SQL;
CREATE TABLE FILTROS_APLICADOS AS
/*SELECT * FROM RESULT.FONOS_MOVIL_FINAL_SFSLN T1*/
SELECT * FROM &libreria2..REMANENTE_FINAL_SIN_FILTROS T1
	WHERE T1.CLIRUT 	NOT IN (SELECT T2.RUT 	FROM PUBLICIN.LNEGRO_CALL T2)
		AND T1.TELEFONO NOT IN (SELECT T2.FONO 	FROM PUBLICIN.LNEGRO_CALL T2)
		AND T1.CLIRUT 	NOT IN (SELECT T3.RUT 	FROM PUBLICIN.LNEGRO_CAR T3)
		AND T1.CLIRUT 	NOT IN (SELECT T4.RUT 	FROM PUBLICIN.LNEGRO_SMS T4)
		AND T1.TELEFONO NOT IN (SELECT T4.FONO 	FROM PUBLICIN.LNEGRO_SMS T4)
;QUIT;


/*solo control*/
PROC SQL;
CREATE TABLE &libreria2..FONOS_FINAL_CAEN_X_FILT_&fechax0 as /*&VdatePeriodo2 AS*/
	SELECT * FROM &libreria2..REMANENTE_FINAL_SIN_FILTROS T1 
		WHERE 	T1.CLIRUT 	NOT IN (SELECT T2.CLIRUT	FROM FILTROS_APLICADOS T2)
			AND 	T1.TELEFONO NOT IN (SELECT T2.TELEFONO 	FROM FILTROS_APLICADOS T2)	
;QUIT;

PROC SQL;
CREATE TABLE &libreria2..FONOS_FINAL_CAEN_XD_FILT_&fechax0 as /*&VdatePeriodo2 AS*/
	SELECT distinct T1.CLIRUT, T1.MANDANTE, T1.TELEFONO,
		CASE WHEN T2.RUT	is not null THEN 1 ELSE 0 END AS LNEGRO_CALL_R,
		CASE WHEN T3.FONO 	is not null THEN 1 ELSE 0 END AS LNEGRO_CALL_F,
		CASE WHEN T4.RUT 	is not null THEN 1 ELSE 0 END AS LNEGRO_CAR_R,
		CASE WHEN T5.RUT 	is not null THEN 1 ELSE 0 END AS LNEGRO_SMS_R,
		CASE WHEN T6.FONO 	is not null THEN 1 ELSE 0 END AS LNEGRO_SMS_F
FROM &libreria2..FONOS_FINAL_CAEN_X_FILT_&fechax0 t1 /*&VdatePeriodo2 T1 */
	LEFT JOIN PUBLICIN.LNEGRO_CALL 	T2 ON (T1.CLIRUT 	= T2.RUT)
	LEFT JOIN PUBLICIN.LNEGRO_CALL 	T3 ON (T1.TELEFONO 	= T3.FONO)
	LEFT JOIN PUBLICIN.LNEGRO_CAR 	T4 ON (T1.CLIRUT 	= T4.RUT)
	LEFT JOIN PUBLICIN.LNEGRO_SMS 	T5 ON (T1.CLIRUT 	= T5.RUT)
	LEFT JOIN PUBLICIN.LNEGRO_SMS 	T6 ON (T1.TELEFONO 	= T6.FONO)
;QUIT;

/*QUITA DUPLICADOS*/
proc sort data=FILTROS_APLICADOS out=FONOS_MOVIL_FINAL nodupkeys dupout=duplicados;
by CLIRUT;
run;

/*=========================================================================================*/
/*=========================================================================================*/
/* PASAR DESDE LIBRERÍA PERSONAL A PUBLICIN SIN EXCLUSIONES - quitando antes duplicados*/

proc sort data=&libreria2..REMANENTE_FINAL_SIN_FILTROS out=&libreria..FONOS_MOVIL_FINAL_SE nodupkeys dupout=duplicados_se;
by CLIRUT;
run;

PROC SQL;
CREATE INDEX CLIRUT ON &libreria..FONOS_MOVIL_FINAL_SE (CLIRUT);
QUIT;


/*---------------------------------------------------------------------------------------- */
/*------------------------------- EXCLUSIONES DE SMS ------------------------------------- */

DATA _null_;
datex0 = put(intnx('month',today(),0,'same'),yymmn6. );
datex1 = put(intnx('month',today(),-1,'same'),yymmn6. );
datex2 = put(intnx('month',today(),-2,'same'),yymmn6. );
Call symput("fechax0", datex0);
Call symput("fechax1", datex1);
Call symput("fechax2", datex2);

date0 = put(intnx('month',today(),0,'begin'),date9.) ;
Call symput("fecha0", date0);

RUN;
%put &fecha0;
%put &fechax0; 

/*SMS DEL MES ACTUAL*/
proc sql;
CREATE TABLE &libreria2..SP_SMS_&fechax0 as
		SELECT	
		  t1.fecha as TIME_SENT,
		  INPUT(substr(PUT(T1.movil,BEST.), 5,15),BEST.) AS TELEFONO,
		  'SMS' as TYPE_NUMBER,
		  'MT' as REQUEST,
		  T1.ESTADO AS STATUS
	FROM LIBCOMUN.output_SMS_&fechax0 t1 
	where t1.fecha >= "&fecha0:00:00:00"dt
;quit;

/*SMS DE LOS ULTIMOS 3 MESES*/
proc sql;
create table &libreria2..SP_SMS_X3_&fechax0 as
	select  * from &libreria2..SP_SMS_&fechax0
		outer union corr
	select  * from &libreria2..SP_SMS_&fechax1
		outer union corr
	select  * from &libreria2..SP_SMS_&fechax2		 
;quit;

/*FONO DE SMS NO ENTREGADOS*/
proc sql;
CREATE TABLE &libreria2..SP_SMS_FONOS_NO_ENTREGADOS as
SELECT a.TELEFONO FROM 
	(select distinct TELEFONO from &libreria2..SP_SMS_X3_&fechax0 
		where STATUS IN ('HORARIO INVA','OPERADOR INV','SERVICIO NO')) a
	left join 
	(select distinct TELEFONO from &libreria2..SP_SMS_X3_&fechax0
		where STATUS = 'SMS ENVIADOS') b
	on a.TELEFONO=b.TELEFONO

	where b.TELEFONO IS NULL
;quit;

/*EXCLUIR FONOS NO ENTREGADOS DEL FINAL */
PROC SQL;
   CREATE TABLE &libreria2..FONOS_MOVIL_FINAL AS 
   SELECT T1.*
      FROM FONOS_MOVIL_FINAL T1 LEFT JOIN &libreria2..SP_SMS_FONOS_NO_ENTREGADOS T2
	  	ON (T1.TELEFONO = T2.TELEFONO) where T2.TELEFONO IS MISSING
;QUIT;

/*------------------------------- EXCLUSIONES DE SMS ------------------------------------- */
/*---------------------------------------------------------------------------------------- */

PROC SQL;
CREATE INDEX CLIRUT ON &libreria2..FONOS_MOVIL_FINAL (CLIRUT);
QUIT;

/*=========================================================================================*/
/*=========================================================================================*/
/* PASAR DESDE LIBRERÍA PERSONAL A PUBLICIN */
PROC SQL;
   CREATE TABLE &libreria..FONOS_MOVIL_FINAL AS 
   SELECT *
      FROM &libreria2..FONOS_MOVIL_FINAL
;
QUIT;

PROC SQL;
CREATE INDEX CLIRUT ON &libreria..FONOS_MOVIL_FINAL (CLIRUT);
QUIT;


/*ESTADÍSTICAS DEL SCORE*/
proc sql;
CREATE TABLE &libreria2..NOTA_RANK_FONOS_MOVIL_&fechax0 AS 
	select
		t1.*,
        case when t2.CLIRUT IS NOT NULL		then 1		else 0 end AS  	R_BOPERS,
        case when t3.CLIRUT IS NOT NULL		then 1		else 0 end AS  	R_REP_TEL,
		case when t4.TELEFONO IS NOT NULL	then 1		else 0 end AS  	F_DUP_MEN2,
		case when t4.TELEFONO IS NULL		then 1		else 0 end AS  	F_DUP_MAY2,
		case when t5.CLIRUT IS NOT NULL		then 1		else 0 end AS  	R_FIN_SIN_FIL,
		case when t6.CLIRUT IS NOT NULL		then 1		else 0 end AS  	R_FIN_CON_FIL,
		case when t7.TELEFONO IS NOT NULL	then 1		else 0 end AS  	F_NO_SMS
		FROM &libreria2..FONOS_MOVIL_PRE_FINAL	t1
				LEFT JOIN &libreria2..FONOS_SMS_MEJOR_BOPERS_&fechax0 	T2 
					ON (t1.CLIRUT = t2.CLIRUT)
				LEFT JOIN &libreria2..FONOS_MOVIL_FINAL_REP_OK			T3
					ON (t1.CLIRUT = t3.CLIRUT)
				LEFT JOIN veces					T4
					ON (t1.TELEFONO = T4.TELEFONO)
				LEFT JOIN &libreria2..REMANENTE_FINAL_SIN_FILTROS		T5
					ON (t1.CLIRUT = t5.CLIRUT)
				LEFT JOIN &libreria2..FONOS_MOVIL_FINAL					T6
					ON (t1.CLIRUT = t6.CLIRUT)
				LEFT JOIN &libreria2..SP_SMS_FONOS_NO_ENTREGADOS			T7
					ON (t1.TELEFONO = T7.TELEFONO)

;QUIT;

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================        EXPORT_TO_AWS - INI          ===============================*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_ctbl_fonos_movil_final,raw,sasdata,0);

/*Exportación a AWS*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_ctbl_fonos_movil_final,publicin.FONOS_MOVIL_FINAL,raw,sasdata,0);

/*==============================        EXPORT_TO_AWS - END          ===============================*/
/*==================================================================================================*/

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
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
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
CC = ("&DEST_1", "&DEST_2", "&DEST_2")
SUBJECT = ("MAIL_AUTOM: Proceso CONTACTABILIDAD FONOS MOVILES");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "  Proceso CONTACTABILIDAD FONOS MOVILES, ejecutado con fecha: &fechaeDVN";  
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 10'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
