/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	KPI_INTERNET					 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-07-12 -- V05-- Sergio J. -- Se agrega código de exportación para alimentar a Tableau
/* 2022-07-01 -- V04-- David V.  -- Actualización password nuevo backend pwa + correo del jefe digital bi

/* INFORMACIÓN:
	Programa que...

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/


/**MACRO FECHAS Y LIBRERIA PARA PROCESO AUTOMATICO */
/**ACT DVN 20220413*/

%let libreria=publicin;

/*
%let periodo_actual=202201;
%let periodo_siguiente=202202;*/

options validvarname=any;

DATA _null_;
periodo_actual = put(intnx('month',today(),0,'end'),yymmn6.);
periodo_siguiente = input(put(intnx('month',today(),1,'end'),yymmn6.),$10.);
primer_dia= put(intnx('month',today(),0,'begin'),yymmdd10.);
ultimo_dia= put(intnx('month',today(),0,'end'),yymmdd10.);

primer_dia_mes= put(intnx('month',today(),0,'begin'),day.);
ultimo_dia_mes= put(intnx('month',today(),0,'end'),day.);

Call symput("periodo_actual", periodo_actual);
Call symput("periodo_siguiente", periodo_siguiente);
Call symput("primer_dia", primer_dia);
Call symput("ultimo_dia", ultimo_dia);
Call symput("primer_dia_mes", primer_dia_mes);
Call symput("ultimo_dia_mes", ultimo_dia_mes);

RUN;

%put &periodo_actual;
%put &periodo_siguiente;
%put &primer_dia;
%put &ultimo_dia;
%put &periodo_siguiente;
%put &primer_dia_mes;
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
FECHA_LOGUEO FORMAT=DATE9. AS CREATED_AT,
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
%put ####      BASE 2 -   OFERTA PWA PARA SAV, AV Y CONSUMO             ####;
%put #######################################################################;


%if (%sysfunc(exist(jaburtom.sav_fin_&periodo_siguiente.))) %then %do;

proc sql;
create table oferta_sav as 
select 
rut_real,
monto_para_canon,
RANGO_PROB,
SAV_APROBADO_FINAL
from jaburtom.sav_fin_&periodo_actual.
union 
select 
rut_real,
monto_para_canon,
RANGO_PROB,
SAV_APROBADO_FINAL
from jaburtom.sav_fin_&periodo_siguiente.
where rut_real not in (select rut_real from jaburtom.sav_fin_&periodo_actual.)
;QUIT;
 %end;
%else %do;
proc sql;
create table oferta_sav as 
select 
rut_real,
monto_para_canon,
RANGO_PROB,
SAV_APROBADO_FINAL
from jaburtom.sav_fin_&periodo_actual.
;QUIT;
%end;

%if (%sysfunc(exist(kmartine.avance_&periodo_siguiente.))) %then %do;

proc sql;
create table oferta_av as 
select 
rut_registro_civil,
AVANCE_FINAL,
RANGO_PROB
from kmartine.avance_&periodo_actual.
union 
select 
rut_registro_civil,
AVANCE_FINAL,
RANGO_PROB
from kmartine.avance_&periodo_siguiente.
where rut_registro_civil not in (select rut_registro_civil from kmartine.avance_&periodo_actual.)
;QUIT;
 %end;
%else %do;
proc sql;
create table oferta_av as 
select 
rut_registro_civil,
AVANCE_FINAL,
RANGO_PROB
from kmartine.avance_&periodo_actual.
;QUIT;
%end;

%if (%sysfunc(exist(JABURTOM.OFERTA_CONS_ONLINE_&periodo_siguiente. ))) %then %do;

proc sql;
create table oferta_consumo as 
SELECT RUT,MAX(MONTO_OFERTA) AS MONTO_OFERTA 
FROM JABURTOM.OFERTA_CONS_ONLINE_&periodo_ACTUAL. 
GROUP BY RUT
union 
SELECT RUT,MAX(MONTO_OFERTA) AS MONTO_OFERTA 
FROM JABURTOM.OFERTA_CONS_ONLINE_&periodo_ACTUAL. 
where rut not in (select rut from JABURTOM.OFERTA_CONS_ONLINE_&periodo_ACTUAL. )
GROUP BY RUT
;QUIT;
 %end;
