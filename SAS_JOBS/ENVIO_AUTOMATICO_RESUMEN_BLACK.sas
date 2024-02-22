/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	ENVIO_AUTOMATICO_RESUMEN_BLACK	 ===============================*/

/* CONTROL DE VERSIONES
/* 2022-11-15 -- v03 -- Sergio J.	- Se agrega variable Periodo
/* 2022-09-12 -- v02 -- David V.	- Cambio en la ruta SFTP según se requiere.
/* 2022-09-12 -- v01 -- David V.	- Ajustes mínimos, comentarios, versionamiento, etc.
/* 2022-09-09 -- v00 -- Pedro M.	- Original
/**/

DATA _null_;
periodo = input(put(intnx('month',today(),0,'same'),yymmn6. ),$10.);
Call symput("periodo", periodo);
RUN;
%put &periodo;/*fecha fin actual ok trx-pagos tda 01MAY2019*/

/* VARIABLE TIEMPO - INICIO */
%let tiempo_inicio= %sysfunc(datetime());
options validvarname=any;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='PMUNOZC' PASSWORD='pmun2102' path ='REPORITF.WORLD'  );
create table contratos  as 
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
c.FECALTA as FECALTA_CDP


from MPDT007 a
INNER JOIN BOPERS_MAE_IDE B 
ON A.IDENTCLI=B.PEMID_NRO_INN_IDE
left join MPDT499 C
on(a.cuenta=c.cuenta) and c.PRODDEST='14'
where  a.producto='14'

) A
;QUIT;



PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table cupo  as 
select * 
from connection to ORACLE( 
select 
CODENT,
CENTALTA,
CUENTA,
max(case when linea='0050' then LIMCRELNA*1 else 0 end ) as cupo_compra,
max(case when linea='0051' then LIMCRELNA*1 else 0 end ) as cupo_av,
max(case when linea='0052' then LIMCRELNA*1 else 0 end ) as cupo_sav,
max(case when linea='0053' then LIMCRELNA*1 else 0 end ) as cupo_Spos,
max(case when linea='0054' then LIMCRELNA*1 else 0 end ) as cupo_seguros_OM,
max(case when linea='0056' then LIMCRELNA*1 else 0 end ) as cupo_seguros_TARJ,
max(case when linea='0057' then LIMCRELNA*1 else 0 end ) as cupo_repactacion
from (select a.* from MPDT450 a
inner join mpdt007 b
on(a.cuenta=b.cuenta) and b.producto='14')
group by CODENT,
CENTALTA,
CUENTA
) A
;QUIT;


PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table SALDO  as 
select * 
from connection to ORACLE( 
select 
codent,
centalta,
cuenta,
sum(case when linea='0050' and SITIMP in('D','A')  then  IMPDEUDA1	+
IMPDEUDA2	+
 IMPDEUDA3	+
IMPDEUDA4	+
 IMPDEUDA5	+
IMPDEUDA6	+
IMPDEUDA7	+
 IMPDEUDA8	+
IMPDEUDA9	+
IMPDEUDA10	
 else 0 end )-
sum(case when linea='0050' and SITIMP in('D','A')  then   IMPAPL1	+
IMPAPL2	+
 IMPAPL3	+
 IMPAPL4	+
 IMPAPL5	+
IMPAPL6	+
 IMPAPL7	+
IMPAPL8	+
IMPAPL9	+
IMPAPL10		
 else 0 end )
as SALDO_compra,
sum(case when linea='0051' and SITIMP in('D','A') then   IMPDEUDA1	+
IMPDEUDA2	+
 IMPDEUDA3	+
IMPDEUDA4	+
 IMPDEUDA5	+
IMPDEUDA6	+
IMPDEUDA7	+
 IMPDEUDA8	+
IMPDEUDA9	+
IMPDEUDA10 else 0 end )-
sum(case when linea='0051' and SITIMP in('D','A')  then   IMPAPL1	+
IMPAPL2	+
 IMPAPL3	+
 IMPAPL4	+
 IMPAPL5	+
IMPAPL6	+
 IMPAPL7	+
IMPAPL8	+
IMPAPL9	+
IMPAPL10		
 else 0 end ) as SALDO_av,
sum(case when linea='0052' and SITIMP in('D','A') then   IMPDEUDA1	+
IMPDEUDA2	+
 IMPDEUDA3	+
IMPDEUDA4	+
 IMPDEUDA5	+
IMPDEUDA6	+
IMPDEUDA7	+
 IMPDEUDA8	+
IMPDEUDA9	+
IMPDEUDA10 else 0 end )-
sum(case when linea='0052' and SITIMP in('D','A')  then   IMPAPL1	+
IMPAPL2	+
 IMPAPL3	+
 IMPAPL4	+
 IMPAPL5	+
IMPAPL6	+
 IMPAPL7	+
IMPAPL8	+
IMPAPL9	+
IMPAPL10		
 else 0 end ) as SALDO_sav,
sum(case when linea='0053' and SITIMP in('D','A') then   IMPDEUDA1	+
IMPDEUDA2	+
 IMPDEUDA3	+
IMPDEUDA4	+
 IMPDEUDA5	+
IMPDEUDA6	+
IMPDEUDA7	+
 IMPDEUDA8	+
IMPDEUDA9	+
IMPDEUDA10 else 0 end ) -
sum(case when linea='0053' and SITIMP in('D','A')  then   IMPAPL1	+
IMPAPL2	+
 IMPAPL3	+
 IMPAPL4	+
 IMPAPL5	+
IMPAPL6	+
 IMPAPL7	+
IMPAPL8	+
IMPAPL9	+
IMPAPL10		
 else 0 end ) as SALDO_Spos,
sum(case when linea='0054' and SITIMP in('D','A') then   IMPDEUDA1	+
IMPDEUDA2	+
 IMPDEUDA3	+
IMPDEUDA4	+
 IMPDEUDA5	+
IMPDEUDA6	+
IMPDEUDA7	+
 IMPDEUDA8	+
IMPDEUDA9	+
IMPDEUDA10 else 0 end )-
sum(case when linea='0054' and SITIMP in('D','A')  then   IMPAPL1	+
IMPAPL2	+
 IMPAPL3	+
 IMPAPL4	+
 IMPAPL5	+
IMPAPL6	+
 IMPAPL7	+
IMPAPL8	+
IMPAPL9	+
IMPAPL10		
 else 0 end ) as SALDO_seguros_OM,
sum(case when linea='0056' and SITIMP in('D','A') then   IMPDEUDA1	+
IMPDEUDA2	+
 IMPDEUDA3	+
IMPDEUDA4	+
 IMPDEUDA5	+
IMPDEUDA6	+
IMPDEUDA7	+
 IMPDEUDA8	+
IMPDEUDA9	+
IMPDEUDA10 else 0 end )-
sum(case when linea='0056' and SITIMP in('D','A')  then   IMPAPL1	+
IMPAPL2	+
 IMPAPL3	+
 IMPAPL4	+
 IMPAPL5	+
IMPAPL6	+
 IMPAPL7	+
IMPAPL8	+
IMPAPL9	+
IMPAPL10		
 else 0 end ) as SALDO_seguros_TARJ,
sum(case when linea='0057' and SITIMP in('D','A') then   IMPDEUDA1	+
IMPDEUDA2	+
 IMPDEUDA3	+
IMPDEUDA4	+
 IMPDEUDA5	+
IMPDEUDA6	+
IMPDEUDA7	+
 IMPDEUDA8	+
IMPDEUDA9	+
IMPDEUDA10 else 0 end )-
sum(case when linea='0057' and SITIMP in('D','A')  then   IMPAPL1	+
IMPAPL2	+
 IMPAPL3	+
 IMPAPL4	+
 IMPAPL5	+
IMPAPL6	+
 IMPAPL7	+
IMPAPL8	+
IMPAPL9	+
IMPAPL10		
 else 0 end ) as SALDO_repactacion
from (select a.* from MPDT460 a 
inner join mpdt007 b
on(a.cuenta=b.cuenta) and b.producto='14')
group by
codent,
centalta,
cuenta) A
;QUIT;


proc sql;
create table base_CONTRATOS AS 
select 
a.*,
b.*,
c.*
from contratos as a 
left join cupo as b
on(a.cuenta=b.cuenta)
left join saldo as c
on(a.cuenta=c.cuenta)
;QUIT;

/*informacion de capta digital*/

PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table CAPTA_DIGITAL  as 
select * 
from connection to ORACLE(
select sol_cod_nro_sol_k SOLICITUD, 
sol_cod_ide_cli RUT, 
sol_fch_crc_sol FECHA,
DECODE(substr(OFE_COD_PRD_OFE_K,1,2),'01','TARJETA','02','CAMBIO DE PRODUCTO') PRODUCTO,
ofe_cac_nro_ctt CONTRATO, sol_cod_est_sol ESTADO, decode(sol_cod_cll_sol,3,'ADMISION',9,'MOVIL',2,'ONLINE',14,'ONLINE') CANAL_SOLICITUD, decode(sol_cod_cll_act,3,'ADMISION',9,'MOVIL',2,'ONLINE',14,'ONLINE') CANAL_FINAL
from sfadmi_bco_sol, sfadmi_bco_ofe, sfadmi_bco_tip_prd
where sol_cod_nro_sol_k = ofe_cod_nro_sol_k
and ofe_cod_ind_sol = 1 and
ofe_cod_prd_ofe_k = prd_cod_tip_prd_k
and prd_cod_cod_1 = 0014 and
prd_cod_cod_2 = 0014
and sol_fch_crc_sol >= to_date('01092022','ddmmyyyy')
and ofe_cod_ind_alt = 1) A
;QUIT;

/*informacion de uso*/

proc sql;
create table spos as 
select 
a.*
from publicin.spos_aut_&periodo. as a 
inner join base_CONTRATOS as b
on(a.cuenta=b.cuenta)
;QUIT;

proc sql;
create table TDA as 
select 
a.*
from publicin.TDA_ITF_&periodo. as a 
inner join base_CONTRATOS as b
on(a.cuenta=b.cuenta)
;QUIT;

proc sql;
create table AV as 
select 
a.*
from publicin.TRX_AV_&periodo. as a 
inner join base_CONTRATOS as b
on(a.cuenta=b.cuenta)
;QUIT;

proc sql;
create table SAV as 
select 
a.*
from publicin.TRX_SAV_&periodo. as a 
inner join base_CONTRATOS as b
on(a.cuenta=b.cuenta)
;QUIT;


/*pagos*/

proc sql;
create table PAGOS as 
select 
a.*
from RESULT.PAGOS_DIGITALES_&periodo. as a 
inner join base_CONTRATOS as b
on(a.cuenta=b.cuenta)
;QUIT;


PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table Panes as 
select * 
from connection to ORACLE(
select 
cast(B.PEMID_GLS_NRO_DCT_IDE_K as INT)  RUT,
A.CODENT,
A.CENTALTA,
A.CUENTA,
A.CALPART,
A.CODENT||A.CENTALTA||A.CUENTA  CTTO,
C.FECALTA  FECALTA_CTTO,
C.FECBAJA  FECBAJA_CTTO,

G.NUMPLASTICO,
G.PAN,
G.FECCADTAR,
G.INDULTTAR,
G.NUMBENCTA,
G.FECALTA  FECALTA_TR,
G.FECBAJA  FECBAJA_TR,
G.INDSITTAR,
g.CODMAR,
g.INDTIPT,
J.DESTIPT  TIPO_TARJETA_RSAT,
H.DESSITTAR,
G.FECULTBLQ,
g.CODBLQ,
g.TEXBLQ,
SUBSTR(G.PAN,13,4)  PAN2, 
A.CODENT||A.CENTALTA||A.CUENTA|| SUBSTR(G.PAN,13,4)   CONTRATO_PAN
FROM GETRONICS.MPDT013 A /*CONTRATO de Tarjeta*/
INNER JOIN GETRONICS.MPDT007 C /*CONTRATO*/
ON (A.CODENT=C.CODENT) AND (A.CENTALTA=C.CENTALTA) AND (A.CUENTA=C.CUENTA) 
INNER JOIN BOPERS_MAE_IDE B ON 
A.IDENTCLI=B.PEMID_NRO_INN_IDE
INNER JOIN GETRONICS.MPDT009 G /*Tarjeta*/ 
ON (A.CODENT=G.CODENT) AND (A.CENTALTA=G.CENTALTA) AND (A.CUENTA=G.CUENTA) AND (A.NUMBENCTA=G.NUMBENCTA)
INNER JOIN GETRONICS.MPDT063 H 
ON (G.CODENT=H.CODENT) AND (G.INDSITTAR=H.INDSITTAR)
LEFT JOIN GETRONICS.MPDT060 I 
ON (G.CODBLQ=I.CODBLQ)
left join GETRONICS.MPDT026 J
on(j.CODMAR=G.codmar) and (J.INDTIPT=G.INDTIPT)
where A.CALPART='BE' and g.INDULTTAR='S' and g.INDSITTAR
=5 and 
C.FECBAJA ='0001-01-01' and 	G.FECBAJA='0001-01-01'
and g.CODBLQ=0

)
;QUIT;

