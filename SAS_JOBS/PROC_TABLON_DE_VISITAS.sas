/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROC_TABLON_DE_VISITAS		================================*/
/* CONTROL DE VERSIONES
/* 2023-06-11 -- v06	-- Esteban P.	-- Se cambian credenciales de conexión GEDCRE.
/* 2022-12-21 -- Esteban P. -- Se actualizan los correos, se reemplazan los nombres de funcionarios por roles en la sección de correos.
/* 2022-04-04 -- Esteban P. -- Se actualizan los correos: Se reemplaza a Pía Olavarría por "PM_CONTACTABILIDAD".
/* 2020-08-14 ---- Corrección a código que generaba error (se quitan cierres de paréntesis)
/* 2020-08-11 ---- RESUMEN DE LAS VISITAS HASTA LA FECHA DE EJECUCIÓN DEL PERIODO POR TODOS LOS CANALES
/*
/* Tiempo ejecución aprox 10 min
/**/
/*==================================================================================================*/

/*tablo de visitas 2.0*/

/*TABLAS DE USO*/
/*credito: VENTAS_TARJETAS_ACTUAL, VENTAS_HEADER_ACTUAL,
           TRX_ABONOS,  TRX_HEADER_ABONOS y VENTAS_DETALLE_ACTUAL*/
/*BRTEFGESTIONP.WORLD: CBCAMP_MOV_TRX_OFE*/
/*FISA: tcaj_forpago, tpre_prestamos y tcli_persona*/

%let libreria=PUBLICIN; /*modificar en base a donde se guardara la informacion*/

%macro TABLON_VISITAS(n,LIB);


%put==================================================================================================;
%put [00.00] Macros de fechas ;
%put==================================================================================================;

DATA _NULL_;
ini = put(intnx('month',today(),-&n,'begin'),date9.);
fin = put(intnx('month',today(),-&n,'end'),date9.);
per = put(intnx('month',today(),-&n,'end'), yymmn6.);
Call symput("INI",ini);
Call symput("FIN",fin);
call symput("periodo",per);
run;

%put &INI;
%put &FIN;
%put &periodo;

%put==================================================================================================;
%put [00.01] Creación de tablas base para visitas ;
%put==================================================================================================;


proc sql;
create table &LIB..tablon_visitas_&periodo. (
rut num,
rut_real num,
n_vis num,
fecha date,
sucursal num,
origen num,
tipo num
)
;QUIT;

%put==================================================================================================;
%put [01.01] Detalle de las compras (parte de con cuotas)  &n;
%put==================================================================================================;

LIBNAME credito ODBC  DATASRC=creditoprd  SCHEMA=GEDCRE_CREDITO  USER=CONSULTA_CREDITO  PASSWORD='crdt#0806';

proc sql;
create table tda1 as 
select 
t1.RUT_TITULAR,
t1.MONTO_CAPITAL, 
t1.AGNO_MES_DIA_TRX,
compress(cat(t1.COD_COMERCIO, 
t1.COD_SUCURSAL, 
t1.FECHA,  
t1.NUM_CAJA, 
t1.NUM_DOCUMENTO,
t1.AGNO_MES_DIA_TRX)) as boleta 
from CREDITO.VENTAS_TARJETAS_ACTUAL as t1 
where t1.AGNO_MES_DIA_TRX between "&INI"D and "&FIN"D
;QUIT;

%put==================================================================================================;
%put [01.02] Detalle de las compras (compra/nota de credito) &n;
%put==================================================================================================;

PROC SQL;
CREATE TABLE tda2 AS 
SELECT  
t2.MONTO_TRANSACCION, 
t2.RUT_COMPR_PAG, 
t2.AGNO_MES_DIA_TRX, 
t2.COD_TIPO_TRANSACCION,
t2.COD_TRANSACCION,
t2.COD_SUCURSAL,
case when t2.COD_TRANSACCIOn in (3, 10, 23, 30) then 'TARJ' else 'OMP' end as tipo,
compress(cat(t2.COD_COMERCIO, 
t2.COD_SUCURSAL, 
t2.FECHA,  
t2.NUM_CAJA, 
t2.NUM_DOCUMENTO,
t2.AGNO_MES_DIA_TRX)) as boleta 
from CREDITO.VENTAS_HEADER_ACTUAL as t2
where t2.AGNO_MES_DIA_TRX between "&INI"D and "&FIN"D
and t2.COD_TIPO_TRANSACCION IN (1, 3)
and t2.COD_TRANSACCIOn not in (300, 304, 308, 401, 402) 
;QUIT; 

