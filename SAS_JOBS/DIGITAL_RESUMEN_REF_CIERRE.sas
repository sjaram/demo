/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================    DIGITAL_RESUMEN_REF_CIERRE	 	 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-10-27 -- v04	-- David V.		--  Se agrega nuevo código para export a AWS de tabla resultado
/* 2022-10-24 -- v03	-- Nicolás V.	--  Cambio en librería y se quitan alguna columnas de tabla de paso.
/* 2022-10-21 -- v02	-- David V.		--  Se agregan comentarios y correo de notificación.
/* 2022-10-19 -- v01	-- Nicolás V.	--  Versión Original

/* VARIABLE TIEMPO - INICIO */
%let tiempo_inicio= %sysfunc(datetime());

options validvarname=any;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

%let libreria=RESULT;
/*
%let periodo_actual=202201;
%let periodo_siguiente=202202;
*/

DATA _null_;
periodo_actual = put(intnx('month',today(),-1,'end'),yymmn6.);
primer_dia= put(intnx('month',today(),-1,'begin'),yymmdd10.);
ultimo_dia= put(intnx('month',today(),-1,'end'),yymmdd10.);
ultimo_dia_mes= input(put(intnx('month',today(),-1,'end'),day.),best16.);


Call symput("periodo_actual", periodo_actual);
Call symput("primer_dia", primer_dia);
Call symput("ultimo_dia", ultimo_dia);
Call symput("ultimo_dia_mes", ultimo_dia_mes);
RUN;

%put &periodo_actual;
%put &primer_dia;
%put &ultimo_dia;
%put &ultimo_dia_mes;




/* ESTE PROCESO ARMA UNA TABLA A NIVEL DE RUT CON DISTINTAS MARCAS Y LUEGO SE GENERA UN RESUMEN (curses, simulaciones, visitas, entre otros) */

%put ################################################################;
%put ########    BASE 1 -  LOGUEOS &periodo_actual.      ############;
%put ################################################################;
    
proc sql;
create table WORK.base1   as
select  
RUT, 
day(FECHA_LOGUEO) as dia,
FECHA_LOGUEO FORMAT=date9. AS CREATED_AT,
count(case when upcase(DISPOSITIVO)='APP' then rut end) as VISITA_APP,
count(case when upcase(DISPOSITIVO)='APP_1' then rut end) as VISITA_APP_1,
count(case when upcase(DISPOSITIVO)='CHEK' then rut end) as VISITA_CHEK,
count(case when upcase(DISPOSITIVO)='DESKTOP' then rut end) as VISITA_DESKTOP,
count(case when upcase(DISPOSITIVO)='IFRAME' then rut end) as VISITA_IFRAME,
count(case when upcase(DISPOSITIVO)='MOBILE' then rut end) as VISITA_MOBILE,
count(case when upcase(DISPOSITIVO)='TOTEM' then rut end) as VISITA_TOTEM
from publicin.LOGEO_INT_&periodo_actual.
WHERE RUT IS NOT NULL AND year(FECHA_LOGUEO)*100+month(FECHA_LOGUEO)=&periodo_actual.
group by 
RUT, 
calculated dia,
FECHA_LOGUEO
ORDER BY dia
;quit;

%put #######################################################################;
%put ####        BASE 2 -   OFERTA PWA PARA REF Y RENE                ####;
%put #######################################################################;


proc sql;
create table oferta_REF as 
select 
RUT,
EVAAM_DIA_MOR,
VU_RIESGO,
SALDO_CONTABLE,
SALDO_TOTAL,
RANGO_PROB,
MARCA_PWA
from MGUZMAN.REF_FIN_&periodo_actual.
;QUIT;


proc sql;
CREATE TABLE WORK.BASE2 as
select
A.*,
case when A.RUT = B.RUT THEN 1 ELSE 0 end as OFERTA_REF,
case when A.RUT = B.RUT AND B.MARCA_PWA = 1 THEN 1 ELSE 0 end as OFERTA_REF_PWA,
case when B.RUT IS NOT NULL THEN B.RANGO_PROB end as RANGO_PROB_SAV,
case when B.RUT IS NOT NULL THEN B.SALDO_CONTABLE end as SALDO_CONTABLE,
case when B.RUT IS NOT NULL THEN B.SALDO_TOTAL end as SALDO_TOTAL
FROM WORK.BASE1 A
LEFT JOIN oferta_REF as b
ON(A.RUT = B.RUT)
;QUIT;


%put #######################################################################;
%put ####                   SIMULACION REF PWA                          ####;
%put #######################################################################;


