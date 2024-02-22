/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	ONBOARDING 3M		        ================================*/
/* CONTROL DE VERSIONES
/* 2020-10-26 -- V1 -- David V. --  
					-- Versión Original
/* INFORMACIÓN:
	Programa tipo con comentarios e instrucciones básicas para ser estandarizadas al equipo.

	(IN) Tablas requeridas o conexiones a BD:
	- PUBLICIN.TDA_ITF_AAAAMM
    - PUBLICIN.SPOS_AUT_AAAAMM
    - result.capta_salida


	(OUT) Tablas de Salida o resultado:
	- RESULT.Concrecion_captados
	- ORACLOUD
*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria=RESULT;

%macro concreta_capta(fecha,lib);

%put==================================================================================================;
%put [00] Macro fechas;
%put==================================================================================================;



DATA _null_;
periodo = input(put(intnx('month',&fecha.,0,'end'),yymmn6. ),$10.);
periodo_1 = input(put(intnx('month',&fecha.,1,'end'),yymmn6. ),$10.);
periodo_2 = input(put(intnx('month',&fecha.,2,'end'),yymmn6. ),$10.);

ini = input(put(intnx('month',&fecha.,0,'begin'), date9. ),$10.);
fin = input(put(intnx('month',&fecha.,0,'end'),date9.  ),$10.);

Call symput("periodo", periodo);
Call symput("periodo_1",periodo_1 );
Call symput("periodo_2", periodo_2);
Call symput("ini", ini);
Call symput("fin", fin);

RUN;

%put &periodo;
%put &periodo_1;
%put &periodo_2;
%put &ini;
%put &fin;

%put==================================================================================================;
%put [01] Info capta salida;
%put==================================================================================================;

PROC SQL;
CREATE TABLE WORK.capta_salida AS 
SELECT 
distinct 
t1.RUT_CLIENTE as rut, 
t1.PRODUCTO, 
t1.FECHA, 
year(t1.fecha)*10000+month(t1.fecha)*100+day(t1.fecha) as fecha_num,
t1.cod_sucursal,
t1.LINEA_CREDITO as cupo,
t1.ORIGEN, 
t1.CANAL,  
t1.VIA
FROM RESULT.CAPTA_SALIDA t1
where 
fecha between "&ini."d and "&fin."d
and cod_prod<>4
;QUIT;

%put==================================================================================================;
%put [02] Venta Spos;
%put==================================================================================================;

%if (%sysfunc(exist(publicin.spos_aut_&periodo.))) %then %do;

proc sql;
create table spos_&periodo. as 
select 
t1.Fecha, 
t1.Periodo, 
t1.rut, 
sum(t1.VENTA_TARJETA) as MONTO, 
count(t1.rut) as TRX
from publicin.spos_aut_&periodo. as t1 
inner join capta_salida as b
on(t1.rut=b.rut) and (t1.Fecha>=b.fecha_num)
group by 
t1.periodo,
t1.rut,
t1.fecha
;QUIT;
 
%end;
%else %do;

proc sql;
create table spos_&periodo. (
Fecha num , 
Periodo num, 
rut num, 
VENTA_TARJETA num , 
CODENT char(99), 
CENTALTA char(99), 
CUENTA char(99)) 
;QUIT;

%end;


%if (%sysfunc(exist(publicin.spos_aut_&periodo_1.))) %then %do;

proc sql;
create table spos_&periodo_1. as 
select 
t1.Fecha, 
t1.Periodo, 
t1.rut, 
sum(t1.VENTA_TARJETA) as MONTO, 
count(t1.rut) as TRX
from publicin.spos_aut_&periodo_1. as t1
inner join capta_salida as b
on(t1.rut=b.rut) and (t1.Fecha>=b.fecha_num)
group by 
t1.periodo,
t1.rut,
t1.fecha
;QUIT;
 
%end;
%else %do;

proc sql;
create table spos_&periodo_1. (
Fecha num , 
Periodo num, 
rut num, 
VENTA_TARJETA num , 
CODENT char(99), 
CENTALTA char(99), 
CUENTA char(99)) 
;QUIT;

%end;



%if (%sysfunc(exist(publicin.spos_aut_&periodo_2.))) %then %do;

proc sql;
create table spos_&periodo_2. as 
select 
t1.Fecha, 
t1.Periodo, 
t1.rut, 
sum(t1.VENTA_TARJETA) as MONTO, 
count(t1.rut) as TRX
from publicin.spos_aut_&periodo_2. as t1
inner join capta_salida as b
on(t1.rut=b.rut) and (t1.Fecha>=b.fecha_num)
group by 
t1.periodo,
t1.rut,
t1.fecha
;QUIT;
 
 
%end;
%else %do;

proc sql;
create table spos_&periodo_2. (
Fecha num , 
Periodo num, 
rut num, 
VENTA_TARJETA num , 
CODENT char(99), 
CENTALTA char(99), 
CUENTA char(99)) 
;QUIT;

%end;


%put==================================================================================================;
%put [03] Venta TDA;
%put==================================================================================================;


%if (%sysfunc(exist(publicin.TDA_ITF_&periodo.))) %then %do;

proc sql;
create table TDA_ITF_&periodo. as 
select 
year(t1.Fecha)*10000+month(t1.Fecha)*100+day(t1.Fecha) as fecha, 
year(t1.Fecha)*100+month(t1.Fecha) as Periodo, 
t1.rut, 
sum(t1.capital) as MONTO, 
count(t1.rut) as TRX
from publicin.TDA_ITF_&periodo. as t1 
inner join capta_salida as b
on(t1.rut=b.rut) and (year(t1.Fecha)*10000+month(t1.Fecha)*100+day(t1.Fecha)>=b.fecha_num)
group by 
calculated periodo,
t1.rut,
calculated fecha
;QUIT;
 
 
%end;
%else %do;

proc sql;
create table TDA_ITF_&periodo. (
Fecha num , 
Periodo num, 
rut num, 
VENTA_TARJETA num , 
CODENT char(99), 
CENTALTA char(99), 
CUENTA char(99)) 
;QUIT;

%end;


%if (%sysfunc(exist(publicin.TDA_ITF_&periodo_1.))) %then %do;

proc sql;
create table TDA_ITF_&periodo_1. as 
select 
year(t1.Fecha)*10000+month(t1.Fecha)*100+day(t1.Fecha) as fecha, 
year(t1.Fecha)*100+month(t1.Fecha) as Periodo, 
t1.rut, 
sum(t1.capital) as MONTO, 
count(t1.rut) as TRX
from publicin.TDA_ITF_&periodo_1. as t1
inner join capta_salida as b
on(t1.rut=b.rut) and (year(t1.Fecha)*10000+month(t1.Fecha)*100+day(t1.Fecha)>=b.fecha_num)
group by 
calculated periodo,
t1.rut,
calculated fecha
;QUIT;
 
%end;
%else %do;

proc sql;
create table TDA_ITF_&periodo_1. (
Fecha num , 
Periodo num, 
rut num, 
VENTA_TARJETA num , 
CODENT char(99), 
CENTALTA char(99), 
CUENTA char(99)) 
;QUIT;

%end;



%if (%sysfunc(exist(publicin.TDA_ITF_&periodo_2.))) %then %do;

proc sql;
create table TDA_ITF_&periodo_2. as 
select 
year(t1.Fecha)*10000+month(t1.Fecha)*100+day(t1.Fecha) as fecha, 
year(t1.Fecha)*100+month(t1.Fecha) as Periodo, 
t1.rut, 
sum(t1.capital) as MONTO, 
count(t1.rut) as TRX
from publicin.TDA_ITF_&periodo_2. as t1
inner join capta_salida as b
on(t1.rut=b.rut) and (year(t1.Fecha)*10000+month(t1.Fecha)*100+day(t1.Fecha)>=b.fecha_num)
group by 
calculated periodo,
t1.rut,
calculated fecha
;QUIT;
 
%end;
%else %do;

proc sql;
create table TDA_ITF_&periodo_2. (
Fecha num , 
Periodo num, 
rut num, 
VENTA_TARJETA num , 
CODENT char(99), 
CENTALTA char(99), 
CUENTA char(99)) 
;QUIT;

%end;




%put==================================================================================================;
%put [04] Unir tablas Spos;
%put==================================================================================================;

proc sql;
create table spos_total as 
select 
*
from spos_&periodo.
outer union corr
select 
*
from spos_&periodo_1.
outer union corr
select 
*
from spos_&periodo_2.
;QUIT;

proc sql;
create table min_spos as 
select 
rut,
min(fecha) as fecha 
from spos_total
group by rut
;QUIT;

proc sql;
create table spos_total as 
select a.*
from spos_total as a
inner join min_spos as b
on(a.rut=b.rut) and (a.fecha=b.fecha)
;QUIT;

proc sql;
drop table min_spos
;QUIT;

%put==================================================================================================;
%put [04] Unir tablas Tda;
%put==================================================================================================;

proc sql;
create table TDA_ITF as 
select 
*
from TDA_ITF_&periodo.
outer union corr
select 
*
from TDA_ITF_&periodo_1.
outer union corr
select 
*
from TDA_ITF_&periodo_2.
;QUIT;


proc sql;
create table min_TDA as 
select 
rut,
min(fecha) as fecha 
from TDA_ITF
group by rut
;QUIT;

proc sql;
create table TDA_ITF as 
select a.*
from TDA_ITF as a
inner join min_TDA as b
on(a.rut=b.rut) and (a.fecha=b.fecha)
;QUIT;

proc sql;
drop table min_TDA
;QUIT;


%put==================================================================================================;
%put [06] Primer cruce, minima fecha de compra spos y tda;
%put==================================================================================================;

proc sql;
create table cruce as 
select distinct  
a.*,
/*TODO SPOS*/
case when b.periodo=&periodo. then '01.Mes actual' 
when b.periodo=&periodo_1. then '02.Mes Siguiente' 
when b.periodo=&periodo_2. then '03.Mes Subsiguiente' 
else '04.Sin Compra' end as Concrecion_SPOS,
sum(case when b.rut is not null then b.monto else 0 end ) as monto_SPOS,
sum(case when b.rut is not null then b.TRX else 0 end ) as TRX_SPOS,
coalesce(b.fecha-floor(b.fecha/100)*100,.) as fecha_spos,

