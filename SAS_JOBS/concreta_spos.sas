/*==================================================================================================*/
/*==================================	EQUIPO ARQ.DATOS Y AUTOM.		============================*/
/*==================================	concreta_spos					============================*/
/* CONTROL DE VERSIONES
/* 2022-08-25 -- V08	-- Sergio J.	-- Se añade sentencia include para borrar y exportar a RAW
/* 2022-07-22 -- V07	-- Sergio J. 	-- Modificación de conexión a Segcom.
/* 2022-07-12 -- V06	-- David V. 	-- Ajustes mínimos para nuevo flujo "Oracloud AWS Athena".
/* 0000-00-00 -- V05 	-- XXXXXXX. 	-- Versión original actual
*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*==================================================================================================*/

/*Tiempo de activación promedio en los últimos 3 meses (separado por producto y tipo de producto)
Cantidad de clientes que entran en la app separado por quienes concretan o no en la APP (veamos forma de segmentarlo)
Estos mismos puntos 1 y 2, tenerlo durante la captación del mes de marzo y abril
*/

%let libreria=RESULT;

%macro concrecion_3M_REAL(N,libreria);

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



%put &periodo_actual;
%put &periodo_1;
%put &periodo_2;
%put &periodo_3;
%put &ini_mes;
%put &fin_mes;
%put &periodo_4;
%put &periodo_5;
%put &periodo_6;


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
via
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
;QUIT;




%if (%sysfunc(exist(publicin.spos_aut_&periodo_actual.))) %then %do;
PROC SQL ;
create table spos1 as 
SELECT
distinct 
rut,
fecha
FROM publicin.spos_aut_&periodo_actual.
;quit;
%end;
%else %do;
PROC SQL ;
create table spos1 
(rut num,
fecha num)
;quit;
%end;


%if (%sysfunc(exist(publicin.spos_aut_&periodo_1.))) %then %do;
PROC SQL ;
create table spos2 as 
SELECT
distinct 
rut,
fecha
FROM publicin.spos_aut_&periodo_1. 
;quit;
%end;
%else %do;
PROC SQL ;
create table spos2 
(rut num,
fecha num)
;quit;
%end;

%if (%sysfunc(exist(publicin.spos_aut_&periodo_2.))) %then %do;
PROC SQL ;
create table spos3 as 
SELECT
distinct 
rut,
fecha
FROM publicin.spos_aut_&periodo_2. 
;quit;
%end;
%else %do;
PROC SQL ;
create table spos3 
(rut num,
fecha num)
;quit;
%end;

%if (%sysfunc(exist(publicin.spos_aut_&periodo_3.))) %then %do;
PROC SQL ;
create table spos4 as 
SELECT
distinct 
rut,
fecha
FROM publicin.spos_aut_&periodo_3. 
;quit;
%end;
%else %do;
PROC SQL ;
create table spos4 
(rut num,
fecha num)
;quit;
%end;

%if (%sysfunc(exist(publicin.tda_itf_&periodo_actual.))) %then %do;
PROC SQL ;
create table tda1 as 
SELECT
distinct 
rut,
year(fecha)*10000+month(fecha)*100+day(fecha) as fecha
FROM publicin.tda_itf_&periodo_actual.
where capital>0
;quit;
%end;
%else %do;
PROC SQL ;
create table tda1 
(rut num,
fecha num)
;quit;
%end;


%if (%sysfunc(exist(publicin.tda_itf_&periodo_1.))) %then %do;
PROC SQL ;
create table tda2 as 
SELECT
distinct 
rut,
year(fecha)*10000+month(fecha)*100+day(fecha) as fecha
FROM publicin.tda_itf_&periodo_1.  where capital>0
;quit;
%end;
%else %do;
PROC SQL ;
create table tda2 
(rut num,
fecha num)
;quit;
%end;

%if (%sysfunc(exist(publicin.tda_itf_&periodo_2.))) %then %do;
PROC SQL ;
create table tda3 as 
SELECT
distinct 
rut,
year(fecha)*10000+month(fecha)*100+day(fecha) as fecha
FROM publicin.tda_itf_&periodo_2. where capital>0
;quit;
%end;
%else %do;
PROC SQL ;
create table tda3 
(rut num,
fecha num)
;quit;
%end;

