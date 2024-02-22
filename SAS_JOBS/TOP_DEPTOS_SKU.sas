/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================    TOP_DEPTOS_SKU              ===============================*/
/* CONTROL DE VERSIONES
/* 2023-03-07 -- v03 -- David V.    -- Se agregaods exclude all
/* 2023-03-07 -- v02 -- David V.    -- Se agrega un noprint que faltaba.
/* 2022-12-12 -- v01 -- David V. -- Actualización para server SAS, versionamiento y correo.
/* 2022-12-07 -- v00 -- Ignacio P.  -- Original
*/

/* VARIABLE TIEMPO   - INICIO */
%let tiempo_inicio= %sysfunc(datetime());
options validvarname=any;
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

%let liberia=RESULT;

%macro TOP_DPTO_SKU(n);

%let peso_TRX=0.4;
%let peso_MONTO=0.6;

DATA _NULL_;
periodo = input(put(intnx('month',today(),-&n.,'end'),yymmn6. ),$10.);
Call symput("periodo", periodo);
RUN;
%put &periodo;


/*desde aqui se saca un resumen de la data*/

PROC SQL;
CREATE TABLE WORK.base_total AS
SELECT t1.Periodo,
t1.COD_DEPTO,
t1.DEPARTAMENTO_FIN,
t1.sku,
/*vista global*/
(sum(case when T1.SUCURSAL = 39 then t1.mto else 0 end)/1000000) as MTO_COM,
SUM(case when T1.SUCURSAL = 39 then NRO_UNI else 0 end) as NRO_UNI_COM,
(sum(case when T1.SUCURSAL <> 39 then t1.mto else 0 end)/1000000) as MTO_TDA,
SUM(case when T1.SUCURSAL <> 39 then NRO_UNI else 0 end) as NRO_UNI_TDA,
(SUM(t1.mto)/1000000) AS MTO_TOTAL,
SUM(NRO_UNI) AS NRO_UNI_TOTAL,

/*vista TR*/
(sum(case when MARCA_TIPO_TR = 'TR' then t1.mto else 0 end)/1000000) as MTO_TR_TOTAL,
SUM(case when MARCA_TIPO_TR = 'TR' then NRO_UNI else 0 end) as NRO_UNI_TR_TOTAL,
(sum(case when MARCA_TIPO_TR = 'TR' and T1.SUCURSAL = 39 then t1.mto else 0 end)/1000000) as MTO_COM_TR,
SUM(case when MARCA_TIPO_TR = 'TR' and T1.SUCURSAL = 39 then NRO_UNI else 0 end) as NRO_UNI_COM_TR,
(sum(case when MARCA_TIPO_TR = 'TR' and T1.SUCURSAL <> 39 then t1.mto else 0 end)/1000000) as MTO_TDA_TR,
SUM(case when MARCA_TIPO_TR = 'TR' and T1.SUCURSAL <> 39 then NRO_UNI else 0 end) as NRO_UNI_TDA_TR,

/*vista opex*/
(sum(case when MARCA_TIPO_TR = 'TR' and OPEX_ONLINE=1 and T1.SUCURSAL = 39 then t1.mto else 0 end)/1000000) as MTO_COM_TR_OPEX,
SUM(case when MARCA_TIPO_TR = 'TR' and OPEX_ONLINE=1 and T1.SUCURSAL = 39 then NRO_UNI else 0 end) as NRO_UNI_COM_TR_OPEX,

(sum(case when MARCA_TIPO_TR = 'TR' and OPEX_TDA=1 and T1.SUCURSAL <> 39 then t1.mto else 0 end)/1000000) as MTO_TDA_TR_OPEX,
SUM(case when MARCA_TIPO_TR = 'TR' and OPEX_TDA=1 and T1.SUCURSAL <> 39 then NRO_UNI else 0 end) as NRO_UNI_TDA_TR_OPEX,

(sum(case when MARCA_TIPO_TR = 'TR' and OPEX_ONLINE+OPEX_TDA>0  then t1.mto else 0 end)/1000000) as MTO_TR_OPEX,
SUM(case when MARCA_TIPO_TR = 'TR' and OPEX_ONLINE+OPEX_TDA>0  then NRO_UNI else 0 end) as NRO_UNI_TR_OPEX,

