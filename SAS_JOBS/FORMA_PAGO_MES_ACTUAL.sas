/*==================================================================================================*/
/*==================================	EQUIPO ARQ.DATOS Y AUTOM.		============================*/
/*==================================	FORMA_PAGO_MES_ACTUAL			============================*/
/* CONTROL DE VERSIONES
/* 2023-06-14 -- v04	-- David V.		-- A solicitud de Pedro, se quita join final que apuntaban al segmento.
										   De igual forma este cruce estaba fallando, ya que no existe en SAS 
										   por periodos el nuevo segmento, solo en aws.
/* 2023-06-11 -- v03	-- Esteban P.	-- Se cambian credenciales de conexión GEDCRE.
/* 2023-05-17 -- v02	-- David V.		-- Versionamiento y export to AWS.
/* 0000-00-00 -- v01 	-- Original 	
*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*==================================================================================================*/
%put===========================================================================================;
%put [02] PARAMETROS ;
%put===========================================================================================;

%let i=0;/* 1 ES EL MES ANTERIOR,13 el año anterior*/
%let libreria= RESULT;

proc import datafile = '/sasdata/users94/user_bi/TRASPASO_DOCS/DEPTO_DIV_RETAIL.csv'
out = DEPTO_DIV_RETAIL
dbms = dlm
replace;
delimiter =';';
run;

DATA _null_;
datex = input(put(intnx('month',today(),-&i.,'end'),yymmn6. ),$10.);
datex2 = input(put(intnx('month',today(),-&i.-1,'end'),yymmn6. ),$10.);
ini_char = input(put(intnx('month',today(),-&i.,'begin'),ddmmyy10. ),$10.);
fin_char = input(put(intnx('month',today(),-&i.,'end'),ddmmyy10. ),$10.);
Call symput("periodo", datex);
Call symput("periodo_ant", datex2);
Call symput("ini_char", ini_char);
Call symput("fin_char", fin_char);
RUN;

%put &periodo;
%put &periodo_ant;
%put &ini_char;
%put &fin_char;


%put==================================================================================================;
%put [03] Extraer Base de ventas Tienda en &Periodo. con Variables Relevantes ;
%put==================================================================================================;



%let mz_connect_zeus=CONNECT TO ODBC as zeus(datasrc="creditoprd" user="CONSULTA_CREDITO" password="crdt#0806");

proc sql;

&mz_connect_zeus;
create table work.Detalle_Vtas_TDA as 
SELECT *,DDMTD_FCH_DIA as FECHA

