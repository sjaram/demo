/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROC_PANEL_CTA_VTA			================================*/
/* CONTROL DE VERSIONES
/* 2022-03-31 ---- Esteban P. -- Se actualizan los correos: Se desvincula de los destinatarios a Sebastián Barrera y vmartinezf
/* 2021-04-16 ----	Modificaciones Pedro M.*/
/* 2020-11-25 ----	Original
*/
/*==================================================================================================*/

/*########################################################################################################*/
/* Nuevo Panel de Cuenta Vista (25-11-20) */
/*########################################################################################################*/


/***************************************** Validar Proceso ************************************************/


/***************************************** Comenzar Proceso ************************************************/
options validvarname=any;
%let libref=RESULT;

%macro PANEL_CV(n,libref);
/*Definir Macro Parametros*/



DATA _NULL_;
per = put(intnx('month',today(),-&n.,'end'), yymmn6.);
INI=put(intnx('month',today(),-&n.,'begin'), date9.);
FIN=put(intnx('month',today(),-&n.,'end'), date9.);
fec_proceso=put(intnx('day',today(),0,'same'), yymmddn8.);
INI_NUM=put(intnx('month',today(),-&n.,'begin'), yymmddn8.);
FIN_NUM=put(intnx('month',today(),-&n.,'end'), yymmddn8.);

call symput("periodo",per);
call symput("INI",INI);
call symput("FIN",FIN);
call symput("INI_NUM",INI_NUM);
call symput("FIN_NUM",FIN_NUM);
call symput("fec_proceso",fec_proceso);
run;
%put &periodo;
%put &INI;
%put &FIN;
%put &INI_NUM;
%put &FIN_NUM;
%put &fec_proceso;
/*::::::::::::::::::::::::::*/
proc sql   noprint inobs=1;
select 
put(cat(substr(put(&INI_NUM,8.),7,2),'/',substr(put(&INI_NUM,8.),5,2),'/',substr(put(&INI_NUM,8.),1,4)),$10. ) format=$10. as INI_CHAR,
put(cat(substr(put(&FIN_NUM,8.),7,2),'/',substr(put(&FIN_NUM,8.),5,2),'/',substr(put(&FIN_NUM,8.),1,4)),$10.)  format=$10. as FIN_CHAR
into
:INI_CHAR,
:FIN_CHAR
from pmunoz.codigos_capta_cdp
;QUIT;

%let INI_CHAR=&INI_CHAR;
%let FIN_CHAR=&FIN_CHAR;
%put &INI_CHAR;
%put &FIN_CHAR;

%put--------------------------------------------------------------------------------------------------;
%put [00.3] Conexion a FISA;
%put--------------------------------------------------------------------------------------------------;

%let path_ora      = '(DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SID = ripleyc)))'; 
%let user_ora      = 'RIPLEYC'; 
%let pass_ora      = 'ri99pley';
%let conexion_ora  = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 

%put--------------------------------------------------------------------------------------------------;
%put [00.4] Base dotación;
%put--------------------------------------------------------------------------------------------------;


%if (%sysfunc(exist(nlagosg.dotacion_&periodo.))) %then %do;
PROC SQL NOERRORSTOP ;
CREATE TABLE DOTACION AS 
SELECT 
*
FROM nlagosg.dotacion_&periodo.
;RUN; 
%end;
%else %do;

PROC SQL noprint;   
select max(anomes) as Max_anomes
into :Max_anomes
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'NLAGOSG.DOTACION_%' 
and length(Nombre_Tabla)=length('NLAGOSG.DOTACION_201810')
) as x
;QUIT;

data _null_ ;
per_DOT=put(&Max_anomes,$6.);
Call symput('per_DOT',per_DOT);
run;
%put &per_DOT;

PROC  SQL;
CREATE TABLE DOTACION AS
SELECT 
*
FROM nlagosg.dotacion_&per_DOT
;RUN;
%end;

%put--------------------------------------------------------------------------------------------------;
%put [00.5] Base Panes;
%put--------------------------------------------------------------------------------------------------;

LIBNAME MPDT  ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME R_BOPERS ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME R_get ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017';


proc sql;
create table foto_panes_hoy  as 
select 
RUT,
CODENT,
CENTALTA,
CUENTA,
CALPART,
CTTO,
CASE WHEN FECBAJA_CTTO = '0001-01-01' THEN 1 ELSE 0 END AS T_CTTO_VIGENTE,
FECALTA_CTTO,
FECBAJA_CTTO,
CASE WHEN SUBSTR(PAN,1,6) IN('628156') THEN 'CERRADA'
WHEN SUBSTR(PAN,1,4) IN('6392') THEN 'CUENTA VISTA'
when substr(pan,1,6) in ('525384') then 'CUENTA VISTA'
WHEN SUBSTR(PAN,1,6) IN('549070')AND INPUT(LEFT(SUBSTR(PAN,1,7)),BEST.) >=5490702 THEN 'TAM CHIP' 
WHEN SUBSTR(PAN,1,6) IN('549070')AND INPUT(LEFT(SUBSTR(PAN,1,7)),BEST.) <5490702 THEN 'TAM' 
ELSE 'CERRADA' END AS TIPO_TR, 
NUMPLASTICO,
PAN,
panant,
FECCADTAR,
INDULTTAR,
NUMBENCTA,
 FECALTA_TR,
FECBAJA_TR,
INDSITTAR,
DESSITTAR,
FECULTBLQ,
CODBLQ as cod_bloq_tr,
CASE WHEN CODBLQ = 1 AND TEXBLQ = 'BLOQUEO TARJETA NO ISO'  THEN 'BLOQUEO TARJETA NO ISO' 
WHEN CODBLQ = 1 AND TEXBLQ NOT IN ('BLOQUEO TARJETA NO ISO') THEN 'ROBO/CODIGO_BLOQUEO' 
WHEN CODBLQ IN (79,98)  THEN 'CAMBIO DE PRODUCTO'
WHEN CODBLQ IN (16,43)  THEN 'FRAUDE' 
WHEN CODBLQ > 1 AND CODBLQ NOT IN (16,43,79,98) THEN DESBLQ END AS MOTIVO_BLOQUEO,
CASE WHEN INDSITTAR=5 AND FECALTA_TR<>'0001-01-01' AND FECBAJA_TR='0001-01-01' AND CODBLQ=0 
THEN 1 ELSE 0 END AS T_TR_VIG,
PAN2, 
CONTRATO_PAN

from (
select 
B.PEMID_GLS_NRO_DCT_IDE_K  AS RUT,
A.CODENT,
A.CENTALTA,
A.CUENTA,
A.CALPART,
A.CODENT||A.CENTALTA||A.CUENTA as CTTO,
C.FECALTA as FECALTA_CTTO,
C.FECBAJA as FECBAJA_CTTO,

G.NUMPLASTICO,
G.PAN,
G.panant,
G.FECCADTAR,
G.INDULTTAR,
G.NUMBENCTA,
G.FECALTA AS FECALTA_TR,
G.FECBAJA AS FECBAJA_TR,
G.INDSITTAR,
H.DESSITTAR,
G.FECULTBLQ,
g.CODBLQ,
g.TEXBLQ,
I.DESBLQ,
SUBSTR(G.PAN,13,4) as PAN2, 
A.CODENT||A.CENTALTA||A.CUENTA|| SUBSTR(G.PAN,13,4)  as CONTRATO_PAN
FROM mpdt.MPDT013 A /*CONTRATO de Tarjeta*/
INNER JOIN mpdt.MPDT007 C /*CONTRATO*/
ON (A.CODENT=C.CODENT) AND (A.CENTALTA=C.CENTALTA) AND (A.CUENTA=C.CUENTA) 
INNER JOIN R_BOPERS.BOPERS_MAE_IDE B ON 
INPUT(A.IDENTCLI,BEST.)=B.PEMID_NRO_INN_IDE
INNER JOIN mpdt.MPDT009 G /*Tarjeta*/ 
ON (A.CODENT=G.CODENT) AND (A.CENTALTA=G.CENTALTA) AND (A.CUENTA=G.CUENTA) AND (A.NUMBENCTA=G.NUMBENCTA)
INNER JOIN mpdt.MPDT063 H 
ON (G.CODENT=H.CODENT) AND (G.INDSITTAR=H.INDSITTAR)
LEFT JOIN mpdt.MPDT060 I 
ON (G.CODBLQ=I.CODBLQ)
where c.producto='08'
) 
;QUIT;


%put==================================================================================================;
%put [01] Base de datos de Stock de Cuenta Vista;
%put==================================================================================================;

%put--------------------------------------------------------------------------------------------------;
%put [01.1] Generar Tabla Stock de Cuenta Vista;
%put--------------------------------------------------------------------------------------------------;

PROC SQL  NOERRORSTOP;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );

create table SB_Stock_Cuenta_Vista  as
select * from connection to ORACLE
( 
SELECT 
CAST(SUBSTR(a.cli_identifica,1,length(a.cli_identifica)-1) AS INT)  rut,
SUBSTR(a.cli_identifica,length(a.cli_identifica),1)  dv,
/*b.vis_pro,*/
b.vis_numcue  cuenta, 
/*b.VIS_TIP  TIPO_PRODUCTO,*/
/*b.vis_fechape,*/ 
cast(TO_CHAR( b.vis_fechape,'YYYYMMDD') as INT) as FECHA_APERTURA,
/*b.VIS_FECHCIERR,*/ 
cast(TO_CHAR( b.VIS_FECHCIERR,'YYYYMMDD') as INT) as FECHA_CIERRE,
/*b.vis_status  estado,*/
CASE WHEN b.VIS_PRO=4 THEN 'CUENTA_VISTA'
WHEN b.VIS_PRO=40 THEN 'LCA' END  DESCRIP_PRODUCTO,
CASE WHEN b.vis_status ='9' THEN 'cerrado' 
when b.vis_status ='2' then 'vigente' end as estado_cuenta,
/*c.DES_CODTAB,*/
b.VIS_SUC as SUCURSAL_APERTURA,
c.DES_CODIGO COD_CIERRE_CONTRATO,
c.DES_DESCRIPCION DESC_CIERRE_CONTRATO

 
from  tcap_vista  b 
inner join  tcli_persona   a
on(a.cli_codigo=b.vis_codcli) 
left join tgen_desctabla  c
on(b.VIS_CODTAB=c.DES_CODTAB) and 	(b.VIS_CAUCIERR=c.DES_CODIGO)

where 
b.vis_mod=4
and (b.VIS_PRO=4)
and b.vis_tip=1  
AND (b.vis_status='2' or b.vis_status='9') 
) ;
disconnect from ORACLE;
QUIT;

%put--------------------------------------------------------------------------------------------------;
%put [01.2] Captados digitales;
%put--------------------------------------------------------------------------------------------------;

PROC SQL ;
CONNECT TO ORACLE AS REPORTITF (PATH="REPORITF.WORLD" USER='KMARTINEZ' PASSWORD='kmar2102');
CREATE TABLE CURSE_debito AS 
SELECT * FROM CONNECTION TO REPORTITF(
SELECT TAR.TAR_CAC_NRO_CTT_K NUMERO_CONTRATO,
TAR.TAR_CAC_NRO_PAN_K NUMERO_TARJETA,
SUBSTR(PRD.PRD_CAC_NRO_CTT,9) NUMERO_CUENTA_VISTA,
SOL.SOL_COD_IDE_CLI RUT_CLIENTE, 
PER.PER_CAC_IDE_CLI_DV DV, 
SOL.SOL_FCH_ALT_SOL  FECHA_SOLICITUD, 
SOL.SOL_COD_NRO_SOL_K NUMERO_SOLICITUD, 
SOL.SOL_COD_EST_SOL ESTADO
FROM SFADMI_BCO_SOL SOL 
INNER JOIN SFADMI_ADM.SFADMI_BCO_TAR TAR
   ON TAR.TAR_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
INNER JOIN SFADMI_BCO_PRD_SOL PRD
   ON TAR.TAR_COD_NRO_SOL_K = PRD.PRD_COD_NRO_SOL_K
   AND TAR.TAR_COD_TIP_PRD_K = PRD.PRD_COD_TIP_PRD_K
INNER JOIN SFADMI_BCO_DAT_PER PER
   ON PRD.PRD_COD_NRO_SOL_K = PER.PER_COD_NRO_SOL_K
 AND SOL.SOL_COD_IDE_CLI = PER.PER_COD_IDE_CLI_K
WHERE 
 SUBSTR(TAR.TAR_COD_TIP_PRD_K,1,2) = '04'
AND (SOL.SOL_COD_CLL_ACT = 14 OR SOL.SOL_COD_CLL_ANT = 14)
AND SOL.SOL_COD_CLL_ADM = 2
and sol.sol_fch_crc_sol between  to_date(%str(%')&INI_CHAR.%str(%'),'dd/mm/yyyy') and 
to_date(%str(%')&fin_CHAR.%str(%'),'dd/mm/yyyy')
AND EXISTS (SELECT BTC_COD_NRO_SOL_K
            FROM SFADMI_BCO_BTC_SOL
            WHERE BTC_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
            AND BTC_COD_TIP_REG_K = 1
            AND BTC_COD_ETA_K = 102
            AND BTC_COD_EVT_K = 30)
ORDER BY  SOL.SOL_COD_NRO_SOL_K ASC
)A
;QUIT;

proc sql;
create table SB_Stock_Cuenta_Vista as 
select 
a.*,
case when b.RUT_CLIENTE is not null and b.NUMERO_CUENTA_VISTA is not null then 'CAPTA_ONLINE'
when  b.RUT_CLIENTE is  null and b.NUMERO_CUENTA_VISTA is null and a.SUCURSAL_APERTURA=70 then 'PWA'
else 'PRESENCIAL' end as tipo_capta
from SB_Stock_Cuenta_Vista as a
left join CURSE_debito as b
on(a.rut=input(b.rut_cliente,best.)) and (a.cuenta=input(b.NUMERO_CUENTA_VISTA,best.))
;QUIT;

proc sql;
drop table CURSE_debito
;QUIT;

%put--------------------------------------------------------------------------------------------------;
%put [01.3] Ultimo pan vigente del periodo;
%put--------------------------------------------------------------------------------------------------;


proc sql;
create table plasticos_cierre as 
select 
*
from foto_panes_hoy
where input(compress(FECALTA_TR,'-','p'),best.)<=&fin_num.
;QUIT;


proc sql;
create table max_plastico as 
select 
ctto,
max(numplastico) as numplastico
from plasticos_cierre
group by 
ctto
;QUIT;

proc sql;
create table plasticos_cierre2 as 
select 
a.*
from plasticos_cierre as a
inner join max_plastico as b
on(a.ctto=b.ctto) and (a.numplastico=b.numplastico)
;QUIT;


%let path_ora2       = '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=192.168.84.76)(PORT=1521))(CONNECT_DATA=(SERVER=dedicated)(SID=SEGCOM)))'; 
%let user_ora2        = 'PMUNOZC'; 
%let pass_ora2        = 'pmun3012';
 
%let conexion_ora2    = ORACLE PATH=&path_ora2. USER=&user_ora2. PASSWORD=&pass_ora2.; 
%put &conexion_ora2.; 
 

PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER=&user_ora2. PASSWORD=&pass_ora2. path =&path_ora2. );
 
create table mpdt666 as
select 

CODENT1,
CENTALTA1,
CUENTA1,
input(cuenta2,best.) as cv

from connection to ORACLE
(
select * from MPDT666
 
);
disconnect from ORACLE;
QUIT;

proc sql;
create table base_plasticos2 as 
select 
a.*,
b.cv as cuenta_cv 
from plasticos_cierre2 as a
left join mpdt666 as b
on(a.ctto=cats(b.CODENT1,b.CENTALTA1,b.CUENTA1))
;QUIT;

proc sql;
create table cdp as 
select distinct 
CODENT,
CENTALTA,
CUENTA
from foto_panes_hoy 
where 
input(compress(FECALTA_TR,'-','p'),best.)between &ini_num. and &fin_num. 
and (substr(pan,1,6)='525384' and substr(panant,1,6)='639229')
;QUIT;

