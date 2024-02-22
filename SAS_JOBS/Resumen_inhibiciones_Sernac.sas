/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	RESUMEN_INHIBICIONES_SERNAC	================================*/
/* CONTROL DE VERSIONES

/* 2021-07-27 -- V01 -- Sergio.J -- Versión original
*/

/*RESUMEN DE INHIBICION POR DÍA*/
DATA _NULL_;
ant = put(intnx('day',today(),0,'same'),date9.);
Call symput("ant",ant);
run;
%put &ant;

proc sql;
create table resumen_fono as 
select distinct 
TIPO_INHIBICION,
max(FECHA_INGRESO) format=date9. as FECHA_INGRESO,
count(fono) as Q_TELEFONOS
from publicin.lnegro_call 
where FECHA_INGRESO = "&ant."d and TIPO_INHIBICION ~= "LISTA_NEGRA_CALL"
group by 
TIPO_INHIBICION
;QUIT;

proc sql;
create table resumen_sms as 
select distinct
TIPO_INHIBICION,
max(FECHA_INGRESO) format=date9. as FECHA_INGRESO,
count(fono) as Q_SMS
from publicin.lnegro_sms
where FECHA_INGRESO = "&ant."d
group by 
TIPO_INHIBICION
;QUIT;

proc sql;
create table resumen_email as 
select distinct
case when MOTIVO="SERNAC_ECCSA" THEN "SERNAC_ECSSA" ELSE MOTIVO END as TIPO_INHIBICION,
max(FECHA_INHIBICION) format=date9. as FECHA_INHIBICION,
count(email) as Q_EMAIL
from publicin.lnegro_email
where FECHA_INHIBICION = "&ant."d 
group by 
motivo
;QUIT;

proc sql;
create table resumen_final as
select t1.TIPO_INHIBICION,
t1.FECHA_INGRESO,
t1.Q_TELEFONOS,
t2.Q_SMS,
t3.Q_EMAIL
from resumen_fono as t1 left join resumen_sms as t2
on (t1.TIPO_INHIBICION=t2.TIPO_INHIBICION)
left join resumen_email as t3
on (t1.TIPO_INHIBICION=t3.TIPO_INHIBICION)
;quit;


FILENAME output EMAIL
SUBJECT= "Resumen inhibiciones SERNAC"
FROM= "sjaram@bancoripley.com"
TO= ("sjaram@BANCORIPLEY.com","dvasquez@bancoripley.com","lmontalbab@bancoripley.com")
cc= ("pfuenzalidam@bancoripley.com","asierrag@bancoripley.com","fsotoga@bancoripley.com")
CT= "text/html" /* Required for HTML output */ ;
ODS LISTING CLOSE;
ODS HTML BODY=output STYLE=sasweb;
TITLE JUSTIFY=left
"Resumen de inhibiciones Sernac para &ant.";
PROC PRINT DATA=WORK.resumen_final NOOBS;
RUN;
ODS HTML CLOSE;
ODS LISTING;
