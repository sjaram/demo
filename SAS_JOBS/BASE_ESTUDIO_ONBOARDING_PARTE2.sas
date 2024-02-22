/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================    BASE_ESTUDIO_ONBOARDING_PARTE2 	 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-08-26 -- v03	-- David V.		--  Cambio de librería PMUNOZ a RESULT, por automatización de proceso precedente.-
/* 2022-08-10 -- v02	-- David V.		--  Se agregan comentarios, envío al ftp para calidad y correo de notificación.
/* 2022-08-10 -- v01	-- Karina M.	--  Versión Original

/* INFORMACIÓN:
	Para todas las bases, adicional a los campos que incluye Pedro, se debe sumar el nombre del titular, el mail.

	Dado lo anterior las bases para cada uno de los estudios debiese contener:

	Clientes que contrataron el servicio por el canal presencial à SÍ
	Clientes que contrataron el servicio por el canal online à SÍ
	30 días -> Clientes que han usado su tarjeta en los primeros 30 días de contratación. à SÍ (se considera trx tienda o spos)
	90 días -> Clientes que han usado su tarjeta en los primeros 90 días, es decir que hayan usado su tarjeta en ese periodo 3 veces y el último uso haya sido en el último mes, es decir últimos 30 días. à sólo tenemos si concreto a los 90 días, pero no cuantas veces usó, ya que la base sólo trae la fecha de la 1ª compra. Se podría agregar pero necesitamos más tiempo.

	90 días -> Clientes que usaron su tarjeta a los 30 primeros días, y a los siguientes 30 días, y no la usaron los últimos 30 días. à no se tiene en la base disponibilizada, pero se podría tener con mas tiempo
	    Clientes que usaron su tarjeta en los primeros 30 días y dejaron de usar los siguientes 60 días desde su ingreso. à no se tiene en la base disponibilizada, pero se podría tener con mas tiempo

	30 días -> Clientes que no usaron su tarjeta en los primeros 30 días. à SÍ, mira los primeros 30 días
	90 días -> Clientes que no usaron su tarjeta en los 90 días. à SÍ, mira los 90 días

/* VARIABLE TIEMPO - INICIO */
%let tiempo_inicio= %sysfunc(datetime());

options validvarname=any;

/*==================================================================================================*/
/*==============================    BASE_ESTUDIO_ONBOARDING_PARTE2	 ===============================*/

/* GENERACION DE BASES DE SALIDA PARA EQUIPO EXPERIENCIA */
%let libreria=RESULT;
%let n=0;

DATA _null_;
periodo_actual = input(put(intnx('month',today(),-&n.,'begin'),yymmn6. ),$10.) ;
fecha_hoy = input(put(intnx('day',today(),&n.,'same'),yymmddn8. ),$10.);
periodo_1 = input(put(intnx('month',today(),-&n.-1,'begin'),yymmn6. ),$10.) ;
periodo_2 = input(put(intnx('month',today(),-&n.-2,'same'),yymmn6. ),$10.) ;
periodo_3 = input(put(intnx('month',today(),-&n.-3,'same'),yymmn6. ),$10.) ;
periodo_4 = input(put(intnx('month',today(),-&n.-4,'same'),yymmn6. ),$10.) ;
periodo_5 = input(put(intnx('month',today(),-&n.-5,'same'),yymmn6. ),$10.) ;
periodo_6 = input(put(intnx('month',today(),-&n.-6,'same'),yymmn6. ),$10.) ;

ini_mes = input(put(intnx('month',today(),-&n.,'begin'),date9. ),$10.) ;
fin_mes = input(put(intnx('month',today(),-&n.,'end'),date9. ),$10.) ;

Call symput("periodo_actual", periodo_actual);
Call symput("fecha_hoy", fecha_hoy);
Call symput("periodo_1", periodo_1);
Call symput("periodo_2", periodo_2);
Call symput("periodo_3", periodo_3);
Call symput("periodo_4", periodo_4);
Call symput("periodo_5", periodo_5);
Call symput("periodo_6", periodo_6);
Call symput("dated_ant", dated_ant);
Call symput("ini_mes", ini_mes);
Call symput("fin_mes", fin_mes);
RUN;

%put &periodo_actual;
%put &fecha_hoy;
%put &periodo_1;
%put &periodo_2;
%put &periodo_3;
%put &periodo_4;
%put &periodo_5;
%put &periodo_6;
%put &ini_mes;
%put &fin_mes;

/*year(fecha)*10000+month(fecha)*100+day(fecha)*/


