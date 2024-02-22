/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================    SPOS_ONBOARDING_3M				 ===============================*/
/* CONTROL DE VERSIONES
/* 2023-06-05 -- v06 -- David V.	-- Corrección a variable periodo para export onboarding_3m to aws.
/* 2023-05-31 -- v05 -- David V.	-- Unificar últimas versiones en conflicto + actualización a export to aws.
/* 2023-02-15 -- v04 -- Karina M.	-- Marca Plan
									-- Actualizacion de query retira plastico cc
/* 2023-01-25 -- v03 -- Esteban P. 	-- Se añade script para credenciales ocultas en conexión a SEGCOM.									 		 
/* 2022-10-25 -- v02 -- David V.	-- Actualizada export a RAW
/* 2022-10-25 -- v01 -- David V.	-- Versionamiento, automatización, export aws.
/* 2022-10-25 -- v00 -- Pedro M.	-- Versión Original

/* INFORMACIÓN: 
Parte 1 del flujo, también conocido proceso como "concreta spos 30 60 90 arreglado v7"
Tiempo de activación promedio en los últimos 3 meses (separado por producto y tipo de producto)
Cantidad de clientes que entran en la app separado por quienes concretan o no en la APP (veamos forma de segmentarlo)
Estos mismos puntos 1 y 2, tenerlo durante la captación del mes de marzo y abril

/* VARIABLE TIEMPO - INICIO */
%let tiempo_inicio= %sysfunc(datetime());

options validvarname=any;

/*==================================================================================================*/
/*==============================    SPOS_ONBOARDING_3M	 ===============================*/

%let libreria=RESULT;

%macro concrecion_3M_REAL(N,libreria);

DATA _null_;
periodo_actual = input(put(intnx('month',today(),-&n.,'begin'),yymmn6. ),$10.) ;
periodo_1 = input(put(intnx('month',today(),-&n.+1,'begin'),yymmn6. ),$10.) ;
periodo_2 = input(put(intnx('month',today(),-&n.+2,'same'),yymmn6. ),$10.) ;
periodo_3 = input(put(intnx('month',today(),-&n.+3,'same'),yymmn6. ),$10.) ;
periodo_4 = input(put(intnx('month',today(),-&n.+4,'same'),yymmn6. ),$10.) ;
periodo_5 = input(put(intnx('month',today(),-&n.+5,'same'),yymmn6. ),$10.) ;
periodo_6 = input(put(intnx('month',today(),-&n.+6,'same'),yymmn6. ),$10.) ;

ini_mes = input(put(intnx('month',today(),-&n.,'begin'),date9. ),$10.) ;
fin_mes = input(put(intnx('month',today(),-&n.,'end'),date9. ),$10.) ;

Call symput("periodo_actual", periodo_actual);
Call symput("periodo_1", periodo_1);
Call symput("periodo_2", periodo_2);
Call symput("periodo_3", periodo_3);
Call symput("periodo_4", periodo_4);
Call symput("periodo_5", periodo_5);
Call symput("periodo_6", periodo_6);
Call symput("dated_ant", dated_ant);
Call symput("ini_mes", ini_mes);
Call symput("fin_mes", fin_mes);
RUN;

%put &periodo_actual;
%put &periodo_1;
%put &periodo_2;
%put &periodo_3;
%put &ini_mes;
%put &fin_mes;
%put &periodo_4;
%put &periodo_5;
%put &periodo_6;

proc sql;
create table captados as
select
rut_cliente as rut,
producto,
fecha,
codent,
centalta,
cuenta,
NRO_SOLICITUD,
ID_OFERTA,
cod_sucursal,
via
from result.capta_salida
where
fecha between "&ini_mes."d and "&fin_mes."d
order by rut_cliente
;QUIT;

proc sql;
create table captados as
select
monotonic() as ind,
*,
year(fecha)*10000+month(fecha)*100+day(fecha) as fecha_numero,
year(intnx("day",fecha,30))*10000+month(intnx("day",fecha,30))*100+day(intnx("day",fecha,30)) as dia_30,
year(intnx("day",fecha,60))*10000+month(intnx("day",fecha,60))*100+day(intnx("day",fecha,60)) as dia_60,
year(intnx("day",fecha,90))*10000+month(intnx("day",fecha,90))*100+day(intnx("day",fecha,90)) as dia_90,
case when producto in ('CUENTA VISTA') then 'CV'
when  producto in ('CUENTA CORRIENTE') then 'CTACTE' else 'TC' end as producto2
from captados
order by rut
;QUIT;

PROC SQL;
CREATE INDEX rut ON WORK.captados (RUT);
QUIT;


%macro recopilar_USOS(periodo,i);

/*SPOS TC*/
%if (%sysfunc(exist(publicin.spos_aut_&periodo.))) %then %do;
PROC SQL ;
create table spos&i as 
SELECT 
a.rut,
a.fecha,
a.hora,
a.codact,
a.venta_tarjeta,
a.Nombre_Comercio
FROM publicin.spos_aut_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)
;quit;
%end;
%else %do;
PROC SQL ;
create table spos&i 
(rut num,
fecha num,
hora char(10),
codact num,
venta_tarjeta num,
Nombre_Comercio char(10)
)
;quit;
%end;

/*TDA TC*/

%if (%sysfunc(exist(publicin.tda_itf_&periodo.))) %then %do;
PROC SQL ;
create table tda&i  as 
SELECT
distinct 
a.rut,
year(a.fecha)*10000+month(a.fecha)*100+day(a.fecha) as fecha
FROM publicin.tda_itf_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)
where a.capital>0
;quit;
%end;
%else %do;
PROC SQL ;
create table tda&i  
(rut num,
fecha num)
;quit;
%end;

/*TDA MCD*/


%if (%sysfunc(exist(publicin.TDA_mcd_&periodo.))) %then %do;
PROC SQL ;
create table TDA_MCD&i as 
SELECT
distinct 
a.rut,
a.fecha
FROM publicin.TDA_mcd_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)
where a.producto='08'
;quit;
%end;
%else %do;
PROC SQL ;
create table TDA_MCD&i 
(rut num,
fecha num)
;quit;
%end;

/*TDA MAESTRO*/


%if (%sysfunc(exist(publicin.TDA_MAESTRO_&periodo.))) %then %do;
PROC SQL ;
create table TDA_MAESTRO&i as 
SELECT
distinct 
a.rut,
a.fecha
FROM publicin.TDA_MAESTRO_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)

;quit;
%end;
%else %do;
PROC SQL ;
create table TDA_MAESTRO&i 
(rut num,
fecha num)
;quit;
%end;

/*SPOS MCD*/

%if (%sysfunc(exist(publicin.spos_mcd_&periodo.))) %then %do;
PROC SQL ;
create table spos_MCD&i as 
SELECT 
a.rut,
a.fecha,
a.hora,
a.codact,
a.venta_tarjeta,
a.Nombre_Comercio
FROM publicin.spos_mcd_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)
where a.producto='08'
;quit;
%end;
%else %do;
PROC SQL ;
create table spos_MCD&i 
(rut num,
fecha num,
hora char(10),
codact num,
venta_tarjeta num,
Nombre_Comercio char(10))
;quit;
%end;

/*spos maestro*/

%if (%sysfunc(exist(publicin.spos_MAESTRO_&periodo.))) %then %do;
PROC SQL ;
create table spos_MAESTRO&i as 
SELECT
 
a.rut,
a.fecha,
a.codact,
a.venta_tarjeta,
a.Nombre_Comercio
FROM publicin.spos_MAESTRO_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)

;quit;
%end;
%else %do;
PROC SQL ;
create table spos_MAESTRO&i 
(rut num,
fecha num,
codact num,
venta_tarjeta num,
Nombre_Comercio char(10))
;quit;
%end;


/*TDA CTACTE*/

%if (%sysfunc(exist(publicin.TDA_CTACTE_&periodo.))) %then %do;
PROC SQL ;
create table TDA_CC&i as 
SELECT
distinct 
a.rut,
a.fecha
FROM publicin.TDA_CTACTE_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)
where a.producto='13'
;quit;
%end;
%else %do;
PROC SQL ;
create table TDA_CC&i 
(rut num,
fecha num)
;quit;
%end;


/*spos ctacte*/

