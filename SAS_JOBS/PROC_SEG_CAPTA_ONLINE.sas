/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROC_SEG_CAPTA_ONLINE		================================*/
/* CONTROL DE VERSIONES
/* 2022-07-12 -- V04-- Sergio J.    -- Se agrega código de exportación para alimentar a Tableau
/* 2022-04-05 -- V03 -- Esteban P. -- Se actualizan los correos: Se elimina a SEBASTIAN_BARRERA.
/* 2020-07-27 ----	Agregado de nuevo filtro
/* 2020-07-22 ----	Original
*/
/*==================================================================================================*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/


%macro capta_digital(n);

%if %eval(&n.=0) %then %do;
DATA _null_;
INI = input(put(intnx('month',today(),0,'begin'),date9. ),$10.);
FIN = input(put(intnx('day',today(),-1,'same'),date9. ),$10.);
periodo = input(put(intnx('month',today(),0,'end'),yymmn6. ),$10.);
INI_FISA = put(intnx('month',today(),0,'begin'),ddmmyy10.);
FIN_FISA = put(intnx('day',today(),-1,'same'),ddmmyy10.);
Call symput("INI", INI);
Call symput("FIN", FIN);
Call symput("periodo", periodo);
Call symput("INI_FISA", INI_FISA);
Call symput("FIN_FISA", FIN_FISA);
RUN;

DATA _null_;
FIN_retiro = put(intnx('day',"&FIN"d,60,'end'),ddmmyy10.);
Call symput("FIN_retiro", FIN_retiro);
RUN;

%end;

%if %eval(&n.=1) %then %do;
DATA _null_;
INI = input(put(intnx('month',today(),-1,'begin'),date9. ),$10.);
FIN = input(put(intnx('month',today(),-1,'end'),date9. ),$10.);
periodo = input(put(intnx('month',today(),-1,'end'),yymmn6. ),$10.);
INI_FISA = put(intnx('month',today(),-1,'begin'),ddmmyy10.);
FIN_FISA = put(intnx('month',today(),-1,'end'),ddmmyy10.);
Call symput("INI", INI);
Call symput("FIN", FIN);
Call symput("periodo", periodo);
Call symput("INI_FISA", INI_FISA);
Call symput("FIN_FISA", FIN_FISA);
RUN;

DATA _null_;
FIN_retiro = put(intnx('day',"&FIN"d,60,'end'),ddmmyy10.);
Call symput("FIN_retiro", FIN_retiro);
RUN;

%end;

%if %eval(&n.=2) %then %do;
DATA _null_;
INI = input(put(intnx('month',today(),-2,'begin'),date9. ),$10.);
FIN = input(put(intnx('month',today(),-2,'end'),date9. ),$10.);
periodo = input(put(intnx('month',today(),-2,'end'),yymmn6. ),$10.);
INI_FISA = put(intnx('month',today(),-2,'begin'),ddmmyy10.);
FIN_FISA = put(intnx('month',today(),-2,'end'),ddmmyy10.);
Call symput("INI", INI);
Call symput("FIN", FIN);
Call symput("periodo", periodo);
Call symput("INI_FISA", INI_FISA);
Call symput("FIN_FISA", FIN_FISA);
RUN;

DATA _null_;
FIN_retiro = put(intnx('day',"&FIN"d,60,'end'),ddmmyy10.);
Call symput("FIN_retiro", FIN_retiro);
RUN;

%end;


%put &INI; 
%put &FIN;
%put &periodo;
%put &INI_FISA;
%put &FIN_FISA;
%put &FIN_retiro;



PROC SQL ;
CONNECT TO ORACLE AS REPORTITF (PATH="REPORITF.WORLD" USER='KMARTINEZ' PASSWORD='kmar2102');
CREATE TABLE CURSE_credito AS 
SELECT * FROM CONNECTION TO REPORTITF(
SELECT 
DISTINCT TAR.TAR_CAC_NRO_CTT_K NUMERO_CONTRATO, 
TAR.TAR_CAC_NRO_PAN_K NUMERO_TARJETA,
 SOL.SOL_COD_IDE_CLI RUT_CLIENTE, 
SOL.SOL_FCH_ALT_SOL FECHA_SOLICITUD, 
SOL.SOL_COD_NRO_SOL_K NUMERO_SOLICITUD,
sol.sol_cod_est_sol ESTADO, 
SEG.SEG_CAC_SEG_DES GLOSASEGURO
FROM SFADMI_ADM.SFADMI_BCO_SOL SOL 
INNER JOIN SFADMI_ADM.SFADMI_BCO_TAR TAR
ON TAR.TAR_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
LEFT OUTER  JOIN SFADMI_ADM.SFADMI_BCO_SEG_ASC SEG
ON  SOL.SOL_COD_NRO_SOL_K = SEG.SEG_COD_NRO_SOL_K
AND SEG_CAC_SEG_CHK = 1

LEFT OUTER  JOIN SFADMI_ADM.SFADMI_BCO_FIR_DCT_SOL FIR
ON  SOL.SOL_COD_NRO_SOL_K = FIR.FIR_COD_NRO_SOL_K
AND FIR.FIR_COD_FIR_IDE_K BETWEEN 500 AND 600
AND FIR.FIR_COD_SEG_IDE_SEG IS NOT NULL 

WHERE 

SUBSTR(TAR.TAR_COD_TIP_PRD_K,1,2) = '01'
AND SOL_FCH_CRC_SOL BETWEEN to_date(%str(%')&INI_FISA.%str(%'),'dd/mm/yyyy') and 
to_date(%str(%')&fin_FISA.%str(%'),'dd/mm/yyyy')

AND (SOL.SOL_COD_CLL_ACT = 14 OR SOL.SOL_COD_CLL_ANT = 14)
AND SOL.SOL_COD_CLL_ADM = 2
AND EXISTS (SELECT BTC_COD_NRO_SOL_K
FROM SFADMI_ADM.SFADMI_BCO_BTC_SOL
WHERE BTC_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
AND BTC_COD_TIP_REG_K = 1
AND BTC_COD_ETA_K = 102
AND BTC_COD_EVT_K = 30)

ORDER BY  SOL.SOL_COD_NRO_SOL_K ASC
)A
;QUIT;



proc sql;
create table base_credito as 
select distinct  
NUMERO_CONTRATO,
NUMERO_TARJETA,
input(RUT_CLIENTE,best.) as rut,
datepart(FECHA_SOLICITUD) format=date9. as fecha,
ESTADO
from CURSE_credito
;QUIT;



PROC SQL ;
CONNECT TO ORACLE AS REPORTITF (PATH="REPORITF.WORLD" USER='KMARTINEZ' PASSWORD='kmar2102');
CREATE TABLE RETIRO_PLASTICO AS 
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
FROM SFADMI_ADM.SFADMI_BCO_SOL SOL 
INNER JOIN SFADMI_ADM.SFADMI_BCO_TAR TAR
ON TAR.TAR_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K

INNER JOIN FEPCOM_ADM.FEPCOM_MAE_REG_EVT MAE
ON sol.SOL_NRO_INN_IDE  = mae.PCOM_COD_IDE_CLI_K
AND MAE.PCOM_COD_EVT_K in (15, 80, 230)  
and  mae.PCOM_DESC_DOC = sol.sol_cod_ide_cli 
INNER JOIN FEPCOM_ADM.fepcom_det_reg_evt DET
ON mae.PCOM_NRO_SEQ_K = det.PCOM_NRO_SEQ_K and 
det.PCOM_COD_EVT_K in (15, 80, 230)  and 
det.PCOM_NRO_CTT = substr(TAR_CAC_NRO_CTT_K,1,4) || '-' || substr(TAR_CAC_NRO_CTT_K,5,4) || '-' || substr(TAR_CAC_NRO_CTT_K,9,12)
WHERE 

SUBSTR(TAR.TAR_COD_TIP_PRD_K,1,2) = '01'
AND SOL_FCH_CRC_SOL BETWEEN to_date(%str(%')&INI_FISA.%str(%'),'dd/mm/yyyy') and 
to_date(%str(%')&fin_FISA.%str(%'),'dd/mm/yyyy')
and  MAE.PCOM_FCH_K BETWEEN to_date(%str(%')&INI_FISA.%str(%'),'dd/mm/yyyy') and 
to_date(%str(%')&FIN_retiro.%str(%'),'dd/mm/yyyy')
AND (SOL.SOL_COD_CLL_ACT = 14 OR SOL.SOL_COD_CLL_ANT = 14)
AND SOL.SOL_COD_CLL_ADM = 2
AND EXISTS (SELECT BTC_COD_NRO_SOL_K
FROM SFADMI_ADM.SFADMI_BCO_BTC_SOL
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




/*CUENTAS CREADAS debito*/

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
FROM SFADMI_ADM.SFADMI_BCO_SOL SOL 
INNER JOIN SFADMI_ADM.SFADMI_BCO_TAR TAR
   ON TAR.TAR_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
