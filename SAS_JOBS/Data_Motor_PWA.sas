
%let libreria=result;

DATA _null_;
%LET N=0;

DATA _null_;
dated2 = input(put(intnx('month',today(),-2-&N.,'begin'),yymmn6. ),$10.) ;
dated1 = input(put(intnx('month',today(),-1-&N.,'begin'),date9. ),$10.) ;
dated0 = input(put(intnx('day',today(),-1-&N.,'same'),date9. ),$10.) ;	
dated_act = input(put(intnx('month',today(),0-&N.,'same'),yymmn6. ),$10.) ;	
dated_ant = input(put(intnx('month',today(),-1-&N.,'same'),yymmn6. ),$10.) ;
ini_mes = input(put(intnx('month',today(),0-&N.,'begin'),date9. ),$10.) ;
fin_mes = input(put(intnx('month',today(),0-&N.,'end'),date9. ),$10.) ;
periodo_actual = put(intnx('month',today(),&N.,'end'),yymmn6.);
primer_dia= put(intnx('month',today(),&N.,'begin'),yymmdd10.);
ultimo_dia= put(intnx('month',today(),&N.,'end'),yymmdd10.);
ultimo_dia_mes= input(put(intnx('month',today(),&N.,'end'),day.),best16.);

	
Call symput("fechad0", dated0);
Call symput("fechad1", dated1);
Call symput("fechad2", dated2);
Call symput("dated_act", dated_act);
Call symput("dated_ant", dated_ant);
Call symput("ini_mes", ini_mes);
Call symput("fin_mes", fin_mes);
Call symput("periodo_actual", periodo_actual);
Call symput("primer_dia", primer_dia);
Call symput("ultimo_dia", ultimo_dia);
Call symput("ultimo_dia_mes", ultimo_dia_mes);
RUN;

%put &fechad1;
%put &fechad0;
%put &fechad2;
%put &dated_act;
%put &dated_ant;
%put &ini_mes;
%put &fin_mes;
%put &periodo_actual;
%put &primer_dia;
%put &ultimo_dia;
%put &ultimo_dia_mes;

LIBNAME libbehb ODBC  DATASRC="BR-BACKENDHB"  SCHEMA=dbo  USER="ripley-bi"  PASSWORD="biripley00"; 


/* Login */

proc sql;
create table WORK.LOG_TOTAL  as
select  RUT, 
FECHA_LOGUEO FORMAT=DATE9. AS CREATED_AT,
count(*) as cantidad_login,
day(FECHA_LOGUEO) as dia
from publicin.LOGEO_INT_&dated_act.
group by rut,FECHA_LOGUEO
;quit;


/* Oferta SAV*/
proc sql;
create table work.oferta_APROBADOS_SAV as
select rut,monto as oferta_sav
from pmunoz.oferta_APROBADOS_SAV_2
where periodo>=year("&fechad1"D)*100+month("&fechad1"D)
;quit;


/* Oferta SAV con Motor */

proc sql;
create table work.oferta_APROBADOS_SAV_2 as
select a.rut,a.oferta_sav, case when b.rut is not null then 1 else 0 end as motor
from work.oferta_APROBADOS_SAV as a
left join jgonzale.rutero_nuevo_flujo_sav as b
on a.rut=input(b.rut,best.)
;quit;

proc sql;
create table work.oferta_APROBADOS_SAV_3 as 
select rut, max(oferta_sav) as oferta_sav,max(motor) as motor
from work.oferta_APROBADOS_SAV_2
group by rut
;quit;

/* Agregamos faltantes de rut de motor */


proc sql;
create table work.oferta_APROBADOS_SAV_4 as 
select input(a.rut,best.) as rut,1 as oferta_sav,1 as motor
from jgonzale.rutero_nuevo_flujo_sav as a
left join work.oferta_APROBADOS_SAV_2 as b
on input(a.rut,best.) = b.rut
where b.rut is null
;quit;


proc sql;
create table work.oferta_APROBADOS_SAV_5 as 
select * from work.oferta_APROBADOS_SAV_3
union all
select * from work.oferta_APROBADOS_SAV_4
;quit;


/* Cruce Login Oferta */

proc sql;
create table work.base_1 as 
select a.CREATED_AT,
a.rut, 
a.dia,
&periodo_actual. as periodo,
case when b.rut is not null then 1 else 0 end as oferta_sav,
case when b.rut is not null then oferta_sav else 0 end as monto_oferta_sav,
case when b.rut is not null then motor else 0 end as oferta_motor
from WORK.LOG_TOTAL as a
left join work.oferta_APROBADOS_SAV_5 as b
on a.rut=b.rut
;quit;

