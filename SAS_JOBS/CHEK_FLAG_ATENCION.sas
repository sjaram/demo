/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	CHEK_FLAG_ATENCION	================================*/
/* CONTROL DE VERSIONES
/* 2022-09-06 -- V04	-- David V. 	-- Se quita export a AWS oracloud CHEK_FLAG_ATENCION_H
/* 2022-08-29 -- V03	-- Sergio J. 	-- Se añade sentencia include para borrar y exportar a RAW
/* 2022-07-11 -- V02	-- David V. 	-- Ajustes mínimos para nuevo flujo "Oracloud AWS Athena".
/* 2021-05-04 -- V01 	-- Mario .G 	-- Nueva Versión Automática Equipo Datos y Procesos BI
*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio = %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*CONEXION A ORACLECLOUD*/
LIBNAME ORACLOUD ORACLE sql_functions=all  READBUFF=1000  INSERTBUFF=1000  PATH="REPORTSAS.WORLD"  SCHEMA=SAS_ADM authdomain=DBOracleCloud_Auth;


PROC SQL;
CREATE TABLE WORK.FLAG_ATENCION AS 
SELECT 
	t1.NAME,
	/*t2.CATEGORY,*/
	t1.PRIMARYACCOUNTCATEGORY AS TIER,
	t2.ID AS PRIMARYACCOUNTID, 
	t2.BALANCE,
	input(CAT(year(datepart(datetime())),
					CASE 
				  		WHEN length(CAT(month(datepart(datetime())))) = 1 THEN CAT('0',month(datepart(datetime()))) 
				  		ELSE CAT(month(datepart(datetime()))) 
				  	END,
					CASE 
				  		WHEN length(CAT(day(datepart(datetime())))) = 1 THEN CAT('0',day(datepart(datetime()))) 
				  		ELSE CAT(day(datepart(datetime()))) 
				  	END),
			  8.) AS FECHA,
	/*t2.MAXBALANCE,*/
	CASE 
		WHEN t2.CATEGORY = "t1" AND t2.BALANCE > 400000 THEN 1 
		WHEN t2.CATEGORY = "t2" AND t2.BALANCE > 4000000 THEN 1 
		ELSE 0
	END AS FLAG_ATENDER
FROM 
	ORACLOUD.CHEK_COMMERCES t1
INNER JOIN 
	ORACLOUD.CHEK_ACCOUNTS t2 
	ON (t1.PRIMARYACCOUNTID = t2.ID)
ORDER BY 
	CASE 
		WHEN t2.CATEGORY = "t1" AND t2.BALANCE > 400000 THEN 1 
		WHEN t2.CATEGORY = "t2" AND t2.BALANCE > 4000000 THEN 1 
		ELSE 0
	END DESC,
t2.BALANCE DESC;
QUIT;


PROC SQL noprint;
INSERT INTO ORACLOUD.CHEK_FLAG_ATENCION_H  
SELECT
	A.*
FROM
(
	SELECT 
		t1.NAME,
		t2.ID AS PRIMARYACCOUNTID, 
		0 AS ULTIMA_FECHA_CON_FLAG_ATENDER,
		0 AS FLAG_ALGUNA_VEZ_ATENDER,
		"null" AS TIER_ALGUNA_VEZ_ATENDER
	FROM 
		ORACLOUD.CHEK_COMMERCES t1
	INNER JOIN 
		ORACLOUD.CHEK_ACCOUNTS t2 
		ON (t1.PRIMARYACCOUNTID = t2.ID)
) 	AS A
LEFT JOIN
	ORACLOUD.CHEK_FLAG_ATENCION_H AS B
ON  A.PRIMARYACCOUNTID = B.PRIMARYACCOUNTID
WHERE 
	B.PRIMARYACCOUNTID IS NULL
;QUIT;



PROC SQL noprint;
UPDATE ORACLOUD.CHEK_FLAG_ATENCION_H AS A
SET 
FLAG_ALGUNA_VEZ_ATENDER = (SELECT 
								B.FLAG_ATENDER 
							FROM 
								WORK.FLAG_ATENCION AS B 
							WHERE 
								A.PRIMARYACCOUNTID = B.PRIMARYACCOUNTID 
								AND B.FLAG_ATENDER = 1
							)
