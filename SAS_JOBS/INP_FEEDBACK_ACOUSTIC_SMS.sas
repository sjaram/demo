/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS			================================*/
/*==================================    INP_FEEDBACK_ACOUSTIC_SMS	================================*/
/* CONTROL DE VERSIONES
/* 2021-05-12 -- V2 -- Sergio J. --
					-- Modificaciones para optimizar código
					-- Eliminacion de posibles duplicados
					-- Eliminacion tablas periodicas
 
/* 2021-01-16 -- V1 -- David V. --  
					-- Versión Original
/* INFORMACIÓN:
	Disponibiliza el feedback de las campañas en sas.

	(IN) Tablas requeridas o conexiones a BD:
	- /sasdata/users94/user_bi/unica/output/OUTPUT_SMS_&fechaDIA;

	(OUT) Tablas de Salida o resultado:
	- LIBCOMUN.OUTPUT_SMS_&fechaDIA
	- LIBCOMUN.OUTPUT_SMS_&fechaMES


*//*============================================================================================	*/
/*	IMPORTAR ARCHIVO DIARIO CON INFORMACIÓN EMAIL	*/
/*	============================================================================================	*/

/* VARIABLE TIEMPO - INICIO */

%let tiempo_inicio= %sysfunc(datetime());

options validvarname=any;

DATA _null_;
fgenera = compress(input(put(today()-1,yymmdd10.),$10.),"-",c);
dateMES	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/

Call symput("fechaMES", dateMES);
Call symput("fechaDIA",fgenera);
%let libreria=libcomun;

RUN;
%put &fechaDIA;
%put &libreria;
%put &fechaMES;

/*IMPORTACION DEL FEEDBACK SMS*/

proc import datafile="/sasdata/users94/user_bi/unica/output/OUTPUT_SMS_&fechaDIA"
out=test
dbms=dlm replace;
delimiter=';';
getnames=yes;
run;

/*ELIMINACION POSIBLES DUPLICADOS*/

proc sort data=work.test out=work.test2
noduprecs dupout=malos; by _all_;
run;

/*AGREGAR CAMPO DATE PARA TENER UNA FECHA QUE PERMITA FILTRAR*/

Data SMS_DE_PASO;
set test2;
Date = &fechaDIA;
run;


/*	============================================================================================	*/
/*	CREAR TABLA PERIODICA DE - EMAIL	*/
/*	============================================================================================	*/

%MACRO PRUEBA (libreria, fechaMES);

%IF %sysfunc(exist(&libreria..OUTPUT_SMS_&fechaMES.)) %then %do;

PROC SQL;
INSERT INTO &libreria..OUTPUT_SMS_&fechaMES 
SELECT *
FROM  SMS_DE_PASO;

;RUN; 
%end;
%else %do;

PROC SQL;
   CREATE TABLE &libreria..OUTPUT_SMS_&fechaMES. AS 
   SELECT *
      FROM  SMS_DE_PASO;
RUN;
%end;

%mend ;
%PRUEBA (&libreria., &fechaMES.);

/*ELIMINACION TABLAS TEMPORALES*/

proc sql noprint;
drop table test;
quit;
proc sql noprint;
drop table test2;
quit;
proc sql noprint;
drop table SMS_DE_PASO;
quit;


/* VARIABLE TIEMPO - FIN */
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
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;


data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1", "&DEST_2")
SUBJECT = ("MAIL_AUTOM: TEST - Proceso INP_FEEDBACK_ACOUSTIC_SMS");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso INP_FEEDBACK_ACOUSTIC_SMS, ejecutado con fecha: &fechaeDVN";  
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 02'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
