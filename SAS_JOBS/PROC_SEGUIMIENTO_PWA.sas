/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROC_SEGUIMIENTO_PWA 		================================*/
/* CONTROL DE VERSIONES
/* 2022-08-25 -- V04-- Sergio J. -- Se añade sentencia include para borrar y exportar a RAW
/* 2022-07-12 -- V03-- Sergio J. -- Se agrega código de exportación para alimentar a Tableau
/* 2020-06-03 ---- Actualización incluye retiro de plastico
/* 2020-05-20 ---- Original 
*/
/*==================================================================================================*/

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

proc sql;
&mz_connect_BANCO;
create table work.sucursal as
SELECT *
from  connection to BANCO(
select *
from tgen_sucursal  /*MAESTRA sucursales banco*/
) as X
;QUIT;

proc sql;

&mz_connect_BANCO;
create table work.SB_Stock_Cuenta_Vista as
SELECT 
cli_identifica as rut_DV,
INPUT((SUBSTR(cli_identifica,1,(LENGTH(cli_identifica)-1))),BEST.) AS RUT,
Vis_suc as sucursal,
vis_pro,
vis_numcue as cuenta, 
VIS_TIP as TIPO_PRODUCTO,
vis_fechape, 
VIS_FECHCIERR, 
vis_status as estado,
vis_numcue AS CONTRATO,
CASE 
WHEN VIS_PRO=4 THEN 'CUENTA_VISTA' 
WHEN VIS_PRO=40 THEN 'LCA' 
END AS DESCRIP_PRODUCTO,
CASE WHEN vis_status ='9' THEN 1 else 0 end as cerrado,
CASE WHEN vis_status ='2' THEN 1 else 0 end as vigente,
INPUT(SUBSTR(put(datepart(VIS_FECHAPE),yymmddn8.),1,8),best.) as Fecha_Apertura, /* periodo alta cv*/
INPUT(SUBSTR(put(datepart(VIS_FECHCIERR),yymmddn8.),1,8),best.) as Fecha_Cierre /* periodo baja cv*/
from  connection to BANCO(

select *
from tcli_persona /*MAESTRA DE CLIENTES BANCO*/
,tcap_vista /*SALDOS CUENTAS VISTAS */
where cli_codigo=vis_codcli
and vis_mod=4/*cuenta vista*/
and (VIS_PRO=4/*CV*/ or VIS_PRO=40/*LCA*/)
and vis_tip=1  /*persona no juridica*/
AND (vis_status='2' or vis_status='9') /*solo aquellas con estado vigente o cerrado*/

) as X

;QUIT;

/*cuentas aperturadas a partir del 19/05/2020*/

proc sql;
create table cuentas as 
select 
a.RUT,
a.sucursal,
b.SUC_NOMBRE as nombre_sucursal,
a.VIS_PRO,
a.cuenta,
datepart(a.VIS_FECHAPE) format=date9. as fec_apertura,
a.estado,
a.DESCRIP_PRODUCTO,
a.cerrado,
a.vigente,
a.Fecha_Apertura,
a.Fecha_Cierre
from SB_Stock_Cuenta_Vista as a
left join sucursal as b
on(a.sucursal=b.SUC_CODIGO)
;QUIT;

/*marca PDWA*/

proc sql;
create table marca as 
select 
a.*,
case when  a.fec_apertura>='19may2020'd and a.sucursal=70 then 'DIGITAL'
else 'PRESENCIAL' end as PWA
from cuentas as a
;QUIT;

/*cuenta en rsat*/

%let path_ora        = '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=192.168.84.76)(PORT=1521))(CONNECT_DATA=(SERVER=dedicated)(SID=SEGCOM)))'; 
%let user_ora        = 'PMUNOZC'; 
%let pass_ora        = 'pmun3012';
 
%let conexion_ora    = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 
LIBNAME DBLIBORA     &conexion_ora. insertbuff=10000 readbuff=10000;   


PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );
 
create table mpdt666 as
select 

CODENT1,
CENTALTA1,
CUENTA1,
input(cuenta2,best.) as cv

from connection to ORACLE
(
select * from MPDT666
 
);
disconnect from ORACLE;
QUIT;

/*datos de la cuenta creada*/