/* vista sku  */
count(distinct(t1.sku)) as DIST_sku_TOTAL,
count(distinct(case when (OPEX_TDA=1 + OPEX_ONLINE=1)>=1 then t1.sku  end)) as DIST_sku_OPEX_TOTAL,

count(distinct(case when T1.SUCURSAL <> 39 AND MARCA_TIPO_TR = 'TR' then t1.sku  end)) as DIST_sku_TDA_TR_TOTAL,
count(distinct(case when T1.SUCURSAL = 39 AND MARCA_TIPO_TR = 'TR' then t1.sku   end)) as DIST_sku_COM_TR_TOTAL,

count(distinct(case when MARCA_TIPO_TR = 'TR' and OPEX_TDA=1 then t1.sku  end)) as DIST_sku_TDA_TR_OPEX_TOTAL,
count(distinct(case when MARCA_TIPO_TR = 'TR' and OPEX_ONLINE=1 then t1.sku  end)) as DIST_sku_COM_TR_OPEX_TOTAL

FROM RESULT.USO_TR_MARCA_&PERIODO. t1
GROUP BY
t1.Periodo,
t1.COD_DEPTO,
t1.DEPARTAMENTO_FIN,
t1.sku
;QUIT;

PROC SQL;
CREATE TABLE BASE_TOTAL_2 AS
SELECT
t1.Periodo,
t1.COD_DEPTO,
t1.DEPARTAMENTO_FIN,

/* vista sku  */
count(distinct(t1.sku)) as DIST_sku_TOTAL,
count(distinct(case when (OPEX_TDA=1 + OPEX_ONLINE=1)>=1 then t1.sku  end)) as DIST_sku_OPEX_TOTAL,


count(distinct(case when T1.SUCURSAL <> 39 AND MARCA_TIPO_TR = 'TR' then t1.sku end)) as DIST_sku_TDA_TR_TOTAL,
count(distinct(case when T1.SUCURSAL = 39 AND MARCA_TIPO_TR = 'TR' then t1.sku end)) as DIST_sku_COM_TR_TOTAL,

count(distinct(case when MARCA_TIPO_TR = 'TR' and OPEX_TDA=1 then t1.sku end)) as DIST_sku_TDA_TR_OPEX_TOTAL,
count(distinct(case when MARCA_TIPO_TR = 'TR' and OPEX_ONLINE=1 then t1.sku end)) as DIST_sku_COM_TR_OPEX_TOTAL

FROM RESULT.USO_TR_MARCA_&PERIODO. t1
GROUP BY
t1.Periodo,
t1.COD_DEPTO,
t1.DEPARTAMENTO_FIN
;QUIT;

PROC SQL;
   CREATE TABLE WORK.BASE_TOTAL_agrupada AS 
   SELECT t1.Periodo, 
          t1.COD_DEPTO, 
          t1.DEPARTAMENTO_FIN, 
          sum(t1.MTO_COM ) as MTO_COM, 
          sum(t1.NRO_UNI_COM ) as NRO_UNI_COM, 
          sum(t1.MTO_TDA ) as MTO_TDA, 
          sum(t1.NRO_UNI_TDA ) as NRO_UNI_TDA, 
          sum(t1.MTO_TOTAL ) as MTO_TOTAL, 
          sum(t1.NRO_UNI_TOTAL ) as NRO_UNI_TOTAL, 
          sum(t1.MTO_TR_TOTAL ) as MTO_TR_TOTAL, 
          sum(t1.NRO_UNI_TR_TOTAL ) as NRO_UNI_TR_TOTAL, 
          sum(t1.MTO_COM_TR ) as MTO_COM_TR, 
          sum(t1.NRO_UNI_COM_TR ) as NRO_UNI_COM_TR, 
          sum(t1.MTO_TDA_TR ) as MTO_TDA_TR, 
          sum(t1.NRO_UNI_TDA_TR ) as NRO_UNI_TDA_TR, 
          sum(t1.MTO_COM_TR_OPEX ) as MTO_COM_TR_OPEX, 
          sum(t1.NRO_UNI_COM_TR_OPEX ) as NRO_UNI_COM_TR_OPEX, 
          sum(t1.MTO_TDA_TR_OPEX ) as MTO_TDA_TR_OPEX, 
          sum(t1.NRO_UNI_TDA_TR_OPEX ) as NRO_UNI_TDA_TR_OPEX, 
          sum(t1.MTO_TR_OPEX ) as MTO_TR_OPEX, 
          sum(t1.NRO_UNI_TR_OPEX ) as NRO_UNI_TR_OPEX

      FROM WORK.BASE_TOTAL t1
     group by 
          t1.Periodo, 
          t1.COD_DEPTO, 
          t1.DEPARTAMENTO_FIN;
