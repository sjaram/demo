/* ------ CONTROL DE VERSIONES ------ */
/* 2023-06-11 -- v04	-- Esteban P.	-- Se cambian credenciales de conexión GEDCRE.
/* 2022-07-22 -- V3  -- Sergio J.  -- Modificación de conexión a Segcom.*/
/* 2022-05-04 -- V2 -- Esteban P. -- Se actualizan los correos: Se elimina a CONSTANZA_CELERY */


%let libreria=RESULT;
options validvarname=any ;

%macro funnel_diario (libreria,n,cierre);


%if %eval(&cierre.=1) %then %DO;
DATA _null;
datef = put(intnx('month',today(),-&N.,'end'),ddmmyy10. );
FIN = put(intnx('MONTH',today(),-&N.,'END'),date9.);
Call symput("fechaf", datef);
Call symput("FIN", FIN);
RUN;
%end;
%else %do;
DATA _null;
datef = put(intnx('month',today(),-&N.,'same'),ddmmyy10. );
FIN = put(intnx('day',today(),&N.-1,'same'),date9.);
Call symput("fechaf", datef);
Call symput("FIN", FIN);
RUN;
%end; 

DATA _null;
date0 = input(put(intnx('month',today(),-&N.,'same'),yymmn6. ),$10.);
date01=input(put(intnx('month',today(),-&N.-1,'same'),yymmn6. ),$10.);
date02=input(put(intnx('month',today(),-&N.-2,'same'),yymmn6. ),$10.);
dated = put(intnx('month',today(),-&N.,'begin'),ddmmyy10.);
INI = put(intnx('MONTH',today(),-&N.,'begin'),date9.);
Call symput("periodo", date0);
Call symput("periodo_ant",date01);
Call symput("periodo_ant2",date02);
Call symput("fechad", dated);
Call symput("ini", ini);
RUN;

%put &periodo; /*PERIODO ACTUAL*/
%put &periodo_ant; /*perido anterior*/
%put &periodo_ant2; /*dos meses atras del periodo que se ejecuta la información*/
%put &fechad;/*FECHA DE INICIO AL PERIODO EN FORMATO FECHA SAS EJEMPLO 01MAY2019*/
%put &ini;
%put &fin;
%put &fechaF;


proc sql noprint;                              
SELECT USUARIO into :USER 
  FROM sasdyp.user_pass WHERE SCHEMA = 'SEGCOM';
SELECT PASSWORD into :PASSWORD 
  FROM sasdyp.user_pass WHERE SCHEMA = 'SEGCOM';
quit;
%put &USER;
%put &PASSWORD;

%let path_ora       = '(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.84.167)(PORT = 1521))(CONNECT_DATA=(SERVER = DEDICATED)(SERVICE_NAME = segcom)))';
%let conexion_ora   = ORACLE PATH=&path_ora. USER=&USER. PASSWORD=&PASSWORD.;
%put &conexion_ora.;

LIBNAME DBLIBORA     &conexion_ora. insertbuff=10000 readbuff=10000;  

LIBNAME CAMP ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="BRTEFGESTIONP.WORLD"  SCHEMA=CAMP_ADM  USER='CAMP_COMERCIAL'  PASSWORD='ccomer2409' ;
LIBNAME credito ODBC  DATASRC=creditoprd  SCHEMA=GEDCRE_CREDITO  USER=CONSULTA_CREDITO  PASSWORD='crdt#0806';
LIBNAME QANEWHB ORACLE  PATH="QANEW.WORLD"  SCHEMA=HBPRI_ADM  USER=RIPLEYC  PASSWORD='ri99pley';


PROC SQL ;
CONNECT TO ORACLE AS CAMPANAS (PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.);
CREATE TABLE actual AS 
SELECT * FROM CONNECTION TO CAMPANAS(
SELECT 
A.CAMP_MOV_ID_K AS IDENTIFICADOR,
A.CAMP_MOV_RUT_CLI as RUT,
A.CAMP_MOV_EST_ACT as EST_OFERTA,
A.CAMP_MOV_COD_CANAL AS CANAL,
A.CAMP_MOV_COD_SUC AS SUCURSAL,
A.CAMP_MOV_FCH_HOR AS FECHA,
b.PRODUCTO,
b.CON_PRODUCTO,
b.MENSAJE,
b.cod_camp,
A.CAMP_MOV_NRO_BOL,
A.CAMP_MOV_MNT_BOL,
A.CAMP_MOV_MNT_DEU_MCC,
A.CAMP_MOV_MTO_DEU_BIC,
A.CAMP_MOV_DET_SBIF_3090,
A.CAMP_MOV_DET_SBIF_90180,
A.CAMP_MOV_DET_SBIF_180MAS,
A.CAMP_MOV_DIAS_MORA_CAR,
A.CAMP_MOV_DIAS_MORA_BCO,
A.CAMP_MOV_MRC_PEP,
A.CAMP_MOV_MRC_LNE,
A.CAMP_MOV_DET_SBIF_3AMAS
from CBCAMP_MOV_TRX_OFE  a
left join (
select 
CAMP_MOV_ID_FK,
CAMD_COD_CAMP cod_camp,
CAMD_TIP_PROD as PRODUCTO,
CAMD_COD_CND_PROD AS CON_PRODUCTO,
CASE  when  CAMD_MSJ_POPUPA IS NOT NULL THEN 1 else 0 END AS MENSAJE 
from cbcamp_mov_det_trx_ofe
where
CAMD_TIP_PROD in ('8','9','300'))  b
on(a.CAMP_MOV_ID_K=b.CAMP_MOV_ID_FK)
where 
TRUNC(a.CAMP_MOV_FCH_HOR) between to_date(%str(%')&fechad.%str(%'),'dd/mm/yyyy') and 
to_date(%str(%')&fechaf.%str(%'),'dd/mm/yyyy')

and a.CAMP_MOV_COD_CANAL in (1,4,9,3,11)
order by a.CAMP_MOV_ID_K
)A
;QUIT;