from  connection to zeus(

SELECT  
FLOOR(DDMTD_FCH_DIA/100) as Periodo,
a.DDMTD_FCH_DIA,


A.DDMTD_FCH_DIA-100*floor(A.DDMTD_FCH_DIA/100) as Dia_Nro,
(a.DDMSU_COD_SUC-10000) AS SUCURSAL,
a.DDMAR_COD_SKU_ART as SKU,
a.DDMDT_RUT_CLI as RUT,
a.DCMDT_RUT_CPD as RUT_CPD,

a.DCMDT_NRO_UNI as NRO_UNI,

case when a.DCMDT_COD_TIP_TRN=1 then 'COMPRA' else 'NOTA CREDITO' end as tipo_compra,
a.DDMFP_COD_FOR_PAG,

CASE WHEN a.DDMFP_COD_FOR_PAG=3 then 'TAR' else 'OMP' end as Medio_Pago,

CASE WHEN DDMFP_COD_FOR_PAG=3 THEN 'TR' 
WHEN DDMFP_COD_FOR_PAG = 1 THEN 'EFECTIVO'
WHEN DDMFP_COD_FOR_PAG = 2 THEN 'CHEQUES'
WHEN DDMFP_COD_FOR_PAG IN (4, 15) THEN 'T_CREDITO'
WHEN DDMFP_COD_FOR_PAG = 16 THEN 'DEBITO'
ELSE 'OTRA' END AS FORMA_PAGO,


a.DCMDT_COD_TIP_TRN AS TIPO_TRX,
CASE WHEN (DDMSU_COD_SUC-10000) = 39 THEN '.COM' ELSE 'TDA' END AS LUGAR,

a.DDMSU_COD_SUC||' '||a.DDMTD_FCH_DIA||' '||a.DCMDT_NRO_TML||' '||a.DCMDT_NRO_DCT  AS BOLETA,

CASE WHEN DCMDT_COD_TIP_TRN = 1 THEN 1 ELSE -1 END AS AUX_TIPO_TRX,


case when DCMDT_COD_TIP_TRN=1 then
DDMSU_COD_SUC||'-'||DDMTD_FCH_DIA||'-'||DCMDT_NRO_TML||'-'||DCMDT_NRO_DCT end as bol_vta,

case when DCMDT_COD_TIP_TRN=3 then
DDMSU_COD_SUC||'-'||DDMTD_FCH_DIA||'-'||DCMDT_NRO_TML||'-'||DCMDT_NRO_DCT end as bol_nc,


a.DCMDT_NRO_ITM as Nro_Item,
a.DCMDT_MNT_PCO_ART-a.DCMDT_MNT_DST_BOL-a.DCMDT_MNT_DST_ART-a.DCMDT_KLM_LAN as Mto,
a.dcmdt_mnt_cap as CAPITAL,
a.DCMDT_MAG_FNR as MAG_FN,
a.DCMDT_MAG_CMC as MAG_CMC

FROM GEDCRE_CREDITO.DCRM_COS_MOV_TRN_DET_VTA_ART as a  
WHERE a.DCMdT_COD_TRN NOT IN(39,401,402,89,90,93)
and a.DDMSU_COD_SUC NOT IN (10993,10990) 
and a.DDMSU_COD_NEG=1
and a.DCMDT_COD_CMR_ASO=1 
and a.DCMDT_COD_TIP_TRN in (1,3) /*1= NO nota de credito, 3= SI nota de credito*/
and a.DDMTD_FCH_DIA>=100*&Periodo+01
and a.DDMTD_FCH_DIA<=100*&Periodo+31
) as conexion 
;QUIT;


LIBNAME CAMP ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="BRTEFGESTIONP.WORLD"  SCHEMA=CAMP_ADM  USER='CAMP_COMERCIAL'  PASSWORD='ccomer2409' ;

proc sql;
create table &libreria..SUCURSAL as 
select distinct
T3.CAMP_DAT_VALOR1 as codigo,
T3.CAMP_DAT_TEXTO1 as sucursal
from CAMP.CBCAMP_PAR_TABLAS T1
INNER JOIN CAMP.CBCAMP_PAR_COLUMNAS T2 ON T1.CAMP_COD_TABLA = T2.CAMP_COD_TABLA_K
INNER JOIN CAMP.CBCAMP_PAR_DATOS T3 ON T1.CAMP_COD_TABLA = T3.CAMP_COD_TABLA_K
WHERE T1.CAMP_COD_TABLA = 2
order by T3.CAMP_DAT_VALOR1
;QUIT;



/*SE DEJA LA DIVISION QUE ASIGANA RETAIL (LOS DEPTOS SON LOS MISMOS)*/
PROC SQL;
CREATE TABLE SKU AS
SELECT t1.PRV_PRODUCTOVTA, 
t1.SKU,
coalesce(t2.DIVISION,'SIN INF') as DIVISION,
t1.PRD_DEPTO, 
t1.DEP_DESCRIPCION, 
t1.PRD_LINEA, 
t1.LIN_DESCRIPCION, 
t1.MOD_DESCRIPCION, 
t1.MAR_DESCRIPCION, 
t1.PRD_CODESTACION
FROM RESULT.SKU t1 LEFT JOIN DEPTO_DIV_RETAIL t2
ON (t1.PRD_DEPTO=t2.Cod_Depto)
where t2.DIVISION not in ('HOME IMPROVEMENT') /* a partir de febrero 2022*/
;QUIT;