%else %do;
proc sql;
create table oferta_consumo as 
SELECT RUT,MAX(MONTO_OFERTA) AS MONTO_OFERTA 
FROM JABURTOM.OFERTA_CONS_ONLINE_&periodo_ACTUAL. 
GROUP BY RUT
;QUIT;
%end;

proc sql;
CREATE TABLE WORK.BASE2 as
select
A.*,
case when B.SAV_APROBADO_FINAL=1 THEN 1 ELSE 0 end as TIENE_OFERTA_SAV,
case when B.SAV_APROBADO_FINAL=1 THEN B.monto_para_canon end as MONTO_OFERTA_SAV,
case when B.SAV_APROBADO_FINAL=1 THEN B.RANGO_PROB end as RANGO_PROB_SAV,
case when C.RUT_REGISTRO_CIVIL IS NOT NULL THEN 1 ELSE 0 end as TIENE_OFERTA_AV,
case when C.RUT_REGISTRO_CIVIL IS NOT NULL THEN C.AVANCE_FINAL end as MONTO_OFERTA_AV,
case when C.RUT_REGISTRO_CIVIL IS NOT NULL THEN C.RANGO_PROB end as RANGO_PROB_AV,
case when D.RUT IS NOT NULL THEN 1 ELSE 0 end as TIENE_OFERTA_cons,
case when D.RUT IS NOT NULL THEN D.MONTO_OFERTA end as MONTO_OFERTA_cons

FROM WORK.BASE1 A
LEFT JOIN  oferta_sav as b
ON(A.RUT = B.RUT_REAL)
LEFT JOIN oferta_av C
ON(A.RUT = C.rut_registro_civil)
LEFT JOIN  oferta_consumo D
ON(A.RUT = D.RUT)
;QUIT;


%put #######################################################################;
%put ####                 SIMULACION AV Y SAV de PWA                    ####;
%put #######################################################################;


proc sql;
connect to ODBC as myconn (user="ripley-bi" password="biripley00"
DATASRC="BR-BACKENDHB"
);
create table SIMULATIONAVSAVPWA as 
select RUT,
FechaSimulación,
Producto,
Cuotas,
DISPOSITIVO,
MontoSimulado,
CostoTotal,
PrecioSeguro
from connection to myconn
(SELECT  *
from SIMULATIONAVSAVVIEW
where CAST(FechaSimulación AS date)BETWEEN %str(%')&primer_dia.%str(%') AND %str(%')&ultimo_dia.%str(%')
);

disconnect from myconn;
quit;



PROC SQL;
CREATE TABLE SIMULATIONAVSAVPWA_2 AS
SELECT 
INPUT(substr(RUT,1,length(RUT)-1),BEST.) as RUT,
day(datepart(FechaSimulación)) as dia,
datepart(FechaSimulación) FORMAT=date9. AS FECHA_SIMULACION,

count(case when upcase(Producto)='AV' then rut end)  as SIMULACION_AV,
count(case when upcase(Producto)='SAV' then rut end) as SIMULACION_SAV,

MIN(case when upcase(Producto)='AV' then MontoSimulado end) as MONTO_MIN_SIM_AV,
MAX(case when upcase(Producto)='AV' then MontoSimulado end) as MONTO_MAX_SIM_AV,

MIN(case when upcase(Producto)='SAV' then MontoSimulado end) as MONTO_MIN_SIM_SAV,
MAX(case when upcase(Producto)='SAV' then MontoSimulado end) as MONTO_MAX_SIM_SAV,

count(case when upcase(DISPOSITIVO)='APP' then rut end) as SIMUL_APP_AVSAV,
count(case when upcase(DISPOSITIVO)='APP_1' then rut end) as SIMUL_APP_1_AVSAV,
count(case when upcase(DISPOSITIVO)='CHEK' then rut end) as SIMUL_CHEK_AVSAV,
count(case when upcase(DISPOSITIVO)='DESKTOP' then rut end) as SIMUL_DESKTOP_AVSAV,
count(case when upcase(DISPOSITIVO)='IFRAME' then rut end) as SIMUL_IFRAME_AVSAV,
count(case when upcase(DISPOSITIVO)='MOBILE' then rut end) as SIMUL_MOBILE_AVSAV,
count(case when upcase(DISPOSITIVO)='TOTEM' then rut end) as SIMUL_TOTEM_AVSAV,
count(case when upcase(DISPOSITIVO) IS NULL then rut end) as SIMUL_VACIO_AVSAV,

