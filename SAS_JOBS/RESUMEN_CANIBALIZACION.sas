/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	RESUMEN_CANIBALIZACION			 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-08-30 -- v07 -- René F.		-- Actualización en variables fechas
/* 2022-08-23 -- v06 -- David V.	-- Nueva versión de eliminación/export a AWS.
/* 2022-08-23 -- v05 -- David V.	-- Unificar ambas versiones de cara a comentarios, librería, correo de notificación y otros.
/* 2022-08-17 -- v04 -- René F.		-- Cambios respecto a la versión con ejecución manual que René tenía.
/* 2022-07-11 -- V03 -- Sergio J. 	-- Se agrega código de exportación para alimentar a Tableau
/* 2020-10-09 -- V02 -- Karina M. 	-- CAMBIOS			
/* 2020-10-09 -- V01 -- Karina M. 	-- Versión Original 
					 -- Comentarios EDYP (Al inicio y al final)
					 -- Envío de email notificando ejecución
/* INFORMACIÓN:
Tablas requeridas o conexiones a BD
	- jaburtom.SAV_FIN_&periodo
	- publicin.TRX_SAV_&periodo
	- publicin.TRX_AV_&periodo
	- kmartine.tmp_ACT_rango_fin_&periodo
	- jaburtom.SAV_FIN_&periodoAnt
	- publicin.TRX_SAV_&periodoAnt
	- publicin.TRX_AV_&periodoAnt
	- kmartine.tmp_ACT_rango_fin_&periodoAnt

Tabla de Salida
	- RESULT.KM_CANIBALIZACION_TOTAL
	- PUBLICIN.KM_CANIBALIZACION_AV_SAV
	- ORACLOUD
*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime());
options validvarname=any;

/*	DECLARACIÓN VARIABLE LIBRERIA	*/
%let libreria = RESULT;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

/*#########################################################################################*/
/*Analisis Canibalizacion AV vs SAV (2020)*/
/*#########################################################################################*/

/*#########################################################################################*/
/*PARA EJECUCION ANTES DEL CIERRE ---> EJECUCION CIERRE DAVID*/
/*#########################################################################################*/


/*===============================================================================================================================================================*/
/*=== MACRO FECHAS  ==============================================================================================================================================*/
/*===============================================================================================================================================================*/

DATA _null_;

date0 = input(put(intnx('month',today(),0,'same'),yymmn6. ),$10.);
date1 = input(put(intnx('month',today(),-1,'same'),yymmn6. ),$10.);
date2 = input(put(intnx('month',today(),-2,'same'),yymmn6. ),$10.);

Call symput("periodo", date0);
Call symput("periodoAnt", date1);
Call symput("periodoAntante", date2);
RUN;

%put &periodo; /*periodo actual */
%put &periodoAnt;/*periodo anterior*/
%put &periodoAntante;/*periodo ante anterior*/

/*
proc sql outobs=1;
create table PUBLICIN.trx_sav_&periodo as
select *
from publicin.trx_sav_&periodoAnt
;quit;

 

proc sql outobs=1;
create table PUBLICIN.trx_av_&periodo as
select *
from publicin.trx_av_&periodoAnt
;quit;
*/




/*=========================================================================================*/
/*[01]  query ANALISIS MES ACTUAL*/
/*=========================================================================================*/

options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/