/* Simulación */

proc sql;
create table work.simul_sav as 
select INPUT((SUBSTR(rut,1,(LENGTH(rut)-1))),BEST.) as rut,datepart('Fechasimulación'n)  FORMAT=DATE9.  AS FECHA,montosimulado,token
from LIBBEHB.SIMULATIONAVSAVVIEW 
where datepart('Fechasimulación'n)>= "&ini_mes."d and datepart('Fechasimulación'n)<= "&fin_mes."d and producto='Sav' and rut is not null
;quit;

proc sql;
create table work.simul_sav_oferta as
select a.*
from simul_sav as a
inner join work.oferta_APROBADOS_SAV_5 as b
on a.rut=b.rut
;quit;

proc sql;
create table work.simul_sav_oferta_con_motor as 
select a.rut,a.FECHA,a.montosimulado,
case when c.token is not null then 1 else 0 end as simul_motor,
case when c.token is not null then c.nuevodisponible else 0 end as nuevo_dispo_motor
from simul_sav_oferta AS A
left join LIBBEHB.SAVONLINEENGINEVIEW AS C
on a.token = c.token 
;quit;


proc sql;
create table work.cons_simul as
select rut,fecha,
max(montosimulado) as montosimulado,
max(simul_motor) as simul_motor,
max(nuevo_dispo_motor) as nuevo_dispo_motor
from work.simul_sav_oferta_con_motor
group by rut,fecha
;quit;



/* Cruce simulacion con base1 */

proc sql;
create table work.base_2 as 
select a.*,
case when b.rut is not null   and simul_motor = 0 then 1 else 0 end as simul_normal,
case when b.rut is not null and a.oferta_motor=1 and simul_motor = 0 then 1 else 0 end as simul_sin_motor,
case when b.rut is not null and a.oferta_motor=1 and simul_motor = 1 then 1 else 0 end as simul_motor,
case when b.rut is not null  and simul_motor = 0 then b.montosimulado else 0 end as montosimulado,
case when b.rut is not null and a.oferta_motor=1 and simul_motor = 1 and a.monto_oferta_sav<b.nuevo_dispo_motor then 'Motor oferta mayor'
when b.rut is not null and a.oferta_motor=1 and simul_motor = 1 and a.monto_oferta_sav=b.nuevo_dispo_motor then 'Motor oferta igual'
when b.rut is not null and a.oferta_motor=1 and simul_motor = 1 and a.monto_oferta_sav>b.nuevo_dispo_motor then 'Motor oferta menor' end as clasifiacion_motor,
case when b.rut is not null and a.oferta_motor=1 and simul_motor = 1  then b.nuevo_dispo_motor  else 0 end as nuevo_dispo_motor
from work.base_1 as a
left join work.cons_simul as b
on a.rut=b.rut and a.CREATED_AT=b.fecha
;quit;


/* Curses */

proc sql;
create table curses as 
select distinct A.token,
A.rut,
montoliquido as venta,
case when CodigoSeguro in ('978','979','980') then 1 else 0 end as seguro,
case when c.token is not null and b.rut is not null then 1 else 0 end as paso_por_motor,
datepart(FechaCreacionRegistro) FORMAT=DATE9.  AS fecha_curse
from LIBBEHB.AVSAVVOUCHERVIEWNOLOGIN  AS A
left join jgonzale.rutero_nuevo_flujo_sav as b
on input(substr(a.rut,1,length(a.rut)-1),best.)=input(b.rut,best.) 
left join LIBBEHB.SAVONLINEENGINEVIEW AS C
on a.token = c.token 
where producto = 'SAV' and  datepart(FechaCreacionRegistro) >= "&ini_mes."d and datepart(FechaCreacionRegistro)<= "&fin_mes."d 
;quit;


proc sql;
create table work.base_3 as 
select a.*,
case when b.rut is not null then 1 else 0 end as curse_Sav,
case when b.rut is not null then b.venta end as monto_curse,
case when b.rut is not null then b.seguro end as seguro,
case when b.rut is not null and paso_por_motor=1 and a.monto_oferta_sav<b.venta then 'Motor con curse'
when b.rut is not null and paso_por_motor=1 and a.monto_oferta_sav>=b.venta then 'Motor sin curse'
when b.rut is not null then 'No Motor'
else 'Sin Curse' end as curse_motor
from work.base_2 as a
left join work.curses as b
on a.rut=input(substr(b.rut,1,length(b.rut)-1),best.)  and a.CREATED_AT=b.fecha_curse
;quit;

