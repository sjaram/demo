%let n=0;
%let LIBRERIA=RESULT;

DATA _NULL_;
INI = put(intnx('day',intnx('month', today(),-&n.-12,'begin'), 1), date9.);
periodo = input(put(intnx('month',today(),-&n.,'end'),yymmn6. ),$10.);
periodo_ini = input(put(intnx('month',today(),-&n.-12,'end'),yymmn6. ),$10.);
periodo_ant = input(put(intnx('month',today(),-&n.-1,'end'),yymmn6. ),$10.);
fecha = put(intnx('day',intnx('week', today(),-&n,'begin'), 1), date9.);
fecha_ini = put(intnx('day',intnx('week', today(),-&n.-55,  'begin'), 1), date9.);


Call symput("INI", INI);
Call symput("periodo", periodo);
Call symput("periodo_ini", periodo_ini);
Call symput("periodo_ant", periodo_ant);
Call symput("fecha", fecha);
Call symput("fecha_ini", fecha_ini);


RUN;


%put &INI;
%put &periodo;
%put &periodo_INI;
%put &periodo_ant;
%put &fecha;
%put &fecha_ini;





proc sql;
create table captados as 
select 
rut_cliente as rut,
max(year(fecha)*10000+month(fecha)*100+day(fecha)) as Fecha_Capta
from result.capta_salida
where fecha>="&ini."d
and producto in ('TAM','CAMBIO DE PRODUCTO','TAM_CUOTAS','TAM_CERRADA')
group by rut_cliente
;QUIT;

/*                     ACTIVACION EN SPOS                      */

proc sql;
create table spos (
periodo num,
rut num,
codact num,
fecha num,
venta_tarjeta num,
hora char(10)
);QUIT;

%macro spos_apilador;

%do i=0 %to 12;

DATA _NULL_;
periodo_paso = input(put(intnx('month',today(),-&i.,'end'),yymmn6. ),$10.);
Call symput("periodo_paso", periodo_paso);
RUN;

%put &periodo_paso;

proc sql;
create table spos_paso as 
   SELECT  distinct 
rut , 
codact, 
fecha, 
venta_tarjeta, 
hora  
FROM publicin.spos_aut_&periodo_paso. 
;QUIT; 

proc sql;
insert into spos 
select &periodo_paso. as periodo,
*
from spos_paso
;QUIT;

proc sql;
drop table spos_paso
;QUIT;

%end;

%mend spos_APILADOR;

%spos_APILADOR;


proc sql;
create table minima_fecha_spos as select 
a.rut,
min(case when b.rut is not null and a.Fecha>=b.Fecha_Capta then a.fecha end ) as minima_fecha

from spos as a 
inner join captados as b
on(a.rut=b.rut )
group by a.rut 

;quit;

proc sql;
create table minima_hora_spos as select 
a.rut,
a.minima_fecha,
MIN(b.HORA) AS MIN_HORA
from minima_fecha_spos as a
left join spos as b on a.rut=b.rut and a.minima_fecha=b.fecha
group by a.rut, a.minima_fecha 

;quit;
proc sql;
create table primera_compra_spos as select 
a.*,
max(B.venta_tarjeta) as venta
from minima_hora_spos as a
left join spos as b on a.rut=b.rut and a.minima_fecha=b.Fecha and a.MIN_HORA=b.hora
group by a.rut, a.minima_fecha, a.min_hora
;quit;


proc sql;
create table BASE AS SELECT
A.*,
B.MINIMA_FECHA AS FECHA_ACTIVACION_SPOS,
C.EDAD 
FROM captados AS A 
LEFT JOIN primera_compra_spos AS B ON A.RUT=B.RUT
LEFT JOIN PUBLICIN.DEMO_BASKET_&periodo_ant. AS C ON A.RUT=C.RUT
;QUIT;

/*                     ACTIVACION EN TIENDA                       */

proc sql;
create table TDA (
periodo num,
rut num,
fecha date,
capital num
);QUIT;

