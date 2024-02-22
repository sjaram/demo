/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*============================= Proceso Panel C1C2 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-03-08 -- V1 -- Ignacio Plaza --  
					-- Versión Original
   2022-06-01 -- V2 -- Karina Martinez --
					--Reproceso con GSE de Raúl
					publicin.GSE_2021 A rsepulv.GSE_ESTIMADO_202203
					nlagosg.SBIF_ACUM A kmartine.SBIF_ACUM_GSE_RAUL --
/******************************* Validar Proceso ************************************/


/****************************** Comenzar Proceso ************************************/
     


/* AGRUPACION C1a Y C1b */
PROC SQL;
CREATE TABLE work.GSE AS 
SELECT 
rut, 
CASE 
WHEN GSE="AB1" THEN "AB"
WHEN GSE in ("C1A","C1B") THEN "C1"
WHEN GSE="C2" THEN "C2"
WHEN GSE="C3" THEN "C3"
WHEN GSE="D" THEN "D"
WHEN GSE="E" THEN "E"
ELSE "SIN SEGMENTO" 
END AS GSE
FROM rsepulv.GSE_ESTIMADO_202203 /*publicin.GSE_2021*/
;QUIT;


/* IMPORTACION DATA DE RECLAMOS NORMATIVOS */

filename server ftp 'DATA_RECLAMOS_NORMATIVOS.txt' CD='/'
HOST='192.168.82.171' user=194893337 pass=194893337 PORT=21;
data _null_; infile server;
file '/sasdata/users94/user_bi/TRASPASO_DOCS/DATA_RECLAMOS_NORMATIVOS.txt'; 
input;
put _infile_;
run;

proc import datafile = '/sasdata/users94/user_bi/TRASPASO_DOCS/DATA_RECLAMOS_NORMATIVOS.txt'
out = DATA_RECLAMOS_NORMATIVOS
dbms = dlm
replace;
delimiter =',';
run;



/* IMPORTACION DATA NPS*/

filename server ftp 'DATA_NPS.txt' CD='/'
HOST='192.168.82.171' user=194893337 pass=194893337 PORT=21;
data _null_; infile server;
file '/sasdata/users94/user_bi/TRASPASO_DOCS/DATA_NPS.txt'; 
input;
put _infile_;
run;

proc import datafile = '/sasdata/users94/user_bi/TRASPASO_DOCS/DATA_NPS.txt'
out = DATA_NPS
dbms = dlm
replace;
delimiter =',';
run;


/* IMPORTACION FRAUDE TICKETS*/

filename server ftp 'AURIS_Fraude_Tickets.txt' CD='/'
HOST='192.168.82.171' user=194893337 pass=194893337 PORT=21;
data _null_; infile server;
file '/sasdata/users94/user_bi/TRASPASO_DOCS/AURIS_Fraude_Tickets.txt'; 
input;
put _infile_;
run;

proc import datafile = '/sasdata/users94/user_bi/TRASPASO_DOCS/AURIS_Fraude_Tickets.txt'
out = AURIS_Fraude_Tickets
dbms = dlm
replace;
delimiter =';';
run;


/* IMPORTACION FRAUDE MONTO*/

filename server ftp 'AURIS_Fraude_Montos_Desconocidos.txt' CD='/'
HOST='192.168.82.171' user=194893337 pass=194893337 PORT=21;
data _null_; infile server;
file '/sasdata/users94/user_bi/TRASPASO_DOCS/AURIS_Fraude_Montos_Desconocidos.txt'; 
input;
put _infile_;
run;

proc import datafile = '/sasdata/users94/user_bi/TRASPASO_DOCS/AURIS_Fraude_Montos_Desconocidos.txt'
out = AURIS_Fraude_Montos_Desconocidos
dbms = dlm
replace;
delimiter =';';
run;


%let n=2;

%let libreria=RESULT;
%macro PANEL_CONTROL_C1C2(n,libreria);
DATA _NULL_;
periodo = input(put(intnx('month',today(),-&n.,'end'),yymmn6. ),$10.);
periodo_R04 = input(put(intnx('month',today(),-&n.-1,'end'),yymmn6. ),$10.);
INI = put(intnx('month',today(),-&n.,'begin'),date9.);
FIN = put(intnx('month',today(),-&n.,'end'),date9.);
Call symput("periodo", periodo);
Call symput("periodo_R04", periodo_R04);
Call symput("INI", INI);
Call symput("FIN", FIN);
RUN;

%put &periodo;
%put &periodo_R04;
%put &INI;
%put &FIN;



%put------------------------------------------------------------------------------------------;
%put [1] SPOS TC/TD;
%put------------------------------------------------------------------------------------------;
/*SPOS_AUT*/

proc sql;
create table spos_AUT as 
select 
periodo, GSE, "TC" as categoria, "SPOS" as gerencia, "VENTA" AS MARCA_TIPO,
sum(venta_tarjeta) as venta_Q
from publicin.spos_aut_&periodo. as a
left join work.GSE as b on (a.rut=b.rut)
group by 
periodo,
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;

/*SPOS_MAESTRO*/

proc sql;
create table spos_MAESTRO as 
select 
periodo, GSE, "TD" as categoria, "SPOS" as gerencia, "VENTA" AS MARCA_TIPO,
sum(venta_tarjeta) as venta_Q
from publicin.spos_maestro_&periodo. as a
left join work.GSE as b on (a.rut=b.rut)
group by 
periodo,
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;

