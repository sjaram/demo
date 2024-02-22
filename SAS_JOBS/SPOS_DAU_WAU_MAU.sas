
%let LIBRERIA=RESULT;
%macro MAU_DAU_WAU_SPOS (n,LIBRERIA);


DATA _null_;
periodo_actual = input(put(intnx('month',today(),-&n.,'begin'),yymmn6. ),$10.) ;
ultimo_dia = input(put(intnx('month',today(),-&n.,'end'),date9. ),$10.) ;
Call symput("periodo_actual", periodo_actual);
Call symput("ultimo_dia", ultimo_dia);
RUN;

%put &periodo_actual;
%put &ultimo_dia;

%if (%sysfunc(exist(publicin.spos_aut_&periodo_actual.))) %then %do;
PROC SQL  ;
create table  spos as 
select  
rut,
fecha,
1 as tc,
0 as td,
sum(venta_tarjeta) as monto
from publicin.spos_aut_&periodo_actual.
group by rut,fecha
;QUIT;
 
%end;
%else %do;
PROC  SQL;
CREATE TABLE spos (
rut num,
fecha nu,
tc num,
td num,
monto num)
;RUN;
%end;



%if (%sysfunc(exist(publicin.spos_maestro_&periodo_actual.))) %then %do;
PROC SQL  ;
create table  spos_maestro as 
select distinct 
rut,
fecha,
0 as tc,
1 as td,
sum(venta_tarjeta) as monto
from publicin.spos_maestro_&periodo_actual.
group by rut,fecha
;QUIT;
 
%end;
%else %do;
PROC  SQL;
CREATE TABLE spos_maestro (
rut num,
fecha num,
tc num,
td num,
monto num)
;RUN;
%end;

%if (%sysfunc(exist(publicin.spos_mcd_&periodo_actual.))) %then %do;
PROC SQL  ;
create table  spos_mcd as 
select distinct 
rut,
fecha,
0 as tc,
1 as td,
sum(venta_tarjeta) as monto 
from publicin.spos_mcd_&periodo_actual.
group by rut,fecha
;QUIT;
 
%end;
%else %do;
PROC  SQL;
CREATE TABLE spos_mcd (
rut num,
fecha num,
tc num,
td num,
monto num)
;RUN;
%end;


PROC SQL  ;
create table  spos_seg as 
select distinct 
rut,
input(compress(FECPROCES,'-'),best.) as fecha,
1 as tc,
0 as td
from publicin.trx_seguros_&periodo_actual.
where CODCONREC not in ('S201','S083','S170')
and TIPO_SEGURO<>'SEGUROS TARJETA'
and (rut<>17519002 and monto_recaudado<>476454338)
;QUIT;
 

%if (%sysfunc(exist(publicin.spos_CTACTE_&periodo_actual.))) %then %do;
PROC SQL  ;
create table  spos_CTACTE as 
select distinct 
rut,
fecha,
0 as tc,
1 as td,
sum(venta_tarjeta) as monto 
from publicin.spos_CTACTE_&periodo_actual.
group by rut,fecha
;QUIT;
 
%end;
%else %do;
PROC  SQL;
CREATE TABLE spos_CTACTE (
rut num,
fecha num,
tc num,
td num,
monto num)
;RUN;
%end;




proc sql;
create table clientes as 
select *, 'TC' as marcaje
from spos
where rut is not null
outer union corr  
select  *,'TD' as marcaje
from spos_mcd 
where rut is not null
outer union corr  
select  *,'TD' as marcaje
from spos_maestro
where rut is not null
outer union corr  
select  * ,'SEG' as marcaje
from spos_seg
where rut is not null
outer union corr 
select  * ,'TD' as marcaje
from spos_CTACTE
where rut is not null
;QUIT;



proc sql;
create table cliente_unico_acum 
(dia num,
cantidad_TOTAL num,
cantidad_TC num,
cantidad_TD num
)
;QUIT;


proc sql noprint;
select distinct 
day("&ultimo_dia."d) as dia
into:dia
from sashelp.air
;QUIT;

%put &dia;


%macro acumular (dia);

%do i=1 %to &dia.;

%put ###########################   &i. ######################################;