QUIT;

proc sql;
create table BASE_TOTAL_agrupada as
select 
t1.*,
t2.DIST_sku_TOTAL,
t2.DIST_sku_OPEX_TOTAL,
t2.DIST_sku_TDA_TR_TOTAL,
t2.DIST_sku_COM_TR_TOTAL,
t2.DIST_sku_TDA_TR_OPEX_TOTAL,
t2.DIST_sku_COM_TR_OPEX_TOTAL
from BASE_TOTAL_agrupada as t1
left join BASE_TOTAL_2 as t2 on (t1.COD_DEPTO=t2.COD_DEPTO)
;quit;


ods exclude all;
proc means data=work.BASE_TOTAL_agrupada StackODSOutput  P10 P90;
CLASS periodo;
var MTO_COM NRO_UNI_COM MTO_TDA  NRO_UNI_TDA MTO_TOTAL   NRO_UNI_TOTAL;
ods output summary=work.Perc;
run;
ods exclude none;


options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/



proc sql;
create table work.Vta_TDA2 as
select
a.*,
 SB_Valor_Interpolado(a.MTO_COM,1,b1.P10,b1.P90,0,1)   as P_MTO_COM,
 SB_Valor_Interpolado(a.NRO_UNI_COM,1,b2.P10,b2.P90,0,1)   as P_NRO_UNI_COM,
 SB_Valor_Interpolado(a.MTO_TDA,1,b3.P10,b3.P90,0,1)   as P_MTO_TDA,
 SB_Valor_Interpolado(a.NRO_UNI_TDA,1,b4.P10,b4.P90,0,1)   as P_NRO_UNI_TDA,
 SB_Valor_Interpolado(a.MTO_TOTAL,1,b5.P10,b5.P90,0,1)   as P_MTO_TOTAL,
 SB_Valor_Interpolado(a.NRO_UNI_TOTAL,1,b6.P10,b6.P90,0,1)   as P_NRO_UNI_TOTAL

from work.BASE_TOTAL_agrupada as a
left join work.Perc as b1
on (a.periodo=b1.periodo) and b1.variable='MTO_COM'

left join work.Perc as b2
on (a.periodo=b2.periodo) and b2.variable='NRO_UNI_COM'

left join work.Perc as b3
on (a.periodo=b3.periodo) and b3.variable='MTO_TDA'

left join work.Perc as b4
on (a.periodo=b4.periodo) and b4.variable='NRO_UNI_TDA'

left join work.Perc as b5
on (a.periodo=b5.periodo) and b5.variable='MTO_TOTAL'

left join work.Perc as b6
on (a.periodo=b6.periodo) and b6.variable='NRO_UNI_TOTAL'
;quit;

proc sql;
create table Vta_TDA3 as 
select *,
&peso_MONTO.*P_MTO_COM +&peso_TRX.*P_NRO_UNI_COM as nota_COM,
&peso_MONTO.*P_MTO_TDA +&peso_TRX.*P_NRO_UNI_TDA as nota_TDA,
&peso_MONTO.*P_MTO_TOTAL +&peso_TRX.*P_NRO_UNI_TOTAL as nota_TOTAL
from Vta_TDA2
;QUIT;

/* ordenar de mayor a menor por nota segun corresponda  */

proc sql; 
create table ORDEN_TOTAL as
select 
Periodo,
COD_DEPTO,
DEPARTAMENTO_FIN,
nota_TOTAL
from Vta_TDA3
order by nota_TOTAL desc
;quit;

proc sql; 
create table ORDEN_TDA as
select 
Periodo,
COD_DEPTO,
DEPARTAMENTO_FIN,
nota_TDA
from Vta_TDA3
order by nota_TDA desc
;quit;