/* unir ultimos 4 meses de  analisis
Pedro lo actualizará los input los dias Lunes-Miercoles-Viernes 
este proceso debe ejecutarlos Lunes-martes-jueves*/

proc sql;
create table Unir_bases_captaciones as
select * FROM ( select *
from &libreria..ONBOARDING_3M_&periodo_actual
union  select *
from &libreria..ONBOARDING_3M_&periodo_1
union  select *
from &libreria..ONBOARDING_3M_&periodo_2
union  select *
from &libreria..ONBOARDING_3M_&periodo_3)
;quit;





%let libreria_2=RESULT;
%let n=0;

%macro concrecion_3M_fecha_max(N,libreria_2);

DATA _null_;
periodo_actual = input(put(intnx('month',today(),-&n.,'begin'),yymmn6. ),$10.) ;
periodo_1 = input(put(intnx('month',today(),-&n.+1,'begin'),yymmn6. ),$10.) ;
periodo_2 = input(put(intnx('month',today(),-&n.+2,'same'),yymmn6. ),$10.) ;
periodo_3 = input(put(intnx('month',today(),-&n.+3,'same'),yymmn6. ),$10.) ;
periodo_4 = input(put(intnx('month',today(),-&n.+4,'same'),yymmn6. ),$10.) ;
periodo_5 = input(put(intnx('month',today(),-&n.+5,'same'),yymmn6. ),$10.) ;
periodo_6 = input(put(intnx('month',today(),-&n.+6,'same'),yymmn6. ),$10.) ;



ini_mes = input(put(intnx('month',today(),-&n.,'begin'),date9. ),$10.) ;
fin_mes = input(put(intnx('month',today(),-&n.,'end'),date9. ),$10.) ;



Call symput("periodo_actual", periodo_actual);
Call symput("periodo_1", periodo_1);
Call symput("periodo_2", periodo_2);
Call symput("periodo_3", periodo_3);
Call symput("periodo_4", periodo_4);
Call symput("periodo_5", periodo_5);
Call symput("periodo_6", periodo_6);
Call symput("dated_ant", dated_ant);
Call symput("ini_mes", ini_mes);
Call symput("fin_mes", fin_mes);
RUN;



proc sql;
create table captados as
select
rut_cliente as rut,
producto,
fecha,
codent,
centalta,
cuenta,
NRO_SOLICITUD,
ID_OFERTA,
cod_sucursal,
via,
RUT_VENDEDOR,
RUT_CAPTADOR,
RUT_ASISTENTE
from result.capta_salida
where
fecha between "&ini_mes."d and "&fin_mes."d
;QUIT;




proc sql;
create table captados as
select
monotonic() as ind,
*,
year(fecha)*10000+month(fecha)*100+day(fecha) as fecha_numero,
year(intnx("day",fecha,30))*10000+month(intnx("day",fecha,30))*100+day(intnx("day",fecha,30)) as dia_30,
year(intnx("day",fecha,60))*10000+month(intnx("day",fecha,60))*100+day(intnx("day",fecha,60)) as dia_60,
year(intnx("day",fecha,90))*10000+month(intnx("day",fecha,90))*100+day(intnx("day",fecha,90)) as dia_90




from captados
order by rut
;QUIT;




%macro recopilar_USOS(periodo,i);

/*SPOS TC*/
%if (%sysfunc(exist(publicin.spos_aut_&periodo.))) %then %do;
PROC SQL ;
create table spos&i as 
SELECT 
a.rut,
a.fecha,
a.hora,
a.codact,
a.venta_tarjeta,
a.Nombre_Comercio
FROM publicin.spos_aut_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)
;quit;
%end;
%else %do;
PROC SQL ;
create table spos&i 
(rut num,
fecha num,
hora char(10),
codact num,
venta_tarjeta num,
Nombre_Comercio char(10)
)
;quit;
%end;

/*TDA TC*/

%if (%sysfunc(exist(publicin.tda_itf_&periodo.))) %then %do;
PROC SQL ;
create table tda&i  as 
SELECT
distinct 
a.rut,
year(a.fecha)*10000+month(a.fecha)*100+day(a.fecha) as fecha
FROM publicin.tda_itf_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)
where a.capital>0
;quit;
%end;
%else %do;
PROC SQL ;
create table tda&i  
(rut num,
fecha num)
;quit;
%end;

/*TDA MCD*/