proc sql;
create table datos as 
select 
a.*,
b.CODENT1 ,
b.CENTALTA1 ,
b.CUENTA1,
put(intnx('day',a.fec_apertura,30,'begin'),yymmdd10.) as dias_30,
put(a.fec_apertura, yymmdd10.) as dias_1,
case when put(today(),yymmdd10.) between  calculated dias_1 and calculated dias_30 then 1 else 0 end as dentro_rango
from marca as a
left join mpdt666 as b
on(a.cuenta=b.cv)
;QUIT;

/*dejar max, min fecha*/

proc sql  noprint;
select max(dias_30)  as max,
min(dias_1)  as min
into:max,
:min
from datos 
where 
dentro_rango=1 
and PWA<>'PRESENCIAL'
;QUIT;

%let max="&max";
%let min="&min";

%put max;
%put min;





/*emisión de plastico*/


LIBNAME MPDT  ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME R_BOPERS ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME R_get ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017';

PROC SQL;
CREATE TABLE UNIVERSO_PANES AS 
SELECT INPUT(B.PEMID_GLS_NRO_DCT_IDE_K,BEST.) AS RUT,
A.CODENT,A.CENTALTA,A.CUENTA,A.CALPART,
CAT(A.CODENT,' ',A.CENTALTA,' ',A.CUENTA) as CTTO,
CASE WHEN C.FECBAJA = '0001-01-01' THEN 1 ELSE 0 END AS T_CTTO_VIGENTE,
C.FECALTA as FECALTA_CTTO,C.FECBAJA as FECBAJA_CTTO,
CASE WHEN SUBSTR(G.PAN,1,6) IN('628156') THEN 'CERRADA'
WHEN SUBSTR(G.PAN,1,4) IN('6392') THEN 'CUENTA VISTA'
WHEN SUBSTR(G.PAN,1,6) IN('549070')AND INPUT(LEFT(SUBSTR(G.PAN,1,7)),BEST.) >=5490702 THEN 'TAM CHIP' 
WHEN SUBSTR(G.PAN,1,6) IN('549070')AND INPUT(LEFT(SUBSTR(G.PAN,1,7)),BEST.) <5490702 THEN 'TAM' 
ELSE 'CERRADA' END AS TIPO_TR, 
G.NUMPLASTICO,G.PAN,G.FECCADTAR,G.INDULTTAR,G.NUMBENCTA,
G.FECALTA AS FECALTA_TR, G.FECBAJA AS FECBAJA_TR,
G.INDSITTAR,H.DESSITTAR, G.FECULTBLQ,
CASE WHEN G.CODBLQ = 1 AND TEXBLQ = 'BLOQUEO TARJETA NO ISO'  THEN 'BLOQUEO TARJETA NO ISO' 
     WHEN G.CODBLQ = 1 AND TEXBLQ NOT IN ('BLOQUEO TARJETA NO ISO') THEN 'ROBO/CODIGO_BLOQUEO' 
     WHEN G.CODBLQ IN (79,98)  THEN 'CAMBIO DE PRODUCTO'
     WHEN G.CODBLQ IN (16,43)  THEN 'FRAUDE' 
     WHEN G.CODBLQ > 1 AND G.CODBLQ NOT IN (16,43,79,98) THEN DESBLQ END AS MOTIVO_BLOQUEO,
CASE WHEN G.INDSITTAR=5 AND G.FECALTA<>'0001-01-01' AND G.FECBAJA='0001-01-01' AND G.CODBLQ=0 /*G.FECULTBLQ='0001-01-01'*/ 
     THEN 1 ELSE 0 END AS T_TR_VIG,
(LEFT(SUBSTR(G.PAN,13,4))) as PAN2, 
CAT(A.CODENT,A.CENTALTA,A.CUENTA,calculated PAN2) as CONTRATO_PAN
FROM R_GET.MPDT013 A /*CONTRATO de Tarjeta*/
INNER JOIN R_GET.MPDT007 C /*CONTRATO*/ ON A.CODENT=C.CODENT AND A.CENTALTA=C.CENTALTA AND A.CUENTA=C.CUENTA 
INNER JOIN R_BOPERS.BOPERS_MAE_IDE B ON INPUT(A.IDENTCLI,BEST.)=B.PEMID_NRO_INN_IDE
INNER JOIN R_GET.MPDT009 G /*Tarjeta*/ ON A.CODENT=G.CODENT AND A.CENTALTA=G.CENTALTA AND A.CUENTA=G.CUENTA AND A.NUMBENCTA=G.NUMBENCTA 
INNER JOIN R_GET.MPDT063 H ON G.CODENT=H.CODENT AND G.INDSITTAR=H.INDSITTAR
LEFT JOIN R_GET.MPDT060 I ON G.CODBLQ=I.CODBLQ
where 
c.FECALTA>=&min. and c.FECALTA<=&max. and c.PRODUCTO='08'
;QUIT;



