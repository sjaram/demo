%LET libreria=kgonzale;


%macro segcampvta_spos(libreria);

PROC SQL outobs=1 noprint  ;   
select max(Periodo_Campana) as Periodo_Proceso /*Sacar Ultimo periodo disponible en esa tabla*/
into :Periodo_Proceso 
from result.CodCom_Camps_SPOS /*Base de Comercios que manda SPOS en excel (asegurarse de que este buena: sin blancos, sin duplicados, otros)*/
;QUIT;


%let periodo_proceso=&periodo_proceso;


/*::::::::::::::::::::::::::*/
%let Periodo=&Periodo_Proceso; /*periodo de campañas a considerar de archivo de campañas*/
%let ventana_tiempo=12; /*ventana de tiempo hacia atras para ver*/

/*::::::::::::::::::::::::::*/



%put==========================================================================================;
%put [01] Identificar Comercios en Campaña;
%put==========================================================================================;


proc sql;

create table work.CodCom_Camps_SPOS_Periodo as 
select distinct
Codigo_Comercio,
max(Marca_Campana) as Marca_Campana,
MAX(Detalle_Comercio) AS Detalle_Comercio
from result.CodCom_Camps_SPOS /*Base de Comercios que manda SPOS en excel (asegurarse de que este buena: sin blancos, sin duplicados, otros)*/
where Periodo_Campana=&periodo. 
and coalesce(Codigo_Comercio,0)>0 
group by /*se agrupa para asegurar de que quede a nivel de codigo UNICO*/
Codigo_Comercio,Detalle_Comercio

;quit;


%put==========================================================================================;
%put [02] Rescatar TRXs de comercios en Alianzas;
%put==========================================================================================;


%put------------------------------------------------------------------------------------------;
%put [02.1] TRXs de Tarjeta de Credito;
%put------------------------------------------------------------------------------------------;

proc sql;
create table Vta_SPOS_TC (
periodo num,
Fecha num ,
Codigo_Comercio num,
Nombre_Comercio char(99),
Actividad_Comercio char(99),
rut num,
VENTA_TARJETA num,
TOTCUOTAS num ,
PORINT num,
Tipo_Tarjeta char(10),
Marca_Campana char(99),
detalle_comercio char(99)
)
;QUIT;

proc sql inobs=1 noprint;
select 
mdy(mod(int((&Periodo_Proceso.*100+01)/100),100),mod((&Periodo_Proceso.*100+01),100),int((&Periodo_Proceso.*100+01)/10000)) format=date9. as pasito
into
:pasito
from pmunoz.codigos_capta_cdp
;QUIT;

%macro APILAR(i,f);

%let periodo_iteracion=&i;
%do %while(&periodo_iteracion<=&f); /*inicio del while*/ 

%put ############### &periodo_iteracion ################################;

DATA _NULL_;
paso = put(intnx('month',"&pasito"d,-&periodo_iteracion.,'end'),yymmn6.);
Call symput("paso",paso);
run;

%put ############### &paso ################################;

%if (&paso.<=202006) %then %do;
proc sql;
insert into Vta_SPOS_TC
select
&paso. as periodo, 
a.Fecha,
a.Codigo_Comercio,
a.Nombre_Comercio,
a.Actividad_Comercio,
a.rut,
a.VENTA_TARJETA,
a.TOTCUOTAS,
a.PORINT,
a.Tipo_Tarjeta,
b.Marca_Campana,
b.Detalle_Comercio 
from publicin.SPOS_AUT_&paso. as a 
inner join work.CodCom_Camps_SPOS_Periodo as b 
on (a.Codigo_Comercio=b.Codigo_Comercio) 
;QUIT;
%end;
%else %do;

proc sql;
insert into Vta_SPOS_TC
select
&paso. as periodo, 
a.Fecha,
a.Codigo_Comercio,
a.Nombre_Comercio,
a.Actividad_Comercio,
a.rut,
a.VENTA_TARJETA,
a.TOTCUOTAS,
a.PORINT,
a.Tipo_Tarjeta,
b.Marca_Campana,
b.Detalle_Comercio 
from publicin.SPOS_AUT_&paso. as a 
inner join work.CodCom_Camps_SPOS_Periodo as b 
on (a.Codigo_Comercio=b.Codigo_Comercio) 
;QUIT;

