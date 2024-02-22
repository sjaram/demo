
/*Nuevo Proceso Panel Cta Cte con aperturas en Digital, Presencial, Funcionarios y Total*/


options validvarname=any;
%let libreria=RESULT;

%macro PANEL_CC(libreria,n);


DATA _null_;
per = put(intnx('month',today(),-&n.,'end'), yymmn6.);
INI=put(intnx('month',today(),-&n.,'begin'), date9.);
FIN=put(intnx('month',today(),-&n.,'end'), date9.);
fec_proceso=put(intnx('day',today(),0,'same'), yymmddn8.);
INI_NUM=put(intnx('month',today(),-&n.,'begin'), yymmddn8.);
FIN_NUM=put(intnx('month',today(),-&n.,'end'), yymmddn8.);
ini_char = put(intnx('month',today(),-&N.,'begin'),ddmmyy10.);
fin_char = put(intnx('month',today(),-&N.,'end'),ddmmyy10. );

call symput("periodo",per);
call symput("INI",INI);
call symput("FIN",FIN);
call symput("INI_NUM",INI_NUM);
call symput("FIN_NUM",FIN_NUM);
call symput("fec_proceso",fec_proceso);
call symput("INI_char",INI_char);
call symput("fin_char",fin_char);
run;
%put &periodo;
%put &INI;
%put &FIN;
%put &INI_NUM;
%put &FIN_NUM;
%put &fec_proceso;
%put &INI_char;
%put &fin_char;

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
SELECT DISTINCT
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


%put==================================================================================================;
%put [01] Base de datos de Stock de Cuenta corriente;
%put==================================================================================================;

%put--------------------------------------------------------------------------------------------------;
%put [01.1] Generar Tabla Stock de Cuentacorriente;
%put--------------------------------------------------------------------------------------------------;


PROC SQL  NOERRORSTOP;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );
create table Stock_Cuenta_corriente  as
select distinct * from connection to ORACLE
( 
SELECT DISTINCT
CAST(SUBSTR(a.cli_identifica,1,length(a.cli_identifica)-1) AS INT)  rut,
SUBSTR(a.cli_identifica,length(a.cli_identifica),1)  dv,
b.vis_numcue  cuenta, 
cast(TO_CHAR( b.vis_fechape,'YYYYMMDD') as INT) as FECHA_APERTURA,
cast(TO_CHAR( b.VIS_FECHCIERR,'YYYYMMDD') as INT) as FECHA_CIERRE,
CASE WHEN b.VIS_PRO=4 THEN 'CUENTA_VISTA'
     WHEN b.VIS_PRO=1 THEN 'CUENTA_CORRIENTE'
WHEN b.VIS_PRO=40 THEN 'LCA' END  DESCRIP_PRODUCTO,
CASE WHEN b.vis_status ='9' THEN 'cerrado' 
when b.vis_status ='2' then 'vigente' end as estado_cuenta,
vis_status,
b.VIS_SUC as SUCURSAL_APERTURA,
e.SUC_NOMBRE nombre_sucursal,
c.DES_CODIGO COD_CIERRE_CONTRATO,
c.DES_DESCRIPCION DESC_CIERRE_CONTRATO

 
from  tcap_vista  b 
inner join  tcli_persona   a
on(a.cli_codigo=b.vis_codcli) 
left join tgen_desctabla  c
on(b.VIS_CODTAB=c.DES_CODTAB) and     (b.VIS_CAUCIERR=c.DES_CODIGO)
left join TGEN_SUCURSAL e 
on(b.VIS_SUC=e.SUC_CODIGO)

where 
b.vis_mod=4
and (b.VIS_PRO=1)
and b.vis_tip=1  
and cast(TO_CHAR( b.vis_fechape,'YYYYMMDD') as INT)>=20210923
and cast(TO_CHAR( b.vis_fechape,'YYYYMMDD') as INT)<=&FIN_NUM.
) ;
disconnect from ORACLE;
QUIT;


proc sqL;
create table Stock_Cuenta_corriente as 
select *,
case when SUCURSAL_APERTURA=70 then 1 else 0 end as digital ,
case when SUCURSAL_APERTURA<>70 then 1 else 0 end as PRESENCIAL 
from Stock_Cuenta_corriente
;QUIT;

PROC SQL ;
CONNECT TO ORACLE AS REPORTITF (PATH="REPORITF.WORLD" USER='KMARTINEZ' PASSWORD='kmar2102');
CREATE TABLE CURSE_CC_RETIRA AS
SELECT * FROM CONNECTION TO REPORTITF(
	SELECT TAR.TAR_CAC_NRO_CTT_K NUMERO_CONTRATO,
	TAR.TAR_CAC_NRO_PAN_K NUMERO_TARJETA,
	SUBSTR(PRD.PRD_CAC_NRO_CTT,9) NUMERO_CUENTA_VISTA,
	SOL.SOL_COD_IDE_CLI RUT_CLIENTE,
	PER.PER_CAC_IDE_CLI_DV DV,
	SOL.SOL_FCH_ALT_SOL FECHA_SOLICITUD,
	SOL.SOL_COD_NRO_SOL_K NUMERO_SOLICITUD,
	SOL.SOL_COD_EST_SOL ESTADO
	FROM SFADMI_BCO_SOL SOL
	INNER JOIN SFADMI_ADM.SFADMI_BCO_OFE OFE/* Nuevo */
      ON SOL.SOL_COD_NRO_SOL_K = OFE.OFE_COD_NRO_SOL_K /* Nuevo */
      AND  SUBSTR(OFE.OFE_COD_PRD_OFE_K ,1,2) = '21' /* Nuevo - Codigo de CtaCte*/
      AND OFE.OFE_COD_IND_NGC = 1 /* Nuevo - Indicador de Negociacion*/
      AND OFE.OFE_COD_IND_ALT = 1 /* Nuevo - Referencia a la alta del producto */
	INNER JOIN SFADMI_BCO_TAR TAR
	ON TAR.TAR_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
	INNER JOIN SFADMI_BCO_PRD_SOL PRD
	ON TAR.TAR_COD_NRO_SOL_K = PRD.PRD_COD_NRO_SOL_K
	AND TAR.TAR_COD_TIP_PRD_K = PRD.PRD_COD_TIP_PRD_K
	INNER JOIN SFADMI_BCO_DAT_PER PER
	ON PRD.PRD_COD_NRO_SOL_K = PER.PER_COD_NRO_SOL_K
	AND SOL.SOL_COD_IDE_CLI = PER.PER_COD_IDE_CLI_K
	WHERE
	SUBSTR(TAR.TAR_COD_TIP_PRD_K,1,2) in ('21')
	AND (SOL.SOL_COD_CLL_ACT = 14 OR SOL.SOL_COD_CLL_ANT = 14)
	AND SOL.SOL_COD_CLL_ADM = 2
	and sol.sol_fch_crc_sol between to_date(%str(%')&INI_char.%str(%'),'dd/mm/yyyy') and 
	to_date(%str(%')&fin_char.%str(%'),'dd/mm/yyyy')
	AND EXISTS (SELECT BTC_COD_NRO_SOL_K
				FROM SFADMI_BCO_BTC_SOL
				WHERE BTC_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
				AND BTC_COD_TIP_REG_K = 1
				AND BTC_COD_ETA_K = 102
				AND BTC_COD_EVT_K = 30)
	ORDER BY SOL.SOL_COD_NRO_SOL_K ASC
)A
;QUIT;