%if (%sysfunc(exist(publicin.TDA_mcd_&periodo.))) %then %do;
PROC SQL ;
create table TDA_MCD&i as 
SELECT
distinct 
a.rut,
a.fecha
FROM publicin.TDA_mcd_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)
where a.producto='08'
;quit;
%end;
%else %do;
PROC SQL ;
create table TDA_MCD&i 
(rut num,
fecha num)
;quit;
%end;

/*TDA MAESTRO*/


%if (%sysfunc(exist(publicin.TDA_MAESTRO_&periodo.))) %then %do;
PROC SQL ;
create table TDA_MAESTRO&i as 
SELECT
distinct 
a.rut,
a.fecha
FROM publicin.TDA_MAESTRO_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)

;quit;
%end;
%else %do;
PROC SQL ;
create table TDA_MAESTRO&i 
(rut num,
fecha num)
;quit;
%end;

/*SPOS MCD*/

%if (%sysfunc(exist(publicin.spos_mcd_&periodo.))) %then %do;
PROC SQL ;
create table spos_MCD&i as 
SELECT 
a.rut,
a.fecha,
a.hora,
a.codact,
a.venta_tarjeta,
a.Nombre_Comercio
FROM publicin.spos_mcd_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)
where a.producto='08'
;quit;
%end;
%else %do;
PROC SQL ;
create table spos_MCD&i 
(rut num,
fecha num,
hora char(10),
codact num,
venta_tarjeta num,
Nombre_Comercio char(10))
;quit;
%end;

/*spos maestro*/

%if (%sysfunc(exist(publicin.spos_MAESTRO_&periodo.))) %then %do;
PROC SQL ;
create table spos_MAESTRO&i as 
SELECT
 
a.rut,
a.fecha,
a.codact,
a.venta_tarjeta,
a.Nombre_Comercio
FROM publicin.spos_MAESTRO_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)

;quit;
%end;
%else %do;
PROC SQL ;
create table spos_MAESTRO&i 
(rut num,
fecha num,
codact num,
venta_tarjeta num,
Nombre_Comercio char(10))
;quit;
%end;


/*TDA CTACTE*/

%if (%sysfunc(exist(publicin.TDA_CTACTE_&periodo.))) %then %do;
PROC SQL ;
create table TDA_CC&i as 
SELECT
distinct 
a.rut,
a.fecha
FROM publicin.TDA_CTACTE_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)
where a.producto='13'
;quit;
%end;
%else %do;
PROC SQL ;
create table TDA_CC&i 
(rut num,
fecha num)
;quit;
%end;


/*spos ctacte*/

%if (%sysfunc(exist(publicin.SPOS_CTACTE_&periodo.))) %then %do;
PROC SQL ;
create table spos_CC&i as 
SELECT 
a.rut,
a.fecha,
a.hora,
a.codact,
a.venta_tarjeta,
a.Nombre_Comercio
FROM publicin.SPOS_CTACTE_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)
where a.producto='13'
;quit;
%end;
%else %do;
PROC SQL ;
create table spos_CC&i 
(rut num,
fecha num,
hora char(10),
codact num,
venta_tarjeta num,
Nombre_Comercio char(10))
;quit;
%end;



%mend recopilar_USOS;


%recopilar_USOS(&periodo_actual.,1);
%recopilar_USOS(&periodo_1.,2);
%recopilar_USOS(&periodo_2.,3);
%recopilar_USOS(&periodo_3.,4);



proc sql;
create table TDA_DEBITO_fin as 
select *
from TDA_MCD1
union 
select *
from TDA_MCD2
union 
select *
from TDA_MCD3
union 
select *
from TDA_MCD4
union select *
from TDA_MAESTRO1
union 
select *
from TDA_MAESTRO2
union 
select *
from TDA_MAESTRO3
union 
select *
from TDA_MAESTRO4
;QUIT;

proc sql;
drop table  TDA_MCD1;
 drop table  TDA_MCD2;
 drop table  TDA_MCD3;
 drop table  TDA_MCD4;
 drop table  TDA_MAESTRO1;
 drop table  TDA_MAESTRO2;
drop table  TDA_MAESTRO3;
 drop table  TDA_MAESTRO4;
;QUIT;

proc sql;
create table spos_DEBITO_fin as 
select *
from spos_MCD1
outer union corr 
select *
from spos_MCD2
outer union corr 
select *
from spos_MCD3
outer union corr 
select *
from spos_MCD4
outer union corr select *
from spos_MAESTRO1
outer union corr 
select *
from spos_MAESTRO2
outer union corr 
select *
from spos_MAESTRO3
outer union corr 
select *
from spos_MAESTRO4
;QUIT;