INNER JOIN SFADMI_ADM.SFADMI_BCO_PRD_SOL PRD
   ON TAR.TAR_COD_NRO_SOL_K = PRD.PRD_COD_NRO_SOL_K
   AND TAR.TAR_COD_TIP_PRD_K = PRD.PRD_COD_TIP_PRD_K
INNER JOIN SFADMI_ADM.SFADMI_BCO_DAT_PER PER
   ON PRD.PRD_COD_NRO_SOL_K = PER.PER_COD_NRO_SOL_K
 AND SOL.SOL_COD_IDE_CLI = PER.PER_COD_IDE_CLI_K
WHERE 
 SUBSTR(TAR.TAR_COD_TIP_PRD_K,1,2) = '04'
AND (SOL.SOL_COD_CLL_ACT = 14 OR SOL.SOL_COD_CLL_ANT = 14)
AND SOL.SOL_COD_CLL_ADM = 2
and sol.sol_fch_crc_sol between  to_date(%str(%')&INI_FISA.%str(%'),'dd/mm/yyyy') and 
to_date(%str(%')&fin_FISA.%str(%'),'dd/mm/yyyy')
AND EXISTS (SELECT BTC_COD_NRO_SOL_K
            FROM SFADMI_ADM.SFADMI_BCO_BTC_SOL
            WHERE BTC_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
            AND BTC_COD_TIP_REG_K = 1
            AND BTC_COD_ETA_K = 102
            AND BTC_COD_EVT_K = 30)