PROC SQL;
CREATE TABLE VTA_BOL AS
SELECT
t1.DDMCT_RUT_CLI AS RUT,
t1.DDMFP_COD_FOR_PAG  as FORMA_PAGO,
t1.DCMCT_MNT_TRN as monto_boleta,
T1.DDMTD_FCH_DIA AS FECHA
FROM CREDITO.DCRM_COS_MOV_TRN_VTA_BOL t1
WHERE DDMSU_COD_NEG=1
AND DCMCT_COD_PRD=1
AND DCMCT_COD_TRN NOT IN(39,401,402,89,90,93)
AND DDMSU_COD_SUC NOT IN (10993,10990,10039)
AND DDMTD_FCH_DIA BETWEEN YEAR("&ini"D)*10000+MONTH("&ini"D)*100+DAY("&ini"D) 
AND YEAR("&fin"D)*10000+MONTH("&fin"D)*100+DAY("&fin"D)
AND DCMCT_COD_TIP_TRN IN (1) /*1 compras, 3 notas de credito*/
;QUIT;


%if (%sysfunc(exist(rfonseca.CAPTA_cdp_&periodo.))) %then %do;
PROC SQL NOERRORSTOP ; /*si encunetra un erro que siga ejecutando la sintaxis*/
CREATE TABLE RESUMEN_OFERTA AS 
SELECT 
RUT,
prod_comerc AS PRODUCTO,
CAMP_COD_CAMP_FK AS CAMP,
CUPO,
tipo_cliente 
FROM rfonseca.CAPTA_cdp_&periodo.

;RUN; 
%end;
%else %do;
PROC SQL;
CREATE TABLE RESUMEN_OFERTA AS 
SELECT 
RUT,
prod_comerc AS PRODUCTO,
CAMP_COD_CAMP_FK AS CAMP,
CUPO,
tipo_cliente
FROM rfonseca.CAPTA_cdp_&periodo_ant.

;RUN;
%end;


%if (%sysfunc(exist(PUBLICIN.LCA_&periodo_ant.))) %then %do;
PROC SQL NOERRORSTOP ; 
CREATE TABLE LCA AS 
SELECT RUT, 
MAX(LIMCRELNA) AS CUPO 
FROM PUBLICIN.LCA_&periodo_ant.
GROUP BY RUT
;RUN; 
%end;
%else %do;
PROC SQL;
CREATE TABLE LCA AS 
SELECT RUT, 
MAX(LIMCRELNA) AS CUPO 
FROM PUBLICIN.LCA_&periodo_ant2.
GROUP BY RUT
;RUN;
%end;


PROC SQL;
CREATE TABLE RESUMEN_OFERTA2 AS 
SELECT distinct
A.RUT,
A.PRODUCTO,
case when  camp like '%ADC%' then '01.AUMENTO DE CUPO'
WHEN CAMP LIKE '%DOR%' THEN '02.DORMIDO'
WHEN CAMP LIKE '%FUN%' THEN '03.FUNCIONARIO'
WHEN CAMP LIKE '%NORM%' THEN '04.NORMAL'
WHEN CAMP LIKE '%BLOQ%' THEN '05.BLOQUEADO'
WHEN CAMP LIKE '%CERR%' THEN '06.CERRADO'
WHEN CAMP LIKE '%NUEV%' THEN '07.NUEVO'
WHEN CAMP LIKE '%NVP%' THEN '08.CUPO 1MM-2MM'
ELSE '09.PILOTO/NOVEDAD' END AS CAMPANA,
CASE WHEN  b.rut is not null and a.cupo=0 and a.camp not like '%ADC%' then b.cupo
ELSE A.CUPO END AS CUPO,
CASE WHEN CALCULATED CUPO<50000 THEN '01.[0M,50M[' 
WHEN CALCULATED  CUPO=50000 THEN '02.50M'
WHEN CALCULATED  CUPO BETWEEN 50001 AND 99999 THEN '03.]50M,100M['
WHEN CALCULATED  CUPO BETWEEN 100000 AND 149999 THEN '04.[100M,150M['
WHEN CALCULATED  CUPO BETWEEN 150000 AND 199999 THEN '05.[150M,200M['
WHEN CALCULATED  CUPO=200000 THEN '06.200M'
WHEN CALCULATED  CUPO BETWEEN 200001 AND 249999 THEN '07.]200M,250M['
WHEN CALCULATED  CUPO BETWEEN 250000 AND 299999 THEN '08.[250M,300M['
WHEN CALCULATED  CUPO BETWEEN 300000 AND 349999 THEN '09.[300M,350M['
WHEN CALCULATED  CUPO BETWEEN 350000 AND 399999 THEN '10.[350M,400M['
WHEN CALCULATED  CUPO BETWEEN 400000 AND 449999 THEN '11.[400M,450M['
WHEN CALCULATED  CUPO BETWEEN 450000 AND 499999 THEN '12.[450M,500M['
WHEN CALCULATED  CUPO BETWEEN 500000 AND 999999 THEN '13.[500M,1MM['
WHEN CALCULATED  CUPO>=1000000 THEN '14.>1MM' 
else '15.SIN OFERTA' END AS CUPO_INTERVALO,
tipo_cliente
FROM RESUMEN_OFERTA AS A
LEFT JOIN LCA AS B
ON(A.RUT=B.RUT)
;quit;