proc sql;
insert into Vta_SPOS_TC
select
&paso. as periodo, 
a.Fecha,
a.Codigo_Comercio,
a.Nombre_Comercio,
a.Actividad_Comercio,
a.rut,
a.VENTA_TARJETA,
a.TOTCUOTAS,
a.PORINT,
a.Tipo_Tarjeta,
b.Marca_Campana,
b.Detalle_Comercio 
from publicin.SPOS_MCD_&paso. as a 
inner join work.CodCom_Camps_SPOS_Periodo as b 
on (a.Codigo_Comercio=b.Codigo_Comercio) 
;QUIT;


%end;

%let periodo_iteracion=%sysevalf(&periodo_iteracion. +1);
%end; /*final del while*/

%mend APILAR;

%APILAR (0,&ventana_tiempo.);

%put------------------------------------------------------------------------------------------;
%put [02.3] Unir TRXs TC + TD;
%put------------------------------------------------------------------------------------------;


proc sql;
create table Vta_SPOS_CC(
periodo num,
Fecha num ,
Codigo_Comercio num,
Nombre_Comercio char(99),
Actividad_Comercio char(99),
rut num,
VENTA_TARJETA num,
TOTCUOTAS num ,
PORINT num,
Tipo_Tarjeta char(10),
Marca_Campana char(99),
detalle_comercio char(99)
)
;QUIT;

proc sql inobs=1 noprint;
select 
mdy(mod(int((&Periodo_Proceso.*100+01)/100),100),mod((&Periodo_Proceso.*100+01),100),int((&Periodo_Proceso.*100+01)/10000)) format=date9. as pasito
into
:pasito
from pmunoz.codigos_capta_cdp
;QUIT;

%macro APILAR3(i,f);

%let periodo_iteracion=&i;
%do %while(&periodo_iteracion<=&f); /*inicio del while*/ 

%put ############### &periodo_iteracion ################################;

DATA _NULL_;
paso = put(intnx('month',"&pasito"d,-&periodo_iteracion.,'end'),yymmn6.);
Call symput("paso",paso);
run;

%put ############### &paso ################################;

%IF %EVAL(&PASO.>=202109) %THEN %DO;
proc sql;
insert into Vta_SPOS_cc
select
&paso. as periodo, 
a.Fecha,
a.Codigo_Comercio,
a.Nombre_Comercio,
a.Actividad_Comercio,
a.rut,
a.VENTA_TARJETA,
a.TOTCUOTAS,
a.PORINT,
a.Tipo_Tarjeta,
b.Marca_Campana,
b.Detalle_Comercio 
from publicin.SPOS_ctacte_&paso. as a 
inner join work.CodCom_Camps_SPOS_Periodo as b 
on (a.Codigo_Comercio=b.Codigo_Comercio) 
;QUIT;
%END;

%let periodo_iteracion=%sysevalf(&periodo_iteracion. +1);
%end; /*final del while*/

%mend APILAR3;

%APILAR3 (0,&ventana_tiempo.);


proc sql;
create table Vta_SPOS (
periodo num,
Fecha num ,
Codigo_Comercio num,
Nombre_Comercio char(99),
Actividad_Comercio char(99),
rut num,
VENTA_TARJETA num,
TOTCUOTAS num ,
PORINT num,
Tipo_Tarjeta char(10),
Marca_Campana char(99),
detalle_comercio char(99)
)
;QUIT;

proc sql;
insert into Vta_SPOS
select 
*
from Vta_SPOS_TC
;quit;



proc sql;
insert into Vta_SPOS
select 
* 
from Vta_SPOS_cc
;quit;




proc sql;
drop table work.Vtas_SPOS_TC; 
drop table work.Vta_SPOS_CC ;
;quit;



%put==========================================================================================;
%put [03] Agregar Variables relevantes;
%put==========================================================================================;


%put------------------------------------------------------------------------------------------;
%put [03.1] Marcar dia de la semana;
%put------------------------------------------------------------------------------------------;


