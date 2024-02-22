/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	EMAIL_AUTOM_REFACTOR 		================================*/
/* CONTROL DE VERSIONES
/* 2023-02-08 ---- v31 -- Andrea S. -- Se agrega filtro email not LIKE	('.%') en línea 1523 para excluir correos que inicien con punto.
/* 2022-12-20 ---- v30 -- Andrea S. -- Se agrega función compress para eliminar espacios en correos obtenidos desde FISA/CAÑON.
/* 2022-11-29 ---- v29 -- David V.  -- Se actualiza export to aws, desde publicin para actualización diaria.
/* 2022-11-04 ---- v28 -- Sergio J. -- Se modifica filtro de and por OR en limpieza de inicio_correo.
									   Agregamos exportación a AWS y el campo periodo .
/* 2022-10-24 ---- v27 -- David V.  -- Corrección mínima agregar un _SE y versión del mail de salida.
/* 2022-10-24 ---- v26 -- Andrea S. -- Se crea base email informativo (sin exclusiones por rebote duro ni suprimidos)
/* 2022-09-12 ---- v25 -- Sergio J. -- Optimización sp_suppressed
/* 2022-09-12 ---- v24 -- Sergio J. -- Cambios finales a la Refactorización del proceso email dejando las librerías originales
/* 2022-08-09 ---- v23 -- Andrea S. -- Refactorización proceso email 
/* 2022-07-05 ---- v22 -- David V.	-- Se comenta parte del código, filtro email not LIKE	('% %') 
/* 2022-04-27 ---- v21 -- David V.	-- Actualizar código para que la nota 0 quede en la tabla final, y no se vea vacío al igual que aperturas.
/* 2022-04-04 ---- v20 -- Esteban P.-- Se actualizan correos: Se reemplaza a Pía Olavarría por "PM_CONTACTABILIDAD".
*/
/*==================================================================================================*/

*  ====================================================================
*  Nombre del proceso almacenado: EMAIL_AUTOMATICO_3.0 - PARTE 1
*  ====================================================================
*;

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

DATA _null_;
/* DECLARACIÓN VARIABLES FECHAS*/
dateDIA	= compress(substr(put(today(),ddmmyy10.),7,4)||substr(put(today(),ddmmyy10.),4,2)||substr(put(today(),ddmmyy10.),1,2));
Call symput("VdateDIA", dateDIA);

dateMES	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
Call symput("VdateMES", dateMES);

RUN;
%put &VdateDIA;
%put &VdateMES; 


/*	VARIABLE LIBRERÍA			*/
%let libreria  = RESULT;



/*=========================================================================================*/
/*======	Respaldo tabla Anterior de Emails		=======================================*/
/*=========================================================================================*/

proc sql;
	create table RESULT.BASE_TRABAJO_EMAIL_&VdateMES AS
		SELECT * FROM PUBLICIN.BASE_TRABAJO_EMAIL
;quit;



/*proc sql;
	create table RESULT.BASE_TRABAJO_EMAIL_&VdateDIA AS
		SELECT * FROM PUBLICIN.BASE_TRABAJO_EMAIL as T1
;quit;*/

/*PROC SQL;
CREATE INDEX RUT ON RESULT.BASE_TRABAJO_EMAIL_&VdateDIA  (RUT);
QUIT;*/

/*proc sql;
	create table RESULT.NOTA_RANK_NEW_&VdateDIA AS
		SELECT * FROM result.NOTA_RANK_NEW_2020
;quit;*/

proc sql;
	create table RESULT.NOTA_RANK_NEW_&VdateMES AS
		SELECT * FROM result.NOTA_RANK_NEW_2020
;quit;

/*=========================================================================================*/
/*======	1.- Obtener Emails desde: las TEFs		=======================================*/
/*=========================================================================================*/
%let mz_connect_BANCO=CONNECT TO ORACLE as BANCO(USER='RIPLEYC' PASSWORD='ri99pley'
PATH="(DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP) (Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SERVICE_NAME = ripleyc)(SERVER = DEDICATED)))"); 

proc sql; 
	&mz_connect_BANCO; 
		create table &libreria..R_TEFs as 
			select	 MTIFO_RUN_CLI_ORE as rut, 
			         COMPRESS(UPCASE(MTIFO_NOM_MAI_ORE)) as email length=50,
					 input(put(datepart(MTIFO_FCH_ING_TRS),yymmddn8.),best.) as FECHA_ACT
			from	connection to BANCO(
										select *
										from BOTEF_ADM.BOTEF_MOV_TRN_IFO 
										where MTIFO_FLG_EST_TRS = 2 /*TRXs correcta*/
									  ) as C2_Emisor
			WHERE 	MTIFO_NOM_MAI_ORE IS NOT NULL
;QUIT;

PROC SQL;
   CREATE TABLE &libreria..R_CORREOS_TEF_MAX AS 
   SELECT distinct t1.RUT, 
          t1.email 	AS EMAIL, 
          MAX(t1.FECHA_ACT) AS FECHA_ACT
      FROM &libreria..R_TEFs t1
      GROUP BY t1.rut;
QUIT;

proc sql;
create table SEPARACION_CORREO as
select
RUT,  
EMAIL, 
scan(EMAIL,1,"@") as inicio_correo,
scan(EMAIL,2,"@") as dominio,
FECHA_ACT
from &libreria..R_CORREOS_TEF_MAX
order by 1;
quit;

/*Tomar el registro de fecha máxima de TEFs*/
proc sql;
create table &libreria..BASE_EMAIL_TEFs AS
	SELECT	DISTINCT T1.RUT, 
	        T1.EMAIL, 	      
			t2.FECHA_ACT
	    FROM SEPARACION_CORREO t1 INNER JOIN &libreria..R_TEFs T2
			ON (T1.RUT = T2.RUT AND T1.FECHA_ACT = T2.FECHA_ACT AND T1.EMAIL = T2.EMAIL)
		WHERE T2.FECHA_ACT IS NOT MISSING AND T2.RUT < 99999999 AND T2.RUT > 10000
		AND dominio not in (select dominio from &libreria..DOMINIO_INCORRECTOS_UNIF) 
		OR inicio_correo not in (select inicio_correo from &libreria..INICIO_CORREO_INCORRECTOS_UNIF)
;
QUIT;

proc sql;
	create table &libreria..BASE_EMAIL_TEFs as
		select *
			from &libreria..BASE_EMAIL_TEFs t1
				where t1.email 
					not LIKE ('.-%') AND t1.email not LIKE ('%.')
					AND t1.email not LIKE ('-%')				AND t1.email not LIKE	('%.@%')
					AND t1.email not CONTAINS	('(')			AND t1.email not CONTAINS 	(')')
					AND t1.email not CONTAINS	('/')			AND t1.email not CONTAINS	('?')
					AND t1.email <>'@'							AND t1.email <>'0' 
					AND t1.email CONTAINS 	('@')
;quit;


PROC SQL;
CREATE INDEX rut ON &libreria..BASE_EMAIL_TEFs (RUT);
QUIT;

/*Eliminar tablas de Paso de TEFs*/
PROC SQL;
/*	DROP TABLE RESULT.R_TEFs;*/
	DROP TABLE &libreria..R_CORREOS_TEF_MAX;
;QUIT;

/*=========================================================================================*/
/*======	2.- Obtener Emails desde: FISA y CAÑON	=======================================*/
/*=========================================================================================*/
PROC SQL; 

	CONNECT TO ORACLE AS GESTION (PATH="QANEW.WORLD" USER='ripleyc' PASSWORD='ri99pley');
	CREATE TABLE BASE_EMAIL_FISA_CANON AS 
		SELECT input(rut,best.) as RUT, 
		COMPRESS(UPCASE(EMAIL)) AS EMAIL length=50, 
		scan(EMAIL,1,"@") as inicio_correo,
		scan(EMAIL,2,"@") as dominio, 
		FECHA_ACTUALIZACION, 
		SEQUENCIA, 
		ORIGEN 
			FROM CONNECTION TO GESTION(
			select distinct 
					(substr(c.cli_identifica, 1, length(c.cli_identifica) - 1)) rut,
			       	a.dir_direccion || a.dir_direccion2 || a.dir_direccion3 email,
			       	a.dir_fecver fecha_ACTUALIZACION,
					to_number(7) SEQUENCIA,
			        'FISA' origen
			  	from tcli_direccion a,
			       tcli_persona c
				where a.dir_codcli = c.cli_codigo
				   and dir_tipodir in(6,4)
				   and a.dir_direccion is not null
				   and to_number(substr(c.cli_identifica, 1, length(c.cli_identifica) - 1))>1000000
			union
			select TO_CHAR(rut) RUT,
			        direccion email, 
			        fecha_carga fecha_ACTUALIZACION,
			        to_number(8) SEQUENCIA,
			        'CANON BCO' ORIGEN
			  from br_dm_direccion_cliente
			where tipodir in (4,6)
			   and direccion is not null
			)A
;QUIT;


proc sql;
	create table BASE_EMAIL_FISA_CANON as
		select *
			from BASE_EMAIL_FISA_CANON t1
			WHERE dominio not in (select dominio from &libreria..DOMINIO_INCORRECTOS_UNIF) 
OR inicio_correo not in (select inicio_correo from &libreria..INICIO_CORREO_INCORRECTOS_UNIF)
;quit;