COUNT(case when PrecioSeguro >= 1 and upcase(Producto)='AV' then PrecioSeguro end) as CANT_SIM_SEGURO_AV,
COUNT(case when PrecioSeguro >= 1 and upcase(Producto)='SAV' then PrecioSeguro end) as CANT_SIM_SEGURO_SAV,

MIN(case when PrecioSeguro >= 1 and upcase(Producto)='AV' then PrecioSeguro end) as MIN_SIM_SEGURO_AV,
MAX(case when PrecioSeguro >= 1 and upcase(Producto)='AV' then PrecioSeguro end) as MAX_SIM_SEGURO_AV,
AVG(case when PrecioSeguro >= 1 and upcase(Producto)='AV' then PrecioSeguro end) as PROM_SIM_SEGURO_AV,

MIN(case when PrecioSeguro >= 1 and upcase(Producto)='SAV' then PrecioSeguro end) as MIN_SIM_SEGURO_SAV,
MAX(case when PrecioSeguro >= 1 and upcase(Producto)='SAV' then PrecioSeguro end) as MAX_SIM_SEGURO_SAV,
AVG(case when PrecioSeguro >= 1 and upcase(Producto)='SAV' then PrecioSeguro end) as PROM_SIM_SEGURO_SAV


FROM SIMULATIONAVSAVPWA
WHERE RUT IS NOT NULL
group by 
calculated RUT, 
calculated dia,
calculated FECHA_SIMULACION
order by dia
;QUIT;

%put #######################################################################;
%put ####            BASE 3 - SIMULACION AV Y SAV de PWA                ####;
%put #######################################################################;


PROC SQL;
CREATE TABLE WORK.base3 AS
SELECT A.*, 
B.SIMULACION_AV,
B.SIMULACION_SAV,
B.MONTO_MIN_SIM_AV,
B.MONTO_MAX_SIM_AV,
B.MONTO_MIN_SIM_SAV,
B.MONTO_MAX_SIM_SAV,
B.SIMUL_APP_AVSAV,
B.SIMUL_APP_1_AVSAV,
B.SIMUL_CHEK_AVSAV,
B.SIMUL_DESKTOP_AVSAV,
B.SIMUL_IFRAME_AVSAV,
B.SIMUL_MOBILE_AVSAV,
B.SIMUL_TOTEM_AVSAV,
B.CANT_SIM_SEGURO_AV,
B.CANT_SIM_SEGURO_SAV,
B.MIN_SIM_SEGURO_AV,
B.MAX_SIM_SEGURO_AV,
B.PROM_SIM_SEGURO_AV,
B.MIN_SIM_SEGURO_SAV,
B.MAX_SIM_SEGURO_SAV,
B.PROM_SIM_SEGURO_SAV
FROM WORK.BASE2 A
LEFT JOIN SIMULATIONAVSAVPWA_2 B
ON A.RUT = B.RUT
AND A.DIA = B.DIA
group by A.RUT,
A.DIA,
A.CREATED_AT
;QUIT;




%put ###################################################################;
%put ####  CURSES AV Y SAV de PWA   (REVISAR POR QUE HISTORICO)     ####;
%put ###################################################################;


proc sql;
connect to ODBC as myconn (user="ripley-bi" password="biripley00" DATASRC="BR-BACKENDHB");
create table PWA as 
select * 
from connection to myconn
(SELECT
RUT,
MONTOLIQUIDO ,
PRODUCTO,
numoperacion, 
DISPOSITIVO,
numoperacion,
TasaMensual,
Cuotas,
FECHACURSE,
PRECIOSEGURO,
CAST(FECHACURSE AS date) as date
FROM AVSAVVOUCHERVIEW
where CAST(FECHACURSE AS date) BETWEEN %str(%')&primer_dia.%str(%') AND %str(%')&ultimo_dia.%str(%')
);
disconnect from myconn
;QUIT;

 
proc sql;
create table CURSE_AVSAV_PWA as 
select 
INPUT(substr(RUT,1,length(RUT)-1),BEST.) as RUT,
day(datepart(FECHACURSE)) as dia,
datepart(FECHACURSE) FORMAT=date9. AS FECHA_CURSE,
case when upcase(Producto)='AV' then 1 ELSE 0 end as HIZO_CURSE_AV,
case when upcase(Producto)='SAV' then 1 ELSE 0 end as HIZO_CURSE_SAV,

