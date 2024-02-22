/*CÓDIGOS DE COMERCIOS AUTOMATIZADOS*/

proc  sql;
create table RESULT.CODCOM_CAMPS_SPOS_2 as 
select * from RESULT.CODCOM_CAMPS_SPOS;
quit;

DATA WORK.cod_Com;
    LENGTH
		Periodo_Campana    8
        Codigo_Comercio  $ 9
        Detalle_Comercio $ 112
        Marca_Campana    $ 55 ;
    FORMAT
        Periodo_Campana  BEST6.
        Codigo_Comercio  $CHAR9.
        Detalle_Comercio $CHAR112.
        Marca_Campana    $CHAR55. ;
    INFORMAT
        Periodo_Campana  BEST6.
        Codigo_Comercio  $CHAR9.
        Detalle_Comercio $CHAR112.
        Marca_Campana    $CHAR55. ;
    INFILE "/sasdata/users94/user_bi/TRASPASO_DOCS/COD_COM_ALIANZAS/cod_com.csv"
        DELIMITER=';'
		firstobs=2
		;
    INPUT
        Periodo_Campana  : ?? BEST6.
        Codigo_Comercio  : $CHAR9.
        Detalle_Comercio : $CHAR112.
        Marca_Campana    : $CHAR55. ;
RUN;

PROC SQL;
create table result.CodCom_Camps_SPOS  as 
select 	Periodo_Campana,
		input (CODIGO_COMERCIO, best.) as  codigo_comercio,
		Detalle_Comercio,
		Marca_Campana
from WORK.COD_COM;

run;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(sas_spos_codcom_camps,raw,sasdata,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(sas_spos_codcom_camps,result.codcom_camps_spos,raw,sasdata,0);


data _null_;
FECHA_PROCESO=cat((put(intnx('month',TODAY(),0,'same'),yymmdd10.)) ,"  " , (put(intnx('month',timepart(TIME()),0,'same'),hhmm8.2)) );
call symput("FECHA_DETALLE",FECHA_PROCESO);

run;

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_CODCOM_CAMPS_SPOS AS 
   SELECT distinct /* MAX_of_Fecha_Archivo_Codigos */
            (MAX(t1.Periodo_Campana)) FORMAT=BEST6. AS Periodo_Campana, 
          /* COUNT_of_Codigo_Comercio */
            (COUNT(t1.Codigo_Comercio)) AS Cantidad_codigos,
			(MAX(t1.Codigo_Comercio)) as ultimo_codigo
      FROM RESULT.CODCOM_CAMPS_SPOS t1;
QUIT;

PROC SQL;
   CREATE TABLE WORK.todos AS 
   SELECT (COUNT(t1.Codigo_Comercio)) AS Codigos_totales,
   (COUNT(distinct(t1.Codigo_Comercio))) AS Codigos_unicos,
	Periodo_Campana
      FROM RESULT.CODCOM_CAMPS_SPOS t1
group by Periodo_Campana ;
QUIT;

FILENAME output EMAIL
SUBJECT= "Ejecución de Proceso Codigos de Comercio SPOS" /*Ejecucion de Proceso de Carga Codigos Comercio SPOS"*/
FROM= "sjaram@bancoripley.com"
TO= ("bschmidtm@bancoripley.com","crachondode@bancoripley.com","pdeaguirrem@bancoripley.com","dgonzalezb@bancoripley.com")
CC=("pmunozc@bancoripley.com","sjaram@bancoripley.com","iplazam@bancoripley.com", "dvasquez@bancoripley.com")
CT= "text/html" /* Required for HTML output */ ;
ODS LISTING CLOSE;
ODS HTML BODY=output STYLE=sasweb;
TITLE JUSTIFY=left;
PROC print DATA=WORK.QUERY_FOR_CODCOM_CAMPS_SPOS NOobs;
RUN;
PROC print DATA=WORK.todos NOobs;
RUN;
ODS HTML CLOSE;
ODS LISTING;