%if (%sysfunc(exist(publicin.tda_itf_&periodo_3.))) %then %do;
PROC SQL ;
create table tda4 as 
SELECT
distinct 
rut,
year(fecha)*10000+month(fecha)*100+day(fecha) as fecha
FROM publicin.tda_itf_&periodo_3. where capital>0
;quit;
%end;
%else %do;
PROC SQL ;
create table tda4 
(rut num,
fecha num)
;quit;
%end;

%if (%sysfunc(exist(publicin.TDA_mcd_&periodo_actual.))) %then %do;
PROC SQL ;
create table TDA_MCD1 as 
SELECT
distinct 
rut,
fecha
FROM publicin.TDA_mcd_&periodo_actual.
where producto='08'
;quit;
%end;
%else %do;
PROC SQL ;
create table TDA_MCD1 
(rut num,
fecha num)
;quit;
%end;


%if (%sysfunc(exist(publicin.TDA_mcd_&periodo_1.))) %then %do;
PROC SQL ;
create table TDA_MCD2 as 
SELECT
distinct 
rut,
fecha
FROM publicin.TDA_mcd_&periodo_1. where producto='08'
;quit;
%end;
%else %do;
PROC SQL ;
create table TDA_MCD2 
(rut num,
fecha num)
;quit;
%end;

%if (%sysfunc(exist(publicin.TDA_mcd_&periodo_2.))) %then %do;
PROC SQL ;
create table TDA_MCD3 as 
SELECT
distinct 
rut,
fecha
FROM publicin.TDA_mcd_&periodo_2. where producto='08'
;quit;
%end;
%else %do;
PROC SQL ;
create table TDA_MCD3 
(rut num,
fecha num)
;quit;
%end;

%if (%sysfunc(exist(publicin.TDA_mcd_&periodo_3.))) %then %do;
PROC SQL ;
create table TDA_MCD4 as 
SELECT
distinct 
rut,
fecha
FROM publicin.TDA_mcd_&periodo_3. where producto='08'
;quit;
%end;
%else %do;
PROC SQL ;
create table TDA_MCD4 
(rut num,
fecha num)
;quit;
%end;


%if (%sysfunc(exist(publicin.TDA_MAESTRO_&periodo_actual.))) %then %do;
PROC SQL ;
create table TDA_MAESTRO1 as 
SELECT
distinct 
rut,
fecha
FROM publicin.TDA_MAESTRO_&periodo_actual.

;quit;
%end;
%else %do;
PROC SQL ;
create table TDA_MAESTRO1 
(rut num,
fecha num)
;quit;
%end;


%if (%sysfunc(exist(publicin.TDA_MAESTRO_&periodo_1.))) %then %do;
PROC SQL ;
create table TDA_MAESTRO2 as 
SELECT
distinct 
rut,
fecha
FROM publicin.TDA_MAESTRO_&periodo_1.
;quit;
%end;
%else %do;
PROC SQL ;
create table TDA_MAESTRO2 
(rut num,
fecha num)
;quit;
%end;

%if (%sysfunc(exist(publicin.TDA_MAESTRO_&periodo_2.))) %then %do;
PROC SQL ;
create table TDA_MAESTRO3 as 
SELECT
distinct 
rut,
fecha
FROM publicin.TDA_MAESTRO_&periodo_2.
;quit;
%end;
%else %do;
PROC SQL ;
create table TDA_MAESTRO3 
(rut num,
fecha num)
;quit;
%end;

%if (%sysfunc(exist(publicin.TDA_MAESTRO_&periodo_3.))) %then %do;
PROC SQL ;
create table TDA_MAESTRO4 as 
SELECT
distinct 
rut,
fecha
FROM publicin.TDA_MAESTRO_&periodo_3. 
;quit;
%end;
%else %do;
PROC SQL ;
create table TDA_MAESTRO4 
(rut num,
fecha num)
;quit;
%end;



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


%if (%sysfunc(exist(publicin.spos_mcd_&periodo_actual.))) %then %do;
PROC SQL ;
create table spos_MCD1 as 
SELECT
distinct 
rut,
fecha
FROM publicin.spos_mcd_&periodo_actual.
where producto='08'
;quit;
%end;
%else %do;
PROC SQL ;
create table spos_MCD1 
(rut num,
fecha num)
;quit;
%end;


