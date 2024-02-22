DATA _null_;
n='0';
Call symput("n", n);
RUN;

%put &n;

DATA _null_;
periodo_actual = input(put(intnx('month',today(),&n.,'begin'),yymmn6. ),$10.) ;
periodo_2 = input(put(intnx('month',today(),&n.-2,'begin'),yymmn6. ),$10.) ;
periodo_1 = input(put(intnx('month',today(),&n.-1,'begin'),yymmn6. ),$10.) ;
periodo_3 = input(put(intnx('month',today(),&n.-3,'begin'),yymmn6. ),$10.) ;
dia_actual= put(intnx('month',today(),&n.,'same'),yymmddn8.); 

Call symput("periodo_actual", periodo_actual);
Call symput("periodo_2", periodo_2);
Call symput("periodo_1", periodo_1);
Call symput("periodo_3", periodo_3);
Call symput("dia_actual", dia_actual);
RUN;


%put &periodo_actual;
%put &periodo_3;
%put &periodo_2;
%put &periodo_1;
%put &dia_actual;

proc sql;
CREATE TABLE pago_presencial_epu AS 
SELECT
	t1.rut, t1.CONTRATO, t1.SUCURSAL, 
t1.facturacion,
	CASE
		WHEN DAY(t1.facturacion) = 5  THEN 20
		WHEN DAY(t1.facturacion) = 10 THEN 25
		WHEN DAY(t1.facturacion) = 15 THEN 30
		WHEN DAY(t1.facturacion) = 18 THEN 5
		WHEN DAY(t1.facturacion) = 20 THEN 5
		WHEN DAY(t1.facturacion) = 25 THEN 10
		WHEN DAY(t1.facturacion) = 30 THEN 15
		ELSE 0 END AS VENCIMIENTO_EPU,
t2.FECHA,
	CASE
		WHEN Day(input(t2.FECHA,yymmdd10.)) BETWEEN 1  AND 5   THEN '1-5'
		WHEN Day(input(t2.FECHA,yymmdd10.)) BETWEEN 6  AND 10  THEN '6-10'
		WHEN Day(input(t2.FECHA,yymmdd10.)) BETWEEN 11 AND 15  THEN '11-15'
		WHEN Day(input(t2.FECHA,yymmdd10.)) BETWEEN 16 AND 20  THEN '16-20'
		WHEN Day(input(t2.FECHA,yymmdd10.)) BETWEEN 21 AND 25  THEN '21-25'
		WHEN Day(input(t2.FECHA,yymmdd10.)) BETWEEN 26 AND 30  THEN '26-30'
		ELSE '0' END AS Pago_REAL_PRESENCIAL,
t2.TIPO, t2.NOMCOMRED, t1.Saldo, t1.PAGO_MINIMO, t1.Tipo_Producto, t1.SI_EPUMAIL, t1.SI_EPUFISICO, t1.si_mantencionepu, t1.fechacorte, t1.glosa, t1.Mto_Mantencion,t2.monto
FROM publicin.SB_CONTRATOEPU_&periodo_actual. as t1
left join result.PAGOS_DIGITALES_&periodo_actual.  as t2 on t1.rut=t2.rut
;
;quit;

/*   Tablas Vencimiento de pago con día de pago     */

PROC SQL;
   CREATE TABLE WORK.Vencimiento_con_dias_de_pago AS 
   SELECT tipo, 
          /* COUNT_of_rut */
            COUNT(t1.rut) AS COUNT_of_rut,
			sum(monto) as monto
      FROM WORK.PAGO_PRESENCIAL_EPU t1
      GROUP BY t1.TIPO
;QUIT;

proc sql;
create table log_mes_actual as
select distinct rut
from publicin.logeo_int_&periodo_actual.
;quit;

proc sql;
create table log_mes_ant as
select distinct rut
from publicin.logeo_int_&periodo_1.
;quit;

proc sql;
create table log_mes_ant_2 as
select distinct rut
from publicin.logeo_int_&periodo_2.
;quit;

proc sql;
create table log_mes_ant_3 as
select distinct rut
from publicin.logeo_int_&periodo_3.
;quit;

proc sql;
create table cons_log as 
select  * from log_mes_actual
union all
select * from log_mes_ant
union all
select * from log_mes_ant_2
union all
select * from log_mes_ant_3
;quit;

proc sql;
create table cruce_login as
select rut
from cons_log
where rut in (select * from log_mes_actual)
and rut in (select * from log_mes_ant)
and rut in (select * from log_mes_ant_2)
and rut in (select * from log_mes_ant_3)
;quit;

/*  EDAD  */

%if (%sysfunc(exist(publicin.demo_basket_&periodo_1.))) %then %do;

proc sql;
create table edad as 
select 
rut,
edad
from publicin.demo_basket_&periodo_1.
where edad is not null and edad >0
;QUIT;
%end;
%else %do;
proc sql;
create table edad as 
select 
rut,
edad
from publicin.demo_basket_&periodo_2.
where edad is not null and edad >0
;QUIT;
%end;

/* Sucursales */

LIBNAME BOTGEN ORACLE PATH='REPORITF.WORLD' SCHEMA='BOTGEN_ADM' USER='JABURTOM' PASSWORD='JABU#_1107';

proc sql;
create table sucursal as
select tgmsu_cod_suc_k as numero_sucursal,TGMSU_NOM_SUC as nombre_sucursal
from BOTGEN.BOTGEN_MAE_SUC
;quit;

/* Detalle Pagos */