proc sql;
create table Stock_Cuenta_corriente as 
select a.*,
max( case when b.NUMERO_CUENTA_VISTA is not null then 1 else 0 end ) as curse_digital,
max(case when b.NUMERO_CUENTA_VISTA  and b.estado in (8,9,11,50) then 1 else 0 end ) as estado_curse
from Stock_Cuenta_corriente as a 
left join CURSE_CC_RETIRA as b
on(a.cuenta=input(b.NUMERO_CUENTA_VISTA,best.))
group by a.cuenta
;QUIT;

%put==================================================================================================;
%put RETIRO HISTORICO;
%put==================================================================================================;

PROC SQL ;
CONNECT TO ORACLE AS CAMPANAS (PATH="REPORITF.WORLD" USER='KMARTINEZ' PASSWORD='kmar2102');
CREATE TABLE retiro_ctacte AS 
SELECT * FROM CONNECTION TO CAMPANAS(SELECT DISTINCT 
	mae.pcom_cod_ide_cli_k, 
	 TAR.TAR_CAC_NRO_CTT_K NUMERO_CONTRATO,
	DET.PCOM_PAN NUMERO_TARJETA,  
	SUBSTR(PRD.PRD_CAC_NRO_CTT,9) NUMERO_CUENTA,
	SOL.SOL_COD_IDE_CLI RUT_CLIENTE, 
	PER.PER_CAC_IDE_CLI_DV DV, 
	SOL.SOL_FCH_ALT_SOL  FECHA_SOLICITUD,
	SOL.SOL_COD_NRO_SOL_K NUMERO_SOLICITUD, 
	SOL.SOL_COD_EST_SOL ESTADO,
	TRUNC(MAE.PCOM_FCH_K) fecha_retiro, 
	MAE.PCOM_GLS_USR_CRC, 
	DET.PCOM_COC_SUC CODIGO_SUC
	FROM SFADMI_ADM.SFADMI_BCO_SOL SOL
	INNER JOIN SFADMI_ADM.SFADMI_BCO_OFE OFE/* Nuevo */
     ON SOL.SOL_COD_NRO_SOL_K = OFE.OFE_COD_NRO_SOL_K /* Nuevo */
     AND  SUBSTR(OFE.OFE_COD_PRD_OFE_K ,1,2) = '21' /* Nuevo - Codigo de CtaCte*/
     AND OFE.OFE_COD_IND_NGC = 1 /* Nuevo - Indicador de Negociacion*/
     AND OFE.OFE_COD_IND_ALT = 1 /* Nuevo - Referencia a la alta del producto */
	 INNER JOIN SFADMI_ADM.SFADMI_BCO_TAR TAR
	   ON TAR.TAR_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
	INNER JOIN SFADMI_ADM.SFADMI_BCO_PRD_SOL PRD
	   ON TAR.TAR_COD_NRO_SOL_K = PRD.PRD_COD_NRO_SOL_K
	   AND TAR.TAR_COD_TIP_PRD_K = PRD.PRD_COD_TIP_PRD_K
	INNER JOIN SFADMI_ADM.SFADMI_BCO_DAT_PER PER
	   ON PRD.PRD_COD_NRO_SOL_K = PER.PER_COD_NRO_SOL_K
	 AND SOL.SOL_COD_IDE_CLI = PER.PER_COD_IDE_CLI_K
	INNER JOIN FEPCOM_ADM.FEPCOM_MAE_REG_EVT MAE
	 ON sol.SOL_NRO_INN_IDE  = mae.PCOM_COD_IDE_CLI_K
	 AND MAE.PCOM_COD_EVT_K = 257 
	and  mae.PCOM_DESC_DOC = sol.sol_cod_ide_cli 
	INNER JOIN FEPCOM_ADM.fepcom_det_reg_evt DET
	ON mae.PCOM_NRO_SEQ_K = det.PCOM_NRO_SEQ_K and 
	det.PCOM_COD_EVT_K = 257 and 
	(det.PCOM_NRO_CTT = substr(TAR_CAC_NRO_CTT_K,1,4) || '-' || substr(TAR_CAC_NRO_CTT_K,5,4) || '-' || substr(TAR_CAC_NRO_CTT_K,9,12) or 
	det.PCOM_NRO_CTT = substr(TAR_CAC_NRO_CTT_K,9,12))
	WHERE 
	 SUBSTR(TAR.TAR_COD_TIP_PRD_K,1,2) = '21'
	AND (SOL.SOL_COD_CLL_ACT = 14 OR SOL.SOL_COD_CLL_ANT = 14)
	AND SOL.SOL_COD_CLL_ADM = 2
	and sol.sol_fch_crc_sol between to_date(%str(%')23/09/2021%str(%'),'dd/mm/yyyy') and 
	to_date(%str(%')&fin_char.%str(%'),'dd/mm/yyyy')
	AND EXISTS (SELECT BTC_COD_NRO_SOL_K
	            FROM SFADMI_ADM.SFADMI_BCO_BTC_SOL
	            WHERE BTC_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
	            AND BTC_COD_TIP_REG_K = 1
	            AND BTC_COD_ETA_K = 102
	            AND BTC_COD_EVT_K = 30)
	and exists (select t.Cuenta from mpdt009 t where 
				t.cuenta = substr(TAR_CAC_NRO_CTT_K,9,12) and 
				t.codent = substr(TAR_CAC_NRO_CTT_K,1,4) and 
				t.centalta = substr(TAR_CAC_NRO_CTT_K,5,4)
	and t.numbencta = 1 and t.numplastico > 1)
	ORDER BY  SOL.SOL_COD_NRO_SOL_K ASC

)A
;QUIT;


proc sql;
create table Stock_Cuenta_corriente as 
select distinct
a.*,
max(case when b.numero_cuenta is not null and a.estado_curse=1  then 1 
	when a.SUCURSAL_APERTURA<>70 or a.presencial=1 then 1  else 0 end) as retiro_plastico,
max(case when c.rut is not null then 1 else 0 end) as SI_Funcionario
from Stock_Cuenta_corriente as a
left join retiro_ctacte as b
on (a.cuenta=input(b.numero_cuenta,best.))
left join DOTACION as c
on (a.rut=c.rut)
group by a.cuenta,a.rut
;QUIT;


%put--------------------------------------------------------------------------------------------------;
%put [01.2] Marcar GSE;
%put--------------------------------------------------------------------------------------------------;

proc sql;
create table Stock_Cuenta_corriente as 
select 
a.*,
coalesce(b.categoria_gse,'SIN INFO') as GSE_CORP
from Stock_Cuenta_corriente as a 
left join rsepulv.gse_corp as b
on(a.rut=b.rut)
;QUIT;

%put--------------------------------------------------------------------------------------------------;
%put [01.2] SALDO;
%put--------------------------------------------------------------------------------------------------;


PROC SQL ;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );
create table Saldos_Cuenta_corriente  as
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
and (VIS_PRO=1) 
and vis_tip=1  
AND (vis_status='2' or vis_status='9')) b
on(a.ACP_NUMCUE=b.vis_numcue)
where a.acp_pro = 1 and a.acp_tip = 1 
and a.acp_fecha >=  to_date(%str(%')&ini_char.%str(%'),'dd/mm/yyyy')
and a.acp_fecha <= to_date(%str(%')&fin_char.%str(%'),'dd/mm/yyyy')
group by 
a.ACP_FECHA, 
a.ACP_NUMCUE,
b.cli_identifica
) ;
disconnect from ORACLE;
QUIT;



