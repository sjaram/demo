/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROC_CONTACT_FONOS_FIJOS	================================*/
/* CONTROL DE VERSIONES
/* 2020-06-23 ----	Se soluciona respaldo de periodo actual (-1 por 0 en macro fecha inicial)
					Se quitan respaldos Diarios
					Validados Filtros Libros Negros ya estaban aplicados
*/
/*==================================================================================================*/

/*=========================================================================================*/
/* CONTACTABILIDAD - TABLA FONOS_FIJOS_FINAL */
/*=========================================================================================*/

DATA _null_;
datex0 = put(intnx('month',today(),0,'same'),yymmn6. );
Call symput("fechax0", datex0);

run;
/*Respaldar versión anterior*/
DATA _null_;
/* Variables Fechas de Ejecución */
datePeriodo1	= compress(substr(put(today(),ddmmyy10.),7,4)||substr(put(today(),ddmmyy10.),4,2)||substr(put(today(),ddmmyy10.),1,2));
Call symput("VdatePeriodo1", datePeriodo1);

datePeriodo2	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.);
Call symput("VdatePeriodo2", datePeriodo2);

RUN;
%put &VdatePeriodo1;
%put &VdatePeriodo2; 

/*=========================================================================================*/
/*	1.- SE EXTRAE NOTA MAXIMA DE FONOS - DESDE REPOSITORIO_TELEFONOS */
PROC SQL;
   CREATE TABLE MAXIMO_FIJO AS 
   SELECT t1.RUT, 
            (MAX(t1.NOTA)) AS NOTA
      FROM PUBLICIN.REPOSITORIO_TELEFONOS t1
      WHERE t1.NOTA >= 0 AND t1.TELEFONO < 900000000
      GROUP BY t1.RUT;
QUIT;


/*=========================================================================================*/
/*	2.- SE EXTRAEN FONOS FIJOS - DESDE REPOSITORIO_TELEFONOS */
PROC SQL;
   CREATE TABLE FONOS_FIJO AS 
   SELECT DISTINCT t1.RUT AS CLIRUT, 
                      case when t1.TELEFONO <300000000 then 
                   COMPRESS(PUT( Floor(t1.TELEFONO/100000000),BEST.))
				   else COMPRESS(PUT( Floor(t1.TELEFONO/10000000),BEST.))
                   end as AREA, 
                   case when t1.TELEFONO <300000000 then 
                   COMPRESS(PUT(t1.TELEFONO-100000000* Floor(t1.TELEFONO/100000000),BEST.))
				   else COMPRESS(PUT(t1.TELEFONO-Floor(t1.TELEFONO/10000000)*10000000,BEST.))
                   end as TELEFONO, 
                   t1.FECHA AS FECHA_ULT_ACTUALIZACION, 
                   t1.NOTA,
                   FUENTE AS MANDANTE
      FROM PUBLICIN.REPOSITORIO_TELEFONOS t1
                    INNER JOIN MAXIMO_fijo T2
                                            ON (t1.RUT=t2.RUT AND t1.NOTA=t2.NOTA)
      WHERE t1.NOTA >= 0 AND t1.TELEFONO < 900000000

;QUIT;


/*=========================================================================================*/
/*	3.- BUSCAR EN BOPERS TODOS LOS FONOS PARTICULARES Y LABORALES */
LIBNAME BOPERS ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=BOPERS_ADM  USER='SAS_USR_BI' PASSWORD='SAS_23072020';

PROC SQL;
   CREATE TABLE PARTICULARES AS 
   SELECT  t1.PEMFO_COC_ARA_FON, 
          COMPRESS(PUT(t1.PEMFO_NRO_FON,BEST.)) AS PEMFO_NRO_FON
      FROM BOPERS.BOPERS_MAE_FON t1
       WHERE t1.PEMFO_COD_TIP_FON=1 
	   ;QUIT;

PROC SQL;
   CREATE TABLE LABORALES AS 
   SELECT  t1.PEMFO_COC_ARA_FON, 
          COMPRESS(PUT(t1.PEMFO_NRO_FON,BEST.)) AS PEMFO_NRO_FON
      FROM BOPERS.BOPERS_MAE_FON t1
       WHERE t1.PEMFO_COD_TIP_FON=2 
	   ;QUIT;
/*	FIN 3.- BUSCAR EN BOPERS TODOS LOS FONOS PARTICULARES Y LABORALES */
/*=========================================================================================*/


/*=========================================================================================*/
/*4.- Con el mejor fono fijo del Repositorio, lo cruzo con BOPERS para identificar si es PA, LB o RF*/
PROC SQL;
	CREATE TABLE FONOS_FIJOS_FINAL_SFSLN AS
	SELECT T1.CLIRUT,
	       input(T1.AREA,best.) as AREA, 
       	   input(T1.TELEFONO,best.) as TELEFONO,
		   T1.FECHA_ULT_ACTUALIZACION,
		   T1.NOTA,
		   T1.MANDANTE,
		   CASE WHEN COMPRESS(T1.AREA||T1.TELEFONO) IN (SELECT COMPRESS(PEMFO_COC_ARA_FON||T2.PEMFO_NRO_FON) FROM PARTICULARES T2) THEN 'PA' 
		        WHEN COMPRESS(T1.AREA||T1.TELEFONO) IN (SELECT COMPRESS(PEMFO_COC_ARA_FON||T2.PEMFO_NRO_FON) FROM LABORALES T2) THEN 'LA' 

