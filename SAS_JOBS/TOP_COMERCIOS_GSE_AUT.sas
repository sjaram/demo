
%let libreria=result;

PROC  SQL;
CREATE TABLE &libreria..top50_rubros 
(
periodo num,
TIPO_TARJETA char(99),
venta num,
clientes num,
trx num,
Nombre_Comercio char(99),
RUBRO2 char(99),
GSE char(99)
)
;quit;

%MACRO IGNACIO(N, libreria);

DATA _NULL_;
PERIODO = put(intnx('month',today(),-&n.,'end'), yymmn6.);
call symput("periodo",PERIODO);
run;
%put &periodo;

/* LA DEJO FIJA POR SI HAY QUE CAMBIAR */
PROC SQL;
CREATE TABLE GSE AS 
SELECT *
FROM RSEPULV.GSE_ESTIMADO_202203
;QUIT;

PROC SQL;
CREATE TABLE SPOS_TC_ AS
SELECT
"TC" as TIPO_TARJETA,
sum(venta_tarjeta) as venta,
count(distinct A.rut) as clientes,
count(A.rut) as trx,
Nombre_Comercio,	
CASE WHEN coalesce(b.RUBRO1,'Otros Rubros SPOS') in ('SERVICIOS','SERVICIOS BASICOS','TRANSPORTE') THEN 'SERVICIOS'
WHEN coalesce(b.RUBRO1,'Otros Rubros SPOS')  IN ('OTROS COMERCIOS','Otros Rubros SPOS','BELLEZA') THEN 'OTROS COMERCIOS'
WHEN coalesce(b.RUBRO1,'Otros Rubros SPOS')  IN ('VIAJES','ENTRETENCION') THEN 'Viajes&Entretencion'
WHEN coalesce(b.RUBRO1,'Otros Rubros SPOS')  IN ('ALIMENTACION Y FAST FOOD','RESTAURANTES') THEN 'Alimentacion'
WHEN coalesce(b.RUBRO1,'Otros Rubros SPOS')   IN ('RECAUDACION SECTOR PUBLICO','RECAUDACION','INSTITUCIONES FINANCIERAS') THEN 'Recaudacion&Inst_Finan'
ELSE coalesce(b.RUBRO1,'Otros Rubros SPOS')  END AS RUBRO2,
C.GSE
FROM PUBLICIN.SPOS_AUT_&PERIODO. AS A
LEFT JOIN (select
COD_ACT,
max(CATEGORIAS_RIPLEY) as RUBRO1
from sbarrera.TABLA_ARBOL /*Tabla de asignacion de rubros*/
group by
COD_ACT) AS B
ON(A.CODACT=B.COD_ACT)
LEFT JOIN GSE AS C ON (A.RUT=C.RUT)
group by
TIPO_TARJETA,
Nombre_Comercio,	
calculated RUBRO2,
C.GSE
order by calculated venta desc
;quit;


%IF %EVAL(&PERIODO.<202006) %then %DO;

PROC SQL;
CREATE TABLE spos_td3 AS
SELECT 
"TD" as TIPO_TARJETA,
sum(venta_tarjeta) as venta,
count(distinct A.rut) as clientes,
count(A.rut) as trx,
Nombre_Comercio,	
CASE WHEN  coalesce(b.RUBRO_GESTION,'Otros Rubros SPOS') in ('SERVICIOS','SERVICIOS BASICOS','TRANSPORTE') THEN 'SERVICIOS'
WHEN coalesce(b.RUBRO_GESTION,'Otros Rubros SPOS') IN ('OTROS COMERCIOS','Otros Rubros SPOS','BELLEZA') THEN 'OTROS COMERCIOS'
WHEN coalesce(b.RUBRO_GESTION,'Otros Rubros SPOS') IN ('VIAJES','ENTRETENCION') THEN 'Viajes&Entretencion'
WHEN coalesce(b.RUBRO_GESTION,'Otros Rubros SPOS') IN ('ALIMENTACION Y FAST FOOD','RESTAURANTES') THEN 'Alimentacion'
WHEN coalesce(b.RUBRO_GESTION,'Otros Rubros SPOS') IN ('RECAUDACION SECTOR PUBLICO','RECAUDACION','INSTITUCIONES FINANCIERAS') THEN 'Recaudacion&Inst_Finan'
ELSE coalesce(b.RUBRO_GESTION,'Otros Rubros SPOS') END AS RUBRO2,
C.GSE
FROM PUBLICIN.SPOS_MAESTRO_&PERIODO. AS A
LEFT JOIN (
select
input(COD_RUB,best.) as COD_RUB,
max(CATEGORIAS_RIPLEY) as RUBRO_GESTION
from sbarrera.TABLA_ARBOL /*Tabla de asignacion de rubros*/
group by
calculated COD_RUB
) AS B
ON(A.CODACT=B.COD_RUB)
LEFT JOIN GSE AS C ON (A.RUT=C.RUT)
group by
TIPO_TARJETA,
Nombre_Comercio,	
calculated RUBRO2,
C.GSE
order by calculated venta desc
;quit;