proc sql;
create table Saldos_Cuenta_corriente2 as
select 
a.*,
b.Saldo as Ultimo_Saldo 
from (
select 
ACP_NUMCUE as cuenta,
max(rut) as rut,
sum(case when Saldo>1 then 1 else 0 end) as Nro_Dias_Saldo_mayor_1,
sum(case when Saldo>1 then Saldo else 0 end) as SUM_SALDO_FECHA
from work.Saldos_Cuenta_corriente
group by 
ACP_NUMCUE 
) as a 
left join (
select distinct 
ACP_NUMCUE,
Saldo 
from Saldos_Cuenta_corriente
where CodFecha=(select max(CodFecha) from Saldos_Cuenta_corriente)
) as b 
on (a.cuenta=b.ACP_NUMCUE)

;QUIT;


proc sql;
create table Stock_Cuenta_corriente as 
select distinct 
a.*,
coalesce(Nro_Dias_Saldo_mayor_1,0) as Nro_Dias_Saldo_mayor_1,
coalesce(SUM_SALDO_FECHA,0) as 	SALDO_ACUMULADO,
coalesce(Ultimo_Saldo,0) as Ultimo_Saldo
from Stock_Cuenta_corriente as a 
left join Saldos_Cuenta_corriente2 as b
on(a.cuenta=b.cuenta)
;QUIT;


%put--------------------------------------------------------------------------------------------------;
%put [02.3] Marcar Funcionarios;
%put--------------------------------------------------------------------------------------------------;


proc sql noprint;
select 
max(day(datepart(ACP_FECHA))) as max_dia
into
:max_dia
from Saldos_Cuenta_corriente
;QUIT;

%let max_dia=&max_dia;


%put--------------------------------------------------------------------------------------------------;
%put [03.1] Extraer Movimientos de cc totales;
%put--------------------------------------------------------------------------------------------------;



PROC SQL;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );

create table MOV_CUENTA_corriente2  as
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
WHEN DESCRIPCION IN ('TRANSFERENCIA DESDE CREDITO') AND  SI_ABR<>1 THEN 'Traspaso desde LCA' 
else 'OTROS ABONOS' 
end else ''
END AS Descripcion_Abono,

CASE 
when tmo_tipotra='D' then 
CASE
WHEN DESCRIPCION IN ('COMPRA NACIONAL CTA CTE') THEN 'Compras Redcompra' 
WHEN DESCRIPCION IN ('COMPRA INTERNACIONAL CTA CTE') THEN 'Compras Internacionales' 
WHEN DESCRIPCION IN ('CARGO POR PEC') THEN 'PEC' 
when DESCRIPCION IN ('GIRO ATM INTERNACIONAL CTA CTE') then 'Giros internacional CTA CTE'
when DESCRIPCION IN ('GIRO ATM NACIONAL CTA CTE') then 'Giros ATM CTA CTE'
WHEN DESCRIPCION IN ('GIRO POR CAJA') THEN 'Giros Caja'
WHEN DESCRIPCION IN ('TRANSFERENCIA A OTROS BANCOS') THEN 'TEF emitidas Otros Bancos'
WHEN DESCRIPCION IN ('PAGO TARJETA DE CREDITO') THEN 'Pago de Tarjeta' 
WHEN DESCRIPCION IN ('A CUENTA BANCO RIPLEY','POR TRASPASO A CUENTA')  THEN 'Pago LCA'
WHEN  DESCRIPCION IN ('COSTO DE MANTENCION MENSUAL CTA CTE') then 'Comision planes'
WHEN DESCRIPCION IN ('IVA COSTO DE MANTENCION MENSUAL CTA CTE') then 'IVA Com cta cte'
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
and tmo_codmod=4
and tmo_codpro = 1 
and tmo_codtip = 1 
and tmo_modo = 'N' 
and tmo_val >= 1 /*solo montos mayores a 1 peso (mov de prueba)*/ 

and tmo_fechcon >= to_date(%str(%')&ini_char.%str(%'),'dd/mm/yyyy')
and tmo_fechcon <= to_date(%str(%')&fin_char.%str(%'),'dd/mm/yyyy')
/*FINAL: QUERY DESDE OPERACIONES*/ 
)  C1  
left join ( 

SELECT distinct cli_identifica ,vis_numcue  
from tcli_persona /*MAESTRA DE CLIENTES BANCO*/ 
,tcap_vista /*SALDOS CUENTAS VISTAS */ 
where cli_codigo=vis_codcli 
and vis_mod=4/*cuenta vista, CUENTA */ 
and (VIS_PRO=1/*CC*/  ) 
and vis_tip=1  /*persona no juridica*/ 
)  C2 

on (c1.tmo_numcue=c2.vis_numcue) 

) ;
disconnect from ORACLE;
QUIT;






%put==================================================================================================;
%put [06] Comenzar a Generar Salidas de cara al panel de cuenta corriente;
%put==================================================================================================;

proc sql;
delete * 
from &libreria..RESUMEN_CTACTE_MARCAJE 
where periodo=&periodo.
;QUIT;

proc sql;
insert into &libreria..RESUMEN_CTACTE_MARCAJE  
select distinct
&periodo. as periodo,
a.*,
max(case when b.cuenta is not null then 1 else 0 end) as CLI_MOV, /*002.02*/
max(case when b.cuenta is not null and b.tipo_movimiento='CARGO' then 1 else 0 end) as CLI_CARGO, /*002.03*/
max(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Compras Internacionales','Compras Redcompra') 
then 1 else 0 end) as CLI_COMPRA, /*002.04*/

max(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Compras Redcompra') 
then 1 else 0 end) as CLI_COMPRA_REDCOMPRA, /*002.05*/

max(case when b.cuenta is not null and 
b.Descripcion_Cargo = 'Compras Redcompra' and b.COMPRA_RIPLEY = 'COMPRA_RIPLEY'
then 1 else 0 end) as CLI_COMPRA_REDCOMPRA_TDA, /*002.06*/

max(case when b.cuenta is not null and 
b.Descripcion_Cargo = 'Compras Redcompra' and b.COMPRA_RIPLEY <> 'COMPRA_RIPLEY'
then 1 else 0 end) as CLI_COMPRA_REDCOMPRA_NOTDA, /*002.07*/

max(case when b.cuenta is not null and 
b.Descripcion_Cargo = 'Compras Internacionales'
then 1 else 0 end) as CLI_COMPRA_INTERNACIONAL, /*002.08*/

max(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Giros Caja','Giros internacional CTA CTE','Giros ATM CTA CTE')
then 1 else 0 end) as CLI_GIROS, /*002.09*/

max(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('TEF emitidas Otros Bancos')
then 1 else 0 end) as CLI_TEF, /*002.10*/

max(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Pago de Tarjeta','Pago LCA')
then 1 else 0 end) as CLI_CON_PAGOS, /*002.11*/

max(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Giro Internacional','Giros internacional CTA CTE')
then 1 else 0 end) as CLI_GIRO_INTERNACIONAL, /*002.12*/

max(case when b.cuenta is not null and 
b.tipo_movimiento='ABONO'
then 1 else 0 end) as CLI_ABONO, /*002.13*/

max(case when b.cuenta is not null and 
b.Descripcion_Abono in ('Depósitos en Efectivo')
then 1 else 0 end) as CLI_DEPOSITO_EFECTIVO, /*002.14*/

max(case when b.cuenta is not null and 
b.Descripcion_Abono in ('Depósitos con Documento')
then 1 else 0 end) as CLI_DEPOSITO_DOCUMENTO, /*002.15*/

max(case when b.cuenta is not null and 
b.Descripcion_Abono in ('TEF Recibidas')
then 1 else 0 end) as CLI_TEF_RECIBIDA, /*002.16*/

max(case when b.cuenta is not null and 
b.Descripcion_Abono in ('Abono de Remuneraciones')
then 1 else 0 end) as CLI_ABR, /*002.17*/