proc sql;
 drop table spos_MCD1;
 drop table spos_MCD2;
 drop table spos_MCD3;
 drop table spos_MCD4;
 drop table spos_MAESTRO1;
 drop table spos_MAESTRO2;
 drop table spos_MAESTRO3;
 drop table spos_MAESTRO4;
;QUIT;

proc sql;
create table TDA_CC_fin as 
select *
from TDA_CC1
union 
select *
from TDA_CC2
union 
select *
from TDA_CC3
union 
select *
from TDA_CC4
;QUIT;

proc sql;
 drop table TDA_CC1;
 drop table TDA_CC2;
 drop table TDA_CC3;
 drop table TDA_CC4;
;QUIT;

proc sql;
create table spos_CC_fin as 
select *
from spos_CC1
outer union corr 
select *
from spos_CC2
outer union corr 
select *
from spos_CC3
outer union corr 
select *
from spos_CC4

;QUIT;


proc sql;
 drop table spos_CC1;
 drop table spos_CC2;
 drop table spos_CC3;
 drop table spos_CC4;
;QUIT;

proc sql;
create table spos_fin as 
select *
from spos1
outer union corr 
select *
from spos2
outer union corr 
select *
from spos3
outer union corr 
select *
from spos4
;QUIT;

proc sql;
 drop table spos1;
 drop table spos2;
 drop table spos3;
 drop table spos4;
;QUIT;

proc sql;
create table tda_fin as 
select *
from tda1
union 
select *
from tda2
union 
select *
from tda3
union 
select *
from tda4
;QUIT;

proc sql;
 drop table tda1;
 drop table tda2;
 drop table tda3;
 drop table tda4;
;QUIT;



PROC SQL;
   CREATE TABLE WORK.SPOS_FIN2 AS 
   SELECT t1.RUT, 
          /* COUNT_of_RUT */
            (COUNT(t1.RUT)) AS trx, 
          /* MIN_of_Fecha */
            (MIN(t1.Fecha)) AS Fecha, 
          /* MAX_of_Fecha */
            (MAX(t1.Fecha)) AS Fecha_max
      FROM WORK.SPOS_FIN t1
      GROUP BY t1.RUT;
QUIT;


PROC SQL;
   CREATE TABLE WORK.tda_fin2 AS 
   SELECT t1.RUT, 
          /* COUNT_of_RUT */
            (COUNT(t1.RUT)) AS trx, 
          /* MIN_of_Fecha */
            (MIN(t1.Fecha)) AS Fecha, 
          /* MAX_of_Fecha */
            (MAX(t1.Fecha)) AS Fecha_max
      FROM WORK.tda_fin t1
      GROUP BY t1.RUT;
QUIT;

PROC SQL;
   CREATE TABLE WORK.spos_debito_fin2 AS 
   SELECT t1.RUT, 
          /* COUNT_of_RUT */
            (COUNT(t1.RUT)) AS trx, 
          /* MIN_of_Fecha */
            (MIN(t1.Fecha)) AS Fecha, 
          /* MAX_of_Fecha */
            (MAX(t1.Fecha)) AS Fecha_max
      FROM WORK.spos_debito_fin t1
      GROUP BY t1.RUT;
QUIT;


PROC SQL;
   CREATE TABLE WORK.TDA_debito_fin2 AS 
   SELECT t1.RUT, 
          /* COUNT_of_RUT */
            (COUNT(t1.RUT)) AS trx, 
          /* MIN_of_Fecha */
            (MIN(t1.Fecha)) AS Fecha, 
          /* MAX_of_Fecha */
            (MAX(t1.Fecha)) AS Fecha_max
      FROM WORK.TDA_debito_fin t1
      GROUP BY t1.RUT;
QUIT;


PROC SQL;
   CREATE TABLE WORK.TDA_CC_fin2 AS 
   SELECT t1.RUT, 
          /* COUNT_of_RUT */
            (COUNT(t1.RUT)) AS trx, 
          /* MIN_of_Fecha */
            (MIN(t1.Fecha)) AS Fecha, 
          /* MAX_of_Fecha */
            (MAX(t1.Fecha)) AS Fecha_max
      FROM WORK.TDA_CC_fin t1
      GROUP BY t1.RUT;
QUIT;

PROC SQL;
   CREATE TABLE WORK.SPOS_CC_fin2 AS 
   SELECT t1.RUT, 
          /* COUNT_of_RUT */
            (COUNT(t1.RUT)) AS trx, 
          /* MIN_of_Fecha */
            (MIN(t1.Fecha)) AS Fecha, 
          /* MAX_of_Fecha */
            (MAX(t1.Fecha)) AS Fecha_max
      FROM WORK.SPOS_CC_fin t1
      GROUP BY t1.RUT;