%END;
%ELSE %DO;

PROC SQL;
CREATE TABLE SPOS_td1 AS
SELECT 
"TD" as TIPO_TARJETA,
sum(venta_tarjeta) as venta,
count(distinct A.rut) as clientes,
count(A.rut) as trx,
Nombre_Comercio,	
CASE WHEN coalesce(b.RUBRO_GESTION,'Otros Rubros SPOS') in ('SERVICIOS','SERVICIOS BASICOS','TRANSPORTE') THEN 'SERVICIOS'
WHEN coalesce(b.RUBRO_GESTION,'Otros Rubros SPOS') IN ('OTROS COMERCIOS','Otros Rubros SPOS','BELLEZA') THEN 'OTROS COMERCIOS'
WHEN coalesce(b.RUBRO_GESTION,'Otros Rubros SPOS') IN ('VIAJES','ENTRETENCION') THEN 'Viajes&Entretencion'
WHEN coalesce(b.RUBRO_GESTION,'Otros Rubros SPOS') IN ('ALIMENTACION Y FAST FOOD','RESTAURANTES') THEN 'Alimentacion'
WHEN coalesce(b.RUBRO_GESTION,'Otros Rubros SPOS') IN ('RECAUDACION SECTOR PUBLICO','RECAUDACION','INSTITUCIONES FINANCIERAS') THEN 'Recaudacion&Inst_Finan'
ELSE coalesce(b.RUBRO_GESTION,'Otros Rubros SPOS') END AS RUBRO2,
C.GSE
FROM PUBLICIN.SPOS_MAESTRO_&PERIODO. AS A
LEFT JOIN (
select
input(COD_RUB,best.) as COD_RUB,
max(CATEGORIAS_RIPLEY) as RUBRO_GESTION
from sbarrera.TABLA_ARBOL /*Tabla de asignacion de rubros*/
group by
calculated COD_RUB
) AS B
ON(A.CODACT=B.COD_RUB)
LEFT JOIN GSE AS C ON (A.RUT=C.RUT)
group by
TIPO_TARJETA,
Nombre_Comercio,	
calculated RUBRO2,
C.GSE
order by calculated venta desc
;quit;

PROC SQL;
CREATE TABLE SPOS_Td2 AS
SELECT
"TD" as TIPO_TARJETA,
sum(venta_tarjeta) as venta,
count(distinct A.rut) as clientes,
count(A.rut) as trx,
Nombre_Comercio,	
CASE WHEN coalesce(b.RUBRO1,'Otros Rubros SPOS') in ('SERVICIOS','SERVICIOS BASICOS','TRANSPORTE') THEN 'SERVICIOS'
WHEN coalesce(b.RUBRO1,'Otros Rubros SPOS')  IN ('OTROS COMERCIOS','Otros Rubros SPOS','BELLEZA') THEN 'OTROS COMERCIOS'
WHEN coalesce(b.RUBRO1,'Otros Rubros SPOS')  IN ('VIAJES','ENTRETENCION') THEN 'Viajes&Entretencion'
WHEN coalesce(b.RUBRO1,'Otros Rubros SPOS')  IN ('ALIMENTACION Y FAST FOOD','RESTAURANTES') THEN 'Alimentacion'
WHEN coalesce(b.RUBRO1,'Otros Rubros SPOS')  IN ('RECAUDACION SECTOR PUBLICO','RECAUDACION','INSTITUCIONES FINANCIERAS') THEN 'Recaudacion&Inst_Finan'
ELSE coalesce(b.RUBRO1,'Otros Rubros SPOS')  END AS RUBRO2,
C.GSE
FROM PUBLICIN.SPOS_mcd_&PERIODO. AS A
LEFT JOIN (select
COD_ACT,
max(CATEGORIAS_RIPLEY) as RUBRO1
from sbarrera.TABLA_ARBOL /*Tabla de asignacion de rubros*/
group by
COD_ACT) AS B
ON(A.CODACT=B.COD_ACT)
LEFT JOIN GSE AS C ON (A.RUT=C.RUT)
group by
TIPO_TARJETA,
Nombre_Comercio,	
calculated RUBRO2,
C.GSE
order by calculated venta desc
;quit;