PROC SQL;
CREATE TABLE ACT_TR AS 
SELECT 
RUT,
ACTIVIDAD_TR,
VU_RIESGO,
case when MARCA_BASE in ('ITF','CREDITO_2000') THEN 'TR' ELSE 'TAM' END AS MARCA_BASE
FROM PUBLICIN.ACT_TR_&periodo_ant2.
;quit;


%put ######## castigos historicos riesgo ##################; 

proc sql noprint ;
select 
count(rut) as pivote
into:pivote
from rfonseca.castigos_historicos 
where periodo_campaña=&periodo.
;QUIT;

%put &pivote;

%macro CASTIGOS;
%if %eval(&pivote.>0) %then %do;
proc sql ;
create table castigo as 
select 
rut 
from rfonseca.castigos_historicos 
where periodo_campaña=&periodo.
;quit; 
%end;

%else %do;

proc sql noprint ;
select 
count(rut) as pivote2
into:pivote2
from rfonseca.castigos_historicos 
where periodo_campaña=&periodo_ant.
;QUIT;

%if %eval(&pivote2.>0) %then %do;
proc sql ;
create table castigo as 
select 
rut 
from rfonseca.castigos_historicos 
where periodo_campaña=&periodo_ant.
;quit; 
%end;

%else %do;
proc sql ;
create table castigo 
(rut num)
;quit; 
%end;


%end;
%mend CASTIGOS;
%CASTIGOS;



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
where upper(Nombre_Tabla) like 'PUBLICIN.CONTRATO_RUT_%' 
and length(Nombre_Tabla)=length('PUBLICIN.CONTRATO_RUT_201810')
) as x
;QUIT;

data _null_ ;
per_DOT=put(&Max_anomes,$6.);
Call symput('per_DOT',per_DOT);
run;
%put &per_DOT;

proc sql;
create table act_tr_bi as 
select distinct 
rut 
from PUBLICIN.CONTRATO_RUT_&per_DOT.
where input(compress(FECALTA,'-','p'),best.)<&periodo.*100+01
;QUIT;


proc sql;
create table TV1 as 
select distinct rut,
count(rut) as cantidad,
count(case when monto_boleta=1 then rut end) as COMPRA_1P,
case when (rut between 1000000 and 50000000) and rut not in (1111111,2222222,3333333,4444444,5555555,
6666666,7777777,8888888,9999999,11111111,22222222,33333333,44444444) then 1 else 0 end as HUMANO,
fecha 
from vta_bol

group by rut, fecha
;QUIT;


/*
DATA _null_;
date0 = input(put(intnx('month',today(),&N-3,'same'),yymmn6. ),$10.);
Call symput("periodo_r04", date0);

RUN;*/

 /* siempre se trabajara con la ultima tabla disponible */
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
where upper(Nombre_Tabla) like 'PUBLICRI.R04_%' 
and length(Nombre_Tabla)=length('PUBLICRI.R04_202203')
) as x
;QUIT;

data _null_ ;
periodo_r04=put(&Max_anomes,$6.);
Call symput('periodo_r04',periodo_r04);
run;
%put &periodo_r04; /*UTLIMO PERIODO DISPONIBLE*/



PROC SQL;
CREATE TABLE TV2 AS 
SELECT A.*,
case when b1.rut is not null AND B1.ACTIVIDAD_TR like '%DORMIDO%' THEN 1 ELSE 0 END AS DORMIDO,
case when b1.rut is not null and b1.actividad_tr='ANTIGUO SIN USO' THEN 1 ELSE 0 END AS ANTIGUO_SIN_USO,
CASE WHEN  B1.RUT IS NOT NULL AND b1.vu_riesgo =1 THEN 1 ELSE 0 END AS VU,

case when calculated vu=0 and a.humano=1  AND B1.ACTIVIDAD_TR not in ('ACTIVO','SEMIACTIVO','OTROS CON SALDO') then 1 
WHEN B1.ACTIVIDAD_TR like '%DORMIDO%' AND b1.vu_riesgo =1 and a.humano=1 and B1.ACTIVIDAD_TR not in ('ACTIVO','SEMIACTIVO','OTROS CON SALDO') THEN 1 
WHEN b1.actividad_tr='ANTIGUO SIN USO' AND b1.vu_riesgo =1 and a.humano=1 AND B1.ACTIVIDAD_TR not in ('ACTIVO','SEMIACTIVO','OTROS CON SALDO')THEN 1 
else 0 end as UOF_CAPTA,