proc sql;
create table pago_epu_mes_act as 
select distinct rut
from result.PAGOS_DIGITALES_&periodo_actual.
where TIPO = 'TIENDA'
;quit;

proc sql;
create table pago_epu_mes_ant as 
select distinct rut
from result.PAGOS_DIGITALES_&periodo_1.
where TIPO = 'TIENDA'
;quit;

proc sql;
create table pago_epu_mes_ant2 as 
select distinct rut
from result.PAGOS_DIGITALES_&periodo_2.
where TIPO = 'TIENDA'
;quit;

proc sql;
create table detalle_pagos_aux as 
select 
tipo as canal, 
case when numero_sucursal is not null and tipo='TIENDA' then b.nombre_sucursal
else NOMCOMRED end as subcanal,
a.rut,
monto,
case when c.rut is not null then 1 else 0 end as log_periodo_actual,
case when d.rut is not null then 1 else 0 end as log_periodo_ant,
case when e.rut is not null then e.edad else 0 end as edad,
case when f.rut is not null then 1 else 0 end as pago_mes_act,
case when g.rut is not null then 1 else 0 end as pago_mes_ant,
case when h.rut is not null then 1 else 0 end as pago_mes_ant_2
from pago_presencial_epu as a
left join sucursal as b
on a.sucursal = b.numero_sucursal
left join log_mes_actual as c
on a.rut = c.rut
left join log_mes_ant as d
on a.rut = d.rut
left join edad as e
on a.rut = e.rut
left join pago_epu_mes_act as f
on a.rut = f.rut
left join pago_epu_mes_ant as g
on a.rut = g.rut
left join pago_epu_mes_ant2 as h
on a.rut = h.rut
;quit;

proc sql;
create table detalle_pagos as 
select canal,
subcanal,
count(rut) as numero_de_pagos_epu,
sum(monto) as  monto_de_pago_epu,
count(distinct rut) as clientes_unicos,
count(distinct case when log_periodo_actual=1 then rut end) as login_mismo_periodo,
count(distinct case when log_periodo_ant=1 then rut end) as login_mes_anterior,
count(distinct case when pago_mes_act=1 and pago_mes_ant=1 and pago_mes_ant_2=1 and log_periodo_actual=0 then rut end) as sin_log_pagos_presencial_3m,
count(distinct case when pago_mes_act=1 and pago_mes_ant=1 and pago_mes_ant_2=1 and log_periodo_actual=1 then rut end) as con_log_pagos_presencial_3m
from detalle_pagos_aux
group by canal,subcanal
;quit;

PROC EXPORT DATA =  work.detalle_pagos
/*OUTFILE="/sasdata/users94/user_bi/unica/INPUT-TR_CAMPANAS-&USUARIO..csv"*/
OUTFILE="/sasdata/users94/user_bi/unica/input/detalle_pagos.csv"
DBMS=dlm REPLACE;
delimiter=';';
PUTNAMES=YES;
RUN;

proc sql;
create table detalle_pagos_por_edad_aux as 
select
*,
case when edad BETWEEN 18 AND 29 then '18 a 29 años'
when edad BETWEEN 30 and 39 then '30 a 39 años'
when edad BETWEEN 40 and 49 then '40 a 49 años'
when edad BETWEEN 50 and 59 then '50 a 59 años'
when edad >= 60 then 'Mayores de 60 años' 
else 'No Validos'
end as tramo_edad
from detalle_pagos_aux
;quit;

proc sql;
create table detalle_pagos_por_edad as 
select
tramo_edad,
canal,
count(distinct rut) as clientes_unicos,
count(distinct case when log_periodo_actual=1 then rut end) as login_mismo_periodo,
count(distinct case when log_periodo_ant=1 then rut end) as login_mes_anterior,
count(distinct case when pago_mes_act=1 and pago_mes_ant=1 and pago_mes_ant_2=1 and log_periodo_actual=0 then rut end) as sin_log_pagos_presencial_3m,
count(distinct case when pago_mes_act=1 and pago_mes_ant=1 and pago_mes_ant_2=1 and log_periodo_actual=1 then rut end) as con_log_pagos_presencial_3m
from detalle_pagos_por_edad_aux
group by tramo_edad,canal
;quit;


PROC EXPORT DATA =  work.detalle_pagos_por_edad
/*OUTFILE="/sasdata/users94/user_bi/unica/INPUT-TR_CAMPANAS-&USUARIO..csv"*/
OUTFILE="/sasdata/users94/user_bi/unica/input/detalle_pagos_por_edad.csv"
DBMS=dlm REPLACE;
delimiter=';';
PUTNAMES=YES;
RUN;

data _null_;
FILENAME OUTBOX EMAIL
SUBJECT="MAIL_AUTOM: Actualización Detalle Pago EPU &dia_actual."
FROM = ("equipo_datos_procesos_bi@bancoripley.com")
TO = ("apinedar@bancoripley.com")
 CC      = ("nverdejog@bancoripley.com","rarcosm@bancoripley.com","mgalazh@bancoripley.com","tpiwonkas@bancoripley.com","vmorah@bancoripley.com")
attach =("/sasdata/users94/user_bi/unica/input/detalle_pagos_por_edad.csv" content_type="excel")
attach    =( "/sasdata/users94/user_bi/unica/input/detalle_pagos.csv" content_type="excel") 
	  Type    = 'Text/Plain';

FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Datos actualizados al &dia_actual.";  
 put ; 
 put ; 
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