proc sql;
create table final_plasticos as 
select 
a.CODENT,
a.CENTALTA,
a.CUENTA,
a.pan,
a.cuenta_cv,

case when b.cuenta is not null and substr(a.pan,1,6)='525384' then 'MAESTRO a MCD'
when b.cuenta is null and substr(a.pan,1,6)='525384' then 'MCD'
when b.cuenta is null and substr(a.pan,1,6)='639229' then 'MAESTRO'
else 'MAESTRO' end as tipo_plastico
from base_plasticos2 as a
left join cdp as b
on(a.codent=b.codent) and (a.centalta=b.centalta) and (a.cuenta=b.cuenta)
;QUIT;



proc sql;
create table SB_Stock_Cuenta_Vista as
select 
a.*,
case when b.cuenta_cv is not null then b.tipo_plastico else 
 'MAESTRO' end as tipo_plastico
from SB_Stock_Cuenta_Vista as a 
left join final_plasticos as b
on(a.cuenta=b.cuenta_cv)

;QUIT;

proc sql;
drop table foto_panes_hoy;
drop table plasticos_cierre;
drop table max_plastico;
drop table plasticos_cierre2;
drop table mpdt666;
drop table base_plasticos2;
drop table cdp;
drop table final_plasticos;
;QUIT;

%put--------------------------------------------------------------------------------------------------;
%put [01.2] Marcar nuevos y fugados;
%put--------------------------------------------------------------------------------------------------;

proc sql;
create table work.SB_Stock_Cuenta_Vista as
SELECT 
*,
case when Fecha_Apertura>=&INI_NUM. and Fecha_Apertura<=&FIN_NUM. then 1 else 0 end as SI_Captado_Periodo,
case when Fecha_Cierre>=&INI_NUM. and Fecha_Cierre<=&FIN_NUM. then 1 else 0 end as SI_Fugado_Periodo,
case when Fecha_Apertura<&INI_NUM. and (Fecha_Cierre>=&FIN_NUM. or Fecha_Cierre is null) then 1 else 0 end as SI_Stock_Anterior 
from work.SB_Stock_Cuenta_Vista
;QUIT;

%put--------------------------------------------------------------------------------------------------;
%put [01.3] Pegar Marca de Funcionarios;
%put--------------------------------------------------------------------------------------------------;

proc sql;
create table work.SB_Stock_Cuenta_Vista as
SELECT 
a.*,
case when b.rut is not null then 1 else 0 end as SI_Funcionario
from work.SB_Stock_Cuenta_Vista as a
left join DOTACION as b
on (a.rut=b.rut)
;QUIT;

%put--------------------------------------------------------------------------------------------------;
%put [01.4] Dejar tabla en duro;
%put--------------------------------------------------------------------------------------------------;

proc sql;
create table &LIBREF..SB_Stock_Cuenta_Vista as  /* VALIDADA */
SELECT * 
from work.SB_Stock_Cuenta_Vista 
;quit;

%put==================================================================================================;
%put [02] Base de Saldos de Cuenta Vista diarios;
%put==================================================================================================;


%put--------------------------------------------------------------------------------------------------;
%put [02.1] Sacar Base de saldos diarios;
%put--------------------------------------------------------------------------------------------------;


PROC SQL ;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );
create table SB_Saldos_Cuenta_Vista  as
select 
*
from connection to ORACLE( select 
CAST(SUBSTR(b.cli_identifica,1,length(b.cli_identifica)-1) AS INT)  rut,
cast(TO_CHAR( a.ACP_FECHA,'YYYYMMDD') as INT) as CodFecha,
a.ACP_FECHA, 
a.ACP_NUMCUE, 
sum(a.acp_salefe + a.acp_sal12h + a.acp_sal24h + a.acp_sal48h) as Saldo 
from tcap_acrpas  a
left join ( select 
distinct cli_identifica ,vis_numcue
from tcli_persona 
,tcap_vista 
where cli_codigo=vis_codcli 
and vis_mod=4
and (VIS_PRO=4) 
and vis_tip=1  
AND (vis_status='2' or vis_status='9')) b
on(a.ACP_NUMCUE=b.vis_numcue)
where a.acp_pro = 4 and a.acp_tip = 1 
and a.acp_fecha >=  to_date(%str(%')&ini_char.%str(%'),'dd/mm/yyyy')
and a.acp_fecha <= to_date(%str(%')&fin_char.%str(%'),'dd/mm/yyyy')
group by 
a.ACP_FECHA, 
a.ACP_NUMCUE,
b.cli_identifica
) ;
disconnect from ORACLE;
QUIT;

%put--------------------------------------------------------------------------------------------------;
%put [02.2] Calcular por cuenta: Saldo ultimo dia, Saldo promedio, dias con saldo;
%put--------------------------------------------------------------------------------------------------;

proc sql;
create table work.SB_Saldos_Cuenta_Vista2 as
select 
a.*,
b.Saldo as Ultimo_Saldo 
from (
select 
ACP_NUMCUE as cuenta,
max(rut) as rut,
sum(case when Saldo>1 then 1 else 0 end) as Nro_Dias_Saldo_mayor_1,
sum(case when Saldo>1 then Saldo else 0 end) as SUM_SALDO_FECHA
from work.SB_Saldos_Cuenta_Vista 
group by 
ACP_NUMCUE 
) as a 
left join (
select distinct 
ACP_NUMCUE,
Saldo 
from work.SB_Saldos_Cuenta_Vista 
where CodFecha=(select max(CodFecha) from work.SB_Saldos_Cuenta_Vista)
) as b 
on (a.cuenta=b.ACP_NUMCUE)

;QUIT;

%put--------------------------------------------------------------------------------------------------;
%put [02.3] Marcar Funcionarios;
%put--------------------------------------------------------------------------------------------------;

proc sql;
create table work.SB_Saldos_Cuenta_Vista2 as
SELECT 
a.*,
case when b.rut is not null then 1 else 0 end as SI_Funcionario
from work.SB_Saldos_Cuenta_Vista2 as a
left join DOTACION as b
on (a.rut=b.rut)
;QUIT;

proc sql noprint;
select 
max(day(datepart(ACP_FECHA))) as max_dia
into
:max_dia
from SB_Saldos_Cuenta_Vista
;QUIT;

%let max_dia=&max_dia;

%put--------------------------------------------------------------------------------------------------;
%put [02.4] Dejar tabla en duro;
%put--------------------------------------------------------------------------------------------------;

proc sql; 
create table &LIBREF..SB_Saldos_Cuenta_Vista2 as	/*	VALIDADO	*/
SELECT * 
from work.SB_Saldos_Cuenta_Vista2 
;quit;

%put==================================================================================================;
%put [03] Base de Movimientos de Cuenta Vista;
%put==================================================================================================;

/*Pendiente Categorizar movimientos (por ejempo Movs de DAP)*/

%put--------------------------------------------------------------------------------------------------;
%put [03.1] Extraer Movimientos de debito totales;
%put--------------------------------------------------------------------------------------------------;

PROC SQL  ;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );

create table SB_MOV_CUENTA_VISTA2  as
select 
*,
CASE 
when tmo_tipotra='C' then 
case 
WHEN DESCRIPCION IN ('VALOR EFECTIVO','EN EFECTIVO') AND GLS_TRANSAC ='DEPOSITO' AND  SI_ABR<>1  THEN 'Depósitos en Efectivo' 
WHEN DESCRIPCION IN ('CON DOCUMENTOS') AND GLS_TRANSAC ='DEPOSITO' AND SI_ABR<>1 THEN 'Depósitos con Documento' 
WHEN DESCRIPCION IN ('TRANSFERENCIA DESDE OTROS BANCOS') AND  SI_ABR<>1 THEN 'TEF Recibidas' 
WHEN DESCRIPCION IN ('DESDE OTROS BANCOS') AND  SI_ABR<>1 THEN 'TEF Recibidas' 
WHEN DESCRIPCION IN ('DESDE OTROS BANCOS') AND  SI_ABR=1 THEN 'Abono de Remuneraciones' 
WHEN DESCRIPCION IN ('DESDE OTROS BANCOS') AND  SI_ABR<>1 and DESC_NEGOCIO CONTAINS 'Proveedores' THEN 'TEF Recibidas' 
WHEN DESCRIPCION IN ('POR REGULARIZACION') AND  SI_ABR<>1 THEN 'Otros (pago proveedores)' 
WHEN DESCRIPCION IN ('DESDE LINEA DE CREDITO') AND GLS_TRANSAC ='TRASPASO DE FONDOS' AND  SI_ABR<>1 THEN 'Traspaso desde LCA'
WHEN DESCRIPCION IN ('AVANCE DESDE TARJETA DE CREDITO BANCO RIPLEY') AND  SI_ABR<>1 THEN 'Avance desde Tarjeta Ripley' 
WHEN DESCRIPCION IN ('DEVOLUCION COMISION') AND  SI_ABR<>1 THEN 'DEVOLUCION COMISION' 
WHEN DESCRIPCION IN ('POR TRANSFERENCIA  DE LCA A CTA VISTA') AND  SI_ABR<>1 THEN 'Traspaso desde LCA' 
else 'OTROS ABONOS' 
end else ''
END AS Descripcion_Abono,

CASE 
when tmo_tipotra='D' then 
CASE
WHEN DESCRIPCION IN ('COMPRA NACIONAL') THEN 'Compras Redcompra' 
WHEN DESCRIPCION IN ('COMPRA NACIONAL MCD') THEN 'Compras Redcompra MCD' 
WHEN DESCRIPCION IN ('COMPRA INTERNACIONAL') THEN 'Compras Internacionales' 
WHEN DESCRIPCION IN ('COMPRA INTERNACIONAL MCD') THEN 'Compras Internacionales MCD' 
WHEN DESCRIPCION IN ('CARGO POR PEC') THEN 'PEC' 
WHEN DESCRIPCION IN ('GIRO CAJERO AUTOMATICO') THEN 'Giros ATM' 
when DESCRIPCION IN ('GIRO ATM INTERNACIONAL MCD') then 'Giros internacional MCD'
when DESCRIPCION IN ('GIRO ATM NACIONAL MCD') then 'Giros ATM MCD'
WHEN DESCRIPCION IN ('GIRO POR CAJA') THEN 'Giros Caja' 
WHEN DESCRIPCION IN ('GIRO INTERNACIONAL') THEN 'Giro Internacional' 
WHEN DESCRIPCION IN ('TRANSFERENCIA A OTROS BANCOS') THEN 'TEF emitidas Otros Bancos'
WHEN DESCRIPCION IN ('PAGO TARJETA DE CREDITO') THEN 'Pago de Tarjeta' 
WHEN DESCRIPCION IN ('A CUENTA BANCO RIPLEY','POR TRASPASO A CUENTA')  THEN 'Pago LCA' 
WHEN DESCRIPCION IN ('COSTO DE MANTENCION MENSUAL CUENTA VISTA') then 'Comision planes' 
else 'OTROS CARGOS' 
end else ''
END AS Descripcion_Cargo 

from connection to ORACLE
( select 
CAST(SUBSTR(c2.cli_identifica,1,length(c2.cli_identifica)-1) AS INT)  rut,
SUBSTR(c2.cli_identifica,length(c2.cli_identifica),1)  dv,

cast(TO_CHAR( c1.tmo_fechor,'YYYYMM') as INT) as PERIODO,
cast(TO_CHAR( c1.tmo_fechor,'YYYYMMDD') as INT) as CodFecha,

c1.tmo_numcue as CUENTA, 
c1.tmo_fechcon as FECHACON, 
c1.tmo_fechor as FECHA, 
c1.rub_desc as DESCRIPCION, 
c1.tmo_val as MONTO, 
c1.con_libre as Desc_negocio, 
c1.tmo_codmod, 
c1.tmo_tipotra, 
c1.tmo_rubro, 
c1.tmo_numtra, 
c1.tmo_numcue, 
c1.tmo_codusr, 
c1.tmo_codusr, 
c1.tmo_sec, 
c1.tmo_codtra, 
(
SELECT cod_destra 
FROM tgen_codtrans 
WHERE cod_tra = tmo_codtra AND cod_mod = tmo_codmod 
) as gls_transac,

case 
when c1.tmo_tipotra='D' then 'CARGO' 
when c1.tmo_tipotra='C' then 'ABONO' 
end as Tipo_Movimiento,

case 
when c1.tmo_rubro = 1 and c1.tmo_codtra = 30 and c1.con_libre like 'Depo%' then 1 
else 0 
end as Marca_DAP,

case 
when c1.tmo_tipotra='C' 
and c1.rub_desc='DESDE OTROS BANCOS' 
and ( 
c1.con_libre like '%Remuneraciones%' OR 
c1.con_libre like '%Anticipos%' OR 
c1.con_libre like '%Sueldos%')  then 1 
ELSE 0 
END as SI_ABR ,

CASE 
WHEN  c1.tmo_tipotra='C' and c1.rub_desc='DESDE OTROS BANCOS' 
and ( c1.con_libre like '%Remuneraciones%' OR c1.con_libre like '%Anticipos%' OR c1.con_libre like '%Sueldos%')
AND c1.con_libre like '%BANCO RIPLEY%' THEN 'BANCO RIPLEY' 
WHEN  c1.tmo_tipotra='C' and c1.rub_desc='DESDE OTROS BANCOS' 
and ( c1.con_libre like '%Remuneraciones%' OR c1.con_libre like '%Anticipos%' OR c1.con_libre like '%Sueldos%')
 AND c1.con_libre like '%CAR S.A.%' THEN 'CAR' 
WHEN  c1.tmo_tipotra='C' and c1.rub_desc='DESDE OTROS BANCOS' 
and ( c1.con_libre like '%Remuneraciones%' OR c1.con_libre like '%Anticipos%' OR c1.con_libre like '%Sueldos%')
 AND c1.con_libre like '%RIPLEY STORE%' THEN 'RIPLEY STORE' 
WHEN  c1.tmo_tipotra='C' and c1.rub_desc='DESDE OTROS BANCOS' 
and ( c1.con_libre like '%Remuneraciones%' OR c1.con_libre like '%Anticipos%' OR c1.con_libre like '%Sueldos%')
 AND ( 
c1.con_libre NOT like ('%RIPLEY STORE%') or 
c1.con_libre NOT like ('%CAR S.A.%') or 
c1.con_libre NOT like ('%BANCO RIPLEY%') 
) THEN 'OTROS BANCOS' else ''
END AS Descripcion_ABR,

CASE 
WHEN c1.tmo_tipotra='D' 
and (c1.con_libre like '%Ripley%' OR c1.con_libre like '%RIPLEY%') 
AND  c1.con_libre NOT like '%PAGO%' 
THEN 'COMPRA_RIPLEY' else ''
END AS COMPRA_RIPLEY



 
from(select * from  tcap_tramon /*base de movimientos*/ 
   , TGEN_TRANRUBRO /*base descriptiva (para complementar movimientos)*/ 
   , tcap_concepto /*base descriptiva (para complementar movimientos)*/ 

where rub_mod    = tmo_codmod /*unificacion de base de movs con rubro*/ 
and rub_tra      = tmo_codtra /*unificacion de base de movs con rubro*/ 
and rub_rubro    = tmo_rubro /*unificacion de base de movs con rubro*/ 

and con_modulo(+)  = tmo_codmod /*unificacion de base de movs con con_*/ 
and con_rubro(+)   = tmo_rubro /*unificacion de base de movs con con_*/ 
and con_numtran(+) = tmo_numtra /*unificacion de base de movs con con_*/ 
and con_cuenta (+) = tmo_numcue /*unificacion de base de movs con con_*/ 
and con_codusr(+)  = tmo_codusr /*unificacion de base de movs con con_*/ 
and con_sec(+)     = tmo_sec /*unificacion de base de movs con con_*/ 
and con_transa(+)  = tmo_codtra /*unificacion de base de movs con con_*/ 
/*FILTROS DE MOVIMIENTOS*/ 
and tmo_tipotra in ('D','C') /*D=Cargo, C=Abono*/ 
and tmo_codpro = 4 
and tmo_codtip = 1 
and tmo_modo = 'N' 
and tmo_val > 1 /*solo montos mayores a 1 peso (mov de prueba)*/ 

and tmo_fechcon >= to_date(%str(%')&ini_char.%str(%'),'dd/mm/yyyy')
and tmo_fechcon <= to_date(%str(%')&fin_char.%str(%'),'dd/mm/yyyy')

/*FINAL: QUERY DESDE OPERACIONES*/ 
)  C1  
left join ( 

SELECT distinct cli_identifica ,vis_numcue  
from tcli_persona /*MAESTRA DE CLIENTES BANCO*/ 
,tcap_vista /*SALDOS CUENTAS VISTAS */ 
where cli_codigo=vis_codcli 
and vis_mod=4/*cuenta vista*/ 
and (VIS_PRO=4/*CV*/) 
and vis_tip=1  /*persona no juridica*/ 
AND (vis_status='2' or vis_status='9') /*solo aquellas con estado vigente o cerrado*/ 
)  C2 

on (c1.tmo_numcue=c2.vis_numcue) 

) ;
disconnect from ORACLE;
QUIT;