proc sql;
create table paso_foto as 
select rut,
tc,	
td,
sum(monto) as monto2
from spos
where rut is not null and 
fecha-floor(fecha/100)*100<=&i.
group by rut,tc,td
having calculated monto2>0
outer union corr  
select rut,tc,	td,sum(monto) as monto2
from spos_MCD
where rut is not null and 
fecha-floor(fecha/100)*100<=&i.
group by rut,tc,	td
having calculated monto2>0
outer union corr  
select rut,tc,	td,sum(monto) as monto2
from spos_Maestro
where rut is not null and 
fecha-floor(fecha/100)*100<=&i.
group by rut,tc,	td
having calculated monto2>0
outer union corr  
select rut,tc,	td
from spos_seg
where rut is not null and 
fecha-floor(fecha/100)*100<=&i.
outer union corr 
select rut,tc,	td,sum(monto) as monto2
from spos_CTACTE
where rut is not null and 
fecha-floor(fecha/100)*100<=&i.
group by rut,tc,	td
having calculated monto2>0
;QUIT;


proc sql;
create table foto as 
select 
&i. as dia,
count(distinct rut) as cantidad_TOTAL,
count(distinct case when tc=1 then  rut end) as cantidad_TC,
count(distinct case when td=1 then  rut end) as cantidad_TD
from paso_foto
;QUIT;

proc sql;
insert into cliente_unico_acum
select * 
from foto
;QUIT;

proc sql;
drop table foto;
drop table paso_foto;
;QUIT;

%end;


%mend acumular;

%acumular(&dia.);


proc sql;
create table paso_total as 
select rut,
tc,	
td,
fecha,
sum(monto) as monto2
from spos
where rut is not null
group by rut,tc,fecha,td
having calculated monto2>0
outer union corr  
select rut,tc,	td,fecha,sum(monto) as monto2
from spos_MCD
where rut is not null 
group by rut,tc,fecha,	td
having calculated monto2>0
outer union corr  
select rut,tc,	td,fecha,sum(monto) as monto2
from spos_Maestro
where rut is not null  
group by rut,tc,fecha,	td
having calculated monto2>0
outer union corr  
select rut,tc,	td,fecha
from spos_seg
where rut is not null  
outer union corr 
select rut,tc,	td,fecha,sum(monto) as monto2
from spos_CTACTE
where rut is not null  
group by rut,tc,fecha,	td
having calculated monto2>0
;QUIT;

proc sqL;
create table vista_dia_total as 
select 
fecha,
count(distinct    rut  ) as cantidad_TOTAL,
count(distinct case when tc=1  then  rut end) as cantidad_TC,
count(distinct case when td=1  then  rut end) as cantidad_TD
from paso_total
group by fecha
;QUIT;



proc sql;
create table paso_semana as 
select rut,
tc,	
td,
case when fecha-floor(fecha/100)*100 between 1 and 7 then 'SEMANA 1 '
when fecha-floor(fecha/100)*100 between 8 and 14 then 'SEMANA 2 '
when fecha-floor(fecha/100)*100 between 15 and 21 then 'SEMANA 3 '
when fecha-floor(fecha/100)*100 >=22 then 'SEMANA 4 ' end as semana,
sum(monto) as monto2
from spos
where rut is not null
group by rut,tc,calculated semana,td
having calculated monto2>0
outer union corr  
select rut,tc,	td,case when fecha-floor(fecha/100)*100 between 1 and 7 then 'SEMANA 1 '
when fecha-floor(fecha/100)*100 between 8 and 14 then 'SEMANA 2 '
when fecha-floor(fecha/100)*100 between 15 and 21 then 'SEMANA 3 '
when fecha-floor(fecha/100)*100 >=22 then 'SEMANA 4 ' end as semana,sum(monto) as monto2
from spos_MCD
where rut is not null 
group by rut,tc,calculated semana,	td
having calculated monto2>0
outer union corr  
select rut,tc,	td,case when fecha-floor(fecha/100)*100 between 1 and 7 then 'SEMANA 1 '
when fecha-floor(fecha/100)*100 between 8 and 14 then 'SEMANA 2 '
when fecha-floor(fecha/100)*100 between 15 and 21 then 'SEMANA 3 '
when fecha-floor(fecha/100)*100 >=22 then 'SEMANA 4 ' end as semana,sum(monto) as monto2
from spos_Maestro
where rut is not null  
group by rut,tc,calculated semana,	td
having calculated monto2>0
outer union corr  
select rut,tc,	td,case when fecha-floor(fecha/100)*100 between 1 and 7 then 'SEMANA 1 '
when fecha-floor(fecha/100)*100 between 8 and 14 then 'SEMANA 2 '
when fecha-floor(fecha/100)*100 between 15 and 21 then 'SEMANA 3 '
when fecha-floor(fecha/100)*100 >=22 then 'SEMANA 4 ' end as semana
from spos_seg
where rut is not null  
outer union corr 
select rut,tc,	td,case when fecha-floor(fecha/100)*100 between 1 and 7 then 'SEMANA 1 '
when fecha-floor(fecha/100)*100 between 8 and 14 then 'SEMANA 2 '
when fecha-floor(fecha/100)*100 between 15 and 21 then 'SEMANA 3 '
when fecha-floor(fecha/100)*100 >=22 then 'SEMANA 4 ' end as semana,sum(monto) as monto2
from spos_CTACTE
where rut is not null  
group by rut,tc,calculated semana,	td
having calculated monto2>0
;QUIT;

proc sql;
create table vista_semana_total as 
select 
semana,
count(distinct rut) as cantidad_TOTAL,
count(distinct case when tc=1 then  rut end) as cantidad_TC,
count(distinct case when td=1 then  rut end) as cantidad_TD
from paso_semana
group by semana
;QUIT;



proc sql;
create table paso_fin as 
select rut,
tc,	
td,
sum(monto) as monto2
from spos
where rut is not null
group by rut,tc,td
having calculated monto2>0
outer union corr  
select rut,tc,	td,sum(monto) as monto2
from spos_MCD
where rut is not null 
group by rut,tc,	td
having calculated monto2>0
outer union corr  
select rut,tc,	td,sum(monto) as monto2
from spos_Maestro
where rut is not null  
group by rut,tc,	td
having calculated monto2>0
outer union corr  
select rut,tc,	td
from spos_seg
where rut is not null  
outer union corr 
select rut,tc,	td,sum(monto) as monto2
from spos_CTACTE
where rut is not null  
group by rut,tc,	td
having calculated monto2>0
;QUIT;

proc sql;
create table colapso_SPOS as 
select 
'VISTA DIA' as PARAMETRO,
*
from cliente_unico_acum
union select 
'DAU' as parametro,
. as dia,
round(avg(cantidad_TOTAL)) as cantidad_TOTAL,
round(avg(cantidad_TC)) as cantidad_TC,
round(avg(cantidad_TD)) as cantidad_TD
from vista_dia_total
union 
select 
'MAU' as PARAMETRO,
. as dia,
count(distinct rut ) as cantidad_TOTAL,
count(distinct case when tc=1 then  rut end) as cantidad_TC,
count(distinct case when td=1 then  rut end) as cantidad_TD
from paso_fin
union 
select 
'WAU' as PARAMETRO,
. as dia,
round(avg(cantidad_TOTAL)) as cantidad_TOTAL,
round(avg(cantidad_TC)) as cantidad_TC,
round(avg(cantidad_TD)) as cantidad_TD
from vista_semana_total

;QUIT;

%PUT###################################################;
%PUT VISTA TDA;
%PUT###################################################;



%if (%sysfunc(exist(publicin.tda_itf_&periodo_actual.))) %then %do;
PROC SQL  ;
create table  tda as 
select  
rut,
fecha,
1 as tc,
sum(capital+pie) as monto
from publicin.tda_itf_&periodo_actual.
group by rut,fecha
;QUIT;
 
%end;
%else %do;
PROC  SQL;
CREATE TABLE tda (
rut num,
fecha date,
tc num,
monto num)
;RUN;
%end;





proc sql;
create table clientes as 
select *, 'TC' as marcaje
from tda
where rut is not null
;QUIT;



proc sql;
create table cliente_unico_acum 
(dia num,
cantidad_TOTAL num,
cantidad_TC num
)
;QUIT;


proc sql noprint;
select distinct 
day("&ultimo_dia."d) as dia
into:dia
from sashelp.air
;QUIT;

%put &dia;


%macro acumular (dia);

%do i=1 %to &dia.;

%put ###########################   &i. ######################################;


proc sql;
create table paso_foto as 
select rut,
tc,
sum(monto) as monto2
from tda
where rut is not null and 
day(fecha)<=&i.
group by rut,tc
having calculated monto2>0
;QUIT;


proc sql;
create table foto as 
select 
&i. as dia,
count(distinct rut) as cantidad_TOTAL,
count(distinct case when tc=1 then  rut end) as cantidad_TC
from paso_foto
;QUIT;

proc sql;
insert into cliente_unico_acum
select * 
from foto
;QUIT;

proc sql;
drop table foto;
drop table paso_foto;
;QUIT;

%end;


%mend acumular;

%acumular(&dia.);


proc sql;
create table paso_total as 
select rut,
tc,	
fecha,
sum(monto) as monto2
from tda
where rut is not null
group by rut,tc,fecha
having calculated monto2>0
;QUIT;

proc sqL;
create table vista_dia_total as 
select 
fecha,
count(distinct    rut  ) as cantidad_TOTAL,
count(distinct case when tc=1  then  rut end) as cantidad_TC
from paso_total
group by fecha
;QUIT;



proc sql;
create table paso_semana as 
select rut,
tc,	
case when day(fecha) between 1 and 7 then 'SEMANA 1 '
when day(fecha) between 8 and 14 then 'SEMANA 2 '
when day(fecha) between 15 and 21 then 'SEMANA 3 '
when day(fecha) >=22 then 'SEMANA 4 ' end as semana,
sum(monto) as monto2
from tda
where rut is not null
group by rut,tc,calculated semana
having calculated monto2>0
;QUIT;

proc sql;
create table vista_semana_total as 
select 
semana,
count(distinct rut) as cantidad_TOTAL,
count(distinct case when tc=1 then  rut end) as cantidad_TC
from paso_semana
group by semana
;QUIT;



proc sql;
create table paso_fin as 
select rut,
tc,	
sum(monto) as monto2
from tda
where rut is not null
group by rut,tc
having calculated monto2>0
;QUIT;

proc sql;
create table colapso_TDA as 
select 
'VISTA DIA' as PARAMETRO,
*
from cliente_unico_acum
union select 
'DAU' as parametro,
. as dia,
round(avg(cantidad_TOTAL)) as cantidad_TOTAL,
round(avg(cantidad_TC)) as cantidad_TC
from vista_dia_total
union 
select 
'MAU' as PARAMETRO,
. as dia,
count(distinct rut ) as cantidad_TOTAL,
count(distinct case when tc=1 then  rut end) as cantidad_TC
from paso_fin
union 
select 
'WAU' as PARAMETRO,
. as dia,
round(avg(cantidad_TOTAL)) as cantidad_TOTAL,
round(avg(cantidad_TC)) as cantidad_TC
from vista_semana_total

;QUIT;

%if (%sysfunc(exist(&LIBRERIA..SPOS_MAU_DAU_WAU))) %then %do;
 
%end;
%else %do;
PROC  SQL;
CREATE TABLE &LIBRERIA..SPOS_MAU_DAU_WAU (
negocio char(20),
periodo	num,
PARAMETRO char(20),
dia num,
cantidad_TOTAL num,
cantidad_TC num,
cantidad_TD num
)
;RUN;
%end;


proc sql;
delete * from &LIBRERIA..SPOS_MAU_DAU_WAU
where periodo=&periodo_actual.
;QUIT;

proc sql;
insert into  &LIBRERIA..SPOS_MAU_DAU_WAU  
select 
'SPOS' as negocio,
&periodo_actual. as periodo,
*
from  colapso_spos
outer union corr 
select 
'TDA' as negocio,
&periodo_actual. as periodo,
*
from  colapso_TDA
;QUIT;


proc sql;
create table   &LIBRERIA..SPOS_MAU_DAU_WAU as   
select 
*
from  &LIBRERIA..SPOS_MAU_DAU_WAU
;QUIT;

proc datasets library=WORK kill noprint;
run;
quit;

%mend MAU_DAU_WAU_SPOS;

%MAU_DAU_WAU_SPOS(	0,&LIBRERIA.	);
%MAU_DAU_WAU_SPOS(	1,&LIBRERIA.	);

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================        EXPORT_TO_AWS - INI          ===============================*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(spos_mau_dau_wau,raw,oracloud,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(spos_mau_dau_wau,&libreria..SPOS_MAU_DAU_WAU,raw,oracloud,0);

/*==============================        EXPORT_TO_AWS - END          ===============================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/





proc sql noprint;                              
SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4",'jsantamaria@bancoripley.com','fmunozh@bancoripley.com','mbentjerodts@bancoripley.com',
'bschmidtm@bancoripley.com','crachondode@bancoripley.com')
CC = ("&DEST_1","&DEST_2","&DEST_3")
SUBJECT="MAIL_AUTOM: MAU DAU WAU " ;
FILE OUTBOX;
	PUT 'Estimados:';
	PUT ; 
 	PUT "Proceso MAU DAU WAU, ejecutado.";  
    PUT;
    PUT;
    put 'Proceso Vers. 02';
    PUT;
    PUT;
    PUT 'Atte.';
    Put 'Equipo Arquitectura de Datos y Automatización BI';
    PUT;
RUN;
FILENAME OUTBOX CLEAR;
