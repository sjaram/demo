%let libreria=RESULT;



%macro cliente_unico_fin(n,libreria);




DATA _null_;
periodo= input(put(intnx('month',today(),-&N.,'same'),yymmn6. ),$10.);
periodo1= input(put(intnx('month',today(),-&N.-1,'same'),yymmn6. ),$10.);
periodo2= input(put(intnx('month',today(),-&N.-2,'same'),yymmn6. ),$10.);
periodo3= input(put(intnx('month',today(),-&N.-3,'same'),yymmn6. ),$10.);
INI_RSAT= input(put(intnx('month',today(),-&n.,'begin'),yymmdd10. ),$10.) ;
FIN_RSAT= input(put(intnx('month',today(),-&n.,'end'),yymmdd10. ),$10.) ;
Call symput("periodo", periodo);
Call symput("periodo1",periodo1);
Call symput("periodo2", periodo2);
Call symput("periodo3",periodo3);
Call symput("FIN_RSAT", FIN_RSAT);
Call symput("INI_RSAT", INI_RSAT);

RUN;

%put &periodo; /*PERIODO ACTUAL*/
%put &periodo1; /*perido anterior*/
%put &periodo2; /*PERIODO ACTUAL*/
%put &periodo3; /*perido anterior*/
%put &FIN_RSAT;

%put &INI_RSAT;


PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table rutero_contratos  as 
select * 
from connection to ORACLE( 
select  
cast(PEMID_GLS_NRO_DCT_IDE_K as INT)  RUT,
a.cuenta,
a.FECALTA,
a.FECBAJA,
a.producto
from MPDT007 a
INNER JOIN BOPERS_MAE_IDE B 
ON (A.IDENTCLI=PEMID_NRO_INN_IDE)
where  a.FECALTA <=%str(%')&FIN_RSAT.%str(%') 
and (a.FECBAJA='0001-01-01' or a.FECBAJA>=%str(%')&INI_RSAT.%str(%'))
) A
;QUIT;

PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='PMUNOZC' PASSWORD='pmun2102' path ='REPORITF.WORLD' );
create table MPDT499  as 
select * 
from connection to ORACLE( 
select 
CUENTA,
min(PRODORIG) as PRODORIG
from MPDT499
where FECALTA >%str(%')&FIN_RSAT.%str(%') 
group by CUENTA
) A
;QUIT;

proc sql;
create table rutero_contratos2 as
select 
a.RUT,
a.cuenta,
a.FECALTA,
a.FECBAJA,
coalesce(PRODORIG,a.producto) as producto
from rutero_contratos as a 
left join MPDT499 as b
on(a.cuenta=b.cuenta)
;QUIT;


%if (%sysfunc(exist(publicin.SPOS_AUT_&periodo.))) %then %do;
proc sql;
create table spos_TC as 
select 
rut,
sum(case when venta_TARJETA>0 then venta_tarjeta else 0 end ) as monto_positivo,
sum(case when venta_TARJETA<0 then venta_tarjeta else 0 end ) as monto_negativo, 
count(case when venta_TARJETA>0 then rut end ) as trx_positivo,
count(case when venta_TARJETA<0 then rut end ) as trx_negativo
from  publicin.SPOS_AUT_&periodo.
group by rut
;QUIT;
%end;
%else %do;
proc sql;
create table spos_tc
(rut num,
 monto_positivo num,
 monto_negativo num, 
 trx_positivo num,
trx_negativo num)
;QUIT;
%end;

%if (%sysfunc(exist(publicin.SPOS_maestro_&periodo.))) %then %do;
proc sql;
create table spos_maestro as 
select 
rut,
sum(case when venta_TARJETA>0 then venta_tarjeta else 0 end ) as monto_positivo,
sum(case when venta_TARJETA<0 then venta_tarjeta else 0 end ) as monto_negativo, 
count(case when venta_TARJETA>0 then rut end ) as trx_positivo,
count(case when venta_TARJETA<0 then rut end ) as trx_negativo
from  publicin.SPOS_maestro_&periodo.
group by rut
;QUIT;
%end;
%else %do;
proc sql;
create table spos_maestro
(rut num,
 monto_positivo num,
 monto_negativo num, 
 trx_positivo num,
trx_negativo num)
;QUIT;
%end;