ORDER BY  SOL.SOL_COD_NRO_SOL_K ASC
)A
;QUIT;


proc sql;
create table base_debito as 
select distinct 
NUMERO_CONTRATO,
NUMERO_TARJETA,
NUMERO_CUENTA_VISTA,
input(RUT_CLIENTE,best.) as rut,
datepart(FECHA_SOLICITUD) format=date9. as FECHA,
ESTADO
from CURSE_debito
;QUIT;


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
FROM SFADMI_ADM.SFADMI_BCO_SOL SOL
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
 SUBSTR(TAR.TAR_COD_TIP_PRD_K,1,2) = '04'
AND (SOL.SOL_COD_CLL_ACT = 14 OR SOL.SOL_COD_CLL_ANT = 14)
AND SOL.SOL_COD_CLL_ADM = 2

and sol.sol_fch_crc_sol between  to_date(%str(%')&INI_FISA.%str(%'),'dd/mm/yyyy') and 
to_date(%str(%')&fin_FISA.%str(%'),'dd/mm/yyyy')

and MAE.PCOM_FCH_K  between  to_date(%str(%')&INI_FISA.%str(%'),'dd/mm/yyyy') and 
to_date(%str(%')&FIN_retiro.%str(%'),'dd/mm/yyyy')
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

/*generación de base unica rutero*/

proc sql;
create table rutero as 
select 
input(RUT_CLIENTE,best.) as rut
from curse_credito
union
select 
input(RUT_CLIENTE,best.) as rut
from curse_debito
;QUIT;


/*pegado de fecha del cursedel producto*/

proc sql;
create table info as 
select distinct 
a.*,
case when b.rut is not null and substr(b.NUMERO_TARJETA,1,6)='628156' then 'TR' 
when b.rut is not null and substr(b.NUMERO_TARJETA,1,6)<>'628156' then 'TAM' end as TIPO_TR, 
b.NUMERO_CONTRATO as CONTRATO_CREDITO,
b.fecha as FECHA_CREDITO,
B.ESTADO as estado_credito,

