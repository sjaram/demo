/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	TABLEAU_EPU			 			 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-11-03 -- v02 -- David V.	-- Comentarios, versionamiento y mail.
/* 2022-11-02 -- v01 -- Sergio J.	-- Automatización en server SAS.
/* 2022-11-02 -- V00 -- Pedro M.   	-- Original
*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*==================================================================================================*/

/*Semuc_Est_Dir_Epu 2,1,0 como fisico  y 3 como mail*/
/*0 es sin info
1 es particular
2 casilla
3 email*/

/*201 237 epu cobro*/
%let lib_base=PUBLICIN;
%let LIB_RESUMEN=RESULT;

%macro EPU(n,lib_base,LIB_RESUMEN);



DATA _null_;
periodo= input(put(intnx('month',today(),-&N.,'same'),yymmn6. ),$10.);

Call symput("periodo", periodo);


RUN;

%put &periodo; /*PERIODO ACTUAL*/


%if (%sysfunc(exist(nlagosg.SEGM_GEST_TODAS_PART_&periodo.))) %then %do;
%end;
%else %do;
PROC SQL noprint;   
select max(anomes) as Max_seg
into :Max_seg
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'NLAGOSG.SEGM_GEST_TODAS_PART_%' 
and length(Nombre_Tabla)=length('NLAGOSG.SEGM_GEST_TODAS_PART_202011')
) as x
;QUIT;
%end;


%let Max_seg=&Max_seg;


%put==========================================================================================;
%put [02] cruce de tablas ;
%put==========================================================================================;


proc sql;
create table SB_ContratoEPU as 
select a.*,
case when f.SEGMENTO='R_GOLD' then '01.GOLD'
when f.SEGMENTO='R_SILVER' then '02.SILVER'
when f.SEGMENTO='RIPLEY_ALTA' then '03.BRONCE'
when f.SEGMENTO='RIPLEY_BAJA' then '04.BAJA'
else '05.SIN SEGMENTO' end as SEGMENTO_GESTION

from &lib_base..sb_contratoepu_&periodo. as a 
left join publicin.segmento_comercial as f
on(a.rut=f.rut)
;QUIT;


%put==========================================================================================;
%put [03] Colapso ;
%put==========================================================================================;

proc sql;
create table resumen as 
select 
&periodo. as periodo,
mdy(mod(int((100*&periodo.+01)/100),100),mod((100*&periodo.+01),100),int((100*&periodo.+01)/10000)) format=e8601da. as periodo_tableau,
case when length(compress(put(day(facturacion) ,2.)))= 1 then cat('0',compress(put(day(facturacion) ,2.))) else 
put(day(facturacion) ,2.) end as FF,
Tipo_Producto,
SI_EpuMail,
SI_EpuFisico,
SI_MantencionEpu,
coalesce(Glosa,'Sin cobro') as GLOSA,
case when Saldo<1000 then '01.Saldo menor a $1.000' else '02.Saldo>$1.000'	 end as Saldo,
SEGMENTO_GESTION,
sum(Mto_Mantencion) as Mto_mantencion,
sum(saldo) as Mto_saldo,
count(CONTRATO) as clientes
from SB_ContratoEPU 
group by 
calculated FF,
Tipo_Producto,
SI_EpuMail,
SI_EpuFisico,
SI_MantencionEpu,
calculated  GLOSA,
calculated Saldo,
SEGMENTO_GESTION
;QUIT;



%if (%sysfunc(exist(&LIB_RESUMEN..MDPG_seguimiento_ff_epu))) %then %do;
%end;
%else %do;
PROC  SQL;
CREATE TABLE &LIB_RESUMEN..MDPG_seguimiento_ff_epu 
(periodo num,
periodo_tableau date,
 FF char(99),
Tipo_Producto char(99),
SI_EpuMail num ,
SI_EpuFisico num ,
SI_MantencionEpu num,
GLOSA char(99),
 Saldo char(99),
 SEGMENTO_GESTION char(99),
 Mto_mantencion num ,
Mto_saldo num,
 clientes num)