%put==================================================================================================;
%put [01.03] Detalle de las compras (detalle articulo) &n;
%put==================================================================================================;

PROC SQL;
CREATE TABLE tda3 AS 
SELECT   
t3.Agno_Mes_Dia_Trx,

compress(cat(t3.COD_COMERCIO, 
t3.COD_SUCURSAL, 
t3.FECHA,  
t3.NUM_CAJA, 
t3.NUM_DOCUMENTO,
t3.AGNO_MES_DIA_TRX)) as boleta 
from CREDITO.VENTAS_DETALLE_ACTUAL AS t3
where 
t3.Agno_Mes_Dia_Trx  between "&INI"D and "&FIN"D
ANd t3.NUM_ITEM = 1

;QUIT;

%put==================================================================================================;
%put [01.04] Detalle de las compras (detalle articulo)  &n;
%put==================================================================================================;

proc sql;
create table cruce_tda as 
select 
case when t2.COD_TIPO_TRANSACCION=1 then 'Compra' else 'Nota Credito' end as TRX, 
t2.AGNO_MES_DIA_TRX, 
t2.MONTO_TRANSACCION, 
t2.RUT_COMPR_PAG, 
t2.tipo,
t2.COD_SUCURSAL,
case when t1.boleta is not null then 1 else 0 end as tda,
case when t3.boleta is not null then 1 else 0 end as detalle 
from  tda2 AS t2
left join tda1 AS t1
on(t1.boleta = t2.boleta) 
left join tda3 as t3 
on(t2.boleta= t3.boleta)
;QUIT;

%put==================================================================================================;
%put [01.05] Base Final &n;
%put==================================================================================================;

PROC SQL;
CREATE TABLE venta_final_TMP AS 
SELECT t1.*
FROM WORK.CRUCE_TDA t1
where (t1.tipo='TARJ' and t1.tda=1 and  
t1.detalle=0) 
outer union corr
select 
*
from WORK.CRUCE_TDA t1
where 
(t1.tipo='OMP'  and
t1.detalle=1 and t1.tda=0)

outer union corr
select 
*
from WORK.CRUCE_TDA t1
where 
(t1.tipo='OMP'  and
t1.detalle=0 and t1.tda=1)
;QUIT;

%put==================================================================================================;
%put [01.06] insertar en base ;
%put==================================================================================================;

proc sqL;
insert into &LIB..tablon_visitas_&periodo.
select 
RUT_COMPR_PAG as rut,
case when RUT_COMPR_PAG between 1000000 and 49999999 and 
RUT_COMPR_PAG not in (1111111,2222222,3333333,4444444,5555555,6666666,7777777,8888888,9999999,
11111111,22222222,33333333,44444444) then 1 else 0 end  as rut_real,
count(RUT_COMPR_PAG) as n_vis,
AGNO_MES_DIA_TRX as fecha,
COD_SUCURSAL as SUCURSAL,
01 as origen, /*TDA*/
case when TRX='Nota Credito' then 04 /*NOTA CREDITO*/
when TRX='Compra' and MONTO_TRANSACCION>1 and tipo='TARJ' then 01 /*'COMPRA TR'*/
when TRX='Compra' and MONTO_TRANSACCION>1 and tipo='OMP' then 02 /*compra omp*/
when TRX='Compra' and MONTO_TRANSACCION=1 and tipo='OMP' then 03 /*'1PESO'*/ 
else 04 end as tipo
from venta_final_TMP
group by 
RUT_COMPR_PAG,
calculated rut_real,
fecha,
sucursal,
calculated tipo
;QUIT;

proc sql;
drop table tda1
;QUIT;

proc sql;
drop table tda2
;QUIT;

proc sql;
drop table tda3
;QUIT;

proc sql;
drop table cruce_tda
;QUIT;

proc sql;
drop table venta_final_TMP
;QUIT;

%put==================================================================================================;
%put [02.01] Pagos en TDA ;
%put==================================================================================================;