proc sqL;
create table marca2 as 
select
a.*,
count(distinct case when b.NUMPLASTICO=1 and a.PWA='DIGITAL' and b.FECALTA_TR  between a.dias_1 and a.dias_30 and b.INDSITTAR=5 then b.rut end) as PLASTICO,
b.FECALTA_TR
from datos as a
left join UNIVERSO_PANES as b
on(a.rut=b.rut) and (a.cuenta1=b.cuenta) and 
(a.codent1=b.codent) and (a.centalta1=b.centalta) and b.NUMPLASTICO=1
group by
a.rut,
a.cuenta
;QUIT;


/*dejar en duro*/

proc sql;
delete 
*
from RESULT.seguimiento_capta_digital 
where put(today(),yymmdd10.) between Dias_1 and  dias_30
;QUIT;

proc sql;
create table insertar as 
select 
*
from marca2
where dentro_rango=1
;QUIT;


PROC SQL NOERRORSTOP ;
INSERT INTO RESULT.seguimiento_capta_digital
SELECT distinct
*
FROM insertar
;QUIT;

/*actualizar estado de la cuenta */

PROC SQL;
   CREATE TABLE RESULT.SEGUIMIENTO_CAPTA_DIGITAL AS 
   SELECT t1.RUT, 
          t1.sucursal, 
          t1.nombre_sucursal, 
          t1.VIS_PRO, 
          t1.cuenta, 
          t1.fec_apertura, 
          t2.estado, 
          t1.DESCRIP_PRODUCTO, 
          t2.cerrado, 
          t2.vigente, 
          t1.Fecha_Apertura, 
          t2.Fecha_Cierre, 
          t1.PWA, 
          t1.CODENT1, 
          t1.CENTALTA1, 
          t1.CUENTA1, 
          t1.dias_30, 
          t1.dias_1, 
          t1.dentro_rango, 
          t1.PLASTICO, 
          t1.FECALTA_TR
      FROM RESULT.SEGUIMIENTO_CAPTA_DIGITAL t1
	  left join marca2 as t2
	  on(t1.rut=t2.rut) and (t1.cuenta=t2.cuenta)

;
QUIT;


/*colapso*/
proc sql;
create table RESULT.seguimiento_capta_PWA as 
select 
dhms(today(), 0, 0, time()) format=datetime. as fecha_ejecucion,
sucursal,
nombre_sucursal,
fec_apertura,
estado,
DESCRIP_PRODUCTO,
PWA,
PLASTICO,
abs(input(compress(dias_1,'-','p'),best.)-input(compress(FECALTA_TR,'-','p'),best.)) as dias_en_buscar_PAN,
count(rut) as CUENTAS,
sum(plastico) as TARJETAS_EMITIDAS
from RESULT.seguimiento_capta_digital
group by 
sucursal,
nombre_sucursal,
fec_apertura,
estado,
DESCRIP_PRODUCTO,
PWA,
PLASTICO,
calculated dias_en_buscar_PAN
;QUIT;


/*borrar tablas de paso*/



proc sql;
drop table cuentas
;QUIT;

proc sql;
drop table marca
;QUIT;

proc sql;
drop table sb_stock_cuenta_vista
;QUIT;

proc sql;
drop table sucursal
;QUIT;

proc sql;
drop table datos
;QUIT;

proc sql;
drop table insertar
;QUIT;

proc sql; 
drop table marca2
;QUIT;

proc sql;
drop table mpdt666
;QUIT;

proc sql;
drop table universo_panes
;QUIT;


%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_DELETE.sas";
%borrarOracleRaw(PPFF_CAPTA_DIGITAL);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_EXPORT.sas";
%ExportacionOracleRaw(PPFF_CAPTA_DIGITAL,RESULT.seguimiento_capta_PWA);


