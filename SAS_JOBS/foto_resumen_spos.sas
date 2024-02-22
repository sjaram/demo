options validvarname=any;
proc sql;
create table credito 
(
periodo num,
'Monto Total'n num, 
Trx  num, 
'Trx Prom por Cliente'n  num, 
'Ticket Prom'n  num, 
'Clientes Únicos'n  num, 
'Cliente Unico 5 trx'n num,
'Gasto Prom'n  num, 
'Vta Cuotas'n  num, 
'% Vta Cuotas'n  num, 
'Tasa Vta Cuotas'n  num, 
'Plazo Vta Cuotas'n  num, 
'Vta Fin'n  num, 
'% Vta Fin'n  num, 
'Tasa Vta Fin'n  num, 
'Plazo Vta Fin'n  num)
;QUIT;

proc sql;
create table credito_TC 
(
periodo num,
'Monto Total'n num, 
Trx  num, 
'Trx Prom por Cliente'n  num, 
'Ticket Prom'n  num, 
'Clientes Únicos'n  num, 
'Cliente Unico 5 trx'n num,
'Gasto Prom'n  num, 
'Vta Cuotas'n  num, 
'% Vta Cuotas'n  num, 
'Tasa Vta Cuotas'n  num, 
'Plazo Vta Cuotas'n  num, 
'Vta Fin'n  num, 
'% Vta Fin'n  num, 
'Tasa Vta Fin'n  num, 
'Plazo Vta Fin'n  num)
;QUIT;

proc sql;
create table debito 
(
periodo num,
'Monto Total'n num, 
Trx  num, 
'Trx Prom por Cliente'n  num, 
'Ticket Prom'n  num, 
'Clientes Únicos'n  num, 
'Cliente Unico 5 trx'n num,
'Gasto Prom'n  num)
;QUIT;

proc sql;
create table CTACTE 
(
periodo num,
'Monto Total'n num, 
Trx  num, 
'Trx Prom por Cliente'n  num, 
'Ticket Prom'n  num, 
'Clientes Únicos'n  num, 
'Cliente Unico 5 trx'n num,
'Gasto Prom'n  num)
;QUIT;

%macro foto_resumen(n);



DATA _NULL_;
periodo_actual = put(intnx('month',today(),-&n,'end'),yymmn6.);
Call symput("periodo_actual",periodo_actual);
run;

%put &periodo_actual;

proc sql noprint;
create table paso as 
select 
rut,
count(case when monto>0 then rut end)-count(case when monto<0 then rut end) as trx,
sum(monto) as monto
from (select rut,
fecha,
venta_tarjeta as monto 
from publicin.spos_aut_&periodo_actual.
outer union corr 
select rut,
input(compress(FECPROCES,'-'),best.) as fecha,
MONTO_RECAUDADO as monto
from publicin.TRX_SEGuros_&periodo_actual.
where CODCONREC not in ('S201','S083','S170')
and TIPO_SEGURO<>'SEGUROS TARJETA'
and (rut<>17519002 and monto_recaudado<>476454338))
where fecha-floor(fecha/100)*100<day(intnx("day",today(),-1))
group by rut 
;QUIT;

proc sql noprint;
select
count(case when trx>=5 and monto>0 then rut end) as trx_5_tc
into: trx_5_tc
from paso
;QUIT;

proc sql noprint;
select
count(distinct case when monto>0 then rut end) as CLIENTE_UNICO
into: CLIENTE_UNICO
from paso
;QUIT;