%if (%sysfunc(exist(publicin.SPOS_CTACTE_&periodo.))) %then %do;
PROC SQL ;
create table spos_CC&i as 
SELECT 
a.rut,
a.fecha,
a.hora,
a.codact,
a.venta_tarjeta,
a.Nombre_Comercio
FROM publicin.SPOS_CTACTE_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)
where a.producto='13'
;quit;
%end;
%else %do;
PROC SQL ;
create table spos_CC&i 
(rut num,
fecha num,
hora char(10),
codact num,
venta_tarjeta num,
Nombre_Comercio char(10))
;quit;
%end;


/*logeo_digital*/
%if (%sysfunc(exist(publicin.logeo_int_&periodo.))) %then %do;
PROC SQL ;
create table logeo_int_&i as 
SELECT
distinct 
a.rut,
a.fecha
FROM publicin.logeo_int_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)
where a.DISPOSITIVO in ('DESKTOP','APP' ,'APP_1')
;quit;
%end;
%else %do;
PROC SQL ;
create table logeo_int_&i 
(rut num,
fecha num)
;quit;
%end;


/*epu cobro*/
%if (%sysfunc(exist(publicin.sb_contratoepu_&periodo.))) %then %do;
PROC SQL ;
create table epu&i as 
SELECT
distinct 
a.rut,
year(a.fechacorte)*10000 +month(a.fechacorte)*100+day(a.fechacorte) as fecha
FROM publicin.sb_contratoepu_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)
where a.si_mantencionepu=1
;quit;
%end;
%else %do;
PROC SQL ;
create table epu&i 
(rut num,
fecha num)
;quit;
%end;


/*pago digital*/
%if (%sysfunc(exist(result.PAGOS_DIGITALES_&periodo.))) %then %do;
PROC SQL ;
create table pagos&i as 
SELECT
distinct 
a.rut,
input(compress(a.fecha,'-'),best.) as fecha
FROM result.PAGOS_DIGITALES_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)
where a.TIPO in ('HB_SERV','UNIRED','KIPHU','SANTANDER')
;quit;
%end;
%else %do;
PROC SQL ;
create table pagos&i 
(rut num,
fecha num)
;quit;
%end;


%mend recopilar_USOS;


%recopilar_USOS(&periodo_actual.,1);
%recopilar_USOS(&periodo_1.,2);
%recopilar_USOS(&periodo_2.,3);
%recopilar_USOS(&periodo_3.,4);

%macro retiro_plasticos(n);

DATA _null_;

fin= input(put(intnx('month',today(),-&n.+4,'end'),date9. ),$10.) ;
ini_mes = input(put(intnx('month',today(),-&n.,'begin'),ddmmyy10. ),$10.) ;
fin_mes = input(put(intnx('month',today(),-&n.,'end'),ddmmyy10. ),$10.) ;
Call symput("fin", fin);
Call symput("ini_fisa", ini_mes);
Call symput("fin_fisa", fin_mes);
RUN;


%put &fin;
%put &ini_fisa;
%put &fin_fisa;



PROC SQL ;
CONNECT TO ORACLE AS REPORTITF (PATH="REPORITF.WORLD" USER='KMARTINEZ' PASSWORD='kmar2102');
CREATE TABLE RETIRO_PLASTICO_TC AS 
SELECT * FROM CONNECTION TO REPORTITF(
SELECT sol.sol_nro_inn_ide,
TAR.TAR_CAC_NRO_CTT_K NUMERO_CONTRATO,
TAR.TAR_CAC_NRO_PAN_K NUMERO_TARJETA,
SOL.SOL_COD_IDE_CLI RUT_CLIENTE, 
SOL.SOL_FCH_ALT_SOL FECHA_SOLICITUD,
SOL.SOL_COD_NRO_SOL_K NUMERO_SOLICITUD, 
sol.sol_cod_est_sol ESTADO, 
TRUNC(MAE.PCOM_FCH_K) as fecha_retiro,
MAE.PCOM_GLS_USR_CRC, 
DET.PCOM_COC_SUC CODIGO_SUC
FROM SFADMI_BCO_SOL SOL 
INNER JOIN SFADMI_BCO_TAR TAR
ON TAR.TAR_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K

INNER JOIN FEPCOM_MAE_REG_EVT MAE
ON sol.SOL_NRO_INN_IDE  = mae.PCOM_COD_IDE_CLI_K
AND MAE.PCOM_COD_EVT_K in (15, 80, 230)  
and  mae.PCOM_DESC_DOC = sol.sol_cod_ide_cli 
INNER JOIN fepcom_det_reg_evt DET
ON mae.PCOM_NRO_SEQ_K = det.PCOM_NRO_SEQ_K and 
det.PCOM_COD_EVT_K in (15, 80, 230)  and 
det.PCOM_NRO_CTT = substr(TAR_CAC_NRO_CTT_K,1,4) || '-' || substr(TAR_CAC_NRO_CTT_K,5,4) || '-' || substr(TAR_CAC_NRO_CTT_K,9,12)
WHERE 

SUBSTR(TAR.TAR_COD_TIP_PRD_K,1,2) = '01'
AND SOL_FCH_CRC_SOL BETWEEN to_date(%str(%')&ini_fisa.%str(%'),'dd/mm/yyyy') and 
to_date(%str(%')&fin_fisa.%str(%'),'dd/mm/yyyy')
/*and  MAE.PCOM_FCH_K BETWEEN to_date(%str(%')&INI_FISA.%str(%'),'dd/mm/yyyy') and */
/*to_date(%str(%')&fin_FISA.%str(%'),'dd/mm/yyyy')*/
AND (SOL.SOL_COD_CLL_ACT = 14 OR SOL.SOL_COD_CLL_ANT = 14)
AND SOL.SOL_COD_CLL_ADM = 2
AND EXISTS (SELECT BTC_COD_NRO_SOL_K
FROM SFADMI_BCO_BTC_SOL
WHERE BTC_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
AND BTC_COD_TIP_REG_K = 1
AND BTC_COD_ETA_K = 102
AND BTC_COD_EVT_K = 30)
and  exists (select t.Cuenta from mpdt009 t where 
t.cuenta = substr(TAR_CAC_NRO_CTT_K,9,12) and 
t.codent = substr(TAR_CAC_NRO_CTT_K,1,4) and 
t.centalta = substr(TAR_CAC_NRO_CTT_K,5,4)
and t.numbencta = 1 and t.numplastico > 0)
ORDER BY  SOL.SOL_COD_NRO_SOL_K ASC
)A
;QUIT;


PROC SQL ;
CONNECT TO ORACLE AS REPORTITF (PATH="REPORITF.WORLD" USER='KMARTINEZ' PASSWORD='kmar2102');
CREATE TABLE RETIRO_PLASTICO_cdp AS 
SELECT * FROM CONNECTION TO REPORTITF(

SELECT 
sol.sol_nro_inn_ide,
TAR.TAR_CAC_NRO_CTT_K NUMERO_CONTRATO,
TAR.TAR_CAC_NRO_PAN_K NUMERO_TARJETA,
SOL.SOL_COD_IDE_CLI RUT_CLIENTE, 
SOL.SOL_FCH_ALT_SOL FECHA_SOLICITUD,
SOL.SOL_COD_NRO_SOL_K NUMERO_SOLICITUD, 
sol.sol_cod_est_sol ESTADO, 
TRUNC(MAE.PCOM_FCH_K) as fecha_retiro,
MAE.PCOM_GLS_USR_CRC, 
DET.PCOM_COC_SUC CODIGO_SUC
FROM SFADMI_BCO_SOL SOL 
INNER JOIN SFADMI_BCO_TAR TAR
ON TAR.TAR_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
INNER JOIN SFADMI_BCO_OFE OFE
ON OFE.OFE_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
AND OFE.OFE_COD_IND_SOL = 1 
AND OFE.OFE_COD_IND_DRM = 1
AND SUBSTR(OFE.OFE_COD_PRD_OFE_K,1,2) = '01'
INNER JOIN FEPCOM_MAE_REG_EVT MAE
ON sol.SOL_NRO_INN_IDE  = mae.PCOM_COD_IDE_CLI_K
AND MAE.PCOM_COD_EVT_K in (15, 80, 230)  
and  mae.PCOM_DESC_DOC = sol.sol_cod_ide_cli 
INNER JOIN fepcom_det_reg_evt DET
ON mae.PCOM_NRO_SEQ_K = det.PCOM_NRO_SEQ_K and 
det.PCOM_COD_EVT_K in (15, 80, 230)  and 
det.PCOM_NRO_CTT = substr(TAR_CAC_NRO_CTT_K,1,4) || '-' || substr(TAR_CAC_NRO_CTT_K,5,4) || '-' || substr(TAR_CAC_NRO_CTT_K,9,12)
WHERE 
SUBSTR(TAR.TAR_COD_TIP_PRD_K,1,2) = '01'
AND SOL_FCH_CRC_SOL BETWEEN  to_date(%str(%')&INI_FISA.%str(%'),'dd/mm/yyyy') and 
to_date(%str(%')&fin_FISA.%str(%'),'dd/mm/yyyy')
/*and  MAE.PCOM_FCH_K BETWEEN  to_date(%str(%')&INI_FISA.%str(%'),'dd/mm/yyyy') and */
/*to_date(%str(%')&fin_FISA.%str(%'),'dd/mm/yyyy')*/
AND (SOL.SOL_COD_CLL_ACT = 14 OR SOL.SOL_COD_CLL_ANT = 14)
AND SOL.SOL_COD_CLL_ADM = 2
AND EXISTS (SELECT BTC_COD_NRO_SOL_K
FROM SFADMI_BCO_BTC_SOL
WHERE BTC_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
AND BTC_COD_TIP_REG_K = 1
AND BTC_COD_ETA_K = 102
AND BTC_COD_EVT_K = 30)
and  exists (select t.Cuenta from mpdt009 t where 
t.cuenta = substr(TAR_CAC_NRO_CTT_K,9,12) and 
t.codent = substr(TAR_CAC_NRO_CTT_K,1,4) and 
t.centalta = substr(TAR_CAC_NRO_CTT_K,5,4)
and trim(t.pan) = trim(TAR.TAR_CAC_NRO_PAN_K))

)
where fecha_retiro<="&fin.:00:00:00"dt
;QUIT;

