/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROC_SEGUIM_RUBRO_SPOS 		================================*/
/* CONTROL DE VERSIONES
/* 2020-09-22 ---- Nueva versión por Pedro
/* 2020-09-04 ---- Nueva correción por Pedro
/* 2020-08-19 ---- Versión validada por Pedro y Ale
/* 2020-08-17 ---- Nueva versión Pedro
/* 2020-05-20 ---- Se actualiza fecha de proceso vs la versión anterior - línea 464 y 499
/*
/* Tiempo Aprox de Ejecución 20 min
*/
/*==================================================================================================*/

/*::::::::::::::::::::::::::*/

%let libreria=RESULT;

PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table Panes as 
select * 
from connection to ORACLE(
select 
G.PAN,
J.DESTIPT  TIPO_TARJETA_RSAT
FROM 
 GETRONICS.MPDT009 G /*Tarjeta*/ 
left join GETRONICS.MPDT026 J
on(j.CODMAR=G.codmar) and (J.INDTIPT=G.INDTIPT)
)
;QUIT;

%macro seg_rubro(periodo_proceso,libreria);



DATA _NULL_;
fin = put(intnx('month',today(),-&periodo_proceso.,'end'),date9.);
mes_fin = put(intnx('month',today(),-&periodo_proceso.,'end'),yymmn6.);
ini = put(intnx('month',today(),-&periodo_proceso.,'begin'),date9.);
mes_ini = put(intnx('month',today(),-&periodo_proceso.,'begin'),yymmn6.);
mes_12 = put(intnx('month',today(),-&periodo_proceso.-12,'begin'),yymmn6.);


Call symput("INI",ini);
Call symput("FIN",fin);
Call symput("mes_fin",mes_fin);
Call symput("mes_ini",mes_ini);
Call symput("mes_12",mes_12);
run;

%put &INI;
%put &FIN;
%put &mes_fin;
%put &mes_ini;
%put &mes_12;




%put===========================================================================================;
%put [01] Sacar Venta de TC desde SPOS_AUT;
%put===========================================================================================;

%put-------------------------------------------------------------------------------------------;
%put [01.1] Extraccion de Venta (con marca de nacional/internacional);
%put-------------------------------------------------------------------------------------------;

proc sql;
create table Vta_SPOS_TC (
PERIODO num,
fecha num,
fecha_tableau date,
Tipo_Tarjeta char(10),
rut num,
CODACT num,
Monto num, 
Codigo_Comercio num, 
SI_Nacional num,
totcuotas char(99),
porint num,
si_online num,
pan char(16)
)
;QUIT;






%if %eval(&mes_ini.<202006) %then %do; 
proc sql;
insert into Vta_SPOS_TC
select 
&mes_ini. as periodo,
fecha,
mdy(mod(int(fecha/100),100),mod(fecha,100),int(fecha/10000)) format=date9. as fecha_tableau,
Tipo_Tarjeta,
rut,
CODACT,
Venta_Tarjeta as Monto, 
Codigo_Comercio, 
case when CODPAIS=152 then 1 else 0 end as SI_Nacional,
case when totcuotas<=12  and totcuotas<=9 then cats('0',totcuotas,'.',totcuotas)
when totcuotas<=12  and totcuotas>9 then cats(totcuotas,'.',totcuotas)
else '13.>12' end as totcuotas ,
case when porint>0 then 1 else 0 end as porint,
. as si_online,
pan
from publicin.SPOS_aut_&mes_ini.

;QUIT;
%end;
%else %do;

proc sql;
insert into Vta_SPOS_TC
select 
&mes_ini. as periodo,
fecha,
mdy(mod(int(fecha/100),100),mod(fecha,100),int(fecha/10000)) format=date9. as fecha_tableau,
Tipo_Tarjeta,
rut,
CODACT,
Venta_Tarjeta as Monto, 
Codigo_Comercio, 
case when CODPAIS=152 then 1 else 0 end as SI_Nacional,
case when totcuotas<=12  and totcuotas<=9 then cats('0',totcuotas,'.',totcuotas)
when totcuotas<=12  and totcuotas>9 then cats(totcuotas,'.',totcuotas)
else '13.>12' end as totcuotas,
case when porint>0 then 1 else 0 end as porint,
si_digital as  si_online,
pan
from publicin.SPOS_aut_&mes_ini. 
;QUIT;

%end;

%if (%sysfunc(exist(publicin.SPOS_MCD_&mes_ini.))) %then %do;
proc sql;
insert into Vta_SPOS_TC
select 
&mes_ini. as periodo,
fecha,
mdy(mod(int(fecha/100),100),mod(fecha,100),int(fecha/10000)) format=date9. as fecha_tableau,
'TD' as Tipo_Tarjeta,
rut,
CODACT,
Venta_Tarjeta as Monto, 
Codigo_Comercio, 
case when CODPAIS=152 then 1 else 0 end as SI_Nacional,
'00.0' as totcuotas ,
0  as porint,
si_digital as  si_online,
pan
from publicin.SPOS_MCD_&mes_ini.
;QUIT; 
%end;


%if (%sysfunc(exist(publicin.SPOS_ctacte_&mes_ini.))) %then %do;
proc sql;
insert into Vta_SPOS_TC
select 
&mes_ini. as periodo,
fecha,
mdy(mod(int(fecha/100),100),mod(fecha,100),int(fecha/10000)) format=date9. as fecha_tableau,
'CTACTE' as Tipo_Tarjeta,
rut,
CODACT,
Venta_Tarjeta as Monto, 
Codigo_Comercio, 
case when CODPAIS=152 then 1 else 0 end as SI_Nacional,
'00.0' as totcuotas ,
0  as porint,
si_digital as  si_online,
pan
from publicin.SPOS_ctacte_&mes_ini.
;QUIT; 
%end;





%put-------------------------------------------------------------------------------------------;
%put [01.2] Pegar Rubro correspondiente;
%put-------------------------------------------------------------------------------------------;

proc sql;
create table TABLA_ARBOL as  
select 
COD_ACT,
max(CATEGORIAS_RIPLEY) as RUBRO_GESTION,
MAX('RUBRO_GESTION (spos)'n) AS RUBRO_TB,
MAX(FAMILIA_GESTION) AS FAMILIA_GESTION
from sbarrera.TABLA_ARBOL /*Tabla de asignacion de rubros*/
group by 
COD_ACT
;QUIT;


PROC SQL;
CREATE INDEX COD_ACT ON work.TABLA_ARBOL (COD_ACT)
;QUIT;

PROC SQL;
CREATE INDEX CODACT ON work.Vta_SPOS_TC (CODACT)
;QUIT;

proc sql;
create table work.Vta_SPOS_TC1 as 
select 
a.* ,
coalesce(b.RUBRO_GESTION,'Otros Rubros SPOS') as Rubro,
coalesce(b.RUBRO_TB,'Otros Rubros SPOS') as RUBRO_TB,
coalesce(b.FAMILIA_GESTION,'Otros Rubros SPOS') as FAMILIA_GESTION

from work.Vta_SPOS_TC as a 
left join TABLA_ARBOL as b 
on (a.CODACT=b.COD_ACT) 
;quit;




proc sql;
create table Vta_SPOS (
Periodo num ,
Fecha num,
fecha_tableau date,
Tipo_Tarjeta char(10),
rut num ,
SI_Nacional num,
totcuotas char(99),
porint num,
SI_online num,
Monto num ,
Codigo_Comercio num,  
Rubro char(99),
RUBRO_TB char(99),
FAMILIA_GESTION char(99),
pan char(16)
)
;QUIT;

proc sql;
insert into Vta_SPOS
select 
Periodo  ,
Fecha ,
fecha_tableau ,
Tipo_Tarjeta ,
rut  ,
SI_Nacional ,
totcuotas ,
porint ,
SI_online ,
Monto  ,
Codigo_Comercio ,  
Rubro ,
RUBRO_TB,
FAMILIA_GESTION,
pan
from Vta_SPOS_TC1
;quit;


/*Eliminar tablas de paso*/

proc sql;
drop table work.Vta_SPOS_TC  ; 
drop table work.Vta_SPOS_TC1  ; 
drop table work.tabla_arbol  ;
drop table work.rubro  ; 
;QUIT;


%put===========================================================================================;
%put [04] Pegar Marcas ;
%put===========================================================================================;

%put-------------------------------------------------------------------------------------------;
%put [04.1] Pegar marca de online/presencial;
%put-------------------------------------------------------------------------------------------;

proc sql;
create table codigos_online as 
select distinct Codigos_Online
from sbarrera.CODIGOS_ONLINE_SPOS
;QUIT;

PROC SQL;
CREATE INDEX Codigos_Online ON work.codigos_online (Codigos_Online)
;QUIT;