case when upcase(Producto)='AV' then MONTOLIQUIDO end as MONTO_CUR_AV,
case when upcase(Producto)='SAV' then MONTOLIQUIDO end as MONTO_CUR_SAV,

case when upcase(Producto)='AV' then PRECIOSEGURO end as PRECIO_SEGURO_CUR_AV,
case when upcase(Producto)='SAV' then PRECIOSEGURO end as PRECIO_SEGURO_CUR_SAV,

case when upcase(DISPOSITIVO)='APP' then rut end as CUR_APP_AVSAV,
case when upcase(DISPOSITIVO)='APP_1' then rut end as CUR_APP_1_AVSAV,
case when upcase(DISPOSITIVO)='CHEK' then rut end as CUR_CHEK_AVSAV,
case when upcase(DISPOSITIVO)='DESKTOP' then rut end as CUR_DESKTOP_AVSAV,
case when upcase(DISPOSITIVO)='IFRAME' then rut end as CUR_IFRAME_AVSAV,
case when upcase(DISPOSITIVO)='MOBILE' then rut end as CUR_MOBILE_AVSAV,
case when upcase(DISPOSITIVO)='TOTEM' then rut end as CUR_TOTEM_AVSAV,
case when upcase(DISPOSITIVO) IS NULL then rut end as CUR_VACIO_AVSAV

from pwa
WHERE RUT IS NOT NULL
group by 
calculated RUT, 
calculated dia,
calculated FECHA_CURSE
order by dia
;QUIT;

%put #######################################################################;
%put ####            BASE 4 - CURSES AV Y SAV de PWA                    ####;
%put #######################################################################;

PROC SQL;
CREATE TABLE WORK.base4 AS
SELECT A.*,
B.HIZO_CURSE_AV,
B.HIZO_CURSE_SAV, 
B.MONTO_CUR_AV,
B.MONTO_CUR_SAV,
B.PRECIO_SEGURO_CUR_AV,
B.PRECIO_SEGURO_CUR_SAV,
B.CUR_APP_AVSAV,
B.CUR_APP_1_AVSAV,
B.CUR_CHEK_AVSAV,
B.CUR_DESKTOP_AVSAV,
B.CUR_IFRAME_AVSAV,
B.CUR_MOBILE_AVSAV,
B.CUR_TOTEM_AVSAV,
B.CUR_VACIO_AVSAV
FROM WORK.BASE3 A
LEFT JOIN CURSE_AVSAV_PWA B
ON A.RUT = B.RUT
AND A.DIA = B.DIA
group by A.RUT,
A.DIA,
A.CREATED_AT
;QUIT;



%put ############################################################;
%put ####          SIMULACIONES DE CONSUMO DE PWA            ####;
%put ############################################################;

proc sql;
connect to ODBC as myconn (user="ripley-bi" password="biripley00" DATASRC="BR-BACKENDHB");
create table SIMULACION_CONSUMO_PWA as 
select * 
from connection to myconn
(SELECT
Rut,
Producto,
MontoLiquido,
FechaSimulacion,
Cuotas,
ValorCuota,
InteresMensual,
CAE,
CostoTotal,
ITE,
GastosNotariales,
MontoBruto,
PrimerVencimiento,
DiasDiferidos,
SeguroDesgravamen,
SeguroVida,
Canal,
Dispositivo,
Comercio,
Sucursal,
Terminal,
TotemID,
Origen,
DisponibleConsumo,
CAST(FechaSimulacion AS date) as date
FROM SimulationPersonalLoanView
where CAST(FechaSimulacion AS date) BETWEEN %str(%')&primer_dia.%str(%') AND %str(%')&ultimo_dia.%str(%') 
);
disconnect from myconn
;QUIT;


PROC SQL;
CREATE TABLE SIMS_CONSUMO AS 
SELECT INPUT((SUBSTR(rut,1,(LENGTH(rut)-1))),BEST.) as RUT, 
day(datepart(FechaSimulacion)) as dia,
datepart(FechaSimulacion) format=date9. as FECHA,
count(case when upcase(Producto)='CONSUMO' then rut end) as SIMUL_CONSUMO,
MIN(case when upcase(Producto)='CONSUMO' then MONTOLIQUIDO end) as MONTO_MIN_SIM_CONSUMO,
MAX(case when upcase(Producto)='CONSUMO' then MONTOLIQUIDO end) as MONTO_MAX_SIM_CONSUMO,