%put--------------------------------------------------------------------------------------------------;
%put [03.2] Pegar Marca de Funcionario;
%put--------------------------------------------------------------------------------------------------;

proc sql;
create table work.SB_MOV_CUENTA_VISTA2 as
SELECT 
a.*,
case when b.rut is not null then 1 else 0 end as SI_Funcionario
from work.SB_MOV_CUENTA_VISTA2 as a
left join DOTACION as b
on (a.rut=b.rut)
;QUIT;

%put--------------------------------------------------------------------------------------------------;
%put [03.3] Dejar tabla en duro;
%put--------------------------------------------------------------------------------------------------;

proc sql; 
create table &LIBREF..SB_MOV_CUENTA_VISTA2 as	/*	VALIDADO	*/
SELECT * 
from work.SB_MOV_CUENTA_VISTA2 
;quit;

%put==================================================================================================;
%put [04] Base de Suscritos Abono de remuneraciones (desde bases control comercial);
%put==================================================================================================;

%put--------------------------------------------------------------------------------------------------;
%put [04.1] Generar Tabla de Core de Ventas;
%put--------------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE work.CORE_VENTA AS
SELECT distinct 
*,
input(put(t1.fecha,yymmddn8.),best.) as fec_num
FROM result.CAPTA_SALIDA t1
/*inner join GEDCRE_CREDITO.CORE_VENTA t2 on t1.RUT_CLIENTE=t2.RUT_CLIENTE */
where  t1.COD_PROD=4 /*AND t1.PRODUCTO = ('CUENTA VISTA')*/
AND T1.fecha>="&ini"d
AND T1.fecha<="&fin"d
;quit;

%put--------------------------------------------------------------------------------------------------;
%put [04.2] Suscritos en CV segun control de seguimiento;
%put--------------------------------------------------------------------------------------------------;

PROC SQL ;
CONNECT TO ORACLE AS REPORTITF (PATH="REPORITF.WORLD" USER='KMARTINEZ' PASSWORD='kmar2102');
CREATE TABLE SB_SUSCRITOS_CV AS 
SELECT a.NRO_SOLICITUD,
a.PRD_CAC_DET_PRD,
b.RUT_CLIENTE as rut
FROM CONNECTION TO REPORTITF(
select distinct
PS.prd_cod_nro_sol_k  NRO_SOLICITUD,
PS.PRD_CAC_DET_PRD
from SFADMI_BCO_PRD_SOL  ps 
where ps.prd_cod_tip_prd_k like '%04%'
) A
inner join work.CORE_VENTA as b
on (a.NRO_SOLICITUD=b.NRO_SOLICITUD)
;QUIT;

%put--------------------------------------------------------------------------------------------------;
%put [04.3] Pegar Marca de Funcionario;
%put--------------------------------------------------------------------------------------------------;

proc sql;
create table work.SB_SUSCRITOS_CV as
SELECT 
a.*,
case when b.rut is not null then 1 else 0 end as SI_Funcionario
from work.SB_SUSCRITOS_CV as a
left join publicin.dotacion as b
on (a.rut=b.rut)
;QUIT;

%put--------------------------------------------------------------------------------------------------;
%put [04.4] Dejar tabla en duro;
%put--------------------------------------------------------------------------------------------------;

proc sql;
create table &LIBREF..SB_SUSCRITOS_CV as 	/*	VALIDADO	*/
SELECT * 
from work.SB_SUSCRITOS_CV 
;quit;

%put==================================================================================================;
%put [05] Informacion de Captaciones de CtaVta segun control comercial;
%put==================================================================================================;


/*Pendiente identificar*/



%put==================================================================================================;
%put [06] Comenzar a Generar Salidas de cara al panel de cuenta Vista;
%put==================================================================================================;


%put--------------------------------------------------------------------------------------------------;
%put [05.1] Total;
%put--------------------------------------------------------------------------------------------------;


%put='query';

proc sql;
create table work.SB_Salida_Panel_CtaVta as 
select *
from (
/*Bloque1: Stock*/
select 
'001.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'001.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Stock' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'001.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'Stock CV Inicio de Periodo' as Categoria,
sum(SI_Stock_Anterior) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'001.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'Captacion' as Categoria,
sum(SI_Captado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'001.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cierre' as Categoria,
sum(SI_Fugado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'001.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'Stock CV Final de periodo' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'001.06' as Nro_Fila,
'Clientes Totales' as Observacion,
'Tasa de cierre' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

/*Bloque2: Informacion de uso CV*/
select 
'002.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'002.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Informacion de uso CV' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'002.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de Cuentas con Movimientos cargos o abonos' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Depósitos en Efectivo',
'Depósitos con Documento',
'TEF Recibidas',
'Abono de Remuneraciones',
'Otros (pago proveedores)',
'Traspaso desde LCA',
'Avance desde Tarjeta Ripley',
'OTROS ABONOS'
)
or
Descripcion_Cargo in (
'Comision planes',
'Compras Internacionales',
'Compras Internacionales MCD',
'Compras Redcompra',
'Compras Redcompra MCD',
'Giro Internacional',
'Giros ATM',
'Giros Caja',
'PEC',
'Pago LCA',
'Pago de Tarjeta',
'TEF emitidas Otros Bancos',
'Giros internacional MCD',
'Giros ATM MCD',
'OTROS CARGOS'
))

outer union corr

select 
'002.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de Cuentas con Cargos' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Comision planes',
'Compras Internacionales',
'Compras Redcompra',
'Compras Internacionales MCD',
'Compras Redcompra MCD',
'Giro Internacional',
'Giros ATM',
'Giros Caja',
'PEC',
'Pago LCA',
'Pago de Tarjeta',
'TEF emitidas Otros Bancos',
'Giros internacional MCD',
'Giros ATM MCD',
'OTROS CARGOS'
))

outer union corr

select 
'002.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con compras' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Internacionales',
'Compras Redcompra',
'Compras Internacionales MCD',
'Compras Redcompra MCD'
))

outer union corr

select 
'002.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con Giros' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Giro Internacional',
'Giros ATM',
'Giros Caja',
'Giros internacional MCD',
'Giros ATM MCD'
))

outer union corr

select 
'002.06' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con TEF' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'002.07' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con Pago' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Pago de Tarjeta',
'Pago LCA'
))

outer union corr

select 
'002.08' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con uso Internacional' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Giro Internacional',
'Giros internacional MCD'
))

outer union corr

select 
'002.09' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Cuentas con  Abonos' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Abono de Remuneraciones',
'Avance desde Tarjeta Ripley',
'Depósitos con Documento',
'Depósitos en Efectivo',
'OTROS ABONOS',
'Otros (pago proveedores)',
'TEF Recibidas',
'Traspaso desde LCA'
))

outer union corr

select 
'002.10' as Nro_Fila,
'Clientes Totales' as Observacion,
'Depósitos en Efectivo' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Depósitos en Efectivo'))

outer union corr

select 
'002.11' as Nro_Fila,
'Clientes Totales' as Observacion,
'Depósitos con Documento' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Depósitos con Documento'))

outer union corr

select 
'002.12' as Nro_Fila,
'Clientes Totales' as Observacion,
'TEF Recibidas' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'TEF Recibidas'))

outer union corr

select 
'002.13' as Nro_Fila,
'Clientes Totales' as Observacion,
'Abono de Remuneraciones' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Abono de Remuneraciones'))

outer union corr

select 
'002.14' as Nro_Fila,
'Clientes Totales' as Observacion,
'Otros (pago proveedores)' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Otros (pago proveedores)'))

outer union corr

select 
'002.15' as Nro_Fila,
'Clientes Totales' as Observacion,
'Traspaso desde LCA' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Traspaso desde LCA'))

outer union corr

select 
'002.16' as Nro_Fila,
'Clientes Totales' as Observacion,
'Avance desde Tarjeta Ripley' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Avance desde Tarjeta Ripley')) 

outer union corr

select 
'002.17' as Nro_Fila,
'Clientes Totales' as Observacion,
'OTROS ABONOS' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'OTROS ABONOS'))

outer union corr

/*Bloque3: Informacion de uso CV %*/
select 
'003.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'003.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Informacion de uso CV %' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'003.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'% de Cuentas con movimiento o abonos' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'003.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'% de Cuentas con Cargos' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'003.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con compras' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'003.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con Giros' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'003.06' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con TEF' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'003.07' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con uso Internacional' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'003.08' as Nro_Fila,
'Clientes Totales' as Observacion,
'% Cuentas con Abonos' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'003.09' as Nro_Fila,
'Clientes Totales' as Observacion,
'Depósitos en Efectivo' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'003.10' as Nro_Fila,
'Clientes Totales' as Observacion,
'Depósitos con Documento' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'003.11' as Nro_Fila,
'Clientes Totales' as Observacion,
'TEF Recibidas' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'003.12' as Nro_Fila,
'Clientes Totales' as Observacion,
'Abono de Remuneraciones' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'003.13' as Nro_Fila,
'Clientes Totales' as Observacion,
'Otros (pago proveedores)' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'003.14' as Nro_Fila,
'Clientes Totales' as Observacion,
'Traspaso desde LCA' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'003.15' as Nro_Fila,
'Clientes Totales' as Observacion,
'Avance desde Tarjeta Ripley' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 

outer union corr

select 
'003.16' as Nro_Fila,
'Clientes Totales' as Observacion,
'OTROS ABONOS' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

/*Bloque4: Informacion de ABR*/
select 
'004.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'004.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Informacion de ABR' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'004.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de Cuentas Distintas Total Abonos >= $270.000' as Categoria,
count(distinct cuenta) as Valor
from (
select cuenta,sum(Monto) as SUM_Monto
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and GLS_TRANSAC='ABONO'
and Descripcion_Abono NOT IN ('Traspaso desde LCA','Abono de Remuneraciones','Avance desde Tarjeta Ripley')
and SI_ABR=0
group by cuenta
) as X
where SUM_Monto>=270000

outer union corr

select 
'004.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de Cuentas Distintas con ABR' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and SI_ABR=1

outer union corr

select 
'004.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'% de ABR vigentes' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'004.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de ABR suscritos de los Captados' as Categoria,
count(*) as Valor
from work.SB_SUSCRITOS_CV
where SI_Funcionario>=0 

outer union corr

select 
'004.06' as Nro_Fila,
'Clientes Totales' as Observacion,
'Tasa de cruce de ABR en Captacion' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'004.07' as Nro_Fila,
'Clientes Totales' as Observacion,
'% de ABR con Cargo' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

/*Bloque5: Informacion de uso CV/por cuenta*/
select 
'005.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>=0

outer union corr

select 
'005.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Informacion de uso CV/por cuenta' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'005.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de movimiento por cuenta cargo y abono' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'005.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de cargos por cuenta' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'005.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de compras por cuenta' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'005.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de Giros por cuenta' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'005.06' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de TEF por cuenta' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'005.07' as Nro_Fila,
'Clientes Totales' as Observacion,
'# uso internacional por cuenta' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'005.08' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Abonos por cuenta' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'005.09' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Depósitos en Efectivo' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'005.10' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Depósitos con Documento' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'005.11' as Nro_Fila,
'Clientes Totales' as Observacion,
'# TEF Recibidas' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'005.12' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Abono de Remuneraciones' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'005.13' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Otros (pago proveedores)' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'005.14' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Traspaso desde LCA' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'005.15' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Avance desde Tarjeta Ripley' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

/*Bloque6: Informacion de Saldo*/
select 
'006.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>=0

outer union corr

select 
'006.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Informacion de Saldo' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>=0

outer union corr

select 
'006.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con Saldo >$1' as Categoria,
count(*) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>=0
and Nro_Dias_Saldo_mayor_1>0

outer union corr

select 
'006.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con Saldo >$1 EOP' as Categoria,
count(*) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>=0
and Ultimo_Saldo>1

outer union corr

select 
'006.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'Saldo Total Promedio Mes (MM$)' as Categoria,
sum(SUM_SALDO_FECHA/&max_dia.)/1000000 as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>=0
and Nro_Dias_Saldo_mayor_1>0

outer union corr

select 
'006.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'Saldo Total EOP (MM$)' as Categoria,
sum(Ultimo_Saldo)/1000000 as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>=0

outer union corr

select 
'006.06' as Nro_Fila,
'Clientes Totales' as Observacion,
'Saldo Promedio por cuenta Activa ($)' as Categoria,
max(0) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>=0

outer union corr

/*Bloque7: Informacion de Saldo %*/
select 
'007.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'007.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Informacion de Saldo %' as Categoria,
max(floor(&ini_num)) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'007.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'% de Cuentas con Saldo' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

/*Bloque8: Movimientos ($)*/
select 
'008.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'008.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Movimientos ($)' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0

outer union corr

select 
'008.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cargos' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Comision planes',
'Compras Internacionales',
'Compras Redcompra',
'Compras Internacionales MCD',
'Compras Redcompra MCD',
'Giro Internacional',
'Giros ATM',
'Giros Caja',
'OTROS CARGOS',
'PEC',
'Pago LCA',
'Pago de Tarjeta',
'TEF emitidas Otros Bancos',
'Giros internacional MCD',
'Giros ATM MCD'
))

outer union corr

select 
'008.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Redcompra',
'Compras Internacionales',
'Compras Internacionales MCD',
'Compras Redcompra MCD',
'PEC'
))

outer union corr

select 
'008.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras Redcompra' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Redcompra'
))

outer union corr

select 
'008.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras  Redcompra Tienda' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Redcompra'
)) and COMPRA_RIPLEY='COMPRA_RIPLEY'

outer union corr

select 
'008.06' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras Redcompra no Tienda' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Redcompra'
)) and COMPRA_RIPLEY<>'COMPRA_RIPLEY'

outer union corr

select 
'008.07' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras Internacionales' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Internacionales'
))

outer union corr

select 
'008.08' as Nro_Fila,
'Clientes Totales' as Observacion,
'PEC' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'PEC'
))

outer union corr

select 
'008.09' as Nro_Fila,
'Clientes Totales' as Observacion,
'Giros' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Giros ATM',
'Giros Caja',
'Giro Internacional',
'Giros internacional MCD',
'Giros ATM MCD'
))

outer union corr

select 
'008.10' as Nro_Fila,
'Clientes Totales' as Observacion,
'ATM' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Giros ATM'
))

outer union corr

select 
'008.11' as Nro_Fila,
'Clientes Totales' as Observacion,
'Caja' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Giros Caja'
))

outer union corr

select 
'008.12' as Nro_Fila,
'Clientes Totales' as Observacion,
'Internacional' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Giro Internacional'
))

outer union corr

select 
'008.13' as Nro_Fila,
'Clientes Totales' as Observacion,
'TEF emitidas' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'008.14' as Nro_Fila,
'Clientes Totales' as Observacion,
'Otros Bancos' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'008.15' as Nro_Fila,
'Clientes Totales' as Observacion,
'Pagos' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Pago de Tarjeta',
'Pago LCA'
))

outer union corr