proc sql;
	create table BASE_EMAIL_FISA_CANON_2 as
		select *
			from BASE_EMAIL_FISA_CANON t1
				where t1.email 
					not LIKE ('.-%') AND t1.email not LIKE ('%.')
					AND t1.email not LIKE ('-%')				AND t1.email not LIKE	('%.@%')
					AND t1.email not CONTAINS	('(')			AND t1.email not CONTAINS 	(')')
					AND t1.email not CONTAINS	('/')			AND t1.email not CONTAINS	('?')
					AND t1.email <>'@'							AND t1.email <>'0' 
					AND t1.email CONTAINS 	('@')
;quit;


/*Eliminar tablas de Paso de TEFs*/
PROC SQL;
CREATE TABLE BASE_EMAIL_FISA AS
   	SELECT 	t7.rut, 
          	t7.EMAIL length=50, 
			input(put(datepart(t7.FECHA_ACTUALIZACION),yymmddn8.),best.) as FECHA_ACT,
            t7.sequencia,
            t7.ORIGEN
 	FROM BASE_EMAIL_FISA_CANON t7
	WHERE t7.sequencia = 7
;QUIT;

PROC SQL;
   CREATE TABLE R_CORREOS_FISA_MAX AS 
   SELECT distinct t1.RUT, 
          t1.email 	AS EMAIL, 
          MAX(t1.FECHA_ACT) AS FECHA_ACT
      FROM BASE_EMAIL_FISA t1
      GROUP BY t1.rut;
QUIT;

proc sql;
create table &libreria..BASE_EMAIL_FISA AS
	SELECT	DISTINCT T1.RUT, 
	        T1.EMAIL, 	      
			t2.FECHA_ACT,
			t2.sequencia,
            t2.ORIGEN
	    FROM R_CORREOS_FISA_MAX t1 INNER JOIN BASE_EMAIL_FISA T2
			ON (T1.RUT = T2.RUT AND T1.FECHA_ACT = T2.FECHA_ACT AND T1.EMAIL = T2.EMAIL)
		WHERE T2.FECHA_ACT IS NOT MISSING AND T2.RUT < 99999999 AND T2.RUT > 10000
;QUIT;

PROC SQL;
CREATE TABLE BASE_EMAIL_CANON AS
   	SELECT 	t8.rut, 
          	t8.EMAIL length=50, 
			input(put(datepart(t8.FECHA_ACTUALIZACION),yymmddn8.),best.) as FECHA_ACT,
            t8.sequencia,
            t8.ORIGEN
 	FROM BASE_EMAIL_FISA_CANON t8
	WHERE t8.sequencia = 8
;QUIT;

PROC SQL;
   CREATE TABLE R_CORREOS_CANON_MAX AS 
   SELECT distinct t1.RUT, 
          t1.email 	AS EMAIL, 
          MAX(t1.FECHA_ACT) AS FECHA_ACT
      FROM BASE_EMAIL_CANON t1
      GROUP BY t1.rut;
QUIT;

proc sql;
create table &libreria..BASE_EMAIL_CANON AS
	SELECT	DISTINCT T1.RUT, 
	        T1.EMAIL, 	      
			t2.FECHA_ACT,
			t2.sequencia,
            t2.ORIGEN
	    FROM R_CORREOS_CANON_MAX t1 INNER JOIN BASE_EMAIL_CANON T2
			ON (T1.RUT = T2.RUT AND T1.FECHA_ACT = T2.FECHA_ACT AND T1.EMAIL = T2.EMAIL)
		WHERE T2.FECHA_ACT IS NOT MISSING AND T2.RUT < 99999999 AND T2.RUT > 10000
;QUIT;

PROC SQL;
	DROP TABLE BASE_EMAIL_FISA_CANON;
	DROP TABLE BASE_EMAIL_FISA;
	DROP TABLE R_CORREOS_FISA_MAX;
	DROP TABLE BASE_EMAIL_CANON;
	DROP TABLE R_CORREOS_CANON_MAX;
;QUIT;

PROC SQL;
CREATE INDEX rut ON &libreria..BASE_EMAIL_FISA (RUT);
QUIT;

PROC SQL;
CREATE INDEX rut ON &libreria..BASE_EMAIL_CANON (RUT);
QUIT;

/*=========================================================================================*/
/*======	3.- Obtener Emails desde: BOPERS todos los que no estén dados de baja	=======*/
/*=========================================================================================*/
LIBNAME R_bopers ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=BOPERS_ADM  USER='SAS_USR_BI' PASSWORD='SAS_23072020';
PROC SQL; 
   CREATE TABLE &libreria..R_BOPERS_TOTALES2 AS 
   SELECT	DISTINCT input(ide.PEMID_GLS_NRO_DCT_IDE_K,best.)	AS RUT,
   			ide.pemid_nro_inn_ide			AS IDINTERNO,
			dml.PEMDM_NRO_SEQ_DML_K 		AS SEQ_ID,
           	compress(upcase(t2.PEMMA_GLS_DML_MAI)) 		AS EMAIL length=50,
			scan(PEMMA_GLS_DML_MAI,1,"@") as inicio_correo,
			scan(PEMMA_GLS_DML_MAI,2,"@") as dominio,
			input(put(datepart(t2.PEMMA_FCH_FIN_ACL),yymmddn8.),best.) AS FECHA_ACT,
			t2.PEMMA_COD_EST_LCL 			AS ESTADO_ACT_VER,
            (t2.PEMMA_NRO_SEQ_MAI_K) 		AS SEQUENCIA,
			CASE 	WHEN t2.PEMMA_GLS_USR_FIN_ACL = 'HB-APP'	then 'BOPERS_HB'
					WHEN t2.PEMMA_GLS_USR_FIN_ACL = 'APP' 		then 'BOPERS_APP' 
					WHEN t2.PEMMA_GLS_USR_FIN_ACL = 'PWA' 		then 'BOPERS_PWA'
					ELSE 'BOPERS_CCSS' END as ORIGEN
		FROM	r_BOPERS.BOPERS_MAE_IDE ide, 		r_BOPERS.bopers_mae_dml dml, 
				r_BOPERS.bopers_rel_ing_lcl lcl, 	r_BOPERS.BOPERS_MAE_MAI t2
		   WHERE 	t2.PEMMA_COD_EST_LCL NOT = 6 
		   and		lcl.peril_cod_tip_lcl_dos_k = 4 and
					lcl.peril_cod_tip_lcl_uno_k = 1 and
					lcl.peril_nro_seq_lcl_uno_k = dml.PEMDM_NRO_SEQ_DML_K and
					lcl.pemid_nro_inn_ide_k=ide.pemid_nro_inn_ide and
					dml.pemid_nro_inn_ide_k=ide.pemid_nro_inn_ide and
					dml.PEMDM_COD_DML_PPA=1 and
					dml.pemdm_cod_tip_dml = 1 and
					dml.pemdm_cod_neg_dml = 1 and
					t2.PEMID_NRO_INN_IDE_K = ide.pemid_nro_inn_ide and
					t2.PEMMA_NRO_SEQ_MAI_K = lcl.PERIL_NRO_SEQ_LCL_DOS_K
			ORDER BY 1
;QUIT;

PROC SQL;
   CREATE TABLE &libreria..R_BOPERS_TOTALES_EMAIL AS 
   SELECT	t1.*
		FROM	&libreria..R_BOPERS_TOTALES2 t1 left join POLAVARR.CORREOS_FAKE_V2 t2
				ON (T1.EMAIL = T2.EMAIL) 
		WHERE T2.EMAIL IS MISSING
		AND dominio not in (select dominio from &libreria..DOMINIO_INCORRECTOS_UNIF) 
OR inicio_correo not in (select inicio_correo from &libreria..INICIO_CORREO_INCORRECTOS_UNIF)
;
QUIT;

proc sql;
	create table &libreria..R_BOPERS_TOTALES_EMAIL as
		select *
			from &libreria..R_BOPERS_TOTALES_EMAIL t1
				where t1.email 
					not LIKE ('.-%') AND t1.email not LIKE ('%.')
					AND t1.email not LIKE ('-%')				AND t1.email not LIKE	('%.@%')
					AND t1.email not CONTAINS	('(')			AND t1.email not CONTAINS 	(')')
					AND t1.email not CONTAINS	('/')			AND t1.email not CONTAINS	('?')
					AND t1.email <>'@'							AND t1.email <>'0' 
					AND t1.email CONTAINS 	('@')
;quit;


PROC SQL;
CREATE INDEX rut ON &libreria..R_BOPERS_TOTALES_EMAIL (RUT);
QUIT;

/*=========================================================================================*/
/*======	4.- Obtener Emails desde: CNAVAR.RESPALDO_MAIL_DGC en buen formato	 ==========*/
/*=========================================================================================*/
proc sql;
create table R_DEPASO_CNAVARRO as
	select	x1.RUT,
     	upcase(x1.EMAIL) as EMAIL length=50,
		scan(EMAIL,1,"@") as inicio_correo,
		scan(EMAIL,2,"@") as dominio,
	  	x1.FECHA as FECHA_ACTUALIZACION,
		input(put(x1.FECHA,yymmddn8.),best.) as FECHAN,
		6 AS sequencia,
	  	'DGC' as ORIGEN,
		x1.INHIBIDO
	FROM CNAVAR.RESPALDO_MAIL_20181012 X1
;quit;