proc sql;
create table spos_td3 as
select
*
from SPOS_td1
OUTER UNION CORR
select
*
from SPOS_Td2
;QUIT;


%END;

PROC SQL;
CREATE TABLE SPOS_TC_ AS
SELECT *,
(((VENTA/SUM(venta))*0.4) + ((clientes/SUM(clientes))*0.4) + ((trx/SUM(trx))*0.2)) as RFM
FROM SPOS_TC_
ORDER BY RFM DESC
;QUIT;

PROC SQL;
CREATE TABLE SPOS_TC_ AS
SELECT *,
monotonic() as ind
FROM SPOS_TC_
;QUIT;

PROC SQL;
CREATE TABLE SPOS_TOP100 AS
SELECT *
FROM SPOS_TC_
WHERE IND<=10000
;QUIT;

PROC SQL;
CREATE TABLE SPOS_TOPRESTO AS
SELECT 
TIPO_TARJETA,
sum(venta) AS venta,
sum(clientes) as clientes,
sum(trx) as trx,
"TOTAL" AS Nombre_Comercio,
"TOTAL" AS RUBRO2,
gse
FROM SPOS_TC_
WHERE IND>10000
group by 
TIPO_TARJETA,

gse
;QUIT;

PROC SQL;
CREATE TABLE SPOS_TOP100_FINAL_TC AS
SELECT 
TIPO_TARJETA,
venta,
clientes,
trx,
Nombre_Comercio,
RUBRO2,
gse
FROM SPOS_TOP100
OUTER UNION CORR

SELECT 
TIPO_TARJETA,
venta,
clientes,
trx,
Nombre_Comercio,
RUBRO2,
gse
FROM SPOS_TOPRESTO
;QUIT;

/*
proc sql;
create table ind as 
select 
distinct rubro2 
from 
SPOS_TC_
;QUIT;

proc sql;
create table ind as 
select 
monotonic() as ind,
*
from ind
;QUIT;

proc sql;
create table spos_tc_fin as 
select 
a.*,
b.ind
from SPOS_TC_ as a 
left join ind as b
on(a.rubro2=b.rubro2)
;QUIT;



proc sql noprint;
select 
max(ind) as stop
into:stop
from ind 
;QUIT;


%macro wea1 (stop);

%if (%sysfunc(exist(work.top50_TC))) %then %do;
%end;
%else %do;
PROC  SQL;
CREATE TABLE work.top50_TC 
(
TIPO_TARJETA char(99),
venta num,
clientes num,
trx num,
Nombre_Comercio char(99),
RUBRO2 char(99),
GSE char(99),
ind num

)
;quit;
%end;

%do i=1 %to &stop. ;

proc sql;
create  table paso_ as 
select 
*
from spos_tc_fin
where ind=&i.
order by venta desc 
;QUIT;

proc sql;
create table paso2 as 
select 
*
from paso_
;QUIT;



proc sql;
delete *
from top50_TC
where ind=&i.
;QUIT;

proc sql;
insert into top50_TC
select *
from paso2
;QUIT;


proc sql;
create table top50_TC  as 
select 
*
from top50_TC
;QUIT;
%end;
%mend wea1;
%wea1(&stop);

*/


PROC SQL;
CREATE TABLE spos_td3 AS
SELECT *,
(((VENTA/SUM(venta))*0.4) + ((clientes/SUM(clientes))*0.4) + ((trx/SUM(trx))*0.2)) as RFM
FROM spos_td3
ORDER BY RFM DESC
;QUIT;