count(case when upcase(Producto)='CONSUMO' then SeguroVida end) as SEGUROVIDA_SIM_CONSUMO,
count(case when upcase(Producto)='CONSUMO' then SeguroDesgravamen end) as SEGURODESGRAVAMEN_SIM_CONSUMO,

MIN(case when upcase(Producto)='CONSUMO' then SeguroVida end) as MIN_SEGVIDA_SIM_CONSUMO,
MAX(case when upcase(Producto)='CONSUMO' then SeguroVida end) as MAX_SEGVIDA_SIM_CONSUMO,
AVG(case when upcase(Producto)='CONSUMO' then SeguroVida end) as PROM_SEGVIDA_SIM_CONSUMO,

MIN(case when upcase(Producto)='CONSUMO' then SeguroDesgravamen end) as MIN_SEGDESGRA_SIM_CONSUMO,
MAX(case when upcase(Producto)='CONSUMO' then SeguroDesgravamen end) as MAX_SEGDESGRA_SIM_CONSUMO,
AVG(case when upcase(Producto)='CONSUMO' then SeguroDesgravamen end) as PROM_SEGDESGRA_SIM_CONSUMO,

count(case when upcase(Dispositivo)='APP' then rut end) as SIMUL_APP_CONS,
count(case when upcase(Dispositivo)='APP_1' then rut end) as SIMUL_APP_1_CONS,
count(case when upcase(Dispositivo)='CHEK' then rut end) as SIMUL_CHEK_CONS,
count(case when upcase(Dispositivo)='DESKTOP' then rut end) as SIMUL_DESKTOP_CONS,
count(case when upcase(Dispositivo)='IFRAME' then rut end) as SIMUL_IFRAME_CONS,
count(case when upcase(Dispositivo)='MOBILE' then rut end) as SIMUL_MOBILE_CONS,
count(case when upcase(Dispositivo)='TOTEM' then rut end) as SIMUL_TOTEM_CONS,
count(case when upcase(Dispositivo) IS NULL then rut end) as SIMUL_VACIO_CONS


FROM SIMULACION_CONSUMO_PWA
WHERE RUT is not NULL
group by 
calculated RUT, 
calculated dia,
calculated fecha
;QUIT;

%put #######################################################################;
%put ####            BASE 5 - SIMULACION CONSUMO de PWA                 ####;
%put #######################################################################;


PROC SQL;
CREATE TABLE WORK.base5 AS
SELECT A.*,
B.SIMUL_CONSUMO,
B.MONTO_MIN_SIM_CONSUMO,
B.MONTO_MAX_SIM_CONSUMO,

B.SEGUROVIDA_SIM_CONSUMO,
B.SEGURODESGRAVAMEN_SIM_CONSUMO,

B.MIN_SEGVIDA_SIM_CONSUMO,
B.MAX_SEGVIDA_SIM_CONSUMO,
B.PROM_SEGVIDA_SIM_CONSUMO,

B.MIN_SEGDESGRA_SIM_CONSUMO,
B.MAX_SEGDESGRA_SIM_CONSUMO,
B.PROM_SEGDESGRA_SIM_CONSUMO,

B.SIMUL_APP_CONS,
B.SIMUL_APP_1_CONS,
B.SIMUL_CHEK_CONS,
B.SIMUL_DESKTOP_CONS,
B.SIMUL_IFRAME_CONS,
B.SIMUL_MOBILE_CONS,
B.SIMUL_TOTEM_CONS,
B.SIMUL_VACIO_CONS

FROM WORK.BASE4 A
LEFT JOIN SIMS_CONSUMO B
ON A.RUT = B.RUT
AND A.DIA = B.DIA
group by A.RUT,
A.DIA,
A.CREATED_AT
;QUIT;


%put ############################################################;
%put #### CURSES PWA CONSUMO  (REVISAR POR QUE HISTORICO)    ####;
%put ############################################################;