%if (%sysfunc(exist(publicin.spos_mcd_&periodo_1.))) %then %do;
PROC SQL ;
create table spos_MCD2 as 
SELECT
distinct 
rut,
fecha
FROM publicin.spos_mcd_&periodo_1. where producto='08'
;quit;
%end;
%else %do;
PROC SQL ;
create table spos_MCD2 
(rut num,
fecha num)
;quit;
%end;

%if (%sysfunc(exist(publicin.spos_mcd_&periodo_2.))) %then %do;
PROC SQL ;
create table spos_MCD3 as 
SELECT
distinct 
rut,
fecha
FROM publicin.spos_mcd_&periodo_2. where producto='08'
;quit;
%end;
%else %do;
PROC SQL ;
create table spos_MCD3 
(rut num,
fecha num)
;quit;
%end;

%if (%sysfunc(exist(publicin.spos_mcd_&periodo_3.))) %then %do;
PROC SQL ;
create table spos_MCD4 as 
SELECT
distinct 
rut,
fecha
FROM publicin.spos_mcd_&periodo_3. where producto='08'
;quit;
%end;
%else %do;
PROC SQL ;
create table spos_MCD4 
(rut num,
fecha num)
;quit;
%end;


%if (%sysfunc(exist(publicin.spos_MAESTRO_&periodo_actual.))) %then %do;
PROC SQL ;
create table spos_MAESTRO1 as 
SELECT
distinct 
rut,
fecha
FROM publicin.spos_MAESTRO_&periodo_actual.

;quit;
%end;
%else %do;
PROC SQL ;
create table spos_MAESTRO1 
(rut num,
fecha num)
;quit;
%end;


%if (%sysfunc(exist(publicin.spos_MAESTRO_&periodo_1.))) %then %do;
PROC SQL ;
create table spos_MAESTRO2 as 
SELECT
distinct 
rut,
fecha
FROM publicin.spos_MAESTRO_&periodo_1.
;quit;
%end;
%else %do;
PROC SQL ;
create table spos_MAESTRO2 
(rut num,
fecha num)
;quit;
%end;

%if (%sysfunc(exist(publicin.spos_MAESTRO_&periodo_2.))) %then %do;
PROC SQL ;
create table spos_MAESTRO3 as 
SELECT
distinct 
rut,
fecha
FROM publicin.spos_MAESTRO_&periodo_2.
;quit;
%end;
%else %do;
PROC SQL ;
create table spos_MAESTRO3 
(rut num,
fecha num)
;quit;
%end;

%if (%sysfunc(exist(publicin.spos_MAESTRO_&periodo_3.))) %then %do;
PROC SQL ;
create table spos_MAESTRO4 as 
SELECT
distinct 
rut,
fecha
FROM publicin.spos_MAESTRO_&periodo_3. 
;quit;
%end;
%else %do;
PROC SQL ;
create table spos_MAESTRO4 
(rut num,
fecha num)
;quit;
%end;



proc sql;
create table spos_DEBITO_fin as 
select *
from spos_MCD1
union 
select *
from spos_MCD2
union 
select *
from spos_MCD3
union 
select *
from spos_MCD4
union select *
from spos_MAESTRO1
union 
select *
from spos_MAESTRO2
union 
select *
from spos_MAESTRO3
union 
select *
from spos_MAESTRO4
;QUIT;


%if (%sysfunc(exist(publicin.TDA_CTACTE_&periodo_actual.))) %then %do;
PROC SQL ;
create table TDA_CC1 as 
SELECT
distinct 
rut,
fecha
FROM publicin.TDA_CTACTE_&periodo_actual.
where producto='13'
;quit;
%end;
%else %do;
PROC SQL ;
create table TDA_CC1 
(rut num,
fecha num)
;quit;
%end;


%if (%sysfunc(exist(publicin.TDA_CTACTE_&periodo_1.))) %then %do;
PROC SQL ;
create table TDA_CC2 as 
SELECT
distinct 
rut,
fecha
FROM publicin.TDA_CTACTE_&periodo_1. where producto='13'
;quit;
%end;
%else %do;
PROC SQL ;
create table TDA_CC2 
(rut num,
fecha num)
;quit;
%end;

%if (%sysfunc(exist(publicin.TDA_CTACTE_&periodo_2.))) %then %do;
PROC SQL ;
create table TDA_CC3 as 
SELECT
distinct 
rut,
fecha
FROM publicin.TDA_CTACTE_&periodo_2. where producto='13'
;quit;
%end;
%else %do;
PROC SQL ;
create table TDA_CC3 
(rut num,
fecha num)
;quit;
%end;