LIBNAME credito ODBC  DATASRC=creditoprd  SCHEMA=GEDCRE_CREDITO  USER=CONSULTA_CREDITO  PASSWORD='crdt#0806';

proc sql ;
create table DETALLE_ARTICULO AS 
SELECT A.*,
b.PRD_LINEA as COD_LINEA,
b.LIN_DESCRIPCION,
b.PRD_CODESTACION,
b.MAR_DESCRIPCION,
b.DIVISION as NOMBRE_DIVISION,
b.PRD_DEPTO as COD_DEPTO,
CATS(b.PRD_DEPTO,'.-',b.DEP_DESCRIPCION) as DEPARTAMENTO_FIN,
CATS(A.SUCURSAL,'.-',C.SUCURSAL) AS Nombre_Sucursal
FROM WORK.Detalle_Vtas_TDA  A
LEFT JOIN SKU B ON (A.SKU=B.SKU) AND B.PRD_DEPTO NOT IS MISSING
LEFT JOIN &libreria..SUCURSAL C ON (A.SUCURSAL=C.CODIGO) /* REVISAR TABLA */

;QUIT;


PROC SQL;
CREATE TABLE DETALLE_ARTICULO_3 AS 
SELECT A.*, 
CASE WHEN A.NOMBRE_DIVISION IN ('ELECTRONICA','TECNOLOGIA','DECOHOGAR') THEN 'DURO' ELSE 'BLANDO' END AS BLANDO_DURO 
FROM WORK.DETALLE_ARTICULO  A 
;QUIT;


%put==================================================================================================;
%put [05] COMO EN PRODUCTO=16 CAE TODO DEBITO SE CRUZA CON CHEK Y DEBITO PARA TENER UN PROXI DE LA VENTA  ;
%put==================================================================================================;

PROC SQL;
CREATE TABLE WORK.BOLETA AS 
SELECT periodo,
fecha,
t1.RUT_CPD, 
t1.BOLETA, 
t1.LUGAR, 
t1.DDMFP_COD_FOR_PAG, 
(SUM(t1.Mto)) AS Mto
FROM WORK.DETALLE_ARTICULO_3 t1
GROUP BY  periodo,fecha,t1.RUT_CPD,
t1.BOLETA,
t1.LUGAR,
t1.DDMFP_COD_FOR_PAG
order by DDMFP_COD_FOR_PAG,fecha asc, rut_cpd,MTO asc;
QUIT;

%put==================================================================================================;
%put [05.1] Ver TRX de Check &Periodo. ;
%put==================================================================================================;

proc sql;
connect to SQLSVR as mydb
(datasrc="SQL_Datawarehouse" user="user_sas"
PASSWORD="{sas002}AC224E474B8742BD13124A965275013020A60F8D15DCC25A52A5D43F49A76B4D");
create table work.DATA_Loyalty_2 as
select *, cat(sucursal+10000,' ',input(put(datepart(FECHA),yymmddn8.),best.) ,' ',input(nro_caja,best.),' ',nro_docto) as BOLETA,
case when  sucursal=39 then '.COM' else 'TDA' end as Tda_online
from connection to mydb ( SELECT
CODIGO_UNICO as ID,
FECHA,
SUCURSAL,
NRO_CAJA,
NRO_DOCTO,
NRO_TARJETA,
MARCA_TAR,
TIPO_TAR,
MONTO
FROM [db2].[TRX_TARJETAS_TRANSBANK]
WHERE 100*year(FECHA)+month(FECHA)=&PERIODO.
AND TRX_TARJETAS_TRANSBANK.tipo_tar= 'D'
AND TRX_TARJETAS_TRANSBANK.marca_tar = 'RP') as conexion 
;quit;


%put==================================================================================================;
%put [05.2] Ver TRX de CV &Periodo. ;
%put==================================================================================================;


%let path_ora      = '(DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SID = ripleyc)))'; 
%let user_ora      = 'RIPLEYC'; 
%let pass_ora      = 'ri99pley';
%let conexion_ora  = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 
LIBNAME DBLIBORA     &conexion_ora. insertbuff=10000 readbuff=10000; 