proc sql;
create table &libreria..R_EMAILS_CNAVARRO_DGC as
select	DISTINCT x1.RUT,
        x1.EMAIL,
		x1.FECHAN AS FECHA_ACT,
		sequencia,
	  	ORIGEN
	FROM R_DEPASO_CNAVARRO X1
	WHERE x1.RUT < 99999999 AND x1.RUT > 10000
		AND dominio not in (select dominio from &libreria..DOMINIO_INCORRECTOS_UNIF) 
		OR inicio_correo not in (select inicio_correo from &libreria..INICIO_CORREO_INCORRECTOS_UNIF)
;quit;

proc sql;
	create table &libreria..R_EMAILS_CNAVARRO_DGC as
		select *
			from &libreria..R_EMAILS_CNAVARRO_DGC t1
				where t1.email 
					not LIKE ('.-%') AND t1.email not LIKE ('%.')
					AND t1.email not LIKE ('-%')				AND t1.email not LIKE	('%.@%')
					AND t1.email not CONTAINS	('(')			AND t1.email not CONTAINS 	(')')
					AND t1.email not CONTAINS	('/')			AND t1.email not CONTAINS	('?')
					AND t1.email <>'@'							AND t1.email <>'0' 
					AND t1.email CONTAINS 	('@')
;quit;


PROC SQL;
	DROP TABLE R_DEPASO_CNAVARRO;
;QUIT;

PROC SQL;
CREATE INDEX rut ON &libreria..R_EMAILS_CNAVARRO_DGC (RUT);
QUIT;

/*=========================================================================================*/
/*======	5.- OBTENER DATOS DESDE LA APP - PROCESO DEFINITIVO		=======================*/
/*=========================================================================================*/

/*========	OBTENER DATOS DE APP DE BD HIS		================================================*/
PROC SQL;
   CREATE TABLE TMP_DEPASO_DATOS_APP_HIS AS 
   SELECT 	(INPUT(LEFT(SUBSTR(LEFT(COMPRESS(COMPRESS(t1.RUT,'.'),'-')),1,LENGTH(LEFT(COMPRESS(COMPRESS(t1.RUT,'.'),'-')))-1)),BEST.)) AS RUT,
   			COMPRESS(upcase(T1.email)) as EMAIL length=50,
			input(cat((SUBSTR(T1.FECHA_ULTIMO_LOGIN,1,4)),(SUBSTR(T1.FECHA_ULTIMO_LOGIN,6,2)),(SUBSTR(T1.FECHA_ULTIMO_LOGIN,9,2))) ,BEST10.) AS F_ULTIMO_CONTACT
      FROM result.DATOS_APP_HIST t1 WHERE t1.RUT IS NOT NULL
ORDER BY t1.RUT
;
QUIT;

/*Maxima fecha de ultimo login*/
proc sql;
create table TMP_DEPASO_APP_HIS_FMAX_CREACION AS
	SELECT	DISTINCT RUT, 
	        EMAIL, 
	        MAX(T1.F_ULTIMO_CONTACT) AS FECHA,
	        4 AS SEQUENCIA,
			'APP HIS' AS ORIGEN
	    FROM TMP_DEPASO_DATOS_APP_HIS t1
	GROUP BY RUT
;quit;

/*Tomar el registro de fecha máximo*/
proc sql;
create table TMP_DEPASO_APP_HIS_FMAX_UN_REG AS
	SELECT	DISTINCT T1.RUT, 
	        T1.EMAIL, 
	        T2.F_ULTIMO_CONTACT AS FECHA,
	        T1.SEQUENCIA,
			T1.ORIGEN
	    FROM TMP_DEPASO_APP_HIS_FMAX_CREACION t1 LEFT JOIN TMP_DEPASO_DATOS_APP_HIS T2
			ON (T1.RUT = T2.RUT AND T1.FECHA = T2.F_ULTIMO_CONTACT AND T1.EMAIL = T2.EMAIL)
		WHERE T2.F_ULTIMO_CONTACT IS NOT MISSING
;quit;

/*Convertir data anterior con fecha correspondiente*/
PROC SQL;
   CREATE TABLE TMP_DATOS_APP_HIS AS 
   SELECT 	T1.RUT,
   			T1.EMAIL,
			DHMS((MDY(INPUT(SUBSTR(PUT(T1.FECHA,BEST8.),5,2),BEST4.),
                  INPUT(SUBSTR(PUT(T1.FECHA,BEST8.),7,2),BEST4.),
                  INPUT(SUBSTR(PUT(T1.FECHA,BEST8.),1,4),BEST4.))),0,0,0) FORMAT=datetime20. AS FECHA_ACTUALIZACION,
			T1.SEQUENCIA,
			T1.ORIGEN
      FROM TMP_DEPASO_APP_HIS_FMAX_UN_REG t1 WHERE t1.RUT > 0
ORDER BY t1.RUT
;
QUIT;
/*========	FIN - OBTENER DATOS DE APP DE BD HIS		====================================*/

/*========	OBTENER DATOS DE APP DE BD DIARIO			====================================*/
PROC SQL;
   CREATE TABLE TMP_DEPASO_DATOS_APP_DIA_2 AS 
   SELECT 	reverse(substr(compress(reverse(t1.RUT)),2,length(t1.RUT)-1)) as rut_sin_dv,
   			COMPRESS(upcase(T1.email)) as EMAIL length=50,
			input(cat((SUBSTR(T1.UpdatedAt,1,4)),(SUBSTR(T1.UpdatedAt,6,2)),(SUBSTR(T1.UpdatedAt,9,2))) ,BEST10.) AS F_ULTIMO_CONTACT,
			input(cat((SUBSTR(T1.CreatedAt,1,4)),(SUBSTR(T1.CreatedAt,6,2)),(SUBSTR(T1.CreatedAt,9,2))) ,BEST10.) AS F_CREACION
      FROM &libreria..USER_INFO t1 
WHERE t1.RUT IS NOT NULL
ORDER BY t1.RUT
;
QUIT;

/*Convertir rut de alfanumerico a numérico*/
PROC SQL;
   CREATE TABLE TMP_DEPASO_DATOS_APP_DIA_3 AS 
   SELECT 	input(cat(t1.rut_sin_dv),best.) as RUT,
   			T1.EMAIL,
			T1.F_ULTIMO_CONTACT,
			T1.F_CREACION
      FROM TMP_DEPASO_DATOS_APP_DIA_2 t1 
ORDER BY RUT
;
QUIT;

/*Tomar fecha maxima de creación DIA*/
proc sql;
create table TMP_DATOS_APP_FMAX_CREACION AS
	SELECT	DISTINCT RUT, 
	        EMAIL, 
	        MAX(T1.F_CREACION) AS FECHA,
	        3 AS SEQUENCIA,
			'APP_USER_INFO' AS ORIGEN
	    FROM TMP_DEPASO_DATOS_APP_DIA_3 t1
	GROUP BY RUT
;quit;

/*Tomar fecha maxima de ultimo contacto DIA*/
proc sql;
create table TMP_DATOS_APP_FMAX_ULT_CONTACTO AS
SELECT	DISTINCT RUT, 
        EMAIL, 
        MAX(T1.F_ULTIMO_CONTACT) AS FECHA,
        3 AS SEQUENCIA,
		'APP' AS ORIGEN
    FROM TMP_DEPASO_DATOS_APP_DIA_3 t1
GROUP BY RUT
;quit;

/*FECHA MÁS RECIENTE YA SEA DE CREACIÓN O DE ULTIMO CONTACTO*/
PROC SQL;
CREATE TABLE TMP_DATOS_APP_FECHA_RECIENTE AS
SELECT DISTINCT T1.RUT,
		T1.EMAIL,
		CASE WHEN (T2.FECHA > T1.FECHA AND T2.FECHA IS NOT NULL) THEN T2.FECHA ELSE T1.FECHA END AS FECHA,
		T1.SEQUENCIA,
		T1.ORIGEN
	FROM TMP_DATOS_APP_FMAX_CREACION T1 LEFT JOIN TMP_DATOS_APP_FMAX_ULT_CONTACTO T2
		ON (T1.RUT = T2.RUT)
;QUIT;

/*CAMBIAR A FORMATO FECHA IGUAL A LOS DEMÁS PROCESOS*/
PROC SQL;
CREATE TABLE TMP_DATOS_APP_UNION_DIA AS
SELECT DISTINCT T1.RUT,
		T1.EMAIL,
		DHMS((MDY(INPUT(SUBSTR(PUT(t1.FECHA,BEST8.),5,2),BEST4.),
                  INPUT(SUBSTR(PUT(t1.FECHA,BEST8.),7,2),BEST4.),
                  INPUT(SUBSTR(PUT(t1.FECHA,BEST8.),1,4),BEST4.))),0,0,0) FORMAT=datetime20. AS FECHA_ACTUALIZACION,
		T1.SEQUENCIA,
		T1.ORIGEN
	FROM TMP_DATOS_APP_FECHA_RECIENTE T1
;QUIT;
/*========	FIN - OBTENER DATOS DE APP DE BD DIARIO		====================================*/