PROC SQL;
CREATE INDEX Codigo_Comercio ON work.Vta_SPOS (Codigo_Comercio)
;QUIT;


%if %eval(&mes_fin.<202006) %then %do;
proc sql;
create table work.Vta_SPOS2 as 
select 
a.Periodo,
a.Fecha,
a.fecha_tableau,
a.Tipo_Tarjeta,
a.rut,
a.SI_Nacional,
a.totcuotas ,
a.porint ,
case when b.Codigos_Online is not null then 1 else 0 end as SI_online, 
a.Monto,
a.Codigo_Comercio,
a.Rubro,
a.RUBRO_TB,
a.FAMILIA_GESTION,
a.pan
from work.Vta_SPOS as a 
left join codigos_online as b 
on (a.Codigo_Comercio=b.Codigos_Online)
;quit;

%end;

%else %do;
proc sql;
create table work.Vta_SPOS2 as 
select 
*
from work.Vta_SPOS

;quit;
%end;



proc sql;
drop table codigos_online;
drop table Vta_SPOS;
;QUIT;



%put-------------------------------------------------------------------------------------------;
%put [04.4] Rubro 2;
%put-------------------------------------------------------------------------------------------;

proc sql;
create table work.Vta_SPOS3 as 
select 
*,
CASE WHEN RUBRO in ('SERVICIOS','SERVICIOS BASICOS','TRANSPORTE') THEN 'SERVICIOS'
WHEN RUBRO IN  ('OTROS COMERCIOS','Otros Rubros SPOS','BELLEZA') THEN 'OTROS COMERCIOS'
WHEN RUBRO IN ('VIAJES','ENTRETENCION') THEN 'Viajes&Entretencion'
WHEN  RUBRO IN ('ALIMENTACION Y FAST FOOD','RESTAURANTES') THEN 'Alimentacion'
WHEN RUBRO IN ('RECAUDACION SECTOR PUBLICO','RECAUDACION','INSTITUCIONES FINANCIERAS') THEN 'Recaudacion&Inst_Finan'
ELSE RUBRO END AS RUBRO2,
day(fecha_tableau) as dia_nro,
weekday(fecha_tableau) as dia_glosa

from work.Vta_SPOS2  
;quit;





/*inyeccion de seguros*/

%if (%sysfunc(exist(publicin.TRX_SEGuros_&mes_ini.))) %then %do;

proc sql;
insert into Vta_SPOS3  
select 
&mes_ini. as periodo,
input(compress(FECPROCES,'-'),best.) as fecha,
mdy(mod(int(input(compress(FECPROCES,'-'),best.)/100),100),mod(input(compress(FECPROCES,'-'),best.),100),int(input(compress(FECPROCES,'-'),best.)/10000)) format=date9. as fecha_tableau,
'TAM' as Tipo_Tarjeta,
rut,
1 as si_nacional,
'00.0' as totcuotas,
0 as porint,
1 as SI_online,
MONTO_RECAUDADO as monto,
0 as Codigo_Comercio,
'SEGUROS RIPLEY OM' as Rubro,
'SEGUROS RIPLEY OM' as RUBRO_TB,
'SEGUROS RIPLEY OM' as FAMILIA_GESTION,
pan,
'SEGUROS RIPLEY OM' as  RUBRO2,
day(mdy(mod(int(input(compress(FECPROCES,'-'),best.)/100),100),mod(input(compress(FECPROCES,'-'),best.),100),int(input(compress(FECPROCES,'-'),best.)/10000))) as dia_nro,
weekday(calculated fecha_tableau) as dia_glosa
from  publicin.TRX_SEGuros_&mes_ini.  
where CODCONREC not in ('S201','S083','S170')
and TIPO_SEGURO<>'SEGUROS TARJETA'
and (rut<>17519002 and monto_recaudado<>476454338)
;QUIT;

%end;


proc sql;
create table vta_spos4 as 
select 
a.*,
coalesce(b.TIPO_TARJETA_RSAT,'SIN INFO')  as TIPO_TARJETA_RSAT,
c.categoria_gse as GSE
from Vta_SPOS3 as a 
left join Panes as b
on(a.pan=b.pan)
left join RSEPULV.GSE_CORP as C
on(a.RUT=C.RUT)
;QUIT;

%put===========================================================================================;
%put [05] AGRUPAMIENTO ACUMULADO;
%put===========================================================================================;