proc sql;
connect to ODBC as myconn (user="ripley-bi" password="biripley00" DATASRC="BR-BACKENDHB");
create table CURSES_CONSUMO_PWA as 
select * 
from connection to myconn
(SELECT
rut,
Montoliquido ,
NumeroOperacion,
DISPOSITIVO,
FechaCurse,
SeguroDesgravamen, 
SeguroVida
FROM PersonalLoanView
where CAST(FECHACURSE AS date) BETWEEN %str(%')&primer_dia.%str(%') AND %str(%')&ultimo_dia.%str(%')
);
disconnect from myconn
;QUIT;


proc sql;
create table CURSES_CONSUMO_PWA_2 as 
select 
input(substr(rut,1,length(rut)-1),best.) AS RUT,
day(datepart(FECHACURSE)) as dia,
datepart(FECHACURSE) FORMAT=date9. AS FECHA,
count(RUT) as CURSE_CONSUMO,
input(Montoliquido,best.) as MONTO_CURSE_CONSUMO,
SeguroDesgravamen as PRECIO_DESGR_CURS_CONSUMO,
SeguroVida  as PRECIO_SEGVID_CURS_CONSUMO,
case when upcase(DISPOSITIVO)='APP' then rut end as CUR_APP_CONS,
case when upcase(DISPOSITIVO)='APP_1' then rut end as CUR_APP_1_CONS,
case when upcase(DISPOSITIVO)='CHEK' then rut end as CUR_CHEK_CONS,
case when upcase(DISPOSITIVO)='DESKTOP' then rut end as CUR_DESKTOP_CONS,
case when upcase(DISPOSITIVO)='IFRAME' then rut end as CUR_IFRAME_CONS,
case when upcase(DISPOSITIVO)='MOBILE' then rut end as CUR_MOBILE_CONS,
case when upcase(DISPOSITIVO)='TOTEM' then rut end as CUR_TOTEM_CONS,
case when upcase(DISPOSITIVO) IS NULL then rut end as CUR_VACIO_CONS

from CURSES_CONSUMO_PWA
WHERE RUT <> 'NULL'
group by 
calculated RUT, 
calculated dia,
calculated fecha
order by dia
;QUIT;

%put #######################################################################;
%put ####            BASE 6 - CURSES CONSUMO de PWA                     ####;
%put #######################################################################;

PROC SQL;
CREATE TABLE WORK.base6 AS
SELECT A.*,
B.CURSE_CONSUMO,
B.MONTO_CURSE_CONSUMO,
B.PRECIO_DESGR_CURS_CONSUMO,
B.PRECIO_SEGVID_CURS_CONSUMO,
B.CUR_APP_CONS,
B.CUR_APP_1_CONS,
B.CUR_CHEK_CONS,
B.CUR_DESKTOP_CONS,
B.CUR_IFRAME_CONS,
B.CUR_MOBILE_CONS,
B.CUR_TOTEM_CONS,
B.CUR_VACIO_CONS

FROM WORK.BASE5 A
LEFT JOIN CURSES_CONSUMO_PWA_2 B
ON A.RUT = B.RUT
AND A.DIA = B.DIA
group by A.RUT,
A.DIA,
A.CREATED_AT
;QUIT;

%put #######################################################################;
%put ####            BASE 7 - GENERACION TABLA RESUMEN                  ####;
%put #######################################################################;


proc sql;
create table &libreria..DIGITAL_TABLON_&periodo_actual. as
select *
from work.base6
;quit;



PROC SQL;
CREATE TABLE WORK.ACUMULADO_TOTAL AS
SELECT 
&periodo_actual. as periodo,
count(distinct case when VISITA_APP	+VISITA_APP_1+	VISITA_CHEK	+VISITA_DESKTOP+	VISITA_IFRAME+	VISITA_MOBILE+	VISITA_TOTEM>=1 then rut end ) as VISITA_MIX,
count(distinct case when VISITA_DESKTOP+VISITA_MOBILE>=1 then rut end ) as VISITA_WEB,
count(distinct case when TIENE_OFERTA_SAV=1 then rut end )as oferta_sav,
count(distinct case when TIENE_OFERTA_AV=1 then rut end )as oferta_av,
count(distinct case when TIENE_OFERTA_CONS=1 then rut end )as oferta_CONS,

count(distinct case when TIENE_OFERTA_SAV=1 and SIMULACION_SAV>0 then rut end )as simu_sav,
count(distinct case when TIENE_OFERTA_AV=1 and SIMULACION_AV>0 then rut end )as simu_av,
count(distinct case when TIENE_OFERTA_CONS=1 and SIMUL_CONSUMO>0 then rut end )as simu_CONS,