proc sql;
create table base_CONTRATOS as 
select distinct 
a.*,
count(distinct b.pan) as NRO_ADICIONALES
from base_CONTRATOS as a 
left join panes as b
on(a.cuenta=b.cuenta) 
group by a.cuenta
;QUIT;

/*exportar*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;


PROC EXPORT DATA=work.base_CONTRATOS
DBMS=xlsx 
OUTFILE= "/sasdata/users94/user_bi/TRASPASO_DOCS/ENVIO_AUTOMATICO_RESUMEN_BLACK/MCBLACK_&fechaeDVN..xlsx"
replace;
sheet="CONTRATOS";
PROC EXPORT DATA=work.CAPTA_DIGITAL
OUTFILE= "/sasdata/users94/user_bi/TRASPASO_DOCS/ENVIO_AUTOMATICO_RESUMEN_BLACK/MCBLACK_&fechaeDVN..xlsx"
DBMS=xlsx;
sheet="CAPTA DIGITAL";
PROC EXPORT DATA=work.SPOS
OUTFILE= "/sasdata/users94/user_bi/TRASPASO_DOCS/ENVIO_AUTOMATICO_RESUMEN_BLACK/MCBLACK_&fechaeDVN..xlsx"
DBMS=xlsx;
sheet="SPOS";
PROC EXPORT DATA=work.TDA
OUTFILE= "/sasdata/users94/user_bi/TRASPASO_DOCS/ENVIO_AUTOMATICO_RESUMEN_BLACK/MCBLACK_&fechaeDVN..xlsx"
DBMS=xlsx;
sheet="TDA";
PROC EXPORT DATA=work.AV
OUTFILE= "/sasdata/users94/user_bi/TRASPASO_DOCS/ENVIO_AUTOMATICO_RESUMEN_BLACK/MCBLACK_&fechaeDVN..xlsx"
DBMS=xlsx;
sheet="AV";
PROC EXPORT DATA=work.SAV
OUTFILE= "/sasdata/users94/user_bi/TRASPASO_DOCS/ENVIO_AUTOMATICO_RESUMEN_BLACK/MCBLACK_&fechaeDVN..xlsx"
DBMS=xlsx;
sheet="SAV";
PROC EXPORT DATA=work.PAGOS
OUTFILE= "/sasdata/users94/user_bi/TRASPASO_DOCS/ENVIO_AUTOMATICO_RESUMEN_BLACK/MCBLACK_&fechaeDVN..xlsx"
DBMS=xlsx;
sheet="PAGOS";
;RUN;

proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_PPFF';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_1';
	SELECT EMAIL into :DEST_7 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'CLAUDIA_PAREDES';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;
%put &=DEST_6;	%put &=DEST_7;

Filename myEmail EMAIL	
    Subject = "MAIL_AUTOM:DETALLE MCBLACK &fechaeDVN."
    From    = ("&EDP_BI.") 
    To      = ("&DEST_4.","&DEST_5.","&DEST_6.","&DEST_7.","carteagas@bancoripley.com",
			  "cvergarar@bancoripley.com","mrodriguez@bancoripley.com")
    CC      = ("&DEST_1.","&DEST_2.","&DEST_3.","iplazam@bancoripley.com")
 attach =("/sasdata/users94/user_bi/TRASPASO_DOCS/ENVIO_AUTOMATICO_RESUMEN_BLACK/MCBLACK_&fechaeDVN..xlsx" content_type="excel") 
    Type    = 'Text/Plain';

Data _null_; File myEmail; 
	PUT "Estimados,";
	PUT "		Adjunto resumen de MCBLACK con fecha: &fechaeDVN.";
	PUT;
	PUT;
	PUT 'Proceso Vers. 03';
	PUT;
	PUT;
	PUT 'Atte.';
	PUT 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
;RUN;
filename myfile "/sasdata/users94/user_bi/TRASPASO_DOCS/ENVIO_AUTOMATICO_RESUMEN_BLACK/MCBLACK_&fechaeDVN..xlsx" ;
data _null_;

rc=fdelete("myfile");

;run;
filename myfile clear;