PROC SQL;
   CREATE TABLE PAGO_CUOTAS AS 
   SELECT t1.SUCURSAL, 
          t1.FECHA, 
          t1.NRO_CJA_NUM AS NRO_CAJA, 
          t1.NRO_DOCTO, 
          t1.RUT_CLIENTE, 
          t1.CAJERO, 
          t1.FECHA_TRUNC
      FROM CREDITO.TRX_HEADER_ABONOS AS t1
WHERE t1.FECHA_TRUNC BETWEEN "&INI:00:00:00"Dt and "&FIN:23:59:59"Dt
AND TIPO_TRX = 2 AND COMERCIO = 1  and t1.sucursal<>63;
QUIT; 


              
PROC SQL;
CREATE TABLE FECHA_MAX_P_CUOTAS AS 
SELECT t1.SUCURSAL, 
/* MAX_of_FECHA */
(MAX(datepart(t1.FECHA))) FORMAT=DATE9. AS MAX_of_FECHA, 
t1.RUT_CLIENTE, 
t1.CAJERO,
t1.NRO_CAJA
FROM WORK.PAGO_CUOTAS AS t1
GROUP BY t1.SUCURSAL, t1.RUT_CLIENTE, t1.CAJERO, t1.Nro_caja;
QUIT;

PROC SQL;
CREATE TABLE PAGO_CUOTAS_FINAL AS 
SELECT t1.SUCURSAL, 
t1.MAX_of_FECHA, 
t1.NRO_CAJA AS NUM_CAJA, 
t1.RUT_CLIENTE, 
t1.CAJERO, 
'PAGOS' AS DETALLE,
CASE WHEN NRO_CAJA>=200 THEN 'TF' ELSE 'TV' END AS VIA 
FROM WORK.FECHA_MAX_P_CUOTAS AS t1
;QUIT;

%put==================================================================================================;
%put [02.02] Insertar pagos en base madre ;
%put==================================================================================================;

proc sqL;
insert into &LIB..tablon_visitas_&periodo.
select 
RUT_CLIENTE as rut,
case when RUT_CLIENTE between 1000000 and 49999999 and 
RUT_CLIENTE not in (1111111,2222222,3333333,4444444,5555555,6666666,7777777,8888888,9999999,
11111111,22222222,33333333,44444444) then 1 else 0 end  as rut_real,
count(RUT_CLIENTE) as n_vis,
MAX_of_FECHA as fecha,
sucursal,
case when via='TF' then 07 else 01 end  as origen, /*tda*/
case when VIA='TF' then 01 else 05 end as tipo /*4 es tf 5 es via*/
from PAGO_CUOTAS_FINAL
group by 
RUT_CLIENTE,
calculated rut_real,
fecha,
sucursal,
calculated tipo,
calculated origen
;QUIT;

proc sql;
drop table fecha_max_p_cuotas
;QUIT;

proc sql;
drop table pago_cuotas
;QUIT;

proc sql;
drop table pago_cuotas_final
;QUIT;

%put==================================================================================================;
%put [03.01] Trae información de campañas para otras vistas;
%put==================================================================================================;

LIBNAME CAMP ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="BRTEFGESTIONP.WORLD"  SCHEMA=CAMP_ADM  USER='CAMP_COMERCIAL'  PASSWORD='ccomer2409' ;


DATA _null_;
INI_FISA = put(intnx('month',today(),-&n.,'begin'),ddmmyy10.);
FIN_FISA = put(intnx('month',today(),-&n.,'end'),ddmmyy10.);
Call symput("INI_FISA", INI_FISA);
Call symput("FIN_FISA", FIN_FISA);
RUN;

PROC SQL ;
CONNECT TO ORACLE AS REPORTITF (PATH="BRTEFGESTIONP.WORLD" USER='CAMP_COMERCIAL' PASSWORD='ccomer2409');
CREATE TABLE TRANSACCIONES_CAMP AS 
SELECT * FROM CONNECTION TO REPORTITF(
SELECT 
CAMP_MOV_ID_K  IDENTIFICADOR,
CAMP_MOV_RUT_CLI  RUT,
CAMP_MOV_COD_CANAL  CANAL,
CAMP_MOV_COD_SUC  SUCURSAL,
CAMP_MOV_FCH_HOR  FECHA,
CAMP_MOV_NRO_TERM  caja
from CBCAMP_MOV_TRX_OFE 
where 
CAMP_MOV_COD_CANAL IN (4,9,3,11,2)
and CAMP_MOV_FCH_HOR  BETWEEN to_date(%str(%')&INI_FISA.%str(%'),'dd/mm/yyyy') and 
to_date(%str(%')&fin_FISA.%str(%'),'dd/mm/yyyy')
)A
;QUIT;