QUIT;


/*55286*/
proc sql;
create table captados2 as 
select distinct 
a.*,



max(case 
when b.rut is not null and a.producto in ('TR','TAM','CAMBIO DE PRODUCTO','TAM_CERRADA','TAM_CUOTAS')
and b.Fecha_max between a.fecha_numero	and a.dia_90 then b.Fecha_max
when d.rut is not null and a.producto in ('CUENTA VISTA')
and d.Fecha_max between a.fecha_numero	and a.dia_90 then d.Fecha_max
when g.rut is not null and a.producto in ('CUENTA CORRIENTE')
and g.Fecha_max between a.fecha_numero	and a.dia_90 then g.Fecha_max
else 0 end
) as fecha_concreta_SPOS_max,


max(case 
when c.rut is not null and a.producto in ('TR','TAM','CAMBIO DE PRODUCTO','TAM_CERRADA','TAM_CUOTAS')
and c.Fecha_max between a.fecha_numero	and a.dia_90 then c.Fecha_max
when e.rut is not null and a.producto in ('CUENTA VISTA')
and e.Fecha_max between a.fecha_numero	and a.dia_90 then e.Fecha_max
when f.rut is not null and a.producto in ('CUENTA CORRIENTE')
and f.Fecha_max between a.fecha_numero	and a.dia_90 then f.Fecha_max
else 0 end ) as fecha_concreta_tda_max,

max(calculated fecha_concreta_tda_max,calculated fecha_concreta_SPOS_max) as fecha_concreta, 
case 
when a.producto in ('TR','TAM','CAMBIO DE PRODUCTO','TAM_CERRADA','TAM_CUOTAS')
and (b.rut is not null or c.rut is not null)
/*and (b.fecha between a.fecha_numero	and a.dia_90 
or c.fecha between a.fecha_numero and a.dia_90)*/ then coalesce(c.trx,0)+ coalesce(b.trx,0) 
when a.producto in ('CUENTA VISTA')
and (d.rut is not null or e.rut is not null)
/*and (d.fecha between a.fecha_numero	and a.dia_90 
or e.fecha between a.fecha_numero and a.dia_90)*/ then coalesce(d.trx,0)+ coalesce(e.trx,0)  
when a.producto in ('CUENTA CORRIENTE')
and (f.rut is not null or g.rut is not null)
/*and (f.fecha between a.fecha_numero	and a.dia_90 
or g.fecha between a.fecha_numero and a.dia_90)*/ then coalesce(f.trx,0)+ coalesce(g.trx,0) 
else 0 end   as concreta_90_Trx



from captados as a 
left join spos_fin2 as b
on(a.rut=b.rut)
left join tda_fin2 as c
on(a.rut=c.rut)
left join spos_debito_fin2 as d
oN(a.rut=d.rut)
left join TDA_debito_fin2 as e
oN(a.rut=e.rut)
left join TDA_CC_fin2 as f
oN(a.rut=f.rut)
left join SPOS_CC_fin2 as g
oN(a.rut=g.rut)

group by 
a.ind,
a.rut,
a.PRODUCTO,
a.FECHA	,
a.fecha_numero,
a.dia_30,
a.dia_60,
a.dia_90,
a.CODENT,	a.CENTALTA,	a.CUENTA

;QUIT;



proc sql;
create table onboarding_3M_v2_&periodo_actual. as
select *
from captados2
;QUIT;


%mend concrecion_3M_fecha_max;


%concrecion_3M_fecha_max(0,&libreria_2.);
%concrecion_3M_fecha_max(1,&libreria_2.);
%concrecion_3M_fecha_max(2,&libreria_2.);
%concrecion_3M_fecha_max(3,&libreria_2.);

/*==================================================================================================*/
/*================================= LIBRERÍA A ACTUALIZAR PARA AUTOM.  =============================*/
%let libreria_final=RESULT;

proc sql;
create table Unir_bases_captaciones_NVO_CAMP as
select *, &fecha_hoy as FECHA_HOY_NUMERO,
mdy(mod(int(fecha_concreta/100),100),mod(fecha_concreta,100),int(fecha_concreta/10000)) format=date9. as concreta_MAX_FECHA_SAS,
mdy(mod(int(&fecha_hoy/100),100),mod(&fecha_hoy,100),int(&fecha_hoy/10000)) format=date9. as FECHA_hoy_SAS,

