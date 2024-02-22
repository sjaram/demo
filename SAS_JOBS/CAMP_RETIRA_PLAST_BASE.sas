/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	CAMP_RETIRA_PLAST_BASE			 ===============================*/
/* CONTROL DE VERSIONES
/* 2023-02-21 -- v03 -- Benja M. 	-- Actualizacion retira con nueva logica y definiciones 21-02-2023 - add Stock CC
/* 2022-12-13 -- v02 -- David V. 	-- Se agrega código validvarname para server SAS.
/* 2022-12-06 -- v01 -- David V. 	-- Comentarios, versionamiento para server SAS.
/* 2022-12-06 -- v00 -- Benja M. 	-- Versión Original

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/


/* 									QUERY ENTREGADA POR EL EQUIPO TECNICO DE MARCELA BERNALES 									 */
/* 					 	   							RETIRO PLASTICO CC						 									 */
/* 			TOMA UNA CAMADA DE CLIENTES DESDE 23SEPT A LA FECHA Y VE QUIEN DE LOS QUE CURSÓ NO HAN RETIRADO PLASTICO 			 */

%let n=0;
%let libreria=RESULT;
options validvarname=any;

DATA _NULL_;
fec_proceso=put(intnx('day',today(),0,'same'), yymmddn8.);
ini_char = put(intnx('month',today(),-&N.,'begin'),ddmmyy10.);
fin_char = put(intnx('month',today(),-&N.,'same'),ddmmyy10. );

call symput("fec_proceso",fec_proceso);
call symput("fin_char",fin_char);
run;

%put &fec_proceso;
%put &fin_char;


/* CURSES DE TARJETA PARA CUENTA CORRIENTE */
PROC SQL ;
CONNECT TO ORACLE AS REPORTITF (PATH="REPORITF.WORLD" USER='KMARTINEZ' PASSWORD='kmar2102');
CREATE TABLE CURSE_CC AS
SELECT * FROM CONNECTION TO REPORTITF(
	SELECT TAR.TAR_CAC_NRO_CTT_K NUMERO_CONTRATO,
	TAR.TAR_CAC_NRO_PAN_K NUMERO_TARJETA,
	SUBSTR(PRD.PRD_CAC_NRO_CTT,9) NUMERO_CUENTA,
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
	and sol.sol_fch_crc_sol between to_date(%str(%')01/09/2021%str(%'),'dd/mm/yyyy') and 
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


/* LIMPIAR BASE CURSES EN FORMATO TRABAJABLE */
proc sql;
create table base_limpio as 
select distinct 
	NUMERO_CONTRATO,
	NUMERO_TARJETA,
	NUMERO_CUENTA,
	input(RUT_CLIENTE,best.) as rut,
	dv,
	datepart(FECHA_SOLICITUD) format=date9. as FECHA,
	ESTADO
from CURSE_CC
;QUIT;


/* QUERY RETIRO CUENTA CORRIENTE */
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
	 INNER JOIN SFADMI_ADM.SFADMI_BCO_OFE OFE /* Nuevo */
       ON SOL.SOL_COD_NRO_SOL_K = OFE.OFE_COD_NRO_SOL_K /* Nuevo */
       AND  SUBSTR(OFE.OFE_COD_PRD_OFE_K ,1,2) = '21' /* Nuevo - Codigo de CtaCte*/
       AND OFE.OFE_COD_IND_NGC = 1 /* Nuevo - Indicador de Negociacion*/
       AND OFE.OFE_COD_IND_ALT = 1 /* Nuevo -Referencia a la alta del producto */
	   
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
	and sol.sol_fch_crc_sol between to_date(%str(%')01/09/2021%str(%'),'dd/mm/yyyy') and 
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



/* REALIZAR MARCA PARA VER QUIEN RETIRO O NO */
PROC SQL;
create table retiro_cuenta_corriente as
select  distinct
	a.*,
	case when (b.numero_cuenta is not null and a.estado in (8,9,11,50)) then 1 else 0 end as retiro, 
	b.fecha_retiro,
	a.estado

	from base_limpio as a
	left join retiro_ctacte as b
		on (a.NUMERO_CUENTA=b.numero_cuenta)
;QUIT;


%let path_ora      = '(DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SID = ripleyc)))'; 
%let user_ora      = 'RIPLEYC'; 
%let pass_ora      = 'ri99pley';
%let conexion_ora  = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 

PROC SQL  NOERRORSTOP;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );

create table Stock_Cuenta_corriente  as
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
     WHEN b.VIS_PRO=1 THEN 'CUENTA_CORRIENTE'
WHEN b.VIS_PRO=40 THEN 'LCA' END  DESCRIP_PRODUCTO,
CASE WHEN b.vis_status ='9' THEN 'cerrado' 
when b.vis_status ='2' then 'vigente' end as estado_cuenta,
/*c.DES_CODTAB,*/
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
AND (b.vis_status='2' or b.vis_status='9') 
and cast(TO_CHAR( b.vis_fechape,'YYYYMMDD') as INT)>=20210923
) ;
disconnect from ORACLE;

QUIT;

/* SALIDA DE RETIRA CUENTA CORRIENTE */
PROC SQL;
CREATE TABLE SALIDA_RETIRA_CC AS
SELECT 
	NUMERO_CONTRATO,
	NUMERO_TARJETA,
	NUMERO_CUENTA,
	rut,
	DV,
	FECHA,
	year(fecha)*100+month(fecha) as periodo,
	ESTADO,
	retiro
from retiro_cuenta_corriente
where rut in (select rut from Stock_Cuenta_corriente where estado_cuenta='vigente')
;quit;

/* SOLO CLIENTES QUE NO HAN RETIRADO SU TARJETA DENTRO DE UN RANGO DE TIEMPO, PARA QUE LES SALTE EL POPUP */
PROC SQL;
create table &libreria..retira_cc as
select 
rut
from salida_retira_cc
where retiro=0
;QUIT;

/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	FECHA DEL PROCESO  			================================*/
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
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_PPFF';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_2';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFATURA_CAMP';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;	 %put &=DEST_6;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4","&DEST_5","&DEST_6")
CC = ("&DEST_1", "&DEST_2", "&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso CAMP_RETIRA_PLAST_BASE");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "		Proceso CAMP_RETIRA_PLAST_BASE, ejecutado con fecha: &fechaeDVN";  
 PUT "		Base disponible en SAS para generar archivo de campañas: &libreria..retira_cc";  
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 02'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

