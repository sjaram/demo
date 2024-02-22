/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	SUSCRIPCIONES_CARGOS_PAT		 ===============================*/
/* CONTROL DE VERSIONES
/* 2023-08-18 -- V07	-- Esteban P.	-- Se añade export para la tabla de RESULT.SUSCRIPCIONES_PAT a AWS.
/* 2022-07-21 -- V06	-- Ignacio P. 	-- Se agrega campo "contrato2 as CUENTA_RSAT2" a tabla de salida. 
/* 2022-07-08 -- V05	-- David V. 	-- Ajustes mínimos, comentarios, correo, versionamiento.
/* 2022-07-08 -- V04	-- Ignacio P. 	-- Cambios en el código
/* 2021-03-29 -- V03	-- Alejandra M. -- Nueva Versión 
										-- Cambios en la lógica del proceso
/* 2020-12-18 -- V02	-- Sergio.J 	-- Nueva Versión Automática Equipo Datos y Procesos BI
										-- SE CAMBIA LIBRERIA DE UNIVERSO PANES DE NLAGOS A "RESULT"

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

DATA _null_;
	datef = input(put(intnx('day',today(),0,'same'),yymmddn8.),$10.);
	per1 = input(put(intnx('month',today(),0,'end'),yymmn6. ),$10.);
	Periodo_FIN = input(put(intnx('month',today(),0,'end'),yymmn6. ),$10.);
	Periodo_INI = input(put(intnx('month',today(),-14,'end'),yymmn6. ),$10.);
	Call symput("fechaf",datef);
	Call symput("per1", per1);
	Call symput("Periodo_FIN", Periodo_FIN);
	Call symput("Periodo_INI", Periodo_INI);

 
RUN;

%let Lib=RESULT;

%put &fechaf;
%put &per1;
%put &Periodo_FIN;
%put &Periodo_INI;

	
/*======================================================================================*/
/* [00] NOMBRES DE COMERCIOS PAT */
/*======================================================================================*/


PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table COMERCIOS  as 
select * 
from connection to ORACLE( 
select 
t1.TGDTG_GLS_CCN_K,
cast(t1.TGDTG_GLS_CCN_K as INT) COD_TG300,
t1.TGDTG_GLS_COO_UNO,
t1.TGDTG_GLS_LAR_UNO,
t1.TGDTG_FCH_ACL_REG,
t1.tgetg_cor_tbl_k,
t2.TGMDO_GLS_DOM 
from botgen_det_tbl_gra t1
LEFT JOIN BOTGEN_MOV_DOM t2
on t1.TGDTG_COD_COO_CIN=t2.TGMDO_COD_DOM_K
WHERE t1.tgetg_cor_tbl_k in (300,320) 
and t2.TGMMD_COD_MAC_DOM_K = 1925
) A
;QUIT;

/*======================================================================================*/
/* [01] SUSCRIPCIONES PAT */
/*======================================================================================*/

LIBNAME BOTGEN ORACLE PATH='REPORITF.WORLD' SCHEMA='BOTGEN_ADM' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME MPDT  ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME SFPACI ORACLE PATH='REPORITF.WORLD' SCHEMA='SFPACI_ADM' USER='SAS_USR_BI ' PASSWORD='SAS_23072020';


