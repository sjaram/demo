/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	Onboarding_CCTC_Semana		 	 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-08-05 -- V03 -- David V.	-- Se agrega replace al export de archivo, para en caso de reejecutar actualice la salida.
/* 2022-08-01 -- V02 -- David V.	-- Se agrega correo dbergoeingc@bancoripley.com
/* 2022-07-27 -- V01 -- Benja M.	-- Original

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

options validvarname=any;

%let libreria=RESULT;
%let n=1;

DATA _NULL_;
fec_proceso=put(intnx('day',today(),0,'same'), yymmddn8.);
periodo_act= input(put(intnx('month',today(),-&n.,'same'),yymmn6. ),$10.);
periodo_ant= input(put(intnx('month',today(),-&n.-1,'same'),yymmn6. ),$10.);
periodo_ant2= input(put(intnx('month',today(),-&n.-2,'same'),yymmn6. ),$10.);
ayer=put(intnx('day',today(),-&n,'same'), yymmddn8.);
call symput("fec_proceso",fec_proceso);
Call symput("periodo_act", periodo_act);
Call symput("periodo_ant", periodo_ant);
Call symput("periodo_ant2", periodo_ant2);
Call symput("fecha_ayer", ayer);
run;

%put &fec_proceso;
%put &periodo_act;
%put &periodo_ant;
%put &periodo_ant2;
%put &fecha_ayer;


proc sql;
create table WORK.capta_cc as
select distinct
rut_cliente as rut,
year(fecha)*10000+month(fecha)*100+day(fecha) as fecha_capta,
'CC' as producto
from result.capta_salida 
where FECHA=intnx('day',today(),-1)
and producto = 'CUENTA CORRIENTE'
and VIA = 'HOMEBAN'
;quit;


%if(%sysfunc(exist(PUBLICIN.ACT_TR_&periodo_ant.))) %then %do;
PROC SQL NOERRORSTOP;
CREATE TABLE WORK.ACT_TR AS
SELECT DISTINCT
*
FROM PUBLICIN.ACT_TR_&periodo_ant. 
WHERE VU_IC=1
;RUN;
%end;
%else %do;
PROC SQL;
CREATE TABLE WORK.ACT_TR AS
SELECT DISTINCT
*
FROM PUBLICIN.ACT_TR_&periodo_ant2. 
WHERE VU_IC=1
;RUN;
%end;


proc sql;
create table WORK.capta_tam as
select distinct
rut_cliente as rut,
year(fecha)*10000+month(fecha)*100+day(fecha) as fecha_capta,
'TAM' as producto
from result.capta_salida 
where FECHA=intnx('day',today(),-1)
and producto in ('TAM','TAM_CERRADA','TAM_CUOTAS')
and VIA = 'HOMEBAN'
;quit;


proc sql;
create table WORK.capta_cdp as
select distinct
rut_cliente as rut,
year(fecha)*10000+month(fecha)*100+day(fecha) as fecha_capta,
'CDP' as producto
from result.capta_salida 
where FECHA=intnx('day',today(),-1)
and producto = 'CAMBIO DE PRODUCTO'
and VIA = 'HOMEBAN'
;quit;

proc sql;
create table WORK.cc_tc as
select distinct a.* from WORK.capta_cc as a
union
select distinct b.* from WORK.capta_tam as b
union 
select distinct d.* from WORK.capta_cdp as d
;quit;


proc sql;
create table WORK.producto as
select distinct
a.*,
case when e.rut is not null then 1 else 0 end as captado_cc,
case when b.rut is not null then 1 else 0 end as captado_tam,
case when d.rut is not null then 1 else 0 end as captado_cdp

from WORK.cc_tc as a
left join WORK.capta_tam as b
on a.rut = b.rut
left join WORK.capta_cdp as d
on a.rut = d.rut
left join WORK.capta_cc as e
on a.rut = e.rut

;quit;


/*SACAR DV*/
PROC SQL;
CREATE TABLE DATA1 AS
SELECT *,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),1,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),1,1),BEST32.) END AS DIG1,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),2,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),2,1),BEST32.) END AS DIG2,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),3,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),3,1),BEST32.) END AS DIG3,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),4,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),4,1),BEST32.) END AS DIG4,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),5,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),5,1),BEST32.) END AS DIG5,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),6,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),6,1),BEST32.) END AS DIG6,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),7,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),7,1),BEST32.) END AS DIG7,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),8,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),8,1),BEST32.) END AS DIG8
FROM work.producto as a
;QUIT;