c.NUMERO_CUENTA_VISTA as contrato_debito,
c.FECHA	as fecha_debito,
c.estado as estado_debito

from rutero as a
left join base_credito as b
on(a.rut=b.rut)
left join base_debito as c
on(a.rut=c.rut)
;QUIT;

/*pegado del retiro de plastico*/

proc sql;
create table con_retiro as 
select distinct 
a.*,
case when b.rut_cliente is not null then 1 else 0 end as retiro_CREDITO,
min(datepart(b.FECHA_RETIRO)) format=date9. as fecha_retiro_credito,
case when c.rut_cliente is not null then 1 else 0 end as retiro_debito,
min(datepart(c.FECHA_RETIRO)) format=date9. as fecha_retiro_debito
from info as a
left join retiro_plastico as b
on(a.rut=input(b.rut_cliente,best.)) and (a.CONTRATO_CREDITO=b.numero_contrato)
left join retiro_debito as c
on(a.rut=input(c.rut_cliente,best.)) and (a.CONTRATO_debito=c.NUMERO_CUENTA_VISTA)
group by a.rut
;QUIT;
 

proc sql;
create table con_retiro2 as 
select 
*,
case when retiro_CREDITO=1 then 	fecha_retiro_credito-FECHA_CREDITO	end as DIF_CREDITO,
case when retiro_debito=1 then 	fecha_retiro_debito-FECHA_debito	end as DIF_debito
from con_retiro
;QUIT;


proc sql;
create  table con_retiro2 as 
select 
*,
case when retiro_credito=1 and 
year(fecha_retiro_credito)*100+month(fecha_retiro_credito)= 
year(FECHA_CREDITO)*100+month(FECHA_CREDITO) then '01.Mismo Mes' 
when retiro_credito=1 and 
year(fecha_retiro_credito)*100+month(fecha_retiro_credito)<> 
year(FECHA_CREDITO)*100+month(FECHA_CREDITO) then '02.Distinto Mes' end as mismo_mes_credito,

case when retiro_debito=1 and 
year(fecha_retiro_debito)*100+month(fecha_retiro_debito)= 
year(FECHA_debito)*100+month(FECHA_debito) then '01.Mismo Mes' 
when retiro_debito=1 and 
year(fecha_retiro_debito)*100+month(fecha_retiro_debito)<> 
year(FECHA_debito)*100+month(FECHA_debito) then '02.Distinto Mes' end as mismo_mes_debito
from con_retiro2
;QUIT;

proc sql;
create table agrupado as 
select 
&periodo. as PERIODO,
case when estado_credito in (9,11) then '01.Con Pan digital' else '02.Sin Pan digital' end as  ESTADO,
TIPO_TR as TIPO,
mismo_mes_credito as mismo_mes,
FECHA_CREDITO format=date9. as FECHA,
count(rut) as clientes,
sum(retiro_CREDITO) as RETIRO_PLASTICO,
max(case when retiro_CREDITO=1 then DIF_CREDITO end) as MAX_DIA,
min(case when retiro_CREDITO=1 then DIF_CREDITO end ) as MIN_DIA,
floor(AVG(case when retiro_CREDITO=1 then DIF_CREDITO end )) as AVG_DIA
from con_retiro2
where FECHA_CREDITO is not null 
group by 
calculated ESTADO,
TIPO,
mismo_mes,
FECHA
outer union corr 
select 
&periodo. as PERIODO,
case when estado_debito in (9,11) then '01.Con Pan digital' else '02.Sin Pan digital' end as  ESTADO,
'CV' as TIPO,
mismo_mes_debito as mismo_mes,
FECHA_debito format=date9.  as FECHA,
count(rut) as clientes,
sum(retiro_debito) as RETIRO_PLASTICO,
max(case when retiro_debito=1 then DIF_debito end) as MAX_DIA,
min(case when retiro_debito=1 then DIF_debito end ) as MIN_DIA,
floor(AVG(case when retiro_debito=1 then DIF_debito end )) as AVG_DIA
from con_retiro2
where FECHA_debito is not null 
group by 
calculated ESTADO,
TIPO,
mismo_mes,
FECHA
;QUIT;