proc sql; 
create table ORDEN_COM as
select 
Periodo,
COD_DEPTO,
DEPARTAMENTO_FIN,
nota_COM
from Vta_TDA3
order by nota_COM desc
;quit;


/*seleccion de top 20*/


proc sql inobs=20;
create table top_20_total as 
select 
Periodo,
COD_DEPTO,
DEPARTAMENTO_FIN,
nota_TOTAL
from ORDEN_TOTAL
;QUIT;

proc sql inobs=20;
create table top_20_tda as 
select 
Periodo,
COD_DEPTO,
DEPARTAMENTO_FIN,
nota_TDA
from ORDEN_TDA
;QUIT;


proc sql inobs=20;
create table top_20_com as 
select 
Periodo,
COD_DEPTO,
DEPARTAMENTO_FIN,
nota_COM
from ORDEN_COM
;QUIT;




proc sql;
create table colapso_agrupado as 
select 
'TOTAL' as categoria_total,
a.*
from Vta_TDA3 as a 
inner join top_20_total as b
on(a.COD_DEPTO =b.COD_DEPTO and 
a.DEPARTAMENTO_FIN=b.DEPARTAMENTO_FIN)

union 

select 
'TDA' as categoria_total,
a.*
from Vta_TDA3 as a 
inner join top_20_TDA as b
on(a.COD_DEPTO =b.COD_DEPTO and 
a.DEPARTAMENTO_FIN=b.DEPARTAMENTO_FIN)

union 

select 
'COM' as categoria_total,
a.*
from Vta_TDA3 as a 
inner join top_20_COM as b
on(a.COD_DEPTO =b.COD_DEPTO and 
a.DEPARTAMENTO_FIN=b.DEPARTAMENTO_FIN)
;QUIT;


/*desde aqui se realizara lo mismo pero a nivel de SKU*/

proc sql;
create table base_total_sku as 
select 
'TOTAL' as categoria_total,
a.*

from base_total as a 
inner join colapso_agrupado as b
on(a.COD_DEPTO =b.COD_DEPTO and 
a.DEPARTAMENTO_FIN=b.DEPARTAMENTO_FIN) and b.categoria_total='TOTAL'
/*and a.MTO_COM>0 and a.NRO_UNI_COM>0 and    a.MTO_TDA>0 and   a.NRO_UNI_TDA  >0 and a.MTO_TOTAL>0 and   a.NRO_UNI_TOTAL>0  */

union 
select 
'TDA' as categoria_total,
a.*

from base_total as a 
inner join colapso_agrupado as b
on(a.COD_DEPTO =b.COD_DEPTO and 
a.DEPARTAMENTO_FIN=b.DEPARTAMENTO_FIN) and b.categoria_total='TDA'
/*and a.MTO_COM>0 and a.NRO_UNI_COM>0 and    a.MTO_TDA>0 and   a.NRO_UNI_TDA  >0 and a.MTO_TOTAL>0 and   a.NRO_UNI_TOTAL>0 */ 

union 
select 
'COM' as categoria_total,
a.*

from base_total as a 
inner join colapso_agrupado as b
on(a.COD_DEPTO =b.COD_DEPTO and 
a.DEPARTAMENTO_FIN=b.DEPARTAMENTO_FIN) and b.categoria_total='COM'
/*and a.MTO_COM>0 and a.NRO_UNI_COM>0 and    a.MTO_TDA>0 and   a.NRO_UNI_TDA  >0 and a.MTO_TOTAL>0 and   a.NRO_UNI_TOTAL>0  */

;QUIT;


ods exclude all;
proc means data=work.base_total_sku StackODSOutput  P10 P90;
CLASS periodo COD_DEPTO categoria_total;
var MTO_COM NRO_UNI_COM MTO_TDA  NRO_UNI_TDA MTO_TOTAL   NRO_UNI_TOTAL;
ods output summary=work.Perc_SKU;
run;
ods exclude none;