proc sql;
create table work.Vtas_SPOS as 
select 
*,
weekday(mdy(mod(int((fecha)/100),100),mod((fecha),100),int((fecha)/10000))) as Dia_Glosa,
fecha-100*floor(fecha/100) as Dia_Nro  
from work.Vta_SPOS 
;quit;



%put------------------------------------------------------------------------------------------;
%put [03.2] Marcar Region del cliente;
%put------------------------------------------------------------------------------------------;

DATA _null_;
PERIODO_1    = input(put(intnx('month',today(),0,'end'),yymmn6. ),$10.);
PERIODO_2    = input(put(intnx('month',today(),-1,'end'),yymmn6. ),$10.);
Call symput("PERIODO_1", PERIODO_1);
Call symput("PERIODO_2", PERIODO_2);
RUN;

%put &PERIODO_1;
%put &PERIODO_2;



%if (%sysfunc(exist(PUBLICIN.demo_basket_&PERIODO_1. ))) %then %do;
proc sql;
create table work.Vtas_SPOS as 
select 
a.*,
coalesce(b.Region,'SIN INFO') as  Region,
coalesce(c.segmento,'SIN INFO') as  SEGMENTO,
coalesce(e.categoria_gse,'SIN INFO') as GSE,
coalesce(d.RANGO_EDAD,'SIN INFO') as RANGO_EDAD,
coalesce(d.SEXO,'SIN INFO') as SEXO,
d.edad



from work.Vtas_SPOS as a 
left join publicin.direcciones as b 
on (a.rut=b.rut)
left join publicin.segmento_comercial as c
on a.rut=c.rut
left join PUBLICIN.demo_basket_&PERIODO_1. as d
on(a.rut=d.rut)
left join rsepulv.gse_corp as e
on(a.rut=e.rut)

;quit;

%end;
%else %do;

proc sql;
create table work.Vtas_SPOS as 
select 
a.*,
coalesce(b.Region,'SIN INFO') as  Region,
coalesce(c.segmento,'SIN INFO') as  SEGMENTO,
coalesce(e.categoria_gse,'SIN INFO') as GSE,
coalesce(d.RANGO_EDAD,'SIN INFO') as RANGO_EDAD,
coalesce(d.SEXO,'SIN INFO') as SEXO,
d.edad



from work.Vtas_SPOS as a 
left join publicin.direcciones as b 
on (a.rut=b.rut)
left join publicin.segmento_comercial as c
on a.rut=c.rut
left join PUBLICIN.demo_basket_&PERIODO_2. as d
on(a.rut=d.rut)
left join rsepulv.gse_corp as e
on(a.rut=e.rut)

;quit;

%end;



/*Queda pendiente para una version 2.0, */


%put==========================================================================================;
%put [04] Agrupar tabla de cara a un entregable;
%put==========================================================================================;

proc sql;

create table work.Vtas_SPOS_AGG as 
select 
Periodo,
/*CODIGO_COMERCIO*/
Tipo_Tarjeta,
Marca_Campana,
Detalle_Comercio,
Dia_Glosa,
Dia_Nro,
Region,
SEGMENTO,
 case when GSE in ('C1a',
'C1b',
'C2') then 'C1C2' else GSE end as GSE,
case when edad between 1 and 10 then '01.[1,10]'
when edad between 11 and 20 then '02.]10,20]'
when edad between 21 and 30 then '03.]20,30]'
when edad between 31 and 40 then '04.]30,40]'
when edad between 41 and 50 then '05.]40,50]'
when edad between 51 and 50 then '06.]50,60]'
when edad between 61 and 50 then '07.]60,70]'
when edad between 71 and 50 then '08.]70,80]'
when edad between 81 and 50 then '09.]80,90]'
when edad between 91 and 50 then '10.]90,100]'
else '11. SIN INFO' end as tramo_edad,

SEXO,
count(rut) as Nro_TRXs,
count(distinct rut) as Nro_Clientes,
sum(VENTA_TARJETA) as Mto_TRXs,
sum(TOTCUOTAS) as sum_TOTCUOTAS,
sum(PORINT) as sum_PORINT,
sum(TOTCUOTAS*VENTA_TARJETA) as sum_TOTCUOTAS_x_Mto,
sum(PORINT*VENTA_TARJETA) as sum_PORINT_x_Mto 
from work.Vtas_SPOS 
group by 
Periodo,
/*CODIGO_COMERCIO,*/
Detalle_Comercio,
Tipo_Tarjeta,
Marca_Campana,
Dia_Glosa,
Dia_Nro,
Region,
SEGMENTO,
calculated GSE,
calculated tramo_edad,
SEXO
;quit;