proc sql;
insert into credito  
select 
&periodo_actual. as periodo,
floor(sum(venta_tarjeta)/1000000)*1 as 'Monto Total'n,
(count(case when venta_tarjeta>0 then rut end)-count(case when venta_tarjeta<0 then rut end))*1 as Trx,
(count(case when venta_tarjeta>0 then rut end)-count(case when venta_tarjeta<0 then rut end))/count(distinct rut) format = 21.1 as 'Trx Prom por Cliente'n,
floor(sum(venta_tarjeta)/(count(case when venta_tarjeta>0 then rut end)-count(case when venta_tarjeta<0 then rut end)))*1 as 'Ticket Prom'n,
&CLIENTE_UNICO.*1 as 'Clientes Únicos'n,
&trx_5_tc. as 'Cliente Unico 5 trx'n ,
floor(sum(venta_tarjeta)/count(distinct rut))*1  as 'Gasto Prom'n,
floor(sum(case when TOTCUOTAS>=2  then venta_tarjeta else 0 end)/1000000)*1 as 'Vta Cuotas'n,
sum(case when TOTCUOTAS>=2  then venta_tarjeta else 0 end)/sum(case when tipo='SPOS' then venta_tarjeta end ) format = 21.2 as  '% Vta Cuotas'n,
sum(case when  TOTCUOTAS>=2  then venta_tarjeta*PORINT else 0 end )
/sum(case when  TOTCUOTAS>=2  then venta_tarjeta else 0 end) as 'Tasa Vta Cuotas'n,
sum(case when  TOTCUOTAS>=2  then venta_tarjeta*TOTCUOTAS else 0 end  )/
sum(case when  TOTCUOTAS>=2  then venta_tarjeta else 0 end ) as 'Plazo Vta Cuotas'n,
floor(sum(case when TOTCUOTAS>=2 and PORINT>0 then venta_tarjeta else 0 end)/1000000)*1 as 'Vta Fin'n,
sum(case when TOTCUOTAS>=2  and PORINT>0 then venta_tarjeta else 0 end)/sum(case when tipo='SPOS' then venta_tarjeta end ) format = 21.2 as '% Vta Fin'n,

sum(case when  TOTCUOTAS>=2  and PORINT>0 then venta_tarjeta*PORINT else 0 end )/
sum(case when  TOTCUOTAS>=2  and PORINT>0 then venta_tarjeta else 0 end) as 'Tasa Vta Fin'n,
sum(case when  TOTCUOTAS>=2  and PORINT>0 then venta_tarjeta*TOTCUOTAS else 0 end  )/
sum(case when  TOTCUOTAS>=2  and PORINT>0 then venta_tarjeta else 0 end) as 'Plazo Vta Fin'n

from (select 
'SPOS' as tipo,
rut,
fecha,
venta_tarjeta,
totcuotas,
PORINT
from publicin.spos_aut_&periodo_actual.
outer union corr 
select 'SEGUROS' as tipo,rut,
input(compress(FECPROCES,'-'),best.) as fecha,
MONTO_RECAUDADO as venta_tarjeta,
0 as totcuotas,
0 as PORINT
from publicin.TRX_SEGuros_&periodo_actual.
where CODCONREC not in ('S201','S083','S170')
and TIPO_SEGURO<>'SEGUROS TARJETA'
and (rut<>17519002 and monto_recaudado<>476454338)
)
where fecha-floor(fecha/100)*100<day(intnx("day",today(),-1))

;QUIT;




%if (%sysfunc(exist(publicin.spos_mcd_&periodo_actual.))) %then %do;
PROC SQL NOERRORSTOP ;
create table spos_mcd as 
SELECT 
rut,
venta_tarjeta,
fecha
FROM publicin.spos_mcd_&periodo_actual.
where fecha-floor(fecha/100)*100<day(intnx("day",today(),-1))
;RUN; 
%end;
%else %do;
PROC  SQL;
CREATE TABLE spos_mcd (
rut num,
venta_tarjeta num,
fecha num
)
;RUN;
%end;


%if (%sysfunc(exist(publicin.spos_maestro_&periodo_actual.))) %then %do;
PROC SQL NOERRORSTOP ;
create table spos_maestro as 
SELECT 
rut,
venta_tarjeta,
fecha
FROM publicin.spos_maestro_&periodo_actual.
where fecha-floor(fecha/100)*100<day(intnx("day",today(),-1))
;RUN; 
%end;
%else %do;
PROC  SQL;
CREATE TABLE spos_maestro (
rut num,
venta_tarjeta num,
fecha num
)
;RUN;
%end;