proc sql;
create table work.Vta_TDA2_sku as
select
a.*,
 SB_Valor_Interpolado(a.MTO_COM,1,b1.P10,b1.P90,0,1)   as P_MTO_COM,
 SB_Valor_Interpolado(a.NRO_UNI_COM,1,b2.P10,b2.P90,0,1)   as P_NRO_UNI_COM,
 SB_Valor_Interpolado(a.MTO_TDA,1,b3.P10,b3.P90,0,1)   as P_MTO_TDA,
 SB_Valor_Interpolado(a.NRO_UNI_TDA,1,b4.P10,b4.P90,0,1)   as P_NRO_UNI_TDA,
 SB_Valor_Interpolado(a.MTO_TOTAL,1,b5.P10,b5.P90,0,1)   as P_MTO_TOTAL,
 SB_Valor_Interpolado(a.NRO_UNI_TOTAL,1,b6.P10,b6.P90,0,1)   as P_NRO_UNI_TOTAL

from work.base_total_sku as a
left join work.Perc_SKU as b1
on (a.periodo=b1.periodo) and b1.variable='MTO_COM' and (a.COD_DEPTO=b1.COD_DEPTO) and (a.categoria_total=b1.categoria_total)
and b1.P90-b1.P10>0

left join work.Perc_SKU as b2
on (a.periodo=b2.periodo) and b2.variable='NRO_UNI_COM' and (a.COD_DEPTO=b2.COD_DEPTO) and (a.categoria_total=b2.categoria_total)
and b2.P90-b2.P10>0
left join work.Perc_SKU as b3
on (a.periodo=b3.periodo) and b3.variable='MTO_TDA' and (a.COD_DEPTO=b3.COD_DEPTO) and (a.categoria_total=b3.categoria_total)
and b3.P90-b3.P10>0
left join work.Perc_SKU as b4
on (a.periodo=b4.periodo) and b4.variable='NRO_UNI_TDA' and (a.COD_DEPTO=b4.COD_DEPTO) and (a.categoria_total=b4.categoria_total)
and b4.P90-b4.P10>0
left join work.Perc_SKU as b5
on (a.periodo=b5.periodo) and b5.variable='MTO_TOTAL' and (a.COD_DEPTO=b5.COD_DEPTO) and (a.categoria_total=b5.categoria_total) 
and b5.P90-b5.P10>0
left join work.Perc_SKU as b6
on (a.periodo=b6.periodo) and b6.variable='NRO_UNI_TOTAL' and (a.COD_DEPTO=b6.COD_DEPTO) and (a.categoria_total=b6.categoria_total)
and b6.P90-b6.P10>0
;quit;

proc sql;
create table Vta_TDA3_sku as 
select *,
&peso_MONTO.*P_MTO_COM +&peso_TRX.*P_NRO_UNI_COM as nota_COM,
&peso_MONTO.*P_MTO_TDA +&peso_TRX.*P_NRO_UNI_TDA as nota_TDA,
&peso_MONTO.*P_MTO_TOTAL +&peso_TRX.*P_NRO_UNI_TOTAL as nota_TOTAL
from Vta_TDA2_sku
;QUIT;

proc sql;
create table llenado 
(categoria_total char(99),
cod_depto char(99),
sku num)
;QUIT;


%macro top_60_sku_DIGITAL;

proc sql;
create table lugar  as 
select distinct 
categoria_total,
COD_DEPTO
from Vta_TDA3_sku
where categoria_total='COM'
;QUIT;

proc sql;
create table lugar as 
select 
monotonic() as ind, * from lugar
;QUIT;

proc sql noprint ;
select max(ind) as stop
into:stop
from lugar
;QUIT;

%do i=1 %to &stop. ;


proc sql;
create table paso as 
select 
a.categoria_total,
a.COD_DEPTO,
a.sku,
a.nota_COM
from Vta_TDA3_sku as a 
inner join lugar as b
on(a.categoria_total=b.categoria_total and 
a.COD_DEPTO=b.COD_DEPTO) and ind=&i. 
order by a.nota_COM DESC
;QUIT;


proc sql inobs=60;
create table paso as 
select 
*
from paso 
;QUIT;

proc sql noprint;
insert into llenado
select  categoria_total,
COD_DEPTO,
sku
from paso
;QUIT;
%end;

%mend top_60_sku_DIGITAL;
%top_60_sku_DIGITAL;



%macro top_60_sku_TDA;