%if (%sysfunc(exist(publicin.TDA_CTACTE_&periodo_3.))) %then %do;
PROC SQL ;
create table TDA_CC4 as 
SELECT
distinct 
rut,
fecha
FROM publicin.TDA_CTACTE_&periodo_3. where producto='13'
;quit;
%end;
%else %do;
PROC SQL ;
create table TDA_CC4 
(rut num,
fecha num)
;quit;
%end;



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



%if (%sysfunc(exist(publicin.SPOS_CTACTE_&periodo_actual.))) %then %do;
PROC SQL ;
create table spos_CC1 as 
SELECT
distinct 
rut,
fecha
FROM publicin.SPOS_CTACTE_&periodo_actual.
where producto='13'
;quit;
%end;
%else %do;
PROC SQL ;
create table spos_CC1 
(rut num,
fecha num)
;quit;
%end;


%if (%sysfunc(exist(publicin.SPOS_CTACTE_&periodo_1.))) %then %do;
PROC SQL ;
create table spos_CC2 as 
SELECT
distinct 
rut,
fecha
FROM publicin.SPOS_CTACTE_&periodo_1. where producto='13'
;quit;
%end;
%else %do;
PROC SQL ;
create table spos_CC2 
(rut num,
fecha num)
;quit;
%end;

%if (%sysfunc(exist(publicin.SPOS_CTACTE_&periodo_2.))) %then %do;
PROC SQL ;
create table spos_CC3 as 
SELECT
distinct 
rut,
fecha
FROM publicin.SPOS_CTACTE_&periodo_2. where producto='13'
;quit;
%end;
%else %do;
PROC SQL ;
create table spos_CC3 
(rut num,
fecha num)
;quit;
%end;

%if (%sysfunc(exist(publicin.SPOS_CTACTE_&periodo_3.))) %then %do;
PROC SQL ;
create table spos_CC4 as 
SELECT
distinct 
rut,
fecha
FROM publicin.SPOS_CTACTE_&periodo_3. where producto='13'
;quit;
%end;
%else %do;
PROC SQL ;
create table spos_CC4 
(rut num,
fecha num)
;quit;
%end;




proc sql;
create table spos_CC_fin as 
select *
from spos_CC1
union 
select *
from spos_CC2
union 
select *
from spos_CC3
union 
select *
from spos_CC4

;QUIT;

proc sql;
create table spos_fin as 
select *
from spos1
union 
select *
from spos2
union 
select *
from spos3
union 
select *
from spos4
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
create table captados2 as 
select distinct 
a.*,

max(case 
when a.producto in ('TR','TAM','CAMBIO DE PRODUCTO','TAM_CERRADA','TAM_CUOTAS')
and (b.rut is not null or c.rut is not null)
and (b.fecha between a.fecha_numero	and a.dia_30 
or c.fecha between a.fecha_numero and a.dia_30) then 1 
when a.producto in ('CUENTA VISTA')
and (d.rut is not null or e.rut is not null)
and (d.fecha between a.fecha_numero	and a.dia_30 
or e.fecha between a.fecha_numero and a.dia_30) then 1 
when a.producto in ('CUENTA CORRIENTE')
and (f.rut is not null or g.rut is not null)
and (f.fecha between a.fecha_numero	and a.dia_30 
or g.fecha between a.fecha_numero and a.dia_30) then 1 
else 0 end ) as concreta_30_T,

max(case 
when a.producto in ('TR','TAM','CAMBIO DE PRODUCTO','TAM_CERRADA','TAM_CUOTAS')
and (b.rut is not null or c.rut is not null)
and (b.fecha between a.fecha_numero	and a.dia_60 
or c.fecha between a.fecha_numero and a.dia_60) then 1 
when a.producto in ('CUENTA VISTA')
and (d.rut is not null or e.rut is not null)
and (d.fecha between a.fecha_numero	and a.dia_60 
or e.fecha between a.fecha_numero and a.dia_60) then 1 
when a.producto in ('CUENTA CORRIENTE')
and (f.rut is not null or g.rut is not null)
and (f.fecha between a.fecha_numero	and a.dia_60 
or g.fecha between a.fecha_numero and a.dia_60) then 1 
else 0 end  ) as concreta_60_T,