proc sql;
connect to ODBC as myconn (user="ripley-bi" password="biripley00" DATASRC="BR-BACKENDHB");
create table SimulationRefReneView as 
select 
Token,
Rut,
Cuotas,
DeudaSimulada,
Plazo,
InteresMensual,
InteresAnual,
Impuesto,
ValorCuota,
ValorUltimaCuota,
PrimerVencimiento,
CAE,
CostoTotalCredito,
FechaSimulacion,
Dispositivo,
Canal,
Producto,
Comercio,
Sucursal,
Terminal,
TotemID,
PwaVersion
from connection to myconn
(SELECT  *
from SimulationRefReneView
where CAST(FechaSimulacion AS date)BETWEEN %str(%')&primer_dia.%str(%') AND %str(%')&ultimo_dia.%str(%')
);

disconnect from myconn;
quit;


PROC SQL;
CREATE TABLE SIMULATIONREFPWA AS
SELECT 
INPUT(substr(RUT,1,length(RUT)-1),BEST.) as RUT,
day(datepart(FechaSimulacion)) as dia,
datepart(FechaSimulacion) FORMAT=date9. AS FECHA_SIMULACION,

count(case when upcase(Producto)='REF' then rut end)  as SIMULACION_REF,
count(case when upcase(Producto)='RENE' then rut end) as SIMULACION_RENE,

MIN(case when upcase(Producto)='REF' then DeudaSimulada end) as MONTO_MIN_SIM_REF,
MAX(case when upcase(Producto)='REF' then DeudaSimulada end) as MONTO_MAX_SIM_REF,
AVG(case when upcase(Producto)='REF' then DeudaSimulada end) as MONTO_MAX_SIM_REF,

count(case when upcase(DISPOSITIVO)='APP' then rut end) as SIMUL_APP_AVSAV,
count(case when upcase(DISPOSITIVO)='DESKTOP' then rut end) as SIMUL_DESKTOP_AVSAV,
count(case when upcase(DISPOSITIVO)='MOBILE' then rut end) as SIMUL_MOBILE_AVSAV,
count(case when upcase(DISPOSITIVO)='TOTEM' then rut end) as SIMUL_TOTEM_AVSAV,
count(case when upcase(DISPOSITIVO) IS NULL then rut end) as SIMUL_VACIO_AVSAV

FROM SimulationRefReneView
WHERE RUT IS NOT NULL
group by 
calculated RUT, 
calculated dia,
calculated FECHA_SIMULACION
order by dia
;QUIT;


%put #######################################################################;
%put ####            BASE 3 - SIMULACION REF de PWA                ####;
%put #######################################################################;



PROC SQL;
CREATE TABLE WORK.base3 AS
SELECT A.*, 
B.SIMULACION_REF,
B.SIMULACION_RENE,
B.MONTO_MIN_SIM_REF,
B.MONTO_MAX_SIM_REF,
B.MONTO_MAX_SIM_REF,

B.SIMUL_APP_AVSAV,
B.SIMUL_DESKTOP_AVSAV,
B.SIMUL_MOBILE_AVSAV,
B.SIMUL_TOTEM_AVSAV,
B.SIMUL_VACIO_AVSAV

FROM WORK.BASE2 A
LEFT JOIN SIMULATIONREFPWA B
ON A.RUT = B.RUT
AND A.DIA = B.DIA
group by A.RUT,
A.DIA,
A.CREATED_AT
;QUIT;


%put ###################################################################;
%put ####  CURSES REF de PWA   (REVISAR POR QUE HISTORICO)     ####;
%put ###################################################################;


proc sql;
connect to ODBC as myconn (user="ripley-bi" password="biripley00" DATASRC="BR-BACKENDHB");
create table CurseRefReneView as 
select * 
from connection to myconn
(SELECT
Token,
Rut,
FechaCurse,
Cuotas,
DeudaSimulada,
Plazo,
InteresMensual,
InteresAnual,
Impuesto,
ValorCuota,
ValorUltimaCuota,
PrimerVencimiento,
CAE,
CostoTotalCredito,
Dispositivo,
Canal,
Producto,
CAST(FechaCurse AS date) as date
FROM CurseRefReneView
where CAST(FechaCurse AS date) BETWEEN %str(%')&primer_dia.%str(%') AND %str(%')&ultimo_dia.%str(%')
);
disconnect from myconn
;QUIT;


proc sql;
create table CURSE_REFRENE_PWA as 
select 
INPUT(substr(RUT,1,length(RUT)-1),BEST.) as RUT,
day(datepart(FechaCurse)) as dia,
datepart(FechaCurse) FORMAT=date9. AS FECHA_CURSE,
case when upcase(Producto)='REF' then 1 ELSE 0 end as HIZO_CURSE_REF,
case when upcase(Producto)='RENE' then 1 ELSE 0 end as HIZO_CURSE_RENE,