proc sql;
create table lugar  as 
select distinct 
categoria_total,
COD_DEPTO
from Vta_TDA3_sku
where categoria_total='TDA'
;QUIT;

proc sql;
create table lugar as 
select 
monotonic() as ind, * from lugar
;QUIT;

proc sql noprint ;
select max(ind) as stop
into:stop
from lugar
;QUIT;



%do i=1 %to &stop.;
proc sql;
create table paso as 
select 
a.categoria_total,
a.COD_DEPTO,
a.sku,
a.nota_TDA
from Vta_TDA3_sku as a 
inner join lugar as b
on(a.categoria_total=b.categoria_total and 
a.COD_DEPTO=b.COD_DEPTO) and ind=&i. 
order by a.nota_TDA DESC
;QUIT;


proc sql inobs=60;
create table paso as 
select 
*
from paso 
;QUIT;

proc sql noprint;
insert into llenado
select  categoria_total,
COD_DEPTO,
sku
from paso
;QUIT;
%end;

%mend top_60_sku_TDA;
%top_60_sku_TDA;



%macro top_60_sku_TOTAL;

proc sql;
create table lugar  as 
select distinct 
categoria_total,
COD_DEPTO
from Vta_TDA3_sku
where categoria_total='TOTAL'
;QUIT;

proc sql;
create table lugar as 
select 
monotonic() as ind, * from lugar
;QUIT;

proc sql noprint ;
select max(ind) as stop
into:stop
from lugar
;QUIT;



%do i=1 %to &stop.;

proc sql;
create table paso as 
select 
a.categoria_total,
a.COD_DEPTO,
a.sku,
a.nota_TOTAL
from Vta_TDA3_sku as a 
inner join lugar as b
on(a.categoria_total=b.categoria_total and 
a.COD_DEPTO=b.COD_DEPTO) and ind=&i. 
order by a.nota_TOTAL DESC
;QUIT;


proc sql inobs=60;
create table paso as 
select 
*
from paso 
;QUIT;

proc sql noprint;
insert into llenado
select  categoria_total,
COD_DEPTO,
sku
from paso
;QUIT;
%end;

%mend top_60_sku_TOTAL;

%top_60_sku_TOTAL;

proc sql;
create  table Vta_TDA4_sku as 
select a.*
from 
Vta_TDA3_sku as a 
inner join llenado as b
on(a.categoria_total=b.categoria_total and
a.COD_DEPTO=b.COD_DEPTO and
a.sku=b.sku )
;QUIT;


proc sql;
create table Vta_TDA5_sku as 
select 
a.*,
b.*
from Vta_TDA4_sku as a 
left join result.sku as b
on(a.sku=b.sku)
;QUIT;

/* LLENADO TABLA &liberia..TOP_20_DEPTOS */
/*
proc sql;
create table &liberia..TOP_20_DEPTOS as 
select *

from colapso_agrupado 
;QUIT;
*/

PROC SQL noprint;
DELETE FROM &liberia..TOP_20_DEPTOS
WHERE PERIODO=&PERIODO.
;QUIT;

PROC SQL noprint;
INSERT INTO &liberia..TOP_20_DEPTOS
SELECT *
FROM colapso_agrupado
;QUIT;

PROC SQL;
CREATE TABLE &liberia..TOP_20_DEPTOS AS
SELECT *
FROM &liberia..TOP_20_DEPTOS 
;QUIT;

/* LLENADO TABLA &liberia..TOP_60_SKU */

/*
proc sql;
create table &liberia..TOP_60_SKU as 
select *

from Vta_TDA5_sku 
;QUIT;
*/

PROC SQL noprint;
DELETE FROM &liberia..TOP_60_SKU
WHERE PERIODO=&PERIODO.
;QUIT;

PROC SQL noprint;
INSERT INTO &liberia..TOP_60_SKU
SELECT *
FROM Vta_TDA5_sku
;QUIT;

PROC SQL;
CREATE TABLE &liberia..TOP_60_SKU AS
SELECT *
FROM &liberia..TOP_60_SKU 
;QUIT;


/* LLENADO TABLA &liberia..TOP_60_SKU_PESO */

