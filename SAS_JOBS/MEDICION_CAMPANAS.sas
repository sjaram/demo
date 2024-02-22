options validvarname=any;
/*Se tiene que ejecutar día por día  */

%let libreria=result;

DATA _null_;


n='0';
Call symput("n", n);
RUN;

%put &n;


DATA _null_;
periodo_actual = input(put(intnx('month',today(),&n.,'begin'),yymmn6. ),$10.) ;
periodo_1 = input(put(intnx('month',today(),&n.-1,'begin'),yymmn6. ),$10.) ;
dia_actual= put(intnx('month',today(),&n.,'same'),yymmddn8.); /* Formato 20220901*/
dia_actual2=input(put(intnx('month',today()-1,&n.,'same'), date9.), date9.);

Call symput("periodo_actual", periodo_actual);
Call symput("periodo_1", periodo_1);
Call symput("dia_actual", dia_actual);
Call symput("dia_actual2", dia_actual2);
RUN;



%put &periodo_actual;
%put &periodo_1;
%put &dia_actual;
%put &dia_actual2;



/*Campañas a ser procesadas */
proc sql;
create table base_campaña as 
select * 
from jgonzale.Base_campanhas_&periodo_actual.
where 	INPUT(fecha_envio, DATE9.) <= &dia_actual2. 
;quit;


/*Logueos */
proc sql;
create table log_mes_actual as
select  rut,max(fecha_logueo)format=date9. as fecha_logueo,
max(case when tipo_logueo='HB' then 'HB'
when tipo_logueo='APP' then 'APP' end ) as tipo_log
from publicin.logeo_int_&periodo_actual.
where fecha<=&dia_actual.
group by RUT
;quit;



/*Cruce campañas con logueos  */

proc sql;
create table cruce as 
select 
a.periodo,
a.id_campaña,
a.campaña,
a.medio,
a.rut,
input(fecha_envio, date9.) format=date9. as fecha_envio,
case when b.rut is not null  then 1 else 0 end  as log,
case when (b.rut is not null and b.fecha_logueo - input(a.fecha_envio, date9.)>=0 ) then 1 else 0 end  as log_post_envio,
case when (b.rut is not null and b.fecha_logueo - input(a.fecha_envio, date9.)>=0 )
then b.fecha_logueo - input(a.fecha_envio, date9.)
else -1 end as dias_log,
case when (b.rut is not null and b.fecha_logueo - input(a.fecha_envio, date9.)>=0) then b.tipo_log
else 'No hizo log' end as tipo_log,
a.edad,
a.tramo_edad,
a.tramo_renta,
a.gse,
a.region,
a.comuna,
a.segmento
from base_campaña a
left join log_mes_actual b
on a.rut=b.rut
;quit;

/*Limpiamos base consolidad de clientes que no se han logueado */
proc sql;
delete from &libreria..consolidado_campaña_&periodo_actual.
where log_post_envio=0 
;quit;

/*Marcamos clientes que ya hicieron login */
proc sql;
create table cruce_fil as 
select a.*,case when b.rut is not null then 1 else 0 end as procesado
from cruce as a
left join ( select * from  &libreria..consolidado_campaña_&periodo_actual. where log_post_envio=1) as b
on a.rut=b.rut and a.campaña=b.campaña and a.fecha_envio=b.fecha_envio
;quit;

/*Insertamos clientes que no han sido procesados anteriormente */
proc sql;
insert into  &libreria..consolidado_campaña_&periodo_actual.
select 
periodo,
id_campaña,
campaña,
medio,
rut,
fecha_envio,
log,
log_post_envio,
dias_log,
tipo_log,
edad,
tramo_edad,
tramo_renta,
gse,
region,
comuna,
segmento
from cruce_fil
where procesado=0
;quit;


/* Tabla Resumen */


proc sql;
create table  work.resumen_&periodo_actual. as 
select 
id_campaña,campaña,medio,fecha_envio,
count(rut) as n_clientes,
count(case when log_post_envio=1 then rut end ) as cantidad_log,
count(case when log_post_envio=1 and dias_log<=5 then rut end ) as _5_dias,
count(case when log_post_envio=1 and dias_log<=10 then rut end ) as _10_dias,
count(case when log_post_envio=1 and dias_log<=15 then rut end ) as _15_dias,
count(case when log_post_envio=1 and dias_log<=20 then rut end ) as _20_dias,
count(case when log_post_envio=1 and dias_log<=30 then rut end ) as _30_dias,
count(case when log_post_envio=1 and dias_log<=5 then rut end )/count(rut) as Efectividad_5_dias,
count(case when log_post_envio=1 and dias_log<=10 then rut end )/count(rut) as Efectividad_10_dias,
count(case when log_post_envio=1 and dias_log<=15 then rut end )/count(rut) as Efectividad_15_dias,
count(case when log_post_envio=1 and tipo_log='HB' then rut end ) as canal_HB,
count(case when log_post_envio=1 and tipo_log='APP' then rut end ) as canal_APP
from  &libreria..consolidado_campaña_&periodo_actual.
group by id_campaña,campaña,medio,fecha_envio
;quit;




PROC EXPORT DATA =  work.resumen_&periodo_actual.
/*OUTFILE="/sasdata/users94/user_bi/unica/INPUT-TR_CAMPANAS-&USUARIO..csv"*/
OUTFILE="/sasdata/users94/user_bi/unica/input/resumen_&periodo_actual..csv"
DBMS=dlm REPLACE;
delimiter=',';
PUTNAMES=YES;
RUN;

data _null_;
FILENAME OUTBOX EMAIL
SUBJECT="MAIL_AUTOM: Actualización Resumen Desempeño Campañas  %sysfunc(date(),yymmdd10.)"
FROM = ("nverdejog@bancoripley.com")
TO = ("apinedar@bancoripley.com")
 CC      = ("nverdejog@bancoripley.com","rarcosm@bancoripley.com","mgalazh@bancoripley.com","tpiwonkas@bancoripley.com")
	attach =("/sasdata/users94/user_bi/unica/input/resumen_&periodo_actual..csv" content_type="excel") 
	  Type    = 'Text/Plain';

FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Datos actualizados al &dia_actual. resumen desempeño campañas";  
 put ; 
 put ; 
 PUT ;
PUT 'Atte.';
Put 'Nicolás Verdejo';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;