%if (%sysfunc(exist(publicin.SPOS_mcd_&periodo.))) %then %do;
proc sql;
create table spos_mcd as 
select 
rut,
sum(case when venta_TARJETA>0 then venta_tarjeta else 0 end ) as monto_positivo,
sum(case when venta_TARJETA<0 then venta_tarjeta else 0 end ) as monto_negativo, 
count(case when venta_TARJETA>0 then rut end ) as trx_positivo,
count(case when venta_TARJETA<0 then rut end ) as trx_negativo
from  publicin.SPOS_mcd_&periodo.
group by rut
;QUIT;
%end;
%else %do;
proc sql;
create table spos_mcd
(rut num,
 monto_positivo num,
 monto_negativo num, 
 trx_positivo num,
trx_negativo num)
;QUIT;
%end;

%if (%sysfunc(exist(publicin.TRX_SEGuros_&periodo.))) %then %do;
proc sql;
create table seg as 
select 
rut,
count(rut) as trx
from  publicin.TRX_SEGuros_&periodo.
where CODCONREC not in ('S201','S083','S170')
and TIPO_SEGURO<>'SEGUROS TARJETA'
group by rut
;QUIT;
%end;
%else %do;
proc sql;
create table seg
(rut num,
trx num)
;QUIT;
%end;

%if (%sysfunc(exist(publicin.SPOS_ctacte_&periodo.))) %then %do;
proc sql;
create table spos_ctacte as 
select 
rut,
sum(case when venta_TARJETA>0 then venta_tarjeta else 0 end ) as monto_positivo,
sum(case when venta_TARJETA<0 then venta_tarjeta else 0 end ) as monto_negativo, 
count(case when venta_TARJETA>0 then rut end ) as trx_positivo,
count(case when venta_TARJETA<0 then rut end ) as trx_negativo
from  publicin.SPOS_ctacte_&periodo.
group by rut
;QUIT;
%end;
%else %do;
proc sql;
create table spos_ctacte
(rut num,
 monto_positivo num,
 monto_negativo num, 
 trx_positivo num,
trx_negativo num)
;QUIT;
%end;

proc sql;
create table spos_TC2 as 
select 
rut,
CASE WHEN trx_positivo-trx_negativo<=0 then 1 else trx_positivo-trx_negativo end  as trx
from spos_tc
where monto_positivo+monto_negativo>0
;QUIT;

proc sql;
create table spos_MAESTRO2 as 
select 
rut,
CASE WHEN trx_positivo-trx_negativo<=0 then 1 else trx_positivo-trx_negativo end  as trx
from spos_MAESTRO
where monto_positivo+monto_negativo>0
;QUIT;

proc sql;
create table spos_mcd2 as 
select 
rut,
CASE WHEN trx_positivo-trx_negativo<=0 then 1 else trx_positivo-trx_negativo end  as trx
from spos_mcd
where monto_positivo+monto_negativo>0
;QUIT;

proc sql;
create table spos_ctacte2 as 
select 
rut,
CASE WHEN trx_positivo-trx_negativo<=0 then 1 else trx_positivo-trx_negativo end  as trx
from spos_ctacte
where monto_positivo+monto_negativo>0
;QUIT;

proc sql;
create table ruteros as 
select 
a.rut,
coalesce(b1.trx,0)+coalesce(b4.trx,0) as trx_TC,
coalesce(b2.trx,0)+coalesce(b3.trx,0)+coalesce(b5.trx,0) as trx_TD

from (select rut from spos_Tc2 union 
select rut from spos_mcd2 union 
select rut from spos_maestro2 union
select rut from seg union 
select rut from spos_ctacte2) as a
left join spos_Tc2 as b1
on(a.rut=b1.rut)
left join spos_mcd2 as b2
on(a.rut=b2.rut)
left join spos_maestro2 as b3
on(a.rut=b3.rut)
left join seg as b4
on(a.rut=b4.rut)
left join spos_ctacte2 as b5 
on(a.rut=b5.rut)
;QUIT;