case when ((b1.rut is null)  or (d.rut is not null) ) and calculated uof_capta=1 then 1 else 0 end as UOF_NUEVOS,
CASE when b1.rut is not null and b1.actividad_TR in ('DORMIDO BLANDO', 
'DORMIDO DURO','NUEVO SIN USO' , 'ANTIGUO SIN USO')  and calculated uof_nuevos=0  and calculated uof_capta=1 THEN 1 ELSE 0 end as UOF_DORMIDOS,

case when calculated UOF_CAPTA=0 and calculated vu=1 and  B1.ACTIVIDAD_TR='ACTIVO' and a.humano=1 then 1 else 0 end as NO_UOF_CAPTA_VU_ACTIVO,
case when calculated UOF_CAPTA=0 and calculated vu=1 and  B1.ACTIVIDAD_TR='SEMIACTIVO' and a.humano=1 then 1 else 0 end as NO_UOF_CAPTA_VU_semi,
case WHEN calculated UOF_CAPTA=0 AND (B1.ACTIVIDAD_TR not like '%DORMIDO%' and b1.actividad_tr<>'ANTIGUO SIN USO') AND b1.vu_riesgo =1 and a.humano=1  THEN 1
else 0 end as NO_UOF_CAPTA_NO_DORMIDO, 
  /*
CASE WHEN B1.RUT IS NOT NULL AND B1.VU_RIESGO=1 and a.humano=1 AND B1.MARCA_BASE= 'TR' THEN 1
 ELSE 0 END AS UOF_CDP,*/
 CASE WHEN e.RUT IS NOT NULL AND b1.marca_base in ('TR') and b1.actividad_TR in ('DORMIDO BLANDO', 
'DORMIDO DURO','NUEVO SIN USO' , 'ANTIGUO SIN USO','ACTIVO')   THEN 1 ELSE 0 END AS UOF_CDP,

case when b1.rut is not null and b1.vu_riesgo=0 and a.humano=1 and b1.marca_base='TR' then 1 else 0 end as NO_UOF_CDP1,
case when b1.rut is not null and b1.vu_riesgo>0 and a.humano=1 and b1.marca_base='TAM' then 1 else 0 end as NO_UOF_CDP2,
case when b1.rut is null then 1 else 0 end as NO_UOF_CDP3,

case when a.humano=0 then 1 else 0 end as no_uof_rut,
case when  b2.rut is not null  then b2.producto else 'SIN OFERTA'  END AS CON_OFERTA,
CASE WHEN B2.RUT IS NOT NULL THEN B2.CUPO_INTERVALO ELSE '15.SIN OFERTA' END AS CUPO,
CASE WHEN B2.RUT IS NOT NULL THEN B2.CAMPANA ELSE '10.SIN OFERTA' END AS CAMPANA,

coalesce(c.DEUDA_MOROSA_30_90,0) as r04_MOROSA_30_90,
coalesce(c.DEUDA_DIRECTA_VENCIDA,0) as r04_DIRECTA_VENCIDA,
coalesce(c.DEUDA_INVERSIONES_FINANCIERAS,0) as r04_INVERSIONES_FINANCIERAS,
coalesce(c.SALDO_DEUDA_CASTIGADA_DIRECTA ,0) as r04_CASTIGADA_DIRECTA,
coalesce(c.SALDO_DEUDA_CASTIGADA_INDIRECT, 0) as r04_CASTIGADA_INDIRECT,
case when c1.rut is not null then 1 else 0 end as LNEGRO,
case when c2.rut is not null  then 1 else 0 end as MORA_SINACOFI,
b2.tipo_cliente

FROM TV1 AS A
LEFT JOIN ACT_TR AS B1
ON(A.RUT=B1.RUT)
LEFT JOIN RESUMEN_OFERTA2 AS B2
ON(A.RUT=B2.RUT)
left join publicri.r04_&periodo_r04. as c
on(a.rut=c.rut)

left join (select DISTINCT  rut from publicin.lnegro_car where TIPO_INHIBICION <>'PEP') as c1
on(a.rut=c1.rut)
left join (SELECT DISTINCT RUT FROM publicin.mora_sinacofi WHERE MORA_CONSOLIDADA>=10000) as c2
on(a.rut=c2.rut)
left join castigo as d
on (a.rut=d.rut)
left join ACT_TR_bi as e 
on (a.rut=e.rut)
;quit;

proc sql;
create table LNEGRO as 
select 
distinct rut 
from PUBLICIN.LNEGRO_CAR
WHERE TIPO_INHIBICION in ('COMPLIANCE','FALLECIDO',
'FALLECIDOS','LRI','SIR')
;QUIT;


PROC SQL;
CREATE TABLE TV3 AS 
SELECT A.*,
CASE WHEN B.RUT IS NULL or c.estado_cuenta='cerrado'  THEN 1 
when c.rut is not null and floor(c.Fecha_Apertura/100)=&periodo. then 1 
ELSE 0 END AS UOF_CV
FROM TV2 AS A
LEFT JOIN LNEGRO AS B
ON(A.RUT=B.RUT)
LEFT JOIN RESULT.CTAVTA1_STOCK AS C
ON(A.RUT=C.RUT)
;quit;