PROC SQL  NOERRORSTOP;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );

create table SB_MOV_CUENTA_VISTA2  as
select 
rut,
FECHA,
COMPRA_RIPLEY,
CASE 
when tmo_tipotra='D' then 
CASE
WHEN DESCRIPCION IN ('COMPRA NACIONAL') THEN 'Compras Redcompra' 
WHEN DESCRIPCION IN ('COMPRA NACIONAL MCD') THEN 'Compras Redcompra MCD' 
WHEN DESCRIPCION IN ('COMPRA INTERNACIONAL') THEN 'Compras Internacionales' 
WHEN DESCRIPCION IN ('COMPRA INTERNACIONAL MCD') THEN 'Compras Internacionales MCD' 
WHEN DESCRIPCION IN ('CARGO POR PEC') THEN 'PEC' 
WHEN DESCRIPCION IN ('GIRO CAJERO AUTOMATICO') THEN 'Giros ATM' 
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
c1.tmo_fechor as FECHA, 
c1.rub_desc as DESCRIPCION, 
c1.tmo_tipotra, 
(
SELECT cod_destra 
FROM tgen_codtrans 
WHERE cod_tra = tmo_codtra AND cod_mod = tmo_codmod 
) as gls_transac,

CASE 
WHEN c1.tmo_tipotra='D' 
and (c1.con_libre like '%Ripley%' OR c1.con_libre like '%RIPLEY%') 
AND  c1.con_libre NOT like '%PAGO%' 
THEN 'COMPRA_RIPLEY' else ''
END AS COMPRA_RIPLEY


from (
select
*
from  tcap_tramon /*base de movimientos*/ 
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

and tmo_fechor >= to_date(%str(%')&ini_char.%str(%'),'dd/mm/yyyy')
and tmo_fechor <= to_date(%str(%')&fin_char.%str(%'),'dd/mm/yyyy')

/*FINAL: QUERY DESDE OPERACIONES*/ 
)  C1  
left join ( 

SELECT distinct cli_identifica ,vis_numcue  
from tcli_persona /*MAESTRA DE CLIENTES BANCO*/ 
,tcap_vista /*SALDOS CUENTAS VISTAS */ 
where cli_codigo=vis_codcli 
and vis_mod=4/*cuenta vista*/ 
and (VIS_PRO=4/*CV*/ or VIS_PRO=40/*LCA*/) 
and vis_tip=1  /*persona no juridica*/ 
AND (vis_status='2' or vis_status='9') /*solo aquellas con estado vigente o cerrado*/ 
)  C2 

on (c1.tmo_numcue=c2.vis_numcue) 
where c1.tmo_tipotra='D'
) ;
disconnect from ORACLE
;QUIT;

proc sql;
create table MOV_CUENTA_VISTA_TDA  as
select 
rut,
COMPRA_RIPLEY,
Descripcion_Cargo,
input(put(datepart(FECHA),yymmddn8.),best.) as fec_num

from SB_MOV_CUENTA_VISTA2
where COMPRA_RIPLEY='COMPRA_RIPLEY' and Descripcion_Cargo not in ('Pago LCA')
;quit;


%let path_ora      = '(DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SID = ripleyc)))'; 
%let user_ora      = 'RIPLEYC'; 
%let pass_ora      = 'ri99pley';
%let conexion_ora  = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 


PROC SQL;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );

create table MOV_CUENTA_corriente2  as
select 
rut,
FECHA,
CodFecha,
COMPRA_RIPLEY,
CASE 
when tmo_tipotra='D' then 
CASE
WHEN DESCRIPCION IN ('COMPRA NACIONAL CTA CTE') THEN 'Compras Redcompra' 
WHEN DESCRIPCION IN ('COMPRA INTERNACIONAL CTA CTE') THEN 'Compras Internacionales' 
WHEN DESCRIPCION IN ('CARGO POR PEC') THEN 'PEC' 
/*--  AAG    Los Giros Nac. e InterN. esta abajo */
/*---  WHEN DESCRIPCION IN ('GIRO CAJERO AUTOMATICO') THEN 'Giros ATM'    
/*-- AAG      */
when DESCRIPCION IN ('GIRO ATM INTERNACIONAL CTA CTE') then 'Giros internacional CTA CTE'
when DESCRIPCION IN ('GIRO ATM NACIONAL CTA CTE') then 'Giros ATM CTA CTE'
WHEN DESCRIPCION IN ('GIRO POR CAJA') THEN 'Giros Caja'
/*--  AAG  el Giro Int esta arriba  */
/*-- WHEN DESCRIPCION IN ('GIRO INTERNACIONAL') THEN 'Giro Internacional'
/*-- AAG */ 
WHEN DESCRIPCION IN ('TRANSFERENCIA A OTROS BANCOS') THEN 'TEF emitidas Otros Bancos'
WHEN DESCRIPCION IN ('PAGO TARJETA DE CREDITO') THEN 'Pago de Tarjeta' 
WHEN DESCRIPCION IN ('A CUENTA BANCO RIPLEY','POR TRASPASO A CUENTA')  THEN 'Pago LCA'
/*--   WHEN DESCRIPCION IN ('COSTO DE MANTENCION MENSUAL CUENTA VISTA') then 'Comision planes'
/*-- AAG*/
WHEN  DESCRIPCION IN ('COSTO DE MANTENCION MENSUAL CTA CTE') then 'Comision planes'
WHEN DESCRIPCION IN ('IVA COSTO DE MANTENCION MENSUAL CTA CTE') then 'IVA Com cta cte'
/*-- AAG*/ 
else 'OTROS CARGOS' 
end else ''
END AS Descripcion_Cargo 

from connection to ORACLE
( select 
CAST(SUBSTR(c2.cli_identifica,1,length(c2.cli_identifica)-1) AS INT)  rut,
SUBSTR(c2.cli_identifica,length(c2.cli_identifica),1)  dv,

cast(TO_CHAR( c1.tmo_fechor,'YYYYMMDD') as INT) as CodFecha,

c1.tmo_fechor as FECHA, 
c1.rub_desc as DESCRIPCION, 
c1.tmo_tipotra, 
(
SELECT cod_destra 
FROM tgen_codtrans 
WHERE cod_tra = tmo_codtra AND cod_mod = tmo_codmod 
) as gls_transac,
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

and tmo_fechor >= to_date(%str(%')&ini_char.%str(%'),'dd/mm/yyyy')
and tmo_fechor <= to_date(%str(%')&fin_char.%str(%'),'dd/mm/yyyy')

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
AND (vis_status='2' or vis_status='9') /*solo aquellas con estado vigente o cerrado*/ 
)  C2 

on (c1.tmo_numcue=c2.vis_numcue) 

) ;
disconnect from ORACLE;
QUIT;


proc sql;
create table CCTE_FILTRADA AS
SELECT 
RUT,
input(put(datepart(FECHA),yymmddn8.),best.) as fec_num,
COMPRA_RIPLEY,
Descripcion_Cargo
FROM MOV_CUENTA_corriente2
WHERE 
COMPRA_RIPLEY="COMPRA_RIPLEY" AND Descripcion_Cargo="Compras Redcompra"
;QUIT;

%put==================================================================================================;
%put [06] Marcar el tipo de Debito &Periodo. ;
%put==================================================================================================;

PROC SQL;
CREATE TABLE CASCADA_DEBITO  AS
select distinct A.*, 
CASE 
WHEN (A.BOLETA=T1.BOLETA AND A.LUGAR='.COM') THEN 'CHECK'
WHEN (A.BOLETA=T4.BOLETA AND A.LUGAR='TDA') THEN 'CHECK'