sum( case when HIZO_CURSE_SAV=1  then MONTO_CUR_SAV end )as monto_curse_sav,
sum( case when HIZO_CURSE_AV=1 then MONTO_CUR_AV end )as monto_curse_av,
sum( case when curse_consumo=1 then monto_curse_consumo end )as monto_curse_CONS,

count( case when  HIZO_CURSE_SAV=1  then rut end )as trx_curse_sav,
count( case when  HIZO_CURSE_AV=1 then rut end )as trx_curse_av,
count( case when  curse_consumo=1 then rut end )as trx_curse_CONS,

count( case when  HIZO_CURSE_SAV=1 and PRECIO_SEGURO_CUR_SAV>0 then rut end )as seg_sav,
count( case when  HIZO_CURSE_AV=1 and PRECIO_SEGURO_CUR_AV>0 then rut end )as seg_av,
count( case when  curse_consumo=1 and PRECIO_DESGR_CURS_CONSUMO+PRECIO_SEGVID_CURS_CONSUMO>0 then rut end )as seg_CONS


FROM &libreria..digital_tablon_&periodo_actual.
;QUIT;


PROC SQL;
CREATE TABLE DIGITAL_ACUMULADO_TOTAL_&periodo_actual. AS
SELECT *
FROM WORK.ACUMULADO_TOTAL
;QUIT;




%put #######################################################################;
%put ####       BASE 8 - GENERACION TABLA ACUMLADO DIARIO               ####;
%put #######################################################################;


%if (%sysfunc(exist(publicin.resumen_PROPUESTA_KPI))) %then %do;

%end;
%else %do;

proc sql;
create table &libreria..resumen_PROPUESTA_KPI
(periodo num,
dia num,
FECHA date,
VISITA_MIX num,
VISITA_WEB num,

VISITA_APP num,
VISITA_APP_1 num,
VISITA_CHEK num,
VISITA_DESKTOP num,
VISITA_IFRAME num,
VISITA_MOBILE num,
VISITA_TOTEM num,
oferta_sav num,
oferta_av num,
oferta_CONS num,
simu_sav num,
simu_av num,
simu_CONS num,
monto_curse_sav num,
monto_curse_av num,
monto_curse_CONS num,
trx_curse_sav num,
trx_curse_av num,
trx_curse_CONS num,
seg_sav num,
seg_av num,
seg_CONS num
)
;QUIT;
%end;

proc sql noprint;
delete *
from &libreria..resumen_PROPUESTA_KPI
where periodo = &periodo_actual.
;QUIT;


%macro evaluar;

%do i=&primer_dia_mes. %to &ultimo_dia_mes.;
PROC SQL;
CREATE TABLE WORK.VISTA_DIARIO AS
SELECT 
&periodo_actual. as periodo,
&i. as dia,
MAX(case when year(CREATED_AT)*100+month(CREATED_AT)=&periodo_actual. THEN CREATED_AT end) AS FECHA,
count(distinct case when VISITA_APP  +VISITA_APP_1+  VISITA_CHEK     +VISITA_DESKTOP+     VISITA_IFRAME+  VISITA_MOBILE+  VISITA_TOTEM>=1 then rut end ) as VISITA_MIX,
count(distinct case when VISITA_DESKTOP+VISITA_MOBILE>=1 then rut end ) as VISITA_WEB,

count(distinct case when VISITA_APP=1 then rut end ) as VISITA_APP,
count(distinct case when VISITA_APP_1=1 then rut end ) as VISITA_APP_1,
count(distinct case when VISITA_CHEK=1 then rut end ) as VISITA_CHEK,
count(distinct case when VISITA_DESKTOP=1 then rut end ) as VISITA_DESKTOP,
count(distinct case when VISITA_IFRAME=1 then rut end ) as VISITA_IFRAME,
count(distinct case when VISITA_MOBILE=1 then rut end ) as VISITA_MOBILE,
count(distinct case when VISITA_TOTEM=1 then rut end ) as VISITA_TOTEM,

count(distinct case when TIENE_OFERTA_SAV=1 then rut end )as oferta_sav,
count(distinct case when TIENE_OFERTA_AV=1 then rut end )as oferta_av,
count(distinct case when TIENE_OFERTA_CONS=1 then rut end )as oferta_CONS,