%put==================================================================================================;
%put [03.02] Informacion de movil;
%put==================================================================================================;

proc sql;
create table MOVIL as 
select 
distinct 
rut,
case when rut between 1000000 and 49999999 and 
rut not in (1111111,2222222,3333333,4444444,5555555,6666666,7777777,8888888,9999999,
11111111,22222222,33333333,44444444) then 1 else 0 end  as rut_real,
count(rut) as n_vis,
datepart(fecha) format=date9.  as fecha,
SUCURSAL,
09 as origen, /*tda*/
01 as tipo /*4 es tf 5 es via*/
from TRANSACCIONES_CAMP
where CANAL=9
group by 
rut,
calculated rut_real,
calculated fecha,
sucursal
;QUIT;

%put==================================================================================================;
%put [03.03] Informacion de plataforma comercial;
%put==================================================================================================;

proc sql;
create table ccss as 
select distinct 
rut,
case when rut between 1000000 and 49999999 and 
rut not in (1111111,2222222,3333333,4444444,5555555,6666666,7777777,8888888,9999999,
11111111,22222222,33333333,44444444) then 1 else 0 end  as rut_real,
count(rut) as n_vis,
datepart(fecha) format=date9.  as fecha,
sucursal,
case when sucursal between 500 and 799 then 00
when sucursal in (800,801,802,60,61) then 03 else 03 end as origen,
case when sucursal between 500 and 799 then 01
when sucursal in (800,801,802,60,61) then 02 else 01 end as tipo

from TRANSACCIONES_CAMP
where CANAL=3
group by 
rut,
calculated rut_real,
calculated fecha,
sucursal,
calculated origen,
calculated tipo
;QUIT;

%put==================================================================================================;
%put [03.04] Informacion de RPOS;
%put==================================================================================================;

proc sql;
create table rpos as 
select 
distinct 
rut,
case when rut between 1000000 and 49999999 and 
rut not in (1111111,2222222,3333333,4444444,5555555,6666666,7777777,8888888,9999999,
11111111,22222222,33333333,44444444) then 1 else 0 end  as rut_real,
count(rut) as n_vis,
datepart(fecha) format=date9.  as fecha,
sucursal,
11 as origen,
01 as tipo
from TRANSACCIONES_CAMP
where CANAL=11
group by 
rut,
calculated rut_real,
calculated fecha,
sucursal
;QUIT;

%put==================================================================================================;
%put [03.05] Informacion de admision;
%put==================================================================================================;

proc sql;
create table adm as 
select 
distinct 
rut,
case when rut between 1000000 and 49999999 and 
rut not in (1111111,2222222,3333333,4444444,5555555,6666666,7777777,8888888,9999999,
11111111,22222222,33333333,44444444) then 1 else 0 end  as rut_real,
count(rut) as n_vis,
datepart(fecha) format=date9.  as fecha,
sucursal,
case when sucursal between 500 and 799 then 00
when sucursal in (800,801,802,60,61) then 04 else 04 end as origen,
case when sucursal between 500 and 799 then 02
when sucursal in (800,801,802,60,61) then 02 else 01 end as tipo

from TRANSACCIONES_CAMP
where CANAL=4
group by 
rut,
calculated rut_real,
calculated fecha,
sucursal,
calculated origen,
calculated tipo
;QUIT;

%put==================================================================================================;
%put [03.06] Informacion de HB;
%put==================================================================================================;

proc sql;
create table hb as 
select 
distinct 
rut,case when rut between 1000000 and 49999999 and 
rut not in (1111111,2222222,3333333,4444444,5555555,6666666,7777777,8888888,9999999,
11111111,22222222,33333333,44444444) then 1 else 0 end  as rut_real,
count(rut) as n_vis,
datepart(fecha) format=date9.  as fecha,
sucursal,
02 as origen,
01 as tipo

from TRANSACCIONES_CAMP
where CANAL=2
group by 
rut,
calculated rut_real,
calculated fecha,
sucursal
;QUIT;

%put==================================================================================================;
%put [03.07] Guardar en duro;
%put==================================================================================================;