max(case when b.cuenta is not null and 
b.Descripcion_Abono in ('Otros (pago proveedores)')
then 1 else 0 end) as CLI_PAGO_PROVEEDORES, /*002.18*/

max(case when b.cuenta is not null and 
b.Descripcion_Abono in ('Traspaso desde LCA')
then 1 else 0 end) as CLI_TRASPASO_LCA, /*002.19*/

max(case when b.cuenta is not null and 
b.Descripcion_Abono in ('Avance desde Tarjeta Ripley')
then 1 else 0 end) as CLI_AV_TAR_RIPLEY, /*002.20*/

max(case when b.cuenta is not null and 
b.Descripcion_Abono in ('OTROS ABONOS')
then 1 else 0 end) as CLI_otros_abonos,/*002.21*/

case when 
sum(case when 
b.GLS_TRANSAC='ABONO'
and b.Descripcion_Abono NOT IN ('Traspaso desde LCA','Abono de Remuneraciones','Avance desde Tarjeta Ripley')
and b.SI_ABR=0 then monto end)>=500000 
then 1 else 0 end as CLI_abono_500k,/*004.02*/

max(case when b.cuenta is not null and 
b.SI_ABR=1
then 1 else 0 end) as CLI_ABR_UNICO,/*004.03*/

max(case when b.cuenta is not null and 
a.Nro_Dias_Saldo_mayor_1>0
then 1 else 0 end) as CLI_SALDO_1,/*006.02*/

max(case when b.cuenta is not null and 
a.Ultimo_Saldo>1
then 1 else 0 end) as CLI_SALDO_EOP_1,/*006.03*/


sum(case when b.cuenta is not null and 
b.TIPO_MOVIMIENTO='CARGO'
then b.MONTO else 0 end) as MTO_CARGO,/*008.02*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Compras Redcompra','Compras Internacionales','PEC')
then b.MONTO else 0 end) as MTO_COMPRAS,/*008.03*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Compras Redcompra')
then b.MONTO else 0 end) as MTO_COMPRAS_redcompra,/*008.04*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Compras Redcompra') and b.COMPRA_RIPLEY='COMPRA_RIPLEY'
then b.MONTO else 0 end) as MTO_COMPRAS_red_TDA,/*008.05*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Compras Redcompra') and b.COMPRA_RIPLEY<>'COMPRA_RIPLEY'
then b.MONTO else 0 end) as MTO_COMPRAS_red_NOTDA,/*008.06*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Compras Internacionales')
then b.MONTO else 0 end) as MTO_COMPRAS_INTERNACIONAL,/*008.07*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('PEC')
then b.MONTO else 0 end) as MTO_PEC,/*008.08*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Giros Caja','Giros internacional CTA CTE','Giros ATM CTA CTE')
then b.MONTO else 0 end) as MTO_GIROS,/*008.09*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Giros ATM CTA CTE')
then b.MONTO else 0 end) as MTO_ATM,/*008.10*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Giros Caja')
then b.MONTO else 0 end) as MTO_GIRO_CAJA,/*008.11*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Giros internacional CTA CTE')
then b.MONTO else 0 end) as MTO_GIRO_INTERNACIONAL,/*008.12*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('TEF emitidas Otros Bancos')
then b.MONTO else 0 end) as MTO_TEF_EMITIDA,/*008.13*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('TEF emitidas Otros Bancos')
then b.MONTO else 0 end) as MTO_TEF_OTROS_BANCOS,/*008.14*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Pago de Tarjeta','Pago LCA')
then b.MONTO else 0 end) as MTO_PAGOS,/*008.15*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Pago de Tarjeta')
then b.MONTO else 0 end) as MTO_PAGO_TARJETA,/*008.16*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Pago LCA')
then b.MONTO else 0 end) as MTO_PAGO_LCA,/*008.17*/

sum(case when b.cuenta is not null and 
b.Descripcion in ('COSTO DE MANTENCION MENSUAL CTA CTE')
then b.MONTO else 0 end) as MTO_COSTO_MANTENCION,/*008.18*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('OTROS CARGOS')
then b.MONTO else 0 end) as MTO_OTROS_CARGOS,/*008.19*/

sum(case when b.cuenta is not null and 
b.TIPO_MOVIMIENTO='ABONO'
then b.MONTO else 0 end) as MTO_ABONOS,/*008.20*/

sum(case when b.cuenta is not null and 
b.Descripcion_Abono='Depósitos en Efectivo'
then b.MONTO else 0 end) as MTO_deposito_efectivo,/*008.21*/

sum(case when b.cuenta is not null and 
b.Descripcion_Abono='Depósitos con Documento'
then b.MONTO else 0 end) as MTO_deposito_documento,/*008.22*/

sum(case when b.cuenta is not null and 
b.Descripcion_Abono='TEF Recibidas'
then b.MONTO else 0 end) as MTO_TEF_RECIBIDA,/*008.23*/

sum(case when b.cuenta is not null and 
b.Descripcion_Abono='Abono de Remuneraciones'
then b.MONTO else 0 end) as MTO_abono_remuneracion,/*008.24*/

sum(case when b.cuenta is not null and 
b.Descripcion_Abono='Otros (pago proveedores)'
then b.MONTO else 0 end) as MTO_pagos_proveedores,/*008.25*/

sum(case when b.cuenta is not null and 
b.Descripcion_Abono='Traspaso desde LCA'
then b.MONTO else 0 end) as MTO_traspaso_lca,/*008.26*/

sum(case when b.cuenta is not null and 
b.Descripcion_Abono='Avance desde Tarjeta Ripley'
then b.MONTO else 0 end) as MTO_AV_TR_RIPLEY,/*008.27*/

sum(case when b.cuenta is not null and 
b.Descripcion_Abono='OTROS ABONOS'
then b.MONTO else 0 end) as MTO_OTROS_ABONOS,/*008.28*/

sum(case when b.cuenta is not null and 
b.TIPO_MOVIMIENTO='CARGO'
then 1 else 0 end) as TRX_CARGO,/*009.02*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Compras Redcompra','Compras Internacionales','PEC')
then 1 else 0 end) as TRX_COMPRAS,/*009.03*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Compras Redcompra')
then 1 else 0 end) as TRX_COMPRAS_redcompra,/*009.04*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Compras Redcompra') and b.COMPRA_RIPLEY='COMPRA_RIPLEY'
then 1 else 0 end) as TRX_COMPRAS_red_TDA,/*009.05*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Compras Redcompra') and b.COMPRA_RIPLEY<>'COMPRA_RIPLEY'
then 1 else 0 end) as TRX_COMPRAS_red_NOTDA,/*009.06*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Compras Internacionales')
then 1 else 0 end) as TRX_COMPRAS_INTERNACIONAL,/*009.07*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('PEC')
then 1 else 0 end) as TRX_PEC,/*009.08*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Giros Caja','Giros internacional CTA CTE','Giros ATM CTA CTE')
then 1 else 0 end) as TRX_GIROS,/*009.09*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Giros ATM CTA CTE')
then 1 else 0 end) as TRX_ATM,/*009.10*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Giros Caja')
then 1 else 0 end) as TRX_GIRO_CAJA,/*009.11*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Giros internacional CTA CTE')
then 1 else 0 end) as TRX_GIRO_INTERNACIONAL,/*009.12*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('TEF emitidas Otros Bancos')
then 1 else 0 end) as TRX_TEF_EMITIDA,/*009.13*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('TEF emitidas Otros Bancos')
then 1 else 0 end) as TRX_TEF_OTROS_BANCOS,/*009.14*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Pago de Tarjeta','Pago LCA')
then 1 else 0 end) as TRX_PAGOS,/*009.15*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Pago de Tarjeta')
then 1 else 0 end) as TRX_PAGO_TARJETA,/*009.16*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('Pago LCA')
then 1 else 0 end) as TRX_PAGO_LCA,/*009.17*/