%put==========================================================================================;
%put [?] Marcar Dia Comparable;
%put==========================================================================================;

%put===========================================================================================;
%put [08] DIA COMPARABLE  y ENTREGABLE PM;
%put===========================================================================================;


proc sql noprint;
select 
max(dia_nro) as dia_comparable_TAM
into:dia_comparable_TAM
from WORK.Vtas_SPOS_AGG
where periodo=&Periodo.
and Tipo_Tarjeta='TAM'
;QUIT;

proc sql noprint;
select 
max(dia_nro) as dia_comparable_TR
into:dia_comparable_TR
from WORK.Vtas_SPOS_AGG
where periodo=&Periodo.
and Tipo_Tarjeta='TR'
;QUIT;

proc sql noprint;
select 
max(dia_nro) as dia_comparable_MCD
into:dia_comparable_MCD
from WORK.Vtas_SPOS_AGG
where periodo=&Periodo.
and Tipo_Tarjeta='MCD'
;QUIT;


proc sql noprint;
select 
max(dia_nro) as dia_comparable_CTACTE
into:dia_comparable_CTACTE
from WORK.Vtas_SPOS_AGG
where periodo=&Periodo.
and Tipo_Tarjeta='CTACTE'
;QUIT;


%let dia_comparable_TAM=&dia_comparable_TAM;
%let dia_comparable_TR=&dia_comparable_TR;
%let dia_comparable_MCD=&dia_comparable_MCD;
%let dia_comparable_CTACTE=&dia_comparable_CTACTE;

%put &dia_comparable_TAM;
%put &dia_comparable_TR;
%put &dia_comparable_MCD;
%put &dia_comparable_CTACTE;



DATA _NULL_;
hoy = put(intnx('month',today(),0-1,'same'),date9.);
ultimo_dia=put(intnx('month',today(),0-1,'end'),date9.);

Call symput("hoy",hoy);
Call symput("ultimo_dia",ultimo_dia);

run;

%put &hoy;
%put &ultimo_dia;

proc sql inobs=1 noprint;
select
day("&hoy."d) as hoy,
day("&ultimo_dia"d) as ultimo_dia
into :hoy,
:ultimo_dia
from pmunoz.codigos_capta_cdp
;QUIT;

%let hoy=&hoy;
%let ultimo_dia=&ultimo_dia;

%put &hoy;
%put &ultimo_dia;

%macro wea;
/*##################cuando el ultimo dia es igual al dia de eje#########################*/
%if %eval(&hoy.=&ultimo_dia.) %then %do;

%if %eval(&dia_comparable_TAM.=&hoy.) %then %do;
proc sql;
create table  entregable_PM as 
select 
*,
case when Tipo_Tarjeta='TAM' and dia_nro<=(&dia_comparable_TAM.-1) then 1 
when Tipo_Tarjeta='TR' and dia_nro<=(&dia_comparable_TAM.-1) then 1 
else 0 end as Dia_Comparable 
from Vtas_SPOS_AGG
where tipo_tarjeta in ('TR','TAM')
;QUIT;
%end;

%else %if %eval(&dia_comparable_TAM.<&hoy.) %then %do;
proc sql;
create table  entregable_PM as 
select 
*,
case when Tipo_Tarjeta='TAM' and dia_nro<=(&dia_comparable_TAM.) then 1 
when Tipo_Tarjeta='TR' and dia_nro<=(&dia_comparable_TAM.) then 1 
else 0 end as Dia_Comparable 
from Vtas_SPOS_AGG
where tipo_tarjeta in ('TR','TAM')
;QUIT;
%end;


/*vista MCD*/

%if %eval(&dia_comparable_MCD.=&hoy.) %then %do;
proc sql;
insert into entregable_PM  
select 
*,
case when Tipo_Tarjeta='MCD' and dia_nro<=(&dia_comparable_MCD.-1) then 1 
else 0 end as Dia_Comparable 
from Vtas_SPOS_AGG
where tipo_tarjeta in ('MCD')
;QUIT;
%end;