WHEN (A.RUT_CPD=T2.RUT AND A.RUT_CPD>1 AND A.FECHA=T2.FEC_NUM) THEN 'MCD RIPLEY'
WHEN (A.RUT_CPD=T3.RUT AND A.RUT_CPD>1 AND A.FECHA=T3.FEC_NUM) THEN 'DEBITO RIPLEY'
WHEN (A.RUT_CPD=T5.RUT AND A.RUT_CPD>1 AND A.FECHA=T5.fec_num) THEN 'CUENTA CORRIENTE RIPLEY'
ELSE 'OTRAS DEBITO' END AS TIPO_DEBITO
FROM boleta A 
LEFT JOIN  (SELECT DISTINCT BOLETA FROM WORK.DATA_Loyalty_2  WHERE Tda_online='.COM' )t1 ON (A.BOLETA=T1.BOLETA AND A.LUGAR='.COM')
LEFT JOIN  (SELECT DISTINCT BOLETA FROM WORK.DATA_Loyalty_2 WHERE Tda_online='TDA' )t4 ON (A.BOLETA=T4.BOLETA AND A.LUGAR='TDA')

LEFT JOIN  (SELECT DISTINCT rut, fec_num FROM WORK.MOV_CUENTA_VISTA_TDA WHERE Descripcion_Cargo='Compras Redcompra MCD' ) t2 ON (A.RUT_CPD=T2.RUT AND A.FECHA=T2.FEC_NUM)
LEFT JOIN  (SELECT DISTINCT rut, fec_num FROM WORK.MOV_CUENTA_VISTA_TDA WHERE Descripcion_Cargo<>'Compras Redcompra MCD') t3 ON (A.RUT_CPD=T3.RUT AND A.FECHA=T3.FEC_NUM)
LEFT JOIN  (SELECT DISTINCT rut, fec_num FROM WORK.CCTE_FILTRADA ) t5 ON (A.RUT_CPD=T5.RUT AND A.FECHA=T5.fec_num) /* EN REVISION */

WHERE A.DDMFP_COD_FOR_PAG=16
;QUIT;


%put==================================================================================================;
%put [07] Insertar MARCA DE TIPO TARJETA &Periodo. ;
%put==================================================================================================;


PROC SQL noprint;
CREATE INDEX RUT_CPD ON work.DETALLE_ARTICULO_3 (RUT_CPD)
;QUIT;

PROC SQL noprint;
CREATE INDEX FECHA ON work.DETALLE_ARTICULO_3 (FECHA)
;QUIT;

PROC SQL noprint;
CREATE INDEX RUT_CPD ON work.CASCADA_DEBITO (RUT_CPD)
;QUIT;

PROC SQL noprint;
CREATE INDEX FECHA ON work.CASCADA_DEBITO (FECHA)
;QUIT;

proc sql;
create table MARCA_TIPO_TR as 
select A.*, case when A.FORMA_PAGO='DEBITO' then B.TIPO_DEBITO else 'otro' end as TIPO_DEBITO
FROM DETALLE_ARTICULO_3 A 
LEFT JOIN CASCADA_DEBITO B
ON ((A.RUT_CPD=B.RUT_CPD) AND (A.FECHA=B.FECHA) AND (A.BOLETA=B.BOLETA) AND A.DDMFP_COD_FOR_PAG=16)
;quit;


PROC SQL;
CREATE TABLE USO_TR_MARCA_&PERIODO. AS
SELECT *,
CASE WHEN  FORMA_PAGO='DEBITO' THEN TIPO_DEBITO
ELSE FORMA_PAGO END AS MARCA_TIPO_TR
FROM MARCA_TIPO_TR
;QUIT;


%put==================================================================================================;
%put [08] MARCAR VENTAS CON OPEX ;
%put==================================================================================================;

PROC SQL;
CREATE TABLE canjes_opex_online AS 
SELECT distinct CATS(BOLETA,'-',NRO_ITEM) AS LLAVE 
FROM  publicin.OPEX_CANJESOP_&PERIODO.
where Tipo_Codigo<>'CANJE' and Codigo_Sucursal=39 
ORDER BY CALCULATED LLAVE
;QUIT;

DATA canjes_opex_online;
SET  canjes_opex_online;
IF llave=LAG(llave) THEN FILTRO =1; 
ELSE FILTRO=0; 
RUN;