/*SPOS_MCD*/

proc sql;
create table spos_MCD as 
select 
periodo, GSE, "TD" as categoria, "SPOS" as gerencia, "VENTA" AS MARCA_TIPO,
sum(venta_tarjeta) as venta_Q
from publicin.spos_mcd_&periodo. as a
left join work.GSE as b on (a.rut=b.rut)
group by 
periodo,
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;

/* CREANDO AGRUPADO */

PROC SQL;
CREATE TABLE AGRUPADO_1 AS
SELECT *
FROM spos_AUT
OUTER UNION CORR

SELECT *
FROM spos_MAESTRO
OUTER UNION CORR

SELECT *
FROM spos_MCD
;QUIT;


%put------------------------------------------------------------------------------------------;
%put [2] RETAIL TC/TD/OMP;
%put------------------------------------------------------------------------------------------;


%if (%sysfunc(exist(result.USO_TR_MARCA_&periodo.))) %then %do;

/* TDA TC */
PROC SQL;
CREATE TABLE TDA_TC AS
SELECT periodo, GSE, "TC" as categoria, "TDA" as gerencia, "VENTA" AS MARCA_TIPO,
sum(mto) as venta_Q
FROM result.USO_TR_MARCA_&periodo. as a
left join work.GSE as b on (a.rut=b.rut)
where MARCA_TIPO_TR= "TR"
group by 
periodo,
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;

/* TDA TD */
PROC SQL;
CREATE TABLE TDA_TD AS
SELECT periodo, GSE, "TD" as categoria, "TDA" as gerencia, "VENTA" AS MARCA_TIPO,
sum(mto) as venta_Q
FROM result.USO_TR_MARCA_&periodo. as a
left join work.GSE as b on (a.rut=b.rut)
where MARCA_TIPO_TR in ("DEBITO RIPLEY", "MCD RIPLEY")
group by 
periodo,
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;

/* TDA OMP */
PROC SQL;
CREATE TABLE TDA_OMP AS
SELECT periodo, GSE, "OMP" as categoria, "TDA" as gerencia, "VENTA" AS MARCA_TIPO,
sum(mto) as venta_Q
FROM result.USO_TR_MARCA_&periodo. as a
left join work.GSE as b on (a.rut=b.rut)
where MARCA_TIPO_TR NOT in ("DEBITO RIPLEY", "MCD RIPLEY", "TR")
group by 
periodo,
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;

%end;
%else %do;

proc sql;
create table TDA_TC (
periodo num,
GSE CHAR(99),
categoria CHAR(99),
gerencia CHAR(99),
MARCA_TIPO CHAR(99),
venta_Q num
)
;QUIT;


proc sql;
create table TDA_TD (
periodo num,
GSE CHAR(99),
categoria CHAR(99),
gerencia CHAR(99),
MARCA_TIPO CHAR(99),
venta_Q num
)
;QUIT;


proc sql;
create table TDA_OMP (
periodo num,
GSE CHAR(99),
categoria CHAR(99),
gerencia CHAR(99),
MARCA_TIPO CHAR(99),
venta_Q num
)
;QUIT;


%end;


/* CREANDO AGRUPADO */

PROC SQL;
CREATE TABLE AGRUPADO_2 AS
SELECT *
FROM TDA_TC
OUTER UNION CORR

SELECT *
FROM TDA_TD
OUTER UNION CORR

SELECT *
FROM TDA_OMP
;QUIT;


%put------------------------------------------------------------------------------------------;
%put [3] CUENTA CORRIENTE CAPTACION(Q)/STOCK(Q);
%put------------------------------------------------------------------------------------------;


/* STOCK CLIENTES */ 
/* PEDIR AYUDA A PEDRO PARA QUE CREE TABLA VACIA EN PERIODOS ANTES DE LA CREACION DE CC  */



%let path_ora      = '(DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SID = ripleyc)))'; 
%let user_ora      = 'RIPLEYC'; 
%let pass_ora      = 'ri99pley';
%let conexion_ora  = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 


PROC SQL  NOERRORSTOP;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );

create table SB_Stock_Cuenta_corriente  as
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

proc sql;
create table stock_cc as 
select 
&periodo as periodo,
GSE, 
"STOCK CC" AS categoria,
"CUENTA CORRIENTE" AS gerencia,
"Q" AS MARCA_TIPO,
COUNT(a.RUT) as venta_Q
from SB_Stock_Cuenta_corriente AS a
left join work.GSE as b on (a.RUT=b.rut)
where floor(FECHA_APERTURA/100)<&periodo.  and (Fecha_Cierre is null or floor(Fecha_Cierre/100)>&periodo.) 
group by 
periodo, 
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT; 


/*Base de clientes captados CC*/

proc sql;
create table captacion_CC as 
select 
&periodo as periodo,
GSE, 
"CAPTACION CC" AS categoria,
"CUENTA CORRIENTE" AS gerencia,
"Q" AS MARCA_TIPO,
COUNT(a.RUT) as venta_Q
from SB_Stock_Cuenta_corriente AS a
left join work.GSE as b on (a.RUT=b.rut)
where floor(FECHA_APERTURA/100)=&periodo.
and DESCRIP_PRODUCTO ="CUENTA_CORRIENTE"
group by 
periodo, 
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;


/* CREANDO AGRUPADO */

