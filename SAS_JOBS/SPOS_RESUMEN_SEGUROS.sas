/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	SPOS_RESUMEN_SEGUROS 		 	 ===============================*/

/* CONTROL DE VERSIONES
/* 2022-11-25 -- v01 -- David V.	-- Comentarios, correo de notificación y librería result para server.
/* 2022-11-25 -- v00 -- Kevin G.	-- Original
/*

/* VARIABLE TIEMPO - INICIO */
%let tiempo_inicio= %sysfunc(datetime());
options validvarname=any;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

%let libreria=RESULT;

%macro seguros(N,libreria);

proc sql;
create table vista as 
select 
*,
count(distinct CATE_NOMBRE) as cant
from &libreria..RSAT_FIDENS
where prod_codigo is not null
group by TRA_VALOR
;QUIT;

proc sql;
create table vista2 as 
select distinct 

TRA_VALOR,
case when cant>1 then 'MIXTO' else CATE_NOMBRE    end as nombre
from vista
;QUIT;

DATA _null_;
PERIODO = input(put(intnx('month',today(),-&N.,'same'),yymmn6. ),$10.);
Call symput("PERIODO", PERIODO);
RUN;

%put &PERIODO;

proc sql;
create table cruce_seguros as 
select 
a.*,
b.nombre
from publicin.trx_seguros_&periodo. as a 
left join vista2 as b
on(b.TRA_VALOR=a.CODCONREC)
where CODCONREC not in ('S201','S083','S170')
and TIPO_SEGURO<>'SEGUROS TARJETA'
and (rut<>17519002 and monto_recaudado<>476454338)
;QUIT;

proc sql;
create table resumen as 
select 
nombre,
sum(MONTO_RECAUDADO) as MONTO_RECAUDADO,
count(rut) as trx,
count(distinct rut) as CLIENTES
from cruce_seguros
group by nombre
;QUIT;

proc sql;
delete * from &libreria..spos_resumen_seguros

where periodo=&periodo.
;QUIT;

proc sql;
insert into  &libreria..spos_resumen_seguros 
select 
&periodo. as periodo,
*
from resumen
;QUIT;

proc sql;
create table  &libreria..spos_resumen_seguros  as 
select 
*
from  &libreria..spos_resumen_seguros
;QUIT;

proc sql;
drop table resumen;
drop table cruce_seguros;
;QUIT;

%mend seguros ;

%seguros(	0,&libreria.);
%seguros(	1,&libreria.);

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================        EXPORT_TO_AWS - INI          ===============================*/

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(spos_resumen_seguros,raw,oracloud,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(spos_resumen_seguros,&libreria..spos_resumen_seguros,raw,oracloud,0);

/*==============================        EXPORT_TO_AWS - END          ===============================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

proc sql noprint;                              
SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_SPOS_2';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4",'&DEST_5')
CC = ("&DEST_1","&DEST_2","&DEST_3")
SUBJECT="MAIL_AUTOM: Proceso SPOS_RESUMEN_SEGUROS" ;
FILE OUTBOX;
	PUT 'Estimados:';
 	PUT "		Proceso SPOS_RESUMEN_SEGUROS, ejecutado.";  
	PUT;
	PUT;
	PUT;
	PUT 'Proceso Vers. 01';
	PUT;
	PUT;
	PUT 'Atte.';
	PUT 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;
FILENAME OUTBOX CLEAR;

/* VARIABLE TIEMPO - FIN */
data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;