Proc sql;
create table Resultado_&periodo as
select 
Tipo_Oferta,
case 
when RANGO_PROB IN('0.9 - 1.0','0.8 - 0.9','0.7 - 0.8','0.6 - 0.7','0.5 - 0.6','0.4 - 0.5') AND ACTIVIDAD_TR IN ('ACTIVO',
'SEMIACTIVO',
'DORMIDO BLANDO',
'OTROS CON SALDO') THEN '1. SI VERDES' ELSE  '2. NO VERDES' END AS Tipo_Base,
SI_VERDES,
VU_RIESGO, 
VU_IC, 
ACTIVIDAD_TR,
RANGO_PROB,
SI_SAV,
SI_AV,
case 
when SI_SAV=0 and SI_AV=0 then '1. NO AV | NO SAV' 
when SI_SAV=1 and SI_AV=0 then '2. NO AV | SI SAV' 
when SI_SAV=0 and SI_AV=1 then '3. SI AV | NO SAV' 
when SI_SAV=1 and SI_AV=1 then '4. SI AV | SI SAV' 
end as Tipo_Compra,
SB_Tramificar(Mto_Oferta_SAV,200000,0,2000000,'') as Tramo_Mto_Oferta_SAV,
SB_Tramificar(Mto_Oferta_AV,200000,0,1600000,'') as Tramo_Mto_Oferta_AV,
SB_Tramificar(Mto_TRXs_SAV,200000,0,2000000,'') as Tramo_Mto_TRXs_SAV,
SB_Tramificar(Mto_TRXs_AV,200000,0,1600000,'') as Tramo_Mto_TRXs_AV, 
count(*) as Nro_Clientes,
sum(SI_SAV) as sum_SI_SAV,
sum(SI_AV) as sum_SI_AV,
sum(Mto_Oferta_SAV) as sum_Mto_Oferta_SAV,
sum(Mto_Oferta_AV) as sum_Mto_Oferta_AV,
sum(Nro_TRXs_SAV) as sum_Nro_TRXs_SAV,
sum(Mto_TRXs_SAV) as sum_Mto_TRXs_SAV,
sum(Nro_TRXs_AV) as sum_Nro_TRXs_AV,
sum(Mto_TRXs_AV) as sum_Mto_TRXs_AV 
from ( 
select 
c.*,
case when d.rut is not null then 1 else 0 end as SI_SAV,
d.Nro_TRXs as Nro_TRXs_SAV,
d.Mto_TRXs as Mto_TRXs_SAV,
case when e.rut is not null then 1 else 0 end as SI_AV,
e.Nro_TRXs as Nro_TRXs_AV,
e.Mto_TRXs as Mto_TRXs_AV,
case 
when j.RANGO_PROB IN('0.9 - 1.0','0.8 - 0.9','0.7 - 0.8','0.6 - 0.7','0.5 - 0.6','0.4 - 0.5') AND j.ACTIVIDAD_TR IN ('ACTIVO',
'SEMIACTIVO',
'DORMIDO BLANDO',
'OTROS CON SALDO') THEN 1 ELSE  0 END AS SI_VERDES,
j.VU_RIESGO, 
j.VU_IC, 
j.ACTIVIDAD_TR,
j.RANGO_PROB  
from ( 
select 
coalesce(a.RUT_REAL,b.rut) as rut, 
case 
when a.RUT_REAL is not null and b.rut is not null then '1. AV+SAV' 
when a.RUT_REAL is not null then '2. Solo SAV' 
else '3. Solo AV' 
end as Tipo_Oferta, 
coalesce(a.MONTO_PARA_CANON,0) as Mto_Oferta_SAV, 
coalesce(b.DISPOFINAL,0) as Mto_Oferta_AV
from ( 
select * 
from jaburtom.SAV_FIN_&periodo 
where SAV_APROBADO_FINAL=1 
) as a 
full outer join kmartine.AVANCE_FIN_&periodo as b 
on (a.RUT_REAL=b.rut) 
) as c 
left join ( 
select 
rut, 
count(*) as Nro_TRXs, 
sum(CAPITAL) as Mto_TRXs 
from PUBLICIN.TRX_SAV_&periodo 
where VIA_FINAL IN ('TLMK','TV','TF','HOME_B','MOVIL','APP','CHEK') 
group by 
rut 
) as d 
on (c.rut=d.rut) 
left join ( 
select 
rut, 
count(*) as Nro_TRXs, 
sum(CAPITAL) as Mto_TRXs 
from PUBLICIN.TRX_AV_&periodo 
group by 
rut 
) as e 
on (c.rut=e.rut) 
left join ( 
select 
rut, 
VU_RIESGO, 
VU_IC, 
ACTIVIDAD_TR,
RANGO_PROB
from kmartine.tmp_ACT_rango_fin_&periodo 
) as j 
on (c.rut=j.rut) 
) as X 
group by 
Tipo_Oferta,
calculated Tipo_Base,
SI_VERDES,
VU_RIESGO, 
VU_IC, 
ACTIVIDAD_TR,
RANGO_PROB, 
SI_SAV, 
SI_AV, 
calculated Tipo_Compra, 
calculated Tramo_Mto_Oferta_SAV, 
calculated Tramo_Mto_Oferta_AV, 
calculated Tramo_Mto_TRXs_SAV, 
calculated Tramo_Mto_TRXs_AV
 ;quit;


 
/*=========================================================================================*/
/*[02]  query ANALISIS MES ANTERIOR (CIERRE)*/
/*=========================================================================================*/
options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/