proc sql;
create table ruteros2 as 
select 
*,
cats(case when trx_TC>0 then 'TC' else '' end ,'+',
case when trx_TD>0 then 'TD' else '' end) as tipo,
 
case when trx_TC+ trx_TD= 1  then '01.1 compra'
when trx_TC+ trx_TD between 2 and 4  then '02.2-4 compras' 
when trx_TC+ trx_TD >=5  then '03.>=5 compras'  end as cant_compras
from ruteros
;QUIT;


%macro spos(per);

%if (%sysfunc(exist(publicin.SPOS_AUT_&per.))) %then %do;
proc sql;
create table spos_TC_&per. as 
select  distinct
rut,
sum(venta_tarjeta) as monto
from  publicin.SPOS_AUT_&per.
group by rut
having calculated monto>0
;QUIT;
%end;
%else %do;
proc sql;
create table spos_tc_&per.
(rut num)
;QUIT;
%end;



%if (%sysfunc(exist(publicin.SPOS_maestro_&per.))) %then %do;
proc sql;
create table spos_maestro_&per. as 
select distinct
rut,
sum(venta_tarjeta) as monto
from  publicin.SPOS_maestro_&per.
group by rut
having calculated monto>0
;QUIT;
%end;
%else %do;
proc sql;
create table spos_maestro_&per.
(rut num)
;QUIT;
%end;


%if (%sysfunc(exist(publicin.SPOS_mcd_&per.))) %then %do;
proc sql;
create table spos_mcd_&per. as 
select distinct
rut,
sum(venta_tarjeta) as monto
from  publicin.SPOS_mcd_&per.
group by rut
having calculated monto>0
;QUIT;
%end;
%else %do;
proc sql;
create table spos_mcd_&per.
(rut num)
;QUIT;
%end;

%if (%sysfunc(exist(publicin.TRX_SEGuros_&per.))) %then %do;
proc sql;
create table seg_&per as 
select distinct 
rut
from  publicin.TRX_SEGuros_&per.
where CODCONREC not in ('S201','S083','S170')
and TIPO_SEGURO<>'SEGUROS TARJETA'
;QUIT;
%end;
%else %do;
proc sql;
create table seg_&per
(rut num)
;QUIT;
%end;

%if (%sysfunc(exist(publicin.SPOS_CTACTE_&per.))) %then %do;
proc sql;
create table spos_CTACTE_&per. as 
select distinct
rut,
sum(venta_tarjeta) as monto
from  publicin.SPOS_CTACTE_&per.
group by rut
having calculated monto>0
;QUIT;
%end;
%else %do;
proc sql;
create table spos_CTACTE_&per.
(rut num)
;QUIT;
%end;
%mend spos;

%spos(&periodo1.);
%spos(&periodo2.);
%spos(&periodo3.);

proc sql;
create table ruteros3 as 
select 
a.*,
case when b.rut is not null then 1 else 0 end as uso_ant,
case when b1.rut is not null then 1 else 0 end as uso_ant1,
case when b2.rut is not null then 1 else 0 end as uso_ant2,
case when b3.rut is not null then 1 else 0 end as uso_ant3


from ruteros2 as a 
left join (select rut from spos_mcd_&periodo1. union  
select rut from spos_mcd_&periodo2. union 
select rut from spos_mcd_&periodo3. union 
select rut from spos_maestro_&periodo1. union 
select rut from spos_maestro_&periodo2. union 
select rut from spos_maestro_&periodo3. union 
select rut from spos_tc_&periodo1. union 
select rut from spos_tc_&periodo2. union 
select rut from spos_tc_&periodo3. union 
select rut from seg_&periodo1. union 
select rut from seg_&periodo2. union 
select rut from seg_&periodo3. union 
select rut from spos_ctacte_&periodo1. union 
select rut from spos_ctacte_&periodo2. union 
select rut from spos_ctacte_&periodo3.
) as b
on(A.rut=b.rut)