max(case 
when a.producto in ('TR','TAM','CAMBIO DE PRODUCTO','TAM_CERRADA','TAM_CUOTAS')
and (b.rut is not null or c.rut is not null)
and (b.fecha between a.fecha_numero	and a.dia_90 
or c.fecha between a.fecha_numero and a.dia_90) then 1 
when a.producto in ('CUENTA VISTA')
and (d.rut is not null or e.rut is not null)
and (d.fecha between a.fecha_numero	and a.dia_90 
or e.fecha between a.fecha_numero and a.dia_90) then 1 
when a.producto in ('CUENTA CORRIENTE')
and (f.rut is not null or g.rut is not null)
and (f.fecha between a.fecha_numero	and a.dia_90 
or g.fecha between a.fecha_numero and a.dia_90) then 1 
else 0 end  ) as concreta_90_T,

max(case 
when b.rut is not null and a.producto in ('TR','TAM','CAMBIO DE PRODUCTO','TAM_CERRADA','TAM_CUOTAS')
and b.fecha between a.fecha_numero	and a.dia_30 then 1
when d.rut is not null and a.producto in ('CUENTA VISTA')
and d.fecha between a.fecha_numero	and a.dia_30 then 1
when g.rut is not null and a.producto in ('CUENTA CORRIENTE')
and g.fecha between a.fecha_numero	and a.dia_30 then 1
else 0 end ) as concreta_30_SPOS,

max( case 
when b.rut is not null and a.producto in ('TR','TAM','CAMBIO DE PRODUCTO','TAM_CERRADA','TAM_CUOTAS')
and b.fecha between a.fecha_numero	and a.dia_60 then 1
when d.rut is not null and a.producto in ('CUENTA VISTA')
and d.fecha between a.fecha_numero	and a.dia_60 then 1
when g.rut is not null and a.producto in ('CUENTA CORRIENTE')
and g.fecha between a.fecha_numero	and a.dia_60 then 1
else 0 end) as concreta_60_SPOS,

max(case 
when b.rut is not null and a.producto in ('TR','TAM','CAMBIO DE PRODUCTO','TAM_CERRADA','TAM_CUOTAS')
and b.fecha between a.fecha_numero	and a.dia_90 then 1
when d.rut is not null and a.producto in ('CUENTA VISTA')
and d.fecha between a.fecha_numero	and a.dia_90 then 1
when g.rut is not null and a.producto in ('CUENTA CORRIENTE')
and g.fecha between a.fecha_numero	and a.dia_90 then 1
else 0 end
) as concreta_90_SPOS,


max(case 
when c.rut is not null and a.producto in ('TR','TAM','CAMBIO DE PRODUCTO','TAM_CERRADA','TAM_CUOTAS')
and c.fecha between a.fecha_numero	and a.dia_30 then 1
when e.rut is not null and a.producto in ('CUENTA VISTA')
and e.fecha between a.fecha_numero	and a.dia_30 then 1
when f.rut is not null and a.producto in ('CUENTA CORRIENTE')
and f.fecha between a.fecha_numero	and a.dia_30 then 1
else 0 end
) as concreta_30_tda,

max(case 
when c.rut is not null and a.producto in ('TR','TAM','CAMBIO DE PRODUCTO','TAM_CERRADA','TAM_CUOTAS')
and c.fecha between a.fecha_numero	and a.dia_60 then 1
when e.rut is not null and a.producto in ('CUENTA VISTA')
and e.fecha between a.fecha_numero	and a.dia_60 then 1
when f.rut is not null and a.producto in ('CUENTA CORRIENTE')
and f.fecha between a.fecha_numero	and a.dia_60 then 1
else 0 end ) as concreta_60_tda,

max(case 
when c.rut is not null and a.producto in ('TR','TAM','CAMBIO DE PRODUCTO','TAM_CERRADA','TAM_CUOTAS')
and c.fecha between a.fecha_numero	and a.dia_90 then 1
when e.rut is not null and a.producto in ('CUENTA VISTA')
and e.fecha between a.fecha_numero	and a.dia_90 then 1
when f.rut is not null and a.producto in ('CUENTA CORRIENTE')
and f.fecha between a.fecha_numero	and a.dia_90 then 1
else 0 end ) as concreta_90_tda