case when fecha_concreta>0 then intck("day",calculated concreta_MAX_FECHA_SAS,calculated FECHA_hoy_SAS) else 999 end as dias_ultima_Compra

FROM ( select *
from ONBOARDING_3M_v2_&periodo_actual
union  select *
from ONBOARDING_3M_v2_&periodo_1
union  select *
from ONBOARDING_3M_v2_&periodo_2
union  select *
from ONBOARDING_3M_v2_&periodo_3)
;quit;


/*175669*/
/*SE AGREGAN NUEVAS VARIABLES Y DATOS DEL CAPTADOR */
proc sql;
create table BASE_ONBOARDING_ESTUDIO as
select distinct t1.ind, 
          t1.rut, 
          t1.PRODUCTO, 
          t1.FECHA, 
          t1.CODENT, 
          t1.CENTALTA, 
          t1.CUENTA, 
          t1.NRO_SOLICITUD, 
          t1.ID_OFERTA, 
          t1.COD_SUCURSAL, 
		  t2.RUT_VENDEDOR,
t2.RUT_CAPTADOR,
t2.RUT_ASISTENTE,
          t1.VIA, 
          t1.fecha_numero, 
          t1.dia_30, 
          t1.dia_60, 
          t1.dia_90, 
          t1.concreta_30_T, 
          t1.concreta_60_T, 
          t1.concreta_90_T, 
          t1.concreta_30_SPOS, 
          t1.concreta_60_SPOS, 
          t1.concreta_90_SPOS, 
          t1.concreta_30_tda, 
          t1.concreta_60_tda, 
          t1.concreta_90_tda, 
          t1.fecha_concreta_SPOS, 
          t1.fecha_concreta_tda, 
          t1.concreta_30_epu, 
          t1.concreta_60_epu, 
          t1.concreta_90_epu, 
          t1.concreta_30_log, 
          t1.concreta_60_log, 
          t1.concreta_90_log, 
          t1.concreta_30_retira_T, 
          t1.concreta_60_retira_T, 
          t1.concreta_90_retira_T, 
          t1.concreta_30_pagos, 
          t1.concreta_60_pagos, 
          t1.concreta_90_pagos, 
          t1.fecha_concreta_epu, 
          t1.fecha_concreta_log, 
          t1.fecha_concreta_retira_T, 
          t1.fecha_concreta_pagos, 
          t1.concreta_30_RPASS, 
          t1.concreta_60_RPASS, 
          t1.concreta_90_RPASS, 
          t1.fecha_concreta_RPASS, 
          t1.CODACT, 
          t1.VENTA_TARJETA_SPOS, 
          t1.Nombre_Comercio_SPOS, 
          t1.COD_CAMP_OFERTA, 
          t1.COD_TIP_PROD, 
          t1.COD_CND_PROD, 
          t1.CAMP_COD_ORI_BASE, 
          t1.DETALLE, 
          t1.TIPO_CLIENTE, 
          t1.combinatoria, 
          t1.concreta_SPOS_SAS, 
          t1.concreta_tda_SAS, 
          t1.concreta_epu_SAS, 
          t1.concreta_log_SAS, 
          t1.concreta_retira_T_SAS, 
          t1.concreta_pagos_SAS, 
          t1.concreta_RPASS_SAS, 
          t1.dias_SPOS, 
          t1.dias_tda, 
          t1.dias_epu, 
          t1.dias_log, 
          t1.dias_RETIRA, 
          t1.dias_pagos, 
          t1.dias_RPASS,t2.FECHA_HOY_NUMERO,
t2.concreta_90_Trx as n_trx,
t2.fecha_concreta AS fecha_concreta_MAX,
t2.concreta_MAX_FECHA_SAS ,
t2.FECHA_hoy_SAS,
t2.dias_ultima_Compra
from   UNIR_BASES_CAPTACIONES  t1 /* proceso pedro*/
left join Unir_bases_captaciones_NVO_CAMP t2 on /* proceso + variables bases laura*/
 (t1.rut = t2.rut AND t1.PRODUCTO = t2.PRODUCTO AND t1.FECHA = t2.FECHA AND t1.NRO_SOLICITUD = 
           t2.NRO_SOLICITUD AND t1.ID_OFERTA = t2.ID_OFERTA AND t1.COD_SUCURSAL = t2.COD_SUCURSAL)
ORDER BY T1.fecha_numero
;quit;