left join (select rut from spos_mcd_&periodo1. union   
select rut from spos_maestro_&periodo1. union  
select rut from spos_tc_&periodo1. union
select rut from seg_&periodo1. union 
select rut from spos_ctacte_&periodo1.
) as b1
on(A.rut=b1.rut)

left join (select rut from spos_mcd_&periodo2. union   
select rut from spos_maestro_&periodo2. union  
select rut from spos_tc_&periodo2. union
select rut from seg_&periodo2. union 
select rut from spos_ctacte_&periodo2. ) as b2
on(A.rut=b2.rut)

left join (select rut from spos_mcd_&periodo3. union   
select rut from spos_maestro_&periodo3. union  
select rut from spos_tc_&periodo3.  union
select rut from seg_&periodo3. union 
select rut from spos_ctacte_&periodo3.) as b3
on(A.rut=b3.rut)

;QUIT;

proc sql;
create table captados as 
select distinct 
rut_cliente as rut

from result.capta_salida
where year(fecha)*100+month(fecha) between &periodo2. and &periodo.  
and producto not in ('TR','CUENTA VISTA','CUENTA CORRIENTE')

;QUIT;

proc sql;
create table 
ruteros4 as 
select 
a.*,
case when b.rut is not null then 1 else 0 end as capta_tc
from ruteros3 as a 
left join captados as b
on(a.rut=b.rut)
where a.rut is not null
;QUIT;

%macro spos12(n);

proc sql;
create table spos12 
(periodo num,
rut num)
;QUIT;

%do i=&n.+1 %to 12+&n.;

%put ################ &i. ##################;

DATA _null_;
per_paso= input(put(intnx('month',today(),-&i.,'same'),yymmn6. ),$10.);
Call symput("per_paso", per_paso);
RUN;

%put &per_paso; /*PERIODO ACTUAL*/



%if (%sysfunc(exist(publicin.SPOS_AUT_&per_paso.))) %then %do;
proc sql;
create table spos_TC as 
select  distinct
rut,
sum(venta_tarjeta) as monto
from  publicin.SPOS_AUT_&per_paso.
having calculated monto>0
;QUIT;
%end;
%else %do;
proc sql;
create table spos_tc
(rut num)
;QUIT;
%end;

%if (%sysfunc(exist(publicin.SPOS_maestro_&per_paso.))) %then %do;
proc sql;
create table spos_maestro as 
select distinct
rut,
sum(venta_tarjeta) as monto
from  publicin.SPOS_maestro_&per_paso.
having calculated monto>0
;QUIT;
%end;
%else %do;
proc sql;
create table spos_maestro
(rut num)
;QUIT;
%end;


%if (%sysfunc(exist(publicin.SPOS_mcd_&per_paso.))) %then %do;
proc sql;
create table spos_mcd as 
select distinct
rut,
sum(venta_tarjeta) as monto
from  publicin.SPOS_mcd_&per_paso.
having calculated monto>0
;QUIT;
%end;
%else %do;
proc sql;
create table spos_mcd
(rut num)
;QUIT;
%end;


%if (%sysfunc(exist(publicin.TRX_SEGuros_&per_paso.))) %then %do;
proc sql;
create table seg_paso as 
select distinct 
rut
from  publicin.TRX_SEGuros_&per_paso.
where CODCONREC not in ('S201','S083','S170')
and TIPO_SEGURO<>'SEGUROS TARJETA'
;QUIT;
%end;
%else %do;
proc sql;
create table seg_paso
(rut num)
;QUIT;
%end;

%if (%sysfunc(exist(publicin.spos_ctacte_&per_paso.))) %then %do;
proc sql;
create table spos_ctacte as 
select distinct
rut,
sum(venta_tarjeta) as monto
from  publicin.SPOS_ctacte_&per_paso.
having calculated monto>0
;QUIT;
%end;
%else %do;
proc sql;
create table spos_ctacte
(rut num)
;QUIT;
%end;

proc sql;
insert into spos12
select &per_paso. as periodo,rut
from spos_TC
union
select &per_paso. as periodo,rut
from spos_maestro
union select &per_paso. as periodo,rut
from spos_mcd
union select &per_paso. as periodo,rut
from seg_paso
union select &per_paso. as periodo,rut
from spos_CTACTE
;QUIT;

proc sql;
drop table spos_TC;
drop table spos_maestro;
drop table spos_mcd;
drop table seg_paso;
drop table spos_CTACTE;
;QUIT;

%end;

proc sql;
create table spos12_fin as 
select 
rut,
count(distinct periodo) as max_periodo
from spos12
group by rut
;QUIT;

proc sql;
drop table spos12;
;QUIT;


%mend spos12;
%SPOS12(&n.);

proc sql;
create table 
ruteros5 as 
select 
a.*,
case when b.rut is not null then b.max_periodo else 0 end as frecuencia
from ruteros4 as a 
left join spos12_fin as b
on(a.rut=b.rut)
where a.rut is not null
;QUIT;

proc sql;
create table 
ruteros6 as 
select 
*,
cat(case when max(case when uso_ant1=1 then 1 else 0 end)=1 then 'ANT1' else ' ' end,'+',
case when max(case when uso_ant2=1 then 1 else 0 end)=1 then 'ANT2' else ' ' end,'+',
case when max(case when uso_ant3=1 then 1 else 0 end)=1 then 'ANT3' else ' ' end) as combinatoria
from ruteros5 
group by rut
;QUIT;


proc sql;
create table plastico_rsat as 
select 
a.rut,
a.venta_tarjeta,
b.producto
from publicin.spos_aut_&periodo. as a 
left join rutero_contratos2 as b
on(a.cuenta=b.cuenta)
inner join (select rut,max(fecha) as max from publicin.spos_aut_&periodo.
group by rut) as c
on(a.rut=c.rut) and (a.fecha=c.max)
;QUIT;

proc sql;
create table plastico_rsat2 as 
select 
a.*
from plastico_rsat as a 
inner join (select a.rut,max(a.venta_tarjeta) as max 
from publicin.spos_aut_&periodo. as a 
inner join (select rut,max(fecha) as fecha from publicin.spos_aut_&periodo.
group by rut) as b
on(a.rut=b.rut) and (a.fecha=b.fecha)

group by a.rut
) as b
on(a.rut=b.rut) and (a.venta_tarjeta=b.max)
;QUIT;


proc sql;
create table ruteros7 as 
select distinct 
a.*,
b.producto,
case when c.categoria_gse in ('C1a','C1b','C2') then 'C1C2' else coalesce(c.categoria_gse,'SIN GSE') end as GSE
from ruteros6 as a 
left join plastico_rsat2 as b
on(a.rut=b.rut)
left join rsepulv.gse_corp as c
on(a.rut=c.rut)
;QUIT;


proc sql;
create table plastico_rsat as 
select 
a.rut,
b.producto,
a.monto_recaudado
from ( select * from  publicin.TRX_SEGuros_&periodo.
where CODCONREC not in ('S201','S083','S170')
and TIPO_SEGURO<>'SEGUROS TARJETA') as a 
left join rutero_contratos2 as b
on(a.cuenta=b.cuenta)
inner join (select rut,max(FECPROCES) as max from  publicin.TRX_SEGuros_&periodo.
where CODCONREC not in ('S201','S083','S170')
and TIPO_SEGURO<>'SEGUROS TARJETA'
group by rut) as c
on(a.rut=c.rut) and (a.FECPROCES=c.max)
;QUIT;

proc sql;
create table plastico_rsat2 as 
select 
a.*
from plastico_rsat as a 
inner join (select a.rut,max(a.monto_recaudado) as max 
from (select *  from  publicin.TRX_SEGuros_&periodo.
where CODCONREC not in ('S201','S083','S170')
and TIPO_SEGURO<>'SEGUROS TARJETA') as a 
inner join (select rut,max(FECPROCES) as FECPROCES from  publicin.TRX_SEGuros_&periodo.
where CODCONREC not in ('S201','S083','S170')
and TIPO_SEGURO<>'SEGUROS TARJETA'
group by rut) as b
on(a.rut=b.rut) and (a.FECPROCES=b.FECPROCES)

group by a.rut
) as b
on(a.rut=b.rut) and (a.monto_recaudado=b.max)
;QUIT;