%macro TDA_APILADOR;

%do i=0 %to 12;

DATA _NULL_;
periodo_paso = input(put(intnx('month',today(),-&i.,'end'),yymmn6. ),$10.);
Call symput("periodo_paso", periodo_paso);
RUN;

%put &periodo_paso;

proc sql;
create table TDA_paso as 
   SELECT  distinct 
rut ,  
fecha, 
CAPITAL  
FROM publicin.tda_itf_&periodo_paso. 
;QUIT; 

proc sql;
insert into TDA 
select &periodo_paso. as periodo,
*
from TDA_paso
;QUIT;

proc sql;
drop table TDA_paso
;QUIT;

%end;

%mend TDA_APILADOR;

%TDA_APILADOR;

proc sql;
create table tda as select
rut,
year(fecha)*10000+month(fecha)*100+day(fecha) as FECHA,
capital as monto
from tda

;quit;
proc sql;
create table minima_fecha_tda as select
a.rut,
min(case when b.rut is not null and a.FECHA>=b.FECHA_CAPTA then a.FECHA end ) as fecha

from TDA as a 
inner join CAPTADOS as b
on(a.rut=b.rut )
group by a.rut 

;quit;
proc sql;
create table primera_compra_tda as select
a.*,
max(b.monto) as monto
from minima_fecha_tda as a
left join tda as b on a.rut=b.rut and a.fecha=b.FECHA
where B.monto>1
group by a.rut, a.fecha
;quit; 
PROC SQL;
CREATE TABLE BASE1 AS SELECT 
A.*,
B.fecha AS FECHA_ACTIVACION_TDA
FROM BASE AS A
LEFT JOIN PRIMERA_COMPRA_TDA AS B ON A.RUT=B.RUT
;QUIT;

/*                     CONSTRUCCION DASHBOARD            */
/*                   CAMBIO FORMATO A FECHA SAS          */
proc sql;
create table BASE2 as select
RUT, 
mdy(mod(int(fecha_capta/100),100),mod(fecha_capta,100),int(fecha_capta/10000)) format=date9. as fecha_capta,
mdy(mod(int(FECHA_ACTIVACION_SPOS/100),100),mod(FECHA_ACTIVACION_SPOS,100),int(FECHA_ACTIVACION_SPOS/10000)) format=date9. as FECHA_ACTIVACION_SPOS,
mdy(mod(int(FECHA_ACTIVACION_tda/100),100),mod(FECHA_ACTIVACION_tda,100),int(FECHA_ACTIVACION_tda/10000)) format=date9. as FECHA_ACTIVACION_tienda,
edad
FROM BASE1
;QUIT;

/*                AGRUPACION DE VARIABLES        */
proc sql;
create table BASE3 as select 
*,
CASE WHEN  intck('DAY',FECHA_CAPTA,FECHA_ACTIVACION_spos,'D') BETWEEN 0 AND 30 THEN '<=30 DIAS'
WHEN intck('DAY',FECHA_CAPTA,FECHA_ACTIVACION_spos,'D') BETWEEN 31 AND 60 THEN '<=60 DIAS'
WHEN intck('DAY',FECHA_CAPTA,FECHA_ACTIVACION_spos,'D') BETWEEN 61 AND 90 THEN '<=90 DIAS'
WHEN FECHA_ACTIVACION_spos IS NULL THEN 'NO ACTIVO'
WHEN intck('DAY',FECHA_CAPTA,FECHA_ACTIVACION_spos,'D')>90 THEN '+90 DIAS' END AS CONCRECION_SPOS,