select 
'008.16' as Nro_Fila,
'Clientes Totales' as Observacion,
'Pago de Tarjeta' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Pago de Tarjeta'
))

outer union corr

select 
'008.17' as Nro_Fila,
'Clientes Totales' as Observacion,
'Pago LCA' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Pago LCA'
))

outer union corr

select 
'008.18' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cobro Mantención Cuenta Vista' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Comision planes'
))
 
outer union corr
 
select 
'008.19' as Nro_Fila,
'Clientes Totales' as Observacion,
'OTROS CARGOS' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'OTROS CARGOS'
))

outer union corr
 
select 
'008.20' as Nro_Fila,
'Clientes Totales' as Observacion,
'Abonos' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Abono de Remuneraciones',
'Avance desde Tarjeta Ripley',
'Depósitos con Documento',
'Depósitos en Efectivo',
'OTROS ABONOS',
'Otros (pago proveedores)',
'TEF Recibidas',
'Traspaso desde LCA'
))
 
outer union corr
 
select 
'008.21' as Nro_Fila,
'Clientes Totales' as Observacion,
'Depósitos en Efectivo' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Depósitos en Efectivo'))
 
outer union corr
 
select 
'008.22' as Nro_Fila,
'Clientes Totales' as Observacion,
'Depósitos con Documento' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Depósitos con Documento'))
 
outer union corr
 
select 
'008.23' as Nro_Fila,
'Clientes Totales' as Observacion,
'TEF Recibidas' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'TEF Recibidas'))
 
outer union corr
 
select 
'008.24' as Nro_Fila,
'Clientes Totales' as Observacion,
'Abono de Remuneraciones' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where (Descripcion_Abono in (
'Abono de Remuneraciones'))

outer union corr
 
select 
'008.25' as Nro_Fila,
'Clientes Totales' as Observacion,
'Otros (pago proveedores)' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Otros (pago proveedores)'))
 
outer union corr
 
select 
'008.26' as Nro_Fila,
'Clientes Totales' as Observacion,
'Traspaso desde LCA' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Traspaso desde LCA'))
 
outer union corr
 
select 
'008.27' as Nro_Fila,
'Clientes Totales' as Observacion,
'Avance desde Tarjeta Ripley' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Avance desde Tarjeta Ripley'))
 
outer union corr
 
select 
'008.28' as Nro_Fila,
'Clientes Totales' as Observacion,
'OTROS ABONOS' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'OTROS ABONOS'))

outer union corr
 
/*Bloque9: Movimientos (Tx)*/
select 
'009.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'009.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Movimientos (#)' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 

outer union corr

select 
'009.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'Movimientos (#) (Cargos y Abonos)' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Comision planes',
'Compras Internacionales',
'Compras Redcompra',
'Compras Internacionales MCD',
'Compras Redcompra MCD',
'Giro Internacional',
'Giros ATM',
'Giros Caja',
'OTROS CARGOS',
'PEC',
'Pago LCA',
'Pago de Tarjeta',
'Giros internacional MCD',
'Giros ATM MCD',
'TEF emitidas Otros Bancos'
) or Descripcion_Abono in (
'Abono de Remuneraciones',
'Avance desde Tarjeta Ripley',
'Depósitos con Documento',
'Depósitos en Efectivo',
'OTROS ABONOS',
'Otros (pago proveedores)',
'TEF Recibidas',
'Traspaso desde LCA'
))

outer union corr

select 
'009.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cargos' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Comision planes',
'Compras Internacionales',
'Compras Redcompra',
'Compras Internacionales MCD',
'Compras Redcompra MCD',
'Giro Internacional',
'Giros ATM',
'Giros Caja',
'OTROS CARGOS',
'PEC',
'Pago LCA',
'Pago de Tarjeta',
'Giros internacional MCD',
'Giros ATM MCD',
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'009.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Redcompra',
'Compras Internacionales',
'Compras Redcompra MCD',
'Compras Internacionales MCD',
'PEC'
))

outer union corr

select 
'009.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras Redcompra' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Redcompra'
))

outer union corr

select 
'009.06' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras  Redcompra Tienda' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Redcompra'
)) and COMPRA_RIPLEY='COMPRA_RIPLEY'

outer union corr

select 
'009.07' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras Redcompra no Tienda' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Redcompra'
)) and COMPRA_RIPLEY<>'COMPRA_RIPLEY'

outer union corr

select 
'009.08' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras Internacionales' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Internacionales'
))

outer union corr

select 
'009.09' as Nro_Fila,
'Clientes Totales' as Observacion,
'PEC' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'PEC'
))

outer union corr

select 
'009.10' as Nro_Fila,
'Clientes Totales' as Observacion,
'Giros' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Giros ATM',
'Giros Caja',
'Giros internacional MCD',
'Giros ATM MCD',
'Giro Internacional'
))

outer union corr

select 
'009.11' as Nro_Fila,
'Clientes Totales' as Observacion,
'ATM' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Giros ATM'
))

outer union corr

select 
'009.12' as Nro_Fila,
'Clientes Totales' as Observacion,
'Caja' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Giros Caja'
))

outer union corr

select 
'009.13' as Nro_Fila,
'Clientes Totales' as Observacion,
'Internacional' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Giro Internacional'
))

outer union corr

select 
'009.14' as Nro_Fila,
'Clientes Totales' as Observacion,
'TEF emitidas' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'009.15' as Nro_Fila,
'Clientes Totales' as Observacion,
'Otros Bancos' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'009.16' as Nro_Fila,
'Clientes Totales' as Observacion,
'Pagos' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Pago de Tarjeta',
'Pago LCA'
))

outer union corr

select 
'009.17' as Nro_Fila,
'Clientes Totales' as Observacion,
'Pago de Tarjeta' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Pago de Tarjeta'
))

outer union corr

select 
'009.18' as Nro_Fila,
'Clientes Totales' as Observacion,
'Pago LCA' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Pago LCA'
))

outer union corr

select 
'009.19' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cobro Mantención Cuenta Vista' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Comision planes'
))
 
outer union corr
 
select 
'009.20' as Nro_Fila,
'Clientes Totales' as Observacion,
'OTROS CARGOS' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'OTROS CARGOS'
))

outer union corr
 
select 
'009.21' as Nro_Fila,
'Clientes Totales' as Observacion,
'Abonos' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Abono de Remuneraciones',
'Avance desde Tarjeta Ripley',
'Depósitos con Documento',
'Depósitos en Efectivo',
'OTROS ABONOS',
'Otros (pago proveedores)',
'TEF Recibidas',
'Traspaso desde LCA'
))
 
outer union corr
 
select 
'009.22' as Nro_Fila,
'Clientes Totales' as Observacion,
'Depósitos en Efectivo' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Depósitos en Efectivo'))
 
outer union corr
 
select 
'009.23' as Nro_Fila,
'Clientes Totales' as Observacion,
'Depósitos con Documento' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Depósitos con Documento'))
 
outer union corr
 
select 
'009.24' as Nro_Fila,
'Clientes Totales' as Observacion,
'TEF Recibidas' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'TEF Recibidas'))
 
outer union corr
 
select 
'009.25' as Nro_Fila,
'Clientes Totales' as Observacion,
'Abono de Remuneraciones' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Abono de Remuneraciones'))
 
outer union corr
 
select 
'009.26' as Nro_Fila,
'Clientes Totales' as Observacion,
'Otros (pago proveedores)' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Otros (pago proveedores)'))
 
outer union corr
 
select 
'009.27' as Nro_Fila,
'Clientes Totales' as Observacion,
'Traspaso desde LCA' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Traspaso desde LCA'))
 
outer union corr
 
select 
'009.28' as Nro_Fila,
'Clientes Totales' as Observacion,
'Avance desde Tarjeta Ripley' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'Avance desde Tarjeta Ripley'))
 
outer union corr
 
select 
'009.29' as Nro_Fila,
'Clientes Totales' as Observacion,
'OTROS ABONOS' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Abono in (
'OTROS ABONOS'))

outer union corr 

select 
'010.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'010.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'$ Compras Redcompra MCD' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Redcompra MCD'
))

outer union corr

select 
'010.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'$ Compras  Redcompra MCD Tienda' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Redcompra MCD'
)) and COMPRA_RIPLEY='COMPRA_RIPLEY'

outer union corr

select 
'010.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'$ Compras Redcompra MCD no Tienda' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Redcompra MCD'
)) and COMPRA_RIPLEY<>'COMPRA_RIPLEY'

outer union corr

select 
'010.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'$ Compras Internacionales MCD' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Internacionales MCD'
))

outer union corr

select 
'011.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'011.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Compras Redcompra MCD' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Redcompra MCD'
))

outer union corr

select 
'011.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Compras  Redcompra MCD Tienda' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Redcompra MCD'
)) and COMPRA_RIPLEY='COMPRA_RIPLEY'


outer union corr

select 
'011.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Compras Redcompra MCD no Tienda' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Redcompra MCD'
)) and COMPRA_RIPLEY<>'COMPRA_RIPLEY'


outer union corr

select 
'011.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Compras Internacionales MCD' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Compras Internacionales MCD'
))

outer union corr

select 
'012.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'012.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Captacion PWA' as Categoria,
sum(case when tipo_capta='PWA' then SI_Captado_Periodo end) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'012.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'Captacion Online' as Categoria,
sum(case when tipo_capta='CAPTA_ONLINE' then SI_Captado_Periodo end) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'012.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'Captacion Presencial' as Categoria,
sum(case when tipo_capta='PRESENCIAL' then SI_Captado_Periodo end) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'013.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>=0

outer union corr

select 
'013.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Cuentas con Saldo >$1' as Categoria,
count(case when ultimo_saldo>1 then cuenta end) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>=0

outer union corr

select 
'013.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Cuentas con Saldo >$1.000' as Categoria,
count(case when ultimo_saldo>1000 then cuenta end) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>=0

outer union corr

select 
'013.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Cuentas con Saldo >$100.000' as Categoria,
count(case when ultimo_saldo>100000 then cuenta end) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>=0

outer union corr 

select 
'014.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'014.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Stock MAESTRO' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0
and tipo_plastico='MAESTRO'

outer union corr

select 
'014.02' as Nro_Fila,
'Clientes Totales ' as Observacion,
'Stock CV Inicio de Periodo MAESTRO' as Categoria,
sum(SI_Stock_Anterior) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0 and tipo_plastico='MAESTRO'

outer union corr

select 
'014.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'Captacion MAESTRO' as Categoria,
sum(SI_Captado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0 and tipo_plastico='MAESTRO'

outer union corr

select 
'014.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cierre MAESTRO' as Categoria,
sum(SI_Fugado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0 and tipo_plastico='MAESTRO'

outer union corr

select 
'014.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'Stock CV Final de periodo MAESTRO' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0 and tipo_plastico='MAESTRO'

outer union corr

select 
'015.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'015.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Stock MCD' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0
and tipo_plastico='MCD'

outer union corr

select 
'015.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'Stock CV Inicio de Periodo MCD' as Categoria,
sum(SI_Stock_Anterior) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0 and tipo_plastico='MCD'

outer union corr

select 
'015.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'Captacion MCD' as Categoria,
sum(SI_Captado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0 and tipo_plastico='MCD'

outer union corr

select 
'015.04' as Nro_Fila,
'Clientes Totales ' as Observacion,
'Cierre MCD' as Categoria,
sum(SI_Fugado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0 and tipo_plastico='MCD'

outer union corr

select 
'015.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'Stock CV Final de periodo MCD' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0 and tipo_plastico='MCD'

outer union corr

select 
'016.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0

outer union corr

select 
'016.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Stock MAESTRO a MCD' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0
and tipo_plastico='MAESTRO a MCD'

outer union corr

select 
'016.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'Stock CV Inicio de Periodo MAESTRO a MCD' as Categoria,
sum(SI_Stock_Anterior) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0 and tipo_plastico='MAESTRO a MCD'

outer union corr

select 
'016.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'Captacion MAESTRO a MCD' as Categoria,
sum(SI_Captado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0 and tipo_plastico='MAESTRO a MCD'

outer union corr

select 
'016.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cierre MAESTRO a MCD' as Categoria,
sum(SI_Fugado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0 and tipo_plastico='MAESTRO a MCD'

outer union corr

select 
'016.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'Stock CV Final de periodo MAESTRO a MCD' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>=0 and tipo_plastico='MAESTRO a MCD'



outer union corr

select 
'017.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'---------------------' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2


outer union corr

select 
'017.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'Monto Giros ATM MCD' as Categoria,
sum(monto) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Giros ATM MCD'
))

outer union corr

select 
'017.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'Monto Giros internacional MCD' as Categoria,
sum(monto) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Giros internacional MCD'
))

outer union corr

select 
'017.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'TRX Giros ATM MCD' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Giros ATM MCD'
))

outer union corr

select 
'017.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'TRX Giros internacional MCD' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>=0 
and (Descripcion_Cargo in (
'Giros internacional MCD'
))

) as X

;quit;



%put--------------------------------------------------------------------------------------------------;
%put [05.2] NO Funcionario;
%put--------------------------------------------------------------------------------------------------;

proc sql;
insert into work.SB_Salida_Panel_CtaVta
select *
from (
/*Bloque1: Stock*/
select 
'001.00' as Nro_Fila,
'Clientes NF' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'001.01' as Nro_Fila,
'Clientes NF' as Observacion,
'Stock' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'001.02' as Nro_Fila,
'Clientes NF' as Observacion,
'Stock CV Inicio de Periodo' as Categoria,
sum(SI_Stock_Anterior) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'001.03' as Nro_Fila,
'Clientes NF' as Observacion,
'Captacion' as Categoria,
sum(SI_Captado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'001.04' as Nro_Fila,
'Clientes NF' as Observacion,
'Cierre' as Categoria,
sum(SI_Fugado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'001.05' as Nro_Fila,
'Clientes NF' as Observacion,
'Stock CV Final de periodo' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'001.06' as Nro_Fila,
'Clientes NF' as Observacion,
'Tasa de cierre' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

/*Bloque2: Informacion de uso CV*/
select 
'002.00' as Nro_Fila,
'Clientes NF' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'002.01' as Nro_Fila,
'Clientes NF' as Observacion,
'Informacion de uso CV' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'002.02' as Nro_Fila,
'Clientes NF' as Observacion,
'# de Cuentas con Movimientos cargos o abonos' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Depósitos en Efectivo',
'Depósitos con Documento',
'TEF Recibidas',
'Abono de Remuneraciones',
'Otros (pago proveedores)',
'Traspaso desde LCA',
'Avance desde Tarjeta Ripley',

'OTROS ABONOS'
)
or
Descripcion_Cargo in (
'Comision planes',
'Compras Internacionales',
'Compras Internacionales MCD',
'Compras Redcompra',
'Compras Redcompra MCD',
'Giro Internacional',
'Giros ATM',
'Giros Caja',
'PEC',
'Pago LCA',
'Pago de Tarjeta',
'TEF emitidas Otros Bancos',
'Giros internacional MCD',
'Giros ATM MCD',
'OTROS CARGOS'
))

outer union corr

select 
'002.03' as Nro_Fila,
'Clientes NF' as Observacion,
'# de Cuentas con Cargos' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Comision planes',
'Compras Internacionales',
'Compras Redcompra',
'Compras Internacionales MCD',
'Compras Redcompra MCD',
'Giro Internacional',
'Giros ATM',
'Giros Caja',
'PEC',
'Pago LCA',
'Pago de Tarjeta',
'TEF emitidas Otros Bancos',
'Giros internacional MCD',
'Giros ATM MCD',
'OTROS CARGOS'
))

outer union corr

select 
'002.04' as Nro_Fila,
'Clientes NF' as Observacion,
'Cuentas con compras' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Internacionales',
'Compras Redcompra',
'Compras Internacionales MCD',
'Compras Redcompra MCD'
))

outer union corr

select 
'002.05' as Nro_Fila,
'Clientes NF' as Observacion,
'Cuentas con Giros' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Giro Internacional',
'Giros ATM',
'Giros internacional MCD',
'Giros ATM MCD',
'Giros Caja'
))

outer union corr

