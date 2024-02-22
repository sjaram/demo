/*INSTANCIA MISCAR */
%macro principal();
%LET NOMBRE_PROCESO = 'Carga_LCA';


data _null_;
	call symputx('anomes',sum(year(today())*100,month( intnx('month',today(),-1,'begin')  )*1));
	call symputx('anomes1',sum(year(today())*100,month( intnx('month',today(),-2,'begin')  )*1));
run;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

%put &anomes;
%put &anomes1;


LIBNAME MPDT         ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS'      USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME R_BOPERS     ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM'      USER='AMARINAOC' PASSWORD='amarinaoc2017';


proc sql;
create table rut as 
select 
a.CODENT,
a.CENTALTA,
a.CUENTA,
INPUT(b.PEMID_GLS_NRO_DCT_IDE_K,BEST.) as rut
from MPDT.MPDT007 as a
left join  R_BOPERS.BOPERS_MAE_IDE b
ON (INPUT(a.IDENTCLI,BEST.) = b.PEMID_NRO_INN_IDE)
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

proc sql;
   connect to ODBC as MIS (DATASRC="BR-MIS" user="nlagosg" password="{SAS002}7183730115E4691046F2820058130A68");
CREATE TABLE LCA AS 
SELECT * FROM connection to MIS(
   SELECT * 
FROM [MIS\rrios].LCA);
quit;


%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SQL;


CREATE TABLE PUBLICIN.LCA_&anomes AS 
SELECT  T2.RUT, 
		t1.LIMCRELNA, 
		t1.LINEA, 
		t1.CUENTA, 
		t1.CENTALTA, 
		t1.CODENT
FROM LCA T1 
INNER JOIN RUT T2 ON T1.CODENT = T2.CODENT 
  AND T1.CENTALTA = T2.CENTALTA 
  AND T1.CUENTA = T2.CUENTA;
QUIT;

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


data _null_;
	call symputx('anomes',sum(year(today())*100,month( intnx('month',today(),-1,'begin')  )*1));
	call symputx('anomes1',sum(year(today())*100,month( intnx('month',today(),-2,'begin')  )*1));
run;


%LET NOMBRE_PROCESO = "Carga_LCA";

PROC SQL;


CREATE TABLE VALIDA_LCA  AS 
SELECT &anomes AS FECHA_PROCESO,
       COUNT(RUT) AS CANTIDAD_REGISTROS		
FROM PUBLICIN.LCA_&anomes T1; 

QUIT;


FILENAME output EMAIL
SUBJECT= "Ejecucion de Proceso Carga LCA"
FROM= "equipo_datos_procesos_bi@bancoripley.com"
TO= ("dvasquez@bancoripley.com", "sjaram@BANCORIPLEY.com")
CT= "text/html" /* Required for HTML output */ ;
ODS LISTING CLOSE;
ODS HTML BODY=output STYLE=sasweb;
TITLE JUSTIFY=left;
PROC print DATA=WORK.VALIDA_LCA noobs;
RUN;
ODS HTML CLOSE;
ODS LISTING;