PROC SQL;
CREATE TABLE CRUCE AS 
SELECT *,
CASE WHEN PRODUCTO='300' AND MENSAJE IS NOT NULL THEN 1 ELSE 0 END AS CV,
CASE WHEN PRODUCTO<>'300' AND MENSAJE IS NOT NULL THEN 1 ELSE 0 END AS TARJETA,
 case when CAMP_MOV_MNT_DEU_MCC>10000 THEN 1 ELSE 0 end as DEU_MCC,
 case when CAMP_MOV_MTO_DEU_BIC>10000 THEN 1 ELSE 0 end as DEU_BIC,
case when CAMP_MOV_MNT_DEU_MCC+CAMP_MOV_MNT_DEU_MCC>10000 THEN 1 ELSE 0 end as MONTO_MORA,
case when CAMP_MOV_DET_SBIF_3090>0 THEN 1 ELSE 0 end  as DET_SBIF_3090,
case when CAMP_MOV_DET_SBIF_90180>0	THEN 1 ELSE 0 end as DET_SBIF_90180,
 case when CAMP_MOV_DET_SBIF_180MAS>0 THEN 1 ELSE 0 end as DET_SBIF_180MAS,
 case when CAMP_MOV_DET_SBIF_3AMAS>0 THEN 1 ELSE 0 end as DET_SBIF_3AMAS,


 case when CAMP_MOV_DIAS_MORA_CAR>0 THEN 1 ELSE 0 end as DIAS_MORA_CAR,
 case when CAMP_MOV_DIAS_MORA_BCO>0 THEN 1 ELSE 0 end as DIAS_MORA_BCO,
 datepart (fecha) format=date9. as fecha_2


FROM actual
where CANAL=1
and rut not in (1111111,2222222,3333333,4444444,5555555,6666666,7777777,8888888,9999999,
11111111,22222222,33333333,44444444)
;quit;


proc sqL;
CREATE TABLE COLAPSO_CRUCE AS 
SELECT DISTINCT 
RUT,
COUNT(CASE WHEN TARJETA=1 THEN RUT END ) AS SALTA_TARJETA,
COUNT(CASE WHEN CV=1 THEN RUT END ) AS SALTA_CV,
COUNT (CASE WHEN EST_OFERTA IN (15,6000)  AND TARJETA=1 THEN RUT END) AS ACEPTA_TARJETA,
COUNT (CASE WHEN EST_OFERTA IN (15,6000)  and cv=1 THEN RUT END) AS ACEPTA_CV,
COUNT( distinct case when  DEU_MCC=1 then rut end) as DEU_MCC,
COUNT(distinct case when  DEU_BIC=1 then rut end) as DEU_BIC,
COUNT(distinct case when  MONTO_MORA=1 then rut end) as MONTO_MORA,
COUNT(distinct case when  DET_SBIF_3090=1 then rut end) as DET_SBIF_3090,
COUNT(distinct case when  DET_SBIF_90180=1 then rut end) as DET_SBIF_90180,
COUNT(distinct case when  DET_SBIF_180MAS=1 then rut end) as DET_SBIF_180MAS,
COUNT(distinct case when  DET_SBIF_3AMAS=1 then rut end) as DET_SBIF_3AMAS,
COUNT(distinct case when  DIAS_MORA_CAR=1 then rut end) as DIAS_MORA_CAR,
COUNT(distinct case when  DIAS_MORA_BCO=1 then rut end) as DIAS_MORA_BCO,
year(fecha_2)*10000+month(fecha_2)*100+day(fecha_2) as fecha 

FROM CRUCE
where rut is not null
GROUP BY RUT, calculated fecha 
;quit;


proc sql;
create table TV4 as 
select distinct 
a.*,
CASE WHEN B2.RUT IS NOT NULL AND B2.SALTA_TARJETA>0 THEN 1 ELSE 0 END AS SALTA_POPUP_TARJETA,
CASE WHEN B2.RUT IS NOT NULL AND B2.SALTA_CV>0 THEN 1 ELSE 0 END AS SALTA_POPUP_CV,
CASE WHEN B2.RUT IS NOT NULL AND B2.ACEPTA_TARJETA>0 THEN 1 ELSE 0 END AS ACEPTA_OFERTA_TARJETA,
CASE WHEN B2.RUT IS NOT NULL AND B2.ACEPTA_CV>0 THEN 1 ELSE 0 END AS ACEPTA_OFERTA_CV,
coalesce(b2.DEU_MCC,0) as DEU_MCC,
coalesce(b2.DEU_BIC,0) as DEU_BIC,
coalesce(b2.MONTO_MORA,0) as MONTO_MORA,
coalesce(b2.DET_SBIF_3090,0) as DET_SBIF_3090,
coalesce(b2.DET_SBIF_90180,0) as DET_SBIF_90180,
coalesce(b2.DET_SBIF_180MAS,0) as DET_SBIF_180MAS,
coalesce(b2.DET_SBIF_3AMAS,0) as DET_SBIF_3AMAS,
coalesce(b2.DIAS_MORA_CAR,0) as DIAS_MORA_CAR,
coalesce(b2.DIAS_MORA_BCO,0) as DIAS_MORA_BCO
from TV3 as a 
left join COLAPSO_CRUCE as b2
on(a.rut=b2.rut) and (a.fecha=b2.fecha)
;QUIT;