select 
'002.06' as Nro_Fila,
'Clientes NF' as Observacion,
'Cuentas con TEF' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'002.07' as Nro_Fila,
'Clientes NF' as Observacion,
'Cuentas con Pago' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Pago de Tarjeta',
'Pago LCA'
))

outer union corr

select 
'002.08' as Nro_Fila,
'Clientes NF' as Observacion,
'Cuentas con uso Internacional' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Giro Internacional'
'Giros internacional MCD'
))

outer union corr

select 
'002.09' as Nro_Fila,
'Clientes NF' as Observacion,
'# Cuentas con  Abonos' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Abono de Remuneraciones',
'Avance desde Tarjeta Ripley',
'Depósitos con Documento',
'Depósitos en Efectivo',
'OTROS ABONOS',
'Otros (pago proveedores)',
'TEF Recibidas',
'Traspaso desde LCA'
))

outer union corr

select 
'002.10' as Nro_Fila,
'Clientes NF' as Observacion,
'Depósitos en Efectivo' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Depósitos en Efectivo'))

outer union corr

select 
'002.11' as Nro_Fila,
'Clientes NF' as Observacion,
'Depósitos con Documento' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Depósitos con Documento'))

outer union corr

select 
'002.12' as Nro_Fila,
'Clientes NF' as Observacion,
'TEF Recibidas' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'TEF Recibidas'))

outer union corr

select 
'002.13' as Nro_Fila,
'Clientes NF' as Observacion,
'Abono de Remuneraciones' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Abono de Remuneraciones'))

outer union corr

select 
'002.14' as Nro_Fila,
'Clientes NF' as Observacion,
'Otros (pago proveedores)' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Otros (pago proveedores)'))

outer union corr

select 
'002.15' as Nro_Fila,
'Clientes NF' as Observacion,
'Traspaso desde LCA' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Traspaso desde LCA'))

outer union corr

select 
'002.16' as Nro_Fila,
'Clientes NF' as Observacion,
'Avance desde Tarjeta Ripley' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Avance desde Tarjeta Ripley')) 

outer union corr

select 
'002.17' as Nro_Fila,
'Clientes NF' as Observacion,
'OTROS ABONOS' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'OTROS ABONOS'))

outer union corr

/*Bloque3: Informacion de uso CV %*/
select 
'003.00' as Nro_Fila,
'Clientes NF' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'003.01' as Nro_Fila,
'Clientes NF' as Observacion,
'Informacion de uso CV %' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'003.02' as Nro_Fila,
'Clientes NF' as Observacion,
'% de Cuentas con movimiento o abonos' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'003.03' as Nro_Fila,
'Clientes NF' as Observacion,
'% de Cuentas con Cargos' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'003.04' as Nro_Fila,
'Clientes NF' as Observacion,
'Cuentas con compras' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'003.05' as Nro_Fila,
'Clientes NF' as Observacion,
'Cuentas con Giros' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'003.06' as Nro_Fila,
'Clientes NF' as Observacion,
'Cuentas con TEF' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'003.07' as Nro_Fila,
'Clientes NF' as Observacion,
'Cuentas con uso Internacional' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'003.08' as Nro_Fila,
'Clientes NF' as Observacion,
'% Cuentas con Abonos' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'003.09' as Nro_Fila,
'Clientes NF' as Observacion,
'Depósitos en Efectivo' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'003.10' as Nro_Fila,
'Clientes NF' as Observacion,
'Depósitos con Documento' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'003.11' as Nro_Fila,
'Clientes NF' as Observacion,
'TEF Recibidas' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'003.12' as Nro_Fila,
'Clientes NF' as Observacion,
'Abono de Remuneraciones' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'003.13' as Nro_Fila,
'Clientes NF' as Observacion,
'Otros (pago proveedores)' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'003.14' as Nro_Fila,
'Clientes NF' as Observacion,
'Traspaso desde LCA' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'003.15' as Nro_Fila,
'Clientes NF' as Observacion,
'Avance desde Tarjeta Ripley' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 

outer union corr

select 
'003.16' as Nro_Fila,
'Clientes NF' as Observacion,
'OTROS ABONOS' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

/*Bloque4: Informacion de ABR*/
select 
'004.00' as Nro_Fila,
'Clientes NF' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'004.01' as Nro_Fila,
'Clientes NF' as Observacion,
'Informacion de ABR' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'004.02' as Nro_Fila,
'Clientes NF' as Observacion,
'# de Cuentas Distintas Total Abonos >= $270.000' as Categoria,
count(distinct cuenta) as Valor
from (
select cuenta,sum(Monto) as SUM_Monto
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and GLS_TRANSAC='ABONO'
and Descripcion_Abono NOT IN ('Traspaso desde LCA','Abono de Remuneraciones','Avance desde Tarjeta Ripley')
and SI_ABR=0
group by cuenta
) as X
where SUM_Monto>=270000

outer union corr

select 
'004.03' as Nro_Fila,
'Clientes NF' as Observacion,
'# de Cuentas Distintas con ABR' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and SI_ABR=1

outer union corr

select 
'004.04' as Nro_Fila,
'Clientes NF' as Observacion,
'% de ABR vigentes' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'004.05' as Nro_Fila,
'Clientes NF' as Observacion,
'# de ABR suscritos de los Captados' as Categoria,
count(*) as Valor
from work.SB_SUSCRITOS_CV
where SI_Funcionario=0 

outer union corr

select 
'004.06' as Nro_Fila,
'Clientes NF' as Observacion,
'Tasa de cruce de ABR en Captacion' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'004.07' as Nro_Fila,
'Clientes NF' as Observacion,
'% de ABR con Cargo' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

/*Bloque5: Informacion de uso CV/por cuenta*/
select 
'005.00' as Nro_Fila,
'Clientes NF' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario=0

outer union corr

select 
'005.01' as Nro_Fila,
'Clientes NF' as Observacion,
'Informacion de uso CV/por cuenta' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'005.02' as Nro_Fila,
'Clientes NF' as Observacion,
'# de movimiento por cuenta cargo y abono' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'005.03' as Nro_Fila,
'Clientes NF' as Observacion,
'# de cargos por cuenta' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'005.04' as Nro_Fila,
'Clientes NF' as Observacion,
'# de compras por cuenta' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'005.05' as Nro_Fila,
'Clientes NF' as Observacion,
'# de Giros por cuenta' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'005.06' as Nro_Fila,
'Clientes NF' as Observacion,
'# de TEF por cuenta' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'005.07' as Nro_Fila,
'Clientes NF' as Observacion,
'# uso internacional por cuenta' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'005.08' as Nro_Fila,
'Clientes NF' as Observacion,
'# Abonos por cuenta' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'005.09' as Nro_Fila,
'Clientes NF' as Observacion,
'# Depósitos en Efectivo' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'005.10' as Nro_Fila,
'Clientes NF' as Observacion,
'# Depósitos con Documento' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'005.11' as Nro_Fila,
'Clientes NF' as Observacion,
'# TEF Recibidas' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'005.12' as Nro_Fila,
'Clientes NF' as Observacion,
'# Abono de Remuneraciones' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'005.13' as Nro_Fila,
'Clientes NF' as Observacion,
'# Otros (pago proveedores)' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'005.14' as Nro_Fila,
'Clientes NF' as Observacion,
'# Traspaso desde LCA' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'005.15' as Nro_Fila,
'Clientes NF' as Observacion,
'# Avance desde Tarjeta Ripley' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

/*Bloque6: Informacion de Saldo*/
select 
'006.00' as Nro_Fila,
'Clientes NF' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario=0

outer union corr

select 
'006.01' as Nro_Fila,
'Clientes NF' as Observacion,
'Informacion de Saldo' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario=0

outer union corr

select 
'006.02' as Nro_Fila,
'Clientes NF' as Observacion,
'Cuentas con Saldo >$1' as Categoria,
count(*) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario=0
and Nro_Dias_Saldo_mayor_1>0

outer union corr

select 
'006.03' as Nro_Fila,
'Clientes NF' as Observacion,
'Cuentas con Saldo >$1 EOP' as Categoria,
count(*) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario=0
and Ultimo_Saldo>1

outer union corr

select 
'006.04' as Nro_Fila,
'Clientes NF' as Observacion,
'Saldo Total Promedio Mes (MM$)' as Categoria,
sum(SUM_SALDO_FECHA/&max_dia.)/1000000 as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario=0
and Nro_Dias_Saldo_mayor_1>0

outer union corr

select 
'006.05' as Nro_Fila,
'Clientes NF' as Observacion,
'Saldo Total EOP (MM$)' as Categoria,
sum(Ultimo_Saldo)/1000000 as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario=0

outer union corr

select 
'006.06' as Nro_Fila,
'Clientes NF' as Observacion,
'Saldo Promedio por cuenta Activa ($)' as Categoria,
max(0) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario=0

outer union corr

/*Bloque7: Informacion de Saldo %*/
select 
'007.00' as Nro_Fila,
'Clientes NF' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'007.01' as Nro_Fila,
'Clientes NF' as Observacion,
'Informacion de Saldo %' as Categoria,
max(floor(&ini_num)) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'007.02' as Nro_Fila,
'Clientes NF' as Observacion,
'% de Cuentas con Saldo' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

/*Bloque8: Movimientos ($)*/
select 
'008.00' as Nro_Fila,
'Clientes NF' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'008.01' as Nro_Fila,
'Clientes NF' as Observacion,
'Movimientos ($)' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0

outer union corr

select 
'008.02' as Nro_Fila,
'Clientes NF' as Observacion,
'Cargos' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Comision planes',
'Compras Internacionales',
'Compras Redcompra',
'Compras Internacionales MCD',
'Compras Redcompra MCD',
'Giro Internacional',
'Giros ATM',
'Giros Caja',
'OTROS CARGOS',
'PEC',
'Pago LCA',
'Pago de Tarjeta',
'Giros internacional MCD',
'Giros ATM MCD',
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'008.03' as Nro_Fila,
'Clientes NF' as Observacion,
'Compras' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Redcompra',
'Compras Internacionales',
'Compras Internacionales MCD',
'Compras Redcompra MCD',
'PEC'
))

outer union corr

select 
'008.04' as Nro_Fila,
'Clientes NF' as Observacion,
'Compras Redcompra' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Redcompra'
))

outer union corr

select 
'008.05' as Nro_Fila,
'Clientes NF' as Observacion,
'Compras  Redcompra Tienda' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Redcompra'
)) and COMPRA_RIPLEY='COMPRA_RIPLEY'

outer union corr

select 
'008.06' as Nro_Fila,
'Clientes NF' as Observacion,
'Compras Redcompra no Tienda' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Redcompra'
)) and COMPRA_RIPLEY<>'COMPRA_RIPLEY'

outer union corr

select 
'008.07' as Nro_Fila,
'Clientes NF' as Observacion,
'Compras Internacionales' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Internacionales'
))

outer union corr

select 
'008.08' as Nro_Fila,
'Clientes NF' as Observacion,
'PEC' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'PEC'
))

outer union corr

select 
'008.09' as Nro_Fila,
'Clientes NF' as Observacion,
'Giros' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Giros ATM',
'Giros Caja',
'Giros internacional MCD',
'Giros ATM MCD',
'Giro Internacional'
))

outer union corr

select 
'008.10' as Nro_Fila,
'Clientes NF' as Observacion,
'ATM' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Giros ATM'
))

outer union corr

select 
'008.11' as Nro_Fila,
'Clientes NF' as Observacion,
'Caja' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Giros Caja'
))

outer union corr

select 
'008.12' as Nro_Fila,
'Clientes NF' as Observacion,
'Internacional' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Giro Internacional'
))

outer union corr

select 
'008.13' as Nro_Fila,
'Clientes NF' as Observacion,
'TEF emitidas' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'008.14' as Nro_Fila,
'Clientes NF' as Observacion,
'Otros Bancos' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'008.15' as Nro_Fila,
'Clientes NF' as Observacion,
'Pagos' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Pago de Tarjeta',
'Pago LCA'
))

outer union corr

select 
'008.16' as Nro_Fila,
'Clientes NF' as Observacion,
'Pago de Tarjeta' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Pago de Tarjeta'
))

outer union corr

select 
'008.17' as Nro_Fila,
'Clientes NF' as Observacion,
'Pago LCA' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Pago LCA'
))

outer union corr

select 
'008.18' as Nro_Fila,
'Clientes NF' as Observacion,
'Cobro Mantención Cuenta Vista' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Comision planes'
))
 
outer union corr
 
select 
'008.19' as Nro_Fila,
'Clientes NF' as Observacion,
'OTROS CARGOS' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'OTROS CARGOS'
))

outer union corr
 
select 
'008.20' as Nro_Fila,
'Clientes NF' as Observacion,
'Abonos' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Abono de Remuneraciones',
'Avance desde Tarjeta Ripley',
'Depósitos con Documento',
'Depósitos en Efectivo',
'OTROS ABONOS',
'Otros (pago proveedores)',
'TEF Recibidas',
'Traspaso desde LCA'
))
 
outer union corr
 
select 
'008.21' as Nro_Fila,
'Clientes NF' as Observacion,
'Depósitos en Efectivo' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Depósitos en Efectivo'))
 
outer union corr
 
select 
'008.22' as Nro_Fila,
'Clientes NF' as Observacion,
'Depósitos con Documento' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Depósitos con Documento'))
 
outer union corr
 
select 
'008.23' as Nro_Fila,
'Clientes NF' as Observacion,
'TEF Recibidas' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'TEF Recibidas'))
 
outer union corr
 
select 
'008.24' as Nro_Fila,
'Clientes NF' as Observacion,
'Abono de Remuneraciones' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Abono de Remuneraciones'))
 
outer union corr
 
select 
'008.25' as Nro_Fila,
'Clientes NF' as Observacion,
'Otros (pago proveedores)' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Otros (pago proveedores)'))
 
outer union corr
 
select 
'008.26' as Nro_Fila,
'Clientes NF' as Observacion,
'Traspaso desde LCA' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Traspaso desde LCA'))
 
outer union corr
 
select 
'008.27' as Nro_Fila,
'Clientes NF' as Observacion,
'Avance desde Tarjeta Ripley' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Avance desde Tarjeta Ripley'))
 
outer union corr
 
select 
'008.28' as Nro_Fila,
'Clientes NF' as Observacion,
'OTROS ABONOS' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'OTROS ABONOS'))

outer union corr
 
/*Bloque9: Movimientos (Tx)*/
select 
'009.00' as Nro_Fila,
'Clientes NF' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'009.01' as Nro_Fila,
'Clientes NF' as Observacion,
'Movimientos (#)' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 

outer union corr

select 
'009.02' as Nro_Fila,
'Clientes NF' as Observacion,
'Movimientos (#) (Cargos y Abonos)' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Comision planes',
'Compras Internacionales',
'Compras Redcompra',
'Compras Internacionales MCD',
'Compras Redcompra MCD',
'Giro Internacional',
'Giros ATM',
'Giros Caja',
'OTROS CARGOS',
'PEC',
'Pago LCA',
'Giros internacional MCD',
'Giros ATM MCD',
'Pago de Tarjeta',
'TEF emitidas Otros Bancos'
) or Descripcion_Abono in (
'Abono de Remuneraciones',
'Avance desde Tarjeta Ripley',
'Depósitos con Documento',
'Depósitos en Efectivo',
'OTROS ABONOS',
'Otros (pago proveedores)',
'TEF Recibidas',
'Traspaso desde LCA'
))

outer union corr

select 
'009.03' as Nro_Fila,
'Clientes NF' as Observacion,
'Cargos' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Comision planes',
'Compras Internacionales',
'Compras Redcompra',
'Compras Internacionales MCD',
'Compras Redcompra MCD',
'Giro Internacional',
'Giros ATM',
'Giros Caja',
'OTROS CARGOS',
'PEC',
'Pago LCA',
'Giros internacional MCD',
'Giros ATM MCD',
'Pago de Tarjeta',
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'009.04' as Nro_Fila,
'Clientes NF' as Observacion,
'Compras' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Redcompra',
'Compras Internacionales',
'Compras Redcompra MCD',
'Compras Internacionales MCD',
'PEC'
))

