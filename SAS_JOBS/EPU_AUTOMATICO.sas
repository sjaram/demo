/*==================================================================================================*/
/*==================================	EQUIPO ARQ.DATOS Y AUTOM.		============================*/
/*==================================	EPU_AUTOMATICO					============================*/
/* CONTROL DE VERSIONES
/* 2023-05-16 -- v06    -- David V.     -- Se quitan comas que daban error.
/* 2023-05-08 -- v05    -- Ale Marinao  -- Se agregan productos Black.
/* 2022-11-18 -- v04	-- Sergio J.	-- Se le agrega el campo periodo a la tabla temporal work.contratoepu_&periodo., 
/* 2022-11-18 -- v03	-- Sergio J.	-- Creación de tabla temporal work.contratoepu_&periodo., 
cambiando el formato de FECHACORTE Y FACTURACION a YYYY-MM-DD para Subir a AWS.
										-- Cambio nombre de tabla en AWS a sas_mdpg_contrato_epu.
/* 2022-11-16 -- v02	-- Sergio J.	-- Exportación a AWS.
/* 2022-10-24 -- v01	-- David V.		-- Versionamiento, automatización en server SAS.
/* 2022-10-24 -- v00 	-- Original 	-- Creado por Pedro, compartido por Nicole para automatizar.
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
periodo = input(put(intnx('month',today(),-&n.,'same'),yymmn6. ),$10.);
INI_FISA = put(intnx('month',today(),-&n.,'begin'),ddmmyy10.);
FIN_FISA = put(intnx('MONTH',today(),-&n.,'end'),ddmmyy10.);
INI_RSAT = put(intnx('month',today(),-&n.,'begin'),yymmdd10.);
FIN_RSAT = put(intnx('MONTH',today(),-&n.,'end'),yymmdd10.);
Call symput("periodo", periodo);
Call symput("INI_FISA", INI_FISA);
Call symput("FIN_FISA", FIN_FISA);
Call symput("INI_RSAT", INI_RSAT);
Call symput("FIN_RSAT", FIN_RSAT);
RUN;


%put &periodo;/*fecha fin actual ok trx-pagos tda 01MAY2019*/
%put &INI_FISA;
%put &FIN_FISA;
%put &INI_RSAT;
%put &FIN_RSAT;



PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table EPU_CORTES as 
select * 
from connection to ORACLE( 
select 
a.SEMUC_COC_EDA_K	as entidad,
a.SEMUC_COC_CEN_ATA_K	as  sucursal,
a.SEMUC_COC_NRO_CTA_K as contrato,
a.SEMUC_CLV_ENC_RUT as rut,
a.SEMUC_FCH_FCN_K as corte,
a.Semuc_Mnt_Cuo_Mes as monto_facturado,
a.Semuc_Coc_Prd as producto,
a.SEMUC_MNT_PAG_MIN_PER as pago_minimo,
/*case when b.Sednd_COC_NRO_CTA_K is not null then b.Sednd_Gls_Trn end as glosa,*/
case when a.Semuc_Est_Dir_Epu in (0,1,2) then 1 else 0 end as SI_EPU_FISICO,
case when a.Semuc_Est_Dir_Epu =3 then 1 else 0 end as SI_EPU_MAIL
/*case when b.Sednd_COC_NRO_CTA_K is not null then 1 else 0 end  as si_mantencionepu,*/
/*b.Sednd_Mnt_Fac*/

from SFEPUS_MAE_NUC_CAB a 
/*left join Sfepus_Det_Nuc_Det b*/
/*on(a.SEMUC_COC_NRO_CTA_K=b.Sednd_COC_NRO_CTA_K) and (a.SEMUC_COC_CEN_ATA_K=b.Sednd_COC_CEN_ATA_K)*/
/*and (b.Sednd_Cod_Tip_Fac in (201,237))*/
/*and (b.Sednd_Fch_Fcn_K>=to_date(%str(%')20/07/2021%str(%'),'dd/mm/yyyy'))*/

where 

a.SEMUC_FCH_FCN_K  between   to_date(%str(%')&ini_fisa.%str(%'),'dd/mm/yyyy') 
and to_date(%str(%')&fin_fisa.%str(%'),'dd/mm/yyyy') 

and a.Semuc_Gls_Emr='S'
and a.Semuc_Dia_Mor<80 

) A
;QUIT;

/*epu cobro */

PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table EPU_cobro as 
select * 
from connection to ORACLE( 
select 

a.Sednd_COC_CEN_ATA_K	as  sucursal,
a.Sednd_COC_NRO_CTA_K as contrato,
a.Sednd_Cod_Tip_Fac,
a.Sednd_Fch_Fcn_K,
a.Sednd_Mnt_Fac,
a.Sednd_Gls_Trn
from  Sfepus_Det_Nuc_Det a
where 
a.Sednd_Fch_Fcn_K  between   to_date(%str(%')&ini_fisa.%str(%'),'dd/mm/yyyy') 
and to_date(%str(%')&fin_fisa.%str(%'),'dd/mm/yyyy') 
and a.Sednd_Cod_Tip_Fac in (201,237)
) A
;QUIT;