case when upcase(Producto)='REF' then DeudaSimulada end as MONTO_CUR_REF,
case when upcase(Producto)='RENE' then DeudaSimulada end as MONTO_CUR_RENE,

case when upcase(Producto)='REF' then CUOTAS end as CUOTAS_REF,
case when upcase(Producto)='RENE' then CUOTAS end as CUOTAS_RENE,

case when upcase(Producto)='REF' then Plazo end as PLAZO_REF,
case when upcase(Producto)='RENE' then Plazo end as PLAZO_RENE,

case when upcase(DISPOSITIVO)='APP' then rut end as CUR_APP_RENEREF,
case when upcase(DISPOSITIVO)='DESKTOP' then rut end as CUR_DESKTOP_RENEREF,
case when upcase(DISPOSITIVO)='MOBILE' then rut end as CUR_MOBILE_RENEREF,
case when upcase(DISPOSITIVO)='TOTEM' then rut end as CUR_TOTEM_RENEREF,
case when upcase(DISPOSITIVO) IS NULL then rut end as CUR_VACIO_RENEREF

from CurseRefReneView
WHERE RUT IS NOT NULL
group by 
calculated RUT, 
calculated dia,
calculated FECHA_CURSE
order by dia
;QUIT;


%put #######################################################################;
%put ####            BASE 4 - CURSES REF Y RENE de PWA                    ####;
%put #######################################################################;

PROC SQL;
CREATE TABLE WORK.base4 AS
SELECT A.*,
B.HIZO_CURSE_REF,
B.HIZO_CURSE_RENE,

B.MONTO_CUR_REF,
B.MONTO_CUR_RENE,
B.CUOTAS_REF,
B.CUOTAS_RENE,
B.PLAZO_REF,
B.PLAZO_RENE,

B.CUR_APP_RENEREF,
B.CUR_DESKTOP_RENEREF,
B.CUR_MOBILE_RENEREF,
B.CUR_TOTEM_RENEREF,
B.CUR_VACIO_RENEREF

FROM WORK.BASE3 A
LEFT JOIN CURSE_REFRENE_PWA B
ON A.RUT = B.RUT
AND A.DIA = B.DIA
group by A.RUT,
A.DIA,
A.CREATED_AT
;QUIT;

proc sql;
create table trx_ref as 
select rut,'REF' as producto ,capital as DEUDA_SIMULADA,'APP' as DISPOSITIVO,
put(mdy(input(substr(put(fecha_trunc,z8.),5,2),8.),input(substr(put(fecha_trunc,z8.),7,2),8.),input(substr(put(fecha_trunc,z8.),1,4),8.)),date9.) as fecha2,
fecha_trunc
from PUBLICIN.TRX_REF_&periodo_actual.
where via='INTERNET'
;quit;

proc sql;
create table work.trx_no_consideradas as
select a.rut,a.fecha2 as cretead_at,a.deuda_simulada,a.dispositivo,a.producto
from trx_ref a
left join(select * from  WORK.base4 where HIZO_CURSE_REF=1) b
on a.rut=b.rut and a.fecha2=put(b.created_at,date9.)
where b.rut is null and b.created_at is null
;quit;

proc sql;
create table work.base5 as 
select * from work.base4 
union all
select rut,
input(substr(cretead_at,1,2),8.) as dia,
INPUT(cretead_at, DATE9.) as cretead_at,
1 as VISITA_APP,
0 as VISITA_APP_1,
0 as VISITA_CHEK,
0 as VISITA_DESKTOP,
0 as VISITA_IFRAME,
0 as VISITA_MOBILE,
0 as VISITA_TOTEM,
1 as OFERTA_REF,
0 as OFERTA_REF_PWA,
'0' as RANGO_PROB_SAV,
0 as SALDO_CONTABLE,
0 as SALDO_TOTAL,
1 as SIMULACION_REF,
0 as SIMULACION_RENE,
0 as MONTO_MIN_SIM_REF,
0 as MONTO_MAX_SIM_REF,
0 as SIMUL_APP_AVSAV,
0 as SIMUL_DESKTOP_AVSAV,
0 as SIMUL_MOBILE_AVSAV,
0 as SIMUL_TOTEM_AVSAV,
0 as SIMUL_VACIO_AVSAV,
1 as HIZO_CURSE_REF,
0 as HIZO_CURSE_RENE,
deuda_simulada as MONTO_CUR_REF,
0 as MONTO_CUR_RENE,
0 as CUOTAS_REF,
0 as CUOTAS_RENE,
0 as PLAZO_REF,
0 as PLAZO_RENE,
'0' as CUR_APP_RENEREF,
'0' as CUR_DESKTOP_RENEREF,
'0' as CUR_MOBILE_RENEREF,
'0' as CUR_TOTEM_RENEREF,
'0' as CUR_VACIO_RENEREF
from work.trx_no_consideradas
;quit;





