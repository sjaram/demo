/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================    m4_consolidado				================================*/
/* CONTROL DE VERSIONES
/* 2022-07-22 -- V01 -- Sergio J. -- Versión original
*/

DATA _null_;
ayer	= compress(tranwrd(put(INTNX('month',today() , -1),yymmn6.),"-",""));
Call symput("ayer", ayer);
RUN;
%put &ayer;


proc sql;
   connect to ODBC as MIS (DATASRC="BR-MIS" user="nlagosg" password="{SAS002}7183730115E4691046F2820058130A68");
CREATE TABLE RESULT.M4_CONSO_&ayer. AS 
SELECT * FROM connection to MIS(
   SELECT * 
FROM  [MAESTRA_CAR].[dbo].[M4_CONSO_&ayer.]);
quit;

proc sql;
create table valida_m4_conso as
select count(rut) as cantidad from result.M4_CONSO_&ayer.;

quit;


FILENAME output EMAIL
SUBJECT= "MAIL_AUTOM: Ejecucion de Proceso M4_CONSO_&ayer"
FROM= "equipo_datos_procesos_bi@bancoripley.com"
TO= ("sjaram@bancoripley.com", "dvasquez@bancoripley.com", "kmartinezb@bancoripley.com","nlagosg@bancoripley.com")
CT= "text/html" /* Required for HTML output */ ;
ODS LISTING CLOSE;
ODS HTML BODY=output STYLE=sasweb;
TITLE JUSTIFY=left;
PROC print DATA=WORK.valida_m4_conso noobs;
RUN;
ODS HTML CLOSE;
ODS LISTING;