/*
proc sql;
create table &liberia..TOP_60_SKU_PESO as
select 
t1.categoria_total,
t1.Periodo,
t1.COD_DEPTO,
t1.DEPARTAMENTO_FIN,
sum(t1.MTO_COM) as MTO_COM,
sum(t1.NRO_UNI_COM) as NRO_UNI_COM,
sum(t1.MTO_TDA) as MTO_TDA,
sum(t1.NRO_UNI_TDA) as NRO_UNI_TDA,
sum(t1.MTO_TOTAL) as MTO_TOTAL,
sum(t1.NRO_UNI_TOTAL) as NRO_UNI_TOTAL,
sum(t1.MTO_TR_TOTAL) as MTO_TR_TOTAL,
sum(t1.NRO_UNI_TR_TOTAL) as NRO_UNI_TR_TOTAL,
sum(t1.MTO_COM_TR) as MTO_COM_TR,
sum(t1.NRO_UNI_COM_TR) as NRO_UNI_COM_TR,
sum(t1.MTO_TDA_TR) as MTO_TDA_TR,
sum(t1.NRO_UNI_TDA_TR) as NRO_UNI_TDA_TR,
sum(t1.MTO_COM_TR_OPEX) as MTO_COM_TR_OPEX,
sum(t1.NRO_UNI_COM_TR_OPEX) as NRO_UNI_COM_TR_OPEX,
sum(t1.MTO_TDA_TR_OPEX) as MTO_TDA_TR_OPEX,
sum(t1.NRO_UNI_TDA_TR_OPEX) as NRO_UNI_TDA_TR_OPEX,
sum(t1.MTO_TR_OPEX) as MTO_TR_OPEX,
sum(t1.NRO_UNI_TR_OPEX) as NRO_UNI_TR_OPEX,
sum(t1.DIST_sku_TOTAL) as DIST_sku_TOTAL,
sum(t1.DIST_sku_OPEX_TOTAL) as DIST_sku_OPEX_TOTAL,
sum(t1.DIST_sku_TDA_TR_TOTAL) as DIST_sku_TDA_TR_TOTAL,
sum(t1.DIST_sku_COM_TR_TOTAL) as DIST_sku_COM_TR_TOTAL,
sum(t1.DIST_sku_TDA_TR_OPEX_TOTAL) as DIST_sku_TDA_TR_OPEX_TOTAL,
sum(t1.DIST_sku_COM_TR_OPEX_TOTAL) as DIST_sku_COM_TR_OPEX_TOTAL,

t2.nota_COM,
t2.nota_TDA,
t2.nota_TOTAL
from &liberia..TOP_60_SKU as t1
left join &liberia..TOP_20_DEPTOS as t2 on (t1.categoria_total=t2.categoria_total and t1.COD_DEPTO=t2.COD_DEPTO and
t1.Periodo=t2.Periodo)
group by
t1.categoria_total,
t1.Periodo,
t1.COD_DEPTO,
t1.DEPARTAMENTO_FIN,

t2.nota_COM,
t2.nota_TDA,
t2.nota_TOTAL
;quit;
*/


PROC SQL noprint;
DELETE FROM &liberia..TOP_60_SKU_PESO
WHERE PERIODO=&PERIODO.
;QUIT;