proc sql noprint;
delete *
from canjes_opex_online
where  FILTRO =1;
quit;

PROC SQL;
CREATE TABLE canjes_opex_tda AS 
SELECT DISTINCT CATS(BOLETA,'-',NRO_ITEM) AS LLAVE 
/*
BOLETA, 
Nro_Item, 
Codigo, 
DCTO, 
Fecha, 
Codigo_Sucursal,
*/

FROM  publicin.OPEX_CANJESOP_&PERIODO. 
where Tipo_Codigo<>'CANJE' and Codigo_Sucursal<>39 
ORDER BY CALCULATED LLAVE

;QUIT;

DATA canjes_opex_tda;
SET  canjes_opex_tda;
IF llave=LAG(llave) THEN FILTRO =1; 
ELSE FILTRO=0; 
RUN;

proc sql noprint;
delete *
from canjes_opex_tda
where  FILTRO =1;
quit;


PROC SQL;
CREATE TABLE &libreria..USO_TR_MARCA_&PERIODO. AS
SELECT A.*, 
CASE WHEN ((CATS(A.BOLETA,'-',A.NRO_ITEM)=B.LLAVE) AND (A.SUCURSAL<>39) AND A.MEDIO_PAGO='TAR') THEN 1 ELSE 0 END AS OPEX_TDA,
CASE WHEN ((CATS(A.BOLETA,'-',A.NRO_ITEM)=C.LLAVE)  AND (A.SUCURSAL=39) AND A.MEDIO_PAGO='TAR') THEN 1 ELSE 0 END AS OPEX_ONLINE

FROM USO_TR_MARCA_&PERIODO. A 
LEFT JOIN canjes_opex_tda B 
ON ((CATS(A.BOLETA,'-',A.NRO_ITEM)=B.LLAVE) AND (A.SUCURSAL<>39) AND A.MEDIO_PAGO='TAR')
LEFT JOIN canjes_opex_online C 
ON ((CATS(A.BOLETA,'-',A.NRO_ITEM)=C.LLAVE)  AND (A.SUCURSAL=39) AND A.MEDIO_PAGO='TAR')

WHERE A.Nro_Item>0
;QUIT;


PROC SQL;
CREATE TABLE &libreria..USO_TR_MARCA_&PERIODO. AS
SELECT A.*, 
CASE WHEN A.OPEX_TDA=1 THEN 'OPEX_TDA' WHEN A.OPEX_ONLINE=1  THEN 'OPEX.COM' ELSE 'NO OPEX' END AS OPEX
/*,coalesce(B.SEGMENTO_FINAL,'SIN INFORMACION') AS SEGMENTO*/
FROM &libreria..USO_TR_MARCA_&PERIODO. A 
/*left join NLAGOSG.SEGMENTO_COMERCIAL_&periodo_ant. B on A.RUT=B.RUT */
;QUIT;

proc sql noprint;
drop table Detalle_Vtas_TDA;}
;quit;

proc sql noprint;
drop table DETALLE_ARTICULO
;quit;

proc sql noprint;
drop table DETALLE_ARTICULO_3
;quit;

proc sql noprint;
drop table BOLETA
;quit;

proc sql noprint;
drop table DATA_Loyalty
;quit;

proc sql noprint;
drop table DATA_Loyalty_2
;quit;

proc sql noprint;
drop table SB_MOV_CUENTA_VISTA2
;quit;

proc sql noprint;
drop table MOV_CUENTA_VISTA_TDA
;quit;

proc sql noprint;
drop table CASCADA_DEBITO
;quit;

proc sql noprint;
drop table ARCA_TIPO_TR
;quit;

proc sql noprint;
drop table USO_TR_MARCA_&PERIODO.
;quit;

proc sql noprint;
drop table canjes_opex_online
;quit;

proc sql noprint;
drop table canjes_opex_tda
;quit;


%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_tnda_uso_tr_marca,raw,sasdata,-&i.);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_tnda_uso_tr_marca,&libreria..USO_TR_MARCA_&PERIODO.,raw,sasdata,-&i.);