/*crear tabla */



%if (%sysfunc(exist(result.captados_digital_resumen))) %then %do;
 
%end;
%else %do;

proc sql;
create table result.captados_digital_resumen (

PERIODO  num,
ESTADO  char(99),
TIPO  char(99),
mismo_mes char(99),
FECHA date,
clientes num,
RETIRO_PLASTICO num,
MAX_DIA	num,
MIN_DIA	num ,
AVG_DIA num
)
;QUIT;

%end;


/*borrado*/


proc sqL;
delete *
from result.captados_digital_resumen 
where periodo=&periodo.
;QUIT;



/*insertar*/

proc sqL;
insert into  result.captados_digital_resumen
select 
*
from agrupado
;QUIT;

/*borrado*/

proc sql;
drop table CURSE_credito;
drop table base_credito;
drop table RETIRO_PLASTICO;
drop table RETIRO_DEBITO;
drop table CURSE_debito;
drop table base_debito;
drop table rutero;
drop table info;
drop table con_retiro;
drop table con_retiro2;
drop table agrupado;
;QUIT;

/*subir a tableau*/

/* export data csv */
proc export data=result.captados_digital_resumen
outfile="/sasdata/users94/user_bi/DGTL_CAPTADOS_DIGITAL_RESUMEN.csv"
dbms=dlm
replace;
delimiter="|";
quit;


LIBNAME ORACLOUD ORACLE sql_functions=all  READBUFF=1000  INSERTBUFF=1000  PATH="REPORTSAS.WORLD"  SCHEMA=SAS_ADM authdomain=DBOracleCloud_Auth;

%if (%sysfunc(exist(oracloud.captados_digital_resumen ))) %then %do;
 
%end;
%else %do;
proc sql;
connect using oracloud;
create table  oracloud.captados_digital_resumen (
PERIODO  num,
ESTADO  char(99),
TIPO  char(99),
mismo_mes char(99),
FECHA date,
clientes num,
RETIRO_PLASTICO num,
MAX_DIA	num,
MIN_DIA	num ,
AVG_DIA num
);
disconnect from oracloud;run;
%end;


proc sql;
connect using oracloud;
execute by oracloud ( delete from captados_digital_resumen  where periodo=&periodo.  );
disconnect from oracloud;
;quit;


proc sql; 
connect using oracloud;
insert into   oracloud.captados_digital_resumen (
PERIODO  ,
ESTADO  ,
TIPO  ,
mismo_mes,
FECHA ,
clientes ,
RETIRO_PLASTICO ,
MAX_DIA	,
MIN_DIA	 ,
AVG_DIA )

select 
PERIODO  ,
ESTADO  ,
TIPO  ,
mismo_mes,
DHMS(FECHA,0,0,0) as FECHA format=datetime20.  ,
clientes ,
RETIRO_PLASTICO ,
MAX_DIA	,
MIN_DIA	 ,
AVG_DIA
from result.captados_digital_resumen
where periodo=&periodo.; 
disconnect from oracloud;run;








%mend capta_digital;

%capta_digital(0);
%capta_digital(1);
%capta_digital(2);

data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */



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
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';

SELECT EMAIL into :DEST_2 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';

SELECT EMAIL into :DEST_4 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'CLAUDIA_PAREDES';

SELECT EMAIL into :DEST_5
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JUAN_PABLO_DONOSO';

SELECT EMAIL into :DEST_6 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'RODRIGO_LAIZ';

SELECT EMAIL into :DEST_7
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SUBG_GOBIERNO_DAT';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_4;
%put &=DEST_5;
%put &=DEST_6;
%put &=DEST_7;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_4","&DEST_5","&DEST_6","&DEST_7")
CC = ("&DEST_2")
SUBJECT = ("MAIL_AUTOM: Actualización seguimiento captación digital - &fechaeDVN");
FILE OUTBOX;
PUT "Estimados:";
PUT ; 
 put "Proceso de actualización para seguimiento Captación Digital, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put ; 
 put ; 
 PUT ;
 put 'Proceso Vers. 04';
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