from captados as a 
left join spos_fin as b
on(a.rut=b.rut)
left join tda_fin as c
on(a.rut=c.rut)
left join spos_debito_fin as d
oN(a.rut=d.rut)
left join TDA_debito_fin as e
oN(a.rut=e.rut)
left join TDA_CC_fin as f
oN(a.rut=f.rut)
left join SPOS_CC_fin as g
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

/*tipo de cliente captado*/



proc sql;
create table llenado (
CAMP_ID_OFE_K num,
CAMP_COD_CAMP_FK char(99),
CAMP_RUT_CLI num,
CAMP_DV_CLI char(99),
CAMP_COD_TIP_PROD char(99),
CAMP_COD_CND_PROD char(99),
CAMP_COD_ORI_BASE char(99)

)
;QUIT;

proc sql noprint ;
select
ceil (count(distinct case when ID_OFERTA is not null then ID_OFERTA end )/500) as corte
into: corte
from captados2
;QUIT;

%let corte=&corte;
%put &corte;

%macro sacar_data(N);

proc sql;
create table base_cortar as 
select 
monotonic() as ind,
ID_OFERTA
from captados2
where ID_OFERTA is not null
;QUIT;

%do i=1 %to &n.;

%put==================================================================================================;
%put CICLO &I. ;
%put==================================================================================================;

proc sql;
create table base_paso_in as 
select 
ID_OFERTA
from base_cortar
where ind between 500*(&i.-1)+1 and 500*&i.
;QUIT;

data work.Valor_Concatenado(keep=Listado); /*base de salida con campo*/
length Listado $9999; /*largo del campo*/
do until(eof);
set work.base_paso_in end=eof; /*base de entrada: (Base detalle de codigos LATAM)*/
Listado = catx(",", Listado, ID_OFERTA); /*concatenacion*/
end;
run;

proc sql outobs=1 noprint ;
select Listado
into :Listado 
from work.Valor_Concatenado 
;quit;
%let Listado="&Listado";