proc sql;
create table insertar as 
select 
*
from movil 
outer union corr
select 
*
from ccss
outer union corr 
select 
*
from RPOS 
outer union corr 
select 
*
from adm
outer union corr  
select 
*
from HB
;QUIT;

proc sqL;
insert into &LIB..tablon_visitas_&periodo.
select 
*
from insertar
;QUIT;

PROC SQL;
DROP TABLE ADM
;quit;

PROC SQL;
DROP TABLE CCSS
;quit;

PROC SQL;
DROP TABLE HB
;quit;

PROC SQL;
DROP TABLE INSERTAR
;quit;

PROC SQL;
DROP TABLE MOVIL
;quit; 

PROC SQL;
DROP TABLE RPOS
;quit; 

PROC SQL;
DROP TABLE TRANSACCIONES_CAMP
;quit;

%put==================================================================================================;
%put [04.01] VISITAS SITIO PRIVADO Y APP;
%put==================================================================================================;

proc sql;
create table agrupado as 
select 
rut,
case when rut between 1000000 and 49999999 and 
rut not in (1111111,2222222,3333333,4444444,5555555,6666666,7777777,8888888,9999999,
11111111,22222222,33333333,44444444) then 1 else 0 end  as rut_real,
count(rut) as n_vis,
datepart(Fecha_Logueo) format=date9.  as fecha,
39 as sucursal,
19 as origen,
case when tipo_logueo='APP' then 01 else 02 end as tipo
from publicin.logeo_int_&periodo.
group by 
rut,
calculated rut_real,
calculated fecha,
calculated tipo
;QUIT;

proc sqL;
insert into &LIB..tablon_visitas_&periodo.
select 
*
from agrupado
;QUIT;

proc sql;
drop table agrupado
;QUIT;

%put==================================================================================================;
%put [05.01] VISITAS CAJA BANCO;
%put==================================================================================================;

PROC SQL;
CREATE TABLE TRX_ABONOS AS 
SELECT distinct
RUT_CLIENTE AS RUT,
fecha,
sucursal
from credito.TRX_ABONOS 
WHERE FECHA  BETWEEN   "&INI:00:00:00"Dt and "&FIN:23:59:59"Dt
AND SUCURSAL = 63 /*63 SUCUSALES BANCO*/
;QUIT;

/*33802*/
PROC SQL;
CREATE TABLE PAGO_EPU_BANCO AS
SELECT DISTINCT RUT,
datepart(FECHA) format=date9. as fec_num,
sucursal
FROM TRX_ABONOS
;QUIT;


/* pago credito consumo en cajas  banco*/

%let mz_connect_BANCO=CONNECT TO ORACLE as BANCO(USER='RIPLEYC' PASSWORD='ri99pley'
PATH="  (DESCRIPTION = 
    (ADDRESS_LIST = 
      (ADDRESS = 
        (PROTOCOL = TCP)
        (Host = 192.168.10.31)
        (Port = 1521)
      )
    )
    (CONNECT_DATA = 
      (SID = ripleyc)
    )
  )
");


proc sql  inobs=1 noprint;
select 
 year("&INI"d)*10000+month("&INI"d)*100+day("&INI"d) as ini2,
 year("&FIN"d)*10000+month("&FIN"d)*100+day("&FIN"d) as fin2
 into:ini2,
 :fin2
 from pmunoz.codigos_capta_cdp
 ;QUIT;

 %let ini2=&ini2;
 %let fin2=&fin2;