/*TODO TDA*/
case when c.periodo=&periodo. then '01.Mes actual' 
when c.periodo=&periodo_1. then '02.Mes Siguiente' 
when c.periodo=&periodo_2. then '03.Mes Subsiguiente' 
else '04.Sin Compra' end as Concrecion_tda,
sum(case when c.rut is not null then c.monto else 0 end ) as monto_tda,
sum(case when c.rut is not null then c.TRX else 0 end ) as TRX_tda,
coalesce(c.fecha-floor(c.fecha/100)*100,.) as fecha_tda,

/*SOLO SPOS*/

case when b.periodo=&periodo. and c.rut is null then '01.Mes actual' 
when b.periodo=&periodo_1.  and c.rut is null  then '02.Mes Siguiente' 
when b.periodo=&periodo_2.  and c.rut is null  then '03.Mes Subsiguiente' 
else '04.Sin Compra' end as Concrecion_spos_UNI,
sum(case when b.rut is not null and c.rut is null then b.monto else 0 end ) as monto_SPOS_UNI,
sum(case when b.rut is not null and c.rut is null then b.TRX else 0 end ) as TRX_spos_uni,
case when b.rut is not null and c.rut is null
then b.fecha-floor(b.fecha/100)*100 else . end as fecha_spos_uni,

/*SOLO TDA*/

case when c.periodo=&periodo. and b.rut is null then '01.Mes actual' 
when c.periodo=&periodo_1.  and b.rut is null  then '02.Mes Siguiente' 
when c.periodo=&periodo_2.  and b.rut is null  then '03.Mes Subsiguiente' 
else '04.Sin Compra' end as Concrecion_tda_UNI,
sum(case when c.rut is not null and b.rut is null then c.monto else 0 end ) as monto_tda_UNI,
sum(case when c.rut is not null and b.rut is null then c.TRX else 0 end ) as TRX_tda_uni,
case when c.rut is not null and b.rut is null
then c.fecha-floor(c.fecha/100)*100 else . end as fecha_tda_uni,

/*TDA + SPOS*/

case 
when c.rut is not null and  b.rut is not null and c.periodo=b.periodo and c.periodo=&periodo. then '01.Mes actual'
when c.rut is not null and  b.rut is not null and c.periodo=b.periodo and c.periodo=&periodo_1. then '02.Mes Siguiente'
when c.rut is not null and  b.rut is not null and c.periodo=b.periodo and c.periodo=&periodo_2. then '03.Mes Subsiguiente'
when c.rut is not null and  b.rut is not null and c.periodo<>b.periodo 
and min(b.periodo,c.periodo)=&periodo. then '01.Mes actual'
when c.rut is not null and  b.rut is not null and c.periodo<>b.periodo 
and min(b.periodo,c.periodo)=&periodo_1. then '02.Mes Siguiente'
when c.rut is not null and  b.rut is not null and c.periodo<>b.periodo 
and min(b.periodo,c.periodo)=&periodo_2. then '03.Mes Subsiguiente'
else '04.Sin Compra' end as Concrecion_tda_spos,

case 
when c.rut is not null and  b.rut is not null and c.periodo=b.periodo and c.periodo=&periodo. then min(c.fecha-floor(c.fecha/100)*100,b.fecha-floor(b.fecha/100)*100)
when c.rut is not null and  b.rut is not null and c.periodo=b.periodo and c.periodo=&periodo_1. then min(c.fecha-floor(c.fecha/100)*100,b.fecha-floor(b.fecha/100)*100)
when c.rut is not null and  b.rut is not null and c.periodo=b.periodo and c.periodo=&periodo_2. then min(c.fecha-floor(c.fecha/100)*100,b.fecha-floor(b.fecha/100)*100)
when c.rut is not null and  b.rut is not null and c.periodo<>b.periodo 
and min(b.periodo,c.periodo)=&periodo. then min(c.fecha-floor(c.fecha/100)*100,b.fecha-floor(b.fecha/100)*100)
when c.rut is not null and  b.rut is not null and c.periodo<>b.periodo 
and min(b.periodo,c.periodo)=&periodo_1. then min(c.fecha-floor(c.fecha/100)*100,b.fecha-floor(b.fecha/100)*100)
when c.rut is not null and  b.rut is not null and c.periodo<>b.periodo 
and min(b.periodo,c.periodo)=&periodo_2. then min(c.fecha-floor(c.fecha/100)*100,b.fecha-floor(b.fecha/100)*100)
else . end as fecha_tda_spos,

/*TDA o SPOS*/

case 
when c.rut is not null and  b.rut is not null and min(c.periodo,b.periodo)=&periodo. then '01.Mes actual'
when c.rut is not null and  b.rut is not null and min(c.periodo,b.periodo)=&periodo_1. then '02.Mes Siguiente'
when c.rut is not null and  b.rut is not null and min(c.periodo,b.periodo)=&periodo_2. then '03.Mes Subsiguiente'
when ((c.rut is not null and  b.rut is null) or (c.rut is  null and  b.rut is  not null)) and coalesce(c.periodo,b.periodo)=&periodo. then '01.Mes actual'
when ((c.rut is not null and  b.rut is null) or (c.rut is  null and  b.rut is  not null)) and coalesce(c.periodo,b.periodo)=&periodo_1. then '02.Mes Siguiente'
when ((c.rut is not null and  b.rut is null) or (c.rut is  null and  b.rut is  not null)) and coalesce(c.periodo,b.periodo)=&periodo_2. then '03.Mes Subsiguiente'
else '04.Sin Compra' end as Concrecion_tdaospos,