/*retiro de plastico cv */
PROC SQL ;
CONNECT TO ORACLE AS CAMPANAS (PATH="REPORITF.WORLD" USER='KMARTINEZ' PASSWORD='kmar2102');
CREATE TABLE retiro_debito AS 
SELECT * FROM CONNECTION TO CAMPANAS(SELECT DISTINCT 
mae.pcom_cod_ide_cli_k, 
 TAR.TAR_CAC_NRO_CTT_K NUMERO_CONTRATO,
TAR.TAR_CAC_NRO_PAN_K NUMERO_TARJETA, 
SUBSTR(PRD.PRD_CAC_NRO_CTT,9) NUMERO_CUENTA_VISTA,
SOL.SOL_COD_IDE_CLI RUT_CLIENTE, 
PER.PER_CAC_IDE_CLI_DV DV, 
SOL.SOL_FCH_ALT_SOL  FECHA_SOLICITUD,
SOL.SOL_COD_NRO_SOL_K NUMERO_SOLICITUD, 
SOL.SOL_COD_EST_SOL ESTADO,
TRUNC(MAE.PCOM_FCH_K) fecha_retiro, 
MAE.PCOM_GLS_USR_CRC, 
DET.PCOM_COC_SUC CODIGO_SUC
FROM SFADMI_BCO_SOL SOL
 INNER JOIN SFADMI_BCO_TAR TAR
   ON TAR.TAR_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
INNER JOIN SFADMI_BCO_PRD_SOL PRD
   ON TAR.TAR_COD_NRO_SOL_K = PRD.PRD_COD_NRO_SOL_K
   AND TAR.TAR_COD_TIP_PRD_K = PRD.PRD_COD_TIP_PRD_K
INNER JOIN SFADMI_BCO_DAT_PER PER
   ON PRD.PRD_COD_NRO_SOL_K = PER.PER_COD_NRO_SOL_K
 AND SOL.SOL_COD_IDE_CLI = PER.PER_COD_IDE_CLI_K
INNER JOIN FEPCOM_MAE_REG_EVT MAE
 ON sol.SOL_NRO_INN_IDE  = mae.PCOM_COD_IDE_CLI_K
 AND MAE.PCOM_COD_EVT_K = 257 
and  mae.PCOM_DESC_DOC = sol.sol_cod_ide_cli 
INNER JOIN fepcom_det_reg_evt DET
ON mae.PCOM_NRO_SEQ_K = det.PCOM_NRO_SEQ_K and 
det.PCOM_COD_EVT_K = 257 and 
(det.PCOM_NRO_CTT = substr(TAR_CAC_NRO_CTT_K,1,4) || '-' || substr(TAR_CAC_NRO_CTT_K,5,4) || '-' || substr(TAR_CAC_NRO_CTT_K,9,12) or 
det.PCOM_NRO_CTT = substr(TAR_CAC_NRO_CTT_K,9,12))
WHERE 
 SUBSTR(TAR.TAR_COD_TIP_PRD_K,1,2) = '04'
AND (SOL.SOL_COD_CLL_ACT = 14 OR SOL.SOL_COD_CLL_ANT = 14)
AND SOL.SOL_COD_CLL_ADM = 2

and sol.sol_fch_crc_sol between  to_date(%str(%')&INI_FISA.%str(%'),'dd/mm/yyyy') and 
to_date(%str(%')&fin_FISA.%str(%'),'dd/mm/yyyy')

/*and MAE.PCOM_FCH_K  between  to_date(%str(%')&INI_FISA.%str(%'),'dd/mm/yyyy') and */
/*to_date(%str(%')&fin_FISA.%str(%'),'dd/mm/yyyy')*/
AND EXISTS (SELECT BTC_COD_NRO_SOL_K
            FROM SFADMI_BCO_BTC_SOL
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

where fecha_retiro <="&fin.:00:00:00"dt
;QUIT;




/******************************************************************************/
/* RETIRO PLASTICO CUENTA CORRIENTE agregado: 30-05-2022*/
/* modificacion query feb 23 */
/*  CUENTA CORRIENTE  */
/*************************************************************************** */

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
	and sol.sol_fch_crc_sol between  to_date(%str(%')01/09/2021%str(%'),'dd/mm/yyyy') 
and 	to_date(%str(%')&fin_FISA.%str(%'),'dd/mm/yyyy')


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



PROC SQL ;
CONNECT TO ORACLE AS CAMPANAS (PATH="REPORITF.WORLD" USER='KMARTINEZ' PASSWORD='kmar2102');
CREATE TABLE retiro_ctacte1 AS 
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
	and sol.sol_fch_crc_sol between  to_date(%str(%')&INI_FISA.%str(%'),'dd/mm/yyyy') 
and to_date(%str(%')&fin_FISA.%str(%'),'dd/mm/yyyy')
/*
	and sol.sol_fch_crc_sol between to_date(%str(%')01/09/2021%str(%'),'dd/mm/yyyy') and 
	to_date(%str(%')31/01/2023%str(%'),'dd/mm/yyyy')*/
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

where fecha_retiro <="&fin.:00:00:00"dt

;QUIT;


/*1691*/
proc sql;
create table retiro_ctacte as 
select distinct
b.* /*,
case when (b.numero_cuenta is not null and a.estado in (8,9,11,50)) then 1 else 0 end as retiro
/*, 
por definicion tomar las altar = 1 de estos estados
b.fecha_retiro*/

from base_limpio as a
left  join retiro_ctacte1 as b
on (a.NUMERO_CUENTA=b.numero_cuenta)
where b.numero_cuenta is not null and a.estado in (8,9,11,50)
;QUIT;




PROC SQL;
   CREATE TABLE WORK.RETIRO_PLASTICO_TC AS 
   SELECT  distinct  input(t1.RUT_CLIENTE,best.) as rut, 
          max(year(datepart(t1.FECHA_RETIRO))*10000+month(datepart(t1.FECHA_RETIRO))*100+
		  day(datepart(t1.FECHA_RETIRO))) as fecha
      FROM WORK.RETIRO_PLASTICO_TC  t1
group by input(t1.RUT_CLIENTE,best.);
QUIT;

PROC SQL;
   CREATE TABLE WORK.RETIRO_PLASTICO_cdp AS 
   SELECT  distinct  input(t1.RUT_CLIENTE,best.) as rut, 
          max(year(datepart(t1.FECHA_RETIRO))*10000+month(datepart(t1.FECHA_RETIRO))*100+
		  day(datepart(t1.FECHA_RETIRO))) as fecha
      FROM WORK.RETIRO_PLASTICO_cdp  t1
group by input(t1.RUT_CLIENTE,best.);
QUIT;

PROC SQL;
   CREATE TABLE WORK.RETIRO_ctacte AS 
   SELECT distinct input(t1.RUT_CLIENTE,best.) as rut, 
          max(year(datepart(t1.FECHA_RETIRO))*10000+month(datepart(t1.FECHA_RETIRO))*100+
		  day(datepart(t1.FECHA_RETIRO))) as fecha
      FROM WORK.RETIRO_ctacte  t1
group by input(t1.RUT_CLIENTE,best.);
QUIT;

PROC SQL;
   CREATE TABLE WORK.RETIRO_debito AS 
   SELECT  distinct  input(t1.RUT_CLIENTE,best.) as rut, 
          max(year(datepart(t1.FECHA_RETIRO))*10000+month(datepart(t1.FECHA_RETIRO))*100+
		  day(datepart(t1.FECHA_RETIRO))) as fecha
      FROM WORK.RETIRO_debito  t1
group by input(t1.RUT_CLIENTE,best.);
QUIT;

%mend retiro_plasticos;

%retiro_plasticos(&n.);


proc sql;
create table TDA_DEBITO_fin as 
select *
from TDA_MCD1
union 
select *
from TDA_MCD2
union 
select *
from TDA_MCD3
union 
select *
from TDA_MCD4
union select *
from TDA_MAESTRO1
union 
select *
from TDA_MAESTRO2
union 
select *
from TDA_MAESTRO3
union 
select *
from TDA_MAESTRO4
;QUIT;

proc sql;
drop table  TDA_MCD1;
 drop table  TDA_MCD2;
 drop table  TDA_MCD3;
 drop table  TDA_MCD4;
 drop table  TDA_MAESTRO1;
 drop table  TDA_MAESTRO2;
drop table  TDA_MAESTRO3;
 drop table  TDA_MAESTRO4;
;QUIT;

proc sql;
create table spos_DEBITO_fin as 
select *
from spos_MCD1
outer union corr 
select *
from spos_MCD2
outer union corr 
select *
from spos_MCD3
outer union corr 
select *
from spos_MCD4
outer union corr select *
from spos_MAESTRO1
outer union corr 
select *
from spos_MAESTRO2
outer union corr 
select *
from spos_MAESTRO3
outer union corr 
select *
from spos_MAESTRO4
;QUIT;


proc sql;
 drop table spos_MCD1;
 drop table spos_MCD2;
 drop table spos_MCD3;
 drop table spos_MCD4;
 drop table spos_MAESTRO1;
 drop table spos_MAESTRO2;
 drop table spos_MAESTRO3;
 drop table spos_MAESTRO4;
;QUIT;

proc sql;
create table TDA_CC_fin as 
select *
from TDA_CC1
union 
select *
from TDA_CC2
union 
select *
from TDA_CC3
union 
select *
from TDA_CC4
;QUIT;

proc sql;
 drop table TDA_CC1;
 drop table TDA_CC2;
 drop table TDA_CC3;
 drop table TDA_CC4;
;QUIT;

proc sql;
create table spos_CC_fin as 
select *
from spos_CC1
outer union corr 
select *
from spos_CC2
outer union corr 
select *
from spos_CC3
outer union corr 
select *
from spos_CC4

;QUIT;


proc sql;
 drop table spos_CC1;
 drop table spos_CC2;
 drop table spos_CC3;
 drop table spos_CC4;
;QUIT;

proc sql;
create table spos_fin as 
select *
from spos1
outer union corr 
select *
from spos2
outer union corr 
select *
from spos3
outer union corr 
select *
from spos4
;QUIT;

proc sql;
 drop table spos1;
 drop table spos2;
 drop table spos3;
 drop table spos4;
;QUIT;

proc sql;
create table tda_fin as 
select *
from tda1
union 
select *
from tda2
union 
select *
from tda3
union 
select *
from tda4
;QUIT;

proc sql;
 drop table tda1;
 drop table tda2;
 drop table tda3;
 drop table tda4;
;QUIT;

proc sql;
create table epu_fin as 
select *
from epu1
union 
select *
from epu2
union 
select *
from epu3
union 
select *
from epu4
;QUIT;

proc sql;
 drop table epu1;
 drop table epu2;
 drop table epu3;
 drop table epu4;
;QUIT;

proc sql;
create table logeo_int_fin as 
select *
from logeo_int_1
union 
select *
from logeo_int_2
union 
select *
from logeo_int_3
union 
select *
from logeo_int_4
;QUIT;

proc sql;
 drop table logeo_int_1;
 drop table logeo_int_2;
 drop table logeo_int_3;
 drop table logeo_int_4;
;QUIT;

proc sql;
create table pagos_fin as 
select *
from pagos1
union 
select *
from pagos2
union 
select *
from pagos3
union 
select *
from pagos4
;QUIT;

proc sql;
 drop table pagos1;
 drop table pagos2;
 drop table pagos3;
 drop table pagos4;
;QUIT;


/*unificar bases de uso y generar indices correspondientes*/

proc sql;
create table SPOS as 
select *
from (
select 
*,
'TC' as producto2
from  spos_FIN
outer union corr 
select 
*,
'CV' as producto2
from  spos_DEBITO_FIN
outer union corr 
select 
*,
'CTACTE' as producto2
from  spos_CC_FIN)
order by rut
;QUIT;

PROC SQL;
CREATE INDEX rut ON work.SPOS (RUT);
QUIT;

proc sql;
drop table spos_FIN;
drop table spos_DEBITO_FIN;
drop table spos_CC_FIN
;QUIT;

proc sql;
create table TDA as 
select *
from (
select 
*,
'TC' as producto2
from  TDA_FIN
outer union corr 
select 
*,
'CV' as producto2
from TDA_DEBITO_FIN
outer union corr 
select 
*,
'CTACTE' as producto2
from  TDA_CC_FIN)
order by rut
;QUIT;

PROC SQL;
CREATE INDEX rut ON work.TDA (RUT);
QUIT;

proc sql;
drop table TDA_FIN;
drop table TDA_DEBITO_FIN;
drop table TDA_CC_FIN
;QUIT;

PROC SQL;
CREATE INDEX rut ON work.EPU_FIN (RUT);
QUIT;

PROC SQL;
CREATE INDEX rut ON work.LOGEO_INT_FIN (RUT);
QUIT;

PROC SQL;
CREATE INDEX rut ON work.PAGOS_FIN (RUT);
QUIT;

PROC SQL;
CREATE INDEX rut ON work.RETIRO_CTACTE (RUT);
QUIT;

PROC SQL;
CREATE INDEX rut ON work.RETIRO_DEBITO (RUT);
QUIT;

PROC SQL;
CREATE INDEX rut ON work.RETIRO_PLASTICO_CDP (RUT);
QUIT;

PROC SQL;
CREATE INDEX rut ON work.RETIRO_PLASTICO_TC (RUT);
QUIT;

proc sql;
create table captados2 as 
select  distinct 
a.*,

max(case 
when (b.rut is not null or c.rut is not null)
and (b.fecha between a.fecha_numero	and a.dia_30 
or c.fecha between a.fecha_numero and a.dia_30) then 1  
else 0 end ) as concreta_30_T,

max(case 
when (b.rut is not null or c.rut is not null)
and (b.fecha between a.fecha_numero	and a.dia_60 
or c.fecha between a.fecha_numero and a.dia_60) then 1 
else 0 end  ) as concreta_60_T,

max(case 
when  (b.rut is not null or c.rut is not null)
and (b.fecha between a.fecha_numero	and a.dia_90 
or c.fecha between a.fecha_numero and a.dia_90) then 1  
else 0 end  ) as concreta_90_T,

max(case 
when  b.fecha between a.fecha_numero	and a.dia_30 then 1
else 0 end ) as concreta_30_SPOS,

max( case 
when b.fecha between a.fecha_numero	and a.dia_60 then 1
else 0 end) as concreta_60_SPOS,

max(case 
when b.fecha between a.fecha_numero	and a.dia_90 then 1
else 0 end
) as concreta_90_SPOS,


max(case 
when  c.fecha between a.fecha_numero	and a.dia_30 then 1
else 0 end
) as concreta_30_tda,

max(case 
when  c.fecha between a.fecha_numero	and a.dia_60 then 1
else 0 end ) as concreta_60_tda,

max(case 
when c.fecha between a.fecha_numero	and a.dia_90 then 1
else 0 end ) as concreta_90_tda,




min(case 
when b.fecha between a.fecha_numero	and a.dia_90 then b.fecha
else 0 end
) as fecha_concreta_SPOS,


min(case when
 c.fecha between a.fecha_numero	and a.dia_90 then c.fecha
else 0 end ) as fecha_concreta_tda



from captados as a 
left join spos as b
on(a.rut=b.rut) and (a.producto2=b.producto2)
left join tda as c
on(a.rut=c.rut)  and (a.producto2=c.producto2)
group by 
a.ind,
a.rut,
a.PRODUCTO,
a.producto2,
a.FECHA	,
a.fecha_numero,
a.dia_30,
a.dia_60,
a.dia_90,
a.CODENT,	a.CENTALTA,	a.CUENTA
;QUIT;

PROC SQL;
CREATE INDEX rut ON work.captados2 (RUT);
QUIT;


proc sql;
create table captados2 as 
select distinct 
a.*,


max(case 
when h.rut is not null and a.producto2='TC'
and h.fecha between a.fecha_numero	and a.dia_30 then 1
else 0 end
) as concreta_30_epu,

max(case 
when h.rut is not null   and a.producto2='TC'
and h.fecha between a.fecha_numero	and a.dia_60 then 1
else 0 end ) as concreta_60_epu,

max(case 
when h.rut is not null   and a.producto2='TC'
and h.fecha between a.fecha_numero	and a.dia_90 then 1
else 0 end ) as concreta_90_epu,

max(case 
when i.rut is not null 
and i.fecha between a.fecha_numero	and a.dia_30 then 1
else 0 end
) as concreta_30_log,

max(case 
when i.rut is not null
and i.fecha between a.fecha_numero	and a.dia_60 then 1
else 0 end ) as concreta_60_log,

max(case 
when i.rut is not null 
and i.fecha between a.fecha_numero	and a.dia_90 then 1
else 0 end ) as concreta_90_log,



max(case 
when  a.producto2='TC'
and (j1.rut is not null or j2.rut is not null)
and (j1.fecha between a.fecha_numero	and a.dia_30 
or j2.fecha between a.fecha_numero and a.dia_30) then 1 
when a.producto2='CV'
and (j3.rut is not null )
and (j3.fecha between a.fecha_numero	and a.dia_30 ) then 1 
when  a.producto2='CTACTE'
and (j4.rut is not null )
and (j4.fecha between a.fecha_numero	and a.dia_30 ) then 1 
else 0 end ) as concreta_30_retira_T,

max(case 
when a.producto2='TC'
and (j1.rut is not null or j2.rut is not null)
and (j1.fecha between a.fecha_numero	and a.dia_60 
or j2.fecha between a.fecha_numero and a.dia_60) then 1 
when a.producto2='CV'
and (j3.rut is not null )
and (j3.fecha between a.fecha_numero	and a.dia_60 ) then 1 
when a.producto2='CTACTE'
and (j4.rut is not null )
and (j4.fecha between a.fecha_numero	and a.dia_60 ) then 1 
else 0 end ) as concreta_60_retira_T,

max(case 
when a.producto2='TC'
and (j1.rut is not null or j2.rut is not null)
and (j1.fecha between a.fecha_numero	and a.dia_90 
or j2.fecha between a.fecha_numero and a.dia_90) then 1 
when a.producto2='CV'
and (j3.rut is not null )
and (j3.fecha between a.fecha_numero	and a.dia_90 ) then 1 
when a.producto2='CTACTE'
and (j4.rut is not null )
and (j4.fecha between a.fecha_numero	and a.dia_90 ) then 1 
else 0 end ) as concreta_90_retira_T,


max(case 
when k.rut is not null and a.producto2='TC'
and k.fecha between a.fecha_numero	and a.dia_30 then 1
else 0 end
) as concreta_30_pagos,

max(case 
when k.rut is not null and a.producto2='TC'
and k.fecha between a.fecha_numero	and a.dia_60 then 1
else 0 end ) as concreta_60_pagos,

max(case 
when k.rut is not null and a.producto2='TC'
and k.fecha between a.fecha_numero	and a.dia_90 then 1
else 0 end ) as concreta_90_pagos,


min(case 
when h.rut is not null and a.producto2='TC'
and h.fecha between a.fecha_numero	and a.dia_90 then h.fecha
else 0 end ) as fecha_concreta_epu,




min(case 
when i.rut is not null 
and i.fecha between a.fecha_numero	and a.dia_90 then i.fecha
else 0 end ) as fecha_concreta_log,

min(case 
when  a.producto2='TC'
and (j1.rut is not null or j2.rut is not null)
and (j1.fecha between a.fecha_numero	and a.dia_90 
or j2.fecha between a.fecha_numero and a.dia_90) then coalesce(j1.fecha,j2.fecha) 
when  a.producto2='CV'
and (j3.rut is not null )
and (j3.fecha between a.fecha_numero	and a.dia_90 ) then j3.fecha 
when  a.producto2='CTACTE'
and (j4.rut is not null )
and (j4.fecha between a.fecha_numero	and a.dia_90 ) then j4.fecha 
else 0 end ) as fecha_concreta_retira_T,
min(case 
when k.rut is not null  and a.producto2='TC'
and k.fecha between a.fecha_numero	and a.dia_90 then k.fecha
else 0 end ) as fecha_concreta_pagos



from captados2 as a 

left join epu_fin as h
on(a.rut=h.rut)

left join logeo_int_fin as i
on(a.rut=i.rut)

left join RETIRO_PLASTICO_TC as j1
on(a.rut=j1.rut)

left join RETIRO_PLASTICO_cdp as j2
on(a.rut=j2.rut)

left join RETIRO_ctacte as j4
on(a.rut=j4.rut)

left join RETIRO_debito  as j3
on(a.rut=j3.rut)
left join pagos_fin as k
on(a.rut=k.rut)
group by 
a.ind,
a.rut,
a.PRODUCTO,
a.FECHA	,
a.fecha_numero,
a.dia_30,
a.dia_60,
a.dia_90,
a.CODENT,	a.CENTALTA,	a.CUENTA

;QUIT;


proc sql;
create table enrolamiento as 
select distinct 
input(substr('Identificador Usuario'n,1,length('Identificador Usuario'n)-1),best.) as rut,
min(year('Inicio Enrolamiento'n)*10000+month('Inicio Enrolamiento'n)*100+day('Inicio Enrolamiento'n)) as fecha
from publicin.IDNOW_REPORTEENROLAMIENTOS 
where 
year('Inicio Enrolamiento'n)*100+month('Inicio Enrolamiento'n) between &periodo_actual. and &periodo_3.
and 'Estado Final'n ='R' 
and calculated rut is not null and 'Sistema Operativo'n IN ('ANDROID','IOS')
group by calculated rut
;QUIT;

PROC SQL;
CREATE INDEX rut ON work.enrolamiento (RUT);
QUIT;


proc sql;
create table captados2 as 
select distinct 
a.*,

max(case 
when h.rut is not null 
and h.fecha between a.fecha_numero	and a.dia_30 then 1
else 0 end
) as concreta_30_RPASS,

max(case 
when h.rut is not null 
and h.fecha between a.fecha_numero	and a.dia_60 then 1
else 0 end ) as concreta_60_RPASS,

max(case 
when h.rut is not null
and h.fecha between a.fecha_numero	and a.dia_90 then 1
else 0 end ) as concreta_90_RPASS,


min(case 
when h.rut is not null 
and h.fecha between a.fecha_numero	and a.dia_90 then h.fecha
else 0 end ) as fecha_concreta_RPASS


from captados2 as a 

left join enrolamiento as h
on(a.rut=h.rut)

group by 
a.ind,
a.rut,
a.PRODUCTO,
a.FECHA	,
a.fecha_numero,
a.dia_30,
a.dia_60,
a.dia_90,
a.CODENT,	a.CENTALTA,	a.CUENTA

;QUIT;


/*primera compra spos*/

proc sql;
create table spos_fin_1 as 
select distinct a.*
from spos as a 
inner join captados2 as b
on(a.rut=b.rut) and (a.fecha=b.fecha_concreta_SPOS) and (a.producto2=b.producto2)
;QUIT;

proc sql;
create table spos_fin_2 as 
select 
a.*

from spos_fin_1 as a 
inner join (select rut,Fecha,producto2,	min(Hora) as hora 
from spos_fin_1
group by rut,fecha,producto2) as b
on(a.rut=b.rut) and (a.fecha=b.fecha) and (a.hora=b.hora) and (a.producto2=b.producto2)
;QUIT;




proc sql;
create table captados3 as 
select distinct 
a.*,
max(case 
when  b.rut is not null then b.CODACT 
  end ) as CODACT ,

max(case 
when  b.rut is not null then b.VENTA_TARJETA   else 0 end)  as VENTA_TARJETA_SPOS ,

max(case 
when  b.rut is not null then b.Nombre_Comercio  end)  as Nombre_Comercio_SPOS 


from captados2 as a 
left join spos_fin_2 as b
on(a.rut=b.rut) and (b.fecha=a.fecha_concreta_SPOS) and (a.producto2=b.producto2)

group by 
a.ind,
a.rut,
a.PRODUCTO,
a.FECHA	,
a.fecha_numero,
a.dia_30,
a.dia_60,
a.dia_90,
a.CODENT,	a.CENTALTA,	a.CUENTA

;QUIT;



/*tipo de cliente captado*/



proc sql;
create table llenado (
CAMP_ID_OFE_K num,
CAMP_COD_CAMP_FK char(99),
CAMP_RUT_CLI num,
CAMP_DV_CLI char(99),
CAMP_COD_TIP_PROD char(99),
CAMP_COD_CND_PROD char(99),
CAMP_COD_ORI_BASE char(99)

)
;QUIT;

proc sql noprint ;
select
ceil (count(distinct case when ID_OFERTA is not null then ID_OFERTA end )/500) as corte
into: corte
from captados3
;QUIT;

%let corte=&corte;
%put &corte;

%macro sacar_data(N);

proc sql;
create table base_cortar as 
select 
monotonic() as ind,
ID_OFERTA
from captados3
where ID_OFERTA is not null
;QUIT;

%do i=1 %to &n.;

%put==================================================================================================;
%put CICLO &I. ;
%put==================================================================================================;

proc sql;
create table base_paso_in as 
select 
ID_OFERTA
from base_cortar
where ind between 500*(&i.-1)+1 and 500*&i.
;QUIT;

data work.Valor_Concatenado(keep=Listado); /*base de salida con campo*/
length Listado $9999; /*largo del campo*/
do until(eof);
set work.base_paso_in end=eof; /*base de entrada: (Base detalle de codigos LATAM)*/
Listado = catx(",", Listado, ID_OFERTA); /*concatenacion*/
end;
run;

proc sql outobs=1 noprint ;
select Listado
into :Listado 
from work.Valor_Concatenado 
;quit;
%let Listado="&Listado";

DATA _NULL_;
Call execute(
cat('
PROC SQL ;
CONNECT TO ORACLE  (PATH=''BRTEFGESTIONP.WORLD'' USER=''CAMP_COMERCIAL'' PASSWORD=''ccomer2409'');
CREATE TABLE cod_camp AS   
SELECT 
* 
FROM CONNECTION TO ORACLE(
SELECT 
CAMP_ID_OFE_K,
CAMP_COD_CAMP_FK,
CAMP_RUT_CLI,
CAMP_DV_CLI,
CAMP_COD_TIP_PROD,
CAMP_COD_CND_PROD,
CAMP_COD_ORI_BASE 

from cbcamp_mae_ofertas 
where CAMP_ID_OFE_K in ( ',&Listado.,' ) ) A 
;QUIT;
')
);
run;  

proc sql noprint;
insert into llenado
select *
from cod_camp 
;QUIT;

proc sql;
drop table base_paso_in;
drop table Valor_Concatenado;
drop table cod_camp;
;QUIT;

%end;

proc sql;
drop table base_cortar
;QUIT;

%mend sacar_data;

%sacar_data(&corte.);

proc sql;
create table llenado2 (
CAMP_ID_OFE_K num,
CAMP_COD_CAMP_FK char(99),
CAMP_RUT_CLI num,
CAMP_DV_CLI char(99),
CAMP_COD_TIP_PROD char(99),
CAMP_COD_CND_PROD char(99),
CAMP_COD_ORI_BASE char(99)

)
;QUIT;

proc sql noprint ;
select
ceil (count(distinct case when ID_OFERTA is not null then ID_OFERTA end )/500) as corte
into: corte
from captados3 where 
id_oferta not in (select CAMP_ID_OFE_K from llenado)
;QUIT;

proc sql NOPRINT;                              
SELECT USUARIO into :USER 
	FROM sasdyp.user_pass WHERE SCHEMA = 'SEGCOM';
SELECT PASSWORD into :PASSWORD 
	FROM sasdyp.user_pass WHERE SCHEMA = 'SEGCOM';
quit;

%let corte=&corte;
%put &corte;

%let path_ora       = '(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.84.167)(PORT = 1521))(CONNECT_DATA=(SERVER = DEDICATED)(SERVICE_NAME = segcom)))';
%let user_ora       = &USER.;
%let pass_ora       = &PASSWORD.;
%let conexion_ora   = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.;
%put &conexion_ora.;

LIBNAME DBLIBORA     &conexion_ora. insertbuff=10000 readbuff=10000;  

%macro sacar_data2(N);

proc sql;
create table base_cortar as 
select 
monotonic() as ind,
ID_OFERTA
from captados3
where ID_OFERTA is not null and   id_oferta not in (select CAMP_ID_OFE_K from llenado)
;QUIT;

%do i=1 %to &n.;

%put==================================================================================================;
%put CICLO &I. ;
%put==================================================================================================;

proc sql ;
create table base_paso_in as 
select 
ID_OFERTA
from base_cortar
where ind between 500*(&i.-1)+1 and 500*&i.
;QUIT;

data work.Valor_Concatenado(keep=Listado); /*base de salida con campo*/
length Listado $9999; /*largo del campo*/
do until(eof);
set work.base_paso_in end=eof; /*base de entrada: (Base detalle de codigos LATAM)*/
Listado = catx(",", Listado, ID_OFERTA); /*concatenacion*/
end;
run;

proc sql outobs=1 noprint ;
select Listado
into :Listado 
from work.Valor_Concatenado 
;quit;
%let Listado=&Listado;


PROC SQL ;
CONNECT TO ORACLE  (PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.);
CREATE TABLE cod_camp AS   
SELECT 
* 
FROM CONNECTION TO ORACLE(
SELECT 
CAMP_ID_OFE_K,
CAMP_COD_CAMP_FK,
CAMP_RUT_CLI,
CAMP_DV_CLI,
CAMP_COD_TIP_PROD,
CAMP_COD_CND_PROD,
CAMP_COD_ORI_BASE 

from CAMPHIS_ADM.cbcamp_mae_ofertas_HIST  
where CAMP_ID_OFE_K in ( &Listado. )
) A 
;QUIT;
 

proc sql noprint;
insert into llenado2
select *
from cod_camp 
;QUIT;

proc sql;
drop table base_paso_in;
drop table Valor_Concatenado;
drop table cod_camp;
;QUIT;

%end;

proc sql;
drop table base_cortar
;QUIT;

%mend sacar_data2;

%sacar_data2(&corte.);

/*PLANES*/

PROC SQL;
   CREATE TABLE PLANES_TBL_PLAN_CLIENTE AS 
   SELECT t1.*,
   (INPUT(LEFT(SUBSTR(LEFT(COMPRESS(COMPRESS( t1.IDENTIFICADOR_CLIENTE,'.'),'-')),1,LENGTH(LEFT(COMPRESS(COMPRESS(t1.IDENTIFICADOR_CLIENTE,'.'),'-')))-1)),BEST.)) AS RUT

      FROM PUBLICIN.PLANES_TBL_PLAN_CLIENTE t1
WHERE ESTADO='ENABLED'
;
QUIT;


proc sql;
create table llenado_fin as 
select 
*
from llenado
union select *
from llenado2
;QuiT;

proc sql;
create table &libreria..onboarding_3M_&periodo_actual. as 
select distinct 
a.*,
b.CAMP_COD_CAMP_FK as COD_CAMP_OFERTA,
b.CAMP_COD_TIP_PROD as COD_TIP_PROD,
b.CAMP_COD_CND_PROD as COD_CND_PROD,

b.CAMP_COD_ORI_BASE,
c.detalle,
case when b.CAMP_COD_ORI_BASE in ('102',
'108',
'201',
'207',
'302') then 'NUEVO' else 'REVIGENTEADO' end as TIPO_CLIENTE,
cats(
case when max(case when concreta_30_SPOS>0 then 1 else 0 end )=1 then 'SPOS' else ' ' end,'-',
case when max(case when concreta_30_tda>0 then 1 else 0 end )=1 then 'TDA' else ' ' end,'-',
case when max(case when concreta_30_epu>0 then 1 else 0 end )=1 then 'EPU COBRO' else ' ' end,'-',
case when max(case when concreta_30_log>0 then 1 else 0 end )=1 then 'LOGUEO' else ' ' end,'-',
case when max(case when concreta_30_pagos>0 then 1 else 0 end )=1 then 'PAGOS' else ' ' end,'-',
case when max(case when concreta_30_RPASS>0 then 1 else 0 end )=1 then 'RPASS' else ' ' end,'-',
case when max(case when concreta_30_retira_T>0 and COD_SUCURSAL=39 and 	VIA='HOMEBAN' then 1 else 0 end )=1 then 'RETIRA TARJ' else ' ' end)
 as combinatoria,

mdy(mod(int(fecha_concreta_SPOS/100),100),mod(fecha_concreta_SPOS,100),int(fecha_concreta_SPOS/10000)) format=date9. as concreta_SPOS_SAS, 
mdy(mod(int(fecha_concreta_tda/100),100),mod(fecha_concreta_tda,100),int(fecha_concreta_tda/10000)) format=date9. as concreta_tda_SAS, 
mdy(mod(int(fecha_concreta_epu/100),100),mod(fecha_concreta_epu,100),int(fecha_concreta_epu/10000)) format=date9. as concreta_epu_SAS, 
mdy(mod(int(fecha_concreta_log/100),100),mod(fecha_concreta_log,100),int(fecha_concreta_log/10000)) format=date9. as concreta_log_SAS, 
mdy(mod(int(fecha_concreta_retira_T/100),100),mod(fecha_concreta_retira_T,100),int(fecha_concreta_retira_T/10000)) format=date9. as concreta_retira_T_SAS, 
mdy(mod(int(fecha_concreta_pagos/100),100),mod(fecha_concreta_pagos,100),int(fecha_concreta_pagos/10000)) format=date9. as concreta_pagos_SAS, 
mdy(mod(int(fecha_concreta_RPASS/100),100),mod(fecha_concreta_RPASS,100),int(fecha_concreta_RPASS/10000)) format=date9. as concreta_RPASS_SAS, 


case when fecha_concreta_SPOS>0 then intck("day",fecha,calculated concreta_SPOS_SAS) else 999 end as dias_SPOS,
case when fecha_concreta_tda>0 then intck("day",fecha,calculated concreta_tda_SAS) else 999 end as dias_tda,
case when fecha_concreta_epu>0 then intck("day",fecha,calculated concreta_epu_SAS) else 999 end as dias_epu,
case when fecha_concreta_log>0 then intck("day",fecha,calculated concreta_log_SAS) else 999 end as dias_log,
case when fecha_concreta_retira_T>0 then intck("day",fecha,calculated concreta_retira_T_SAS) else 999 end as dias_RETIRA,
case when fecha_concreta_pagos>0 then intck("day",fecha,calculated concreta_pagos_SAS) else 999 end as dias_pagos,
case when fecha_concreta_RPASS>0 then intck("day",fecha,calculated concreta_RPASS_SAS) else 999 end as dias_RPASS,
d.plan_id,
case when d.plan_id =1 then  'PLAN LIGHT'
when d.plan_id=2 then 'PLAN PRO'
when d.plan_id=3 then 'PLAN BLACK' else 'NO APLICA' end as Plan
from captados3 as a 
left join llenado_fin as b
on(a.id_oferta=b.CAMP_ID_OFE_K)
left join pmunoz.tipo_cliente_camp as c
on(input(b.CAMP_COD_ORI_BASE,best.)=c.codigo)
left join planes_tbl_plan_cliente  as D
on(a.rut=d.rut)
group by a.rut
;QUIT;


/*colapso*/ 

proc sql;
create table colapso as 
select 
&periodo_actual. as periodo,
PRODUCTO,
TIPO_CLIENTE,
combinatoria,

case when COD_SUCURSAL=39 and 	VIA='HOMEBAN' then 'DIGITAL' else 'PRESENCIAL' end as TIPO_CAPTACION,
count(rut) as captados,
sum(concreta_30_T) as con_30_T,
sum(concreta_60_T) as con_60_T	,
sum(concreta_90_T) as con_90_T,
calculated con_60_T-calculated con_30_T as con_T_diff1, 
calculated con_90_T-calculated con_60_T as con_T_diff2, 

sum(concreta_30_SPOS) as con_30_SPOS,
sum(concreta_60_SPOS) as con_60_SPOS,
sum(concreta_90_SPOS) as con_90_SPOS,

calculated con_60_SPOS-calculated con_30_SPOS as con_SPOS_diff1, 
calculated con_90_SPOS-calculated con_60_SPOS as con_SPOS_diff2,

sum(concreta_30_tda) as	con_30_tda,
sum(concreta_60_tda) as	con_60_tda,
sum(concreta_90_tda) as con_90_tda,

calculated con_60_tda-calculated con_30_tda as con_tda_diff1, 
calculated con_90_tda-calculated con_60_tda as con_tda_diff2,

count(case when concreta_30_tda>0 and concreta_30_SPOS>0 then rut end) as	con_30_tda_SPOS,
count(case when concreta_60_tda>0 and concreta_60_SPOS>0 then rut end) as	con_60_tda_SPOS,
count(case when concreta_90_tda>0 and concreta_90_SPOS>0 then rut end) as con_90_tda_SPOS,

calculated con_60_tda_SPOS-calculated con_30_tda_SPOS as con_tda_SPOS_diff1, 
calculated con_90_tda_SPOS-calculated con_60_tda_SPOS as con_tda_SPOS_diff2,

count(case when concreta_30_tda>0 and concreta_30_SPOS=0 then rut end) as	con_30_solo_TDA,
count(case when concreta_60_tda>0 and concreta_60_SPOS=0 then rut end) as	con_60_solo_TDA,
count(case when concreta_90_tda>0 and concreta_90_SPOS=0 then rut end) as con_90_solo_TDA,

calculated con_60_solo_TDA-calculated con_30_solo_TDA as con_solo_TDA_diff1, 
calculated con_90_solo_TDA-calculated con_60_solo_TDA as con_solo_TDA_diff2,

count(case when concreta_30_tda=0 and concreta_30_SPOS>0 then rut end) as	con_30_solo_SPOS,
count(case when concreta_60_tda=0 and concreta_60_SPOS>0 then rut end) as	con_60_solo_SPOS,
count(case when concreta_90_tda=0 and concreta_90_SPOS>0 then rut end) as con_90_solo_SPOS,

calculated con_60_solo_SPOS-calculated con_30_solo_SPOS as con_solo_SPOS_diff1, 
calculated con_90_solo_SPOS-calculated con_60_solo_SPOS as con_solo_SPOS_diff2,

sum(concreta_30_epu) as con_30_epu,
sum(concreta_60_epu) as con_60_epu,
sum(concreta_90_epu) as con_90_epu,

calculated con_60_epu-calculated con_30_epu as con_epu_diff1, 
calculated con_90_epu-calculated con_60_epu as con_epu_diff2,

sum(concreta_30_log) as con_30_log,
sum(concreta_60_log) as con_60_log,
sum(concreta_90_log) as con_90_log,

calculated con_60_log-calculated con_30_log as con_log_diff1, 
calculated con_90_log-calculated con_60_log as con_log_diff2,


sum(case when COD_SUCURSAL=39 and 	VIA='HOMEBAN' then concreta_30_retira_T else 0 end) as con_30_retira_T,
sum(case when COD_SUCURSAL=39 and 	VIA='HOMEBAN' then  concreta_60_retira_T else 0 end) as con_60_retira_T,
sum(case when COD_SUCURSAL=39 and 	VIA='HOMEBAN' then concreta_90_retira_T else 0 end) as con_90_retira_T,

calculated con_60_retira_T-calculated con_30_retira_T as con_retira_T_diff1, 
calculated con_90_retira_T-calculated con_60_retira_T as con_retira_T_diff2,

sum(concreta_30_pagos) as con_30_pagos,
sum(concreta_60_pagos) as con_60_pagos,
sum(concreta_90_pagos) as con_90_pagos,

calculated con_60_pagos-calculated con_30_pagos as con_pagos_diff1, 
calculated con_90_pagos-calculated con_60_pagos as con_pagos_diff2,

sum(concreta_30_RPASS) as con_30_RPASS,
sum(concreta_60_RPASS) as con_60_RPASS,
sum(concreta_90_RPASS) as con_90_RPASS,

calculated con_60_RPASS-calculated con_30_RPASS as con_RPASS_diff1, 
calculated con_90_RPASS-calculated con_60_RPASS as con_RPASS_diff2,



case when dias_SPOS<=30 and dias_SPOS<10 then cats('0',dias_SPOS,'.',dias_SPOS)
when dias_SPOS<=30 and dias_SPOS>=10 then cats(dias_SPOS,'.',dias_SPOS)
when dias_SPOS between 31 and 40 then  '31.[31,40]'
when dias_SPOS between 41 and 50 then  '32.[41,50]'
when dias_SPOS between 51 and 60 then  '33.[51,60]'
when dias_SPOS between 61 and 70 then  '34.[61,70]'
when dias_SPOS between 71 and 80 then  '35.[71,80]'
when dias_SPOS between 81 and 70 then  '36.[81,90]'
else '00.No Aplica' end as DIAS_SPOS,

case when dias_TDA<=30 and dias_TDA<10 then cats('0',dias_TDA,'.',dias_TDA)
when dias_TDA<=30 and dias_TDA>=10 then cats(dias_TDA,'.',dias_TDA)
when dias_TDA between 31 and 40 then  '31.[31,40]'
when dias_TDA between 41 and 50 then  '32.[41,50]'
when dias_TDA between 51 and 60 then  '33.[51,60]'
when dias_TDA between 61 and 70 then  '34.[61,70]'
when dias_TDA between 71 and 80 then  '35.[71,80]'
when dias_TDA between 81 and 70 then  '36.[81,90]'
else '00.No Aplica' end as DIAS_TDA,

case when dias_EPU<=30 and dias_EPU<10 then cats('0',dias_EPU,'.',dias_EPU)
when dias_EPU<=30 and dias_EPU>=10 then cats(dias_EPU,'.',dias_EPU)
when dias_EPU between 31 and 40 then  '31.[31,40]'
when dias_EPU between 41 and 50 then  '32.[41,50]'
when dias_EPU between 51 and 60 then  '33.[51,60]'
when dias_EPU between 61 and 70 then  '34.[61,70]'
when dias_EPU between 71 and 80 then  '35.[71,80]'
when dias_EPU between 81 and 70 then  '36.[81,90]'
else '00.No Aplica' end as DIAS_EPU,

case when dias_LOG<=30 and dias_LOG<10 then cats('0',dias_LOG,'.',dias_LOG)
when dias_LOG<=30 and dias_LOG>=10 then cats(dias_LOG,'.',dias_LOG)
when dias_LOG between 31 and 40 then  '31.[31,40]'
when dias_LOG between 41 and 50 then  '32.[41,50]'
when dias_LOG between 51 and 60 then  '33.[51,60]'
when dias_LOG between 61 and 70 then  '34.[61,70]'
when dias_LOG between 71 and 80 then  '35.[71,80]'
when dias_LOG between 81 and 70 then  '36.[81,90]'
else '00.No Aplica' end as DIAS_LOG,

case when dias_RETIRA<=30 and dias_RETIRA<10 then cats('0',dias_RETIRA,'.',dias_RETIRA)
when dias_RETIRA<=30 and dias_RETIRA>=10 then cats(dias_RETIRA,'.',dias_RETIRA)
when dias_RETIRA between 31 and 40 then  '31.[31,40]'
when dias_RETIRA between 41 and 50 then  '32.[41,50]'
when dias_RETIRA between 51 and 60 then  '33.[51,60]'
when dias_RETIRA between 61 and 70 then  '34.[61,70]'
when dias_RETIRA between 71 and 80 then  '35.[71,80]'
when dias_RETIRA between 81 and 70 then  '36.[81,90]'
else '00.No Aplica' end as DIAS_RETIRA,

case when dias_PAGOS<=30 and dias_PAGOS<10 then cats('0',dias_PAGOS,'.',dias_PAGOS)
when dias_PAGOS<=30 and dias_PAGOS>=10 then cats(dias_PAGOS,'.',dias_PAGOS)
when dias_PAGOS between 31 and 40 then  '31.[31,40]'
when dias_PAGOS between 41 and 50 then  '32.[41,50]'
when dias_PAGOS between 51 and 60 then  '33.[51,60]'
when dias_PAGOS between 61 and 70 then  '34.[61,70]'
when dias_PAGOS between 71 and 80 then  '35.[71,80]'
when dias_PAGOS between 81 and 70 then  '36.[81,90]'
else '00.No Aplica' end as DIAS_PAGOS,

case when dias_RPASS<=30 and dias_RPASS<10 then cats('0',dias_RPASS,'.',dias_RPASS)
when dias_RPASS<=30 and dias_RPASS>=10 then cats(dias_RPASS,'.',dias_RPASS)
when dias_RPASS between 31 and 40 then  '31.[31,40]'
when dias_RPASS between 41 and 50 then  '32.[41,50]'
when dias_RPASS between 51 and 60 then  '33.[51,60]'
when dias_RPASS between 61 and 70 then  '34.[61,70]'
when dias_RPASS between 71 and 80 then  '35.[71,80]'
when dias_RPASS between 81 and 70 then  '36.[81,90]'
else '00.No Aplica' end as DIAS_RPASS,

case when VENTA_TARJETA_SPOS>0 then coalesce(b.RUBRO_GESTION,'Otros Rubros SPOS') else 'NO APLICA' end  as rubro_spos,

sum(VENTA_TARJETA_SPOS) as MONTO_SPOS,
Nombre_Comercio_SPOS,
plan_id,
Plan
	
from &libreria..onboarding_3M_&periodo_actual. as a 
left join ( select 
COD_ACT,
max(CATEGORIAS_RIPLEY) as RUBRO_GESTION
from sbarrera.TABLA_ARBOL /*Tabla de asignacion de rubros*/
group by 
COD_ACT) as b
on(a.codact=b.COD_ACT)
group by 
PRODUCTO,
TIPO_CLIENTE,
calculated TIPO_CAPTACION,
combinatoria,
plan_id,
Plan,


calculated DIAS_SPOS,

calculated DIAS_TDA,

calculated DIAS_EPU,

calculated DIAS_LOG,

calculated DIAS_RETIRA,

calculated DIAS_PAGOS,

calculated DIAS_RPASS,

calculated rubro_spos,

Nombre_Comercio_SPOS
;QUIT;



proc sql;
delete * from &libreria..SPOS_ONBOARDING_3M 
where periodo=&periodo_actual.
;QUIT;

proc sql noprint;
insert into &libreria..SPOS_ONBOARDING_3M  
select 
*
from colapso
;QUIT;

proc sql;
create table &libreria..SPOS_ONBOARDING_3M as 
select * 
from &libreria..SPOS_ONBOARDING_3M
;QUIT;

/*borrar todas las tablas del work, tener cuidado con tablas internas si no borrara toda la libreria*/
proc datasets library=WORK kill noprint;
run;
quit;

%mend concrecion_3M_REAL;

%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

%concrecion_3M_REAL(0,&libreria.);
%concrecion_3M_REAL(1,&libreria.);
%concrecion_3M_REAL(2,&libreria.);
%concrecion_3M_REAL(3,&libreria.);
%concrecion_3M_REAL(4,&libreria.);


DATA _null_;
periodo_MM = input(put(intnx('month',today(),-0,'begin'),yymmn6. ),$10.) ;
Call symput("periodo_MM", periodo_MM);
RUN;
%put &periodo_MM;

/*==================================================================================================*/
/*== Export a AWS para tableau ==== EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(spos_onboarding_3m,raw,oracloud,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(spos_onboarding_3m,&libreria..spos_onboarding_3m,raw,oracloud,0);

/*== Export a AWS para sasdata ==== EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_dgtl_onboarding_3m,raw,sasdata,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_dgtl_onboarding_3m,&libreria..onboarding_3M_&periodo_MM.,raw,sasdata,0);

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
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_CLIENTES';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CLIENTES_2';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3; %put &=DEST_4;	%put &=DEST_5;	
%put &=DEST_6;

/* VARIABLE TIEMPO - FIN */
data _null_;
dur = datetime() - &tiempo_inicio;
put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
/*TO = ("&DEST_1")*/
TO = ("&DEST_6")
CC = ("&DEST_1", "&DEST_2", "&DEST_3", "&DEST_4", "&DEST_5")
SUBJECT = ("MAIL_AUTOM: Proceso SPOS_ONBOARDING_3M");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "		Proceso SPOS_ONBOARDING_3M, ejecutado con fecha: &fechaeDVN";  
 PUT "		Información disponible en:";  
 PUT "			- SAS, &libreria..SPOS_ONBOARDING_3M";
 PUT "			- SAS, &libreria..onboarding_3M_&periodo_actual. ";
 PUT "			- AWS, oracloud.spos_onboarding_3m";
 PUT "			- AWS, sasdata.sas_dgtl_onboarding_3m";
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