proc sql;
create table primer_agrupamiento as 
select 
today() format=date9. as Fecha_Proceso, 
Periodo,
Tipo_Tarjeta,
SI_Nacional,
RUBRO_TB,
FAMILIA_GESTION,
RUBRO2,
SI_online,
dia_nro,
totcuotas,
porint,
case when dia_glosa=1 then '07.Domingo'
when dia_glosa=2 then '01.Lunes'
when dia_glosa=3 then '02.Martes'
when dia_glosa=4 then '03.Miercoles'
when dia_glosa=5 then '04.Jueves'
when dia_glosa=6 then '05.Viernes'
when dia_glosa=7 then '06.Sabado' else '' end as dia_glosa,
TIPO_TARJETA_RSAT,
count(rut) as Nro_TRXs,
count(distinct rut) as Nro_Clientes,
sum(Monto) as Mto_TRXs,
case when GSE in ('C1a', 'C1b', 'C2') the 'C1C2' else GSE end as GSE2 
from Vta_SPOS4
group by 
calculated Fecha_Proceso, 
Periodo,
Tipo_Tarjeta,
SI_Nacional,
RUBRO_TB,
FAMILIA_GESTION,
RUBRO2,
SI_online,
TIPO_TARJETA_RSAT,
dia_nro,
calculated dia_glosa,
totcuotas,
porint,
calculated GSE2
;QUIT;

%put===========================================================================================;
%put [07] GUARDAR EN DURO;
%put===========================================================================================;

%if (%sysfunc(exist(&libreria..seg_rubro_spos_SEG_HIST))) %then %do;
 
%end;
%else %do;
proc sql;
create table &libreria..seg_rubro_spos_SEG_HIST (
Fecha_Proceso date, 
Periodo num , 
Tipo_Tarjeta char(30), 
SI_Nacional num, 
RUBRO_TB char(30),
FAMILIA_GESTION char(30), 
RUBRO2 char (30), 
SI_online num, 
dia_nro num, 
totcuotas char(30),
porint num,
dia_glosa char(30), 
TIPO_TARJETA_RSAT char(30),
Nro_TRXs num, 
Nro_Clientes num, 
Mto_TRXs num,
GSE2 CHAR(10))
;QUIT;
%end;

proc sql;
delete *
from &libreria..seg_rubro_spos_SEG_HIST
where periodo=&mes_ini. 
;QUIT;

proc sql;
insert into &libreria..seg_rubro_spos_SEG_HIST
select *
from primer_agrupamiento
;QUIT;

proc sql;
create table  &libreria..seg_rubro_spos_SEG_HIST as 
select *
from &libreria..seg_rubro_spos_SEG_HIST
;QUIT;

proc sql;
drop table primer_agrupamiento;
drop table seg_paso;
drop table vta_spos2;
drop table vta_spos3;
drop table vta_spos4;
;QUIT;


%mend SEG_RUBRO;

%macro evaluar (A);

proc sql noprint ;
select distinct day(today()) as dia 
into:dia
from sashelp.library
;QUIT;

%if %eval(&dia.<=6) %then %do;

%seg_rubro(	1	,	&libreria.)	;
%seg_rubro(	0	,	&libreria.)	;
%end;
%else %do;
%seg_rubro(	0	,	&libreria.)	;
%end;

%mend evaluar;

%evaluar(A);



proc sql;
create table  &libreria..seg_rubro_spos_SEG_HIST_comp as 
select *,
case when dia_nro<=day(intnx("day",today(),-1)) then 1 else 0 end as dia_comparable

from &libreria..seg_rubro_spos_SEG_HIST
;QUIT;

DATA _NULL_;
mes_ini = put(intnx('month',today(),0,'begin'),yymmn6.);
mes_12 = put(intnx('month',today(),-12,'begin'),yymmn6.);


Call symput("mes_ini",mes_ini);
Call symput("mes_12",mes_12);
run;

%put &mes_ini;
%put &mes_12;

proc sql;
create table &libreria..SEG_RUBRO_SPOS_SEG_HIST_12M as
select *
from &libreria..seg_rubro_spos_SEG_HIST
where periodo between &mes_12. and &mes_ini.
;quit;








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
TO =("&DEST_1","&DEST_2","&DEST_3","&DEST_4","kgonzalezi@bancoripley.com")

SUBJECT="MAIL_AUTOM: PROCESO SEGUIMIENTO DE RUBROS SPOS %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso SEGUIMIENTO DE RUBROS SPOS, ejecutado con fecha: &fechaeDVN";  
 put "Version 14 "; 
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

