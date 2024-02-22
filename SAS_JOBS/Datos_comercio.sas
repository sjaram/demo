/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	Datos_comercio				 	 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-11-07 -- v04 -- David V.	-- Se actualizar export a AWS, según nuevas definiciones a RAW.
/* 2022-08-29 -- v03 -- Sergio J. 	-- Se añade sentencia include para borrar y exportar a RAW
/* 2022-07-11 -- v02 -- David V. 	-- Ajustes mínimos para nuevo flujo "Oracloud AWS Athena".

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

LIBNAME ORACLOUD ORACLE sql_functions=all  READBUFF=1000  INSERTBUFF=1000  PATH="REPORTSAS.WORLD"  SCHEMA=SAS_ADM authdomain=DBOracleCloud_Auth;

PROC SQL;
CREATE TABLE WORK.COMERCIOS AS
SELECT
	CAT(year(datepart(CREATEDAT)),'-',
					CASE 
				  		WHEN length(CAT(month(datepart(CREATEDAT)))) = 1 THEN CAT('0',month(datepart(CREATEDAT))) 
				  		ELSE CAT(month(datepart(CREATEDAT))) 
				  	END,'-',
					CASE 
				  		WHEN length(CAT(day(datepart(CREATEDAT)))) = 1 THEN CAT('0',day(datepart(CREATEDAT))) 
				  		ELSE CAT(day(datepart(CREATEDAT))) 
				  	END) AS FECHA,
	NAME AS NOMBRE_COMERCIO,
	TRANWRD(CASE WHEN index(ADDRESS,'"region": "') > 0 THEN SUBSTR(ADDRESS,index(ADDRESS,'"region": "')+LENGTH('"region": "'),index(SUBSTR(ADDRESS,index(ADDRESS,'"region": "')+LENGTH('"region": "')),'"')-1) ELSE '' END,'%20',' ') AS REGION,
	TRANWRD(CASE WHEN index(ADDRESS,'"commune": "') > 0 THEN SUBSTR(ADDRESS,index(ADDRESS,'"commune": "')+LENGTH('"commune": "'),index(SUBSTR(ADDRESS,index(ADDRESS,'"commune": "')+LENGTH('"commune": "')),'"')-1) ELSE '' END,'%20',' ') AS COMUNA,
	INPUT(CASE WHEN index(ADDRESS,'"lat": ') > 0 THEN SUBSTR(ADDRESS,index(ADDRESS,'"lat": ')+LENGTH('"lat": '),index(SUBSTR(ADDRESS,index(ADDRESS,'"lat": ')+LENGTH('"lat": ')),',')-1) ELSE '' END,comma9.20) AS LATITUD,	
	INPUT(CASE WHEN index(ADDRESS,'"lng": ') > 0 THEN SUBSTR(ADDRESS,index(ADDRESS,'"lng": ')+LENGTH('"lng": '),index(SUBSTR(ADDRESS,index(ADDRESS,'"lng": ')+LENGTH('"lng": ')),',')-1) ELSE '' END,comma9.20) AS LONGITUD,
	CATEGORYID as CATEGORIA,
	PRIMARYACCOUNTCATEGORY AS TIER,
	PRIMARYACCOUNTID AS ID
FROM
	ORACLOUD.CHEK_COMMERCES
;RUN;

/* export data csv */
proc export data=WORK.COMERCIOS
outfile="/sasdata/users94/user_bi/ORACLOUD/CHEK_RESUMEN_COMERCIO.csv"
dbms=dlm
replace;
delimiter="|";
quit;

%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;
/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================        EXPORT_TO_AWS - INI          ===============================*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(chek_resumen_comercio,raw,oracloud,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(chek_resumen_comercio,work.comercios,raw,oracloud,0);

/*==============================        EXPORT_TO_AWS - END          ===============================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

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
SUBJECT="MAIL_AUTOM: PROCESO Datos_comercio" ;
FILE OUTBOX;
	PUT 'Estimados:';
 	PUT "	Proceso Datos_comercio, ejecutado con fecha: &fechaeDVN";  
 	PUT ; 
 	PUT '	Tabla resultante en Athena: CHEK_RESUMEN_COMERCIO';
 	PUT ;
 	PUT ;
 	PUT 'Proceso Vers. 04'; 
 	PUT;
 	PUT;
 	PUT 'Atte.';
 	PUT 'Equipo Arquitectura de Datos y Automatización BI';
 	PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