%if (%sysfunc(exist(publicin.spos_CTACTE_&periodo_actual.))) %then %do;
PROC SQL NOERRORSTOP ;
create table spos_CTACTE as 
SELECT 
rut,
venta_tarjeta,
fecha
FROM publicin.spos_CTACTE_&periodo_actual.
where fecha-floor(fecha/100)*100<day(intnx("day",today(),-1))
;RUN; 
%end;
%else %do;
PROC  SQL;
CREATE TABLE spos_CTACTE (
rut num,
venta_tarjeta num,
fecha num
)
;RUN;
%end;



proc sql noprint;
create table paso as 
select 
rut,
count(rut) as trx
from (select * from spos_maestro
outer union corr
select * from spos_mcd
outer union corr
select * from spos_CTACTE)
where rut is not null
group by rut 
;QUIT;

proc sql noprint;
select
count(case when trx>=5 then rut end) as trx_5_td
into: trx_5_td
from paso
;QUIT;




proc sql;
insert into  debito  
select 
&periodo_actual. as periodo,
floor(sum(venta_tarjeta)/1000000)*1 as 'Monto Total'n,
count(rut)*1 as Trx,
count(rut)/count(distinct rut) format = 21.1 as 'Trx Prom por Cliente'n,
floor(sum(venta_tarjeta)/count(rut))*1 as 'Ticket Prom'n,
count(distinct rut)*1 as 'Clientes Únicos'n,
&trx_5_td. as 'Cliente Unico 5 trx'n ,
floor(sum(venta_tarjeta)/count(distinct rut))  as 'Gasto Prom'n
from (select * from spos_maestro
outer union corr
select * from spos_mcd
outer union corr
select * from spos_CTACTE)
where rut is not null
;QUIT;

proc sql noprint;
create table paso as 
select 
rut,
count(rut) as trx
from spos_CTACTE
where rut is not null
group by rut 
;QUIT;

proc sql noprint;
select
count(case when trx>=5 then rut end) as trx_5_CTACTE
into: trx_5_CTACTE
from paso
;QUIT;


proc sql;
insert into  CTACTE  
select 
&periodo_actual. as periodo,
floor(sum(venta_tarjeta)/1000000)*1 as 'Monto Total'n,
count(rut)*1 as Trx,
count(rut)/count(distinct rut) format = 21.1 as 'Trx Prom por Cliente'n,
floor(sum(venta_tarjeta)/count(rut))*1 as 'Ticket Prom'n,
count(distinct rut)*1 as 'Clientes Únicos'n,
&trx_5_CTACTE. as 'Cliente Unico 5 trx'n ,
floor(sum(venta_tarjeta)/count(distinct rut))  as 'Gasto Prom'n
from spos_CTACTE
where rut is not null
;QUIT;



proc sql noprint;
create table paso as 
select 
rut,
count(case when capital+pie>0 then rut end)-count(case when capital+pie<0 then rut end) as trx,
sum(capital+pie) as monto
from  publicin.tda_itf_&periodo_actual.
where day(fecha)<day(intnx("day",today(),-1))
group by rut
;QUIT;

proc sql noprint;
select
count(case when trx>=5 and monto>0 then rut end) as trx_5_tc2
into: trx_5_tc2
from paso
;QUIT;

proc sql noprint;
select
count(distinct case when monto>0 then rut end) as CLIENTE_UNICO
into: CLIENTE_UNICO
from paso
;QUIT;