proc sql;
create table ajuste_venta_faltante as 
select b.*,c.oferta_sav as monto_oferta
from work.curses as b
left join work.base_2 as a
on input(substr(b.rut,1,length(b.rut)-1),best.)=a.rut  and b.fecha_curse=a.CREATED_AT
inner join work.oferta_APROBADOS_SAV_5 as c
on input(substr(b.rut,1,length(b.rut)-1),best.)=c.rut
where a.rut is null
;quit;



proc sql;
create table work.base_4 as 
select *,0 as ajuste_venta from work.base_3
union all
select 
fecha_curse as CREATED_AT,
input(substr(rut,1,length(rut)-1),best.) as rut, 
day(fecha_curse) as dia,
&periodo_actual. as  periodo,
1 as oferta_sav,
monto_oferta as monto_oferta_sav,
0 as oferta_motor,
1 as simul_normal,
0 as simul_sin_motor,
0 as simul_motor,
venta as montosimulado,
'' as clasificacion_motor,
0 as nuevo_dispo_motor,
1 as curse_sav,
venta as monto_curse,
seguro,
'No Motor' as curse_motor,
1 as ajuste_venta
from ajuste_venta_faltante
;quit;


/*   Generar Tabla de Salida     */

proc sql;
create table funnel_motor_&periodo_actual. as 
select * 
from work.base_4
;quit;

/*
proc sql;
drop table &libreria..funnel_motor_&periodo_actual.
;quit;

*/

%if (%sysfunc(exist(&libreria..funnel_motor_&periodo_actual.))) %then %do;

%end;
%else %do;


proc sql;
create table &libreria..funnel_motor_&periodo_actual.
( periodo num,
dia num,
login num,
monto_oferta_sav_t_MM num,
monto_oferta_sav_MM num,
monto_oferta_sav_motor_MM num,
oferta_t num,
oferta_sav num,
oferta_sav_motor num,
simul_t num,
simul_sav num,
simul_sav_sin_motor num,
simul_sav_motor num,
simul_motor_ofe_mayor num,
simul_motor_ofe_igual num,
simul_motor_ofe_menor num,
monto_simul_sav num,
monto_simul_motor num,
curses_sav_t num,
curses_sav num,
curses_sav_motor num,
curses_con_seguro_t num,
curses_con_seguro num,
curses_con_seguro_motor num,
monto_sav_t num,
oferta_sav_t_curse num,
monto_sav num,
oferta_sav_curse num,
monto_sav_motor num,
oferta_sav_curse_motor num

)
;QUIT;
%end;


proc sql;
delete *
from &libreria..funnel_motor_&periodo_actual.
where periodo = &periodo_actual.
;QUIT;



%macro evaluar;