outer union corr

select 
'009.05' as Nro_Fila,
'Clientes NF' as Observacion,
'Compras Redcompra' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Redcompra'
))

outer union corr

select 
'009.06' as Nro_Fila,
'Clientes NF' as Observacion,
'Compras  Redcompra Tienda' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Redcompra'
)) and COMPRA_RIPLEY='COMPRA_RIPLEY'

outer union corr

select 
'009.07' as Nro_Fila,
'Clientes NF' as Observacion,
'Compras Redcompra no Tienda' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Redcompra'
)) and COMPRA_RIPLEY<>'COMPRA_RIPLEY'

outer union corr

select 
'009.08' as Nro_Fila,
'Clientes NF' as Observacion,
'Compras Internacionales' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Internacionales'
))

outer union corr

select 
'009.09' as Nro_Fila,
'Clientes NF' as Observacion,
'PEC' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'PEC'
))

outer union corr

select 
'009.10' as Nro_Fila,
'Clientes NF' as Observacion,
'Giros' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Giros ATM',
'Giros Caja',
'Giros internacional MCD',
'Giros ATM MCD',
'Giro Internacional'
))

outer union corr

select 
'009.11' as Nro_Fila,
'Clientes NF' as Observacion,
'ATM' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Giros ATM'
))

outer union corr

select 
'009.12' as Nro_Fila,
'Clientes NF' as Observacion,
'Caja' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Giros Caja'
))

outer union corr

select 
'009.13' as Nro_Fila,
'Clientes NF' as Observacion,
'Internacional' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Giro Internacional'
))

outer union corr

select 
'009.14' as Nro_Fila,
'Clientes NF' as Observacion,
'TEF emitidas' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'009.15' as Nro_Fila,
'Clientes NF' as Observacion,
'Otros Bancos' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'009.16' as Nro_Fila,
'Clientes NF' as Observacion,
'Pagos' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Pago de Tarjeta',
'Pago LCA'
))

outer union corr

select 
'009.17' as Nro_Fila,
'Clientes NF' as Observacion,
'Pago de Tarjeta' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Pago de Tarjeta'
))

outer union corr

select 
'009.18' as Nro_Fila,
'Clientes NF' as Observacion,
'Pago LCA' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Pago LCA'
))

outer union corr

select 
'009.19' as Nro_Fila,
'Clientes NF' as Observacion,
'Cobro Mantención Cuenta Vista' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Comision planes'
))
 
outer union corr
 
select 
'009.20' as Nro_Fila,
'Clientes NF' as Observacion,
'OTROS CARGOS' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'OTROS CARGOS'
))

outer union corr
 
select 
'009.21' as Nro_Fila,
'Clientes NF' as Observacion,
'Abonos' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Abono de Remuneraciones',
'Avance desde Tarjeta Ripley',
'Depósitos con Documento',
'Depósitos en Efectivo',
'OTROS ABONOS',
'Otros (pago proveedores)',
'TEF Recibidas',
'Traspaso desde LCA'
))
 
outer union corr
 
select 
'009.22' as Nro_Fila,
'Clientes NF' as Observacion,
'Depósitos en Efectivo' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Depósitos en Efectivo'))
 
outer union corr
 
select 
'009.23' as Nro_Fila,
'Clientes NF' as Observacion,
'Depósitos con Documento' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Depósitos con Documento'))
 
outer union corr
 
select 
'009.24' as Nro_Fila,
'Clientes NF' as Observacion,
'TEF Recibidas' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'TEF Recibidas'))
 
outer union corr
 
select 
'009.25' as Nro_Fila,
'Clientes NF' as Observacion,
'Abono de Remuneraciones' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Abono de Remuneraciones'))
 
outer union corr
 
select 
'009.26' as Nro_Fila,
'Clientes NF' as Observacion,
'Otros (pago proveedores)' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Otros (pago proveedores)'))
 
outer union corr
 
select 
'009.27' as Nro_Fila,
'Clientes NF' as Observacion,
'Traspaso desde LCA' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Traspaso desde LCA'))
 
outer union corr
 
select 
'009.28' as Nro_Fila,
'Clientes NF' as Observacion,
'Avance desde Tarjeta Ripley' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'Avance desde Tarjeta Ripley'))
 
outer union corr
 
select 
'009.29' as Nro_Fila,
'Clientes NF' as Observacion,
'OTROS ABONOS' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Abono in (
'OTROS ABONOS'))

outer union corr 

select 
'010.00' as Nro_Fila,
'Clientes NF' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'010.01' as Nro_Fila,
'Clientes NF' as Observacion,
'$ Compras Redcompra MCD' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Redcompra MCD'
))

outer union corr

select 
'010.02' as Nro_Fila,
'Clientes NF' as Observacion,
'$ Compras  Redcompra MCD Tienda' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Redcompra MCD'
)) and COMPRA_RIPLEY='COMPRA_RIPLEY'

outer union corr

select 
'010.03' as Nro_Fila,
'Clientes NF' as Observacion,
'$ Compras Redcompra MCD no Tienda' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Redcompra MCD'
)) and COMPRA_RIPLEY<>'COMPRA_RIPLEY'

outer union corr

select 
'010.04' as Nro_Fila,
'Clientes NF' as Observacion,
'$ Compras Internacionales MCD' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Internacionales MCD'
))

outer union corr

select 
'011.00' as Nro_Fila,
'Clientes NF' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'011.01' as Nro_Fila,
'Clientes NF' as Observacion,
'# Compras Redcompra MCD' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Redcompra MCD'
))

outer union corr

select 
'011.02' as Nro_Fila,
'Clientes NF' as Observacion,
'# Compras  Redcompra MCD Tienda' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Redcompra MCD'
)) and COMPRA_RIPLEY='COMPRA_RIPLEY'


outer union corr

select 
'011.03' as Nro_Fila,
'Clientes NF' as Observacion,
'# Compras Redcompra MCD no Tienda' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Redcompra MCD'
)) and COMPRA_RIPLEY<>'COMPRA_RIPLEY'


outer union corr

select 
'011.04' as Nro_Fila,
'Clientes NF' as Observacion,
'# Compras Internacionales MCD' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Compras Internacionales MCD'
))

outer union corr

select 
'012.00' as Nro_Fila,
'Clientes NF' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'012.01' as Nro_Fila,
'Clientes NF' as Observacion,
'Captacion PWA' as Categoria,
sum(case when tipo_capta='PWA' then SI_Captado_Periodo end) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'012.02' as Nro_Fila,
'Clientes NF' as Observacion,
'Captacion Online' as Categoria,
sum(case when tipo_capta='CAPTA_ONLINE' then SI_Captado_Periodo end) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'012.03' as Nro_Fila,
'Clientes NF' as Observacion,
'Captacion Presencial' as Categoria,
sum(case when tipo_capta='PRESENCIAL' then SI_Captado_Periodo end) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'013.00' as Nro_Fila,
'Clientes NF' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario=0

outer union corr

select 
'013.01' as Nro_Fila,
'Clientes NF' as Observacion,
'# Cuentas con Saldo >$1' as Categoria,
count(case when ultimo_saldo>1 then cuenta end) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario=0

outer union corr

select 
'013.02' as Nro_Fila,
'Clientes NF' as Observacion,
'# Cuentas con Saldo >$1.000' as Categoria,
count(case when ultimo_saldo>1000 then cuenta end) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario=0

outer union corr

select 
'013.03' as Nro_Fila,
'Clientes NF' as Observacion,
'# Cuentas con Saldo >$100.000' as Categoria,
count(case when ultimo_saldo>100000 then cuenta end) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario=0

outer union corr
select 
'014.00' as Nro_Fila,
'Clientes NF' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'014.01' as Nro_Fila,
'Clientes NF' as Observacion,
'Stock MAESTRO' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0
and tipo_plastico='MAESTRO'

outer union corr

select 
'014.02' as Nro_Fila,
'Clientes NF' as Observacion,
'Stock CV Inicio de Periodo MAESTRO' as Categoria,
sum(SI_Stock_Anterior) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0 and tipo_plastico='MAESTRO'

outer union corr

select 
'014.03' as Nro_Fila,
'Clientes NF' as Observacion,
'Captacion MAESTRO' as Categoria,
sum(SI_Captado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0 and tipo_plastico='MAESTRO'

outer union corr

select 
'014.04' as Nro_Fila,
'Clientes NF' as Observacion,
'Cierre MAESTRO' as Categoria,
sum(SI_Fugado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0 and tipo_plastico='MAESTRO'

outer union corr

select 
'014.05' as Nro_Fila,
'Clientes NF' as Observacion,
'Stock CV Final de periodo MAESTRO' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0 and tipo_plastico='MAESTRO'

outer union corr

select 
'015.00' as Nro_Fila,
'Clientes NF' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'015.01' as Nro_Fila,
'Clientes NF' as Observacion,
'Stock MCD' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0
and tipo_plastico='MCD'

outer union corr

select 
'015.02' as Nro_Fila,
'Clientes NF' as Observacion,
'Stock CV Inicio de Periodo MCD' as Categoria,
sum(SI_Stock_Anterior) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0 and tipo_plastico='MCD'

outer union corr

select 
'015.03' as Nro_Fila,
'Clientes NF' as Observacion,
'Captacion MCD' as Categoria,
sum(SI_Captado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0 and tipo_plastico='MCD'

outer union corr

select 
'015.04' as Nro_Fila,
'Clientes NF ' as Observacion,
'Cierre MCD' as Categoria,
sum(SI_Fugado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0 and tipo_plastico='MCD'

outer union corr

select 
'015.05' as Nro_Fila,
'Clientes NF' as Observacion,
'Stock CV Final de periodo MCD' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0 and tipo_plastico='MCD'

outer union corr

select 
'016.00' as Nro_Fila,
'Clientes NF' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0

outer union corr

select 
'016.01' as Nro_Fila,
'Clientes NF' as Observacion,
'Stock MAESTRO a MCD' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0
and tipo_plastico='MAESTRO a MCD'

outer union corr

select 
'016.02' as Nro_Fila,
'Clientes NF' as Observacion,
'Stock CV Inicio de Periodo MAESTRO a MCD' as Categoria,
sum(SI_Stock_Anterior) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0 and tipo_plastico='MAESTRO a MCD'

outer union corr

select 
'016.03' as Nro_Fila,
'Clientes NF' as Observacion,
'Captacion MAESTRO a MCD' as Categoria,
sum(SI_Captado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0 and tipo_plastico='MAESTRO a MCD'

outer union corr

select 
'016.04' as Nro_Fila,
'Clientes NF' as Observacion,
'Cierre MAESTRO a MCD' as Categoria,
sum(SI_Fugado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0 and tipo_plastico='MAESTRO a MCD'

outer union corr

select 
'016.05' as Nro_Fila,
'Clientes NF' as Observacion,
'Stock CV Final de periodo MAESTRO a MCD' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario=0 and tipo_plastico='MAESTRO a MCD'


outer union corr

select 
'017.01' as Nro_Fila,
'Clientes NF' as Observacion,
'---------------------' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2


outer union corr

select 
'017.02' as Nro_Fila,
'Clientes NF' as Observacion,
'Monto Giros ATM MCD' as Categoria,
sum(monto) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Giros ATM MCD'
))

outer union corr

select 
'017.03' as Nro_Fila,
'Clientes NF' as Observacion,
'Monto Giros internacional MCD' as Categoria,
sum(monto) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Giros internacional MCD'
))

outer union corr

select 
'017.04' as Nro_Fila,
'Clientes NF' as Observacion,
'TRX Giros ATM MCD' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Giros ATM MCD'
))

outer union corr

select 
'017.05' as Nro_Fila,
'Clientes NF' as Observacion,
'TRX Giros internacional MCD' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario=0 
and (Descripcion_Cargo in (
'Giros internacional MCD'
))


) as X

;quit;



%put--------------------------------------------------------------------------------------------------;
%put [05.3] Funcionario;
%put--------------------------------------------------------------------------------------------------;



%put='query';

proc sql;
insert into work.SB_Salida_Panel_CtaVta
select *
from (
/*Bloque1: Stock*/
select 
'001.00' as Nro_Fila,
'Clientes F' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'001.01' as Nro_Fila,
'Clientes F' as Observacion,
'Stock' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'001.02' as Nro_Fila,
'Clientes F' as Observacion,
'Stock CV Inicio de Periodo' as Categoria,
sum(SI_Stock_Anterior) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'001.03' as Nro_Fila,
'Clientes F' as Observacion,
'Captacion' as Categoria,
sum(SI_Captado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'001.04' as Nro_Fila,
'Clientes F' as Observacion,
'Cierre' as Categoria,
sum(SI_Fugado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'001.05' as Nro_Fila,
'Clientes F' as Observacion,
'Stock CV Final de periodo' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'001.06' as Nro_Fila,
'Clientes F' as Observacion,
'Tasa de cierre' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

/*Bloque2: Informacion de uso CV*/
select 
'002.00' as Nro_Fila,
'Clientes F' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'002.01' as Nro_Fila,
'Clientes F' as Observacion,
'Informacion de uso CV' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'002.02' as Nro_Fila,
'Clientes F' as Observacion,
'# de Cuentas con Movimientos cargos o abonos' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Depósitos en Efectivo',
'Depósitos con Documento',
'TEF Recibidas',
'Abono de Remuneraciones',
'Otros (pago proveedores)',
'Traspaso desde LCA',
'Avance desde Tarjeta Ripley',
'OTROS ABONOS'
)
or
Descripcion_Cargo in (
'Comision planes',
'Compras Internacionales',
'Compras Internacionales MCD',
'Compras Redcompra',
'Compras Redcompra MCD',
'Giro Internacional',
'Giros ATM',
'Giros Caja',
'PEC',
'Pago LCA',
'Pago de Tarjeta',
'Giros internacional MCD',
'Giros ATM MCD',
'TEF emitidas Otros Bancos',
'OTROS CARGOS'
))

outer union corr

select 
'002.03' as Nro_Fila,
'Clientes F' as Observacion,
'# de Cuentas con Cargos' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Comision planes',
'Compras Internacionales',
'Compras Redcompra',
'Compras Internacionales MCD',
'Compras Redcompra MCD',
'Giro Internacional',
'Giros ATM',
'Giros Caja',
'PEC',
'Pago LCA',
'Pago de Tarjeta',
'Giros internacional MCD',
'Giros ATM MCD',
'TEF emitidas Otros Bancos',
'OTROS CARGOS'
))

outer union corr

select 
'002.04' as Nro_Fila,
'Clientes F' as Observacion,
'Cuentas con compras' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Internacionales',
'Compras Redcompra',
'Compras Internacionales MCD',
'Compras Redcompra MCD'
))

outer union corr

select 
'002.05' as Nro_Fila,
'Clientes F' as Observacion,
'Cuentas con Giros' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Giro Internacional',
'Giros ATM',
'Giros internacional MCD',
'Giros ATM MCD',
'Giros Caja'
))

outer union corr

select 
'002.06' as Nro_Fila,
'Clientes F' as Observacion,
'Cuentas con TEF' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'002.07' as Nro_Fila,
'Clientes F' as Observacion,
'Cuentas con Pago' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Pago de Tarjeta',
'Pago LCA'
))

outer union corr

select 
'002.08' as Nro_Fila,
'Clientes F' as Observacion,
'Cuentas con uso Internacional' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Giro Internacional'
'Giros internacional MCD'
))

outer union corr

select 
'002.09' as Nro_Fila,
'Clientes F' as Observacion,
'# Cuentas con  Abonos' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Abono de Remuneraciones',
'Avance desde Tarjeta Ripley',
'Depósitos con Documento',
'Depósitos en Efectivo',
'OTROS ABONOS',
'Otros (pago proveedores)',
'TEF Recibidas',
'Traspaso desde LCA'
))

outer union corr

select 
'002.10' as Nro_Fila,
'Clientes F' as Observacion,
'Depósitos en Efectivo' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Depósitos en Efectivo'))

outer union corr

select 
'002.11' as Nro_Fila,
'Clientes F' as Observacion,
'Depósitos con Documento' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Depósitos con Documento'))