Proc sql;
create table Resultado_&periodoAnt as
select 
Tipo_Oferta,
case 
when RANGO_PROB IN('0.9 - 1.0','0.8 - 0.9','0.7 - 0.8','0.6 - 0.7','0.5 - 0.6','0.4 - 0.5') AND ACTIVIDAD_TR IN ('ACTIVO',
'SEMIACTIVO',
'DORMIDO BLANDO',
'OTROS CON SALDO') THEN '1. SI VERDES' ELSE  '2. NO VERDES' END AS Tipo_Base,
SI_VERDES,
VU_RIESGO, 
VU_IC, 
ACTIVIDAD_TR,
RANGO_PROB,
SI_SAV,
SI_AV,
case 
when SI_SAV=0 and SI_AV=0 then '1. NO AV | NO SAV' 
when SI_SAV=1 and SI_AV=0 then '2. NO AV | SI SAV' 
when SI_SAV=0 and SI_AV=1 then '3. SI AV | NO SAV' 
when SI_SAV=1 and SI_AV=1 then '4. SI AV | SI SAV' 
end as Tipo_Compra,
SB_Tramificar(Mto_Oferta_SAV,200000,0,2000000,'') as Tramo_Mto_Oferta_SAV,
SB_Tramificar(Mto_Oferta_AV,200000,0,2000000,'') as Tramo_Mto_Oferta_AV,
SB_Tramificar(Mto_TRXs_SAV,200000,0,2000000,'') as Tramo_Mto_TRXs_SAV,
SB_Tramificar(Mto_TRXs_AV,200000,0,2000000,'') as Tramo_Mto_TRXs_AV, 
count(*) as Nro_Clientes,
sum(SI_SAV) as sum_SI_SAV,
sum(SI_AV) as sum_SI_AV,
sum(Mto_Oferta_SAV) as sum_Mto_Oferta_SAV,
sum(Mto_Oferta_AV) as sum_Mto_Oferta_AV,
sum(Nro_TRXs_SAV) as sum_Nro_TRXs_SAV,
sum(Mto_TRXs_SAV) as sum_Mto_TRXs_SAV,
sum(Nro_TRXs_AV) as sum_Nro_TRXs_AV,
sum(Mto_TRXs_AV) as sum_Mto_TRXs_AV 
from ( 
select 
c.*,
case when d.rut is not null then 1 else 0 end as SI_SAV,
d.Nro_TRXs as Nro_TRXs_SAV,
d.Mto_TRXs as Mto_TRXs_SAV,
case when e.rut is not null then 1 else 0 end as SI_AV,
e.Nro_TRXs as Nro_TRXs_AV,
e.Mto_TRXs as Mto_TRXs_AV,
case 
when j.RANGO_PROB IN('0.9 - 1.0','0.8 - 0.9','0.7 - 0.8','0.6 - 0.7','0.5 - 0.6','0.4 - 0.5') AND j.ACTIVIDAD_TR IN ('ACTIVO',
'SEMIACTIVO',
'DORMIDO BLANDO',
'OTROS CON SALDO') THEN 1 ELSE  0 END AS SI_VERDES,
j.VU_RIESGO, 
j.VU_IC, 
j.ACTIVIDAD_TR,
j.RANGO_PROB  
from ( 
select 
coalesce(a.RUT_REAL,b.rut) as rut, 
case 
when a.RUT_REAL is not null and b.rut is not null then '1. AV+SAV' 
when a.RUT_REAL is not null then '2. Solo SAV' 
else '3. Solo AV' 
end as Tipo_Oferta, 
coalesce(a.MONTO_PARA_CANON,0) as Mto_Oferta_SAV, 
coalesce(b.DISPOFINAL,0) as Mto_Oferta_AV
from ( 
select * 
from jaburtom.SAV_FIN_&periodoAnt 
where SAV_APROBADO_FINAL=1 
) as a 
full outer join kmartine.AVANCE_FIN_&periodoAnt as b 
on (a.RUT_REAL=b.rut) 
) as c 
left join ( 
select 
rut, 
count(*) as Nro_TRXs, 
sum(CAPITAL) as Mto_TRXs 
from publicin.TRX_SAV_&periodoAnt 
where VIA_FINAL IN ('TLMK','TV','TF','HOME_B','MOVIL','APP','CHEK') 
group by 
rut 
) as d 
on (c.rut=d.rut) 
left join ( 
select 
rut, 
count(*) as Nro_TRXs, 
sum(CAPITAL) as Mto_TRXs 
from publicin.TRX_AV_&periodoAnt 
group by 
rut 
) as e 
on (c.rut=e.rut) 
left join ( 
select 
rut, 
VU_RIESGO, 
VU_IC, 
ACTIVIDAD_TR,
RANGO_PROB
from kmartine.tmp_ACT_rango_fin_&periodoAnt 
) as j 
on (c.rut=j.rut) 
) as X 
group by 
Tipo_Oferta,
calculated Tipo_Base,
SI_VERDES,
VU_RIESGO, 
VU_IC, 
ACTIVIDAD_TR,
RANGO_PROB, 
SI_SAV, 
SI_AV, 
calculated Tipo_Compra, 
calculated Tramo_Mto_Oferta_SAV, 
calculated Tramo_Mto_Oferta_AV, 
calculated Tramo_Mto_TRXs_SAV, 
calculated Tramo_Mto_TRXs_AV
 ;quit;



 