sum(case when b.cuenta is not null and 
b.Descripcion in ('COSTO DE MANTENCION MENSUAL CTA CTE')
then 1 else 0 end) as TRX_COSTO_MANTENCION,/*009.18*/

sum(case when b.cuenta is not null and 
b.Descripcion_Cargo in ('OTROS CARGOS')
then 1 else 0 end) as TRX_OTROS_CARGOS,/*009.19*/

sum(case when b.cuenta is not null and 
b.TIPO_MOVIMIENTO='ABONO'
then 1 else 0 end) as TRX_ABONOS,/*009.20*/

sum(case when b.cuenta is not null and 
b.Descripcion_Abono='Depósitos en Efectivo'
then 1 else 0 end) as TRX_deposito_efectivo,/*009.21*/

sum(case when b.cuenta is not null and 
b.Descripcion_Abono='Depósitos con Documento'
then 1 else 0 end) as TRX_deposito_documento,/*009.22*/

sum(case when b.cuenta is not null and 
b.Descripcion_Abono='TEF Recibidas'
then 1 else 0 end) as TRX_TEF_RECIBIDA,/*009.23*/

sum(case when b.cuenta is not null and 
b.Descripcion_Abono='Abono de Remuneraciones'
then 1 else 0 end) as TRX_abono_remuneracion,/*009.24*/

sum(case when b.cuenta is not null and 
b.Descripcion_Abono='Otros (pago proveedores)'
then 1 else 0 end) as TRX_pagos_proveedores,/*009.25*/

sum(case when b.cuenta is not null and 
b.Descripcion_Abono='Traspaso desde LCA'
then 1 else 0 end) as TRX_traspaso_lca,/*009.26*/

sum(case when b.cuenta is not null and 
b.Descripcion_Abono='Avance desde Tarjeta Ripley'
then 1 else 0 end) as TRX_AV_TR_RIPLEY,/*009.27*/

sum(case when b.cuenta is not null and 
b.Descripcion_Abono='OTROS ABONOS'
then 1 else 0 end) as TRX_OTROS_ABONOS/*009.28*/


from Stock_Cuenta_corriente as a 
left join MOV_CUENTA_corriente2 as b
on(a.cuenta=b.cuenta)
group by a.cuenta
;QUIT;


%put--------------------------------------------------------------------------------------------------;
%put [05.1] resumen;
%put--------------------------------------------------------------------------------------------------;



%macro agrupado_data(libreria,n,DIGITAL,PRESENCIAL,FUNCIONARIO,I);



DATA _null_;
per = put(intnx('month',today(),-&n.,'end'), yymmn6.);
call symput("periodo",per);

run;
%put &periodo;


proc sql;
create table Salida_Panel_Ctacte_&I. as 
/*Bloque1: Stock*/
select 
'001.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'001.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Stock' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'001.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'Stock CC Inicio de Periodo' as Categoria,
count(case when floor(FECHA_APERTURA/100)<&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>=&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'001.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'Captacion' as Categoria,
count(case when floor(FECHA_APERTURA/100)=&periodo. then cuenta end) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'001.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cierre' as Categoria,
count(case when floor(FECHA_CIERRE/100)=&periodo. then cuenta end) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'001.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'Stock CC Final de periodo' as Categoria,
count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'001.06' as Nro_Fila,
'Clientes Totales' as Observacion,
'Tasa de cierre' as Categoria,
count(case when floor(FECHA_CIERRE/100)=&periodo. then cuenta end)/
count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end )as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

/*Bloque2: Informacion de uso CC*/
select 
'002.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'002.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Informacion de uso CC' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'002.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de Cuentas con Movimientos cargos o abonos' as Categoria,
sum(cli_mov) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'002.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de Cuentas con Cargos' as Categoria,
sum(CLI_CARGO) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'002.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con compras' as Categoria,
sum(CLI_COMPRA) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'002.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con compras redcompra' as Categoria,
sum(CLI_COMPRA_REDCOMPRA) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'002.06' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con compras redcompra tienda' as Categoria,
sum(cli_compra_redcompra_tda) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'002.07' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con compras redcompra no tienda' as Categoria,
sum(cli_compra_redcompra_notda) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'002.08' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con compras internacionales' as Categoria,
sum(CLI_COMPRA_INTERNACIONAL) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'002.09' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con Giros' as Categoria,
sum(cli_GIROS) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'002.10' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con TEF' as Categoria,
sum(CLI_TEF) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'002.11' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con Pago' as Categoria,
sum(cli_con_pagos) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'002.12' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con uso Internacional' as Categoria,
sum(cli_giro_internacional) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'002.13' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Cuentas con  Abonos' as Categoria,
sum(cli_abono) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'002.14' as Nro_Fila,
'Clientes Totales' as Observacion,
'Depósitos en Efectivo' as Categoria,
sum(cli_deposito_efectivo) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'002.15' as Nro_Fila,
'Clientes Totales' as Observacion,
'Depósitos con Documento' as Categoria,
sum(cli_deposito_documento) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'002.16' as Nro_Fila,
'Clientes Totales' as Observacion,
'TEF Recibidas' as Categoria,
sum(cli_tef_recibida) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'002.17' as Nro_Fila,
'Clientes Totales' as Observacion,
'Abono de Remuneraciones' as Categoria,
sum(cli_abr) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'002.18' as Nro_Fila,
'Clientes Totales' as Observacion,
'Otros (pago proveedores)' as Categoria,
sum(cli_pago_proveedores) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'002.19' as Nro_Fila,
'Clientes Totales' as Observacion,
'Traspaso desde LCA' as Categoria,
sum(cli_traspaso_lca) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'002.20' as Nro_Fila,
'Clientes Totales' as Observacion,
'Avance desde Tarjeta Ripley' as Categoria,
sum(cli_av_tar_ripley) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
 
outer union corr

select 
'002.21' as Nro_Fila,
'Clientes Totales' as Observacion,
'OTROS ABONOS' as Categoria,
sum(cli_otros_abonos) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

/*Bloque3: Informacion de uso CC %*/
select 
'003.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'003.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Informacion de uso CC %' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'003.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'% de Cuentas con movimiento o abonos' as Categoria,
 sum(cli_mov)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'003.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'% de Cuentas con Cargos' as Categoria,
 sum(cli_CARGO)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'003.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con compras' as Categoria,
 sum(cli_Compra)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'003.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con compras redcompra' as Categoria,
 sum(cli_compra_redcompra)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO. 

outer union corr

select 
'003.06' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con compras redcompra tienda' as Categoria,
 sum(cli_compra_redcompra_tda)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO. 

outer union corr

select 
'003.07' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con compras redcompra no tienda' as Categoria,
 sum(cli_compra_redcompra_notda)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'003.08' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con compras internacionales' as Categoria,
 sum(cli_compra_internacional)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'003.09' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con Giros' as Categoria,
 sum(cli_giros)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'003.10' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con TEF' as Categoria,
 sum(cli_tef)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'003.11' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con uso Internacional' as Categoria,
 sum(cli_giro_internacional)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'003.12' as Nro_Fila,
'Clientes Totales' as Observacion,
'% Cuentas con Abonos' as Categoria,
 sum(cli_abono)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'003.13' as Nro_Fila,
'Clientes Totales' as Observacion,
'Depósitos en Efectivo' as Categoria,
 sum(cli_deposito_efectivo)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'003.14' as Nro_Fila,
'Clientes Totales' as Observacion,
'Depósitos con Documento' as Categoria,
 sum(cli_deposito_documento)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'003.15' as Nro_Fila,