proc sql;
create table ruteros8 as 
select distinct 
a.*,
b.producto as producto2
from ruteros7 as a 
left join plastico_rsat2 as b
on(a.rut=b.rut)

;QUIT;

proc sql;
create table ruteros9 as 
select 
RUT,
trx_TC,
trx_TD,
tipo,
cant_compras,
uso_ant	,
uso_ant1,
uso_ant2,
uso_ant3,
capta_tc,
frecuencia,
combinatoria,
GSE,

max(max(input(producto,best.),	input(producto2,best.))) as PRODUCTO
from ruteros8
group by 
RUT,
trx_TC,
trx_TD,
tipo,
cant_compras,
uso_ant	,
uso_ant1,
uso_ant2,
uso_ant3,
capta_tc,
frecuencia,
combinatoria,
GSE
;QUIT;

PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='PMUNOZC' PASSWORD='pmun2102' path ='REPORITF.WORLD' );
create table MPDT043  as 
select * 
from connection to ORACLE( 
select 
*
from MPDT043
) A
;QUIT;

proc sql;
create table ruteros10 as 
select 
a.*,
b.DESPROD
from ruteros9 as a left join mpdt043 as b
on(a.producto=input(b.producto,best.))
;QUIT;


proc sql;
create table colapso_SPOS as 
select 
&periodo. as periodo,
tipo,
cant_compras,
case when capta_tc>0 then 'CAPTADO'
when capta_tc=0 and uso_ant=1 then 'Recencia <=3'
when capta_tc=0 and uso_ant=0 then 'Recencia >3' end as tipo2,
count(rut) as clientes,
frecuencia,
combinatoria,
case when tipo like '%TC%' then DESPROD  end as TIPO_TARJETA_RSAT,	GSE

from ruteros10
group by tipo,
cant_compras,
calculated tipo2 ,
frecuencia,combinatoria,
TIPO2,
calculated TIPO_TARJETA_RSAT,	GSE
union 
select &periodo. as periodo,
'TOTAL' as tipo,
cant_compras,
case when capta_tc>0 then 'CAPTADO'
when capta_tc=0 and uso_ant=1 then 'Recencia <=3'
when capta_tc=0 and uso_ant=0 then 'Recencia >3' end as tipo2,
count(rut) as clientes,
frecuencia,combinatoria,
case when tipo like '%TC%' then DESPROD  end as TIPO_TARJETA_RSAT,	GSE
from ruteros10
group by 
cant_compras,
calculated tipo2 ,
frecuencia,combinatoria,
TIPO2,
calculated TIPO_TARJETA_RSAT,	GSE

;QUIT;


%if (%sysfunc(exist(publicin.tda_itf_&periodo.))) %then %do;
proc sql;
create table tda_TC as 
select 
rut,
sum(case when capital>0 then capital else 0 end ) as monto_positivo,
sum(case when capital<0 then capital else 0 end ) as monto_negativo, 
count(case when capital>0 then rut end ) as trx_positivo,
count(case when capital<0 then rut end ) as trx_negativo
from  publicin.tda_itf_&periodo.
group by rut
;QUIT;
%end;
%else %do;
proc sql;
create table tda_TC
(rut num,
 monto_positivo num,
 monto_negativo num, 
 trx_positivo num,
trx_negativo num)
;QUIT;
%end;


proc sql;
create table tda_TC2 as 
select 
rut,
CASE WHEN trx_positivo-trx_negativo<=0 then 1 else trx_positivo-trx_negativo end  as trx
from tda_tc
where monto_positivo+monto_negativo>0
;QUIT;

proc sql;
create table ruteros as 
select 
rut,
coalesce(trx,0) as trx_TC

 from tda_Tc2 
;QUIT;

proc sql;
create table ruteros2 as 
select 
*,
 'TC'  as tipo,
 
case when trx_TC= 1  then '01.1 compra'
when trx_TC between 2 and 4  then '02.2-4 compras' 
when trx_TC>=5  then '03.>=5 compras'  end as cant_compras
from ruteros
;QUIT;


%macro tda(per);