PROC SQL;
CREATE TABLE spos_td3 AS
SELECT *,
monotonic() as ind
FROM spos_td3
;QUIT;

PROC SQL;
CREATE TABLE SPOS_TOP100_TD AS
SELECT *
FROM spos_td3
WHERE IND<=10000
;QUIT;

PROC SQL;
CREATE TABLE SPOS_TOPRESTO_TD AS
SELECT 
TIPO_TARJETA,
sum(venta) AS venta,
sum(clientes) as clientes,
sum(trx) as trx,
"TOTAL" AS Nombre_Comercio,
"TOTAL" AS RUBRO2,
gse
FROM spos_td3
WHERE IND>10000
group by 
TIPO_TARJETA,
gse
;QUIT;

PROC SQL;
CREATE TABLE SPOS_TOP100_FINAL_TD AS
SELECT 
TIPO_TARJETA,
venta,
clientes,
trx,
Nombre_Comercio,
RUBRO2,
gse
FROM SPOS_TOP100_TD
OUTER UNION CORR

SELECT 
TIPO_TARJETA,
venta,
clientes,
trx,
Nombre_Comercio,
RUBRO2,
gse
FROM SPOS_TOPRESTO_TD
;QUIT;

/* 
proc sql;
create table ind2 as 
select 
distinct rubro2 
from 
spos_td3
;QUIT;

proc sql;
create table ind2 as 
select 
monotonic() as ind,
*
from ind2
;QUIT;

proc sql;
create table spos_td_fin as 
select 
a.*,
b.ind
from spos_td3 as a 
left join ind2 as b
on(a.rubro2=b.rubro2)
;QUIT;



proc sql noprint;
select 
max(ind) as stop_
into:stop_
from ind2 
;QUIT;


%macro wea2 (stop_);

%if (%sysfunc(exist(work.top50_TD))) %then %do;
%end;
%else %do;
PROC  SQL;
CREATE TABLE work.top50_TD 
(
TIPO_TARJETA char(99),
venta num,
clientes num,
trx num,
Nombre_Comercio char(99),
RUBRO2 char(99),
GSE char(99),
ind num

)
;quit;
%end;

%do i=1 %to &stop_. ;

proc sql;
create  table paso_2 as 
select 
*
from spos_td_fin
where ind=&i.
order by venta desc 
;QUIT;

proc sql inobs=50;
create table paso3 as 
select 
*
from paso_2
;QUIT;



proc sql;
delete *
from top50_TD
where ind=&i.
;QUIT;

proc sql;
insert into top50_TD
select *
from paso3
;QUIT;


proc sql;
create table top50_TD  as 
select 
*
from top50_TD
;QUIT;
%end;
%mend wea2;
%wea2(&stop_);
*/

%if (%sysfunc(exist(&libreria..top50_rubros))) %then %do;
 
%end;
%else %do;
PROC  SQL;
CREATE TABLE &libreria..top50_rubros 
(
periodo num,
TIPO_TARJETA char(99),
venta num,
clientes num,
trx num,
Nombre_Comercio char(99),
RUBRO2 char(99),
GSE char(99)
)
;quit;
%end;


proc sql;
delete *
from &libreria..top50_rubros 
where periodo=&periodo.
;QUIT;

proc sql;
insert into &libreria..top50_rubros
select 
&periodo as periodo,
TIPO_TARJETA,
venta,
clientes,
trx,
Nombre_Comercio,
RUBRO2,
gse
from SPOS_TOP100_FINAL_TC
;QUIT;

proc sql;
insert into &libreria..top50_rubros
select 
&periodo as periodo,
TIPO_TARJETA,
venta,
clientes,
trx,
Nombre_Comercio,
RUBRO2,
gse
from SPOS_TOP100_FINAL_TD
;QUIT;

proc sql;
create table &libreria..top50_rubros  as 
select 
*
from &libreria..top50_rubros 
;QUIT;


LIBNAME ORACLOUD ORACLE sql_functions=all READBUFF=1000 INSERTBUFF=1000 PATH="REPORTSAS.WORLD" SCHEMA=SAS_ADM authdomain=DBOracleCloud_Auth;

