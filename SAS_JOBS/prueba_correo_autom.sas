/*ods html file="/sasdata/users94/user_bi/sergio.html";*/

DATA _null_;
fgenera = compress(input(put(today()-1,yymmdd10.),$10.),"-",c);
dateMES	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/

Call symput("fechaMES", dateMES);
DATA _null_;
fgenera = compress(input(put(today()-1,yymmdd10.),$10.),"-",c);
Call symput("fechaDIA",fgenera);
RUN;
%let libreria=libcomun;
%put &fechaDIA;
%put &libreria;
%put &fechaMES;


proc sql;
create table count_id as
select count(EMAIL) AS COUNT_EMAIL,
COUNT(AREA) AS AREA
from RESULT.EDP_BI_DESTINATARIOS;
quit;

FILENAME    output EMAIL
FROM    = "equipo_datos_procesos_bi@BANCORIPLEY.com"
TO      = ("dvasquez@BANCORIPLEY.com","SJARAM@BANCORIPLEY.COM")
SUBJECT = "Ejecución de Proceso FEEDBACK EMAIL" CONTENT_TYPE="text/html"    
CT      = "text/html";
ODS LISTING CLOSE;
ODS HTML path   = "/sasdata/users94/user_bi" file = "prueba_correo_autom.lst" (URL=none) BODY=output STYLE=sasweb;
TITLE height=16p J=left;
TITLE color = purple "PRIMERA LINEA - prueba 1003";
TITLE2  " ";
TITLE3 height=8pt color=red 
        "Linea 3";
TITLE4  " ";
TITLE5  color = black
        "Linea 5";
TITLE6  " ";
TITLE7 color = blue 
        "Linea 7 ";
footnote "Que tengas un gran gran Día! &fechaDIA";
 PROC PRINT DATA=count_id NOOBS;
RUN;
FILENAME OUTBOX CLEAR;
ODS HTML CLOSE;
ODS LISTING;



/*FILENAME output EMAIL*/
/*SUBJECT= "Ejecucion de FEEDBACK EMAIL"*/
/*FROM= "equipo_datos_procesos_bi@bancoripley.com"*/
/*TO= ("sjaram@bancoripley.com")*/
/*CT= "text/html" /* Required for HTML output */ ;*/
/*ODS HTML BODY=output STYLE=sasweb;*/
/*TITLE JUSTIFY=left;*/
/*PROC REPORT DATA=count_id NOWD*/
/*STYLE(REPORT)=[PREHTML="<hr>"] /*Inserts a rule between title & body*/;*/
/*RUN;*/
/*ODS HTML CLOSE;*/;
/**/
/*	FILENAME output EMAIL*/
/*	FROM= "equipo_datos_procesos_bi@BANCORIPLEY.com"*/
/*	TO= ("sjaram@BANCORIPLEY.com","dvasquez@BANCORIPLEY.com")*/
/*	SUBJECT= "Ejecución de Proceso FEEDBACK EMAIL"*/
/*	CT= "text/html" /* Required for HTML output */;*/
/*	*/
/*	FILENAME mail EMAIL TO=("sjaram@BANCORIPLEY.com")*/
/* 	SUBJECT="HTML OUTPUT" CONTENT_TYPE="text/html";*/
/*	ODS LISTING CLOSE;*/
/*	ODS HTML  path="/sasdata/users94/user_bi" file = "prueba_correo_autom.lst" (URL=none) BODY=output STYLE=sasweb;*/
/*	TITLE JUSTIFY=left;*/
/*	TITLE "Estimados, el proceso Feedback fue ejecutado con fecha &fechaDIA";*/
/*ods html text = "Estimados el proceso INP_FEEDBACK_ACOUSTIC_EMAIL_&fechaDIA fue ejecutado correctamente.*/
/*La Data se encuentra disponible en la libreria COMUNICACIONES (POR SAS LIBCOMUN)";*/
/*ods html text ="    ";*/
/*ods html text ="    ";*/
/*ods html text ="saludos";*/
/*ods html text ="    ";*/
/*ods html text =" Que tengas una buena semana";*/
/**/
/*	PROC PRINT DATA=count_id  NOOBS;*/
/*	RUN;*/
/*ods html text ="    ";*/
/*ods html text ="    ";*/
/*ods html text = "Greetings, Have a Great Day."; */
/*FILENAME OUTBOX CLEAR;*/
/*	ODS HTML CLOSE;*/
/*	ODS LISTING;*/
/**/
/*proc sql;*/
/*drop table count_id;*/
/*quit;*/

/**/
/*filename OUTBOX email*/
/*to = ( "sjaram@BANCORIPLEY.com" )*/
/*/*cc = ("xxxxx@xxxx.com" )*/*/
/*subject="Email With Table"*/
/*type="text/html"*/
/*from = "equipo_datos_procesos_bi@BANCORIPLEY.com" ;*/
/**/
/*ods html path="/sasdata/users94/user_bi" file = "prueba_correo_autom.lst" (URL=none) BODY=outbox STYLE=noline;*/
/*TITLE "Proceso Feedback fue ejecutado con fecha &fechaDIA ";*/
/*ods html text = "Estimados el proceso INP_FEEDBACK_ACOUSTIC_EMAIL_&fechaDIA fue ejecutado correctamente, La Data se encuentra */
/*disponible en la libreria COMUNICACIONES (POR SAS LIBCOMUN)";*/
/**/
/* */
/*PROC REPORT DATA=count_id nowd HEADLINE HEADSKIP;*/
/*run;*/
/*ods html text = "Greetings, Have a Great Day."; */
/*ods _all_ close;*/
