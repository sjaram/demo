/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	Local_primera_compra				 	 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-08-29 -- V03	-- Sergio J. 	-- Se añade sentencia include para borrar y exportar a RAW
/* 2022-07-11 -- V02	-- David V. 	-- Ajustes mínimos para nuevo flujo "Oracloud AWS Athena".

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

LIBNAME ORACLOUD ORACLE sql_functions=all  READBUFF=1000  INSERTBUFF=1000  PATH="REPORTSAS.WORLD"  SCHEMA=SAS_ADM authdomain=DBOracleCloud_Auth;

/*CALCULAMOS PRIMERA COMPRA DEL USUARIO EN CADA COMERCIO*/
PROC SQL;
CREATE TABLE WORK.PRIMERA_CADA_LOCALES AS
SELECT 
  t1.FROMACCOUNTID,
  t1.TOACCOUNTID,
  MIN(t1.CREATEDAT) AS FECHA
FROM 
( 
  SELECT
    A.*
  FROM
    ORACLOUD.CHEK_PAYMENTS A
  INNER JOIN
    ORACLOUD.CHEK_COMMERCES B
    on A.TOACCOUNTID = B.PRIMARYACCOUNTID
) AS t1
GROUP BY
  t1.FROMACCOUNTID,
  t1.TOACCOUNTID
;RUN;



/*CALCULAMOS PRIMERA COMPRA Y EL LOCAL*/
PROC SQL;
CREATE TABLE WORK.PRIMERA_COMPRA AS
SELECT 
	*
FROM
(
	SELECT 
		t2.ID,
		t2.FROMACCOUNTID,
		t2.TOACCOUNTID,
		CAT(year(datepart(t2.CREATEDAT)),'-',
					CASE 
				  		WHEN length(CAT(month(datepart(t2.CREATEDAT)))) = 1 THEN CAT('0',month(datepart(t2.CREATEDAT))) 
				  		ELSE CAT(month(datepart(t2.CREATEDAT))) 
				  	END,'-',
					CASE 
				  		WHEN length(CAT(day(datepart(t2.CREATEDAT)))) = 1 THEN CAT('0',day(datepart(t2.CREATEDAT))) 
				  		ELSE CAT(day(datepart(t2.CREATEDAT))) 
				  	END) AS FECHA,
		t2.AMOUNT,
		input(CAT(year(datepart(t2.CREATEDAT)),
		  	CASE 
		  		WHEN length(CAT(month(datepart(t2.CREATEDAT)))) = 1 THEN CAT('0',month(datepart(t2.CREATEDAT))) 
		  		ELSE CAT(month(datepart(t2.CREATEDAT))) 
		  	END),6.) AS PERIODO
	FROM
	  	ORACLOUD.CHEK_PAYMENTS AS t2
	INNER JOIN
	(
	  	SELECT 
	    	t3.FROMACCOUNTID,
	    	(MIN(t3.FECHA)) FORMAT=DATETIME20. AS FECHA_MIN
	  	FROM 
	    	WORK.PRIMERA_CADA_LOCALES t3
	  	GROUP BY
	    	t3.FROMACCOUNTID
	) 	AS t4
	ON t2.FROMACCOUNTID = t4.FROMACCOUNTID
	  	AND t2.CREATEDAT = t4.FECHA_MIN
) 	AS A
;RUN;

%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_DELETE.sas";
%borrarOracleRaw(CHEK_PRIMER_COMPRA_CLIENTE);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_EXPORT.sas";
%ExportacionOracleRaw(CHEK_PRIMER_COMPRA_CLIENTE,WORK.PRIMERA_COMPRA);


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
SUBJECT="MAIL_AUTOM: PROCESO Local_primera_compra" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso Local_primera_compra, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put 'Tabla resultante en Athena: CHEK_PRIMER_COMPRA_CLIENTE';
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 03'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