proc sql;
create table admision as 
select DISTINCT 
RUT,
datepart(fecha) format date9. as fecha_2,
year(calculated fecha_2)*10000+month(calculated fecha_2)*100+day(calculated fecha_2) as fecha 
from actual  as A
where 
CANAL=4
;QUIT; 

proc sql;
create table admision_MOVIL as 
select DISTINCT 
RUT ,
datepart(fecha) format date9. as fecha_2,
year(calculated fecha_2)*10000+month(calculated fecha_2)*100+day(calculated fecha_2) as fecha 
from actual  as A
where 
CANAL=9 AND EST_OFERTA=822
;QUIT; 

proc sql;
create table TV5 as 
select a.*,
case when  b.rut is not null then 1 else 0 end as admision,
CASE WHEN C.RUT IS NOT NULL THEN 1 ELSE 0 END AS ADMISION_MOVIL
from TV4 as a
left join admision as b
on(a.rut=B.RUT) and (a.fecha=b.fecha)
LEFT JOIN ADMISION_MOVIL AS C
ON(A.RUT=C.RUT) and (a.fecha=c.fecha)
;quit;

PROC SQL; 
CREATE TABLE captado AS 
SELECT 
RUT_CLIENTE AS RUT,
PRODUCTO,
ORIGEN,
CANAL,
year(FECHA)*10000+month(fecha)*100+day(fecha) as fecha 
FROM RESULT.capta_salida 
WHERE FECHA >= "&ini."D
AND fecha<="&fin."D
AND COD_CANAL=1  
and origen='CORE'
and cod_sucursal<>39
and via<>'HOMEBAN'
;QUIT; 


PROC SQl;
CREATE TABLE TV6 AS 
SELECT distinct A.*,
CASE WHEN  B.RUT IS NOT NULL AND B.PRODUCTO IN ('TAM','TR')  THEN 1 ELSE 0 END AS CAPTADO_TARJ,
CASE WHEN  B.RUT  IS NOT NULL AND B.PRODUCTO IN ('CAMBIO DE PRODUCTO')  THEN 1 ELSE 0 END AS CAPTADO_CDP,
CASE WHEN  B.RUT  IS NOT NULL AND B.PRODUCTO IN ('CUENTA VISTA')  THEN 1 ELSE 0 END AS CAPTADO_CV,
CASE WHEN  B.RUT IS NOT NULL  AND B.PRODUCTO IN ('TAM','TR','CAMBIO DE PRODUCTO') THEN B.ORIGEN ELSE 'SIN INFORMACION' END AS ORIGEN_CAPTA_TARJETA,
CASE WHEN  B.RUT IS NOT NULL AND B.PRODUCTO IN  ('CUENTA VISTA') THEN B.ORIGEN ELSE 'SIN INFORMACION' END AS ORIGEN_CAPTA_CV
FROM TV5 AS A
LEFT JOIN CAPTADO AS B
ON(A.RUT=B.RUT) and (a.fecha=b.fecha)
;quit;

PROC SQL;
CREATE TABLE PROPENSION AS 
SELECT A.RUT,
COUNT(CASE WHEN B.FORMA_PAGO=3 AND B.FECHA>=a.fecha THEN B.RUT END) AS COMPRA_MES,
COUNT(CASE WHEN B.FORMA_PAGO=3 AND B.FECHA=a.fecha THEN B.RUT END) AS COMPRA_DIA
FROM CAPTADO AS A
LEFT JOIN VTA_BOL AS B
ON(A.RUT=B.RUT)
WHERE A.PRODUCTO IN ('TAM','TR','CAMBIO DE PRODUCTO')
GROUP BY
A.RUT
;quit;


PROC SQL;
CREATE TABLE funnel_TV_diario_&periodo. AS 
SELECT distinct A.*,
CASE WHEN  B.RUT IS NOT NULL AND B.COMPRA_MES>0 THEN 1 ELSE 0 END AS CONCRETA_MES,
CASE WHEN B.RUT IS NOT NULL AND B.COMPRA_DIA>0 THEN 1 ELSE 0 END AS CONCRETA_DIA,
put(fecha,best.) as fecha2
FROM TV6 AS A
LEFT JOIN PROPENSION AS B
ON(A.RUT=B.RUT)
;quit;



proc sql;
create table colapso_TV_diario_&periodo. as  
select
&periodo. as periodo, 
CON_OFERTA  AS OFERTA, 
CUPO, 
ORIGEN_CAPTA_TARJETA as origen_capta, 
DORMIDO, 
ANTIGUO_SIN_USO, 
CAMPANA,
VU, 
sum(cantidad) as TRX_TOTAL, 
sum(CASE WHEN humano=1 THEN cantidad END)-sum(CASE WHEN HUMANO=1 THEN COMPRA_1P END) AS DIG, 
SUM(HUMANO) AS DIG_UNICAS, 
count(case when HUMANO=1 and CON_OFERTA  in ('TAM','TR','TR-SE') then rut end) as oferta_RIESGO,
count(case when humano=1  AND  (UOF_CAPTA=1 ) then rut end) AS UOF, 