%if (%sysfunc(exist(oracloud.iplaza_top50_rubros))) %then %do;

%end;
%else %do;
proc sql;
connect using oracloud;
create table oracloud.iplaza_top50_rubros (
periodo_tableau date,
periodo num,
TIPO_TARJETA char(99),
venta num,
clientes num,
trx num,
Nombre_Comercio char(99),
RUBRO2 char(99),
GSE char(99)
);
disconnect from oracloud;run;
%end;

proc sql;
connect using oracloud;
execute by oracloud ( delete from iplaza_top50_rubros where periodo=&periodo.);
disconnect from oracloud;
;quit;

proc sql;
connect using oracloud;
insert into oracloud.iplaza_top50_rubros (
periodo_tableau ,
periodo,
TIPO_TARJETA,
venta,
clientes,
trx,
Nombre_Comercio,
RUBRO2,
GSE )

select
DHMS(mdy(mod(int((periodo*100+01)/100),100),mod((periodo*100+01),100),int((periodo*100+01)/10000)),0,0,0) as periodo_tableau format=datetime20.,
periodo,
TIPO_TARJETA,
venta,
clientes,
trx,
Nombre_Comercio,
RUBRO2,
GSE
from &Libreria..top50_rubros
/*where periodo=&periodo_actual. */ ;
disconnect from oracloud;run;

%MEND IGNACIO;
%IGNACIO(	0, &Libreria.	);
%IGNACIO(	1, &Libreria.	);
%IGNACIO(	2, &Libreria.	);
%IGNACIO(	3, &Libreria.	);
%IGNACIO(	4, &Libreria.	);
%IGNACIO(	5, &Libreria.	);
%IGNACIO(	6, &Libreria.	);
%IGNACIO(	7, &Libreria.	);
%IGNACIO(	8, &Libreria.	);
%IGNACIO(	9, &Libreria.	);
%IGNACIO(	10, &Libreria.	);
%IGNACIO(	11, &Libreria.	);
%IGNACIO(	12, &Libreria.	);
%IGNACIO(	13, &Libreria.	);
%IGNACIO(	14, &Libreria.	);
%IGNACIO(	15, &Libreria.	);
%IGNACIO(	16, &Libreria.	);
%IGNACIO(	17, &Libreria.	);
%IGNACIO(	18, &Libreria.	);
%IGNACIO(	19, &Libreria.	);
%IGNACIO(	20, &Libreria.	);
%IGNACIO(	21, &Libreria.	);
%IGNACIO(	22, &Libreria.	);
%IGNACIO(	23, &Libreria.	);
%IGNACIO(	24, &Libreria.	);
%IGNACIO(	25, &Libreria.	);
%IGNACIO(	26, &Libreria.	);
%IGNACIO(	27, &Libreria.	);
%IGNACIO(	28, &Libreria.	);
%IGNACIO(	29, &Libreria.	);
%IGNACIO(	30, &Libreria.	);
%IGNACIO(	31, &Libreria.	);
%IGNACIO(	32, &Libreria.	);
%IGNACIO(	33, &Libreria.	);
%IGNACIO(	34, &Libreria.	);
%IGNACIO(	35, &Libreria.	);
%IGNACIO(	36, &Libreria.	);

/* ENVÍO DE CORREO CON MAIL VARIABLE */
proc sql noprint;
SELECT EMAIL into :EDP_BI
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';



SELECT EMAIL into :DEST_1
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';



SELECT EMAIL into :DEST_2
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';



SELECT EMAIL into :DEST_3
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_SPOS_1';



SELECT EMAIL into :DEST_4
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';




quit;



%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;



data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_2","&DEST_4",'mbentjerodts@bancoripley.com',
'bschmidtm@bancoripley.com','crachondode@bancoripley.com')
SUBJECT="MAIL_AUTOM: PROCESO ONBOARDING CAPTACION %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ;
put "Proceso COMERCIOS_SPOS_TOP_100, ejecutado.";
put "Para visualizar Dashboard utilizar el siguiente link:";
put "https://tableau1.bancoripley.cl/#/site/BI_Lab/views/COMERCIOSSPOS/Historia1?:iid=6";
put ;
put 'Vers.4';
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