/*========	De la dos bases, el registro más actualizado	================================*/
/*LEFT JOIN*/
PROC SQL;
CREATE TABLE TMP_BASE_EMAIL_APP_UNION3 AS
SELECT 	DISTINCT T1.RUT,
		T1.EMAIL,
		CASE WHEN (T2.FECHA_ACTUALIZACION > T1.FECHA_ACTUALIZACION AND T2.FECHA_ACTUALIZACION IS NOT NULL) THEN T2.FECHA_ACTUALIZACION ELSE T1.FECHA_ACTUALIZACION END AS FECHA_ACTUALIZACION,
		T1.SEQUENCIA,
		T1.ORIGEN
	FROM TMP_DATOS_APP_UNION_DIA T1 left JOIN TMP_DATOS_APP_HIS T2
		ON (T1.RUT = T2.RUT)
;QUIT;

/*RIGHT JOIN*/
PROC SQL;
CREATE TABLE TMP_BASE_EMAIL_APP_UNION4 AS
SELECT 	DISTINCT T2.RUT,
		T2.EMAIL,
		CASE WHEN (T2.FECHA_ACTUALIZACION > T1.FECHA_ACTUALIZACION AND T2.FECHA_ACTUALIZACION IS NOT NULL) THEN T2.FECHA_ACTUALIZACION ELSE T1.FECHA_ACTUALIZACION END AS FECHA_ACTUALIZACION,
		T2.SEQUENCIA,
		T2.ORIGEN
	FROM TMP_DATOS_APP_UNION_DIA T1 RIGHT JOIN TMP_DATOS_APP_HIS T2
		ON (T1.RUT = T2.RUT) WHERE T1.RUT IS NULL
;QUIT;

/*PASAR LA FECHA DEL LEFT JOIN A FORMATO FECHA*/
PROC SQL;
CREATE TABLE TMP_BASE_EMAIL_APP_UNION5 AS
SELECT 	T1.RUT,
		T1.EMAIL,
		scan(EMAIL,1,"@") as inicio_correo,
		scan(EMAIL,2,"@") as dominio,
		t1.FECHA_ACTUALIZACION FORMAT=datetime20. AS FECHA_ACTUALIZACION,
		T1.SEQUENCIA,
		T1.ORIGEN
	FROM TMP_BASE_EMAIL_APP_UNION3 T1
order by FECHA_ACTUALIZACION
;QUIT;

/*PASAR LA FECHA DEL RIGHT JOIN A FORMATO FECHA*/
PROC SQL;
CREATE TABLE TMP_BASE_EMAIL_APP_UNION6 AS
SELECT 	T1.RUT,
		T1.EMAIL,
		scan(EMAIL,1,"@") as inicio_correo,
		scan(EMAIL,2,"@") as dominio,
		t1.FECHA_ACTUALIZACION FORMAT=datetime20. AS FECHA_ACTUALIZACION,
		T1.SEQUENCIA,
		T1.ORIGEN
	FROM TMP_BASE_EMAIL_APP_UNION4 T1
order by FECHA_ACTUALIZACION
;QUIT;

/*UNIR AMBOS RESULTADOS PARA OBTENER TODOS LOS REGISTROS MÁS ACTUALIZADOS DEL DIA Y HISTÓRICOS*/
PROC SQL;
CREATE TABLE BASE_EMAIL_APP_FINAL AS
	SELECT * FROM TMP_BASE_EMAIL_APP_UNION5
UNION ALL
	SELECT * FROM TMP_BASE_EMAIL_APP_UNION6
;QUIT;

PROC SQL;
CREATE TABLE &libreria..BASE_EMAIL_APP_FINAL AS
	SELECT T1.RUT,
		T1.EMAIL,
		input(put(datepart(t1.FECHA_ACTUALIZACION),yymmddn8.),best.) as FECHA_ACT,
		T1.SEQUENCIA,
		T1.ORIGEN 
	FROM BASE_EMAIL_APP_FINAL t1
	WHERE T1.RUT < 99999999 AND T1.RUT > 10000 AND T1.RUT IS NOT MISSING
		AND dominio not in (select dominio from &libreria..DOMINIO_INCORRECTOS_UNIF) 
		OR inicio_correo not in (select inicio_correo from &libreria..INICIO_CORREO_INCORRECTOS_UNIF)
;QUIT;

proc sql;
	create table &libreria..BASE_EMAIL_APP_FINAL as
		select *
			from &libreria..BASE_EMAIL_APP_FINAL t1
				where t1.email 
					not LIKE ('.-%') AND t1.email not LIKE ('%.')
					AND t1.email not LIKE ('-%')				AND t1.email not LIKE	('%.@%')
					AND t1.email not CONTAINS	('(')			AND t1.email not CONTAINS 	(')')
					AND t1.email not CONTAINS	('/')			AND t1.email not CONTAINS	('?')
					AND t1.email <>'@'							AND t1.email <>'0' 
					AND t1.email CONTAINS 	('@')
;quit;

PROC SQL;
CREATE INDEX rut ON &libreria..BASE_EMAIL_APP_FINAL (RUT);
QUIT;

/*Eliminar tablas temporales*/
PROC SQL;
	DROP TABLE WORK.TMP_BASE_EMAIL_APP_UNION3;
	DROP TABLE WORK.TMP_BASE_EMAIL_APP_UNION4;
	DROP TABLE WORK.TMP_BASE_EMAIL_APP_UNION5;
	DROP TABLE WORK.TMP_BASE_EMAIL_APP_UNION6;
	DROP TABLE WORK.TMP_DATOS_APP_FECHA_RECIENTE;
	DROP TABLE WORK.TMP_DATOS_APP_FMAX_CREACION;
	DROP TABLE WORK.TMP_DATOS_APP_FMAX_ULT_CONTACTO;
	DROP TABLE WORK.TMP_DATOS_APP_HIS;
	DROP TABLE WORK.TMP_DATOS_APP_UNION_DIA;
	DROP TABLE WORK.TMP_DEPASO_APP_HIS_FMAX_CREACION;
	DROP TABLE WORK.TMP_DEPASO_APP_HIS_FMAX_UN_REG;
	DROP TABLE WORK.TMP_DEPASO_DATOS_APP_DIA_2;
	DROP TABLE WORK.TMP_DEPASO_DATOS_APP_DIA_3;
	DROP TABLE WORK.TMP_DEPASO_DATOS_APP_HIS;
;QUIT;
/*======	FIN 5.- OBTENER DATOS DESDE LA APP - PROCESO DEFINITIVO		===================*/
/*=========================================================================================*/