count(case when HUMANO=1 and CON_OFERTA  not in ('TAM','TR','TR-SE')
and (UOF_CAPTA=1 ) and (r04_MOROSA_30_90+
r04_DIRECTA_VENCIDA+
r04_INVERSIONES_FINANCIERAS+
r04_CASTIGADA_DIRECTA+
 r04_CASTIGADA_INDIRECT>0 or	MORA_SINACOFI>0) 
then rut end) as NO_oferta_mora_protesto,

 count(case when HUMANO=1 and CON_OFERTA  not in ('TAM','TR','TR-SE')
and (UOF_CAPTA=1 ) and r04_MOROSA_30_90+
r04_DIRECTA_VENCIDA+
r04_INVERSIONES_FINANCIERAS+
r04_CASTIGADA_DIRECTA+
 r04_CASTIGADA_INDIRECT=0 and LNEGRO=1 and 	MORA_SINACOFI=0  then rut end ) as No_oferta_lnegro,

  count(case when HUMANO=1 and CON_OFERTA  not in ('TAM','TR','TR-SE')
and (UOF_CAPTA=1 ) and r04_MOROSA_30_90+
r04_DIRECTA_VENCIDA+
r04_INVERSIONES_FINANCIERAS+
r04_CASTIGADA_DIRECTA+
 r04_CASTIGADA_INDIRECT=0 and LNEGRO=0 and 	MORA_SINACOFI=0  then rut end ) as No_oferta_riesgo,

count(case when humano=1 and (UOF_CAPTA=0) and NO_UOF_CAPTA_VU_ACTIVO=1 then rut end ) as NO_UOF_1,
count(case when humano=1 and (UOF_CAPTA=0) and NO_UOF_CAPTA_VU_semi=1 then rut end ) as NO_UOF_2,
count(case when humano=1 and (UOF_CAPTA=0) and  NO_UOF_CAPTA_VU_ACTIVO+NO_UOF_CAPTA_VU_semi=0 then rut end ) as NO_UOF_3,
 
SUM(case when humano=1    AND CON_OFERTA in ('TAM','TR','TR-SE') then SALTA_POPUP_TARJETA end )  AS SALTA_POPUP, 

count(case when 
 humano=1 
AND  CON_OFERTA  in ('TAM','TR','TR-SE')
and SALTA_POPUP_TARJETA=0 and 
DEU_MCC+
DEU_BIC+
MONTO_MORA+
DET_SBIF_3090+
DET_SBIF_90180+
DET_SBIF_180MAS+
DET_SBIF_3AMAS+
DIAS_MORA_CAR+
DIAS_MORA_BCO=0 then rut end ) as NO_POPUP_LN,

count(case when 
 humano=1 
AND CON_OFERTA and CON_OFERTA  in ('TAM','TR','TR-SE')
and SALTA_POPUP_TARJETA=0 and 

DET_SBIF_3090+
DET_SBIF_90180+
DET_SBIF_180MAS+
DET_SBIF_3AMAS>0
 then rut end ) +

 count(
case when 
 humano=1 
AND CON_OFERTA and CON_OFERTA  in ('TAM','TR','TR-SE')
and SALTA_POPUP_TARJETA=0 and 
DEU_MCC+
DEU_BIC+
MONTO_MORA+
DIAS_MORA_CAR+
DIAS_MORA_BCO>0
and 
DET_SBIF_3090+
DET_SBIF_90180+
DET_SBIF_180MAS+
DET_SBIF_3AMAS=0 then rut end ) as NO_popup_MORA,

SUM(case when humano=1   AND CON_OFERTA NOT IN ('CDP-NORM','CDP-ADC','CDP','CDP-Nuev','CDP-PRUE') and SALTA_POPUP_TARJETA=1 then ACEPTA_OFERTA_TARJETA end ) AS ACEPTA_OFERTA, 
SUM( case when humano=1   AND CON_OFERTA NOT IN ('CDP-NORM','CDP-ADC','CDP','CDP-Nuev','CDP-PRUE') and SALTA_POPUP_TARJETA=1 and ACEPTA_OFERTA_TARJETA=1 then ADMISION end) AS ACEPTACION_REAL_ADM, 
SUM( case when humano=1   AND CON_OFERTA NOT IN ('CDP-NORM','CDP-ADC','CDP','CDP-Nuev','CDP-PRUE') and SALTA_POPUP_TARJETA=1 and ACEPTA_OFERTA_TARJETA=1  AND ADMISION=0 then ADMISION_MOVIL end) AS ACEPTACION_REAL_MOVIL, 