outer union corr

select 
'002.12' as Nro_Fila,
'Clientes F' as Observacion,
'TEF Recibidas' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'TEF Recibidas'))

outer union corr

select 
'002.13' as Nro_Fila,
'Clientes F' as Observacion,
'Abono de Remuneraciones' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Abono de Remuneraciones'))

outer union corr

select 
'002.14' as Nro_Fila,
'Clientes F' as Observacion,
'Otros (pago proveedores)' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Otros (pago proveedores)'))

outer union corr

select 
'002.15' as Nro_Fila,
'Clientes F' as Observacion,
'Traspaso desde LCA' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Traspaso desde LCA'))

outer union corr

select 
'002.16' as Nro_Fila,
'Clientes F' as Observacion,
'Avance desde Tarjeta Ripley' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Avance desde Tarjeta Ripley')) 

outer union corr

select 
'002.17' as Nro_Fila,
'Clientes F' as Observacion,
'OTROS ABONOS' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'OTROS ABONOS'))

outer union corr

/*Bloque3: Informacion de uso CV %*/
select 
'003.00' as Nro_Fila,
'Clientes F' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'003.01' as Nro_Fila,
'Clientes F' as Observacion,
'Informacion de uso CV %' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'003.02' as Nro_Fila,
'Clientes F' as Observacion,
'% de Cuentas con movimiento o abonos' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'003.03' as Nro_Fila,
'Clientes F' as Observacion,
'% de Cuentas con Cargos' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'003.04' as Nro_Fila,
'Clientes F' as Observacion,
'Cuentas con compras' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'003.05' as Nro_Fila,
'Clientes F' as Observacion,
'Cuentas con Giros' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'003.06' as Nro_Fila,
'Clientes F' as Observacion,
'Cuentas con TEF' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'003.07' as Nro_Fila,
'Clientes F' as Observacion,
'Cuentas con uso Internacional' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'003.08' as Nro_Fila,
'Clientes F' as Observacion,
'% Cuentas con Abonos' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'003.09' as Nro_Fila,
'Clientes F' as Observacion,
'Depósitos en Efectivo' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'003.10' as Nro_Fila,
'Clientes F' as Observacion,
'Depósitos con Documento' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'003.11' as Nro_Fila,
'Clientes F' as Observacion,
'TEF Recibidas' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'003.12' as Nro_Fila,
'Clientes F' as Observacion,
'Abono de Remuneraciones' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'003.13' as Nro_Fila,
'Clientes F' as Observacion,
'Otros (pago proveedores)' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'003.14' as Nro_Fila,
'Clientes F' as Observacion,
'Traspaso desde LCA' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'003.15' as Nro_Fila,
'Clientes F' as Observacion,
'Avance desde Tarjeta Ripley' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 

outer union corr

select 
'003.16' as Nro_Fila,
'Clientes F' as Observacion,
'OTROS ABONOS' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

/*Bloque4: Informacion de ABR*/
select 
'004.00' as Nro_Fila,
'Clientes F' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'004.01' as Nro_Fila,
'Clientes F' as Observacion,
'Informacion de ABR' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'004.02' as Nro_Fila,
'Clientes F' as Observacion,
'# de Cuentas Distintas Total Abonos >= $270.000' as Categoria,
count(distinct cuenta) as Valor
from (
select cuenta,sum(Monto) as SUM_Monto
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and GLS_TRANSAC='ABONO'
and Descripcion_Abono NOT IN ('Traspaso desde LCA','Abono de Remuneraciones','Avance desde Tarjeta Ripley')
and SI_ABR=0
group by cuenta
) as X
where SUM_Monto>=270000

outer union corr

select 
'004.03' as Nro_Fila,
'Clientes F' as Observacion,
'# de Cuentas Distintas con ABR' as Categoria,
count(distinct cuenta) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and SI_ABR=1

outer union corr

select 
'004.04' as Nro_Fila,
'Clientes F' as Observacion,
'% de ABR vigentes' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'004.05' as Nro_Fila,
'Clientes F' as Observacion,
'# de ABR suscritos de los Captados' as Categoria,
count(*) as Valor
from work.SB_SUSCRITOS_CV
where SI_Funcionario>0 

outer union corr

select 
'004.06' as Nro_Fila,
'Clientes F' as Observacion,
'Tasa de cruce de ABR en Captacion' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'004.07' as Nro_Fila,
'Clientes F' as Observacion,
'% de ABR con Cargo' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

/*Bloque5: Informacion de uso CV/por cuenta*/
select 
'005.00' as Nro_Fila,
'Clientes F' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>0

outer union corr

select 
'005.01' as Nro_Fila,
'Clientes F' as Observacion,
'Informacion de uso CV/por cuenta' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'005.02' as Nro_Fila,
'Clientes F' as Observacion,
'# de movimiento por cuenta cargo y abono' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'005.03' as Nro_Fila,
'Clientes F' as Observacion,
'# de cargos por cuenta' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'005.04' as Nro_Fila,
'Clientes F' as Observacion,
'# de compras por cuenta' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'005.05' as Nro_Fila,
'Clientes F' as Observacion,
'# de Giros por cuenta' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'005.06' as Nro_Fila,
'Clientes F' as Observacion,
'# de TEF por cuenta' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'005.07' as Nro_Fila,
'Clientes F' as Observacion,
'# uso internacional por cuenta' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'005.08' as Nro_Fila,
'Clientes F' as Observacion,
'# Abonos por cuenta' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'005.09' as Nro_Fila,
'Clientes F' as Observacion,
'# Depósitos en Efectivo' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'005.10' as Nro_Fila,
'Clientes F' as Observacion,
'# Depósitos con Documento' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'005.11' as Nro_Fila,
'Clientes F' as Observacion,
'# TEF Recibidas' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'005.12' as Nro_Fila,
'Clientes F' as Observacion,
'# Abono de Remuneraciones' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'005.13' as Nro_Fila,
'Clientes F' as Observacion,
'# Otros (pago proveedores)' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'005.14' as Nro_Fila,
'Clientes F' as Observacion,
'# Traspaso desde LCA' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'005.15' as Nro_Fila,
'Clientes F' as Observacion,
'# Avance desde Tarjeta Ripley' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

/*Bloque6: Informacion de Saldo*/
select 
'006.00' as Nro_Fila,
'Clientes F' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>0

outer union corr

select 
'006.01' as Nro_Fila,
'Clientes F' as Observacion,
'Informacion de Saldo' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>0

outer union corr

select 
'006.02' as Nro_Fila,
'Clientes F' as Observacion,
'Cuentas con Saldo >$1' as Categoria,
count(*) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>0
and Nro_Dias_Saldo_mayor_1>0

outer union corr

select 
'006.03' as Nro_Fila,
'Clientes F' as Observacion,
'Cuentas con Saldo >$1 EOP' as Categoria,
count(*) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>0
and Ultimo_Saldo>1

outer union corr

select 
'006.04' as Nro_Fila,
'Clientes F' as Observacion,
'Saldo Total Promedio Mes (MM$)' as Categoria,
sum(SUM_SALDO_FECHA/&max_dia.)/1000000 as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>0
and Nro_Dias_Saldo_mayor_1>0

outer union corr

select 
'006.05' as Nro_Fila,
'Clientes F' as Observacion,
'Saldo Total EOP (MM$)' as Categoria,
sum(Ultimo_Saldo)/1000000 as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>0

outer union corr

select 
'006.06' as Nro_Fila,
'Clientes F' as Observacion,
'Saldo Promedio por cuenta Activa ($)' as Categoria,
max(0) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>0

outer union corr

/*Bloque7: Informacion de Saldo %*/
select 
'007.00' as Nro_Fila,
'Clientes F' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'007.01' as Nro_Fila,
'Clientes F' as Observacion,
'Informacion de Saldo %' as Categoria,
max(floor(&ini_num)) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'007.02' as Nro_Fila,
'Clientes F' as Observacion,
'% de Cuentas con Saldo' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

/*Bloque8: Movimientos ($)*/
select 
'008.00' as Nro_Fila,
'Clientes F' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'008.01' as Nro_Fila,
'Clientes F' as Observacion,
'Movimientos ($)' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0

outer union corr

select 
'008.02' as Nro_Fila,
'Clientes F' as Observacion,
'Cargos' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Comision planes',
'Compras Internacionales',
'Compras Redcompra',
'Compras Internacionales MCD',
'Compras Redcompra MCD',
'Giro Internacional',
'Giros ATM',
'Giros Caja',
'OTROS CARGOS',
'PEC',
'Pago LCA',
'Giros internacional MCD',
'Giros ATM MCD',
'Pago de Tarjeta',
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'008.03' as Nro_Fila,
'Clientes F' as Observacion,
'Compras' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Redcompra',
'Compras Internacionales',
'Compras Internacionales MCD',
'Compras Redcompra MCD',
'PEC'
))

outer union corr

select 
'008.04' as Nro_Fila,
'Clientes F' as Observacion,
'Compras Redcompra' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Redcompra'
))

outer union corr

select 
'008.05' as Nro_Fila,
'Clientes F' as Observacion,
'Compras  Redcompra Tienda' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Redcompra'
)) and COMPRA_RIPLEY='COMPRA_RIPLEY'

outer union corr

select 
'008.06' as Nro_Fila,
'Clientes F' as Observacion,
'Compras Redcompra no Tienda' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Redcompra'
)) and COMPRA_RIPLEY<>'COMPRA_RIPLEY'

outer union corr

select 
'008.07' as Nro_Fila,
'Clientes F' as Observacion,
'Compras Internacionales' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Internacionales'
))

outer union corr

select 
'008.08' as Nro_Fila,
'Clientes F' as Observacion,
'PEC' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'PEC'
))

outer union corr

select 
'008.09' as Nro_Fila,
'Clientes F' as Observacion,
'Giros' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Giros ATM',
'Giros Caja',
'Giros internacional MCD',
'Giros ATM MCD',
'Giro Internacional'
))

outer union corr

select 
'008.10' as Nro_Fila,
'Clientes F' as Observacion,
'ATM' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Giros ATM'
))

outer union corr

select 
'008.11' as Nro_Fila,
'Clientes F' as Observacion,
'Caja' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Giros Caja'
))

outer union corr

select 
'008.12' as Nro_Fila,
'Clientes F' as Observacion,
'Internacional' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Giro Internacional'
))

outer union corr

select 
'008.13' as Nro_Fila,
'Clientes F' as Observacion,
'TEF emitidas' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'008.14' as Nro_Fila,
'Clientes F' as Observacion,
'Otros Bancos' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'008.15' as Nro_Fila,
'Clientes F' as Observacion,
'Pagos' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Pago de Tarjeta',
'Pago LCA'
))

outer union corr

select 
'008.16' as Nro_Fila,
'Clientes F' as Observacion,
'Pago de Tarjeta' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Pago de Tarjeta'
))

outer union corr

select 
'008.17' as Nro_Fila,
'Clientes F' as Observacion,
'Pago LCA' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Pago LCA'
))

outer union corr

select 
'008.18' as Nro_Fila,
'Clientes F' as Observacion,
'Cobro Mantención Cuenta Vista' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Comision planes'
))
 
outer union corr
 
select 
'008.19' as Nro_Fila,
'Clientes F' as Observacion,
'OTROS CARGOS' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'OTROS CARGOS'
))

outer union corr
 
select 
'008.20' as Nro_Fila,
'Clientes F' as Observacion,
'Abonos' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Abono de Remuneraciones',
'Avance desde Tarjeta Ripley',
'Depósitos con Documento',
'Depósitos en Efectivo',
'OTROS ABONOS',
'Otros (pago proveedores)',
'TEF Recibidas',
'Traspaso desde LCA'
))
 
outer union corr
 
select 
'008.21' as Nro_Fila,
'Clientes F' as Observacion,
'Depósitos en Efectivo' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Depósitos en Efectivo'))
 
outer union corr
 
select 
'008.22' as Nro_Fila,
'Clientes F' as Observacion,
'Depósitos con Documento' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Depósitos con Documento'))
 
outer union corr
 
select 
'008.23' as Nro_Fila,
'Clientes F' as Observacion,
'TEF Recibidas' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'TEF Recibidas'))
 
outer union corr
 
select 
'008.24' as Nro_Fila,
'Clientes F' as Observacion,
'Abono de Remuneraciones' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Abono de Remuneraciones'))
 
outer union corr
 
select 
'008.25' as Nro_Fila,
'Clientes F' as Observacion,
'Otros (pago proveedores)' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Otros (pago proveedores)'))
 
outer union corr
 
select 
'008.26' as Nro_Fila,
'Clientes F' as Observacion,
'Traspaso desde LCA' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Traspaso desde LCA'))
 
outer union corr
 
select 
'008.27' as Nro_Fila,
'Clientes F' as Observacion,
'Avance desde Tarjeta Ripley' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Avance desde Tarjeta Ripley'))
 
outer union corr
 
select 
'008.28' as Nro_Fila,
'Clientes F' as Observacion,
'OTROS ABONOS' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'OTROS ABONOS'))

outer union corr
 
/*Bloque9: Movimientos (Tx)*/
select 
'009.00' as Nro_Fila,
'Clientes F' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'009.01' as Nro_Fila,
'Clientes F' as Observacion,
'Movimientos (#)' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 

outer union corr

select 
'009.02' as Nro_Fila,
'Clientes F' as Observacion,
'Movimientos (#) (Cargos y Abonos)' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Comision planes',
'Compras Internacionales',
'Compras Redcompra',
'Compras Internacionales MCD',
'Compras Redcompra MCD',
'Giro Internacional',
'Giros ATM',
'Giros Caja',
'OTROS CARGOS',
'PEC',
'Pago LCA',
'Giros internacional MCD',
'Giros ATM MCD',
'Pago de Tarjeta',
'TEF emitidas Otros Bancos'
) or Descripcion_Abono in (
'Abono de Remuneraciones',
'Avance desde Tarjeta Ripley',
'Depósitos con Documento',
'Depósitos en Efectivo',
'OTROS ABONOS',
'Otros (pago proveedores)',
'TEF Recibidas',
'Traspaso desde LCA'
))

outer union corr

select 
'009.03' as Nro_Fila,
'Clientes F' as Observacion,
'Cargos' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Comision planes',
'Compras Internacionales',
'Compras Redcompra',
'Compras Internacionales MCD',
'Compras Redcompra MCD',
'Giro Internacional',
'Giros ATM',
'Giros Caja',
'OTROS CARGOS',
'PEC',
'Giros internacional MCD',
'Giros ATM MCD',
'Pago LCA',
'Pago de Tarjeta',
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'009.04' as Nro_Fila,
'Clientes F' as Observacion,
'Compras' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Redcompra',
'Compras Internacionales',
'Compras Redcompra MCD',
'Compras Internacionales MCD',
'PEC'
))

outer union corr

select 
'009.05' as Nro_Fila,
'Clientes F' as Observacion,
'Compras Redcompra' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Redcompra'
))

outer union corr

select 
'009.06' as Nro_Fila,
'Clientes F' as Observacion,
'Compras  Redcompra Tienda' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Redcompra'
)) and COMPRA_RIPLEY='COMPRA_RIPLEY'

outer union corr

select 
'009.07' as Nro_Fila,
'Clientes F' as Observacion,
'Compras Redcompra no Tienda' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Redcompra'
)) and COMPRA_RIPLEY<>'COMPRA_RIPLEY'

outer union corr

select 
'009.08' as Nro_Fila,
'Clientes F' as Observacion,
'Compras Internacionales' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Internacionales'
))

outer union corr

select 
'009.09' as Nro_Fila,
'Clientes F' as Observacion,
'PEC' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'PEC'
))

outer union corr

select 
'009.10' as Nro_Fila,
'Clientes F' as Observacion,
'Giros' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Giros ATM',
'Giros Caja',
'Giros internacional MCD',
'Giros ATM MCD',
'Giro Internacional'
))

outer union corr

select 
'009.11' as Nro_Fila,
'Clientes F' as Observacion,
'ATM' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Giros ATM'
))

outer union corr