ELSE 'RF' END AS TIPO
		FROM WORK.FONOS_FIJO T1 
;QUIT;

PROC SQL;
CREATE TABLE FILTROS_APLICADOS AS
SELECT t1.CLIRUT, 
       T1.AREA as AREA, 
       T1.TELEFONO as TELEFONO, 
       t1.FECHA_ULT_ACTUALIZACION, 
       t1.NOTA, 
       t1.MANDANTE, 
       t1.TIPO
FROM FONOS_FIJOS_FINAL_SFSLN T1
	WHERE T1.CLIRUT 	NOT IN (SELECT T2.RUT 	FROM PUBLICIN.LNEGRO_CALL T2)
		AND T1.TELEFONO NOT IN (SELECT T2.FONO 	FROM PUBLICIN.LNEGRO_CALL T2)
		AND T1.CLIRUT 	NOT IN (SELECT T3.RUT 	FROM PUBLICIN.LNEGRO_CAR T3)
		AND T1.CLIRUT 	NOT IN (SELECT T4.RUT 	FROM PUBLICIN.LNEGRO_SMS T4)
		AND T1.TELEFONO NOT IN (SELECT T4.FONO 	FROM PUBLICIN.LNEGRO_SMS T4)
;QUIT;

/*solo control*/
PROC SQL;
CREATE TABLE RESULT.FONOS_FINAL_CAEN_FILT_F as /*&VdatePeriodo2 AS*/
	SELECT t1.CLIRUT, 
       T1.AREA as AREA, 
       T1.TELEFONO as TELEFONO, 
       t1.FECHA_ULT_ACTUALIZACION, 
       t1.NOTA, 
       t1.MANDANTE, 
       t1.TIPO
		FROM FONOS_FIJOS_FINAL_SFSLN T1 
		WHERE 	T1.CLIRUT 	NOT IN (SELECT T2.CLIRUT	FROM FILTROS_APLICADOS T2)
			AND	T1.TELEFONO NOT IN (SELECT T2.TELEFONO	FROM FILTROS_APLICADOS T2)	
;QUIT;

PROC SQL;
CREATE TABLE FONOS_FINAL_CAEND_FILT_F_&fechax0 as /*&VdatePeriodo2 AS*/
	SELECT distinct T1.CLIRUT, T1.MANDANTE, T1.TELEFONO,
		CASE WHEN T2.RUT 	is not null THEN 1 ELSE 0 END AS LNEGRO_CALL_R,
		CASE WHEN T3.FONO 	is not null THEN 1 ELSE 0 END AS LNEGRO_CALL_F,
		CASE WHEN T4.RUT 	is not null THEN 1 ELSE 0 END AS LNEGRO_CAR_R,
		CASE WHEN T5.RUT 	is not null THEN 1 ELSE 0 END AS LNEGRO_SMS_R,
		CASE WHEN T6.FONO 	is not null THEN 1 ELSE 0 END AS LNEGRO_SMS_F
FROM RESULT.FONOS_FINAL_CAEN_FILT_F t1 /*&VdatePeriodo2 T1 */
	LEFT JOIN PUBLICIN.LNEGRO_CALL 	T2 ON (T1.CLIRUT 	= T2.RUT)
	LEFT JOIN PUBLICIN.LNEGRO_CALL 	T3 ON (T1.TELEFONO 	= T3.FONO)
	LEFT JOIN PUBLICIN.LNEGRO_CAR 	T4 ON (T1.CLIRUT 	= T4.RUT)
	LEFT JOIN PUBLICIN.LNEGRO_SMS 	T5 ON (T1.CLIRUT 	= T5.RUT)
	LEFT JOIN PUBLICIN.LNEGRO_SMS 	T6 ON (T1.TELEFONO 	= T6.FONO)
;QUIT;

/*QUITA DUPLICADOS*/
proc sort data=FILTROS_APLICADOS out=FONOS_FIJOS_FINAL nodupkeys dupout=duplicados_fijos;
by CLIRUT;
run;

PROC SQL;
CREATE INDEX CLIRUT ON RESULT.FONOS_FIJOS_FINAL (CLIRUT);
QUIT;

/*=========================================================================================*/
/*=========================================================================================*/
/* PASAR DESDE LIBRERÍA PERSONAL A PUBLICIN */
PROC SQL;
   CREATE TABLE PUBLICIN.FONOS_FIJOS_FINAL AS 
   SELECT *
      FROM FONOS_FIJOS_FINAL
;
QUIT;

PROC SQL;
CREATE INDEX CLIRUT ON PUBLICIN.FONOS_FIJOS_FINAL (CLIRUT);
QUIT;

/*=========================================================================================*/
/*=========================================================================================*/
/* PASAR DESDE LIBRERÍA PERSONAL A PUBLICIN SIN EXCLUSIONES */

proc sort data=FONOS_FIJOS_FINAL_SFSLN out=FONOS_FIJOS_FINAL_SFSLN nodupkeys dupout=duplicados_fijos_se;
by CLIRUT;
run;

PROC SQL;
   CREATE TABLE PUBLICIN.FONOS_FIJOS_FINAL_SE AS 
   SELECT *
      FROM FONOS_FIJOS_FINAL_SFSLN
;
QUIT;

PROC SQL;
CREATE INDEX CLIRUT ON PUBLICIN.FONOS_FIJOS_FINAL_SE (CLIRUT);
QUIT;