DATA _NULL_;
Call execute(
cat('
PROC SQL ;
CONNECT TO ORACLE  (PATH=''BRTEFGESTIONP.WORLD'' USER=''CAMP_COMERCIAL'' PASSWORD=''ccomer2409'');
CREATE TABLE cod_camp AS   
SELECT 
* 
FROM CONNECTION TO ORACLE(
SELECT 
CAMP_ID_OFE_K,
CAMP_COD_CAMP_FK,
CAMP_RUT_CLI,
CAMP_DV_CLI,
CAMP_COD_TIP_PROD,
CAMP_COD_CND_PROD,
CAMP_COD_ORI_BASE 

from cbcamp_mae_ofertas 
where CAMP_ID_OFE_K in ( ',&Listado.,' ) ) A 
;QUIT;
')
);
run;  

proc sql;
insert into llenado
select *
from cod_camp 
;QUIT;

proc sql;
drop table base_paso_in;
drop table Valor_Concatenado;
drop table cod_camp;
;QUIT;

%end;

proc sql;
drop table base_cortar
;QUIT;

%mend sacar_data;

%sacar_data(&corte.);





proc sql;
create table llenado2 (
CAMP_ID_OFE_K num,
CAMP_COD_CAMP_FK char(99),
CAMP_RUT_CLI num,
CAMP_DV_CLI char(99),
CAMP_COD_TIP_PROD char(99),
CAMP_COD_CND_PROD char(99),
CAMP_COD_ORI_BASE char(99)

)
;QUIT;

proc sql noprint ;
select
ceil (count(distinct case when ID_OFERTA is not null then ID_OFERTA end )/500) as corte
into: corte
from captados2 where 
id_oferta not in (select CAMP_ID_OFE_K from llenado)
;QUIT;

%let corte=&corte;
%put &corte;

proc sql noprint;                              
SELECT USUARIO into :USER 
	FROM sasdyp.user_pass WHERE SCHEMA = 'SEGCOM';
SELECT PASSWORD into :PASSWORD 
	FROM sasdyp.user_pass WHERE SCHEMA = 'SEGCOM';
quit;
%put &USER;
%put &PASSWORD;

%let path_ora       = '(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.84.167)(PORT = 1521))(CONNECT_DATA=(SERVER = DEDICATED)(SERVICE_NAME = segcom)))';
%let conexion_ora   = ORACLE PATH=&path_ora. USER=&USER. PASSWORD=&PASSWORD.;
%put &conexion_ora.;

LIBNAME DBLIBORA     &conexion_ora. insertbuff=10000 readbuff=10000;  

%macro sacar_data2(N);

proc sql;
create table base_cortar as 
select 
monotonic() as ind,
ID_OFERTA
from captados2
where ID_OFERTA is not null and   id_oferta not in (select CAMP_ID_OFE_K from llenado)
;QUIT;

%do i=1 %to &n.;

%put==================================================================================================;
%put CICLO &I. ;
%put==================================================================================================;

proc sql ;
create table base_paso_in as 
select 
ID_OFERTA
from base_cortar
where ind between 500*(&i.-1)+1 and 500*&i.
;QUIT;

data work.Valor_Concatenado(keep=Listado); /*base de salida con campo*/
length Listado $9999; /*largo del campo*/
do until(eof);
set work.base_paso_in end=eof; /*base de entrada: (Base detalle de codigos LATAM)*/
Listado = catx(",", Listado, ID_OFERTA); /*concatenacion*/
end;
run;

proc sql outobs=1 noprint ;
select Listado
into :Listado 
from work.Valor_Concatenado 
;quit;
%let Listado=&Listado;


PROC SQL ;
CONNECT TO ORACLE  (PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.);
CREATE TABLE cod_camp AS   
SELECT 
* 
FROM CONNECTION TO ORACLE(
SELECT 
CAMP_ID_OFE_K,
CAMP_COD_CAMP_FK,
CAMP_RUT_CLI,
CAMP_DV_CLI,
CAMP_COD_TIP_PROD,
CAMP_COD_CND_PROD,
CAMP_COD_ORI_BASE 

from CAMPHIS_ADM.cbcamp_mae_ofertas_HIST  
where CAMP_ID_OFE_K in ( &Listado. )
) A 
;QUIT;
 

proc sql;
insert into llenado2
select *
from cod_camp 
;QUIT;

proc sql;
drop table base_paso_in;
drop table Valor_Concatenado;
drop table cod_camp;
;QUIT;

%end;

proc sql;
drop table base_cortar
;QUIT;

%mend sacar_data2;

%sacar_data2(&corte.);


proc sql;
create table llenado_fin as 
select 
*
from llenado
union select *
from llenado2
;QuiT;

proc sql;
create table captados3 as 
select 
a.*,
b.CAMP_COD_ORI_BASE,
c.detalle,
case when b.CAMP_COD_ORI_BASE in ('102',
'108',
'201',
'207',
'302') then 'NUEVO' else 'REVIGENTEADO' end as TIPO_CLIENTE
from captados2 as a 
left join llenado_fin as b
on(a.id_oferta=b.CAMP_ID_OFE_K)
left join pmunoz.tipo_cliente_camp as c
on(input(b.CAMP_COD_ORI_BASE,best.)=c.codigo)
;QUIT;


/*colapso*/ 



proc sql;
create table colapso as 
select 
&periodo_actual. as periodo,
PRODUCTO,
TIPO_CLIENTE,
case when COD_SUCURSAL=39 and 	VIA='HOMEBAN' then 'DIGITAL' else 'PRESENCIAL' end as TIPO_CAPTACION,
count(rut) as captados,
sum(concreta_30_T) as con_30_T,
sum(concreta_60_T) as con_60_T	,
sum(concreta_90_T) as con_90_T,
calculated con_60_T-calculated con_30_T as con_T_diff1, 
calculated con_90_T-calculated con_60_T as con_T_diff2, 

sum(concreta_30_SPOS) as con_30_SPOS,
sum(concreta_60_SPOS) as con_60_SPOS,
sum(concreta_90_SPOS) as con_90_SPOS,

calculated con_60_SPOS-calculated con_30_SPOS as con_SPOS_diff1, 
calculated con_90_SPOS-calculated con_60_SPOS as con_SPOS_diff2,

sum(concreta_30_tda) as	con_30_tda,
sum(concreta_60_tda) as	con_60_tda,
sum(concreta_90_tda) as con_90_tda,

calculated con_60_tda-calculated con_30_tda as con_tda_diff1, 
calculated con_90_tda-calculated con_60_tda as con_tda_diff2,

count(case when concreta_30_tda>0 and concreta_30_SPOS>0 then rut end) as	con_30_tda_SPOS,
count(case when concreta_60_tda>0 and concreta_60_SPOS>0 then rut end) as	con_60_tda_SPOS,
count(case when concreta_90_tda>0 and concreta_90_SPOS>0 then rut end) as con_90_tda_SPOS,

calculated con_60_tda_SPOS-calculated con_30_tda_SPOS as con_tda_SPOS_diff1, 
calculated con_90_tda_SPOS-calculated con_60_tda_SPOS as con_tda_SPOS_diff2,

count(case when concreta_30_tda>0 and concreta_30_SPOS=0 then rut end) as	con_30_solo_TDA,
count(case when concreta_60_tda>0 and concreta_60_SPOS=0 then rut end) as	con_60_solo_TDA,
count(case when concreta_90_tda>0 and concreta_90_SPOS=0 then rut end) as con_90_solo_TDA,

calculated con_60_solo_TDA-calculated con_30_solo_TDA as con_solo_TDA_diff1, 
calculated con_90_solo_TDA-calculated con_60_solo_TDA as con_solo_TDA_diff2,

count(case when concreta_30_tda=0 and concreta_30_SPOS>0 then rut end) as	con_30_solo_SPOS,
count(case when concreta_60_tda=0 and concreta_60_SPOS>0 then rut end) as	con_60_solo_SPOS,
count(case when concreta_90_tda=0 and concreta_90_SPOS>0 then rut end) as con_90_solo_SPOS,

calculated con_60_solo_SPOS-calculated con_30_solo_SPOS as con_solo_SPOS_diff1, 
calculated con_90_solo_SPOS-calculated con_60_solo_SPOS as con_solo_SPOS_diff2




from captados3 
group by 
PRODUCTO,
TIPO_CLIENTE,
calculated TIPO_CAPTACION
;QUIT;



proc sql;
delete * from &libreria..concrecion_3M_REAL 
where periodo=&periodo_actual.
;QUIT;

proc sql;
insert into &libreria..concrecion_3M_REAL  
select 
*
from colapso
;QUIT;

proc sql;
create table &libreria..concrecion_3M_REAL as
select * 
from &libreria..concrecion_3M_REAL 
;QUIT;


/*borrar todas las tablas del work, tener cuidado con tablas internas si no borrara toda la libreria*/
proc datasets library=WORK kill noprint;
run;
quit;

%mend concrecion_3M_REAL;


%macro ejecutar;

proc sql noprint;
select distinct 
day(today()) as dia
into:dia
from pmunoz.codigos_capta_cdp
;QUIT;

%if %eval(&dia.=5) %then %do;

%concrecion_3M_REAL(0,&libreria.);
%concrecion_3M_REAL(1,&libreria.);
%concrecion_3M_REAL(2,&libreria.);
%concrecion_3M_REAL(3,&libreria.);
%concrecion_3M_REAL(4,&libreria.);
%end;
%else %do;
%concrecion_3M_REAL(0,&libreria.);
%concrecion_3M_REAL(1,&libreria.);
%concrecion_3M_REAL(2,&libreria.);
%concrecion_3M_REAL(3,&libreria.);

%end;

%mend ejecutar;

%ejecutar;

%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_DELETE.sas";
%borrarOracleRaw(SPOS_ONBOARDING_NEW);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_EXPORT.sas";
%ExportacionOracleRaw(SPOS_ONBOARDING_NEW,&libreria..concrecion_3M_REAL);



/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4",'lhernandezh@bancoripley.com','jsantamaria@bancoripley.com','fmunozh@bancoripley.com',
'aillanesa@bancoripley.com','farancibiab@bancoripley.com','lbachelets@bancoripley.com',
'mbentjerodts@bancoripley.com','bschmidtm@bancoripley.com','crachondode@bancoripley.com',
'bmartinezg@bancoripley.com')
CC = ("&DEST_1","&DEST_2","&DEST_3")
SUBJECT="MAIL_AUTOM: PROCESO ONBOARDING CAPTACION %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso ONBOARDING CAPTACION, ejecutado.";  
 put "Para visualizar Dashboard utilizar el siguiente link:"; 
 put "https://tableau1.bancoripley.cl/#/site/BI_Lab/views/Onboardingcaptacin2_0/Historia1?:iid=2";
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 08'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