'Clientes Totales' as Observacion,
'TEF Recibidas' as Categoria,
 sum(cli_tef_recibida)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'003.16' as Nro_Fila,
'Clientes Totales' as Observacion,
'Abono de Remuneraciones' as Categoria,
 sum(cli_abr)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'003.17' as Nro_Fila,
'Clientes Totales' as Observacion,
'Otros (pago proveedores)' as Categoria,
 sum(cli_pago_proveedores)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'003.18' as Nro_Fila,
'Clientes Totales' as Observacion,
'Traspaso desde LCA' as Categoria,
 sum(cli_traspaso_lca)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'003.19' as Nro_Fila,
'Clientes Totales' as Observacion,
'Avance desde Tarjeta Ripley' as Categoria,
 sum(cli_av_tar_ripley)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'003.20' as Nro_Fila,
'Clientes Totales' as Observacion,
'OTROS ABONOS' as Categoria,
 sum(cli_otros_abonos)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

/*Bloque4: Informacion de ABR*/
select 
'004.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'004.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Informacion de ABR' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'004.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de Cuentas Distintas Total Abonos >= $500.000' as Categoria,
sum(cli_abono_500k) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'004.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de Cuentas Distintas con ABR' as Categoria,
sum(cli_abr_unico) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'004.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'% de ABR vigentes' as Categoria,
sum(cli_abr_unico)/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.



outer union corr

select 
'004.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de ABR suscritos de los Captados' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'004.06' as Nro_Fila,
'Clientes Totales' as Observacion,
'Tasa de cruce de ABR en Captacion' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'004.07' as Nro_Fila,
'Clientes Totales' as Observacion,
'% de ABR con Cargo' as Categoria,
sum(cli_abr_unico)/sum(cli_cargo) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

/*Bloque5: Informacion de uso Cc/por cuenta*/
select 
'005.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'005.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Informacion de uso CC/por cuenta' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'005.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de movimiento por cuenta cargo y abono' as Categoria,
(sum(trx_cargo)+sum(trx_abonos))/sum(cli_mov) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'005.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de cargos por cuenta' as Categoria,
sum(trx_cargo)/sum(cli_cargo) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'005.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de compras por cuenta' as Categoria,
sum(trx_compras)/sum(cli_compra) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'005.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Cuentas con compra redcompra' as Categoria,
sum(trx_compras_redcompra)/sum(cli_compra_redcompra) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'005.06' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Cuentas con compras  redcompra tienda' as Categoria,
sum(trx_compras_red_tda)/sum(cli_compra_redcompra_tda) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'005.07' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Cuentas con compras  redcompra no tienda' as Categoria,
sum(trx_compras_red_notda)/sum(cli_compra_redcompra_notda) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'005.08' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Cuentas con compras Internacionales' as Categoria,
sum(trx_compras_internacional)/sum(cli_compra_internacional) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'005.09' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de Giros por cuenta' as Categoria,
sum(trx_giros)/sum(cli_giros) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'005.10' as Nro_Fila,
'Clientes Totales' as Observacion,
'# de TEF por cuenta' as Categoria,
(sum(trx_tef_otros_bancos))/sum(cli_tef) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'005.11' as Nro_Fila,
'Clientes Totales' as Observacion,
'# uso internacional por cuenta' as Categoria,
sum(trx_giro_internacional)/sum(cli_giro_internacional) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'005.12' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Abonos por cuenta' as Categoria,
sum(trx_abonos)/sum(cli_abono) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'005.13' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Depósitos en Efectivo' as Categoria,
sum(trx_deposito_efectivo)/sum(cli_deposito_efectivo) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'005.14' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Depósitos con Documento' as Categoria,
sum(trx_deposito_Documento)/sum(cli_deposito_Documento) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'005.15' as Nro_Fila,
'Clientes Totales' as Observacion,
'# TEF Recibidas' as Categoria,
sum(trx_TEF_Recibida)/sum(cli_TEF_Recibida) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'005.16' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Abono de Remuneraciones' as Categoria,
sum(trx_abono_remuneracion)/sum(cli_abr) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'005.17' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Otros (pago proveedores)' as Categoria,
sum(trx_pagos_proveedores)/sum(cli_pago_proveedores) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'005.18' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Traspaso desde LCA' as Categoria,
sum(trx_traspaso_lca)/sum(cli_traspaso_lca) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'005.19' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Avance desde Tarjeta Ripley' as Categoria,
sum(trx_av_tr_ripley)/sum(cli_av_tar_ripley) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.



outer union corr

/*Bloque6: Informacion de Saldo*/
select 
'006.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.



outer union corr

select 
'006.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Informacion de Saldo' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'006.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con Saldo >$1' as Categoria,
count( case when floor(fecha_apertura/100)<=&periodo. and nro_dias_saldo_mayor_1>0 then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

/*and ultimo_saldo>1*/

outer union corr

select 
'006.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cuentas con Saldo >$1 EOP' as Categoria,
count( case when floor(fecha_apertura/100)<=&periodo. and ultimo_saldo>1 then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'006.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'Saldo Total Promedio Mes (MM$)' as Categoria,
sum(case when nro_dias_saldo_mayor_1>0 and floor(fecha_apertura/100)<=&periodo. then ultimo_saldo else 0 end)
/count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) and nro_dias_saldo_mayor_1>0 then cuenta end ) as Valor /*sum(SUM_SALDO_FECHA/&max_dia.)/1000000*/ 
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'006.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'Saldo Total EOP (MM$)' as Categoria,
sum(case when floor(fecha_apertura/100)<=&periodo. then ultimo_saldo else 0 end)/1000000 as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'006.06' as Nro_Fila,
'Clientes Totales' as Observacion,
'Saldo Promedio por cuenta Activa ($)' as Categoria,
sum(case when floor(fecha_apertura/100)<=&periodo. and cli_mov=1 then ultimo_saldo else 0 end)
/sum(cli_mov) AS VALOR
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

/*AND NRO_DIAS_SALDO_MAYOR_1>0*/

outer union corr

select 
'006.07' as Nro_Fila,
'Clientes Totales' as Observacion,
'Numero de Cuentas Activas' as Categoria,
sum(cli_mov) AS VALOR
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
/*
AND NRO_DIAS_SALDO_MAYOR_1>0*/

outer union corr

select 
'006.08' as Nro_Fila,
'Clientes Totales' as Observacion,
'Suma de Saldo por cuenta Activa ($)' as Categoria,
sum(case when floor(fecha_apertura/100)<=&periodo. and cli_mov=1 then ultimo_saldo else 0 end) AS VALOR
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

/*AND NRO_DIAS_SALDO_MAYOR_1>0*/

outer union corr