;quit;
%end;

proc sql;
delete *
from &LIB_RESUMEN..MDPG_seguimiento_ff_epu
where periodo=&periodo.  and glosa<>'PRESUPUESTO'
;QUIT;


proc sql;
insert into &LIB_RESUMEN..MDPG_seguimiento_ff_epu
select 
* 
from resumen
;QUIT;

proc sql;
drop table SB_ContratoEPU;
drop table resumen;
;QUIT;


%if (%sysfunc(exist(&LIB_RESUMEN..MDPG_MES_ff_epu))) %then %do;
%end;
%else %do;
PROC  SQL;
CREATE TABLE &LIB_RESUMEN..MDPG_MES_ff_epu 
(periodo num,
 FF num,
 Tipo_tarjeta char(10),
 Mto_mantencion num ,
 clientes num,
 TRX NUM,
 Mto_mantencion_ACT num ,
  clientes_act num,
TRX_ACT NUM,
 Mto_mantencion_SIG num ,
   clientes_sig num,
TRX_SIG num)
;quit;
%end;

proc sql;
delete *
from &LIB_RESUMEN..MDPG_MES_ff_epu
where periodo=&periodo.  
;QUIT;

proc sql;
insert into &LIB_RESUMEN..MDPG_MES_ff_epu
select 
&periodo. as periodo ,
 corte as FF ,
 case when producto   in ('10','05','06','07') then 'TAM' else 'TR' end as Tipo_tarjeta,
 sum(monto)  as Mto_mantencion  ,
 count(distinct cuenta) as clientes ,
 sum(trx) as  TRX,
sum(monto_actual) as Mto_mantencion_ACT,
count(distinct case when trx_actual>0 then cuenta end) as clientes_act,
sum(trx_actual) as TRX_ACT,
sum(monto_des) as Mto_mantencion_SIG,
count(distinct case when trx_des>0 then cuenta end) as clientes_SIG,
sum(trx_des) as TRX_SIG
from &LIB_RESUMEN..EPU_MESACTUAL_&periodo.
group by corte,calculated Tipo_tarjeta
;QUIT;



%if (%sysfunc(exist(&LIB_RESUMEN..MDPG_dia_ff_epu))) %then %do;
%end;
%else %do;
PROC  SQL;
CREATE TABLE &LIB_RESUMEN..MDPG_dia_ff_epu 
(periodo num,
tipologia char(10),
fecha char(10),
monto num, 
trx num, 
 monto_actual num, 
trx_actual num, 
 monto_DES num, 
trx_DES num, 
Tipo_tarjeta char(10), 
clientes num)
;quit;
%end;

proc sql;
delete *
from &LIB_RESUMEN..MDPG_dia_ff_epu
where periodo=&periodo.  
;QUIT;

proc sql;
insert into &LIB_RESUMEN..MDPG_dia_ff_epu
select 
    
   &periodo. as periodo,
   'ACUMULADO' as tipologia,
'05' as fecha,
sum(monto) as monto, 
          sum(trx) as trx, 
          sum(monto_actual) as monto_actual, 
          sum(trx_actual) as trx_actual, 
          sum(monto_DES) as monto_DES, 
          sum(trx_DES) as trx_DES, 
         case when producto   in ('10','05','06','07') then 'TAM' else 'TR' end as Tipo_tarjeta, 
          count(distinct CUENTA) as clientes
      FROM &LIB_RESUMEN..EPU_MESACTUAL_&periodo.
where 	fecfac-floor(fecfac/100)*100<=5
group by calculated tipo_tarjeta
outer union corr 
   SELECT  