proc sql;
&mz_connect_BANCO;
create table PAGOS_BANCO as
SELECT *
from  connection to BANCO(
 select substr(cli_identifica, 1, length(cli_identifica) - 1) rut,
       pre_credito nro_operacion,
       fpa_codeje codigo_usuario,
       pkg_data_marketing.obtiene_nombre_usuario(fpa_codeje) nombre_usuario,
       substr(cli_identifica, 1, length(cli_identifica) - 1) rut_cliente,
       cli_nomcorresp nombre_cliente,
       fpa_valor cuota_pagada,
       fpa_fecha fecha_pago,
       pre_fecontab fecha_contable,
       pkg_data_marketing.obtiene_rut_empleado(fpa_codeje) rut_cajero,
       fpa_sucorg codigo_suc_origen,
       pkg_data_marketing.obtiene_nombre_sucursal(fpa_sucorg) sucursal_origen,
       fpa_sucdes codigo_suc_destino,
       pkg_data_marketing.obtiene_nombre_sucursal(fpa_sucdes) sucursal_destino,
       trunc(sysdate) fecha_extraccion 
  from tcaj_forpago,
       tpre_prestamos,
       tcli_persona
  where fpa_cuentades = pre_credito
  and fpa_clides = cli_codigo
   /*filtro para periodo.*/
and TO_NUMBER(TO_CHAR(trunc(fpa_fecha),'YYYYMMDD')) between &ini2 and &fin2 /* desafio */
   /*Filtro para mes en curso */
   /*and fpa_fecha >= trunc(sysdate, 'mm') */
)A /*WHERE t1.VIS_FECHAPE = '10Jun2016:15:10:33'dt*/
;QUIT;


PROC SQL;
   CREATE TABLE WORK.PAGOS_CREDITOS_BANCO AS 
   SELECT DISTINCT input(t1.rut_cliente,best.) as rut,
          /*t1.FECHA_PAGO,input(put(FECHA_PAGO,yymmddn8.),best.) as fec_num,*/
		  datepart(fecha_pago) format=date9. as fec_num,
		  codigo_suc_destino
      FROM WORK.PAGOS_BANCO t1
WHERE t1.CODIGO_SUC_ORIGEN NOT IN (82,
83,
84)

;QUIT;


proc sqL;
insert into &LIB..tablon_visitas_&periodo.
select 
rut,
case when rut between 1000000 and 49999999 and 
rut not in (1111111,2222222,3333333,4444444,5555555,6666666,7777777,8888888,9999999,
11111111,22222222,33333333,44444444) then 1 else 0 end  as rut_real,
count(rut) as n_vis,
fec_num format=date9. as fecha,
sucursal,
00 as origen, /*banco*/
03 as tipo /*´pago epu*/
from PAGO_EPU_BANCO 
group by 
rut,
calculated rut_real,
 fecha,
calculated tipo
;QUIT;


proc sqL;
insert into &LIB..tablon_visitas_&periodo.
select 
rut,
case when rut between 1000000 and 49999999 and 
rut not in (1111111,2222222,3333333,4444444,5555555,6666666,7777777,8888888,9999999,
11111111,22222222,33333333,44444444) then 1 else 0 end  as rut_real,
count(rut) as n_vis,
fec_num format=date9. as fecha,
codigo_suc_destino as sucursal,
00 as origen, /*banco*/
04 as tipo /*´pago consumo*/
from PAGOS_CREDITOS_BANCO
group by 
rut,
calculated rut_real,
 fecha,
calculated tipo,
sucursal
;QUIT;


proc sql;
drop table pago_epu_banco;
drop table pagos_banco;
drop table pagos_creditos_banco;
drop table trx_abonos;
;QUIT;

%mend TABLON_VISITAS;

%put==================================================================================================;
%put [06.00] EJECUCION DEL PROCESO;
%put==================================================================================================;


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

%MACRO EVALUAR(A);
%if %eval(&todays_date.=&PRIMER_DIAL_LABORAL.) %then %do;
%TABLON_VISITAS(0,&libreria.);
%TABLON_VISITAS(1,&libreria.);
%end;
%else %do;
%TABLON_VISITAS(0,&libreria.);
%end;
%MEND EVALUAR;

%EVALUAR(A);

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
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';

SELECT EMAIL into :DEST_2 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';

SELECT EMAIL into :DEST_3 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SUBG_BI';

SELECT EMAIL into :DEST_4 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_PPFF';

SELECT EMAIL into :DEST_5 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CLIENTES_2';

SELECT EMAIL into :DEST_6 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CONTACTABILIDAD';

SELECT EMAIL into :DEST_7
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';

SELECT EMAIL into :DEST_8
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;
%put &=DEST_5;
%put &=DEST_6;
%put &=DEST_7;
%put &=DEST_8;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_2","&DEST_3","&DEST_4","&DEST_5")
CC = ("&DEST_1","&DEST_6","&DEST_7","&DEST_8")
SUBJECT="MAIL_AUTOM: PROCESO TABLON DE VISITAS %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso TABLON DE VISITAS, ejecutado con fecha: &fechaeDVN";  
 put ; 
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