%else %if %eval(&dia_comparable_MCD.<&hoy.) %then %do;

proc sql;
insert into entregable_PM  
select 
*,
case when Tipo_Tarjeta='MCD' and dia_nro<=(&dia_comparable_MCD.) then 1 
else 0 end as Dia_Comparable 
from Vtas_SPOS_AGG
where tipo_tarjeta in ('MCD')
;QUIT;

%end;




/*vista CTACTE*/

%if %eval(&dia_comparable_CTACTE.=&hoy.) %then %do;
proc sql;
insert into entregable_PM  
select 
*,
case when Tipo_Tarjeta='CTACTE' and dia_nro<=(&dia_comparable_CTACTE.-1) then 1 
else 0 end as Dia_Comparable 
from Vtas_SPOS_AGG
where tipo_tarjeta in ('CTACTE')
;QUIT;
%end;

%else %if %eval(&dia_comparable_CTACTE.<&hoy.) %then %do;

proc sql;
insert into entregable_PM  
select 
*,
case when Tipo_Tarjeta='CTACTE' and dia_nro<=(&dia_comparable_CTACTE.) then 1 
else 0 end as Dia_Comparable 
from Vtas_SPOS_AGG
where tipo_tarjeta in ('CTACTE')
;QUIT;

%end;


%end;

/*#####################CUANDO EL DIA DE EJE ES DISTINTO AL ULTIMO DIA DEL MES#############################*/

%else  %do;

%if %eval(&dia_comparable_TAM.=&hoy.) %then %do;
proc sql;
create table  entregable_PM as 
select 
*,
case when Tipo_Tarjeta='TAM' and dia_nro<=(&dia_comparable_TAM.-1) then 1 
when Tipo_Tarjeta='TR' and dia_nro<=(&dia_comparable_TAM.-1) then 1 
else 0 end as Dia_Comparable 
from Vtas_SPOS_AGG
where tipo_tarjeta in ('TR','TAM')
;QUIT;
%end;

%else %if %eval(&dia_comparable_TAM.<&hoy.) %then %do;

proc sql;
create table  entregable_PM as 
select 
*,
case when Tipo_Tarjeta='TAM' and dia_nro<=(&dia_comparable_TAM.) then 1 
when Tipo_Tarjeta='TR' and dia_nro<=(&dia_comparable_TAM.) then 1 
else 0 end as Dia_Comparable 
from Vtas_SPOS_AGG
where tipo_tarjeta in ('TR','TAM')
;QUIT;

%end;

%else %if %eval(&dia_comparable_TAM.=&ultimo_dia.) %then %do;
proc sql;
create table  entregable_PM as 
select 
*,
case when Tipo_Tarjeta='TAM' and dia_nro<=(&dia_comparable_TAM.) then 1 
when Tipo_Tarjeta='TR' and dia_nro<=(&dia_comparable_TAM.) then 1 
else 0 end as Dia_Comparable 
from Vtas_SPOS_AGG
where tipo_tarjeta in ('TR','TAM')
;QUIT;
%end;

/*vista MCD*/

%if %eval(&dia_comparable_MCD.=&hoy.) %then %do;
proc sql;
insert into entregable_PM  
select 
*,
case when Tipo_Tarjeta='MCD' and dia_nro<=(&dia_comparable_MCD.-1) then 1 
else 0 end as Dia_Comparable 
from Vtas_SPOS_AGG
where tipo_tarjeta in ('MCD')

;QUIT;
%end;

%else %if %eval(&dia_comparable_MCD.<&hoy.) %then %do;
proc sql;
insert into entregable_PM
select 
*,
case when Tipo_Tarjeta='MCD' and dia_nro<=(&dia_comparable_MCD.) then 1  
else 0 end as Dia_Comparable 
from Vtas_SPOS_AGG
where tipo_tarjeta in ('MCD')
;QUIT;
%end;