SUM(case when humano=1   AND CON_OFERTA NOT IN ('CDP-NORM','CDP-ADC','CDP','CDP-Nuev','CDP-PRUE') and SALTA_POPUP_TARJETA=1 and ACEPTA_OFERTA_TARJETA=1 and (admision=1 OR ADMISION_MOVIL=1) then  CAPTADO_TARJ end ) AS CAPTADO, 
SUM( CASE WHEN humano=1   AND CON_OFERTA NOT IN ('CDP-NORM','CDP-ADC','CDP','CDP-Nuev','CDP-PRUE') and SALTA_POPUP_TARJETA=1 and ACEPTA_OFERTA_TARJETA=1 and (admision=1 OR ADMISION_MOVIL=1) AND CAPTADO_TARJ=1 THEN CONCRETA_MES END ) AS CONCRETA_MES, 
SUM(CASE WHEN humano=1   AND CON_OFERTA NOT IN ('CDP-NORM','CDP-ADC','CDP','CDP-Nuev','CDP-PRUE') and SALTA_POPUP_TARJETA=1 and ACEPTA_OFERTA_TARJETA=1 and (admision=1 OR ADMISION_MOVIL=1) AND CAPTADO_TARJ=1 THEN  CONCRETA_DIA END) AS CONCRETA_DIA,
tipo_cliente,
input(SUBSTR(FECHA2,11,2),best.) as dia 
from funnel_TV_diario_&periodo.
GROUP BY 
periodo, 
OFERTA, 
CUPO, 
ORIGEN_CAPTA, 
DORMIDO, 
ANTIGUO_SIN_USO, 
CAMPANA,
VU,
tipo_cliente,
calculated dia
;QUIT; 

%if (%sysfunc(exist(&LIBRERIA..RESUMEN_FUNNEL_DIARIO_CAPTA_TV))) %then %do;
 
%end;
%else %do;
PROC SQL;
CREATE TABLE &LIBRERIA..RESUMEN_FUNNEL_DIARIO_CAPTA_TV 
(periodo num,
OFERTA best(99),
CUPO best(99),
origen_capta best (99),
DORMIDO num,
ANTIGUO_SIN_USO num,
CAMPANA best(99),
VU num,
TRX_TOTAL num,
DIG num,
DIG_UNICAS num,
oferta_RIESGO num,
UOF num,
NO_oferta_mora_protesto num,
No_oferta_lnegro num,
No_oferta_riesgo num,
NO_UOF_1 num,
NO_UOF_2 num,
NO_UOF_3 num,
SALTA_POPUP num,
NO_POPUP_LN	num,
NO_popup_MORA num,
ACEPTA_OFERTA num,
ACEPTACION_REAL_ADM	num,
ACEPTACION_REAL_MOVIL num,
CAPTADO	num,
CONCRETA_MES num,
CONCRETA_DIA num,
TIPO_CLIENTE best(99),
dia num
)
;RUN;
%end;

proc sql;
delete *
from  &LIBRERIA..RESUMEN_FUNNEL_DIARIO_CAPTA_TV
where periodo=&periodo.
;QUIT;

proc sql;
insert into  &LIBRERIA..RESUMEN_FUNNEL_DIARIO_CAPTA_TV
select *
from colapso_TV_diario_&periodo.
;QUIT;

proc sql;
create table &LIBRERIA..RESUMEN_FUNNEL_DIARIO_CAPTA_TV as 
select * 
from &LIBRERIA..RESUMEN_FUNNEL_DIARIO_CAPTA_TV
;QUIT;

proc sql;
drop table actual;
drop table vta_bol;
drop table resumen_oferta;
drop table lca;
drop table resumen_oferta2;
drop table act_tr;
drop table castigo;
drop table act_tr_bi;
drop table tv1;
drop table lnegro;
drop table tv2;
drop table tv3;
drop table tv4;
drop table tv5;
drop table tv6;
drop table cruce;
drop table colapso_cruce;
drop table admision;
drop table admision_movil;
drop table propension;
drop table captado;
drop table funnel_TV_diario_&periodo.;
drop table colapso_TV_diario_&periodo.;
;QUIT;


%mend funnel_diario;

%macro ejecutar(A);

DATA _null_;
HOY = day(today());
Call symput("HOY", HOY);
RUN;
%put &HOY;



%if %eval(&HOY.<=5) %then %do;

%funnel_diario(&libreria.,0,0);
%funnel_diario(&libreria.,1,1);
%end;
%else %DO;


%funnel_diario(&libreria.,0,0);



%end;



%mend ejecutar;



%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/



%ejecutar(A);



data _null_;
dur = datetime() - &tiempo_inicio;
put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */




/* Fecha ejecución del proceso */
data _null_;
execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechaeDVN", execDVN) ;
RUN;
%put &fechaeDVN;/*fecha ejecucion proceso */



/* ENVÍO DE CORREO CON MAIL VARIABLE */
proc sql noprint;
SELECT EMAIL into :EDP_BI
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'CLAUDIA_PAREDES';

SELECT EMAIL into :DEST_2
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';

SELECT EMAIL into :DEST_3
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'CONSUELO_ARTEAGA';

SELECT EMAIL into :DEST_6
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_7
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

quit;



%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_6;
%put &=DEST_7;



data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_2","&DEST_3")
CC=("&DEST_6","&DEST_7","jaburtom@bancoripley.com
","bmartinezg@bancoripley.com","rfonsecaa@bancoripley.com")
SUBJECT="MAIL_AUTOM: FUNNEL TV DIARIO %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ;
put "Proceso FUNNEL TV DIARIO, ejecutado con fecha: &fechaeDVN";
put ;
put ;
PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