WHERE A.PRIMARYACCOUNTID IN (SELECT DISTINCT PRIMARYACCOUNTID FROM WORK.FLAG_ATENCION WHERE FLAG_ATENDER = 1)
;QUIT;

PROC SQL noprint;
UPDATE ORACLOUD.CHEK_FLAG_ATENCION_H AS A
SET 
ULTIMA_FECHA_CON_FLAG_ATENDER = (SELECT 
									B.FECHA 
								FROM 
									WORK.FLAG_ATENCION AS B 
								WHERE 
									A.PRIMARYACCOUNTID = B.PRIMARYACCOUNTID 
									AND B.FLAG_ATENDER = 1
								)
WHERE A.PRIMARYACCOUNTID IN (SELECT DISTINCT PRIMARYACCOUNTID FROM WORK.FLAG_ATENCION WHERE FLAG_ATENDER = 1)
;QUIT;

PROC SQL noprint;
UPDATE ORACLOUD.CHEK_FLAG_ATENCION_H AS A
SET 
TIER_ALGUNA_VEZ_ATENDER = (SELECT 
								B.TIER 
							FROM 
								WORK.FLAG_ATENCION AS B 
							WHERE 
								A.PRIMARYACCOUNTID = B.PRIMARYACCOUNTID 
								AND B.FLAG_ATENDER = 1
							)
WHERE A.PRIMARYACCOUNTID IN (SELECT DISTINCT PRIMARYACCOUNTID FROM WORK.FLAG_ATENCION WHERE FLAG_ATENDER = 1)
;QUIT;

PROC SQL noprint;
DROP TABLE ORACLOUD.CHEK_FLAG_ATENCION_D 
;QUIT;

PROC SQL noprint;
CREATE TABLE ORACLOUD.CHEK_FLAG_ATENCION_D AS 
SELECT 
	A.NAME,
	A.TIER,
	A.PRIMARYACCOUNTID, 
	A.BALANCE,
	A.FECHA,
	A.FLAG_ATENDER,
	B.ULTIMA_FECHA_CON_FLAG_ATENDER,
	B.FLAG_ALGUNA_VEZ_ATENDER,
	B.TIER_ALGUNA_VEZ_ATENDER
FROM 
	WORK.FLAG_ATENCION AS A
LEFT JOIN
	ORACLOUD.CHEK_FLAG_ATENCION_H AS B
ON A.PRIMARYACCOUNTID = B.PRIMARYACCOUNTID
ORDER BY
	A.FLAG_ATENDER DESC,
	B.FLAG_ALGUNA_VEZ_ATENDER DESC, 
	A.BALANCE DESC
;QUIT;

data work.CHEK_FLAG_ATENCION_D;
set ORACLOUD.CHEK_FLAG_ATENCION_D;
run;

data work.CHEK_FLAG_ATENCION_H;
set ORACLOUD.CHEK_FLAG_ATENCION_H;
run;

%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_DELETE.sas";
%borrarOracleRaw(CHEK_FLAG_ATENCION_D);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_EXPORT.sas";
%ExportacionOracleRaw(CHEK_FLAG_ATENCION_D,work.CHEK_FLAG_ATENCION_D);

/*%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_DELETE.sas";*/
/*%borrarOracleRaw(CHEK_FLAG_ATENCION_H);*/
/*%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_EXPORT.sas";*/
/*%ExportacionOracleRaw(CHEK_FLAG_ATENCION_H,work.CHEK_FLAG_ATENCION_H);*/

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*=========================================================================================*/
/*=======================       FECHA PROCESO Y ENVÍO DE EMAIL      =======================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_DIGITAL';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_CHEK_1';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_CHEK_2';

quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;
%put &=DEST_6;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4","&DEST_5", "&DEST_6")
CC = ("&DEST_1","&DEST_2", "&DEST_3")
SUBJECT = ("MAIL_AUTOM: PROCESO CHEK_FLAG_ATENCION");
FILE OUTBOX;
 PUT "Estimados:";
 put "    	Proceso CHEK_FLAG_ATENCION, ejecutado con fecha: &fechaeDVN";  
 PUT '		Tabla resultante en Athena: CHEK_FLAG_ATENCION_D';
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 04'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