/*=========================================================================================*/
/*[02]  query ANALISIS MES ANTERIOR (CIERRE)*/
/*=========================================================================================*/
options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/

Proc sql;
create table Resultado_&periodoAntante as
select 
Tipo_Oferta,
case 
when RANGO_PROB IN('0.9 - 1.0','0.8 - 0.9','0.7 - 0.8','0.6 - 0.7','0.5 - 0.6','0.4 - 0.5') AND ACTIVIDAD_TR IN ('ACTIVO',
'SEMIACTIVO',
'DORMIDO BLANDO',
'OTROS CON SALDO') THEN '1. SI VERDES' ELSE  '2. NO VERDES' END AS Tipo_Base,
SI_VERDES,
VU_RIESGO, 
VU_IC, 
ACTIVIDAD_TR,
RANGO_PROB,
SI_SAV,
SI_AV,
case 
when SI_SAV=0 and SI_AV=0 then '1. NO AV | NO SAV' 
when SI_SAV=1 and SI_AV=0 then '2. NO AV | SI SAV' 
when SI_SAV=0 and SI_AV=1 then '3. SI AV | NO SAV' 
when SI_SAV=1 and SI_AV=1 then '4. SI AV | SI SAV' 
end as Tipo_Compra,
SB_Tramificar(Mto_Oferta_SAV,200000,0,2000000,'') as Tramo_Mto_Oferta_SAV,
SB_Tramificar(Mto_Oferta_AV,200000,0,2000000,'') as Tramo_Mto_Oferta_AV,
SB_Tramificar(Mto_TRXs_SAV,200000,0,2000000,'') as Tramo_Mto_TRXs_SAV,
SB_Tramificar(Mto_TRXs_AV,200000,0,2000000,'') as Tramo_Mto_TRXs_AV, 
count(*) as Nro_Clientes,
sum(SI_SAV) as sum_SI_SAV,
sum(SI_AV) as sum_SI_AV,
sum(Mto_Oferta_SAV) as sum_Mto_Oferta_SAV,
sum(Mto_Oferta_AV) as sum_Mto_Oferta_AV,
sum(Nro_TRXs_SAV) as sum_Nro_TRXs_SAV,
sum(Mto_TRXs_SAV) as sum_Mto_TRXs_SAV,
sum(Nro_TRXs_AV) as sum_Nro_TRXs_AV,
sum(Mto_TRXs_AV) as sum_Mto_TRXs_AV 
from ( 
select 
c.*,
case when d.rut is not null then 1 else 0 end as SI_SAV,
d.Nro_TRXs as Nro_TRXs_SAV,
d.Mto_TRXs as Mto_TRXs_SAV,
case when e.rut is not null then 1 else 0 end as SI_AV,
e.Nro_TRXs as Nro_TRXs_AV,
e.Mto_TRXs as Mto_TRXs_AV,
case 
when j.RANGO_PROB IN('0.9 - 1.0','0.8 - 0.9','0.7 - 0.8','0.6 - 0.7','0.5 - 0.6','0.4 - 0.5') AND j.ACTIVIDAD_TR IN ('ACTIVO',
'SEMIACTIVO',
'DORMIDO BLANDO',
'OTROS CON SALDO') THEN 1 ELSE  0 END AS SI_VERDES,
j.VU_RIESGO, 
j.VU_IC, 
j.ACTIVIDAD_TR,
j.RANGO_PROB  
from ( 
select 
coalesce(a.RUT_REAL,b.rut) as rut, 
case 
when a.RUT_REAL is not null and b.rut is not null then '1. AV+SAV' 
when a.RUT_REAL is not null then '2. Solo SAV' 
else '3. Solo AV' 
end as Tipo_Oferta, 
coalesce(a.MONTO_PARA_CANON,0) as Mto_Oferta_SAV, 
coalesce(b.DISPOFINAL,0) as Mto_Oferta_AV
from ( 
select * 
from jaburtom.SAV_FIN_&periodoAntante 
where SAV_APROBADO_FINAL=1 
) as a 
full outer join PUBLICIN.AVANCE_FIN_&periodoAntante as b 
on (a.RUT_REAL=b.rut) 
) as c 
left join ( 
select 
rut, 
count(*) as Nro_TRXs, 
sum(CAPITAL) as Mto_TRXs 
from publicin.TRX_SAV_&periodoAntante 
where VIA_FINAL IN ('TLMK','TV','TF','HOME_B','MOVIL','APP','CHEK') 
group by 
rut 
) as d 
on (c.rut=d.rut) 
left join ( 
select 
rut, 
count(*) as Nro_TRXs, 
sum(CAPITAL) as Mto_TRXs 
from publicin.TRX_AV_&periodoAntante 
group by 
rut 
) as e 
on (c.rut=e.rut) 
left join ( 
select 
rut, 
VU_RIESGO, 
VU_IC, 
ACTIVIDAD_TR,
RANGO_PROB
from kmartine.tmp_ACT_rango_fin_&periodoAntante 
) as j 
on (c.rut=j.rut) 
) as X 
group by 
Tipo_Oferta,
calculated Tipo_Base,
SI_VERDES,
VU_RIESGO, 
VU_IC, 
ACTIVIDAD_TR,
RANGO_PROB, 
SI_SAV, 
SI_AV, 
calculated Tipo_Compra, 
calculated Tramo_Mto_Oferta_SAV, 
calculated Tramo_Mto_Oferta_AV, 
calculated Tramo_Mto_TRXs_SAV, 
calculated Tramo_Mto_TRXs_AV
 ;quit;