proc sql;
insert into credito_tc  
select 
&periodo_actual. as periodo,
floor(sum(venta_tarjeta)/1000000)*1 as 'Monto Total'n,
(count(case when venta_tarjeta>0 then rut end)-count(case when venta_tarjeta<0 then rut end))*1 as Trx,
(count(case when venta_tarjeta>0 then rut end)-count(case when venta_tarjeta<0 then rut end))/count(distinct rut) format = 21.1 as 'Trx Prom por Cliente'n,
floor(sum(venta_tarjeta)/(count(case when venta_tarjeta>0 then rut end)-count(case when venta_tarjeta<0 then rut end)))*1 as 'Ticket Prom'n,
&CLIENTE_UNICO.*1 as 'Clientes Únicos'n,
&trx_5_tc2. as 'Cliente Unico 5 trx'n ,
floor(sum(venta_tarjeta)/count(distinct rut))*1  as 'Gasto Prom'n,
floor(sum(case when TOTCUOTAS>=3  then venta_tarjeta else 0 end)/1000000)*1 as 'Vta Cuotas'n,
sum(case when TOTCUOTAS>=3  then venta_tarjeta else 0 end)/sum( venta_tarjeta  ) format = 21.2 as  '% Vta Cuotas'n,
sum(case when  TOTCUOTAS>=3  then venta_tarjeta*PORINT else 0 end )
/sum(case when  TOTCUOTAS>=3  then venta_tarjeta else 0 end) as 'Tasa Vta Cuotas'n,
sum(case when  TOTCUOTAS>=3  then venta_tarjeta*TOTCUOTAS else 0 end  )/
sum(case when  TOTCUOTAS>=3  then venta_tarjeta else 0 end ) as 'Plazo Vta Cuotas'n,
floor(sum(case when TOTCUOTAS>=3 and PORINT>0.001 then venta_tarjeta else 0 end)/1000000)*1 as 'Vta Fin'n,
sum(case when TOTCUOTAS>=3  and PORINT>0.001 then venta_tarjeta else 0 end)/sum(venta_tarjeta  ) format = 21.2 as '% Vta Fin'n,

sum(case when  TOTCUOTAS>=3  and PORINT>0.001 then venta_tarjeta*PORINT else 0 end )/
sum(case when  TOTCUOTAS>=3  and PORINT>0.001 then venta_tarjeta else 0 end) as 'Tasa Vta Fin'n,
sum(case when  TOTCUOTAS>=3  and PORINT>0.001 then venta_tarjeta*TOTCUOTAS else 0 end  )/
sum(case when  TOTCUOTAS>=3  and PORINT>0.001 then venta_tarjeta else 0 end) as 'Plazo Vta Fin'n

from (select 
rut,
fecha,
capital+pie as venta_tarjeta,
cuotas as totcuotas,
tasa as PORINT
from publicin.tda_itf_&periodo_actual.
)
where day(fecha)<day(intnx("day",today(),-1))

;QUIT;


proc sql;
drop table spos_maestro;
drop table spos_mcd;
drop table paso;
drop table spos_CTACTE;
;QUIT;

%mend foto_resumen;

%foto_resumen(0);
%foto_resumen(1);
%foto_resumen(12);
%foto_resumen(24);
%foto_resumen(36);
%foto_resumen(48);

PROC TRANSPOSE DATA=WORK.credito
NAME=PERIODO
OUT=WORK.credito2 ;
id periodo;	
;
	VAR  
periodo
'Monto Total'n  
Trx  
'Trx Prom por Cliente'n  
'Ticket Prom'n  
'Clientes Únicos'n 
'Cliente Unico 5 trx'n 
'Gasto Prom'n  
'Vta Cuotas'n  
'% Vta Cuotas'n  
'Tasa Vta Cuotas'n   
'Plazo Vta Cuotas'n 
'Vta Fin'n   
'% Vta Fin'n   
'Tasa Vta Fin'n  
'Plazo Vta Fin'n  ;

RUN; QUIT;

proC TRANSPOSE DATA=WORK.credito_tc
NAME=PERIODO
OUT=WORK.credito_tc2 ;
id periodo;	
;
	VAR  
periodo
'Monto Total'n  
Trx  
'Trx Prom por Cliente'n  
'Ticket Prom'n  
'Clientes Únicos'n 
'Cliente Unico 5 trx'n 
'Gasto Prom'n  
'Vta Cuotas'n  
'% Vta Cuotas'n  
'Tasa Vta Cuotas'n   
'Plazo Vta Cuotas'n 
'Vta Fin'n   
'% Vta Fin'n   
'Tasa Vta Fin'n  
'Plazo Vta Fin'n  ;

RUN; QUIT;

PROC TRANSPOSE DATA=WORK.DEBITO
NAME=PERIODO
OUT=WORK.DEBITO2 ;
id periodo;	
;
	VAR  
periodo
'Monto Total'n  
Trx  
'Trx Prom por Cliente'n  
'Ticket Prom'n  
'Clientes Únicos'n 
'Cliente Unico 5 trx'n 
'Gasto Prom'n   ;
RUN; QUIT;


PROC TRANSPOSE DATA=WORK.CTACTE
NAME=PERIODO
OUT=WORK.CTACTE2 ;
id periodo;	
;
	VAR  
periodo
'Monto Total'n  
Trx  
'Trx Prom por Cliente'n  
'Ticket Prom'n  
'Clientes Únicos'n 
'Cliente Unico 5 trx'n 
'Gasto Prom'n   ;
RUN; QUIT;


proc sql;
create table credito3 as 
select monotonic() as ind,
*
from credito2
where calculated ind>1
;QUIT;

proc sql;
create table credito_tc3 as 
select monotonic() as ind,
*
from credito_tc2
where calculated ind>1
;QUIT;

proc sql;
create table debito3 as 
select monotonic() as ind,
*
from debito2
where calculated ind>1
;QUIT;

proc sql;
create table CTACTE3 as 
select monotonic() as ind,
*
from CTACTE2
where calculated ind>1
;QUIT;


DATA _NULL_;
periodo_actual = put(intnx('month',today(),0,'end'),yymmn6.);
fecha = put(intnx('day',today(),-1,'end'),ddmmyy10.);
periodo_ant = put(intnx('month',today(),-1,'end'),yymmn6.);
periodo_12 = put(intnx('month',today(),-12,'end'),yymmn6.);
periodo_24 = put(intnx('month',today(),-24,'end'),yymmn6.);
periodo_36 = put(intnx('month',today(),-36,'end'),yymmn6.);
periodo_48 = put(intnx('month',today(),-48,'end'),yymmn6.);
Call symput("periodo_actual",periodo_actual);
Call symput("periodo_ant",periodo_ant);
Call symput("periodo_12",periodo_12);
Call symput("periodo_24",periodo_24);
Call symput("periodo_36",periodo_36);
Call symput("periodo_48",periodo_48);
Call symput("fecha",fecha);
run;



proc sql;
create table credito4 as 
select 
PERIODO	,
case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_actual."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_actual."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_actual."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_actual."n,best.),1,4),"%")
else substr(put("&periodo_actual."n,best.),1,4) end as "&periodo_actual."n,

case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_ant."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_ant."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_ant."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_ant."n,best.),1,4),"%")
else substr(put("&periodo_ant."n,best.),1,4) end as "&periodo_ant."n,


case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_12."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_12."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_12."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_12."n,best.),1,4),"%")
else substr(put("&periodo_12."n,best.),1,4) end as "&periodo_12."n,

case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_24."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_24."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_24."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_24."n,best.),1,4),"%")
else substr(put("&periodo_24."n,best.),1,4) end as "&periodo_24."n,

case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_36."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_36."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_36."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_36."n,best.),1,4),"%")
else substr(put("&periodo_36."n,best.),1,4) end as "&periodo_36."n,

case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_48."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_48."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_48."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_48."n,best.),1,4),"%")
else substr(put("&periodo_48."n,best.),1,4) end as "&periodo_48."n,

put("&periodo_actual."n/"&periodo_ant."n-1,percentn.) as  'Var vs Mes Ant'n,
put("&periodo_actual."n/"&periodo_12."n-1,percentn.)as  "Var vs &periodo_12."n,
put("&periodo_actual."n/"&periodo_24."n-1,percentn.)as  "Var vs &periodo_24."n,
put("&periodo_actual."n/"&periodo_36."n-1,percentn.)as  "Var vs &periodo_36."n,
put("&periodo_actual."n/"&periodo_48."n-1,percentn.) as  "Var vs &periodo_48"n 
from credito3
;QUIT;

proc sql;
create table credito_TC4 as 
select 
PERIODO	,
case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_actual."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_actual."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_actual."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_actual."n,best.),1,4),"%")
else substr(put("&periodo_actual."n,best.),1,4) end as "&periodo_actual."n,

case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_ant."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_ant."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_ant."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_ant."n,best.),1,4),"%")
else substr(put("&periodo_ant."n,best.),1,4) end as "&periodo_ant."n,


case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_12."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_12."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_12."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_12."n,best.),1,4),"%")
else substr(put("&periodo_12."n,best.),1,4) end as "&periodo_12."n,

case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_24."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_24."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_24."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_24."n,best.),1,4),"%")
else substr(put("&periodo_24."n,best.),1,4) end as "&periodo_24."n,

case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_36."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_36."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_36."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_36."n,best.),1,4),"%")
else substr(put("&periodo_36."n,best.),1,4) end as "&periodo_36."n,

case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_48."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_48."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_48."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_48."n,best.),1,4),"%")
else substr(put("&periodo_48."n,best.),1,4) end as "&periodo_48."n,

put("&periodo_actual."n/"&periodo_ant."n-1,percentn.) as  'Var vs Mes Ant'n,
put("&periodo_actual."n/"&periodo_12."n-1,percentn.)as  "Var vs &periodo_12."n,
put("&periodo_actual."n/"&periodo_24."n-1,percentn.)as  "Var vs &periodo_24."n,
put("&periodo_actual."n/"&periodo_36."n-1,percentn.)as  "Var vs &periodo_36."n,
put("&periodo_actual."n/"&periodo_48."n-1,percentn.) as  "Var vs &periodo_48"n 
from credito_TC3
;QUIT;


proc sql;
create table debito4 as 
select 
PERIODO	,
case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_actual."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_actual."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_actual."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_actual."n,best.),1,4),"%")
else substr(put("&periodo_actual."n,best.),1,4) end as "&periodo_actual."n,

case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_ant."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_ant."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_ant."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_ant."n,best.),1,4),"%")
else substr(put("&periodo_ant."n,best.),1,4) end as "&periodo_ant."n,


case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_12."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_12."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_12."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_12."n,best.),1,4),"%")
else substr(put("&periodo_12."n,best.),1,4) end as "&periodo_12."n,

case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_24."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_24."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_24."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_24."n,best.),1,4),"%")
else substr(put("&periodo_12."n,best.),1,4) end as "&periodo_24."n,

case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_36."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_36."n,21.2)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_36."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_36."n,best.),1,4),"%")
else substr(put("&periodo_36."n,best.),1,4) end as "&periodo_36."n,

case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_48."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_48."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_48."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_48."n,best.),1,4),"%")
else substr(put("&periodo_12."n,best.),1,4) end as "&periodo_48."n,

put("&periodo_actual."n/"&periodo_ant."n-1,percentn.) as  'Var vs Mes Ant'n,
put("&periodo_actual."n/"&periodo_12."n-1,percentn.)as  "Var vs &periodo_12."n,
put("&periodo_actual."n/"&periodo_24."n-1,percentn.)as  "Var vs &periodo_24."n,
put("&periodo_actual."n/"&periodo_36."n-1,percentn.)as  "Var vs &periodo_36."n,
put("&periodo_actual."n/"&periodo_48."n-1,percentn.) as  "Var vs &periodo_48"n 
from debito3
;QUIT;



proc sql;
create table CTACTE4 as 
select 
PERIODO	,
case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_actual."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_actual."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_actual."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_actual."n,best.),1,4),"%")
else substr(put("&periodo_actual."n,best.),1,4) end as "&periodo_actual."n,

case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_ant."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_ant."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_ant."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_ant."n,best.),1,4),"%")
else substr(put("&periodo_ant."n,best.),1,4) end as "&periodo_ant."n,


case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_12."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_12."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_12."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_12."n,best.),1,4),"%")
else substr(put("&periodo_12."n,best.),1,4) end as "&periodo_12."n,

case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_24."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_24."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_24."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_24."n,best.),1,4),"%")
else substr(put("&periodo_24."n,best.),1,4) end as "&periodo_24."n,

case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_36."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_36."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_36."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_36."n,best.),1,4),"%")
else substr(put("&periodo_36."n,best.),1,4) end as "&periodo_36."n,

case when periodo in 
('Monto Total',
'Ticket Prom',
'Gasto Prom','Vta Cuotas','Vta Fin') then put("&periodo_48."n,COMMAX20.)
when periodo in ('% Vta Cuotas','% Vta Fin') then put("&periodo_48."n,percentn.)
when PERIODO in ('Trx','Clientes Únicos','Cliente Unico 5 trx') then put("&periodo_48."n,COMMAX20.)
when periodo in ('Tasa Vta Cuotas','Tasa Vta Fin') then cat(substr(put("&periodo_48."n,best.),1,4),"%")
else substr(put("&periodo_48."n,best.),1,4) end as "&periodo_48."n,

put("&periodo_actual."n/"&periodo_ant."n-1,percentn.) as  'Var vs Mes Ant'n,
put("&periodo_actual."n/"&periodo_12."n-1,percentn.)as  "Var vs &periodo_12."n,
put("&periodo_actual."n/"&periodo_24."n-1,percentn.)as  "Var vs &periodo_24."n,
put("&periodo_actual."n/"&periodo_36."n-1,percentn.)as  "Var vs &periodo_36."n,
put("&periodo_actual."n/"&periodo_48."n-1,percentn.) as  "Var vs &periodo_48"n 
from CTACTE3
;QUIT;

proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

		SELECT EMAIL into :DEST_4
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_4;



FILENAME output EMAIL
SUBJECT= "MAIL_AUTOM: Resumen Facturación &fecha."
FROM= ("&EDP_BI")
TO = ("mbentjerodts@bancoripley.com","bschmidtm@bancoripley.com","fmunozh@bancoripley.com"
"sfaz@bancoripley.com","cruizs@bancoripley.com","caimoneb@bancoripley.com",
"jsantamaria@bancoripley.com",
"adiazse@bancoripley.com")
CC = ("&DEST_1","&DEST_4","pmunozc@bancoripley.com","gherrerab@bancoripley.com","iplazam@bancoripley.com",
"kgonzalezi@bancoripley.com","pfuenzalidam@bancoripley.com","gvallejosa@bancoripley.com")
CT= "text/html" /* Required for HTML output */ ;
%put "Información de debito puede tener hasta 4 días de desfase por data de Maestro.";
ODS LISTING CLOSE;
ODS HTML BODY=output STYLE=sasweb;
TITLE JUSTIFY=left
"Resumen Spos Credito+Seguros Open Market, detalle al &fecha.";
PROC PRINT DATA=WORK.credito4 NOOBS;
RUN;
TITLE JUSTIFY=left
"Resumen Spos Debito+Cuenta Corriente, detalle al &fecha.";
PROC PRINT DATA=WORK.debito4 NOOBS;
RUN;

TITLE JUSTIFY=left
"Resumen Spos Cuenta Corriente, detalle al &fecha.";
PROC PRINT DATA=WORK.ctacte4 NOOBS;
RUN;

TITLE JUSTIFY=left
"Resumen Tda, detalle al &fecha.";
PROC PRINT DATA=WORK.credito_Tc4 NOOBS;
RUN;



ODS HTML CLOSE;
ODS LISTING;

proc datasets library=WORK kill noprint;
run;
quit;