/*Agregar nombre y email*/
/* 174324*/
proc sql;
create table &libreria_final..ONBOARDING as
select t1.*,t2.email,t3.primer_nombre,t3.NOMBRES, 
          t3.PATERNO, 
          t3.MATERNO,
case when t1.VIA='HOMEBAN' THEN 'NO-PRESENCIAL' ELSE 'PRESENCIAL' END AS CANAL
from 
BASE_ONBOARDING_ESTUDIO t1
left join publicin.base_trabajo_email t2 on t1.rut=t2.rut
left join publicin.base_nombres t3 on t1.rut=t3.rut
/*where T1.rut not in (select rut from publicin.LNEGRO_CAR)*/
;quit;



/* GENERACION DE LAS BASES DE SALIDA PARA COMPARTIR EN FTP AL AREA DE EXPERIENCIA */



/*1- Clientes que contrataron el servicio por el canal presencial*/ /*OK*/
proc sql;
create table &libreria_final..ONBOARDING_CAPTA_PRESENCIAL as
select t1.*
from &libreria_final..ONBOARDING t1
WHERE CANAL='PRESENCIAL'
ORDER BY T1.fecha_numero
;quit;


/*2- Clientes que contrataron el servicio por el canal online*//*OK*/
proc sql;
create table &libreria_final..ONBOARDING_CAPTA_NO_PRESENCIAL as
select t1.*
from &libreria_final..ONBOARDING t1
WHERE CANAL='NO-PRESENCIAL'
ORDER BY T1.fecha_numero
;quit;


/*3.1- 30 días -> Clientes que han usado su tarjeta en los primeros 30 días de contratación*//*OK*/
proc sql;
create table &libreria_final..ONBOARDING_USO_30D as
select t1.*
from   &libreria_final..ONBOARDING  t1
WHERE  t1.concreta_30_SPOS =1
     or     t1.concreta_30_tda=1
ORDER BY T1.fecha_numero
;quit;

/*3.2- 90 días -> Clientes que han usado su tarjeta en los primeros 90 días, 
es decir que hayan usado su tarjeta en ese periodo 3 veces y el último uso haya sido en el último mes, es decir últimos 30 días.*/
proc sql;
create table &libreria_final..ONBOARDING_USO_90D as
select distinct t1.*
from   &libreria_final..ONBOARDING  t1
WHERE  t1.concreta_90_T=1 
and t1.n_trx>=3 /* numero de trx realizadas*/
and t1.fecha_concreta_MAX /* ultima fecha de trx*/ between t1.dia_60	and t1.dia_90
ORDER BY T1.fecha_numero
;quit;


/*4.1- 90 días -> Clientes que usaron su tarjeta a los 30 primeros días, y a los siguientes 30 días, y no la usaron los últimos 30 días.*/
proc sql;
create table &libreria_final..ONBOARDING_DEJO_DE_USAR_90D as
select distinct t1.*
from   &libreria_final..ONBOARDING  t1
WHERE   T1.dias_ultima_Compra NOT=999
AND t1.dias_ultima_Compra >=30
and t1.concreta_30_T=1 
AND t1.concreta_60_T=1 
ORDER BY T1.fecha_numero
;quit;


/*4.2- Clientes que usaron su tarjeta en los primeros 30 días y dejaron de usar los siguientes 60 días desde su ingreso.*/
proc sql;
create table &libreria_final..ONBOARDING_DEJO_DE_USAR_60D as
select distinct t1.*
from   &libreria_final..ONBOARDING  t1
WHERE    t1.concreta_30_T=1 
AND  t1.fecha_concreta_MAX <t1.dia_60	
ORDER BY T1.fecha_numero
;quit;


/*5.1- 30 días -> Clientes que no usaron su tarjeta en los primeros 30 días.*/
proc sql;
create table &libreria_final..ONBOARDING_SIN_USO_30D as
select t1.*
from &libreria_final..ONBOARDING t1
WHERE t1.concreta_30_SPOS =0
     and     t1.concreta_30_tda=0
	
	 and t1.dia_30 < &fecha_hoy
ORDER BY T1.fecha_numero
;quit;

/*6690*/
/*5.2- 90 días -> Clientes que no usaron su tarjeta en los 90 días.*/
proc sql;
create table &libreria_final..ONBOARDING_SIN_USO_90D as
select t1.*
from &libreria_final..ONBOARDING t1
WHERE t1.concreta_90_SPOS =0
     and     t1.concreta_90_tda=0
	 and t1.concreta_30_SPOS =0
     and     t1.concreta_30_tda=0
	 and t1.concreta_60_SPOS =0
     and     t1.concreta_60_tda=0
	 and t1.dia_90 < &fecha_hoy