CASE WHEN  intck('DAY',FECHA_CAPTA,FECHA_ACTIVACION_tienda,'D') BETWEEN 0 AND 30 THEN '<=30 DIAS'
WHEN intck('DAY',FECHA_CAPTA,FECHA_ACTIVACION_tienda,'D') BETWEEN 31 AND 60 THEN '<=60 DIAS'
WHEN intck('DAY',FECHA_CAPTA,FECHA_ACTIVACION_tienda,'D') BETWEEN 61 AND 90 THEN '<=90 DIAS'
WHEN FECHA_ACTIVACION_tienda IS NULL THEN 'NO ACTIVO'
WHEN intck('DAY',FECHA_CAPTA,FECHA_ACTIVACION_tienda,'D')>90 THEN '+90 DIAS' END AS CONCRECION_TDA,
(INTCK('WEEK',FECHA_CAPTA,"&FECHA_INI."d,'D'))*-1 AS SEMANA_CAPTA_numero,
(INTCK('WEEK',FECHA_ACTIVACION_spos,"&FECHA_INI."d,'D'))*-1 AS SEMANA_ACTIVACION_SPOS,
(INTCK('WEEK',FECHA_ACTIVACION_TIENDA,"&FECHA_INI."d,'D'))*-1 AS SEMANA_ACTIVACION_TDA, 
case when weekday(FECHA_CAPTA)=2 then FECHA_CAPTA
when weekday(FECHA_CAPTA) between 3 and 7 then intnx('day',FECHA_CAPTA,-(weekday(FECHA_CAPTA)-2))
when weekday(FECHA_CAPTA)=1 then intnx('day',FECHA_CAPTA,-6) end format=date9. as semana_captacion,
CASE when EDAD < 35 then '1. Joven'
    when EDAD < 45 then '2. Adulto 1'
    when EDAD < 60 then '3. Adulto 2'
    ELSE  '4. Mayor' end as RangoEtario,
put(intnx('day',intnx('week', FECHA_CAPTA,0,'begin'), 1), ddmmyy10.) AS SEMANA_CAPTA_char,
put(intnx('day',intnx('week', FECHA_ACTIVACION_spos,0,'begin'), 1), ddmmyy10.) AS SEMANA_ACTIVACION_SPOS_char,
put(intnx('day',intnx('week', FECHA_ACTIVACION_tienda,0,'begin'), 1), ddmmyy10.) AS SEMANA_ACTIVACION_TDA_char



FROM BASE2
;QUIT;


proc sql;
create table BASE4 as 
select 
a.semana_captacion,
'Tienda' as canal,
a.CONCRECION_TDA as concrecion,
a.cantidad,
b.cantidad as cantidad_cum

from  (select 
semana_captacion,
CONCRECION_TDA,
count(rut) as cantidad
from BASE3 group by 
semana_captacion,
CONCRECION_TDA) as a
left join (select 
semana_captacion,
count(rut) as cantidad
from BASE3 group by 

semana_captacion) as b
on(a.semana_captacion=b.semana_captacion) 
;QUIT;


proc sql;
create table BASE5 as 
select 
a.semana_captacion,
'SPOS' as canal,
a.CONCRECION_SPOS as concrecion,
a.cantidad,
b.cantidad as cantidad_cum

from  (select 
semana_captacion,
CONCRECION_SPOS,
count(rut) as cantidad
from BASE3 group by 
semana_captacion,
CONCRECION_SPOS) as a
left join (select 
semana_captacion,
count(rut) as cantidad
from BASE3 group by 

semana_captacion) as b
on(a.semana_captacion=b.semana_captacion) 
;QUIT;


/* TABLA 1 */