case 
when c.rut is not null and  b.rut is not null and min(c.periodo,b.periodo)=&periodo. then min(c.fecha-floor(c.fecha/100)*100,b.fecha-floor(b.fecha/100)*100)
when c.rut is not null and  b.rut is not null and min(c.periodo,b.periodo)=&periodo_1. then min(c.fecha-floor(c.fecha/100)*100,b.fecha-floor(b.fecha/100)*100)
when c.rut is not null and  b.rut is not null and min(c.periodo,b.periodo)=&periodo_2. then min(c.fecha-floor(c.fecha/100)*100,b.fecha-floor(b.fecha/100)*100)
when ((c.rut is not null and  b.rut is null) or (c.rut is  null and  b.rut is  not null)) and coalesce(c.periodo,b.periodo)=&periodo. then coalesce(c.fecha-floor(c.fecha/100)*100,b.fecha-floor(b.fecha/100)*100)
when ((c.rut is not null and  b.rut is null) or (c.rut is  null and  b.rut is  not null)) and coalesce(c.periodo,b.periodo)=&periodo_1. then coalesce(c.fecha-floor(c.fecha/100)*100,b.fecha-floor(b.fecha/100)*100)
when ((c.rut is not null and  b.rut is null) or (c.rut is  null and  b.rut is  not null)) and coalesce(c.periodo,b.periodo)=&periodo_2. then coalesce(c.fecha-floor(c.fecha/100)*100,b.fecha-floor(b.fecha/100)*100)
else . end as fecha_tdaospos,

case 
when b.rut is not null and c.rut is null then '01.SPOS'
when b.rut is  null and c.rut is not null then '02.TDA'
when b.rut is  not null and c.rut is not null  and b.fecha=c.fecha then '03.TDA+SPOS'
when b.rut is  not null and c.rut is not null  and b.fecha<>c.fecha and min(b.fecha,c.fecha)=b.fecha then '01.SPOS'
when b.rut is  not null and c.rut is not null  and b.fecha<>c.fecha and min(b.fecha,c.fecha)=c.fecha then '02.TDA'
else '04.Sin Compra' end as PRIMERA_COMPRA

from capta_salida as a 

left join spos_total as b
on(a.rut=b.rut)

left join tda_itf as c
on(a.rut=c.rut) 

group by 
a.rut
;QUIT;

%put==================================================================================================;
%put [07] Colapso &periodo.;
%put==================================================================================================;

proc sql;
create table colapso as 
select 
year(fecha)*100+month(fecha) as periodo,
PRODUCTO,
FECHA,
ORIGEN,
case when cupo=0 then '00.0'
when cupo between 1 and 49999 then '01.]0,50M['
when cupo=50000 then '02.50M'
when cupo between 50001 and 199999 then '03.]50M,200M['
when cupo=200000 then '04.200M'
when cupo between 200001 and 500000 then '05.]200M,500M]'
when cupo between 500001 and 1000000 then '06.]500M,1MM]'
when cupo between 1000001 and 1500000 then '07.]1MM,1.5MM]'
when cupo between 1500001 and 2000000 then '08.]1.5MM,2MM]'
when cupo >2000000 then '09.>2MM' end as intervalo_cupo,
case when cod_sucursal between 500 and 600 then 'BANCO'
when cod_sucursal=39 and via='HOMEBAN' then 'DIGITAL' else canal end as canal,

Concrecion_SPOS,
fecha_spos,
Concrecion_tda,
fecha_tda,
Concrecion_spos_UNI,
fecha_spos_uni,
Concrecion_tda_UNI,
fecha_tda_uni,
Concrecion_tda_spos,
fecha_tda_spos,
Concrecion_tdaospos,
fecha_tdaospos,
PRIMERA_COMPRA,