PROC SQL noprint;
INSERT INTO &liberia..TOP_60_SKU_PESO
select 
t1.categoria_total,
t1.Periodo,
t1.COD_DEPTO,
t1.DEPARTAMENTO_FIN,
sum(t1.MTO_COM) as MTO_COM,
sum(t1.NRO_UNI_COM) as NRO_UNI_COM,
sum(t1.MTO_TDA) as MTO_TDA,
sum(t1.NRO_UNI_TDA) as NRO_UNI_TDA,
sum(t1.MTO_TOTAL) as MTO_TOTAL,
sum(t1.NRO_UNI_TOTAL) as NRO_UNI_TOTAL,
sum(t1.MTO_TR_TOTAL) as MTO_TR_TOTAL,
sum(t1.NRO_UNI_TR_TOTAL) as NRO_UNI_TR_TOTAL,
sum(t1.MTO_COM_TR) as MTO_COM_TR,
sum(t1.NRO_UNI_COM_TR) as NRO_UNI_COM_TR,
sum(t1.MTO_TDA_TR) as MTO_TDA_TR,
sum(t1.NRO_UNI_TDA_TR) as NRO_UNI_TDA_TR,
sum(t1.MTO_COM_TR_OPEX) as MTO_COM_TR_OPEX,
sum(t1.NRO_UNI_COM_TR_OPEX) as NRO_UNI_COM_TR_OPEX,
sum(t1.MTO_TDA_TR_OPEX) as MTO_TDA_TR_OPEX,
sum(t1.NRO_UNI_TDA_TR_OPEX) as NRO_UNI_TDA_TR_OPEX,
sum(t1.MTO_TR_OPEX) as MTO_TR_OPEX,
sum(t1.NRO_UNI_TR_OPEX) as NRO_UNI_TR_OPEX,
sum( t1.DIST_sku_TOTAL) as DIST_sku_TOTAL,
sum( t1.DIST_sku_OPEX_TOTAL) as DIST_sku_OPEX_TOTAL,
sum( t1.DIST_sku_TDA_TR_TOTAL) as DIST_sku_TDA_TR_TOTAL,
sum( t1.DIST_sku_COM_TR_TOTAL) as DIST_sku_COM_TR_TOTAL,
sum( t1.DIST_sku_TDA_TR_OPEX_TOTAL) as DIST_sku_TDA_TR_OPEX_TOTAL,
sum( t1.DIST_sku_COM_TR_OPEX_TOTAL) as DIST_sku_COM_TR_OPEX_TOTAL,

t2.nota_COM,
t2.nota_TDA,
t2.nota_TOTAL
from &liberia..TOP_60_SKU as t1
left join &liberia..TOP_20_DEPTOS as t2 on (t1.categoria_total=t2.categoria_total and t1.COD_DEPTO=t2.COD_DEPTO and
t1.Periodo=t2.Periodo)
where t1.PERIODO=&PERIODO.

group by
t1.categoria_total,
t1.Periodo,
t1.COD_DEPTO,
t1.DEPARTAMENTO_FIN,

t2.nota_COM,
t2.nota_TDA,
t2.nota_TOTAL

;QUIT;

PROC SQL;
CREATE TABLE &liberia..TOP_60_SKU_PESO AS
SELECT *
FROM &liberia..TOP_60_SKU_PESO 
;QUIT;

%MEND TOP_DPTO_SKU;

%TOP_DPTO_SKU(0);
%TOP_DPTO_SKU(1);


/*==================================================================================================*/
/*==================================   EQUIPO DATOS Y PROCESOS    ================================*/
/* VARIABLE TIEMPO   - FIN */
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================   FECHA DEL PROCESO          ================================*/
data _null_;
   execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
   Call symput("fechaeDVN", execDVN) ;
RUN;
   %put &fechaeDVN;

/*==================================   EMAIL CON CASILLA VARIABLE ================================*/
proc sql noprint;                              
   SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
   SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
   SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
   SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
   SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_SPOS_1';
   SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
quit;

%put &=EDP_BI; %put &=DEST_1; %put &=DEST_2; %put &=DEST_3; %put &=DEST_4; %put &=DEST_5;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4","&DEST_5")
CC = ("&DEST_1", "&DEST_2", "&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso TOP_DEPTOS_SKU");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "      Proceso TOP_DEPTOS_SKU, ejecutado con fecha: &fechaeDVN";  
 PUT "      Tablas Disponibles en SAS, librería &libreria.";  
 PUT "         - TOP_20_DEPTOS";
 PUT "         - TOP_60_SKU_PESO";
 PUT "         - TOP_60_SKU";
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

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================       EXPORT_TO_AWS - INI         ===============================*/

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(sas_tnda_top_20_deptos,pre-raw,sasdata,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(sas_tnda_top_20_deptos,&liberia..TOP_20_DEPTOS,pre-raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(sas_tnda_top_60_sku_peso,pre-raw,sasdata,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(sas_tnda_top_60_sku_peso,&liberia..TOP_60_SKU_PESO,pre-raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(sas_tnda_top_60_sku,pre-raw,sasdata,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(sas_tnda_top_60_sku,&liberia..TOP_60_SKU,pre-raw,sasdata,0);

/*==============================       EXPORT_TO_AWS - END         ===============================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