&periodo. as periodo,
'ACUMULADO' as tipologia,
'10' as fecha,
sum(monto) as monto, 
          sum(trx) as trx, 
          sum(monto_actual) as monto_actual, 
          sum(trx_actual) as trx_actual, 
          sum(monto_DES) as monto_DES, 
          sum(trx_DES) as trx_DES, 
         case when producto   in ('10','05','06','07') then 'TAM' else 'TR' end as Tipo_tarjeta, 
          count(distinct CUENTA) as clientes
      FROM &LIB_RESUMEN..EPU_MESACTUAL_&periodo.
where 	fecfac-floor(fecfac/100)*100<=10
group by calculated tipo_tarjeta
outer union corr 
   SELECT &periodo. as periodo,
'ACUMULADO' as tipologia,
'15' as fecha,
sum(monto) as monto, 
          sum(trx) as trx, 
          sum(monto_actual) as monto_actual, 
          sum(trx_actual) as trx_actual, 
          sum(monto_DES) as monto_DES, 
          sum(trx_DES) as trx_DES, 
         case when producto   in ('10','05','06','07') then 'TAM' else 'TR' end as Tipo_tarjeta, 
          count(distinct CUENTA) as clientes
      FROM &LIB_RESUMEN..EPU_MESACTUAL_&periodo.
where 	fecfac-floor(fecfac/100)*100<=15
group by calculated tipo_tarjeta
outer union corr 
   SELECT 
&periodo. as periodo,
'ACUMULADO' as tipologia,
'18' as fecha,
sum(monto) as monto, 
          sum(trx) as trx, 
          sum(monto_actual) as monto_actual, 
          sum(trx_actual) as trx_actual, 
          sum(monto_DES) as monto_DES, 
          sum(trx_DES) as trx_DES, 
         case when producto   in ('10','05','06','07') then 'TAM' else 'TR' end as Tipo_tarjeta, 
          count(distinct CUENTA) as clientes
      FROM &LIB_RESUMEN..EPU_MESACTUAL_&periodo.
where 	fecfac-floor(fecfac/100)*100<=18
group by calculated tipo_tarjeta
outer union corr 
   SELECT  
&periodo. as periodo,
'ACUMULADO' as tipologia,
'20' as fecha,
sum(monto) as monto, 
          sum(trx) as trx, 
          sum(monto_actual) as monto_actual, 
          sum(trx_actual) as trx_actual, 
          sum(monto_DES) as monto_DES, 
          sum(trx_DES) as trx_DES, 
         case when producto   in ('10','05','06','07') then 'TAM' else 'TR' end as Tipo_tarjeta, 
          count(distinct CUENTA) as clientes
      FROM &LIB_RESUMEN..EPU_MESACTUAL_&periodo.
where 	fecfac-floor(fecfac/100)*100<=20
group by calculated tipo_tarjeta
outer union corr 
   SELECT &periodo. as periodo,
   'ACUMULADO' as tipologia,
'25' as fecha,
sum(monto) as monto, 
          sum(trx) as trx, 
          sum(monto_actual) as monto_actual, 
          sum(trx_actual) as trx_actual, 
          sum(monto_DES) as monto_DES, 
          sum(trx_DES) as trx_DES, 
         case when producto   in ('10','05','06','07') then 'TAM' else 'TR' end as Tipo_tarjeta, 
          count(distinct CUENTA) as clientes
      FROM &LIB_RESUMEN..EPU_MESACTUAL_&periodo.
where 	fecfac-floor(fecfac/100)*100<=25
group by calculated tipo_tarjeta
outer union corr 
   SELECT  &periodo. as periodo,'ACUMULADO' as tipologia,
'30' as fecha,
sum(monto) as monto, 
          sum(trx) as trx, 
          sum(monto_actual) as monto_actual, 
          sum(trx_actual) as trx_actual, 
          sum(monto_DES) as monto_DES, 
          sum(trx_DES) as trx_DES, 
         case when producto   in ('10','05','06','07') then 'TAM' else 'TR' end as Tipo_tarjeta, 
          count(distinct CUENTA) as clientes
      FROM &LIB_RESUMEN..EPU_MESACTUAL_&periodo.