PROC SQL NOERRORSTOP ;
CONNECT TO ORACLE (USER='SAS_USR_BI' PASSWORD='SAS_23072020' path ='REPORITF.WORLD' );
create table resumen_pat2 as 
select *
from connection to ORACLE( 
select 
DECODE (MDT.MMDT_COD_SUB_PRD,  1, 'PAC',  2, 'PTR',  3, 'PAT') M_MANDATO, 
DECODE (SVC.DSMDT_COD_FAC,  '1', 'BANCO RIPLEY',  '2', 'EFT',  '3', 'TBK',  '4', 'OTRO',  '5', 'FISA O CAM') S_FACILITADOR,
MDT.MMDT_IDE_MDT_K M_ID_MANDATO, 
SVC.DSMDT_COC_IDE_SVC_K S_ID_SERVICIO,
SVC.DSMDT_COC_CVN_K S_CODCOMERCIO,
DECODE (MDT.MMDT_COD_SUB_PRD
   , '1', 'Pago Servicios con cargo CV BR'
   , '2', 'Pago Servicios con cargo TR'
   , '3', 'Pago Servicios con cargo TAM'
   , '4', 'Pago Credito, TR o TAM con cargo OB'
   , '5', 'Pago credito, TR o TAM con cargo CV BR'
   , '6', 'Pago credito, TC OB con cargo a CV BR')
M_SUBPRODUCTO,
DECODE (MDT.MMDT_NRO_CLL_ING,  '10', 'HB',  '99', 'TBK',  '9', 'PC',  MDT.MMDT_NRO_CLL_ING) M_CANAL_SUSC,
DECODE (MDT.MMDT_FLG_EST_MDT,  1, 'En Proceso',  2, 'Vigente',  3, 'Rechazado',  4, 'Cerrado') AS M_ESTADO, 
TG300.DESTG300 B300_DESCOM,
MDT.MMDT_NRO_RUN M_RUT, 
MDT.MMDT_NRO_CTA_CRO M_CUENTA_RSAT, 
MDT.MMDT_NRO_PAN_CRO M_PAN,
case when length(MDT.MMDT_NRO_PAN_CRO)=18 then substr(MDT.MMDT_NRO_PAN_CRO,3,length(MDT.MMDT_NRO_PAN_CRO)) 
else MDT.MMDT_NRO_PAN_CRO end  M_PAN2, 
MDT.MMDT_FCH_ING_MDT M_FECHA_SUCR,
MDT.MMDT_FCH_ALT_MDT M_FECHA_ALTA,
MDT.MMDT_FCH_BAJ_MDT M_FECHA_BAJA,
MDT.MMDT_FCH_MDC_AUD M_FECHA_MODIF,
MDT.MMDT_FCH_ENV_MDT M_FECHA_ENVIO_A_COMERCIO,
SVC.DSMDT_COC_RBR S_RUBRO,
DECODE (SVC.DSMDT_COD_IDC_MNT,  1, 'PAGO MÍNIMO',  2, 'PAGO TOTAL',  3, 'PAGO LÍMITE',  4, 'PAGO FIJO') S_INDICADOR,
NVL (SVC.DSMDT_MNT_LME, 0) S_MONTO_LIMITE,
NVL (SVC.DSMDT_MNT_FIJ, 0) S_MONTO_FIJO,
DECODE (SVC.DSMDT_FLG_EST_SVC,  '1', 'EN PROCESO',  '2', 'VIGENTE',  '3', 'RECHAZADO',  '4', 'CERRADO',  '99') S_ESTADO, DECODE (MMDT_FLG_ALT_PRD,  'S', 'GRABO EN CRUCE',  'N', 'NO GRABO EN CRUCE',  'NOSE') M_CRUCE_PROD, 
SVC.DSMDT_FCH_RPT_ENV S_FECHA_RESP, 
SVC.DSMDT_FCH_ULT_CRO S_FECHA_ULTCAR, 
SVC.DSMDT_FCH_TER S_FECHA_TERSER, 
SVC.DSMDT_FCH_BAJ_SVC S_FECHA_BAJASER, 
SVC.DSMDT_FCH_MDC_AUD S_FECHA_MODIF,
SVC.DSMDT_GLS_DES_SVC
FROM SFPACI_ADM.SFPACI_MAE_MDT MDT
, SFPACI_ADM.SFPACI_DET_SVC_MDT SVC
, (SELECT TO_NUMBER (TGDTG_GLS_CCN_K) COD_TG300, TGDTG_GLS_LAR_UNO DESTG300
FROM BOTGEN_DET_TBL_GRA
WHERE TGETG_COR_TBL_K = 300) TG300
, (SELECT TGDTG_GLS_COO_UNO COD_TG320, TGDTG_GLS_LAR_CUA DESTG320
FROM BOTGEN_DET_TBL_GRA
WHERE TGETG_COR_TBL_K = 320) TG320
WHERE MDT.MMDT_IDE_MDT_K = SVC.MMDT_IDE_MDT_FK
AND TG300.COD_TG300(+) = SVC.DSMDT_COC_CVN_K
AND TG320.COD_TG320(+) = SVC.DSMDT_COC_CVN_K


ORDER BY MDT.MMDT_FCH_ING_MDT DESC) A
;QUIT;



PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table COMERCIOS  as 
select * 
from connection to ORACLE( 
select 
t1.TGDTG_GLS_CCN_K,
cast(t1.TGDTG_GLS_CCN_K as INT) COD_TG300,
t1.TGDTG_GLS_COO_UNO,
t1.TGDTG_GLS_LAR_UNO,
t1.TGDTG_FCH_ACL_REG,
t1.tgetg_cor_tbl_k,
t2.TGMDO_GLS_DOM 
from botgen_det_tbl_gra t1
LEFT JOIN BOTGEN_MOV_DOM t2
on t1.TGDTG_COD_COO_CIN=t2.TGMDO_COD_DOM_K
WHERE t1.tgetg_cor_tbl_k in (300,320) 
and t2.TGMMD_COD_MAC_DOM_K = 1925
) A
;QUIT;


PROC SQL;
CREATE TABLE Suscripciones_PAT2 AS 
SELECT *,
floor(input(put(datepart(M_FECHA_SUCR),yymmddn8.),best.)/100) as PERIODO_SUSCR,
floor(input(put(datepart(M_FECHA_BAJA),yymmddn8.),best.)/100) as PERIODO_BAJA
from resumen_pat2;
QUIT;


PROC SQL;
CREATE TABLE Suscripciones_PAT AS
SELECT A.*, 
TG300.TGDTG_GLS_CCN_K,
TG300.COD_TG300,
TG300.TGDTG_GLS_COO_UNO,
TG300.TGDTG_GLS_LAR_UNO,
TG300.TGMDO_GLS_DOM ,
TG300.TGDTG_FCH_ACL_REG
FROM Suscripciones_PAT2 A
left join  COMERCIOS as TG300 
ON (input(a.S_CODCOMERCIO,best32.) = TG300.COD_TG300);
QUIT;


PROC SQL;
CREATE TABLE Suscripciones_PAT AS
SELECT A.*, 
COALESCE(TGDTG_GLS_LAR_UNO,DSMDT_GLS_DES_SVC) AS COMERCIO_FIN /*en algunos casos aporta info*/,
CASE WHEN SUBSTR(M_PAN,1,6) IN('628156') THEN 'CERRADA'
WHEN SUBSTR(M_PAN,1,6) IN('549070')AND INPUT(LEFT(SUBSTR(M_PAN,1,7)),BEST.) >=5490702 THEN 'TAM CHIP' 
WHEN SUBSTR(M_PAN,1,6) IN('549070')AND INPUT(LEFT(SUBSTR(M_PAN,1,7)),BEST.) <5490702 THEN 'TAM'
WHEN SUBSTR(M_PAN,1,6) IN('525384') THEN 'MCD'
WHEN SUBSTR(M_PAN,1,4) IN('6392') THEN 'DEBITO'
ELSE 'OTRA' END AS TIPO_TR,
CASE WHEN SUBSTR(M_PAN2,1,6) IN('628156') THEN 'CERRADA'
WHEN SUBSTR(M_PAN2,1,6) IN('549070')AND INPUT(LEFT(SUBSTR(M_PAN2,1,7)),BEST.) >=5490702 THEN 'TAM CHIP' 
WHEN SUBSTR(M_PAN2,1,6) IN('549070')AND INPUT(LEFT(SUBSTR(M_PAN2,1,7)),BEST.) <5490702 THEN 'TAM'
WHEN SUBSTR(M_PAN2,1,6) IN('525384') THEN 'MCD'
WHEN SUBSTR(M_PAN2,1,4) IN('6392') THEN 'DEBITO'
ELSE 'OTRA' END AS TIPO_TR2
FROM Suscripciones_PAT A ;
QUIT;



PROC SQL;
	CREATE TABLE Suscripciones_PAT AS
	SELECT A.*,
	CASE WHEN TIPO_TR NOT IN ('OTRA') THEN M_PAN
	WHEN TIPO_TR2 NOT IN ('OTRA') THEN M_PAN2 ELSE ' ' END AS PAN_FINAL
	FROM Suscripciones_PAT A 
	ORDER BY PAN_FINAL;
QUIT;



PROC SQL;
CREATE TABLE Suscripciones_PAT AS
SELECT A.*,

CASE 
WHEN SUBSTR(PAN_FINAL,1,6) IN('628156') THEN 'CERRADA'
WHEN SUBSTR(PAN_FINAL,1,6) IN('549070') AND INPUT(LEFT(SUBSTR(PAN_FINAL,1,7)),BEST.) >=5490702 THEN 'TAM CHIP' 
WHEN SUBSTR(PAN_FINAL,1,6) IN('549070') AND INPUT(LEFT(SUBSTR(PAN_FINAL,1,7)),BEST.) <5490702 THEN 'TAM'
WHEN SUBSTR(PAN_FINAL,1,6) IN('525384') THEN 'MCD'
WHEN SUBSTR(PAN_FINAL,1,4) IN('6392') THEN 'DEBITO'
ELSE 'OTRA' END AS TIPO_TR_FINAL


FROM Suscripciones_PAT A 
ORDER BY PAN_FINAL;
QUIT;



PROC SQL;
CREATE TABLE Suscripciones_PAT AS
SELECT A.*,B.RUT AS RUT2,
cats(b.codent,b.centalta,b.cuenta) as contrato2
FROM Suscripciones_PAT A LEFT JOIN RESULT.UNIVERSO_PANES B ON A.PAN_FINAL=B.PAN
ORDER BY RUT;
QUIT;


PROC SQL;
CREATE TABLE Suscripciones_PAT2 AS
SELECT 
A.*,
case when rut2 is not null then rut2 else input(substr(M_rut,1,length(M_rut)-1),best.) end as RUT_FIN
FROM Suscripciones_PAT A 
ORDER BY RUT_FIN;
QUIT;


proc sql;
create table suscripciones_pat3 as 
select 
*,
count(M_ID_MANDATO) as cant
from suscripciones_pat2
group by M_ID_MANDATO

;QUIT;



PROC SQL;
CREATE TABLE &lib..Suscripciones_PAT AS
SELECT &fechaf as Fecha_Proceso,
t1.RUT_FIN, 
t1.PERIODO_SUSCR, 
input(put(datepart(M_FECHA_SUCR),yymmddn8.),best.) as FECHA,
t1.PERIODO_BAJA, 
t1.TGDTG_GLS_CCN_K, 
t1.COD_TG300, 
t1.TGDTG_GLS_COO_UNO, 
t1.TGDTG_GLS_LAR_UNO, 
t1.TGMDO_GLS_DOM, 
t1.TGDTG_FCH_ACL_REG, 
M_ID_MANDATO as MMDT_IDE_MDT_K, 
M_MANDATO as MANDATO, 
M_SUBPRODUCTO as SUBPRODUCTO, 
M_CANAL_SUSC as CANAL_SUSC, 
M_CUENTA_RSAT as CUENTA_RSAT, 
M_FECHA_SUCR as FECHA_SUCR, 
M_FECHA_ALTA as  FECHA_ALTA, 
M_FECHA_BAJA as FECHA_BAJA, 
M_FECHA_ENVIO_A_COMERCIO as FECHA_ENVIO_A_COMERCIO, 
CASE WHEN M_FECHA_BAJA IS MISSING THEN 'NO CERRADA' ELSE 'CERRADA' END AS IND_FECHA_BAJA, 
t1.DSMDT_GLS_DES_SVC, 
S_FACILITADOR as FACILITADOR, 
S_CODCOMERCIO as N_IDENTIFICADOR, 
S_RUBRO as RUBRO, 
S_ID_SERVICIO as ID_SERVICIO, 
S_INDICADOR as INDICADOR, 
S_ESTADO as ESTADO, 
 S_MONTO_LIMITE as MONTO_LIMITE,
 S_MONTO_FIJO as MONTO_FIJO, 