PROC SQL;
CREATE TABLE &LIBRERIA..SPOS_DB_CONCRECION_1 AS SELECT 
*,
(CANTIDAD/CANTIDAD_CUM) AS PORCENTAJE
FROM BASE4 
OUTER UNION CORR SELECT 
*,
(CANTIDAD/CANTIDAD_CUM) AS PORCENTAJE
FROM BASE5
;QUIT;
PROC SQL;
CREATE TABLE &LIBRERIA..SPOS_DB_CONCRECION_1 AS SELECT
PUT(semana_captacion,e8601da.) AS SEMANA_CAPTACION,
canal,
concrecion,
cantidad,
cantidad_cum,
PORCENTAJE 
FROM &LIBRERIA..SPOS_DB_CONCRECION_1
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(SPOS_DB_CONCRECION_UNO,raw,oracloud,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(SPOS_DB_CONCRECION_UNO,&libreria..SPOS_DB_CONCRECION_1,raw,oracloud,0);

/* TABLA 2 */

proc sql;
create table BASE6 as 
select 
a.SEMANA_CAPTA_char,
a.SEMANA_ACTIVACION_SPOS_char,
a.SEMANA_CAPTA_numero,
a.SEMANA_ACTIVACION_SPOS,
'SPOS' AS CANAL,
a.cantidad,
b.cantidad as cantidad_cum

from  (select 
SEMANA_CAPTA_char,
SEMANA_ACTIVACION_SPOS_char,
SEMANA_CAPTA_numero,
SEMANA_ACTIVACION_SPOS,
count(rut) as cantidad
from BASE3 group by 
SEMANA_CAPTA_char,
SEMANA_ACTIVACION_SPOS_char,
SEMANA_CAPTA_numero,
SEMANA_ACTIVACION_SPOS) as a
left join (select 
SEMANA_CAPTA_numero,
count(rut) as cantidad
from BASE3 group by 

SEMANA_CAPTA_numero) as b
on(a.SEMANA_CAPTA_numero=b.SEMANA_CAPTA_numero) 
;QUIT;

proc sql;
create table BASE7 as 
select 
a.SEMANA_CAPTA_char,
a.SEMANA_ACTIVACION_TDA_char,
a.SEMANA_CAPTA_numero,
a.SEMANA_ACTIVACION_TDA,
'TIENDA' AS CANAL,
a.cantidad,
b.cantidad as cantidad_cum

from  (select 
SEMANA_CAPTA_char,
SEMANA_ACTIVACION_TDA_char,
SEMANA_CAPTA_numero,
SEMANA_ACTIVACION_TDA,
count(rut) as cantidad
from BASE3 group by SEMANA_CAPTA_char,
SEMANA_ACTIVACION_TDA_char,
SEMANA_CAPTA_numero,
SEMANA_ACTIVACION_TDA) as a
left join (select 
SEMANA_CAPTA_numero,
count(rut) as cantidad
from BASE3 group by 

SEMANA_CAPTA_numero) as b
on(a.SEMANA_CAPTA_numero=b.SEMANA_CAPTA_numero) 
;QUIT;


PROC SQL;
CREATE TABLE &LIBRERIA..SPOS_DB_CONCRECION_2 AS SELECT 
*,
(CANTIDAD/CANTIDAD_CUM) AS PORCENTAJE
FROM (select * from BASE6 where SEMANA_CAPTA_numero>1) 
OUTER UNION CORR SELECT 
*,
(CANTIDAD/CANTIDAD_CUM) AS PORCENTAJE
FROM (select * from BASE7 where SEMANA_CAPTA_numero>1)
;QUIT;

/*borrar todas las tablas del work, tener cuidado con tablas internas si no borrara toda la libreria*/
proc datasets library=WORK kill noprint;
run;
quit;


%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(SPOS_DB_CONCRECION_DOS,raw,oracloud,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(SPOS_DB_CONCRECION_DOS,&libreria..SPOS_DB_CONCRECION_2,raw,oracloud,0);

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
'mbentjerodts@bancoripley.com','bschmidtm@bancoripley.com','caimoneb@bancoripley.com',
'kgonzalezi@bancoripley.com')
SUBJECT="MAIL_AUTOM: PROCESO CONCRECIÓN SEMANAL %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso PROCESO CONCRECIÓN SEMANAL, ejecutado.";  
 put "Para visualizar Dashboard utilizar el siguiente link:"; 
 put "https://tableau1.bancoripley.cl/#/site/BI_Lab/views/ConcrecinPorcamadasDigiventure/Historia1?:iid=1";
 put ;
 put 'Vers.2'; 
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