%if (%sysfunc(exist(publicin.tda_itf_&per.))) %then %do;
proc sql;
create table tda_TC_&per. as 
select  distinct
rut,
sum(capital) as monto
from  publicin.tda_itf_&per.
group by rut
having calculated monto>0
;QUIT;
%end;
%else %do;
proc sql;
create table tda_tc_&per.
(rut num)
;QUIT;
%end;


%mend tda;

%tda(&periodo1.);
%tda(&periodo2.);
%tda(&periodo3.);

proc sql;
create table ruteros3 as 
select 
a.*,
case when b.rut is not null then 1 else 0 end as uso_ant,
case when b1.rut is not null then 1 else 0 end as uso_ant1,
case when b2.rut is not null then 1 else 0 end as uso_ant2,
case when b3.rut is not null then 1 else 0 end as uso_ant3


from ruteros2 as a 
left join (
select rut from tda_tc_&periodo1. union 
select rut from tda_tc_&periodo2. union 
select rut from tda_tc_&periodo3. 
) as b
on(A.rut=b.rut)

left join  tda_tc_&periodo1.  as b1
on(A.rut=b1.rut)

left join tda_tc_&periodo2. as b2
on(A.rut=b2.rut)

left join tda_tc_&periodo3. as b3
on(A.rut=b3.rut)
;QUIT;

proc sql;
create table captados as 
select distinct 
rut_cliente as rut

from result.capta_salida
where year(fecha)*100+month(fecha) between &periodo2. and &periodo.  
and producto not in ('TR','CUENTA VISTA','CUENTA CORRIENTE')

;QUIT;

proc sql;
create table 
ruteros4 as 
select 
a.*,
case when b.rut is not null then 1 else 0 end as capta_tc
from ruteros3 as a 
left join captados as b
on(a.rut=b.rut)
where a.rut is not null
;QUIT;

%macro tda12(n);

proc sql;
create table tda12 
(periodo num,
rut num)
;QUIT;

%do i=&n.+1 %to 12+&n.;

%put ################ &i. ##################;

DATA _null_;
per_paso= input(put(intnx('month',today(),-&i.,'same'),yymmn6. ),$10.);
Call symput("per_paso", per_paso);
RUN;

%put &per_paso; /*PERIODO ACTUAL*/



%if (%sysfunc(exist(publicin.tda_itf_&per_paso.))) %then %do;
proc sql;
create table tda_TC as 
select  distinct
rut,
sum(capital) as monto
from  publicin.tda_itf_&per_paso.
having calculated monto>0
;QUIT;
%end;
%else %do;
proc sql;
create table tda_TC
(rut num)
;QUIT;
%end;


proc sql;
insert into tda12
select &per_paso. as periodo,rut
from tda_TC
;QUIT;

proc sql;
drop table tda_TC;
;QUIT;

%end;

proc sql;
create table tda12_fin as 
select 
rut,
count(distinct periodo) as max_periodo
from tda12
group by rut
;QUIT;

proc sql;
drop table tda12;
;QUIT;


%mend tda12;
%tda12(&n.);

proc sql;
create table 
ruteros5 as 
select 
a.*,
case when b.rut is not null then b.max_periodo else 0 end as frecuencia
from ruteros4 as a 
left join tda12_fin as b
on(a.rut=b.rut)
where a.rut is not null
;QUIT;

proc sql;
create table 
ruteros6 as 
select 
*,
case when max(case when uso_ant1=1 then 1 else 0 end)=1 then 'ANT1' else ' ' end||'+'||
case when max(case when uso_ant2=1 then 1 else 0 end)=1 then 'ANT2' else ' ' end||'+'||
case when max(case when uso_ant3=1 then 1 else 0 end)=1 then 'ANT3' else ' ' end as combinatoria
from ruteros5 
group by rut
;QUIT;


proc sql;
create table plastico_rsat as 
select 
a.rut,
a.capital,
b.producto
from publicin.tda_itf_&periodo. as a 
left join rutero_contratos2 as b
on(a.cuenta=b.cuenta)
inner join (select rut,max(fecha) as max from publicin.tda_itf_&periodo.
group by rut) as c
on(a.rut=c.rut) and (a.fecha=c.max)
;QUIT;