/*Bloque7: Informacion de Saldo %*/
select 
'007.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'007.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Informacion de Saldo %' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'007.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'% de Cuentas con Saldo' as Categoria,
count( case when floor(fecha_apertura/100)<=&periodo. and nro_dias_saldo_mayor_1>0 then cuenta end )/
count(case when floor(FECHA_APERTURA/100)<=&periodo.	
and (FECHA_CIERRE is null or floor(FECHA_CIERRE/100)>&periodo.) then cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

/*Bloque8: Movimientos ($)*/
select 
'008.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'008.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Movimientos ($)' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'008.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cargos' as Categoria,
sum(mto_cargo) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'008.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras' as Categoria,
sum(mto_compras) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'008.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras Redcompra' as Categoria,
sum(mto_compras_redcompra) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'008.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras  Redcompra Tienda' as Categoria,
sum(mto_compras_red_tda) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'008.06' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras Redcompra no Tienda' as Categoria,
sum(mto_compras_red_notda) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'008.07' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras Internacionales' as Categoria,
sum(mto_compras_internacional) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'008.08' as Nro_Fila,
'Clientes Totales' as Observacion,
'PEC' as Categoria,
sum(mto_pec) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'008.09' as Nro_Fila,
'Clientes Totales' as Observacion,
'Giros' as Categoria,
sum(mto_giros) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'008.10' as Nro_Fila,
'Clientes Totales' as Observacion,
'ATM' as Categoria,
sum(mto_atm) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'008.11' as Nro_Fila,
'Clientes Totales' as Observacion,
'Caja' as Categoria,
sum(mto_giro_caja) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'008.12' as Nro_Fila,
'Clientes Totales' as Observacion,
'Internacional' as Categoria,
sum(mto_giro_internacional) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'008.13' as Nro_Fila,
'Clientes Totales' as Observacion,
'TEF emitidas' as Categoria,
sum(mto_tef_emitida) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'008.14' as Nro_Fila,
'Clientes Totales' as Observacion,
'Otros Bancos' as Categoria,
sum(mto_tef_otros_bancos) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'008.15' as Nro_Fila,
'Clientes Totales' as Observacion,
'Pagos' as Categoria,
sum(mto_pagos) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'008.16' as Nro_Fila,
'Clientes Totales' as Observacion,
'Pago de Tarjeta' as Categoria,
sum(mto_pago_tarjeta) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'008.17' as Nro_Fila,
'Clientes Totales' as Observacion,
'Pago LCA' as Categoria,
sum(mto_pago_lca) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'008.18' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cobro Mantención Cuenta Vista' as Categoria,
sum(mto_costo_mantencion) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr
 
select 
'008.19' as Nro_Fila,
'Clientes Totales' as Observacion,
'OTROS CARGOS' as Categoria,
sum(mto_otros_cargos) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr
 
select 
'008.20' as Nro_Fila,
'Clientes Totales' as Observacion,
'Abonos' as Categoria,
sum(mto_abonos) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
 
outer union corr
 
select 
'008.21' as Nro_Fila,
'Clientes Totales' as Observacion,
'Depósitos en Efectivo' as Categoria,
sum(mto_deposito_efectivo) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
 
outer union corr
 
select 
'008.22' as Nro_Fila,
'Clientes Totales' as Observacion,
'Depósitos con Documento' as Categoria,
sum(mto_deposito_Documento) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
 
outer union corr
 
select 
'008.23' as Nro_Fila,
'Clientes Totales' as Observacion,
'TEF Recibidas' as Categoria,
sum(mto_tef_recibida) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
 
outer union corr
 
select 
'008.24' as Nro_Fila,
'Clientes Totales' as Observacion,
'Abono de Remuneraciones' as Categoria,
sum(mto_abono_remuneracion) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr
 
select 
'008.25' as Nro_Fila,
'Clientes Totales' as Observacion,
'Otros (pago proveedores)' as Categoria,
sum(mto_pagos_proveedores) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
 
outer union corr
 
select 
'008.26' as Nro_Fila,
'Clientes Totales' as Observacion,
'Traspaso desde LCA' as Categoria,
sum(mto_traspaso_lca) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
 
outer union corr
 
select 
'008.27' as Nro_Fila,
'Clientes Totales' as Observacion,
'Avance desde Tarjeta Ripley' as Categoria,
sum(mto_av_tr_ripley) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
 
outer union corr
 
select 
'008.28' as Nro_Fila,
'Clientes Totales' as Observacion,
'OTROS ABONOS' as Categoria,
sum(mto_otros_abonos) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr
 
/*Bloque9: Movimientos (Tx)*/
select 
'009.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'009.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Movimientos (#)' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'009.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'Movimientos (#) (Cargos y Abonos)' as Categoria,
sum(trx_cargo)+ sum(trx_abonos) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'009.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cargos' as Categoria,
sum(trx_cargo) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'009.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras' as Categoria,
sum(trx_compras) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'009.05' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras Redcompra' as Categoria,
sum(trx_compras_Redcompra) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'009.06' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras  Redcompra Tienda' as Categoria,
sum(trx_compras_Red_tda) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'009.07' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras Redcompra no Tienda' as Categoria,
sum(trx_compras_Red_notda) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'009.08' as Nro_Fila,
'Clientes Totales' as Observacion,
'Compras Internacionales' as Categoria,
sum(trx_compras_internacional)  as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'009.09' as Nro_Fila,
'Clientes Totales' as Observacion,
'PEC' as Categoria,
sum(trx_pec)  as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'009.10' as Nro_Fila,
'Clientes Totales' as Observacion,
'Giros' as Categoria,
sum(trx_giros)  as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'009.11' as Nro_Fila,
'Clientes Totales' as Observacion,
'ATM' as Categoria,
sum(trx_atm) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'009.12' as Nro_Fila,
'Clientes Totales' as Observacion,
'Caja' as Categoria,
sum(trx_giro_caja) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'009.13' as Nro_Fila,
'Clientes Totales' as Observacion,
'Internacional' as Categoria,
sum(trx_giro_Internacional) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'009.14' as Nro_Fila,
'Clientes Totales' as Observacion,
'TEF emitidas' as Categoria,
sum(trx_TEF_emitida) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'009.15' as Nro_Fila,
'Clientes Totales' as Observacion,
'Otros Bancos' as Categoria,
sum(trx_TEF_Otros_Bancos) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'009.16' as Nro_Fila,
'Clientes Totales' as Observacion,
'Pagos' as Categoria,
sum(trx_Pagos) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'009.17' as Nro_Fila,
'Clientes Totales' as Observacion,
'Pago de Tarjeta' as Categoria,
sum(trx_Pago_Tarjeta)  as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
outer union corr

select 
'009.18' as Nro_Fila,
'Clientes Totales' as Observacion,
'Pago LCA' as Categoria,
sum(trx_Pago_LCA) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'009.19' as Nro_Fila,
'Clientes Totales' as Observacion,
'Cobro Mantención Cuenta Vista' as Categoria,
sum(trx_costo_mantencion) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


 
outer union corr
 
select 
'009.20' as Nro_Fila,
'Clientes Totales' as Observacion,
'OTROS CARGOS' as Categoria,
sum(trx_OTROS_CARGOS) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr
 
select 
'009.21' as Nro_Fila,
'Clientes Totales' as Observacion,
'Abonos' as Categoria,
sum(trx_Abonos) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
 
outer union corr
 
select 
'009.22' as Nro_Fila,
'Clientes Totales' as Observacion,
'Depósitos en Efectivo' as Categoria,
sum(trx_deposito_efectivo) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
 
outer union corr
 
select 
'009.23' as Nro_Fila,
'Clientes Totales' as Observacion,
'Depósitos con Documento' as Categoria,
sum(trx_deposito_Documento) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
 
outer union corr
 
select 
'009.24' as Nro_Fila,
'Clientes Totales' as Observacion,
'TEF Recibidas' as Categoria,
sum(trx_TEF_Recibida) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
 
outer union corr
 
select 
'009.25' as Nro_Fila,
'Clientes Totales' as Observacion,
'Abono de Remuneraciones' as Categoria,
sum(trx_abono_remuneracion)  as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
 
outer union corr
 
select 
'009.26' as Nro_Fila,
'Clientes Totales' as Observacion,
'Otros (pago proveedores)' as Categoria,
sum(trx_pagos_proveedores)  as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
 
outer union corr
 
select 
'009.27' as Nro_Fila,
'Clientes Totales' as Observacion,
'Traspaso desde LCA' as Categoria,
sum(trx_traspaso_lca)  as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
 
outer union corr
 
select 
'009.28' as Nro_Fila,
'Clientes Totales' as Observacion,
'Avance desde Tarjeta Ripley' as Categoria,
sum(trx_av_tr_ripley)   as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
 
outer union corr
 
select 
'009.29' as Nro_Fila,
'Clientes Totales' as Observacion,
'OTROS ABONOS' as Categoria,
sum(trx_OTROS_ABOnos)  as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'012.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'012.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'Captacion PWA' as Categoria,
sum(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'012.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'Captacion Online' as Categoria,
sum(case when floor(fecha_apertura/100)=&periodo. then digital end) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'012.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'Captacion Presencial' as Categoria,
sum(case when floor(fecha_apertura/100)=&periodo. then presencial end) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.


outer union corr

select 
'013.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'013.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Cuentas con Saldo >$1' as Categoria,
count(case when floor(fecha_apertura/100)<=&periodo. and ultimo_saldo>1 then cuenta end) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.
outer union corr

select 
'013.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Cuentas con Saldo >$1.000' as Categoria,
count(case when floor(fecha_apertura/100)<=&periodo. and ultimo_saldo>1000 then cuenta end) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'013.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Cuentas con Saldo >$100.000' as Categoria,
count(case when floor(fecha_apertura/100)<=&periodo. and ultimo_saldo>100000 then cuenta end)as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'013.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Cuentas con Saldo >$500.000' as Categoria,
count(case when floor(fecha_apertura/100)<=&periodo. and ultimo_saldo>500000 then cuenta end) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'014.00' as Nro_Fila,
'Clientes Totales' as Observacion,
'----------------------' as Categoria,
max(0) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'014.01' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Clientes Retiro Plastico' as Categoria,
sum(case when floor(fecha_apertura/100)=&periodo. then 	retiro_plastico end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'014.02' as Nro_Fila,
'Clientes Totales' as Observacion,
'# Clientes No Retiro Plastico' as Categoria,
count(case when floor(fecha_apertura/100)=&periodo. and retiro_plastico=0 then 	cuenta end ) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'014.03' as Nro_Fila,
'Clientes Totales' as Observacion,
'% Retiro Plastico' as Categoria,
sum(case when floor(fecha_apertura/100)=&periodo. then 	retiro_plastico end ) /count(case when floor(fecha_apertura/100)=&periodo.  then 	cuenta end) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.

outer union corr

select 
'014.04' as Nro_Fila,
'Clientes Totales' as Observacion,
'% Retiro No Plastico' as Categoria,
count(case when floor(fecha_apertura/100)=&periodo. and retiro_plastico=0 then 	cuenta end )/count(case when floor(fecha_apertura/100)=&periodo.  then 	cuenta end) as Valor
from &libreria..RESUMEN_CTACTE_MARCAJE 
where PERIODO=&periodo. 
and DIGITAL>=&digital.
and PRESENCIAL>=&presencial.
and si_FUNCIONARIO>=&FUNCIONARIO.



;QUIT;


%mend agrupado_data;

/*libreria,n,DIGITAL,PRESENCIAL,FUNCIONARIO,I*/

%agrupado_data(&libreria.,&n.,0,0,0,1); /*vista total*/
%agrupado_data(&libreria.,&n.,1,0,0,2); /*vista DIGITAL*/
%agrupado_data(&libreria.,&n.,0,1,0,3); /*vista presencial*/
%agrupado_data(&libreria.,&n.,0,0,1,4); /*vista funcionario*/



proc sql;
create table colapso_final as 
select 
'01.TOTAL' as marcaje,
*
from Salida_Panel_Ctacte_1
outer union corr 
select 
'02.DIGITAL' as marcaje,
*
from Salida_Panel_Ctacte_2
outer union corr 
select 
'03.PRESENCIAL' as marcaje,
*
from Salida_Panel_Ctacte_3
outer union corr 
select 
'04.FUNCIONARIO' as marcaje,
*
from Salida_Panel_Ctacte_4
;QUIT;


%if (%sysfunc(exist(&libreria..PANEL_CTACTE_APERTURAS))) %then %do;
%end;
%else %do;
PROC  SQL;
CREATE TABLE &libreria..PANEL_CTACTE_APERTURAS 
(periodo num,
marcaje char(20),
Nro_Fila char(99),
Observacion char(99),
Categoria char(99),
valor num 
)
;quit;
%end;

proc sql;
delete *
from &libreria..PANEL_CTACTE_APERTURAS
where periodo=&periodo.
;QUIT;


proc sql;
insert into &libreria..PANEL_CTACTE_APERTURAS
select 
&periodo. as periodo,
*
from colapso_final
;QUIT;

proc sql;
create table &libreria..PANEL_CTACTE_APERTURAS as
select 
periodo,
marcaje ,
Nro_Fila ,
Observacion ,
Categoria ,
coalesce(valor,0) as valor
from  &libreria..PANEL_CTACTE_APERTURAS

;quit;

proc datasets library=WORK kill noprint;
run;
quit;

%mend PANEL_CC;

/******************** ENVIO CORREO AUTOMATICO *******************************/

%macro ENVIO_CORREO(N);

data _null_;
	execDVN = compress(input(put(today(),ddmmyy10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;


data _null_;
FILENAME OUTBOX EMAIL
FROM= ("bmartinezg@bancoripley.com")
TO = ("bmartinezg@bancoripley.com","jaburtom@ripley.com","jgunckele@bancoripley.com")
CC = ("rfonsecaa@bancoripley.com","gvallejosa@bancoripley.com","sjaram@bancoripley.com")
SUBJECT= "MAIL_AUTOM: Panel Cuenta Corriente &fechaeDVN."; 
 FILE OUTBOX;
 PUT "Estimados:";
 PUT ;
 put "     Proceso PANEL CTACTE, ejecutado con fecha: &fechaeDVN.  ";   
	PUT;
PUT;
	PUT;
	put 'Saludos.';
	PUT;
	PUT 'Atte.';
	Put 'Benjamin Martinez Garate';
	PUT;
RUN;
FILENAME OUTBOX CLEAR;

%mend ENVIO_CORREO;


%macro ENVIO_CORREO_cierre(N);

data _null_;
	execDVN = compress(input(put(today(),ddmmyy10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;


data _null_;
FILENAME OUTBOX EMAIL
FROM= ("bmartinezg@bancoripley.com")
TO = ("bmartinezg@bancoripley.com","jaburtom@ripley.com","jgunckele@bancoripley.com")
CC = ("rfonsecaa@bancoripley.com","gvallejosa@bancoripley.com","sjaram@bancoripley.com")
SUBJECT= "MAIL_AUTOM: Panel Cuenta Corriente &fechaeDVN."; 
 FILE OUTBOX;
 PUT "Estimados:";
 PUT ;
 put "     Proceso PANEL CTACTE al Cierre, ejecutado con fecha: &fechaeDVN.  ";   
	PUT;
PUT;
	PUT;
	put 'Saludos.';
	PUT;
	PUT 'Atte.';
	Put 'Benjamin Martinez Garate';
	PUT;
RUN;
FILENAME OUTBOX CLEAR;

%mend ENVIO_CORREO_cierre;


%macro ejecutar(A);

DATA _null_;
HOY = day(today());
Call symput("HOY", HOY);
RUN;
%put &HOY;

%if %eval(&HOY.=2) %then %do; /*El cierre se ejecutara el 2 de cada mes*/
%PANEL_CC(&libreria.,1);
%ENVIO_CORREO_cierre(1);

%end;

%else %DO;
%PANEL_CC(&libreria.,0);
%ENVIO_CORREO(0);
%end;

%mend ejecutar;

%ejecutar(A);