PROC SQL;
CREATE TABLE AGRUPADO_3 AS
SELECT *
FROM captacion_CC
OUTER UNION CORR

SELECT *
FROM stock_cc
;QUIT;


%put------------------------------------------------------------------------------------------;
%put [4] TAM:TR:TD CAPTACION(Q)/STOCK(Q);
%put------------------------------------------------------------------------------------------;

/*Base de clientes captados TAM*/

proc sql;
create table captacion_TAM as 
select RUT_CLIENTE,
&periodo as periodo,
GSE, 
case
when producto="TAM" then "CAPTACION TAM"
when producto="CAMBIO DE PRODUCTO" the "CAMBIO DE PRODUCTO"
end as categoria,
"TAM" as gerencia,
"Q" AS MARCA_TIPO
from result.capta_salida as a
left join work.GSE as b on (a.RUT_CLIENTE=b.rut)
where fecha between "&ini."d and "&fin."d 
and producto in ("TAM", "CAMBIO DE PRODUCTO")
;QUIT;

%if (%sysfunc(exist(publicin.ACT_TR_&Periodo.))) %then %do;

proc sql;
create table ACTIVIDAD_TAM as 
select rut,
VU_C_PRIMA,
MARCA_BASE
from  publicin.ACT_TR_&Periodo.
;QUIT;

%end;
%else %do;

proc sql;
create table ACTIVIDAD_TAM (
rut num,
VU_C_PRIMA char(99),
MARCA_BASE char(99)
)
;QUIT;

%end;

/*Base de clientes stock TAM*/
PROC SQL;
CREATE TABLE STOCK_TAM AS 
SELECT  
&periodo as periodo, 
GSE, 
"STOCK TAM" AS categoria,
"TAM" AS gerencia,
"Q" AS MARCA_TIPO,
COUNT(A.RUT) AS venta_Q
FROM ACTIVIDAD_TAM AS A 
left join work.GSE as b on (a.rut=b.rut)
WHERE VU_C_PRIMA="VU" and MARCA_BASE in ("TAM","TAM_CHIP") and a.rut not in (select c.RUT_CLIENTE from captacion_TAM as c) /* TOMANDO EN CONSIDERACION QUE SEAN SOLO LAS VIGENTES, SINO SACAR FILTRO DE VU_C_PRIMA="VU" */
group by 
periodo, 
GSE,
categoria,
gerencia,
MARCA_TIPO,
vu_c_prima
;QUIT;


/*Base de clientes captados TR*/
proc sql;
create table captacion_TR as 
select RUT_CLIENTE,
&periodo as periodo,
GSE, 
"CAPTACION TR" AS categoria,
"TR" AS gerencia,
"Q" AS MARCA_TIPO,
COUNT(RUT_CLIENTE) as venta_Q
from result.capta_salida as a
left join work.GSE as b on (a.RUT_CLIENTE=b.rut)
where fecha between "&ini."d and "&fin."d  
and producto = "TR"
;QUIT;


%if (%sysfunc(exist(publicin.ACT_TR_&Periodo.))) %then %do;

proc sql;
create table ACTIVIDAD_TR as 
select rut,
VU_C_PRIMA,
MARCA_BASE
from  publicin.ACT_TR_&Periodo.
;QUIT;

%end;
%else %do;

proc sql;
create table ACTIVIDAD_TR (
rut num,
VU_C_PRIMA char(99),
MARCA_BASE char(99)
)
;QUIT;

%end;



/*Base de clientes stock TR*/
PROC SQL;
CREATE TABLE STOCK_TR AS 
SELECT  
&periodo as periodo, 
GSE, 
"STOCK TR" AS categoria,
"TR" AS gerencia,
"Q" AS MARCA_TIPO,
COUNT(A.RUT) AS venta_Q
FROM ACTIVIDAD_TR AS A 
left join work.GSE as b on (a.rut=b.rut)
WHERE VU_C_PRIMA="VU" and MARCA_BASE in ("CREDITO_2000","ITF") and a.rut not in (select c.RUT_CLIENTE from captacion_TR as c) /* TOMANDO EN CONSIDERACION QUE SEAN SOLO LAS VIGENTES, SINO SACAR FILTRO DE VU_C_PRIMA="VU" */
group by 
periodo, 
GSE,
categoria,
gerencia,
MARCA_TIPO,
vu_c_prima
;QUIT;


/* STOCK CLIENTES */ 


/*Conexion a FISA*/

%let path_ora = '(DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SID = ripleyc)))';
%let user_ora = 'RIPLEYC';
%let pass_ora = 'ri99pley';
%let conexion_ora = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.;
%put &conexion_ora.;PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );create table SB_Stock_Cuenta_Vista as
select * from connection to ORACLE
(
SELECT
CAST(SUBSTR(a.cli_identifica,1,length(a.cli_identifica)-1) AS INT) rut,
SUBSTR(a.cli_identifica,length(a.cli_identifica),1) dv,
/*b.vis_pro,*/
b.vis_numcue cuenta,
/*b.VIS_TIP TIPO_PRODUCTO,*/
/*b.vis_fechape,*/
cast(TO_CHAR( b.vis_fechape,'YYYYMMDD') as INT) as FECHA_APERTURA,
/*b.VIS_FECHCIERR,*/
cast(TO_CHAR( b.VIS_FECHCIERR,'YYYYMMDD') as INT) as FECHA_CIERRE,
/*b.vis_status estado,*/
CASE WHEN b.VIS_PRO=4 THEN 'CUENTA_VISTA'
WHEN b.VIS_PRO=40 THEN 'LCA' END DESCRIP_PRODUCTO,
CASE WHEN b.vis_status ='9' THEN 'cerrado'
when b.vis_status ='2' then 'vigente' end as estado_cuenta,
/*c.DES_CODTAB,*/
b.VIS_SUC as SUCURSAL_APERTURA,
c.DES_CODIGO COD_CIERRE_CONTRATO,
c.DES_DESCRIPCION DESC_CIERRE_CONTRATO
from tcap_vista b
inner join tcli_persona a
on(a.cli_codigo=b.vis_codcli)
left join tgen_desctabla c
on(b.VIS_CODTAB=c.DES_CODTAB) and (b.VIS_CAUCIERR=c.DES_CODIGO)where
b.vis_mod=4
and (b.VIS_PRO=4 or b.VIS_PRO=40)
and b.vis_tip=1
AND (b.vis_status='2' or b.vis_status='9')
) ;
disconnect from ORACLE;
QUIT;



proc sql;
create table stock_TD as 
select 
&periodo as periodo,
GSE, 
"STOCK TD" AS categoria,
"TD" AS gerencia,
"Q" AS MARCA_TIPO,
COUNT(a.RUT) as venta_Q
from SB_Stock_Cuenta_VISTA AS a
left join work.GSE as b on (a.RUT=b.rut)
where  floor(FECHA_APERTURA/100)<&periodo.  and (Fecha_Cierre is null or floor(Fecha_Cierre/100)>&periodo.)  /* SE MIRARAN SOLO LAS QUE ESTAN EN STCOK (DESDE VISTA HOY), SI NO, BORRAR CONDICION DE ESTADO_CUENTA_VIGENTE */
group by 
periodo, 
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT; 

/*Base de clientes captados TD*/
proc sql;
create table captacion_TD as 
select 
&periodo as periodo,
GSE, 
"CAPTACION TD" AS categoria,
"TD" AS gerencia,
"Q" AS MARCA_TIPO,
COUNT(a.rut) as venta_Q
from SB_Stock_Cuenta_VISTA AS a
left join work.GSE as b on (a.RUT=b.rut)
where  floor(FECHA_APERTURA/100)=&periodo.  
group by 
periodo, 
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;


/* CREANDO AGRUPADO */

PROC SQL;
CREATE TABLE AGRUPADO_4 AS
SELECT periodo, 
GSE,
categoria,
gerencia,
MARCA_TIPO,
COUNT(RUT_CLIENTE) as venta_Q
FROM captacion_TAM
group by 
periodo, 
GSE,
categoria,
gerencia,
MARCA_TIPO
OUTER UNION CORR

SELECT *
FROM STOCK_TAM
OUTER UNION CORR

SELECT periodo, 
GSE,
categoria,
gerencia,
MARCA_TIPO,
COUNT(RUT_CLIENTE) as venta_Q
FROM captacion_TR
group by 
periodo, 
GSE,
categoria,
gerencia,
MARCA_TIPO
OUTER UNION CORR

SELECT *
FROM STOCK_TR
OUTER UNION CORR

SELECT *
FROM captacion_TD
OUTER UNION CORR

SELECT *
FROM stock_TD
;QUIT;

%put------------------------------------------------------------------------------------------;
%put [5] COLOCACIONES AV/SAV/CONSUMO;
%put------------------------------------------------------------------------------------------;

/* COLOCACIONES AV */
PROC SQL;
CREATE TABLE COLOCACIONES_AV AS
SELECT &PERIODO AS periodo, GSE, "COLOCACIONES" as categoria, "AV" as gerencia, "COLOCACIONES" AS MARCA_TIPO,
sum(CAPITAL) as venta_Q
FROM PUBLICIN.TRX_AV_&periodo. as a
left join work.GSE as b on (a.RUT=b.rut)
group by 
periodo, 
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;

/* COLOCACIONES SAV */
PROC SQL;
CREATE TABLE COLOCACIONES_SAV AS
SELECT &PERIODO AS periodo, GSE, "COLOCACIONES" as categoria, "SAV" as gerencia, "COLOCACIONES" AS MARCA_TIPO,
sum(CAPITAL) as venta_Q
FROM PUBLICIN.TRX_SAV_&periodo. as a
left join work.GSE as b on (a.RUT=b.rut)
group by 
calculated periodo, 
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;

/* COLOCACIONES CONSUMO */
PROC SQL;
CREATE TABLE COLOCACIONES_CONSUMO AS
SELECT &PERIODO AS periodo, GSE, "COLOCACIONES" as categoria, "CONSUMO" as gerencia, "COLOCACIONES" AS MARCA_TIPO,
sum(VENTA_LIQUIDA) as venta_Q
FROM PUBLICIN.TRX_CONSUMO_&periodo. as a
left join work.GSE as b on (a.RUT=b.rut)
group by 
calculated periodo, 
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;


/* CREANDO AGRUPADO */

PROC SQL;
CREATE TABLE AGRUPADO_5 AS
SELECT *
FROM COLOCACIONES_AV
OUTER UNION CORR

SELECT *
FROM COLOCACIONES_SAV
OUTER UNION CORR

SELECT *
FROM COLOCACIONES_CONSUMO
;QUIT;

%put------------------------------------------------------------------------------------------;
%put [6] CUPO PROMEDIO INDUSTRIA | CUPO PROMEDIO BR;
%put------------------------------------------------------------------------------------------;


%if (%sysfunc(exist(publicin.LCA_&Periodo.))) %then %do;


proc sql;
create table work.rutero_TP as
select
GSE, TC_Cupo,
MONTO_LINEA_DISPONIBLE,
NRO_INST_CREDITO_CONSUMO,
t1.rut
from publicin.TABLON_PRODUCTOS_&Periodo. t1
left join publicri.R04_&periodo_R04. t2 on t1.rut=t2.rut
left join work.GSE t3 on t1.rut=t3.rut
where t1.rut in (select rut from publicin.act_Tr_&Periodo. where vu_c_prima='VU')
;quit;

/* CUPO PROMEDIO INDUSTRIA DE CLIENTS BR */
proc sql;
create table BENCH_INDUSTRIA as
select
&periodo as periodo,
GSE,
"CUPO PROMEDIO INDUSTRIA" as categoria, "CUPO" as gerencia, "CUPO" AS MARCA_TIPO,
(sum(((MONTO_LINEA_DISPONIBLE*1000)/(case when NRO_INST_CREDITO_CONSUMO>0 then NRO_INST_CREDITO_CONSUMO else 1 end) )*0.7 )/count(rut)) as venta_Q
from rutero_TP t1
group by
periodo,
GSE,
categoria,
gerencia,
MARCA_TIPO
;quit;

/* CUPO PROMEDIO BR */
proc sql;
create table BENCH_BR as
select
&periodo as periodo,
GSE,
"CUPO PROMEDIO BR" as categoria, "CUPO" as gerencia, "CUPO" AS MARCA_TIPO,
(sum(TC_Cupo)/count(rut)) as venta_Q
from rutero_TP t1
group by
periodo,
GSE,
categoria,
gerencia,
MARCA_TIPO
;quit;


/* N CLIENTES */
proc sql;
create table CLIENTES as
select
&periodo as periodo,
GSE,
"CLIENTES" as categoria, "CUPO" as gerencia, "CUPO" AS MARCA_TIPO,
(count(rut)) as venta_Q
from rutero_TP t1
group by
periodo,
GSE,
categoria,
gerencia,
MARCA_TIPO
;quit;


PROC SQL;
CREATE TABLE AGRUPADO_6 as
SELECT *
FROM WORK.BENCH_INDUSTRIA
OUTER UNION CORR

SELECT *
FROM WORK.BENCH_BR
OUTER UNION CORR

SELECT *
FROM WORK.CLIENTES
;QUIT;

%end;
%else %do;

proc sql;
create table AGRUPADO_6 (
periodo num,
GSE CHAR(99),
categoria CHAR(99),
gerencia CHAR(99),
MARCA_TIPO CHAR(99),
venta_Q num
)
;QUIT;

%end;


%put------------------------------------------------------------------------------------------;
%put [7] PD (PROBABILIDAD DE INCUMPLIMIENTO) PD_NM=PD DE LA CARTERA;
%put------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE AGRUPADO_7 as
SELECT 
&periodo as periodo,
b.GSE, 
"PROMEDIO PD" as categoria, "PD" as gerencia, "PD" AS MARCA_TIPO,
avg(a.PD_NM) as venta_Q
from PUBLICRI.PD_SAV_UNIF_&periodo as a 
left join work.GSE as b on (a.RUT_REGISTRO_CIVIL=b.rut)
group by
periodo,
GSE,
categoria,
gerencia,
MARCA_TIPO
;quit;

%put------------------------------------------------------------------------------------------;
%put [8] SOW (MONTO | CLIENTES | SOW);
%put------------------------------------------------------------------------------------------;
/* MONTO (COLOCACIONES) SBIF */


%if (%sysfunc(exist(KMARTINE.SBIF_ACUM_GSE_RAUL))) %then %do;

PROC SQL;
CREATE TABLE COLOCACIONES_SOW AS 
SELECT 
&periodo as periodo,
CASE 
WHEN GSE="AB1" THEN "AB"
WHEN GSE in ("C1A","C1B") THEN "C1"
WHEN GSE="C2" THEN "C2"
WHEN GSE="C3" THEN "C3"
WHEN GSE="D" THEN "D"
WHEN GSE="E" THEN "E"
ELSE "" 
END AS GSE,
"COLOCACIONES SOW BR" as categoria, "SOW" as gerencia, "COLOCACIONES" AS MARCA_TIPO,
(SUM(t1.sum_Dda_Ripley)) AS venta_Q
FROM KMARTINE.SBIF_ACUM_GSE_RAUL t1
where Categoria_Dda_Cons in ("1. Ripley y SBIF","2. Solo Ripley") and periodo=&periodo.
GROUP BY
periodo,
CALCULATED GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;
%end;
%else %do;

proc sql;
create table COLOCACIONES_SOW (
periodo num,
GSE CHAR(99),
categoria CHAR(99),
gerencia CHAR(99),
MARCA_TIPO CHAR(99),
venta_Q num
)
;QUIT;
%end;


/* CLIENTES SBIF */


%if (%sysfunc(exist(KMARTINE.SBIF_ACUM_GSE_RAUL))) %then %do;

PROC SQL;
CREATE TABLE CLIENTES_SOW AS 
SELECT 
&periodo as periodo,
CASE 
WHEN GSE="AB1" THEN "AB"
WHEN GSE in ("C1A","C1B") THEN "C1"
WHEN GSE="C2" THEN "C2"
WHEN GSE="C3" THEN "C3"
WHEN GSE="D" THEN "D"
WHEN GSE="E" THEN "E"
ELSE "" 
END AS GSE,
"CLIENTES SOW BR" as categoria, "SOW" as gerencia, "COLOCACIONES" AS MARCA_TIPO,
(SUM(t1.Nro_Clientes)) AS venta_Q
FROM KMARTINE.SBIF_ACUM_GSE_RAUL t1
where Categoria_Dda_Cons in ("1. Ripley y SBIF","2. Solo Ripley") and periodo=&periodo.
GROUP BY
periodo,
calculated GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;

%end;
%else %do;

proc sql;
create table CLIENTES_SOW (
periodo num,
GSE CHAR(99),
categoria CHAR(99),
gerencia CHAR(99),
MARCA_TIPO CHAR(99),
venta_Q num

)
;QUIT;

%end;


/* SOW */


%if (%sysfunc(exist(KMARTINE.SBIF_ACUM_GSE_RAUL))) %then %do;

/* INFO BANCA */

PROC SQL;
CREATE TABLE BANCA_MONTO AS 
SELECT 
&periodo as periodo,
CASE 
WHEN GSE="AB1" THEN "AB"
WHEN GSE in ("C1A","C1B") THEN "C1"
WHEN GSE="C2" THEN "C2"
WHEN GSE="C3" THEN "C3"
WHEN GSE="D" THEN "D"
WHEN GSE="E" THEN "E"
ELSE "" 
END AS GSE,
"MONTO SOW BANCA" as categoria, "SOW" as gerencia, "COLOCACIONES" AS MARCA_TIPO,
(SUM(t1.sum_SBF_Dda_Cred_Cons)) AS venta_Q
FROM KMARTINE.SBIF_ACUM_GSE_RAUL t1
where Categoria_Dda_Cons in ("1. Ripley y SBIF", "3. Solo SBIF") and periodo=&periodo.
GROUP BY
periodo,
calculated GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;


PROC SQL;
CREATE TABLE BANCA_CLIENTES AS 
SELECT 
&periodo as periodo,
CASE 
WHEN GSE="AB1" THEN "AB"
WHEN GSE in ("C1A","C1B") THEN "C1"
WHEN GSE="C2" THEN "C2"
WHEN GSE="C3" THEN "C3"
WHEN GSE="D" THEN "D"
WHEN GSE="E" THEN "E"
ELSE "" 
END AS GSE,
"CLIENTES SOW BANCA" as categoria, "SOW" as gerencia, "COLOCACIONES" AS MARCA_TIPO,
(SUM(t1.Nro_Clientes)) AS venta_Q
FROM KMARTINE.SBIF_ACUM_GSE_RAUL t1
where Categoria_Dda_Cons in ("1. Ripley y SBIF", "3. Solo SBIF") and periodo=&periodo.
GROUP BY
periodo,
calculated GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;

%end;
%else %do;

proc sql;
create table BANCA_MONTO (
periodo num,
GSE CHAR(99),
categoria CHAR(99),
gerencia CHAR(99),
MARCA_TIPO CHAR(99),
venta_Q num

)
;QUIT;

proc sql;
create table BANCA_CLIENTES (
periodo num,
GSE CHAR(99),
categoria CHAR(99),
gerencia CHAR(99),
MARCA_TIPO CHAR(99),
venta_Q num

)
;QUIT;

%end;


/* AGRUPADO FINAL SOW */

PROC SQL;
CREATE TABLE AGRUPADO_8 AS 
SELECT *
FROM COLOCACIONES_SOW
outer union corr

SELECT *
FROM CLIENTES_SOW
outer union corr

SELECT *
FROM BANCA_MONTO
outer union corr

SELECT *
FROM BANCA_CLIENTES
;QUIT;



%put------------------------------------------------------------------------------------------;
%put [9] RECLAMOS NORMATIVOS | NPS;
%put------------------------------------------------------------------------------------------;


PROC SQL;
CREATE TABLE RECLAMOS_NORMATIVOS AS 
SELECT
&periodo. as periodo, 
t2.GSE,
"N RECLAMOS" as categoria, "RECLAMOS NORMATIVOS" as gerencia, "CANTIDAD (Q)" AS MARCA_TIPO,
count(t1.rut) as venta_Q
FROM work.DATA_RECLAMOS_NORMATIVOS t1
left join work.GSE as t2 on (t1.rut=t2.rut)
where t1.fecha=&periodo. and upcase(Tipo_Canal)="NORMATIVO"
group by
periodo,
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;

PROC SQL;
CREATE TABLE RECLAMOS_INTERNOS AS 
SELECT
&periodo. as periodo, 
t2.GSE,
"N RECLAMOS" as categoria, "RECLAMOS INTERNOS" as gerencia, "CANTIDAD (Q)" AS MARCA_TIPO,
count(t1.rut) as venta_Q
FROM work.DATA_RECLAMOS_NORMATIVOS t1
left join work.GSE as t2 on (t1.rut=t2.rut)
where t1.fecha=&periodo. and upcase(Tipo_Canal)="INTERNO"
group by
periodo,
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;

PROC SQL;
CREATE TABLE NPS_NOTA as
select 
&periodo. as periodo, 
t2.GSE,
"%" as categoria, "NPS TRANSACCIONAL" as gerencia, "%" AS MARCA_TIPO,
(SUM(t1.NPS_PROMOTORES)-SUM(t1.NPS_DETRACTORES))*1./SUM(1) AS venta_Q 
FROM work.DATA_NPS as t1
left join work.GSE as t2 on (t1.rut=t2.rut)
where t1.fecha=&periodo.
GROUP BY 
periodo,
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;

PROC SQL;
CREATE TABLE NPS_N as
select 
&periodo. as periodo, 
t2.GSE,
"Q" as categoria, "NPS TRANSACCIONAL" as gerencia, "Q" AS MARCA_TIPO,
count(*) AS venta_Q 
FROM work.DATA_NPS as t1
left join work.GSE as t2 on (t1.rut=t2.rut)
where t1.fecha=&periodo.
GROUP BY 
periodo,
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;

PROC SQL;
CREATE TABLE AGRUPADO_9 AS
SELECT *
FROM RECLAMOS_NORMATIVOS
OUTER UNION CORR

SELECT *
FROM RECLAMOS_INTERNOS
OUTER UNION CORR

SELECT *
FROM NPS_NOTA
OUTER UNION CORR

SELECT *
FROM NPS_N
;QUIT;

%put------------------------------------------------------------------------------------------;
%put [10] FRAUDE;
%put------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE TICKETS AS
SELECT
&periodo. as periodo, 
t2.GSE,
"Q" as categoria, "TICKETS FRAUDES" as gerencia, "Q" AS MARCA_TIPO,
count(T1.RUTsinDV) AS venta_Q 
FROM work.AURIS_Fraude_Tickets as t1
left join work.GSE as t2 on (t1.RUTsinDV=t2.rut)
WHERE t1.periodo=&periodo.
GROUP BY
periodo,
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;


%if (%sysfunc(exist(publicin.ACT_TR_&Periodo.))) %then %do;

proc sql;
create table ACTIVIDAD as 
select rut,
VU_C_PRIMA,
MARCA_BASE
from  publicin.ACT_TR_&Periodo.
;QUIT;

%end;
%else %do;

proc sql;
create table ACTIVIDAD (
rut num,
VU_C_PRIMA char(99),
MARCA_BASE char(99)
)
;QUIT;

%end;

PROC SQL;
CREATE TABLE CLIENTES_TC AS 
SELECT  
&periodo as periodo, 
GSE,
COUNT(A.RUT) AS venta_Q
FROM ACTIVIDAD AS A 
left join work.GSE as b on (a.rut=b.rut)
WHERE VU_C_PRIMA="VU" and MARCA_BASE in ("TAM","TAM_CHIP","CREDITO_2000","ITF")
group by 
periodo, 
GSE,
vu_c_prima
;QUIT;

PROC SQL;
CREATE TABLE TICKET_PROM AS 
SELECT
T1.periodo, 
t1.GSE,
"%" as categoria, "TICKETS/CLIENTES TC" as gerencia, "%" AS MARCA_TIPO,
(T1.venta_Q/T2.venta_Q) AS venta_Q 
FROM TICKETS as T1
LEFT JOIN CLIENTES_TC as T2 on (T1.GSE=T2.GSE) AND (T1.PERIODO=T2.PERIODO)
;QUIT;


PROC SQL;
CREATE TABLE MONTO AS
SELECT
&periodo. as periodo, 
t2.GSE,
"MONTO" as categoria, "MONTO FRAUDES" as gerencia, "MONTO" AS MARCA_TIPO,
SUM(T1.Monto_Desconocido) AS venta_Q 
FROM work.AURIS_FRAUDE_MONTOS_DESCONOCIDOS as t1
left join work.GSE as t2 on (t1.RUTsinDV=t2.rut)
WHERE t1.periodo=&periodo.
and t1.Marca_Corte=1
GROUP BY
periodo,
GSE,
categoria,
gerencia,
MARCA_TIPO
;QUIT;

PROC SQL;
CREATE TABLE PUNTOS_BASE AS 
SELECT
T1.periodo, 
t1.GSE,
"%" as categoria, "PUNTOS BASE" as gerencia, "%" AS MARCA_TIPO,
(T1.venta_Q/(T2.venta_Q+T3.venta_Q/*+T4.venta_Q+T5.venta_Q*/)) AS venta_Q 
FROM MONTO as T1
LEFT JOIN spos_AUT as T2 on         (T1.GSE=T2.GSE) AND (T1.PERIODO=T2.PERIODO)
LEFT JOIN TDA_TC as T3 on           (T1.GSE=T3.GSE) AND (T1.PERIODO=T3.PERIODO)
LEFT JOIN COLOCACIONES_AV as T4 on  (T1.GSE=T4.GSE) AND (T1.PERIODO=T4.PERIODO)
LEFT JOIN COLOCACIONES_SAV as T5 on (T1.GSE=T5.GSE) AND (T1.PERIODO=T5.PERIODO)
;QUIT;


PROC SQL;
CREATE TABLE AGRUPADO_10 AS
SELECT *
FROM TICKETS
OUTER UNION CORR

SELECT *
FROM TICKET_PROM
OUTER UNION CORR

SELECT *
FROM PUNTOS_BASE