PROC SQL;
CREATE TABLE DATA2 AS
SELECT *,
11-(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)-
            (INT(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)/11)*11)) AS DIG,
CASE 
WHEN 11-(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)-
            (INT(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)/11)*11))=11 THEN '0'
WHEN 11-(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)-
            (INT(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)/11)*11))=10 THEN 'K'
ELSE PUT(11-(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)-
            (INT(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)/11)*11)),BEST1.) END AS DV_2
FROM DATA1
;QUIT;


proc sql;
create table WORK.base_onboarding_1 as 
select distinct
a.rut,
a.dv_2 as rut_dv,
a.fecha_capta,
case 
	when a.captado_cc=1 and a.captado_tam=0 and a.captado_cdp=0 then '01.CC'
	when a.captado_cc=0 and a.captado_tam=1 and a.captado_cdp=0 then '02.TAM'
	when a.captado_cc=0 and a.captado_tam=0 and a.captado_cdp=1 then '03.CDP'
	when a.captado_cc=1 and a.captado_tam=1 and a.captado_cdp=0 then '04.CC+TAM'
	when a.captado_cc=1 and a.captado_tam=0 and a.captado_cdp=1 then '05.CC+CDP'
	when a.captado_cc=0 and a.captado_tam=1 and a.captado_cdp=1 then '06.TAM+CDP'
end as tipo_producto,
case when d.primer_nombre is not null then d.primer_nombre else 'S.I' end as nombre,
case when d.paterno is not null then d.paterno else 'S.I' end as paterno,
case when d.materno is not null then d.materno else 'S.I' end as materno,
case when b.email is not null then b.email else 'NULL' end as email,
case when c.telefono is not null then cat('569',c.telefono) else 'NULL' end as telefono,
case when e.rut is not null then 1 else 0 end as CV_Tenencia,
case when f.rut is not null then 1 else 0 end as tc_tenencia

from WORK.DATA2 as a
left join publicin.base_trabajo_email as b
	on a.rut = b.rut
left join publicin.fonos_movil_final as c
	on a.rut = c.clirut
left join publicin.base_nombres as d
	on a.rut = d.rut
left join (select distinct rut from result.ctavta1_stock where estado_cuenta='vigente') as e
	on a.rut = e.rut
left join WORK.act_tr as f
	on a.rut = f.rut

where a.rut not in (select rut from publicin.lnegro_call)
and a.rut not in (select rut from publicin.lnegro_car)
;quit;


proc sql;
create table WORK.base_call_limpia as
select a.*
from work.base_onboarding_1 a
left join PUBLICIN.LNEGRO_CAR b
on a.rut = b.rut
where b.TIPO_INHIBICION	<> "FALLECIDOS";
quit;


PROC SQL ;
CONNECT TO ORACLE AS  bopers (PATH="REPORITF.WORLD" USER='SAS_USR_BI' PASSWORD='SAS_23072020');
CREATE TABLE WORK.bopers_fono AS 
SELECT * FROM CONNECTION TO bopers(
select distinct 
ide.PEMID_GLS_NRO_DCT_IDE_K as rut,
ide.pemid_nro_inn_ide as idclte, 
fon.pemfo_nro_fon as celular, 
fon.PEMFO_COD_EST_LCL as EST_ACT,
fon.PEMFO_FCH_VER_FON as FEC_VERIF, 
fon.PEMFO_FCH_FIN_ACL as FEC_ACT,
fon.PEMFO_NRO_SEQ_FON_K as NRO_SEQ, 
dml.PEMDM_COD_DML_PPA as tip_dir
FROM  
bopers_mae_ide ide,
bopers_mae_dml dml, 
bopers_rel_ing_lcl lcl, 
bopers_mae_fon fon,
BOTGEN_MAE_UBC_GEO GEN
where
fon.pemfo_cod_tip_fon = 4 and
fon.pemfo_cod_est_lcl <> 6 and
/*fon.PEMFO_COD_EST_LCL = 2 and*/
fon.pemid_nro_inn_ide_k = ide.pemid_nro_inn_ide and
fon.pemfo_nro_seq_fon_k = lcl.peril_nro_seq_lcl_dos_k and
lcl.peril_cod_tip_lcl_dos_k = 5 and
lcl.peril_cod_tip_lcl_uno_k = 1 and
lcl.peril_nro_seq_lcl_uno_k = dml.PEMDM_NRO_SEQ_DML_K and
lcl.pemid_nro_inn_ide_k = ide.pemid_nro_inn_ide and
dml.pemid_nro_inn_ide_k = ide.pemid_nro_inn_ide and
dml.PEMDM_COD_DML_PPA = 1 and
dml.pemdm_cod_tip_dml = 1 and
dml.pemdm_cod_neg_dml = 1
AND dml.PEMDM_COD_UBC_3ER = GEN.TGMUG_COD_UBC_GEO_K) A;
QUIT;