count(rut) as clientes,
sum(trx_SPOS) as TRX_SPOS,
sum(monto_SPOS) as MONTO_SPOS,
sum(trx_tda) as TRX_tda,
sum(monto_tda) as MONTO_tda,
sum(monto_SPOS_UNI) as monto_SPOS_UNI,
sum(TRX_spos_uni) as TRX_spos_uni,
sum(monto_tda_UNI) as monto_tda_UNI,
sum(TRX_tda_uni) as TRX_tda_uni

from cruce 
group by 
calculated periodo,
PRODUCTO,
FECHA,
ORIGEN,
calculated intervalo_cupo,
calculated canal,

Concrecion_SPOS,
fecha_spos,
Concrecion_tda,
fecha_tda,
Concrecion_spos_UNI,
fecha_spos_uni,
Concrecion_tda_UNI,
fecha_tda_uni,
Concrecion_tda_spos,
fecha_tda_spos,
Concrecion_tdaospos,
fecha_tdaospos,
PRIMERA_COMPRA
;QUIT;


%put==================================================================================================;
%put [08] Preguntar si existe la tabla para guardar, caso contrario crearla;
%put==================================================================================================;

%if (%sysfunc(exist(&lib..Concrecion_captados))) %then %do;

%end;
%else %do;
proc sql;
create table &lib..Concrecion_captados(
periodo num,
PRODUCTO char(99),
FECHA date,
ORIGEN char(99),
intervalo_cupo char(99),
canal char(99),
Concrecion_SPOS char(99),
fecha_spos num,
Concrecion_tda char(99),
fecha_tda num,
Concrecion_spos_UNI char(99),
fecha_spos_uni num,
Concrecion_tda_UNI char(99),
fecha_tda_uni num,
Concrecion_tda_spos char(99),
fecha_tda_spos num,
Concrecion_tdaospos char(99),
fecha_tdaospos num,
PRIMERA_COMPRA char(99),
clientes num,
TRX_SPOS num,
MONTO_SPOS num,
TRX_tda num,
MONTO_tda num,
monto_SPOS_UNI num,
TRX_spos_uni num,
monto_tda_UNI num,
TRX_tda_uni num
)
;QUIT;
%end;

%put==================================================================================================;
%put [09] borrado de informacion y llenado de tabla;
%put==================================================================================================;

proc sql;
delete *
from &lib..Concrecion_captados
where periodo=&periodo.
;QUIT;

proc sql;
insert into &lib..Concrecion_captados
select *
from colapso
;QUIT;

%put==================================================================================================;
%put [10] borrado tablas de paso;
%put==================================================================================================;

proc sql;
drop table capta_salida;
drop table colapso;
drop table cruce;
drop table spos_&periodo_1.;
drop table spos_&periodo.;
drop table spos_&periodo_2.;
drop table spos_total;
drop table tda_itf_&periodo_1.;
drop table tda_itf_&periodo.;
drop table tda_itf_&periodo_2.;
drop table tda_itf;
;QUIT;

%put==================================================================================================;
%put [11] SUBIR A ORACLOUD;
%put==================================================================================================;


LIBNAME ORACLOUD ORACLE sql_functions=all  READBUFF=1000  INSERTBUFF=1000  PATH="REPORTSAS.WORLD"  SCHEMA=SAS_ADM authdomain=DBOracleCloud_Auth;

%if (%sysfunc(exist(oracloud.pmunoz_Concrecion_captados ))) %then %do;
 