%do i=1 %to &ultimo_dia_mes.;
PROC SQL;
CREATE TABLE WORK.VISTA_DIARIO AS
SELECT 
&periodo_actual. as periodo,
&i. as dia,
count(  distinct rut) as login,
sum(  case when oferta_sav=1 then monto_oferta_sav end )/1000000 as monto_oferta_sav_t_MM ,
sum(  case when oferta_sav=1 and oferta_motor=0 then monto_oferta_sav end )/1000000  as monto_oferta_sav_MM ,
sum(  case when oferta_sav=1 and oferta_motor=1 then monto_oferta_sav end )/1000000  as monto_oferta_sav_motor_MM ,
count( distinct case when oferta_sav=1 then rut end ) as oferta_t,
count( distinct case when oferta_sav=1 and oferta_motor=0 then rut end ) as oferta_sav,
count( distinct case when oferta_motor=1 then rut end ) as oferta_sav_motor,
count( distinct case when oferta_sav=1 and (simul_normal=1 or simul_motor=1)  then rut end ) as simul_t,
count( distinct case when oferta_sav=1 and simul_normal=1 and simul_motor=0  then rut end ) as simul_sav,
count( distinct case when oferta_motor=1 and simul_motor=0 and simul_normal=1 then rut end ) as simul_sav_sin_motor,
count( distinct case when oferta_motor=1 and simul_motor=1  then rut end ) as simul_sav_motor,
count( distinct case when oferta_motor=1 and simul_motor=1 and clasifiacion_motor='Motor oferta mayor' then rut end) as simul_motor_ofe_mayor,
count( distinct case when oferta_motor=1 and simul_motor=1 and clasifiacion_motor='Motor oferta igual' then rut end) as simul_motor_ofe_igual,
count( distinct case when oferta_motor=1 and simul_motor=1 and clasifiacion_motor='Motor oferta menor' then rut end) as simul_motor_ofe_menor,
avg(case when oferta_sav=1 and simul_normal=1 then montosimulado end )  as monto_simul_sav,
avg(case when oferta_motor=1 and simul_motor=1 then nuevo_dispo_motor end )  as monto_simul_motor,
count( distinct case when curse_Sav=1  then rut end) as curses_sav_t,
count( distinct case when curse_Sav=1 and ( curse_motor='No Motor' or  curse_motor='Motor sin curse') then rut end) as curses_sav,
count( distinct case when curse_Sav=1  and curse_motor='Motor con curse' then rut end) as curses_sav_motor,
count( distinct case when curse_Sav=1 and seguro=1  then rut end) as curses_con_seguro_t,
count( distinct case when curse_Sav=1 and seguro=1 and ( curse_motor='No Motor' or  curse_motor='Motor sin curse')  then rut end) as curses_con_seguro,
count( distinct case when curse_Sav=1 and seguro=1 and curse_motor='Motor con curse' then rut end) as curses_con_seguro_motor,
sum(  case when curse_Sav=1  then monto_curse end) as monto_sav_t,
sum(  case when curse_Sav=1  then monto_oferta_sav end ) as oferta_sav_t_curse,
sum(  case when curse_Sav=1 and ( curse_motor='No Motor' or  curse_motor='Motor sin curse') then monto_curse end) as monto_sav,
sum(  case when curse_Sav=1 and ( curse_motor='No Motor' or  curse_motor='Motor sin curse') then monto_oferta_sav end ) as oferta_sav_curse,
sum(  case when curse_Sav=1 and  curse_motor='Motor con curse' then monto_curse end) as monto_sav_motor,
sum(  case when curse_Sav=1 and  curse_motor='Motor con curse' then monto_oferta_sav end ) as oferta_sav_curse_motor


FROM funnel_motor_&periodo_actual. A
where dia<=&i.
;QUIT;


proc sql;
insert into &libreria..funnel_motor_&periodo_actual.
select *
from VISTA_DIARIO
;QUIT;

proc sql;
drop table VISTA_DIARIO
;QUIT;
%end;

%mend evaluar;

%evaluar;

proc sql;
create table work.funnel_motor as 
select periodo,dia,login,round(monto_oferta_sav_t_MM) as monto_oferta_sav_t_MM,round(monto_oferta_sav_MM) as monto_oferta_sav_MM,round(monto_oferta_sav_motor_MM) as monto_oferta_sav_motor_MM,oferta_t,oferta_sav,oferta_sav_motor,simul_t,simul_sav,simul_sav_sin_motor,simul_sav_motor,
simul_motor_ofe_mayor,simul_motor_ofe_igual,simul_motor_ofe_menor,round(monto_simul_sav) as monto_simul_sav,round(monto_simul_motor) as monto_simul_motor,curses_sav_t,
curses_sav,	curses_sav_motor,curses_con_seguro_t,curses_con_seguro,curses_con_seguro_motor,monto_sav_t,oferta_sav_t_curse,monto_sav,oferta_sav_curse,monto_sav_motor,oferta_sav_curse_motor
from &libreria..funnel_motor_&periodo_actual.
;quit;



PROC EXPORT DATA =  work.funnel_motor
OUTFILE="/sasdata/users94/user_bi/unica/input/funnel_motor.csv"
DBMS=dlm REPLACE;
delimiter=';';
PUTNAMES=YES;
RUN;




data _null_;
FILENAME OUTBOX EMAIL
SUBJECT="MAIL_AUTOM: Datos Motor  &fechad0."
FROM = ("equipo_datos_procesos_bi@bancoripley.com")
TO = ("tpiwonkas@bancoripley.com","nverdejog@bancoripley.com","cchamorroc@bancoripley.com","ediazl@bancoripley.com","cperezv@bancoripley.com","mdiaza@bancoripley.com")
 CC      = ("nverdejog@bancoripley.com","rarcosm@bancoripley.com","tpiwonkas@bancoripley.com")
 attach =("/sasdata/users94/user_bi/unica/input/funnel_motor.csv" content_type="excel")
	  Type    = 'Text/Plain';

FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Envio datos correspondientes a Motor de PWA."; 
 put ; 
 put ; 
 PUT ;
PUT 'Atte.';
Put 'Nicolás Verdejo';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