%else %if %eval(&dia_comparable_MCD.=&ultimo_dia.) %then %do;
proc sql;
insert into entregable_PM
select 
*,
case when Tipo_Tarjeta='MCD' and dia_nro<=(&dia_comparable_MCD.) then 1 
else 0 end as Dia_Comparable 
from Vtas_SPOS_AGG 
where tipo_tarjeta in ('MCD')
;QUIT;
%end;




/*vista CTACTE*/

%if %eval(&dia_comparable_CTACTE.=&hoy.) %then %do;
proc sql;
insert into entregable_PM  
select 
*,
case when Tipo_Tarjeta='CTACTE' and dia_nro<=(&dia_comparable_CTACTE.-1) then 1 
else 0 end as Dia_Comparable 
from Vtas_SPOS_AGG
where tipo_tarjeta in ('CTACTE')

;QUIT;
%end;

%else %if %eval(&dia_comparable_CTACTE<&hoy.) %then %do;
proc sql;
insert into entregable_PM
select 
*,
case when Tipo_Tarjeta='CTACTE' and dia_nro<=(&dia_comparable_CTACTE.) then 1  
else 0 end as Dia_Comparable 
from Vtas_SPOS_AGG
where tipo_tarjeta in ('CTACTE')
;QUIT;
%end;

%else %if %eval(&dia_comparable_CTACTE.=&ultimo_dia.) %then %do;
proc sql;
insert into entregable_PM
select 
*,
case when Tipo_Tarjeta='CTACTE' and dia_nro<=(&dia_comparable_CTACTE.) then 1 
else 0 end as Dia_Comparable 
from Vtas_SPOS_AGG 
where tipo_tarjeta in ('CTACTE')
;QUIT;
%end;
%end;
%mend wea;
%wea;

%put==========================================================================================;
%put [05] Vaciar en tabla entregable;
%put==========================================================================================;

proc sql;
create table cliente_unico as 
select 
periodo,
. as Codigo_Comercio,
'' as Tipo_Tarjeta,
Marca_Campana,
'' as detalle_comercio,
. as Dia_Glosa,
. as Dia_Nro,	
'' as REGION,
'' as SEGMENTO,
. as Nro_TRXs,
 count (distinct rut ) as Nro_Clientes,
. as Mto_TRXs,
. as sum_TOTCUOTAS,
. as sum_PORINT,
. as sum_TOTCUOTAS_x_Mto,	
. as sum_PORINT_x_Mto,
case when dia_nro<=max(&dia_comparable_CTACTE.,&dia_comparable_MCD.,&dia_comparable_TR.,&dia_comparable_TAM.) then 1 
else 0 end as  Dia_Comparable

from Vtas_SPOS
group by periodo,
calculated dia_comparable,
Marca_Campana
;QUIT;


proc sql; 
create table &libreria..SegCampSPOS_Ventas as 
select 
/* today() format=datetime20. as Fecha_Proceso, */
dhms(today(),0,0,time()) format=datetime. as Fecha_Proceso,
'HISTORICO' as TIPO,
* 
from work.entregable_PM  
outer union corr
select 
dhms(today(),0,0,time()) format=datetime. as Fecha_Proceso,
'CLIENTE UNICO' as TIPO,
* 
from cliente_unico
;quit; 

%put &Fecha_Proceso;

proc sql;
drop table work.entregable_PM ;
drop table work.Vtas_SPOS_AGG; 
drop table codcom_camps_spos_periodo;
drop table vta_spos;
drop table vta_spos_tc;
drop table cliente_unico;
drop table vtas_spos;
drop table cuentas;
;QUIT;


%mend segcampvta_spos;

%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/
%segcampvta_spos(&LIBRERIA.);

data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */






/*	Fecha ejecución del proceso	*/
data _null_;
execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechaeDVN", execDVN) ;
RUN;
%put &fechaeDVN;/*fecha ejecucion proceso */


/*   ENVÍO DE CORREO CON MAIL VARIABLE   */

proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';

SELECT EMAIL into :DEST_3 
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'ALEJANDRA_MARINAO';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_2","&DEST_3","kgonzalezi@bancoripley.com")
SUBJECT="MAIL_AUTOM: PROCESO SEGUIMIENTO VENTA SPOS %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso SEGUIMIENTO VENTA SPOS, ejecutado con fecha: &fechaeDVN";  
 put "Version 03 "; 
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