t1.COMERCIO_FIN, 
t1.PAN_FINAL, 
t1.TIPO_TR_FINAL,
contrato2 as CUENTA_RSAT2
FROM suscripciones_pat3 t1
ORDER BY PERIODO_SUSCR,RUT_FIN;
QUIT;

/* EXPORT SAS TO AWS */


%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(SAS_MDPG_SUSCRIPCIONES_PAT,raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(SAS_MDPG_SUSCRIPCIONES_PAT,&lib..Suscripciones_PAT,raw,sasdata,0);


PROC SQL;
CREATE TABLE &lib..RESUMEN_SUSCRIPCIONES_PAT AS
SELECT &fechaf as Fecha_Proceso,
TIPO_TR_FINAL,
PERIODO_SUSCR,
PERIODO_BAJA,
IND_FECHA_BAJA,
ESTADO,
CANAL_SUSC,
FACILITADOR,
TGDTG_GLS_LAR_UNO,
TGMDO_GLS_DOM,
COMERCIO_FIN,
COUNT(RUT_FIN) AS N_SUSCRITOS,
(COUNT(DISTINCT(RUT_FIN))) AS N_CLIENTES
FROM &lib..Suscripciones_PAT
GROUP BY
TIPO_TR_FINAL,
PERIODO_SUSCR,
PERIODO_BAJA,
IND_FECHA_BAJA,
ESTADO,
CANAL_SUSC,
FACILITADOR,
TGDTG_GLS_LAR_UNO,
TGMDO_GLS_DOM,
COMERCIO_FIN;
QUIT;



%put==================================================================================================;
%put [02] CARGOS  ;
%put==================================================================================================;


/*CARGOS de TARJETA CERRADA*/


%let path_ora        = '(DESCRIPTION = (ADDRESS_LIST = (ADDRESS =  (PROTOCOL = TCP) (Host = reporteslegales-bd.bancoripley.cl)        (Port = 1521)      )    )    (CONNECT_DATA =       (SID = BORLG)    )  ) '; 
%let user_ora      = 'SAS_USR'; 	
%let pass_ora      = ' sas2020$';	
%let Schema_ora         = 'VERGARAM';	
%let conexion_ora    = ORACLE PATH=&path_ora. Schema=&Schema_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 		
LIBNAME DB_BOLRG     &conexion_ora. insertbuff=10000 readbuff=10000;  



PROC SQL ;
CREATE TABLE WORK.CARGOS AS 
		SELECT INPUT(t1.RUT_CLIENTE, BEST.) AS RUT,
		input(put(datepart(t1.FEC_CARGO),yymmddn8.),best.) as FECHA_CARGO,
		input(put(datepart(t1.FEC_CARGO),yymmddn8.),BEST6.) as PERIODO,
		T1.FEC_CARGO,
		INPUT(t1.ID_SERVICIO, BEST.) AS ID_SERVICIO, 
		t1.ESTADO, 
		t1.NRO_TARJETA AS PAN,
		LEFT(REVERSE(SUBSTR(LEFT(REVERSE(LEFT(CAT('00000000',t1.NRO_TARJETA)))),1,16))) as PAN_V2,
		T1.MEDIO_PAGO,
		T1.GLOS_RETORNO, 
		GLOS_CAUSAL_PAGO,
		COMERCIO,
		t1.MONTO, 
		t1.ESTADO_FINAL
		FROM DB_BOLRG.TABLA_PAT t1
		WHERE T1.ESTADO_FINAL='ACEPTADO' AND input(put(datepart(t1.FEC_CARGO),yymmddn8.),BEST6.)>=&Periodo_INI.


;QUIT;

PROC SQL;
CREATE TABLE WORK.CARGOS_TR AS 
SELECT T1.*, 

CASE 
WHEN SUBSTR(PAN_V2,1,6) IN('628156') THEN 'CERRADA'
WHEN SUBSTR(PAN_V2,1,6) IN('549070') AND INPUT(LEFT(SUBSTR(PAN_V2,1,7)),BEST.) >=5490702 THEN 'TAM CHIP' 
WHEN SUBSTR(PAN_V2,1,6) IN('549070') AND INPUT(LEFT(SUBSTR(PAN_V2,1,7)),BEST.) <5490702 THEN 'TAM'
WHEN SUBSTR(PAN_V2,1,6) IN('525384') THEN 'MCD'
WHEN SUBSTR(PAN_V2,1,4) IN('6392') THEN 'DEBITO'
ELSE 'OTRA' END AS TIPO_TR,

CASE
WHEN COMERCIO= 'pat_CBomb' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_bombero' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_bomberos' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_corpS' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_cuerpob' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_cuerpobo' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_cuerpobom' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_cuerpobomb' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_cuerpodebomber' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_fondoCOAN' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_fondoN' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_fundB' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_fundP' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_fundParent' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_fundR' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_fundacionparentesis' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_help' THEN 'AMBULANCIAS'
WHEN COMERCIO= 'pat_mercu' THEN 'EL  MERCURIO'
WHEN COMERCIO= 'pat_mercurio' THEN 'EL  MERCURIO'
WHEN COMERCIO= 'pat_rostro' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_rostros' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_santander' THEN 'SEGURO'
WHEN COMERCIO= 'pat_servipag' THEN 'SERVIPAG'
WHEN COMERCIO= 'pat_sumate' THEN 'FUNDACIONES'
WHEN COMERCIO= 'pat_unidadC' THEN 'AMBULANCIAS'
WHEN COMERCIO= 'pat_vtrBA' THEN 'TELEFONIA FIJA'
WHEN COMERCIO= 'pat_vtrBAN' THEN 'TELEFONIA FIJA'
WHEN COMERCIO= 'pat_vtrBA' THEN 'VTR'
WHEN COMERCIO= 'pat_vtrBAN' THEN 'VTR'
WHEN COMERCIO= 'ENTEL HOGAR' THEN 'ENTEL'
WHEN COMERCIO= 'FUNDACION GENTE DE LA CAL' THEN 'FUNDACIONES'
WHEN COMERCIO= 'APORTES A CRUZ ROJA' THEN 'FUNDACIONES'
ELSE COMERCIO END AS TGMDO_GLS_DOM,
COMERCIO AS TGDTG_GLS_LAR_UNO
FROM WORK.CARGOS t1
;QUIT;

/*CARGOS de TARJETA TAM, CON APILADOR PARA SERVIDOR*/


DATA _null_;
datex = input(put(intnx('month',today(),-0,'end'),yymmn6. ),$10.);
Call symput("periodo", datex);
RUN;

%put &periodo;
%let ventana_tiempo=14; /*ventana de tiempo hacia atras para ver*/

 
proc sql;
create table CARGOS_PAT_TAM (
periodo num,
FECTRN char(10),
RUT NUM,
PAN CHAR(30), 
TIPO_TR char(10), 
IMPTRN NUM, 
cod_com NUM, 
TGDTG_GLS_LAR_UNO  char(99), 
TGMDO_GLS_DOM   char(99)
)
;QUIT;

 

proc sql inobs=1 noprint;
select 
mdy(mod(int((&periodo.*100+01)/100),100),mod((&periodo.*100+01),100),int((&periodo.*100+01)/10000)) format=date9. as pasito
into
:pasito
from pmunoz.codigos_capta_cdp
;QUIT;

 


%macro APILAR(i,f);

 

%let periodo_iteracion=&i;
%do %while(&periodo_iteracion<=&f); /*inicio del while*/ 

 

%put ############### &periodo_iteracion ################################;

 

DATA _NULL_;
paso = put(intnx('month',"&pasito"d,-&periodo_iteracion.,'end'),yymmn6.);
Call symput("paso",paso);
run;

 

%put &paso;

 

proc sql;
insert into CARGOS_PAT_TAM
select
a.periodo, 
A.FECTRN, 
A.RUT,
A.PAN, 
A.TIPO_TR, 
A.IMPTRN, 
A.cod_com, 
A.TGDTG_GLS_LAR_UNO, 
A.TGMDO_GLS_DOM 
FROM  publicin.CARGOS_PAT_&paso. AS A
;QUIT;

 

%let periodo_iteracion=%sysevalf(&periodo_iteracion. +1);
%end; /*final del while*/

 


%mend APILAR;

 

%APILAR (0,14);

/*************************************************************/



proc sql;
create table &LIB..CARGOS_PAT AS
SELECT
&fechaf as Fecha_Proceso,
A.FECTRN,	
A.PERIODO,			
A.RUT,
A.PAN,	
A.TIPO_TR,			
A.IMPTRN, 		
A.COD_COM,		
A.TGDTG_GLS_LAR_UNO,
A.TGMDO_GLS_DOM
FROM(
SELECT 
input(compress(b.fectrn,"-"),best.) AS FECTRN,	
B.PERIODO,			
B.RUT,
B.PAN,	
B.TIPO_TR,			
B.IMPTRN FORMAT=BEST. AS IMPTRN,			
B.COD_COM,		
B.TGDTG_GLS_LAR_UNO,
B.TGMDO_GLS_DOM
FROM CARGOS_PAT_TAM B
WHERE B.IMPTRN>50
OUTER UNION CORR
SELECT
C.FECHA_CARGO AS FECTRN,	
C.PERIODO,			
C.RUT,
C.PAN,	
C.TIPO_TR,			
C.MONTO AS IMPTRN,			
. AS COD_COM,		
C.TGDTG_GLS_LAR_UNO,
C.TGMDO_GLS_DOM
FROM CARGOS_TR C
WHERE C.MONTO>50

) A
WHERE A.PERIODO>=&PERIODO_INI
;QUIT;

PROC SQL;
CREATE TABLE &lib..RESUMEN_CARGOS AS 
select a.*
from (
(SELECT &fechaf as Fecha_Proceso, 
t1.TGDTG_GLS_LAR_UNO, 
t1.TGMDO_GLS_DOM, 
t1.TIPO_TR, 
t1.PERIODO, 
(SUM(t1.MONTO)) FORMAT=19.0 AS MONTO, 
(COUNT(DISTINCT(t1.RUT))) AS CLIENTES, 
(COUNT(t1.RUT)) AS TRX
FROM CARGOS_TR t1
WHERE T1.MONTO>50
GROUP BY t1.TGDTG_GLS_LAR_UNO,
t1.TGMDO_GLS_DOM,
t1.TIPO_TR,
t1.PERIODO
)
UNION
(SELECT &fechaf as Fecha_Proceso, 
t2.TGDTG_GLS_LAR_UNO, 
t2.TGMDO_GLS_DOM, 
t2.TIPO_TR, 
t2.PERIODO, 
(SUM(t2.IMPTRN)) FORMAT=19.0 AS MONTO, 
(COUNT(DISTINCT(t2.RUT))) AS CLIENTES, 
(COUNT(t2.RUT)) AS TRX
FROM CARGOS_PAT_TAM t2
WHERE T2.IMPTRN>50
GROUP BY t2.TGDTG_GLS_LAR_UNO,
t2.TGMDO_GLS_DOM,
t2.TIPO_TR,
t2.PERIODO
)
) a ORDER BY a.TGMDO_GLS_DOM ASC
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
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_SPOS_1';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SUBG_BI';
	SELECT EMAIL into :DEST_7 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_GOBIERNO_DAT_1';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;	
%put &=DEST_6;	%put &=DEST_7;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4","&DEST_5","&DEST_6","&DEST_7")
CC = ("&DEST_1", "&DEST_2", "&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso SUSCRIPCIONES_CARGOS_PAT");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso SUSCRIPCIONES_CARGOS_PAT, ejecutado con fecha: &fechaeDVN";  
 PUT ;
 PUT ;
 PUT ;
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