/*Cruce base call limpia con bopers*/

proc sql;
create table WORK.base_call_bopers as
select a.*,
b.EST_ACT,
b.NRO_SEQ, 
case 
when b.celular is not null then cats(569,b.celular)
else 'NULL' end as fono_bopers
from work.BASE_CALL_LIMPIA a
left join work.BOPERS_FONO b
on a.rut = input(b.rut,best.)
order by a.rut
;
quit;


/*Rescata registro con nro secuencia mayor - Registro mas actualizado - Elimina duplicados*/

proc sql;
create table WORK.base_call_max_seq as
select a.rut, 
max(a.NRO_SEQ) as NRO_SEQ
from work.base_call_bopers a
group by a.rut
;
QUIT;

/*Cruza tabla max nro secuencia con cruce bopers*/

proc sql;
create table WORK.onboarding_ctacte_tc_1 as
select b.RUT,
b.rut_dv,
b.fecha_capta,
b.tipo_producto,
b.nombre,
b.paterno,
b.materno,
b.email,
b.fono_bopers as telefono,
b.CV_Tenencia,
b.tc_tenencia,
' ' as "1.Nota Escala Experiencia(0-10)"n,
' ' as "2.Descargó App Banco Ripley"n,
' ' as "3.Ha utilizado CC/TC BR"n,
' ' as "4.Como ha utilizado CC (A,C,Tef)"n,
' ' as "5.Activó Rpass"n,
' ' as "6.Utilizó Cupón de Dcto (TC)"n
from WORK.base_call_max_seq a
left join  WORK.base_call_bopers b
on a.rut = b.rut
and a.NRO_SEQ = b.NRO_SEQ
;
quit;



/*guardar en libreria*/
proc sql;
create table &libreria..ONB_CCTC_SEMANA_&fec_proceso. as
select distinct
*
from onboarding_ctacte_tc_1
;quit;



/*para exportar archivo en correo*/
PROC EXPORT DATA=&libreria..ONB_CCTC_SEMANA_&fec_proceso.
   OUTFILE="/sasdata/users94/user_bi/CC/ONB_CCTC_SEMANA_&fec_proceso..csv" 
   DBMS=dlm replace; 
   delimiter=';'; 
   PUTNAMES=YES; 
RUN;

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */

/*fecha proceso*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*preparacion envio correo*/
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_PPFF';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_1';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_2';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;	
%put &=DEST_6;

/*envio correo y adjunto archivo*/
data _null_;
FILENAME OUTBOX EMAIL
FROM	= ("&EDP_BI")
TO 		= ("mvargasc@bancoripley.com","ivivancom@bancoripley.com","cparedesp@bancoripley.com")
CC 		= ("&DEST_1","&DEST_2","&DEST_3","&DEST_4","&DEST_5","&DEST_6","jriverar@bancoripley.com","carteagas@bancoripley.com","cparrab@bancoripley.com","vsaavedraq@bancoripley.com","dbergoeingc@bancoripley.com")
ATTACH	= "/sasdata/users94/user_bi/CC/ONB_CCTC_SEMANA_&fec_proceso..csv"  
SUBJECT = ("MAIL_AUTOM: Proceso ONBOARDING CTA CTE Y TC");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "		Proceso PILOTO_ONBOARDING_CCTC, ejecutado automáticamente con fecha: &fechaeDVN";  
 PUT ;
 PUT "	  	Se adjunta archivo: ONB_CCTC_SEMANA_&fec_proceso..csv";
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 03'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