where 	fecfac-floor(fecfac/100)*100<=30
group by calculated tipo_tarjeta
outer union corr 
   SELECT &periodo. as periodo,
'ACUMULADO' as tipologia,
'TOTAL' as fecha,
sum(monto) as monto, 
          sum(trx) as trx, 
          sum(monto_actual) as monto_actual, 
          sum(trx_actual) as trx_actual, 
          sum(monto_DES) as monto_DES, 
          sum(trx_DES) as trx_DES, 
         case when producto   in ('10','05','06','07') then 'TAM' else 'TR' end as Tipo_tarjeta, 
          count(distinct CUENTA) as clientes
      FROM &LIB_RESUMEN..EPU_MESACTUAL_&periodo.

group by calculated tipo_tarjeta
outer union corr 
   SELECT &periodo. as periodo,
'DIARIO' as tipologia,
put(	fecfac-floor(fecfac/100)*100,2.) as fecha,
sum(monto) as monto, 
          sum(trx) as trx, 
          sum(monto_actual) as monto_actual, 
          sum(trx_actual) as trx_actual, 
          sum(monto_DES) as monto_DES, 
          sum(trx_DES) as trx_DES, 
         case when producto   in ('10','05','06','07') then 'TAM' else 'TR' end as Tipo_tarjeta, 
          count(distinct CUENTA) as clientes
      FROM &LIB_RESUMEN..EPU_MESACTUAL_&periodo.
	  group by calculated tipo_tarjeta,calculated fecha
;QUIT;


%put==========================================================================================;
%put [04] Subida a tableau ;
%put==========================================================================================;





%mend EPU;


%macro ejecutar(A);
DATA _null_;
HOY = day(today());
Call symput("HOY", HOY);
RUN;
%put &HOY;

%if %eval(&HOY.<=5) %then %do;

%EPU(0,&lib_base.,&LIB_RESUMEN.);
%EPU(1,&lib_base.,&LIB_RESUMEN.);
%end;
%else %DO;

%EPU(0,&lib_base.,&LIB_RESUMEN.);

%end;
%mend ejecutar;

%ejecutar(A);

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================        EXPORT_TO_AWS - INI          ===============================*/
/*SUBIDA A AWS*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(mdpg_seguimiento_ff_epu,raw,oracloud,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(mdpg_mes_ff_epu,raw,oracloud,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(mdpg_dia_ff_epu,raw,oracloud,0);


%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(mdpg_seguimiento_ff_epu,&LIB_RESUMEN..MDPG_seguimiento_ff_epu,raw,oracloud,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(mdpg_mes_ff_epu,&LIB_RESUMEN..MDPG_MES_ff_epu,raw,oracloud,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(mdpg_dia_ff_epu,&LIB_RESUMEN..MDPG_dia_ff_epu,raw,oracloud,0);
/*==============================        EXPORT_TO_AWS - END          ===============================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

proc sql noprint;                              
SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_SEGMENTOS_1';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("equipo_datos_procesos_bi@bancoripley.com")
TO = ("&DEST_4","&DEST_5","psallorenzop@bancoripley.com")
CC = ("&DEST_1","&DEST_2","&DEST_3")
SUBJECT="MAIL_AUTOM: Actualización TABLEAU EPU  &periodo. " ;
FILE OUTBOX;
	PUT 'Estimados:';
 	PUT "Data actualizada TABLEAU EPU";  
 	PUT "https://tableau1.bancoripley.cl/#/site/BI_Lab/views/FF_EPU/FFEPU?:iid=1";
    PUT;
    PUT;
    PUT 'Proceso Vers. 02';
    PUT;
    PUT;
    PUT 'Atte.';
    Put 'Equipo Arquitectura de Datos y Automatización BI';
    PUT;
RUN;
FILENAME OUTBOX CLEAR;


/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 


/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