%put #######################################################################;
%put ####            BASE 5 - GENERACION TABLA RESUMEN                  ####;
%put #######################################################################;


proc sql;
create table DIGITAL_RENEREF_&periodo_actual. as
select *
from work.base5
;quit;



%put #######################################################################;
%put ####       BASE 6 - GENERACION TABLA ACUMULADO DIARIO               ####;
%put #######################################################################;


%if (%sysfunc(exist(&libreria..DIGITAL_RESUMEN_REF))) %then %do;

%end;
%else %do;

proc sql;
create table &libreria..DIGITAL_RESUMEN_REF
( periodo num,
dia num,
FECHA date,
VISITA_MIX num,
VISITA_WEB num,
oferta_ref num,
oferta_ref_pwa num,

SIMU_REF num,
monto_curse_ref num,
monto_curse_rene num,
trx_curse_ref num,
trx_curse_rene num
)
;QUIT;
%end;

proc sql noprint;
delete *
from &libreria..DIGITAL_RESUMEN_REF
where periodo = &periodo_actual.
;QUIT;



%macro evaluar;

%do i=1 %to &ultimo_dia_mes.;
PROC SQL;
CREATE TABLE WORK.VISTA_DIARIO AS
SELECT 
&periodo_actual. as periodo,
&i. as dia,
MAX(case when year(A.CREATED_AT)*100+month(A.CREATED_AT)=&periodo_actual. THEN A.CREATED_AT end) AS FECHA,
count(distinct case when A.VISITA_APP+A.VISITA_APP_1+A.VISITA_CHEK+A.VISITA_DESKTOP+A.VISITA_IFRAME+A.VISITA_MOBILE+A.VISITA_TOTEM>=1 then A.RUT end ) as VISITA_MIX,
count(distinct case when A.VISITA_DESKTOP + A.VISITA_MOBILE>=1 then A.RUT end) as VISITA_WEB,

count(distinct case when A.OFERTA_REF=1 then A.RUT end )as oferta_ref,
count(distinct case when A.OFERTA_REF_PWA=1 then A.RUT end )as oferta_ref_pwa,

count(distinct case when A.OFERTA_REF=1 and A.SIMULACION_REF>0 then a.rut end )as SIMU_REF,
/*count(distinct case when TIENE_OFERTA_RENE=1 and SIMULACION_RENE>0 then rut end )as SIMU_RENE,*/

sum( case when A.HIZO_CURSE_REF=1  then A.MONTO_CUR_REF end )as monto_curse_ref,
sum( case when A.HIZO_CURSE_RENE=1 then A.MONTO_CUR_RENE end )as monto_curse_rene,

count( case when  A.HIZO_CURSE_REF=1  then A.rut end )as trx_curse_ref,
count( case when  A.HIZO_CURSE_RENE=1 then A.rut end )as trx_curse_rene

FROM DIGITAL_RENEREF_&periodo_actual. A
where A.dia<=&i.
;QUIT;


proc sql noprint;
insert into &libreria..DIGITAL_RESUMEN_REF
select *
from VISTA_DIARIO
;QUIT;

proc sql noprint;
drop table VISTA_DIARIO
;QUIT;
%end;

%mend evaluar;

%evaluar;

%put #######################################################################;
%put ####       NUEVO FLUJO PARA TABLEAU - CON AWS / ATHENA 			####;
%put #######################################################################;
/*==================================================================================================*/
/*== Export a AWS para tableau ==== EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(dgtl_resumen_ref,raw,oracloud,-1);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(dgtl_resumen_ref,&libreria..digital_resumen_ref,raw,oracloud,-1);

/*==================================================================================================*/
/*== Envío correo notificación ==== EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/

data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_DIGITAL';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_DIGITAL_1';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SUBG_BI';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3; %put &=DEST_4;	%put &=DEST_5;	%put &=DEST_6;


/* VARIABLE TIEMPO - FIN */
data _null_;
dur = datetime() - &tiempo_inicio;
put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4", "&DEST_5","&DEST_6")
CC = ("&DEST_1", "&DEST_2", "&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso DIGITAL_RESUMEN_REF_CIERRE");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "		Proceso DIGITAL_RESUMEN_REF_CIERRE, ejecutado con fecha: &fechaeDVN";
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 04'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