%end;
%else %do;
proc sql;
connect using oracloud;
create table  oracloud.pmunoz_Concrecion_captados (
periodo num,
PRODUCTO char(99),
FECHA date,
ORIGEN char(99),
intervalo_cupo char(99),
canal char(99),
Concrecion_SPOS char(99),
fecha_spos num,
Concrecion_tda char(99),
fecha_tda num,
Concrecion_spos_UNI char(99),
fecha_spos_uni num,
Concrecion_tda_UNI char(99),
fecha_tda_uni num,
Concrecion_tda_spos char(99),
fecha_tda_spos num,
Concrecion_tdaospos char(99),
fecha_tdaospos num,
PRIMERA_COMPRA char(99),
clientes num,
TRX_SPOS num,
MONTO_SPOS num,
TRX_tda num,
MONTO_tda num,
monto_SPOS_UNI num,
TRX_spos_uni num,
monto_tda_UNI num,
TRX_tda_uni num
);
disconnect from oracloud;run;
%end;


proc sql;
connect using oracloud;
execute by oracloud (delete from  pmunoz_Concrecion_captados  where periodo=&periodo.);
disconnect from oracloud;
;quit;


proc sql; 
connect using oracloud;
insert into   oracloud.pmunoz_Concrecion_captados (
periodo ,
PRODUCTO ,
FECHA ,
ORIGEN ,
intervalo_cupo ,
canal ,
Concrecion_SPOS ,
fecha_spos ,
Concrecion_tda ,
fecha_tda ,
Concrecion_spos_UNI ,
fecha_spos_uni ,
Concrecion_tda_UNI ,
fecha_tda_uni ,
Concrecion_tda_spos ,
fecha_tda_spos ,
Concrecion_tdaospos ,
fecha_tdaospos ,
PRIMERA_COMPRA ,
clientes ,
TRX_SPOS ,
MONTO_SPOS ,
TRX_tda ,
MONTO_tda ,
monto_SPOS_UNI ,
TRX_spos_uni ,
monto_tda_UNI ,
TRX_tda_uni  )

select 
periodo ,
PRODUCTO ,
DHMS(FECHA,0,0,0) as fecha format=datetime20. ,
ORIGEN ,
intervalo_cupo ,
canal ,
Concrecion_SPOS ,
fecha_spos ,
Concrecion_tda ,
fecha_tda ,
Concrecion_spos_UNI ,
fecha_spos_uni ,
Concrecion_tda_UNI ,
fecha_tda_uni ,
Concrecion_tda_spos ,
fecha_tda_spos ,
Concrecion_tdaospos ,
fecha_tdaospos ,
PRIMERA_COMPRA ,
clientes ,
TRX_SPOS ,
MONTO_SPOS ,
TRX_tda ,
MONTO_tda ,
monto_SPOS_UNI ,
TRX_spos_uni ,
monto_tda_UNI ,
TRX_tda_uni 
from &lib..Concrecion_captados
where periodo=&periodo.; 
disconnect from oracloud;run;



%mend concreta_capta;



DATA _null_;
fecha = input(put(intnx('month',today(),0,'begin'),date9.),$10.);
fecha_1 = input(put(intnx('month',today(),-1,'begin'),date9.),$10.);
fecha_2 = input(put(intnx('month',today(),-2,'begin'),date9.),$10.);

Call symput("fecha", fecha);
Call symput("fecha_1",fecha_1 );
Call symput("fecha_2", fecha_2);


RUN;

%put &fecha;
%put &fecha_1;
%put &fecha_2;



%concreta_capta("&fecha."d,&libreria.);
%concreta_capta("&fecha_1."d,&libreria.);
%concreta_capta("&fecha_2."d,&libreria.);

data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */



/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*	VARIABLE TIEMPO	- FIN	*/
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

SELECT EMAIL into :DEST_3
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';

SELECT EMAIL into :DEST_4
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'VALENTIN_TRONCOSO';


quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_3","&DEST_4","lbachelets@bancoripley.com", "vmartinezf@bancoripley.com")
CC = ("&DEST_1", "&DEST_2")
SUBJECT = ("MAIL_AUTOM: Proceso ONBOARDING 3M");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso ONBOARDING 3M, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put ; 
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 01'; 
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
/*==================================================================================================*/
