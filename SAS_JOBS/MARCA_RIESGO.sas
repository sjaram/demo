%macro principal();
%LET NOMBRE_PROCESO = 'Marca_Riesgo';

DATA _null_;
ayer	= compress(tranwrd(put(INTNX('month',today() , -1),yymmn6.),"-",""));
Call symput("ayer", ayer);
RUN;
%put &ayer;

%if &syserr. > 0 %then %do;
 	%goto exit;
	%end;

%put &anomes;

proc sql;
   connect to ODBC as MIS (DATASRC="BR-MIS" user="nlagosg" password="{SAS002}7183730115E4691046F2820058130A68");
CREATE TABLE RESULT.MARCA_RIESGO_&ayer. AS 
SELECT * FROM connection to MIS(
   SELECT * 
FROM [MAESTRA_CAR].[MIS\rrios].MARCA_RIESGO_&ayer.);
quit;

%if &syserr. > 0 %then %do;
 	%goto exit;
	%end;

%exit:

%put &FECHA_DETALLE; 
%let error = &syserr;

/*REGISTRO EN TABLA DE ESTADO DE PROCESO */
data _null_;
FECHA_PROCESO=cat((put(intnx('month',TODAY(),0,'same'),yymmdd10.)) ,"  " , (put(intnx('month',timepart(TIME()),0,'same'),hhmm8.2)) );
call symput("FECHA_DETALLE",FECHA_PROCESO);

run;

%put &FECHA_DETALLE; 
%let error = &syserr;


%mend;
%principal();

/*Fecha Inicial de la etapa*/
PROC SQL outobs=1 noprint;   
select 
infoerr as temp_error
into :temp_error
from result.tbl_estado_proceso_localsj
where nombre_proceso = 'Marca_Riesgo'
order by fecha desc
;QUIT;

DATA _null_;
ayer	= compress(tranwrd(put(INTNX('month',today() , -1),yymmn6.),"-",""));
Call symput("ayer", ayer);
RUN;
%put &ayer;

proc sql;
create table valida_marca_riesgo as
select count(rut) as cantidad from result.marca_riesgo_&ayer.;

quit;


FILENAME output EMAIL
SUBJECT= "Ejecucion de Proceso Marca Riesgo"
FROM= "equipo_datos_procesos_bi@bancoripley.com"
TO= ("sjaram@bancoripley.com", "dvasquez@bancoripley.com", "mguzmans@bancoripley.com")
CT= "text/html" /* Required for HTML output */ ;
ODS LISTING CLOSE;
ODS HTML BODY=output STYLE=sasweb;
TITLE JUSTIFY=left
&temp_error;
PROC print DATA=WORK.valida_marca_riesgo noobs;
RUN;
ODS HTML CLOSE;
ODS LISTING;