select 
'009.12' as Nro_Fila,
'Clientes F' as Observacion,
'Caja' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Giros Caja'
))

outer union corr

select 
'009.13' as Nro_Fila,
'Clientes F' as Observacion,
'Internacional' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Giro Internacional'
))

outer union corr

select 
'009.14' as Nro_Fila,
'Clientes F' as Observacion,
'TEF emitidas' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'009.15' as Nro_Fila,
'Clientes F' as Observacion,
'Otros Bancos' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'TEF emitidas Otros Bancos'
))

outer union corr

select 
'009.16' as Nro_Fila,
'Clientes F' as Observacion,
'Pagos' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Pago de Tarjeta',
'Pago LCA'
))

outer union corr

select 
'009.17' as Nro_Fila,
'Clientes F' as Observacion,
'Pago de Tarjeta' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Pago de Tarjeta'
))

outer union corr

select 
'009.18' as Nro_Fila,
'Clientes F' as Observacion,
'Pago LCA' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Pago LCA'
))

outer union corr

select 
'009.19' as Nro_Fila,
'Clientes F' as Observacion,
'Cobro Mantención Cuenta Vista' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Comision planes'
))
 
outer union corr
 
select 
'009.20' as Nro_Fila,
'Clientes F' as Observacion,
'OTROS CARGOS' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'OTROS CARGOS'
))

outer union corr
 
select 
'009.21' as Nro_Fila,
'Clientes F' as Observacion,
'Abonos' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Abono de Remuneraciones',
'Avance desde Tarjeta Ripley',
'Depósitos con Documento',
'Depósitos en Efectivo',
'OTROS ABONOS',
'Otros (pago proveedores)',
'TEF Recibidas',
'Traspaso desde LCA'
))
 
outer union corr
 
select 
'009.22' as Nro_Fila,
'Clientes F' as Observacion,
'Depósitos en Efectivo' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Depósitos en Efectivo'))
 
outer union corr
 
select 
'009.23' as Nro_Fila,
'Clientes F' as Observacion,
'Depósitos con Documento' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Depósitos con Documento'))
 
outer union corr
 
select 
'009.24' as Nro_Fila,
'Clientes F' as Observacion,
'TEF Recibidas' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'TEF Recibidas'))
 
outer union corr
 
select 
'009.25' as Nro_Fila,
'Clientes F' as Observacion,
'Abono de Remuneraciones' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Abono de Remuneraciones'))
 
outer union corr
 
select 
'009.26' as Nro_Fila,
'Clientes F' as Observacion,
'Otros (pago proveedores)' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Otros (pago proveedores)'))
 
outer union corr
 
select 
'009.27' as Nro_Fila,
'Clientes F' as Observacion,
'Traspaso desde LCA' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Traspaso desde LCA'))
 
outer union corr
 
select 
'009.28' as Nro_Fila,
'Clientes F' as Observacion,
'Avance desde Tarjeta Ripley' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'Avance desde Tarjeta Ripley'))
 
outer union corr
 
select 
'009.29' as Nro_Fila,
'Clientes F' as Observacion,
'OTROS ABONOS' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Abono in (
'OTROS ABONOS'))

outer union corr 

select 
'010.00' as Nro_Fila,
'Clientes F' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'010.01' as Nro_Fila,
'Clientes F' as Observacion,
'$ Compras Redcompra MCD' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Redcompra MCD'
))

outer union corr

select 
'010.02' as Nro_Fila,
'Clientes F' as Observacion,
'$ Compras  Redcompra MCD Tienda' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Redcompra MCD'
)) and COMPRA_RIPLEY='COMPRA_RIPLEY'

outer union corr

select 
'010.03' as Nro_Fila,
'Clientes F' as Observacion,
'$ Compras Redcompra MCD no Tienda' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Redcompra MCD'
)) and COMPRA_RIPLEY<>'COMPRA_RIPLEY'

outer union corr

select 
'010.04' as Nro_Fila,
'Clientes F' as Observacion,
'$ Compras Internacionales MCD' as Categoria,
sum(MONTO) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Internacionales MCD'
))

outer union corr

select 
'011.00' as Nro_Fila,
'Clientes F' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'011.01' as Nro_Fila,
'Clientes F' as Observacion,
'# Compras Redcompra MCD' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Redcompra MCD'
))

outer union corr

select 
'011.02' as Nro_Fila,
'Clientes F' as Observacion,
'# Compras  Redcompra MCD Tienda' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Redcompra MCD'
)) and COMPRA_RIPLEY='COMPRA_RIPLEY'


outer union corr

select 
'011.03' as Nro_Fila,
'Clientes F' as Observacion,
'# Compras Redcompra MCD no Tienda' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Redcompra MCD'
)) and COMPRA_RIPLEY<>'COMPRA_RIPLEY'


outer union corr

select 
'011.04' as Nro_Fila,
'Clientes F' as Observacion,
'# Compras Internacionales MCD' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Compras Internacionales MCD'
))

outer union corr

select 
'012.00' as Nro_Fila,
'Clientes F' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'012.01' as Nro_Fila,
'Clientes F' as Observacion,
'Captacion PWA' as Categoria,
sum(case when tipo_capta='PWA' then SI_Captado_Periodo end) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'012.02' as Nro_Fila,
'Clientes F' as Observacion,
'Captacion Online' as Categoria,
sum(case when tipo_capta='CAPTA_ONLINE' then SI_Captado_Periodo end) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'012.03' as Nro_Fila,
'Clientes F' as Observacion,
'Captacion Presencial' as Categoria,
sum(case when tipo_capta='PRESENCIAL' then SI_Captado_Periodo end) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'013.00' as Nro_Fila,
'Clientes F' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>0

outer union corr

select 
'013.01' as Nro_Fila,
'Clientes F' as Observacion,
'# Cuentas con Saldo >$1' as Categoria,
count(case when ultimo_saldo>1 then cuenta end) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>0

outer union corr

select 
'013.02' as Nro_Fila,
'Clientes F' as Observacion,
'# Cuentas con Saldo >$1.000' as Categoria,
count(case when ultimo_saldo>1000 then cuenta end) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>0

outer union corr

select 
'013.03' as Nro_Fila,
'Clientes F' as Observacion,
'# Cuentas con Saldo >$100.000' as Categoria,
count(case when ultimo_saldo>100000 then cuenta end) as Valor
from work.SB_Saldos_Cuenta_Vista2
where SI_Funcionario>0

outer union corr
select 
'014.00' as Nro_Fila,
'Clientes F' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'014.01' as Nro_Fila,
'Clientes F' as Observacion,
'Stock MAESTRO' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0
and tipo_plastico='MAESTRO'

outer union corr

select 
'014.02' as Nro_Fila,
'Clientes F' as Observacion,
'Stock CV Inicio de Periodo MAESTRO' as Categoria,
sum(SI_Stock_Anterior) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0 and tipo_plastico='MAESTRO'

outer union corr

select 
'014.03' as Nro_Fila,
'Clientes F' as Observacion,
'Captacion MAESTRO' as Categoria,
sum(SI_Captado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0 and tipo_plastico='MAESTRO'

outer union corr

select 
'014.04' as Nro_Fila,
'Clientes F' as Observacion,
'Cierre MAESTRO' as Categoria,
sum(SI_Fugado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0 and tipo_plastico='MAESTRO'

outer union corr

select 
'014.05' as Nro_Fila,
'Clientes F' as Observacion,
'Stock CV Final de periodo MAESTRO' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0 and tipo_plastico='MAESTRO'

outer union corr 

select 
'015.00' as Nro_Fila,
'Clientes F' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'015.01' as Nro_Fila,
'Clientes F' as Observacion,
'Stock MCD' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0
and tipo_plastico='MCD'

outer union corr

select 
'015.02' as Nro_Fila,
'Clientes F' as Observacion,
'Stock CV Inicio de Periodo MCD' as Categoria,
sum(SI_Stock_Anterior) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0 and tipo_plastico='MCD'

outer union corr

select 
'015.03' as Nro_Fila,
'Clientes F' as Observacion,
'Captacion MCD' as Categoria,
sum(SI_Captado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0 and tipo_plastico='MCD'

outer union corr

select 
'015.04' as Nro_Fila,
'Clientes F ' as Observacion,
'Cierre MCD' as Categoria,
sum(SI_Fugado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0 and tipo_plastico='MCD'

outer union corr

select 
'015.05' as Nro_Fila,
'Clientes F' as Observacion,
'Stock CV Final de periodo MCD' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0 and tipo_plastico='MCD'

outer union corr

select 
'016.00' as Nro_Fila,
'Clientes F' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0

outer union corr

select 
'016.01' as Nro_Fila,
'Clientes F' as Observacion,
'Stock MAESTRO a MCD' as Categoria,
max(floor(&ini_num/100)) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0
and tipo_plastico='MAESTRO a MCD'

outer union corr

select 
'016.02' as Nro_Fila,
'Clientes F' as Observacion,
'Stock CV Inicio de Periodo MAESTRO a MCD' as Categoria,
sum(SI_Stock_Anterior) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0 and tipo_plastico='MAESTRO a MCD'

outer union corr

select 
'016.03' as Nro_Fila,
'Clientes F' as Observacion,
'Captacion MAESTRO a MCD' as Categoria,
sum(SI_Captado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0 and tipo_plastico='MAESTRO a MCD'

outer union corr

select 
'016.04' as Nro_Fila,
'Clientes F' as Observacion,
'Cierre MAESTRO a MCD' as Categoria,
sum(SI_Fugado_Periodo) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0 and tipo_plastico='MAESTRO a MCD'

outer union corr

select 
'016.05' as Nro_Fila,
'Clientes F' as Observacion,
'Stock CV Final de periodo MAESTRO a MCD' as Categoria,
max(0) as Valor
from work.SB_Stock_Cuenta_Vista
where SI_Funcionario>0 and tipo_plastico='MAESTRO a MCD'


outer union corr

select 
'017.01' as Nro_Fila,
'Clientes F' as Observacion,
'---------------------' as Categoria,
max(0) as Valor
from work.SB_MOV_CUENTA_VISTA2


outer union corr

select 
'017.02' as Nro_Fila,
'Clientes F' as Observacion,
'Monto Giros ATM MCD' as Categoria,
sum(monto) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Giros ATM MCD'
))

outer union corr

select 
'017.03' as Nro_Fila,
'Clientes F' as Observacion,
'Monto Giros internacional MCD' as Categoria,
sum(monto) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Giros internacional MCD'
))

outer union corr

select 
'017.04' as Nro_Fila,
'Clientes F' as Observacion,
'TRX Giros ATM MCD' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Giros ATM MCD'
))

outer union corr

select 
'017.05' as Nro_Fila,
'Clientes F' as Observacion,
'TRX Giros internacional MCD' as Categoria,
count(*) as Valor
from work.SB_MOV_CUENTA_VISTA2
where SI_Funcionario>0 
and (Descripcion_Cargo in (
'Giros internacional MCD'
))


) as X

;quit;

%put--------------------------------------------------------------------------------------------------;
%put [05.4] Eliminar tablas de paso;
%put--------------------------------------------------------------------------------------------------;

proc sql;
drop table work.SB_Stock_Cuenta_Vista;
drop table work.SB_Saldos_Cuenta_Vista2;
drop table work.SB_MOV_CUENTA_VISTA2;
drop table work.SB_SUSCRITOS_CV;
;quit;

%put==================================================================================================;
%put [06] Vaciar resultados en tabla entregable;
%put==================================================================================================;


/*rescatar Fecha del Proceso*/

/*Vaciar resultados en tabla en duro*/

proc sql;
create table &libref..Panel_CtaVta as 	/*	VALIDADO	*/
SELECT 
dhms(date(), 0, 0, time()) format=datetime. as Fecha_Proceso, 
&ini_num. as anomesdia_desde, 
&fin_num. as anomesdia_hasta, 
* 
from work.SB_Salida_Panel_CtaVta  
;quit;



%put==================================================================================================;
%put [07] Consolidar Resultados en tabla agrupada (solo si se ingresa periodo);
%put==================================================================================================;


/*Consultar si existe previamente tabla consolidada */

%if  %index(&Periodo.,-)<=0 %then /*si no tiene guion viene en formato AAAAMM*/
%do; /*inicio if*/ 
PROC SQL noprint ;   
select count(*) as Si_Existe_Tabla 
into :Si_Existe_Tabla 
from ( 
select *  
from ( 
select 
*, 
cat(trim(libname),.,trim(memname)) as Nombre_Tabla 
from sashelp.vmember 
where 
trim(libname)=upper("&libref.")
and trim(memname)='PANEL_CTAVTA_CONSOLIDADO'
) as a 
) as x 

;QUIT; 

%end; /*final de if */



/*CREAR/APILAR TABLA*/

%if  %index(&Periodo,-)<=0 and &Si_Existe_Tabla.=0 %then /*si no tiene guion viene en formato AAAAMM*/
%do; /*inicio if*/ 
PROC SQL;   
create table &libref..Panel_CtaVta_CONSOLIDADO as 
select 
*, 
&fec_proceso. as Fecha2_Proceso, 
&periodo. as Periodo 
from &libref..Panel_CtaVta  	/*	VALIDADO	*/
;QUIT; 
%end; /*final de if */

%if  %index(&Periodo.,-)<=0 and &Si_Existe_Tabla.>0 %then
%do; /*inicio else*/

/*eliminar de la tabla previamente periodo que se va a insertar para evitar duplicidad*/
PROC SQL;   
delete * from &libref..Panel_CtaVta_CONSOLIDADO  
where Periodo=&periodo.
;QUIT; 

PROC SQL;   
insert into &libref..Panel_CtaVta_CONSOLIDADO  
select 
*, 
&fec_proceso. as Fecha2_Proceso, 
&periodo. as Periodo 
from &libref..Panel_CtaVta  
;QUIT; 

%end; /*final de else */

%put==================================================================================================;
%put [08] Borrado de las tablas de paso;
%put==================================================================================================;

proc sql;
drop table work.core_venta;
drop table work.dotacion;
drop table work.sb_saldos_cuenta_vista;
drop table work.sb_salida_panel_ctavta;
;QUIT;

%mend PANEL_CV;

/*si es el primer dia habil del mes generar cierre del mes anterior*/


/*si es el primer dia habil del mes generar cierre del mes anterior*/

proc sql inobs=1 noprint ; 
select 
mdy(month(today()), 1, year(today())) format=date9. as PRIMER_DIA_MES,
NWKDOM(1, 2, month(today()), year(today())) format=date9. as PRIMER_LUNES,
case when day(calculated PRIMER_LUNES) <= 3 then calculated PRIMER_LUNES
else intnx('weekday17w',calculated PRIMER_DIA_MES,0) end format=date9. as PRIMER_DIAL_LABORAL
into
:PRIMER_DIAL_LABORAL
from pmunoz.codigos_capta_cdp
;QUIT;

%let PRIMER_DIAL_LABORAL=&PRIMER_DIAL_LABORAL;
%put &PRIMER_DIAL_LABORAL;


data _null_;
todays_date=put(intnx('month',today(),0.,'same'), date9.);
call symput('todays_date',todays_date);
run;
%put &todays_date;

%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

%if %eval(&todays_date.=&PRIMER_DIAL_LABORAL.) %then %do;
%PANEL_CV(1,&libref.);
%end;
%else %do;

%PANEL_CV(0,&libref.);
%end;



/*	Fecha ejecución del proceso	*/
data _null_;
execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechaeDVN", execDVN) ;
RUN;
%put &fechaeDVN;/*fecha ejecucion proceso */

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';

SELECT EMAIL into :DEST_2 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_3 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

	SELECT EMAIL into :DEST_5 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'KARINA_MARTINEZ';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;
%put &=DEST_5;


data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_5","bmartinezg@bancoripley.com")
CC = ("&DEST_2","&DEST_3")
SUBJECT = ("MAIL_AUTOM: Panel Cuenta Vista");
FILE OUTBOX;
 PUT "Estimados:";
 put " Proceso Panel Cuenta Vista ejecutado,  con fecha: &fechaeDVN";  
 put ; 
 put ; 
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 06'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;   

data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */
