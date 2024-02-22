/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	SUSCRIPCIONES_CARGOS_PAT		 ===============================*/
/* CONTROL DE VERSIONES
/* 2023-06-13 -- V08	-- Esteban P.	-- Se actualizan credenciales para conexión gedcre.
/* 2022-11-08 -- V07	-- Esteban P.	-- Se añade nueva sentencia include para borrar y exportar a RAW.
/* 2022-08-25 -- V06    -- Sergio J.	-- Se añade sentencia include para borrar y exportar a RAW
/* 2022-07-15 -- V05	-- David V. 	-- Ajustes mínimos, comentarios, correo, versionamiento.

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
/*proceso que unifica informacion opéx y uso en tda temporada*/

%let libreria=RESULT;

%macro opex_temporada(n,lib);


DATA _NULL_;
per = put(intnx('month',today(),-&n.,'end'), yymmn6.);
call symput("periodo",per);
run;
%put &periodo;



%put==================================================================================================;
%put [01] Verificar si existe base madre , caso contrario crearla &periodo. ;
%put==================================================================================================;

%if (%sysfunc(exist(&lib..Analisis_VTA_ART1_test))) %then %do;	
%end;
%else %do;
PROC SQL;
CREATE TABLE &lib..Analisis_VTA_ART1_test (
periodo_tableau date,
Periodo num, 
Codigo_Sucursal  num, 
Articulo_Temporada char(99), 
Marca  char(99), 
Codigo_Dpto  char(99), 
Nombre_Dpto char(99),
tipo_compra char(99), 
Medio_Pago char(99), 
Codigo_OPEX num, 
Nro_Articulos  num, 
Mto_Articulos  num, 
Mto_Articulos_opex num,
Mto_Dcto_OPEX  num, 
Nombre_Sucursal char(99), 
Nombre_Division char(99), 
Nombre_Depto2 char(99), 
Categoria_Dpto  char(99))
;QUIT;
%end;


%put==================================================================================================;
%put [02] Eliminar &periodo. para evitar duplicado de información;
%put==================================================================================================;

proc sql;
delete *
from &lib..Analisis_VTA_ART1_test
where periodo=&periodo.
;QUIT;

proc sql;
create table &lib..Analisis_VTA_ART1_test as 
select *
from &lib..Analisis_VTA_ART1_test;
quit;

%put==================================================================================================;
%put [03] Extraer Base de ventas Tienda en &Periodo. con Variables Relevantes ;
%put==================================================================================================;

%let mz_connect_zeus=CONNECT TO ODBC as zeus(datasrc="creditoprd" user="CONSULTA_CREDITO" password="crdt#0806");

proc sql;

&mz_connect_zeus;
create table work.Detalle_Vtas_TDA as 
SELECT *
from  connection to zeus(
SELECT  
a.DDMTD_FCH_DIA as Fecha,
a.DDMSU_COD_SUC,
a.DDMAR_COD_SKU_ART as SKU,
b.DDMAR_GLS_SKU_ART,
b.DDMAR_GLS_TMD, /*Clasificacion de Articulo de Temporada*/
b.GMMRC_GLS_MRC, /*Marca del producto*/
a.DDMDT_RUT_CLI as RUT,
b.DDMAR_COD_DPT as Codigo_Dpto,
b.DDMAR_GLS_DPT as Nombre_Dpto,
case when a.DCMDT_COD_TIP_TRN=1 then 'COMPRA' else 'NOTA CREDITO' end as tipo_compra,
case when a.DDMFP_COD_FOR_PAG=3 then 'TAR' else 'OMP' end as Medio_Pago, 
a.DDMSU_COD_SUC||' '||a.DDMTD_FCH_DIA||' '||a.DCMDT_NRO_TML||' '||a.DCMDT_NRO_DCT  AS BOLETA,
a.DCMDT_NRO_ITM as Nro_Item,
a.DCMDT_MNT_PCO_ART-a.DCMDT_MNT_DST_BOL-a.DCMDT_MNT_DST_ART-a.DCMDT_KLM_LAN as Mto 
FROM GEDCRE_CREDITO.DCRM_COS_MOV_TRN_DET_VTA_ART as a  
left JOIN GEDCRE_CREDITO.DCRM_DIM_MAE_ART_RTL as b 
ON (a.DDMAR_COD_SKU_ART=b.DDMAR_COD_SKU_ART)
WHERE a.DCMdT_COD_TRN NOT IN(39,401,402,89,90,93)
and a.DDMSU_COD_SUC NOT IN (10993,10990) 
and a.DDMSU_COD_NEG=1
and a.DCMDT_COD_CMR_ASO=1 
and a.DCMDT_COD_TIP_TRN in (1,3) /*1= NO nota de credito, 3= SI nota de credito*/
and a.DDMTD_FCH_DIA>=100*&Periodo.+01
and a.DDMTD_FCH_DIA<=100*&Periodo.+31
) as conexion 
;QUIT;

%put==================================================================================================;
%put [04] Extraer Base de OPEX &Periodo. ;
%put==================================================================================================;

proc sql;
create table work.SB20200220_OPEX as 
select 
BOLETA,
Nro_Item,
Codigo,
DCTO,
Fecha,
Codigo_Sucursal
from publicin.OPEX_CANJESOP_&periodo.
where Tipo_Codigo<>'CANJE' 
;QUIT;



%put==================================================================================================;
%put [05] Indexar ambas tablas &Periodo. ;
%put==================================================================================================;

PROC SQL;
CREATE INDEX Boleta ON work.SB20200220_OPEX (Boleta)
;QUIT;

PROC SQL;
CREATE INDEX Nro_Item ON work.SB20200220_OPEX (Nro_Item)
;QUIT;

PROC SQL;
CREATE INDEX Boleta ON Detalle_Vtas_TDA (Boleta)
;QUIT;

PROC SQL;
CREATE INDEX Nro_Item ON Detalle_Vtas_TDA (Nro_Item)
;QUIT;

%put==================================================================================================;
%put [06.0] Cruce de ventas con opex PRESENCIAL &Periodo. ;
%put==================================================================================================;

proc sql ;
create table seguimiento_OPEX as 
select
a.*,
case when a.Medio_Pago='TAR' and b.codigo<>0 then b.Codigo 
when a.Medio_Pago='TAR' and b.codigo=0 then a.sku else . end  format=13. as Codigo_OPEX,
case when a.Medio_Pago='TAR' then	b.DCTO  else . end as DCTO_OPEX 
from Detalle_Vtas_TDA as a 
left join work.SB20200220_OPEX as b 
on (a.Boleta=b.Boleta) and (a.Nro_Item=b.Nro_Item) 
;quit;

%put==================================================================================================;
%put [06.1] Cruce de ventas con opex INTERNET &Periodo. ;
%put==================================================================================================;


proc sql;
create table seguimiento_OPEX2 as 
select 
*
from seguimiento_OPEX
;QUIT;


%put==================================================================================================;
%put [07] Colapso de informacion &Periodo. ;
%put==================================================================================================;

proc sql;
create table work.Vta_TDA_ART_AGG as 
select 
floor(Fecha/100) as Periodo,
DDMSU_COD_SUC-10000 as Codigo_Sucursal,
DDMAR_GLS_TMD as Articulo_Temporada,
GMMRC_GLS_MRC as Marca,
Codigo_Dpto,
Nombre_Dpto,
tipo_compra,
Medio_Pago,
Codigo_OPEX,
count(*) as Nro_Articulos,
sum(Mto) as Mto_Articulos,
sum(case when DCTO_OPEX>0 then MTO else 0 end ) as Mto_Articulos_opex,
sum(DCTO_OPEX) as Mto_Dcto_OPEX  
from seguimiento_OPEX2
group by 
calculated Periodo,
calculated Codigo_Sucursal,
DDMAR_GLS_TMD,
GMMRC_GLS_MRC,
Codigo_Dpto,
Nombre_Dpto,
tipo_compra,
Medio_Pago,
Codigo_OPEX 
;quit;

%put==================================================================================================;
%put [08] Pegado de información de división y depto &Periodo. ;
%put==================================================================================================;

proc sql;
create table work.Vta_TDA_ART_AGG2 as 
select 
a.*,
cats(compress(put(a.Codigo_Sucursal,best.)),'|',c.TGMSU_NOM_SUC) as Nombre_Sucursal, 
case when b.cod_depto is not null then b.division else 'Sin informacion'
end as Nombre_Division,
case when b.cod_depto is not null then b.departamento else 'Sin informacion'
end as Nombre_Depto2,
case
when a.Codigo_Dpto IN ('D102','D103','D111','D113','D119','D122','D123',
'D126','D128','D130','D133','D136','D148','D149','D150','D171','D172','D185','D191',
'D194','D195','D199','D200','D345','D346','D347','D359','D360','D367','D377','D381',
'D384','D386') 
then 'Duro'
else 'Blando'
end as Categoria_Dpto 
from work.Vta_TDA_ART_AGG as a 
left join pmunoz.deptos_limpio as b
on(a.Codigo_Dpto=b.cod_depto)
left join jaburtom.BOTGEN_MAE_SUC as c 
on (a.Codigo_Sucursal=c.TGMSU_COD_SUC_K)
;quit;

%put==================================================================================================;
%put [09] Insertar en tabla madre el colapso &Periodo. ;
%put==================================================================================================;

proc sql;
insert into &lib..Analisis_VTA_ART1_test 
select 
mdy(mod(int((&periodo.*100+01)/100),100),mod((&periodo.*100+01),100),int((&periodo.*100+01)/10000)) format=date9. as periodo_tableau,
*
from Vta_TDA_ART_AGG2
;QUIT;

%put==================================================================================================;
%put [10] Eliminación de tablas &Periodo. ;
%put==================================================================================================;

proc sql;
drop table Detalle_Vtas_TDA;
drop table SB20200220_OPEX;
drop table seguimiento_OPEX;
drop table seguimiento_OPEX2;
drop table Vta_TDA_ART_AGG;
drop table Vta_TDA_ART_AGG2;
;QUIT;

%put==================================================================================================;
%put [11] Codigos opex &Periodo. ;
%put==================================================================================================;


%if (%sysfunc(exist(&lib..conteo_opex))) %then %do;	
%end;
%else %do;
PROC SQL;
CREATE TABLE &lib..conteo_opex (
Periodo num, 
Nro_OPEX_CANJEADAS num,
Nro_OPEX_DISTINTAS num,
Tipo_Prom char(99),
N_OPEX_CREADAS num
)
;QUIT;
%end;


proc sql;
delete *
from &lib..conteo_opex
where periodo=&periodo.
;QUIT;

proc sql;
create table &lib..conteo_opex as 
select *
from &lib..conteo_opex;
quit;


proc sql;
create table canjes as 
SELECT &periodo. as periodo,
T1.RUT,T1.Codigo 
FROM PUBLICIN.OPEX_CANJESOP_&periodo. t1 
where (t1.Codigo NOT = . and t1.Codigo NOT =0) and Tipo_Codigo in ('CANJE+OPEX','OPEX')
;QUIT;


PROC SQL;
   CREATE TABLE WORK.SALIDA_OPEX_CANJEADAS AS 
   SELECT t1.Periodo, 
            (COUNT(t1.Codigo)) AS Nro_OPEX_CANJEADAS, 
            (COUNT(DISTINCT(t1.Codigo))) AS Nro_OPEX_DISTINTAS
      FROM WORK.CANJES t1
      GROUP BY t1.Periodo
;QUIT;

proc sql;
insert into &lib..conteo_opex
select 

Periodo , 
Nro_OPEX_CANJEADAS ,
Nro_OPEX_DISTINTAS ,
'NULL' as Tipo_Prom ,
. as N_OPEX_CREADAS 
from SALIDA_OPEX_CANJEADAS
;QUIT;

PROC SQL;
CREATE TABLE CODIGOS_creados_MES AS 
SELECT &periodo. as periodo, Tipo_Prom,(COUNT(DISTINCT(t1.Codigo))) AS N_OPEX_CREADAS
FROM PUBLICIN.CODIGOS_OPEX t1
WHERE floor(input(cat(substr(t1.Desde,7,4),substr(t1.Desde,4,2),substr(t1.Desde,1,2)),best.)/100) >= &periodo.
AND floor(input(cat(substr(t1.Desde,7,4),substr(t1.Desde,4,2),substr(t1.Desde,1,2)),best.)/100)  <= &periodo.
Group by Tipo_Prom
;QUIT;


proc sql;
insert into &lib..conteo_opex
select 
Periodo , 
. as Nro_OPEX_CANJEADAS ,
. as Nro_OPEX_DISTINTAS ,
 Tipo_Prom ,
N_OPEX_CREADAS 
from CODIGOS_creados_MES
;QUIT;

proc sql;
drop table canjes;
drop table SALIDA_OPEX_CANJEADAS;
drop table CODIGOS_creados_MES;
;quit;


%mend opex_temporada;

%opex_temporada(0,&libreria.);
%opex_temporada(1,&libreria.);

%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(tnda_analisis_vta_art,raw,oracloud,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(tnda_analisis_vta_art,&libreria..analisis_vta_art1_test,raw,oracloud,0);

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(tnda_conteo_opex,raw,oracloud,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(tnda_conteo_opex,&libreria..conteo_opex,raw,oracloud,0);



DM "log; clear; ";

/*	Fecha ejecución del proceso	*/
data _null_;
execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechaeDVN", execDVN) ;
RUN;

%put &fechaeDVN;/*fecha ejecucion proceso */

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_SPOS_1';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SUBG_BI';
	SELECT EMAIL into :DEST_7 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'LIVIA_HERNANDEZ';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;	
%put &=DEST_6;	%put &=DEST_7;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_7")
CC = ("&DEST_1", "&DEST_2","&DEST_3","&DEST_4", "&DEST_5","&DEST_6")
SUBJECT = ("MAIL_AUTOM: Proceso Uso Temporada/opex");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso Uso Temporada/opex, ejecutado con fecha: &fechaeDVN";  
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 08'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/  

data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */
