/*MACRO QUE GENERA INFORMACION DE CLIENTES INTEGRALES*/


%let libreria=RESULT;


/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table cuentas  as 
select * 
from connection to ORACLE( 
select 
cast(B.PEMID_GLS_NRO_DCT_IDE_K as INT)  RUT,
A.CODENT,
A.CENTALTA,
A.CUENTA,
cast(REPLACE(a.FECALTA, '-') as INT)   FECALTA_CTTO,
cast(REPLACE(a.FECBAJA , '-') as INT)   FECBAJA_CTTO,
a.PRODUCTO,
a.SUBPRODU,
a.CONPROD,
c.DESPROD as DESCRIPCION_PRODUCTO,
case when c.DESPROD in ('CUOTAS','CUOTAS SIR','PREFERENTE') then 'TR'
when c.desprod in ('MASTERCARD CLASICA',
'MASTERCARD CLASICA CHIP',
'MASTERCARD CUOTAS') then 'TAM'
when c.desprod in ('TARJETA DEBITO') then 'TD' end as tipo_producto

from MPDT007 a
INNER JOIN BOPERS_MAE_IDE B 
ON A.IDENTCLI=B.PEMID_NRO_INN_IDE
inner join MPDT043 C
on(a.producto=c.producto) and (a.SUBPRODU=c.SUBPRODU)
where a.PRODUCTO<>'08'
) A
;QUIT;


%macro ejecutar (i,lib);


DATA _null_;
INI = input(put(intnx('month',today(),-&i.,'begin'),date9. ),$10.);
FIN = input(put(intnx('month',today(),-&i.,'end'),date9. ),$10.);
periodo = input(put(intnx('month',today(),-&i.,'end'),yymmn6. ),$10.);
Call symput("INI", INI);
Call symput("FIN", FIN);
Call symput("periodo", periodo);
RUN;

%put &INI; 
%put &FIN;
%put &periodo;

proc sql;
create table captados as 
select 
rut_cliente as rut,
producto,
fecha,
cuenta 
from result.capta_salida 
where fecha between "&ini."d and "&fin."d
and producto not in ('CAMBIO DE PRODUCTO')
;QUIT;


proc sql;
create table captados2 as 
select distinct a.rut,
count(distinct case when a.producto in ('TR','TAM','CAMBIO DE PRODUCTO') then a.rut end) as capta_credito,
count(distinct case when a.producto not in ('TR','TAM','CAMBIO DE PRODUCTO') then a.rut end) as capta_debito
from captados  as a
group by a.rut
;QUIT;

proc sql;
create table captados3 as 
select distinct 
a.*,
case when b.producto in ('TR','TAM','CAMBIO DE PRODUCTO') then b.fecha end  format=date9. as fecha_credito,
case when c.producto not in ('TR','TAM','CAMBIO DE PRODUCTO') then c.fecha end  format=date9. as fecha_debito
from captados2 as a 
left join (select * from captados where producto in ('TR','TAM','CAMBIO DE PRODUCTO') ) as b
on(a.rut=b.rut)
left join (select * from captados where producto not in ('TR','TAM','CAMBIO DE PRODUCTO') ) as c
on(a.rut=c.rut)
;QUIT;



proc sql;
create table captados4 as 
select 
a.*,
count(distinct case when 
b.FECALTA_CTTO<year(a.fecha_debito)*10000+month(a.fecha_debito)*100+day(a.fecha_debito) and 
(b.fecbaja_ctto =10101 or b.fecbaja_ctto>year(a.fecha_debito)*10000+month(a.fecha_debito)*100+day(a.fecha_debito))
and capta_credito=0 and capta_debito=1
then b.rut  end) as CAPTA_DEBITO_STOCK
from captados3 as a 
left join cuentas as b
on(a.rut=b.rut)
group by a.rut
;QUIT;


proc sql;
create table resumen as 
select 
&periodo. as periodo,
count(distinct case when capta_credito= 1then rut end) as capta_credito,
count(distinct case when capta_debito=1 then rut end) as capta_debito,
count(distinct case when capta_debito=1 and capta_credito=1 then rut end) as integral,
count(distinct case when CAPTA_DEBITO_STOCK=1 then rut end) as stock_credito
from captados4
;QUIT;


%if (%sysfunc(exist(&lib..cliente_integral_capta))) %then %do;
 
%end;
%else %do;
PROC  SQL;
CREATE TABLE &lib..cliente_integral_capta (
periodo num,
capta_credito num,
capta_debito num,
 integral num,
stock_credito num
)
;QUIT;
%end;

proc sql;
delete *
from &lib..cliente_integral_capta 
where periodo=&periodo.
;QUIT;

proc sql;
insert into &lib..cliente_integral_capta
select 
*
from resumen
;QUIT;

proc sql;
drop table captados;
drop table captados2;
drop table captados3;
drop table captados4;
drop table resumen;
;QUIT;


%mend ejecutar;

%ejecutar(0,&libreria.);
%ejecutar(1,&libreria.);


DATA _null_;
periodo = input(put(intnx('month',today(),0,'end'),yymmn6. ),$10.);
periodo_ant = input(put(intnx('month',today(),-1,'end'),yymmn6. ),$10.);
Call symput("periodo", periodo);
Call symput("periodo_ant", periodo_ant);
RUN;

%put &periodo_ant;
%put &periodo;

		
proc sql noprint ;
select periodo as periodo_ini into:periodo_ini
from &libreria..cliente_integral_capta where periodo=&periodo_ant.;
select capta_credito as capta_credito1 into:capta_credito1
from &libreria..cliente_integral_capta where periodo=&periodo_ant.;
select capta_debito as capta_debito1 into:capta_debito1
from &libreria..cliente_integral_capta where periodo=&periodo_ant.;
select integral as integral1 into:integral1
from &libreria..cliente_integral_capta where periodo=&periodo_ant.;
select stock_credito as stock_credito1 into:stock_credito1
from &libreria..cliente_integral_capta where periodo=&periodo_ant.
;QUIT;

proc sql noprint;
select periodo as periodo2 into:periodo2
from &libreria..cliente_integral_capta where periodo=&periodo.;
select capta_credito as capta_credito2 into:capta_credito2
from &libreria..cliente_integral_capta where periodo=&periodo.;
select capta_debito as capta_debito2 into:capta_debito2
from &libreria..cliente_integral_capta where periodo=&periodo.;
select integral as integral2 into:integral2
from &libreria..cliente_integral_capta where periodo=&periodo.;
select stock_credito as stock_credito2 into:stock_credito2
from &libreria..cliente_integral_capta where periodo=&periodo.
;QUIT;


/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 


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


quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;



data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_3","carteagas@bancoripley.com")
CC = ("&DEST_1", "&DEST_2")
SUBJECT = ("MAIL_AUTOM: Proceso Cliente integral &periodo_ant. y &periodo.");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso Cliente integral, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put "periodo        capta_credito     capta_debito     integral     stock_credito"; 
 put "&periodo_ini.  &capta_credito1.   &capta_debito1.   &integral1.   &stock_credito1.";
 put "&periodo2.      &capta_credito2.  &capta_debito2.   &integral2.   &stock_credito2.";
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

proc sql;
drop table cuentas;
;QUIT;