;QUIT;



%put------------------------------------------------------------------------------------------;
%put FINAL QUERY;
%put------------------------------------------------------------------------------------------;


%if (%sysfunc(exist(&libreria..PANEL_CONTROL_C1C2))) %then %do;
 
%end;
%else %do;

PROC  SQL;
CREATE TABLE &libreria..PANEL_CONTROL_C1C2 
(
periodo	 num,
GSE char(99),
categoria char(99),
gerencia char(99), 
MARCA_TIPO char(99),
venta_Q num
)
;quit;
%end;


proc sql;
delete *
from &libreria..PANEL_CONTROL_C1C2 
where periodo=&periodo.
;QUIT;

proc sql;
insert into &libreria..PANEL_CONTROL_C1C2
select *
from AGRUPADO_1
;QUIT;

proc sql;
insert into &libreria..PANEL_CONTROL_C1C2
select *
from AGRUPADO_2
;QUIT;

proc sql;
insert into &libreria..PANEL_CONTROL_C1C2
select *
from AGRUPADO_3
;QUIT;

proc sql;
insert into &libreria..PANEL_CONTROL_C1C2
select *
from AGRUPADO_4
;QUIT;

proc sql;
insert into &libreria..PANEL_CONTROL_C1C2
select *
from AGRUPADO_5
;QUIT;

proc sql;
insert into &libreria..PANEL_CONTROL_C1C2
select *
from AGRUPADO_6
;QUIT;

proc sql;
insert into &libreria..PANEL_CONTROL_C1C2
select *
from AGRUPADO_7
;QUIT;

proc sql;
insert into &libreria..PANEL_CONTROL_C1C2
select *
from AGRUPADO_8
;QUIT;

proc sql;
insert into &libreria..PANEL_CONTROL_C1C2
select *
from AGRUPADO_9
;QUIT;

proc sql;
insert into &libreria..PANEL_CONTROL_C1C2
select *
from AGRUPADO_10
;QUIT;

proc sql;
create table &libreria..PANEL_CONTROL_C1C2  as 
select 
*
from &libreria..PANEL_CONTROL_C1C2 
;QUIT;

%mend PANEL_CONTROL_C1C2;


%PANEL_CONTROL_C1C2(	0, &Libreria.	);
%PANEL_CONTROL_C1C2(	1, &Libreria.	);

PROC SQL;
DROP TABLE ACTIVIDAD_TAM;

PROC SQL;
DROP TABLE ACTIVIDAD_TR;

PROC SQL;
DROP TABLE AGRUPADO_1;

PROC SQL;
DROP TABLE AGRUPADO_2;

PROC SQL;
DROP TABLE AGRUPADO_3;

PROC SQL;
DROP TABLE AGRUPADO_4;

PROC SQL;
DROP TABLE AGRUPADO_5;

PROC SQL;
DROP TABLE AGRUPADO_6;

PROC SQL;
DROP TABLE AGRUPADO_7;

PROC SQL;
DROP TABLE AGRUPADO_8;

PROC SQL;
DROP TABLE AGRUPADO_9;

PROC SQL;
DROP TABLE BANCA_CLIENTES;

PROC SQL;
DROP TABLE BANCA_MONTO;

PROC SQL;
DROP TABLE CAPTACION_CC;

PROC SQL;
DROP TABLE CAPTACION_TAM;

PROC SQL;
DROP TABLE CAPTACION_TD;

PROC SQL;
DROP TABLE CAPTACION_TR;

PROC SQL;
DROP TABLE CLIENTES_SOW;

PROC SQL;
DROP TABLE COLOCACIONES_AV;

PROC SQL;
DROP TABLE COLOCACIONES_CONSUMO;

PROC SQL;
DROP TABLE COLOCACIONES_SAV;

PROC SQL;
DROP TABLE COLOCACIONES_SOW;

PROC SQL;
DROP TABLE GSE;

PROC SQL;
DROP TABLE NPS_N;

PROC SQL;
DROP TABLE NPS_NOTA;

PROC SQL;
DROP TABLE RECLAMOS_NORMATIVOS;

PROC SQL;
DROP TABLE SB_STOCK_CUENTA_CORRIENTE;

PROC SQL;
DROP TABLE SB_STOCK_CUENTA_VISTA;

PROC SQL;
DROP TABLE SPOS_AUT;

PROC SQL;
DROP TABLE SPOS_MAESTRO;

PROC SQL;
DROP TABLE SPOS_MCD;

PROC SQL;
DROP TABLE STOCK_CC;

PROC SQL;
DROP TABLE STOCK_TAM;

PROC SQL;
DROP TABLE STOCK_TD;

PROC SQL;
DROP TABLE STOCK_TR;

PROC SQL;
DROP TABLE TDA_OMP;

PROC SQL;
DROP TABLE STOCK_TR;

PROC SQL;
DROP TABLE TDA_TC;

PROC SQL;
DROP TABLE TDA_TD;

PROC SQL;
DROP TABLE TICKETS;

PROC SQL;
DROP TABLE ACTIVIDAD;

PROC SQL;
DROP TABLE CLIENTES_TC;

PROC SQL;
DROP TABLE TICKET_PROM;

PROC SQL;
DROP TABLE MONTO;

PROC SQL;
DROP TABLE PUNTOS_BASE;

PROC SQL;
DROP TABLE AGRUPADO_10;