/*=========================================================================================*/
/*[03]  ACTUALIZAR TABLA RESUMEN */
/*=========================================================================================*/

/* TABLA PASO */

PROC SQL;
CREATE TABLE &libreria..KM_CANIBALIZACION_TOTAL AS
SELECT *
FROM &libreria..KM_CANIBALIZACION_AV_SAV WHERE PERIODO NOT IN (&periodoAnt,&periodo,&periodoAntante)
UNION SELECT &periodo as Periodo , * FROM Resultado_&periodo 
UNION SELECT &periodoAnt as Periodo,* FROM Resultado_&periodoAnt 
UNION SELECT &periodoAntante as Periodo,* FROM Resultado_&periodoAntante
;QUIT;

PROC SQL;
CREATE TABLE &libreria..KM_CANIBALIZACION_AV_SAV AS
SELECT *
FROM &libreria..KM_CANIBALIZACION_TOTAL
;QUIT;


/*=========================================================================================*/
/*[04]  SUBIR AL ORACLAUD TABLA RESUMEN */
/*=========================================================================================*/

proc sql;
create table SAS_CANIBALIZACION_AV_SAV as 
select case when periodo-floor(periodo/100)*100 between 1 and 9 then 
cat(floor(periodo/100),'-',
cat('0',periodo-floor(periodo/100)*100),'-',
'01')
else 
cat(floor(periodo/100),'-',
periodo-floor(periodo/100)*100,'-',
'01') end  as periodo2, * from &libreria..KM_CANIBALIZACION_AV_SAV;
;quit;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_DELETE.sas";
%borrarOracleRaw(PPFF_CANIBALIZACION_AV_SAV);

/*Exporta la data a Raw*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_EXPORT.sas";
%ExportacionOracleRaw(PPFF_CANIBALIZACION_AV_SAV,SAS_CANIBALIZACION_AV_SAV);

/*==============================        EXPORT_TO_AWS - END          ===============================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

proc sqL;
drop table Resultado_&periodo;
drop table Resultado_&periodoAnt;
;QUIT;

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	FECHA PROCESO Y ENVÍO DE EMAIL =============================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_PPFF';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_1';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_2';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4", "&DEST_5", "&DEST_6")
CC = ("&DEST_1", "&DEST_2", "&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso RESUMEN_CANIBALIZACION AV SAV");
FILE OUTBOX;
	PUT "Estimados:";
 	PUT "		Proceso RESUMEN_CANIBALIZACION AV SAV, ejecutado con fecha: &fechaeDVN";  
    PUT;
    PUT;
    PUT 'Proceso Vers. 07';
    PUT;
    PUT;
    PUT 'Atte.';
    PUT 'Equipo Arquitectura de Datos y Automatización BI';
    PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