ORDER BY T1.fecha_numero
;quit;

/*
1-kmartine.ONBOARDING_CAPTA_PRESENCIAL  --> 49.405
2-kmartine.ONBOARDING_CAPTA_NO_PRESENCIAL --> 126.164
3.1-kmartine.ONBOARDING_USO_30D -->89.667
3.2-kmartine.ONBOARDING_USO_90D -->16.064
4.1-kmartine.ONBOARDING_DEJO_DE_USAR_90D -->39.872
4.1-kmartine.ONBOARDING_DEJO_DE_USAR_60D -->79.247
5.1-kmartine.ONBOARDING_SIN_USO_30D -->60.501
5.2-kmartine.ONBOARDING_SIN_USO_90D --> 6.731*/

/*==================================================================================================*/
/*== INICIO : Macro para export al ftp de Control comercial donde los tomará el equipo de Calidad ==*/
%macro ciclos(tabla, archivo);

	PROC EXPORT DATA=&tabla.
	OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/TO_CALIDAD/&archivo."
	DBMS=dlm replace;
	delimiter=';';
	PUTNAMES=YES;
	RUN;

	filename server ftp "&archivo." CD='/'
	HOST='192.168.82.171' user='17457765K' pass='17457765K' PORT=21;

	data _null_;
	infile "/sasdata/users94/user_bi/TRASPASO_DOCS/TO_CALIDAD/&archivo.";
	file server;
	input;
	put _infile_;
	run;

%mend ciclos;

%ciclos(&libreria_final..ONBOARDING_CAPTA_PRESENCIAL,ONBOARDING_CAPTA_PRESENCIAL.csv);
%ciclos(&libreria_final..ONBOARDING_CAPTA_NO_PRESENCIAL,ONBOARDING_CAPTA_NO_PRESENCIAL.csv);
%ciclos(&libreria_final..ONBOARDING_USO_30D,ONBOARDING_USO_30D.csv);
%ciclos(&libreria_final..ONBOARDING_USO_90D,ONBOARDING_USO_90D.csv);
%ciclos(&libreria_final..ONBOARDING_DEJO_DE_USAR_90D,ONBOARDING_DEJO_DE_USAR_90D.csv);
%ciclos(&libreria_final..ONBOARDING_DEJO_DE_USAR_60D,ONBOARDING_DEJO_DE_USAR_60D.csv);
%ciclos(&libreria_final..ONBOARDING_SIN_USO_30D,ONBOARDING_SIN_USO_30D.csv);
%ciclos(&libreria_final..ONBOARDING_SIN_USO_90D,ONBOARDING_SIN_USO_90D.csv);

/*== FINAL : Macro para export al ftp de Control comercial donde los tomará el equipo de Calidad  ==*/
/*==================================================================================================*/

/*==================================================================================================*/
/*== Envío correo notificación ==== EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/

data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_CLIENTES';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CLIENTES_2';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'MARCELO_ANTONELLI';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3; %put &=DEST_4;	%put &=DEST_5;	%put &=DEST_6;


/* VARIABLE TIEMPO - FIN */
data _null_;
dur = datetime() - &tiempo_inicio;
put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
/*TO = ("&DEST_1")*/
TO = ("&DEST_6")
CC = ("&DEST_1", "&DEST_2", "&DEST_3", "&DEST_4", "&DEST_5")
SUBJECT = ("MAIL_AUTOM: Proceso BASE_ESTUDIO_ONBOARDING_PARTE2");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "		Proceso BASE_ESTUDIO_ONBOARDING_PARTE2, ejecutado con fecha: &fechaeDVN";  
 PUT "		Información disponible en:";  
 PUT "			- SAS, librería &libreria_final. ";
 PUT "			- Ftp 192.168.82.171, archivos con extensión .csv";
 PUT ;
 PUT "		Nombres de tablas y archivos:";
 PUT "			- ONBOARDING_CAPTA_PRESENCIAL";
 PUT "			- ONBOARDING_CAPTA_NO_PRESENCIAL";
 PUT "			- ONBOARDING_USO_30D";
 PUT "			- ONBOARDING_USO_90D";
 PUT "			- ONBOARDING_DEJO_DE_USAR_90D";
 PUT "			- ONBOARDING_DEJO_DE_USAR_60D";
 PUT "			- ONBOARDING_SIN_USO_30D";
 PUT "			- ONBOARDING_SIN_USO_90D";
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 03'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