proc sql;
create table plastico_rsat2 as 
select 
a.*
from plastico_rsat as a 
inner join (select a.rut,max(a.capital) as max 
from publicin.tda_itf_&periodo. as a 
inner join (select rut,max(fecha) as fecha from publicin.tda_itf_&periodo.
group by rut) as b
on(a.rut=b.rut) and (a.fecha=b.fecha)

group by a.rut
) as b
on(a.rut=b.rut) and (a.capital=b.max)
;QUIT;


proc sql;
create table ruteros7 as 
select distinct 
a.*,
b.producto,
case when c.categoria_gse in ('C1a','C1b','C2') then 'C1C2' else coalesce(c.categoria_gse,'SIN GSE') end as GSE
from ruteros6 as a 
left join plastico_rsat2 as b
on(a.rut=b.rut)
left join rsepulv.gse_corp as c
on(a.rut=c.rut)
;QUIT;



proc sql;
create table ruteros8 as 
select 
a.*,
b.DESPROD
from ruteros7 as a left join mpdt043 as b
on(input(a.producto,best.)=input(b.producto,best.))
;QUIT;



proc sql;
create table colapso_TDA as 
select 
&periodo. as periodo,
tipo,
cant_compras,
case when capta_tc>0 then 'CAPTADO'
when capta_tc=0 and uso_ant=1 then 'Recencia <=3'
when capta_tc=0 and uso_ant=0 then 'Recencia >3' end as tipo2,
count(rut) as clientes,
frecuencia,
combinatoria,
DESPROD as TIPO_TARJETA_RSAT,
GSE

from ruteros8
group by tipo,
cant_compras,
calculated tipo2 ,
frecuencia,combinatoria,
TIPO2,
DESPROD,
GSE

;QUIT;


%if (%sysfunc(exist(&libreria..CLIENTE_UNICO_MAGDA))) %then %do;

%end;
%else %do;
proc sql;
create table &libreria..CLIENTE_UNICO_MAGDA
(negocio char(20),
periodo num,
tipo char(20),
cant_compras char(20),
tipo2 char(20),
clientes num,
frecuencia num,
combinatoria char(30),
TIPO_TARJETA_RSAT char(30),
GSE char(30)
)
;QUIT;
%end;


proc sql;
delete * from &libreria..CLIENTE_UNICO_MAGDA
where periodo=&periodo.
;QUIT;

proc sql;
insert into &libreria..CLIENTE_UNICO_MAGDA
select 'SPOS' as NEGOCIO, 
*
from colapso_SPOS
outer union corr 
select 'TDA' as NEGOCIO ,
*
from colapso_TDA 
;QUIT;

proc sql;
create table &libreria..CLIENTE_UNICO_MAGDA as 
select * 
from &libreria..CLIENTE_UNICO_MAGDA
;QUIT;

proc datasets library=WORK kill noprint;
run;
quit;


%mend cliente_unico_fin;


%cliente_unico_fin(0,&libreria.);
%cliente_unico_fin(1,&libreria.);

%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;
/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================        EXPORT_TO_AWS - INI          ===============================*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(spos_cliente_unico_3m,raw,oracloud,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(spos_cliente_unico_3m,&libreria..CLIENTE_UNICO_MAGDA,raw,oracloud,0);

/*==============================        EXPORT_TO_AWS - END          ===============================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/



/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';

		SELECT EMAIL into :DEST_4
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_2","&DEST_4",
'mbentjerodts@bancoripley.com','bschmidtm@bancoripley.com','crachondode@bancoripley.com',
'bmartinezg@bancoripley.com'
)
SUBJECT="MAIL_AUTOM: PROCESO CLIENTE UNICO 3M %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso PROCESO CLIENTE UNICO 3M, ejecutado.";  
 put "Para visualizar Dashboard utilizar el siguiente link:"; 
 put "https://tableau1.bancoripley.cl/#/site/BI_Lab/views/Clienteunico3M/CLIENTE3M";
 put ;
 put 'Vers.1'; 
 put ; 
 put ; 
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;