/*=========================================================================================*/
/*======	6.- Une Email de todos los Orígenes	actuales		===========================*/
/*======		QUE NO ESTÉN EN BOPERS O QUE TENGAN UNA FECHA MEJOR LOS AGREGA		=======*/
/*=========================================================================================*/
PROC SQL;
CREATE TABLE &libreria..R_EMAIL_UNIDOS AS					/* maxima secuencia 8 */
/*	SIMULACIONES_HB - SEQ 2 */
	SELECT
          t2.RUT, 
          t2.EMAIL length=50, 
		  t2.FECHA_ACT,
          t2.SEQUENCIA,
          t2.ORIGEN
    FROM RESULT.SIMULACIONES_HB_EMAIL t2				/* Datos hasta 22 Nov 2019 */
		LEFT JOIN &libreria..R_BOPERS_TOTALES_EMAIL tx on (t2.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t2.FECHA_ACT > tx.FECHA_ACT	/* Ya aplicados los filtros al email*/ 
union
/*	BOPERS	- SEQ ALEATORIA */
	SELECT	tx.rut, 
          	tx.EMAIL length=50, 
          	tx.FECHA_ACT,
           	tx.SEQUENCIA,
            Tx.ORIGEN
    FROM &libreria..R_BOPERS_TOTALES_EMAIL tx
union
/*	FISA - SEQ 7 */
   	SELECT 	distinct t7.rut, 
          	t7.EMAIL length=50, 
          	t7.FECHA_ACT,
            t7.sequencia,
            t7.ORIGEN
 	FROM &libreria..BASE_EMAIL_FISA t7 
		LEFT JOIN &libreria..R_BOPERS_TOTALES_EMAIL tx on (t7.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t7.FECHA_ACT > tx.FECHA_ACT
union
/*	CAÑON - SEQ 8 */
   	SELECT 	distinct t8.rut, 
          	t8.EMAIL length=50, 
          	t8.FECHA_ACT,
            t8.sequencia,
            t8.ORIGEN
 	FROM &libreria..BASE_EMAIL_CANON t8
		LEFT JOIN &libreria..R_BOPERS_TOTALES_EMAIL tx on (t8.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t8.FECHA_ACT > tx.FECHA_ACT
union
/*	TEF 	- SEQ 5 */
	SELECT	DISTINCT t5.RUT,
          	t5.EMAIL length=50, 
          	t5.FECHA_ACT,
          	5 AS sequencia,
          	'TEF' AS ORIGEN
    FROM &libreria..BASE_EMAIL_TEFs t5 
		LEFT JOIN &libreria..R_BOPERS_TOTALES_EMAIL tx on (t5.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t5.FECHA_ACT > tx.FECHA_ACT
union
/*	CNAVARRO 	- SEQ 6 */
  	select	distinct t6.RUT,
          	t6.EMAIL length=50,
		  	t6.FECHA_ACT,
		  	t6.sequencia,
		  	t6.ORIGEN
	FROM RESULT.R_EMAILS_CNAVARRO_DGC t6 
		LEFT JOIN &libreria..R_BOPERS_TOTALES_EMAIL tx on (t6.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t6.FECHA_ACT > tx.FECHA_ACT
union
/*	RETAIL_COM 	- SEQ 1*/
   	SELECT	distinct t1.RUT, 
          	t1.EMAIL length=50, 
          	t1.FECHA_ACT,
		  	t1.sequencia,
		  	t1.ORIGEN
  	FROM PUBLICIN.BASE_EMAIL_COM_&VdateMES t1 /*VA CON VARIABLE FECHA*/ 
		LEFT JOIN &libreria..R_BOPERS_TOTALES_EMAIL tx on (t1.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t1.FECHA_ACT > tx.FECHA_ACT
union 
/* CORRIMIENTO DE CUOTAS SEQ 12*/
SELECT distinct t12.RUT,
				t12.EMAIL length=50,
				t12.FECHA_ACT,
				t12.sequencia,
				t12.ORIGEN
	FROM POLAVARR.BASE_CORRIMIENTO_FINAL t12
		LEFT JOIN &libreria..R_BOPERS_TOTALES_EMAIL tx on (t12.RUT=tx.rut)
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t12.FECHA_ACT > tx.FECHA_ACT

union
/*	APP 	- SEQ 3 NEW Y HIS SEQ 4 */
   	SELECT	distinct t3.RUT, 
          	t3.EMAIL length=50, 
          	t3.FECHA_ACT,
		  	t3.sequencia,
		  	t3.ORIGEN
  	FROM RESULT.BASE_EMAIL_APP_FINAL t3 
		LEFT JOIN &libreria..R_BOPERS_TOTALES_EMAIL tx on (t3.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t3.FECHA_ACT > tx.FECHA_ACT
union 
/*	SIMULACIONES NEW HB 	- SEQ 9 */
   	SELECT	distinct t9.RUT, 
          	t9.EMAIL length=50, 
          	t9.FECHA_ACT,
		  	t9.sequencia,
		  	t9.ORIGEN
  	FROM POLAVARR.SIMULACIONES_HB_NEW_E t9 				/* Ya aplicados los filtros al email */
		LEFT JOIN &libreria..R_BOPERS_TOTALES2 tx on (t9.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t9.FECHA_ACT > tx.FECHA_ACT
/*union 
	QUIERO SER CLIENTE HB 	- SEQ 10 
   	SELECT	distinct t10.RUT, 
          	t10.EMAIL length=50, 
          	t10.FECHA_ACT,
		  	t10.sequencia,
		  	t10.ORIGEN
  	FROM PUBLICIN.QUIERO_SER_CLIENTE_HB_E t10 
		LEFT JOIN RESULT.R_BOPERS_TOTALES_EMAIL tx on (t10.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t10.FECHA_ACT > tx.FECHA_ACT */
union 
/*	CHEK 	- SEQ 11 */
   	SELECT	distinct t11.RUT, 
          	t11.EMAIL length=50, 
          	t11.FECHA_ACT,
		  	t11.sequencia,
		  	t11.ORIGEN
  	FROM PUBLICIN.CHEK_E t11 
		LEFT JOIN &libreria..R_BOPERS_TOTALES_EMAIL tx on (t11.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t11.FECHA_ACT > tx.FECHA_ACT

/*union 
	QSC HB NEW	- SEQ 13 
   	SELECT	distinct t11.RUT, 
          	t13.EMAIL length=50, 
          	t13.FECHA_ACT,
		  	t13.sequencia,
		  	t13.ORIGEN
  	FROM PUBLICIN.QSC_GHB_E_NEW t13 
		LEFT JOIN RESULT.R_BOPERS_TOTALES_EMAIL tx on (t13.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t13.FECHA_ACT > tx.FECHA_ACT */

;
QUIT;
/*======	FIN 6.- Une Email de todos los Orígenes	actuales	=======================*/
/*=====================================================================================*/

PROC SQL;
CREATE INDEX RUT ON &libreria..R_EMAIL_UNIDOS  (RUT);
QUIT;

/*=========================================================================================*/
/*======	7.- Cruce con Emails incorrectos y dominios incorrectos		===================*/
/*=========================================================================================*/
PROC SQL;
CREATE TABLE &libreria..R_BASE_TRABAJO_EMAIL AS
	SELECT	t1.rut,
			t1.email,
			t1.FECHA_ACT,
			t1.SEQUENCIA,
			t1.ORIGEN
		FROM &libreria..R_EMAIL_UNIDOS T1 
			LEFT JOIN result.EMAIL_INCORRECTOS_ACUMULADOS T2 ON (T1.EMAIL = T2.EMAIL)
		WHERE PRXMATCH( '/^[A-Z0-9_\.\+-]+(\.[A-Z0-9_\+-]+)*@[A-Z0-9-]{2,}(\.[A-Z0-9-]+)*\.([A-Z]{2,8})/',COMPRESS(UPCASE(t1.email)))
				AND (SUBSTR(t1.EMAIL,(INDEX(t1.EMAIL,'@'))+1)) 
					NOT IN (SELECT DOMINIOS FROM RESULT.DOMINIOS_INCORRECTOS)
				AND T2.email IS missing
;quit;

PROC SQL;
CREATE INDEX rut ON &libreria..R_BASE_TRABAJO_EMAIL (RUT);
QUIT;

PROC SQL;
   CREATE TABLE &libreria..R_BASE_TRABAJO_ORIGEN AS 
	   SELECT 	DISTINCT t1.rut, 
          		t1.EMAIL, 
          		t1.FECHA_ACT,
				t1.SEQUENCIA,
/*				ESTO ES LO DESCRITO EN R_UNIDOS - AL SUMAR APP VERIFICANDO EMAIL. REVISAR */
				CASE 	WHEN t1.ORIGEN = 'BOPERS_HB'	then 2
						WHEN t1.ORIGEN = 'APP' 			then 2
 						WHEN t1.ORIGEN = 'BOPERS_PWA' 	then 2
						WHEN t1.ORIGEN = 'BOPERS_CCSS' 	then 1
					ELSE 0 END as ORIGEN,
				t1.ORIGEN as ORI_CANAL
		FROM &libreria..R_BASE_TRABAJO_EMAIL t1
;
QUIT;

PROC SQL;
CREATE INDEX rut ON &libreria..R_BASE_TRABAJO_ORIGEN (RUT);
QUIT;

*  ==========================================================================
*  Nombre del proceso almacenado: EMAIL_AUTOMATICO_3.0 - PARTE 1 - TERMINADA
*  ==========================================================================




/*NUEVO PROGRAMA EMAIL ENERO 2020*/

*  ====================================================================
*  Nombre del proceso almacenado: EMAIL_AUTOMATICO_3.0 - PARTE 2
*  ====================================================================
*;

/*=========================================================================================*/
/*======		BÚSQUEDA A ÚNICA DIARIAMENTE --- 45 MINUTOS APROX		===================*/
/*=========================================================================================*/

/*=========================================================================================*/
/*======	00.- CONECCIÓN Y VARIABLES FECHA		=======================================*/
/*=========================================================================================*/

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

/*===========		01.- Correo Abiertos DEL ULTIMO PERIODO		=========================*/
proc sql ;
CREATE TABLE RESULT.SP_OPEN_&fechax0 as 
	SELECT	t1.customer_id AS RUT, 
			COMPRESS(UPCASE(t1.email)) AS EMAIL length=50
	FROM LIBCOMUN.output_email_&fechax0 t1 
	where EVENT_TIMESTAMP >= "&fecha0:00:00:00"dt and event_type='Open'

;quit;

/*===========		02.- Correo Abiertos - Cantidad por RUT	DEL ULTIMO PERIODO	=========*/
PROC SQL;
CREATE TABLE RESULT.SP_OPEN_APER_&fechax0 AS 
   SELECT t1.RUT, 
          t1.EMAIL length=50, 
          (COUNT(t1.EMAIL)) AS aperturas
FROM RESULT.SP_OPEN_&fechax0 t1 
   
	  WHERE t1.RUT IS NOT MISSING AND t1.RUT > 10000 AND t1.RUT < 99999999
      GROUP BY t1.RUT,
               t1.EMAIL;
QUIT;

PROC SQL;
CREATE INDEX EMAIL ON RESULT.SP_OPEN_APER_&fechax0   (EMAIL);
QUIT;

/*===========		03.- Correo Enviados DEL ULTIMO PERIODO			=====================*/
proc sql ;
 CREATE TABLE RESULT.SP_SENT_&fechax0 as 
	SELECT	t1.customer_id AS RUT,  
			COMPRESS(UPCASE(t1.email)) AS EMAIL length=50
	FROM LIBCOMUN.output_email_&fechax0 t1 
	where  /*EVENT_TIMESTAMP >= "&fecha0:00:00:00"dt AND */ event_type= 'Sent'
;quit;


/*===========		04.- Correo Enviados - Cantidad	DEL ULTIMO PERIODO	=================*/
PROC SQL;
CREATE TABLE RESULT.SP_SENT_ENVIADO_&fechax0 AS 
   SELECT t1.RUT, 
          t1.EMAIL length=50, 
          (COUNT(t1.EMAIL)) AS envios
	FROM RESULT.SP_SENT_&fechax0 t1 
	  WHERE t1.RUT IS NOT MISSING AND t1.RUT > 10000 AND t1.RUT < 99999999
      GROUP BY t1.RUT,
               t1.EMAIL;
QUIT;

PROC SQL;
 CREATE INDEX EMAIL ON RESULT.SP_SENT_ENVIADO_&fechax0  (EMAIL); 
QUIT;

/*===========		05.- Correo SUPRIMIDOS - DEL ULTIMO PERIODO		===========================*/
proc sql;
	CREATE TABLE SP_SUPPRESSED_A as		
		SELECT	CUSTOMER_ID AS RUT,
				compress(upcase(email)) as EMAIL length=50,
 				scan(EMAIL,1,"@") as inicio_correo,
				scan(EMAIL,2,"@") as dominio,
				FECHA,
				1 AS SUPPRESSED
		FROM LIBCOMUN.output_email_&fechax0
			WHERE suppression_reason in ('Global Suppression List', 'Invalid Organization Email Domain',
			'Invalid System Email Domain', 'Organization Suppression List', 'Mailing Level Suppression')
			/*	and EVENT_TIMESTAMP >= "&fecha0:00:00:00"dt > '08JAN2020:16:00:00.000000'dt*/
;quit;

/*===========		05.- Correo SUPRIMIDOS - FORMATO FECHA Y LIMPIEZA		==================*/
proc sql;
	CREATE TABLE RESULT.SP_SUPPRESSED_&fechax0 as
		SELECT	
				t1.RUT, 
				t1.email, 
				FECHA, 
				T1.SUPPRESSED
		FROM SP_SUPPRESSED_A t1
		where dominio not in (select dominio from &libreria..DOMINIO_INCORRECTOS_UNIF) 
		OR inicio_correo not in (select inicio_correo from &libreria..INICIO_CORREO_INCORRECTOS_UNIF)

;quit;

/*===========		05.- Correo SUPRIMIDOS - MAXIMO FECHA RUT E EMAIL			============*/
/*===========		YA QUE UN RUT PODRÍA SUPRIMIR MÁS DE UN EMAIL				============*/
PROC SQL;
   CREATE TABLE SP_SUPPRESSED_MAX AS 
	   SELECT	T1.RUT,
				T1.email,
				MAX(T1.FECHA) AS FECHA_NUM, 
				T1.SUPPRESSED
		FROM RESULT.SP_SUPPRESSED_&fechax0 t1 
	  group by  t1.rut, t1.email
;QUIT; 

/*===========		06.- Correo SUPRIMIDOS - FINAL DEL PERIODO				============*/
/*===========	VALIDADO. EXISTEN POCOS REGISTROS DE UN RUT CON MAS DE UN EMAIL SUPRIMIDO	===*/
PROC SQL;
  CREATE TABLE RESULT.SP_SUPPRESSED_UNICO_&fechax0 AS  
	   SELECT DISTINCT
				T1.RUT, 
				T1.email, 
				T1.FECHA AS FECHA_NUM, 
				T1.SUPPRESSED
	  FROM RESULT.SP_SUPPRESSED_&fechax0 T1 
	  	INNER JOIN SP_SUPPRESSED_MAX T2 
			ON (T1.email = T2.email AND T1.FECHA=T2.FECHA_NUM)
;QUIT;


/*UNION DE LA TODA LA HISTORIA DE SUPRIMIDOS MÁS EL ÚLTIMO PERIODO*/
PROC SQL;
CREATE TABLE SP_SUPPRESSED_UNION_HIS_NEW AS
	SELECT 	T1.RUT,
			T1.email length=50, 
			T1.FECHA_NUM, 
			T1.SUPPRESSED
		FROM RESULT.SP_SUPRIMIDOS_FINAL_HIS T1
UNION ALL
	SELECT 	T2.RUT,
			T2.email length=50, 
			T2.FECHA_NUM, 
			T2.SUPPRESSED
			FROM RESULT.SP_SUPPRESSED_UNICO_&fechax0 T2 
;QUIT;

PROC SQL;
CREATE INDEX RUT ON SP_SUPPRESSED_UNION_HIS_NEW  (RUT);
QUIT;

/*MAXIMO DE LA UNION DE HIS Y NUEVO DEL PERIODO*/
PROC SQL;
   CREATE TABLE SP_SUPPRESSED_UNION_MAX AS 
	   SELECT	T1.RUT,
	   			T1.email length=50,
				MAX(T1.FECHA_NUM) AS FECHA, 
				T1.SUPPRESSED
      FROM SP_SUPPRESSED_UNION_HIS_NEW t1
	  group by t1.RUT, t1.email
;
QUIT;

PROC SQL;
CREATE INDEX RUT ON SP_SUPPRESSED_UNION_MAX  (RUT);
QUIT;

/* SUPRIMIDOS FINAL Y TOTAL A TOMAR EN CUENTA - HASTA ESTE PERIODO */
PROC SQL;
  CREATE TABLE RESULT.SP_SUPPRESSED_&fechax0 AS 
	   SELECT 	T1.RUT,
	   			T1.EMAIL length=50,
				T1.FECHA_NUM, 
				T1.SUPPRESSED
      FROM SP_SUPPRESSED_UNION_HIS_NEW t1
	  	INNER JOIN SP_SUPPRESSED_UNION_MAX T2 
			ON (t1.email = t2.email AND T1.FECHA_NUM = T2.FECHA)
;QUIT;

PROC SQL;
CREATE INDEX EMAIL ON RESULT.SP_SUPPRESSED_&fechax0  (EMAIL); 
QUIT;


/*===========		08.- Correo REBOTADOS - DURO - FORMATO FECHA	============*/
PROC SQL;
   CREATE TABLE SP_REBOTE_DURO AS 					
   SELECT CUSTOMER_ID AS RUT,
          compress(upcase(email)) as EMAIL length=50, 
		  case when t1.EVENT_TYPE = 'Hard Bounce' then 1 else 0 end as rebote_duro
      FROM LIBCOMUN.output_email_&fechax0 t1
	  GROUP BY t1.EMAIL
	order by 1
    ;
QUIT;

/* proc sort data=SP_REBOTE_DURO out=RESULT.SP_REBOTE_DURO nodupkeys dupout=WORK.duplicados_RUT_rebote;
by EMAIL;
run; */ 


proc sort data=SP_REBOTE_DURO out=RESULT.SP_REBOTE_DURO nodupkeys dupout=WORK.duplicados_RUT_rebote;
by EMAIL;
run;

PROC SQL;
CREATE INDEX EMAIL ON RESULT.SP_REBOTE_DURO  (EMAIL);
QUIT; 

PROC SQL;
CREATE INDEX EMAIL ON SP_REBOTE_DURO  (EMAIL);
QUIT;

/*	VALIDADO OK	*/
/*===========		09.- Correo con aperturas últimos 3 meses	============*/
DATA _null_;
datex0 = put(intnx('month',today(),0,'same'),yymmn6. );
datex1 = put(intnx('month',today(),-1,'same'),yymmn6. );
datex2 = put(intnx('month',today(),-2,'same'),yymmn6. );
Call symput("fechax0", datex0);
Call symput("fechax1", datex1);
Call symput("fechax2", datex2);
RUN;

proc sql;
create table SP_OPEN_APER_X3 as
	select  * from RESULT.SP_OPEN_APER_&fechax0
		outer union corr
	select  * from RESULT.SP_OPEN_APER_&fechax1
		outer union corr
	select  * from RESULT.SP_OPEN_APER_&fechax2		
;quit; 


PROC SQL;
CREATE INDEX RUT ON SP_OPEN_APER_X3  (RUT);
QUIT;

/*APERTURAS DE LOS ÚLTIMOS 3 PERIODOS*/
PROC SQL;
  CREATE TABLE RESULT.SP_OPEN_APER_X3 AS 
   SELECT 	distinct compress(upcase(t1.EMAIL)) as EMAIL length=50,
			t1.RUT,
          	(COUNT(t1.EMAIL)) AS APERTURAS_3M
      FROM SP_OPEN_APER_X3 t1
	  WHERE t1.RUT IS NOT MISSING AND t1.RUT > 10000 AND t1.RUT < 99999999
      GROUP BY t1.EMAIL, T1.RUT
;QUIT;

 PROC SQL;
CREATE INDEX EMAIL ON RESULT.SP_OPEN_APER_X3  (EMAIL);
QUIT; 


proc sql;
create table SP_SENT_ENVIADO_X3 as
	select  * from RESULT.SP_SENT_ENVIADO_&fechax0
		outer union corr
	select  * from RESULT.SP_SENT_ENVIADO_&fechax1
		outer union corr
	select  * from RESULT.SP_SENT_ENVIADO_&fechax2
;quit; 

PROC SQL;
CREATE INDEX RUT ON SP_SENT_ENVIADO_X3  (RUT);
QUIT;

/*ENVIADOS LOS ÚLTIMOS 3 PERIODOS*/
PROC SQL;
 CREATE TABLE RESULT.SP_SENT_ENVIADO_X3 AS 
   SELECT 	compress(upcase(t1.EMAIL)) as EMAIL length=50,
			t1.RUT, 
          	(COUNT(t1.EMAIL)) AS ENVIOS_3M
      FROM SP_SENT_ENVIADO_X3 t1
	  WHERE t1.RUT IS NOT MISSING AND t1.RUT > 10000 AND t1.RUT < 99999999
      GROUP BY t1.EMAIL, T1.RUT
;QUIT;

PROC SQL;
CREATE INDEX EMAIL ON RESULT.SP_SENT_ENVIADO_X3  (EMAIL);
QUIT; 

*  ==========================================================================
*  Nombre del proceso almacenado: EMAIL_AUTOMATICO_3.0 - PARTE 2 - TERMINADA
*  ==========================================================================

/*NUEVO PROGRAMA EMAIL ENERO 2020*/

*  ====================================================================
*  Nombre del proceso almacenado: EMAIL_AUTOMATICO_3.0 - PARTE 3
*  ====================================================================
*;
/*=========================================================================================*/
/*======	00.- VARIABLES FECHA					=======================================*/
/*=========================================================================================*/
DATA _null_;
datex0 = put(intnx('month',today(),0,'same'),yymmn6. );
Call symput("fechax0", datex0);
RUN;

/*=========================================================================================*/
/*======	01.- CALCULO NOTA: NIVEL REBOTE - SUPPRISSED					===============*/
/*======					5 horas											===============*/
/*=========================================================================================*/
proc sql;
CREATE TABLE NOTA_RANK_INI_1 AS 
	select
		DISTINCT t1.RUT,
        t1.EMAIL length=50,
		t1.FECHA_ACT,
        case when t2.rebote_duro = 1 		then -15	else 0 end AS  	MRC_HardBounce,
        case when t2.rebote_duro = 0 		then 0		else 0 end AS  	MRC_SoftBounce,
		CASE 	WHEN T1.ORIGEN = 2 			then 2  	/*	si esta en bopers y es HB o APP	*/
				WHEN T1.ORIGEN = 1 			then 1 		/*	si esta en bopers y es CCSS	*/
				ELSE 0 END as 	MRC_BOPERS,
		CASE 	WHEN T6.ESTADO_ACT_VER = 2 	then 2  	/* cuando llegue otro verificado debe quedar en este estado */
				WHEN T6.ESTADO_ACT_VER = 1 	then 1 		
				ELSE 0 END as 	MRC_BOPERS_ACL_VER,
		CASE 	WHEN T6.ESTADO_ACT_VER = 2 	then 2 
				WHEN T6.ESTADO_ACT_VER = 1 	then 1 		
				WHEN T6.ESTADO_ACT_VER = 4 	then 4 		/* Para que quede el 0 en la tabla */		
				ELSE 0 END as 	ESTADO_ACT_VER,
		T1.ORIGEN,
		t1.ORI_CANAL
			FROM &libreria..R_BASE_TRABAJO_ORIGEN	t1
			LEFT JOIN RESULT.SP_REBOTE_DURO 	t2 
					ON (t1.EMAIL = t2.EMAIL)
				LEFT JOIN &libreria..R_BOPERS_TOTALES_EMAIL		t6
					ON (T1.RUT = T6.RUT AND T1.EMAIL = T6.EMAIL)
;QUIT;

PROC SQL;
CREATE INDEX RUT ON NOTA_RANK_INI_1  (RUT);
QUIT;


proc sql;
CREATE TABLE NOTA_RANK_INI_2 AS 
	select
		t1.*,
        case when t3.email is not missing 	then -20  	else 0 end AS	MRC_SUPPRESSED
			FROM NOTA_RANK_INI_1	t1
				LEFT JOIN RESULT.SP_SUPPRESSED_&fechax0 	t3 
					ON (t1.EMAIL = t3.EMAIL AND T1.RUT = T3.RUT)
;QUIT;

PROC SQL;
CREATE INDEX RUT ON NOTA_RANK_INI_2  (RUT);
QUIT;

proc sql;
CREATE TABLE NOTA_RANK_INI_3 AS 
	select
		t1.*,
		case when t4.email is not missing 	then 1  	else 0 end AS	MRC_EMAIL_APER_3M,
		case when t5.email is not missing 	then 1  	else 0 end AS	MRC_EMAIL_SENT_3M,
		T4.APERTURAS_3M,
		T5.ENVIOS_3M
			FROM NOTA_RANK_INI_2	t1
					LEFT JOIN RESULT.SP_OPEN_APER_X3 			t4 
					ON (T1.EMAIL = T4.EMAIL AND T1.RUT = T4.RUT)
					LEFT JOIN RESULT.SP_SENT_ENVIADO_X3 		t5 
					ON (T1.EMAIL = T5.EMAIL)
;QUIT;

proc sql;
CREATE TABLE &libreria..NOTA_RANK_NEW_2020 AS 
	select distinct *
			FROM NOTA_RANK_INI_3
;QUIT; 

PROC SQL;
CREATE INDEX RUT ON &libreria..NOTA_RANK_NEW_2020  (RUT);
QUIT; 


DATA _null_;
dateMES	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
Call symput("VdateMES", dateMES);

RUN;
%put &VdateMES; 

/*=========================================================================================*/
/* CALCULAR CONTACTABILIDAD - NOTA  - dice nota VU pero no es VU.. */
/*=========================================================================================*/
PROC SQL;
   CREATE TABLE CALCULO_NOTA_VU_&VdateMES AS 
   SELECT t1.rut, 
          t1.EMAIL, 
          (t1.MRC_BOPERS_ACL_VER+ 
          t1.MRC_SUPPRESSED+ 
          t1.MRC_HardBounce+
          t1.MRC_BOPERS+ 
          t1.MRC_EMAIL_APER_3M+ 
          t1.MRC_EMAIL_SENT_3M+
		  t1.APERTURAS_3M) AS NOTA,
		  t1.APERTURAS_3M AS APERTURAS,
		  t1.MRC_BOPERS,
		  t1.ORI_CANAL
	FROM &libreria..NOTA_RANK_NEW_2020 t1 WHERE t1.MRC_HardBounce = 0 and t1.MRC_SUPPRESSED <> -20
;
QUIT;

PROC SQL;
   CREATE TABLE MAXIMO_NOTA_VU_&VdateMES AS 
   SELECT t1.rut, (MAX(t1.NOTA)) AS NOTA
      FROM CALCULO_NOTA_VU_&VdateMES t1
      GROUP BY t1.rut;
QUIT;


PROC SQL;
   CREATE TABLE ELIGE_MAXIMO_NOTA_&VdateMES AS 
   SELECT t1.rut, 
          t1.NOTA, 
		  T2.EMAIL,
		  T2.APERTURAS,
		  t2.MRC_BOPERS,
		  t2.ORI_CANAL
      FROM MAXIMO_NOTA_VU_&VdateMES t1 INNER JOIN CALCULO_NOTA_VU_&VdateMES T2 ON (T1.RUT=T2.RUT);
QUIT;

/* MEJORES MAILS SEGÚN NOTA */
PROC SQL;
   CREATE TABLE MEJORES_EMAIL_NOTA_AP AS 
   SELECT 	DISTINCT t1.rut, 
			T2.EMAIL, 
			CASE WHEN t1.APERTURAS < 1 	then 0 
		  	ELSE t1.APERTURAS END as APERTURAS,
			t2.nota, 
			t2.MRC_BOPERS, 
			t2.ORI_CANAL
      FROM ELIGE_MAXIMO_NOTA_&VdateMES t1 
		INNER JOIN CALCULO_NOTA_VU_&VdateMES T2 
			ON (T1.RUT = T2.RUT AND t1.nota = T2.NOTA)  
	where t1.rut < 99999999 and t1.rut > 10000
;
QUIT;


/*ELIMINA RUTS DUPLICADOS*/
proc sort data=MEJORES_EMAIL_NOTA_AP out=&libreria..MEJORES_EMAIL_NOTA_AP_&VdateMES 
nodupkeys dupout=duplicados;
by RUT;
run;



/*=========================================================================================*/
/* GENERA BASE INFORMATIVA - SIN EXCLUSIONES REBOTE DURO NI SUPRIMIDOS */
/*=========================================================================================*/
PROC SQL;
   CREATE TABLE CALCULO_NOTA_VU_SE_&VdateMES AS 
   SELECT t1.rut, 
          t1.EMAIL, 
          (t1.MRC_BOPERS_ACL_VER+ 
          t1.MRC_SUPPRESSED+ 
          t1.MRC_HardBounce+
          t1.MRC_BOPERS+ 
          t1.MRC_EMAIL_APER_3M+ 
          t1.MRC_EMAIL_SENT_3M+
		  t1.APERTURAS_3M) AS NOTA,
		  t1.APERTURAS_3M AS APERTURAS,
		  t1.MRC_BOPERS,
		  t1.ORI_CANAL
	FROM &libreria..NOTA_RANK_NEW_2020 t1 
;
QUIT;

PROC SQL;
   CREATE TABLE MAXIMO_NOTA_VU_SE_&VdateMES AS 
   SELECT t1.rut, (MAX(t1.NOTA)) AS NOTA
      FROM CALCULO_NOTA_VU_SE_&VdateMES t1
      GROUP BY t1.rut;
QUIT;


PROC SQL;
   CREATE TABLE ELIGE_MAXIMO_NOTA_SE_&VdateMES AS 
   SELECT t1.rut, 
          t1.NOTA, 
		  T2.EMAIL,
		  T2.APERTURAS,
		  t2.MRC_BOPERS,
		  t2.ORI_CANAL
      FROM MAXIMO_NOTA_VU_SE_&VdateMES t1 
INNER JOIN CALCULO_NOTA_VU_SE_&VdateMES T2 ON (T1.RUT=T2.RUT);
QUIT;

/* MEJORES MAILS SEGÚN NOTA */
PROC SQL;
   CREATE TABLE MEJORES_EMAIL_NOTA_AP_SE AS 
   SELECT 	DISTINCT t1.rut, 
			T2.EMAIL, 
			CASE WHEN t1.APERTURAS < 1 	then 0 
		  	ELSE t1.APERTURAS END as APERTURAS,
			t2.nota, 
			t2.MRC_BOPERS, 
			t2.ORI_CANAL
      FROM ELIGE_MAXIMO_NOTA_SE_&VdateMES t1 
		INNER JOIN CALCULO_NOTA_VU_&VdateMES T2 
			ON (T1.RUT = T2.RUT AND t1.nota = T2.NOTA)  
	where t1.rut < 99999999 and t1.rut > 10000
;
QUIT;


/*ELIMINA RUTS DUPLICADOS*/
proc sort data=MEJORES_EMAIL_NOTA_AP_SE out=&libreria..MEJORES_EMAIL_NOTA_AP_SE_&VdateMES 
nodupkeys dupout=duplicados;
by RUT;
run;



/* BASE EMAIL SIN EXCLUSIONES O SIN FILTROS APLICADOS */
PROC SQL;
   CREATE TABLE BASE_TRABAJO_EMAIL_SE AS 
   SELECT 	*
      FROM	&libreria..MEJORES_EMAIL_NOTA_AP_SE_&VdateMES
;QUIT;

/*se crea BASE_TRABAJO_EMAIL_INFORMATIVO donde solo se excluyen clientes puntuales para comunicacion informativa */ 

PROC SQl;
CREATE TABLE LNEGRO_EMAIL AS 
SELECT DISTINCT  RUT
FROM publicin.lnegro_email 
WHERE motivo  in ('EMAIL_NO_CORRESPONDE') 
;quit;

/*se excluyen emails que no corresponden y fallecidos */

proc sql;
create table PUBLICIN.BASE_TRABAJO_EMAIL_INFORMATIVO as 
select 
t1.*
from BASE_TRABAJO_EMAIL_SE t1
left join publicin.lnegro_car t2
on (t1.rut=t2.rut)
left join LNEGRO_EMAIL t3
on (t1.rut=t3.rut)
where /*(tipo_inhibicion=lista_negra_car and canal_reclamo=auris) and */
t2.tipo_inhibicion not in ('FALLECIDO','FALLECIDOS')  AND 
T3.RUT IS NULL
;quit ; 


/*EXCLUSIONES PUNTUALES SOLICITADAS*/
PROC SQL;
   CREATE TABLE BASE_TRABAJO_EMAIL_EPUNT AS 
   SELECT t1.RUT, 
          t1.EMAIL, 
          t1.MRC_BOPERS,
		  t1.APERTURAS,
          t1.NOTA,
		  t1.ORI_CANAL
      FROM &libreria..MEJORES_EMAIL_NOTA_AP_&VdateMES T1 LEFT JOIN POLAVARR.EXCLUSIONES_PUNTUALES T2
	  	ON (T1.RUT = T2.RUT AND T1.EMAIL = T2.EMAIL) where T2.RUT IS MISSING
;QUIT;

PROC SQL;
   CREATE TABLE BASE_TRABAJO_EMAIL_LNCAR AS 
   SELECT t1.RUT, 
          t1.EMAIL, 
          t1.MRC_BOPERS,
		  t1.APERTURAS,
          t1.NOTA,
		  t1.ORI_CANAL
		FROM BASE_TRABAJO_EMAIL_EPUNT 	T1 
				LEFT JOIN PUBLICIN.LNEGRO_CAR T2
				ON (T1.RUT = T2.RUT) where T2.RUT IS MISSING
;QUIT;

PROC SQL;
   CREATE TABLE BASE_TRABAJO_EMAIL_LNEMAIL_R AS 
   SELECT t1.RUT, 
          t1.EMAIL, 
          t1.MRC_BOPERS,
		  t1.APERTURAS,
          t1.NOTA,
		  t1.ORI_CANAL
		FROM BASE_TRABAJO_EMAIL_LNCAR 	T1 
			LEFT JOIN PUBLICIN.LNEGRO_EMAIL T3	
				ON (T1.RUT = T3.RUT) where T3.RUT IS MISSING
;QUIT;
 
PROC SQL;
	CREATE TABLE BASE_TRABAJO_EMAIL_WEBBULA AS 
	SELECT T1.RUT,
		   T1.EMAIL,
           T1.MRC_BOPERS,
           T1.APERTURAS,
           T1.NOTA,
           T1.ORI_CANAL
        FROM BASE_TRABAJO_EMAIL_LNEMAIL_R T1 
			LEFT JOIN POLAVARR.WEBBULA_EXCLUSION T2
				ON (T1.RUT=T2.RUT AND T1.EMAIL=T2.EMAIL)
					WHERE T2.RUT IS NULL AND T2.EMAIL IS NULL
;quit;


/* TRANSFORMACION A MAYUSCULA DE TODOS LOS EMAILS DEL LNEGRO_EMAIL*/
proc sql;
create table lnegro_email_mayusc as
select upcase(email) as email
from PUBLICIN.LNEGRO_EMAIL;
quit;

/*APLICADOS FILTROS DE LNEGROS CAR/EMAIL (PARA EL EMAIL Y RUT)*/
PROC SQL;
   CREATE TABLE &libreria..BASE_TRABAJO_EMAIL AS 
   SELECT t1.RUT, 
          t1.EMAIL, 
          t1.MRC_BOPERS,
		  t1.APERTURAS,
          t1.NOTA,
		  t1.ORI_CANAL
		FROM BASE_TRABAJO_EMAIL_WEBBULA 	T1 
			LEFT JOIN work.lnegro_email_mayusc T4
				ON (T1.EMAIL = T4.EMAIL) where T4.EMAIL IS MISSING
ORDER BY T1.RUT
;QUIT;

proc sql;
create table SEPARACION_CORREO as
select
		t1.RUT, 
          t1.EMAIL, 
		  scan(EMAIL,1,"@") as inicio_correo,
		  scan(EMAIL,2,"@") as dominio,
          t1.MRC_BOPERS,
		  t1.APERTURAS,
          t1.NOTA,
		  t1.ORI_CANAL
from &libreria..BASE_TRABAJO_EMAIL t1
order by 1;
quit;

/*Tomar el registro de fecha máxima de TEFs*/
proc sql;
create table SEPARACION_CORREO_2 AS
	SELECT	t1.RUT, 
          t1.EMAIL, 
		  t1.inicio_correo,
		  t1.dominio,
          t1.MRC_BOPERS,
		  t1.APERTURAS,
          t1.NOTA,
		  t1.ORI_CANAL
	    FROM SEPARACION_CORREO t1 
		WHERE dominio not in (select dominio from  &libreria..DOMINIO_INCORRECTOS_UNIF) 
		OR inicio_correo not in (select inicio_correo from  &libreria..INICIO_CORREO_INCORRECTOS_UNIF)
;
QUIT;

/*LIMPIEZA Y TABLA FINAL*/
proc sql;
	create table &libreria..BASE_TRABAJO_EMAIL as
		select *
			from SEPARACION_CORREO_2 t1
				where t1.email 
					not LIKE ('.-%') AND t1.email not LIKE ('%.')
					AND t1.email not LIKE ('.%')
					AND t1.email not LIKE ('-%')				AND t1.email not LIKE	('%.@%')
					AND t1.email not CONTAINS	('(')			AND t1.email not CONTAINS 	(')')
					AND t1.email not CONTAINS	('/')			AND t1.email not CONTAINS	('?')
					AND t1.email <>'@'							AND t1.email <>'0' 
					AND t1.email CONTAINS 	('@')
;quit;

PROC SQL;
CREATE INDEX rut ON &libreria..BASE_TRABAJO_EMAIL (rut);
QUIT;


/*=========================================================================================*/
/* FIN - CALCULAR CONTACTABILIDAD - NOTA */
/*=========================================================================================*/

/*=========================================================================================*/
/*=========================================================================================*/
/* PASAR DESDE LIBRERÍA PERSONAL A PUBLICIN */
PROC SQL;
   CREATE TABLE PUBLICIN.BASE_TRABAJO_EMAIL AS 
   SELECT *, &VdateMES. AS PERIODO
      FROM &libreria..BASE_TRABAJO_EMAIL
;
QUIT;

PROC SQL;
CREATE INDEX rut ON PUBLICIN.BASE_TRABAJO_EMAIL (rut);
QUIT;

/*EXPORTACIÓN AWS*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_ctbl_base_trabajo_email,raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_ctbl_base_trabajo_email,publicin.BASE_TRABAJO_EMAIL,raw,sasdata,0);


/*  ==========================================================================*/
/*  Nombre del proceso almacenado: EMAIL_AUTOMATICO_3.0 - PARTE 3 - TERMINADA */
/*  ==========================================================================*/

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
SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CONTACTABILIDAD';
SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1")
CC = ("&DEST_2","&DEST_3")
SUBJECT = ("MAIL_AUTOM: PROCESO DE CONTACTABILIDAD - EMAIL");
FILE OUTBOX;
	PUT "Estimados:";
 	put "		Proceso de contactabilidad EMAIL_AUTOM_REFACTOR, ejecutado con fecha: &fechaeDVN";  
	PUT;
	PUT;
	put 'Proceso Vers. 30';
	PUT;
	PUT;
	PUT 'Atte.';
	Put 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;
FILENAME OUTBOX CLEAR;