count(distinct case when TIENE_OFERTA_SAV=1 and SIMULACION_SAV>0 then rut end )as simu_sav,
count(distinct case when TIENE_OFERTA_AV=1 and SIMULACION_AV>0 then rut end )as simu_av,
count(distinct case when TIENE_OFERTA_CONS=1 and SIMUL_CONSUMO>0 then rut end )as simu_CONS,

sum( case when HIZO_CURSE_SAV=1  then MONTO_CUR_SAV end )as monto_curse_sav,
sum( case when HIZO_CURSE_AV=1 then MONTO_CUR_AV end )as monto_curse_av,
sum( case when curse_consumo=1 then monto_curse_consumo end )as monto_curse_CONS,

count( case when  HIZO_CURSE_SAV=1  then rut end )as trx_curse_sav,
count( case when  HIZO_CURSE_AV=1 then rut end )as trx_curse_av,
count( case when  curse_consumo=1 then rut end )as trx_curse_CONS,

count( case when  HIZO_CURSE_SAV=1 and PRECIO_SEGURO_CUR_SAV>0 then rut end )as seg_sav,
count( case when  HIZO_CURSE_AV=1 and PRECIO_SEGURO_CUR_AV>0 then rut end )as seg_av,
count( case when  curse_consumo=1 and PRECIO_DESGR_CURS_CONSUMO+PRECIO_SEGVID_CURS_CONSUMO>0 then rut end )as seg_CONS

FROM &libreria..DIGITAL_TABLON_&periodo_actual.
where dia<=&i.
;QUIT;

proc sql noprint;
insert into &libreria..resumen_PROPUESTA_KPI
select *
from VISTA_DIARIO
;QUIT;

proc sql noprint;
drop table VISTA_DIARIO
;QUIT;
%end;

%mend evaluar;

%evaluar;

proc sql;
create table &libreria..resumen_PROPUESTA_KPI as 
select *
from &libreria..resumen_PROPUESTA_KPI
;QUIT;


%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_DELETE.sas";
%borrarOracleRaw(DGTL_DIGITAL_RESUMEN);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_EXPORT.sas";
%ExportacionOracleRaw(DGTL_DIGITAL_RESUMEN,publicin.resumen_PROPUESTA_KPI);


%put #######################################################################;
%put ####             ELIMINAMOS TABLAS TEMPORALES                      ####;
%put #######################################################################;

proc sql noprint;
drop table base1
;QUIT;
proc sql noprint;
drop table base2
;QUIT;
proc sql noprint;
drop table base3
;QUIT;
proc sql noprint;
drop table base4
;QUIT;
proc sql noprint;
drop table base5
;QUIT;
proc sql noprint;
drop table base6
;QUIT;

proc sql noprint;
drop table oferta_sav
;QUIT;
proc sql noprint;
drop table oferta_av
;QUIT;
proc sql noprint;
drop table oferta_consumo
;QUIT;
proc sql noprint;
drop table SIMULATIONAVSAVPWA
;QUIT;
proc sql noprint;
drop table SIMULATIONAVSAVPWA_2
;QUIT;
proc sql noprint;
drop table PWA
;QUIT;
proc sql noprint;
drop table CURSE_AVSAV_PWA
;QUIT;
proc sql noprint;
drop table SIMULACION_CONSUMO_PWA
;QUIT;
proc sql noprint;
drop table SIMS_CONSUMO
;QUIT;
proc sql noprint;
drop table CURSES_CONSUMO_PWA
;QUIT;
proc sql noprint;
drop table CURSES_CONSUMO_PWA_2
;QUIT;

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*  VARIABLE TIEMPO - FIN   */
data _null_;
    dur = datetime() - &tiempo_inicio;
    put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';

/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';
SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';
SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_DIGITAL_1';
SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SUBGERENT_CNL_DIGITAL';
SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_DIGITAL';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;

data _null_;
FILENAME OUTBOX EMAIL
FROM	= ("&EDP_BI")
TO 		= ("&DEST_3","&DEST_4","&DEST_5")
CC 		= ("&DEST_1","&DEST_2")
SUBJECT = ("MAIL_AUTOM: Proceso KPI_INTERNET");
FILE OUTBOX;
 PUT "Estimados:";
 put "        Proceso KPI_INTERNET, ejecutado automáticamente con fecha: &fechaeDVN";  
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 05'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Arquitectura de Datos y Automatización BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