proc sql;
create table epu_cobro2 as 
select 
a.*,
b.Sednd_Cod_Tip_Fac as Tip_Fac_201,
b.Sednd_Fch_Fcn_K as fec_201,
b.Sednd_Mnt_Fac as monto_201,
b.Sednd_Gls_Trn as glosa_201,

c.Sednd_Cod_Tip_Fac as Tip_Fac_237,
c.Sednd_Fch_Fcn_K as fec_237,
c.Sednd_Mnt_Fac as monto_237,
c.Sednd_Gls_Trn as glosa_237
from (select distinct sucursal,
contrato
from EPU_cobro) as a 
left join (select * from EPU_cobro where Sednd_Cod_Tip_Fac in (201)) as b
on(a.contrato=b.contrato) and (a.sucursal=b.sucursal)
left join (select * from EPU_cobro where Sednd_Cod_Tip_Fac in (237)) as c
on(a.contrato=c.contrato) and (a.sucursal=c.sucursal)
;QUIT;

proc sql;
create table base_epu as 
select 
a.*,
case when b.contrato is not null then coalesce(b.glosa_201,b.glosa_237) end as glosa,
case when b.contrato is not null then 1 else 0 end  as si_mantencionepu,
case when b.contrato is not null then coalesce(b.monto_201,0)+coalesce(b.monto_237,0) end   as Sednd_Mnt_Fac
from EPU_CORTES as a 
left join EPU_cobro2 as b
on(a.contrato=b.contrato) and (a.sucursal=b.sucursal)
;QUIT;



PROC SQL;
   CREATE TABLE WORK.UNICOS AS 
   SELECT t1.ENTIDAD, 
          t1.SUCURSAL, 
          t1.CONTRATO, 
          input(substr(t1.RUT,1,length(t1.rut)-1),best.) as rut, 
          datepart(t1.CORTE) format=date9. as facturacion, 
          t1.MONTO_FACTURADO*1 as Saldo, 
case 
when t1.PRODUCTO='01' then 'TR (con revolving)' 
when t1.PRODUCTO='03' then 'TR (sin revolving)' 
when t1.PRODUCTO='05' then 'TAM (con revolving)' 
when t1.PRODUCTO='06' then 'TAM (sin revolving)' 
when t1.PRODUCTO='07' then 'TAM chip' 
when t1.PRODUCTO='10' then 'Mastercard Cerrada '
when t1.PRODUCTO='14' then 'Mastercard Black '
end as Tipo_Producto, 
          t1.PAGO_MINIMO*1 as PAGO_MINIMO, 
          t1.SI_EPU_FISICO as SI_EPUFISICO, 
          t1.SI_EPU_MAIL as SI_EPUMAIL, 
          t1.SI_MANTENCIONEPU, 
		  t1.glosa,
          sum(t1.SEDND_MNT_FAC*1) as Mto_Mantencion
      FROM WORK.base_epu t1

group by 
t1.ENTIDAD, 
          t1.SUCURSAL, 
          t1.CONTRATO,
		  calculated RUT, 
          t1.CORTE, 
          t1.MONTO_FACTURADO, 
          calculated Tipo_Producto, 
          t1.PAGO_MINIMO, 
          t1.SI_EPU_FISICO, 
          t1.SI_EPU_MAIL, 
          t1.SI_MANTENCIONEPU,
		  t1.glosa
;
QUIT;


proc sql;
create table  &lib_base..sb_contratoepu_&periodo. as 
select 
RUT,
input(CONTRATO,best.) as CONTRATO,
input(SUCURSAL,best.) as SUCURSAL,
FACTURACION	,
Saldo,
PAGO_MINIMO,
Tipo_Producto,
SI_EpuMail,
SI_EpuFisico,
SI_MantencionEpu,
case when SI_MantencionEpu=1 then FACTURACION end format=date9. as fechacorte,
Glosa,
Mto_Mantencion
from unicos 
;QUIT;

/*CAMBIO EN EL FORMATO DE FACTURACION Y FECHACORTE PARA AWS YYYY-MM-DD*/
DATA work.contratoepu_&periodo.;
SET  &lib_base..sb_contratoepu_&periodo. ;
PERIODO=&periodo.;
FORMAT FACTURACION e8601da. FECHACORTE e8601da.;
RUN;

proc sql;
drop table EPU_CORTES;
drop table EPU_cobro;
drop table base_epu;
drop table unicos;
;QUIT;




PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table MPDT012  as 
select * 
from connection to ORACLE( 
select 
a.CODENT,
a.CENTALTA,
a.CUENTA,
a.INDNORCOR,
a.TIPOFAC,
a.FECFAC,
a.INDMOVANU,
a.IMPFAC,
a.DESCUENTO,
a.linea,
a.pan
from GETRONICS.MPDT012   a 
where  a.FECFAC between %str(%')&ini_rsat.%str(%') and %str(%')&fin_rsat.%str(%')
and a.TIPOFAC in (237,76)
) A
;QUIT;



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
a.FECALTA  FECALTA_CTTO,
a.FECBAJA  FECBAJA_CTTO,
a.PRODUCTO,
a.SUBPRODU,
a.CONPROD,
a.GRUPOLIQ,
a.INDBLQOPE,
case when a.GRUPOLIQ=1 then 5
when a.GRUPOLIQ=2 then 10
when a.GRUPOLIQ=3 then 15
when a.GRUPOLIQ=4 then 20
when a.GRUPOLIQ=5 then 25
when a.GRUPOLIQ=6 then 30
when a.GRUPOLIQ=7 then 18 end as corte 

from MPDT007 a
INNER JOIN BOPERS_MAE_IDE B 
ON A.IDENTCLI=B.PEMID_NRO_INN_IDE

where a.PRODUCTO not in ('08','12','13')
) A
;QUIT;


proc sql;
create table MPDT012_v2 as 

select 
a.*,
b.rut ,
b.PRODUCTO,
b.SUBPRODU,
b.CONPROD,
b.corte
from MPDT012 as a 
left join cuentas as b
on(a.cuenta=b.cuenta) and (a.centalta=b.centalta)

;QUIT;

proc sql;
create table MPDT012_v3 as 
select 
a.*,
b.FACTURACION,
b.si_mantencionepu

from MPDT012_v2 as a 
left join &lib_base..sb_contratoepu_&periodo. as b
on(input(a.cuenta,best.)=b.contrato)
;QUIT;


proc sql;
create table &LIB_RESUMEN..EPU_MESACTUAL_&periodo. as 
select 
RUT,
PRODUCTO,
SUBPRODU,
CONPROD,
pan,
input(compress(FECFAC,'-'),best.) as fecfac,
case when si_mantencionepu=1 then day(FACTURACION) else  CORTE end as corte,
CODENT,
CENTALTA,
CUENTA,
sum(IMPFAC) as monto,
count(cuenta) as trx,

sum(case when si_mantencionepu=1 and input(compress(FECFAC,'-'),best.)<=year(FACTURACION)*10000+month(FACTURACION)*100
+day(FACTURACION) then 

IMPFAC else 0 end ) as monto_actual,
count(case when si_mantencionepu=1 and input(compress(FECFAC,'-'),best.)<=year(FACTURACION)*10000+month(FACTURACION)*100
+day(FACTURACION) then cuenta end ) as trx_actual,

sum(case when  input(compress(FECFAC,'-'),best.)>year(FACTURACION)*10000+month(FACTURACION)*100
+day(FACTURACION) then 

IMPFAC else 0 end ) as monto_DES,
count(case when  input(compress(FECFAC,'-'),best.)>year(FACTURACION)*10000+month(FACTURACION)*100
+day(FACTURACION) then cuenta end ) as trx_DES

from MPDT012_v3
group by 
RUT,
PRODUCTO,
SUBPRODU,
CONPROD,
calculated CORTE,
CODENT,
CENTALTA,
CUENTA,
calculated fecfac,
 pan
;QUIT;


proc sql;
drop table cuentas;
drop table mpdt012;
drop table mpdt012_v2;
;QUIT;
 
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_mdpg_contrato_epu,raw,sasdata,-&n.);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_mdpg_contrato_epu,work.contratoepu_&periodo.,raw,sasdata,-&n.);

%mend EPU;


%macro ejecutar(A);
DATA _null_;
HOY = day(today());
Call symput("HOY", HOY);
RUN;
%put &HOY;

%if %eval(&HOY.<=2) %then %do;

%EPU(0,&lib_base.,&LIB_RESUMEN.);
%EPU(1,&lib_base.,&LIB_RESUMEN.);


%end;
%else %DO;

%EPU(0,&lib_base.,&LIB_RESUMEN.);

%end;
%mend ejecutar;

%ejecutar(A);


/*	Fecha ejecución del proceso	*/
data _null_;
execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechaeDVN", execDVN) ;
RUN;
%put &fechaeDVN;/*fecha ejecucion proceso */

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_CLIENTES';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CLIENTES_2';
	SELECT EMAIL into :DEST_7 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PRISCILLA_SALLORENZO';
	SELECT EMAIL into :DEST_8 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_SEGMENTOS';
	SELECT EMAIL into :DEST_9 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_SEGMENTOS_1';

quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;
%put &=DEST_6;	%put &=DEST_7;	%put &=DEST_8;	%put &=DEST_9;


data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4","&DEST_5","&DEST_6","&DEST_7","&DEST_8","&DEST_9")
CC = ("&DEST_1","&DEST_2","&DEST_3")
SUBJECT="MAIL_AUTOM: Actualización TABLEAU EPU &periodo. " ;
FILE OUTBOX;
 PUT 'Estimados:';
 PUT "		Proceso EPU_AUTOMATICO, ejecutado con fecha: &fechaeDVN";  
 PUT "		Data actualizada TABLEAU EPU";  
 PUT "		https://tableau1.bancoripley.cl/#/site/BI_Lab/views/FF_EPU/FFEPU?:iid=1";
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 06'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */
