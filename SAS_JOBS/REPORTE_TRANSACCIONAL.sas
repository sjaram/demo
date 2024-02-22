%let n=1;
%let libreria=result;

DATA _NULL_;
periodo = input(put(intnx('month',today(),-&n.,'end'),yymmn6. ),$10.);
periodo_R04 = input(put(intnx('month',today(),-&n.-1,'end'),yymmn6. ),$10.);
INI = put(intnx('month',today(),-&n.,'begin'),date9.);
FIN = put(intnx('month',today(),-&n.,'end'),date9.);
INI_NUM=put(intnx('month',today(),-&n.,'begin'), yymmddn8.);
FIN_NUM=put(intnx('month',today(),-&n.,'end'), yymmddn8.);
FIN_NUM2=put(intnx('month',today(),-&n.+1,'begin'), yymmddn8.);
Call symput("periodo", periodo);
Call symput("periodo_R04", periodo_R04);
Call symput("INI", INI);
Call symput("FIN", FIN);
call symput("INI_NUM",INI_NUM);
call symput("FIN_NUM",FIN_NUM);
call symput("FIN_NUM2",FIN_NUM2);
RUN;

%put &periodo;
%put &periodo_R04;
%put &INI;
%put &FIN;
%put &INI_NUM;
%put &FIN_NUM;
%put &FIN_NUM2;

proc sql   noprint inobs=1;
select 
put(cat(substr(put(&INI_NUM,8.),7,2),'/',substr(put(&INI_NUM,8.),5,2),'/',substr(put(&INI_NUM,8.),1,4)),$10. ) format=$10. as INI_CHAR,
put(cat(substr(put(&FIN_NUM2,8.),7,2),'/',substr(put(&FIN_NUM2,8.),5,2),'/',substr(put(&FIN_NUM2,8.),1,4)),$10.)  format=$10. as FIN_CHAR
into
:INI_CHAR,
:FIN_CHAR
from pmunoz.codigos_capta_cdp
;QUIT;

%put------------------------------------------------------------------------------------------;
%put CUENTA CCTE:TAM:TR:TD ;
%put------------------------------------------------------------------------------------------;
proc sql;
create table captacion_TC as 
select 
&periodo. as periodo,
0 as VENTA,
COUNT(DISTINCT RUT_CLIENTE) AS TRX,
case
when producto not in ("CAMBIO DE PRODUCTO","TR",'CUENTA CORRIENTE','CUENTA VISTA') then "CAPTACION TAM"
when producto="CAMBIO DE PRODUCTO" then "CAPTACION CDP"
when producto="TR" then "CAPTACION TR"
when producto='CUENTA CORRIENTE' then 'CAPTACION CC'
when producto='CUENTA VISTA' then 'CAPTACION CV'
end as DETALLE,
'' AS LUGAR,
'CAPTACION' AS APERTURA
from result.capta_salida as a
where fecha between "&ini."d and "&fin."d
GROUP BY
periodo,
DETALLE,
LUGAR,
APERTURA
;QUIT;

%put------------------------------------------------------------------------------------------;
%put VENTA AV;
%put------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE av AS 
SELECT 
&PERIODO. AS PERIODO,
SUM(CAPITAL) AS VENTA,
SUM(CASE WHEN TRANSACCION='COMPRA' THEN 1 ELSE 0 END)-SUM(CASE WHEN TRANSACCION='NOTA CREDITO' THEN 1 ELSE 0 END) as TRX,
'VENTA AV' as DETALLE,
CASE WHEN VIA='HB' THEN 'DIGITAL'
	 ELSE 'PRESENCIAL' END AS LUGAR,
'VENTA' AS APERTURA
FROM PUBLICIN.TRX_AV_&periodo. 
GROUP BY
periodo,
DETALLE,
CALCULATED LUGAR,
APERTURA
;QUIT;

%put------------------------------------------------------------------------------------------;
%put VENTA SAV;
%put------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE sav AS 
SELECT 
&PERIODO. AS PERIODO,
SUM(CAPITAL) AS VENTA,
SUM(CASE WHEN TRANSACCION='COMPRA' THEN 1 ELSE 0 END)-SUM(CASE WHEN TRANSACCION='NOTA CREDITO' THEN 1 ELSE 0 END) as TRX,
'VENTA SAV' as DETALLE,
CASE WHEN VIA_FINAL='HOME_B' THEN 'DIGITAL'
	 ELSE 'PRESENCIAL' END AS LUGAR,
'VENTA' AS APERTURA
FROM PUBLICIN.TRX_SAV_&periodo.
GROUP BY
CALCULATED PERIODO,
CALCULATED DETALLE,
CALCULATED LUGAR,
CALCULATED APERTURA
;QUIT;

%put------------------------------------------------------------------------------------------;
%put VENTA CONSUMO;
%put------------------------------------------------------------------------------------------;

proc sql;
create table work.Trx_Consumo_Flujo as 
select * 
from ( 
select 
'CONSUMO' as Producto, 
RUT,
10000*year(datepart(FECHA_CONTBLE))+100*month(datepart(FECHA_CONTBLE))+day(datepart(FECHA_CONTBLE)) as Fecha,
PRE_NUMPER as Plazo,
VENTA_LIQUIDA as Monto,
PRE_TASAPAC/12 FORMAT=BEST6.2 as Tasa,
/* PRE_TASAPAC as Tasa,*/ 
SUCURSAL,
&periodo. as Mes
from publicin.TRX_CONSUMO_&periodo.   
) as x 
;quit;


proc sql;
alter table work.Trx_Consumo_Flujo add Canal char(12);
update work.Trx_Consumo_Flujo
set Canal = 'Tlmk'
where SUCURSAL = 'HUERFANOS 1060'
;
update work.Trx_Consumo_Flujo
set Canal = 'Pwa'
where SUCURSAL is missing
;
Quit;

proc sql;
update work.Trx_Consumo_Flujo
set Canal = 'Sucursal'
where Canal is missing
;
Quit;

PROC SQL;
CREATE TABLE consumo AS 
SELECT 
&PERIODO. AS PERIODO,
SUM(Monto) AS VENTA,
COUNT(RUT) AS TRX,
'VENTA CONSUMO' as DETALLE,
CASE WHEN Canal='Pwa' THEN 'DIGITAL'
	 ELSE 'PRESENCIAL' END AS LUGAR,
'VENTA' AS APERTURA
FROM Trx_Consumo_Flujo 
GROUP BY
periodo,
DETALLE,
LUGAR,
APERTURA
;QUIT;

%put------------------------------------------------------------------------------------------;
%put VENTA DAP;
%put------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE DAP_ACUMULADO AS 
SELECT 
&PERIODO. AS PERIODO,
SUM(PDA_CAPITAL) AS VENTA,
COUNT(RUT) AS TRX,
'VENTA DAP ACUMULADA' as DETALLE,
CASE WHEN CODIGO_SUCURSAL=70 THEN 'DIGITAL'
	 ELSE 'PRESENCIAL' END AS LUGAR,
'VENTA' AS APERTURA
FROM PUBLICIN.OPERACIONES_DAP_&periodo.
GROUP BY
periodo,
DETALLE,
CALCULATED LUGAR,
APERTURA
;QUIT;

PROC SQL;
CREATE TABLE DAP_STOCK AS 
SELECT 
&PERIODO. AS PERIODO,
SUM(Capital_Vigente) AS VENTA,
COUNT(RUT) AS TRX,
'VENTA DAP STOCK' as DETALLE,
CASE WHEN Sucursal=70 THEN 'DIGITAL'
	 ELSE 'PRESENCIAL' END AS LUGAR,
'VENTA' AS APERTURA
FROM PUBLICIN.STOCK_DAP_&periodo.
GROUP BY
periodo,
DETALLE,
CALCULATED LUGAR,
APERTURA
;QUIT;

%put------------------------------------------------------------------------------------------;
%put VENTA REF;
%put------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE REF AS 
SELECT 
&PERIODO. AS PERIODO,
SUM(CAPITAL) AS VENTA,
COUNT(RUT) AS TRX,
'VENTA REF' as DETALLE,
CASE WHEN VIA='CALL' THEN 'ASISTIDA'
	 ELSE 'DIGITAL' END AS LUGAR,
'VENTA' AS APERTURA
FROM PUBLICIN.TRX_REF_&periodo.
GROUP BY
periodo,
DETALLE,
CALCULATED LUGAR,
APERTURA
;QUIT;

%put------------------------------------------------------------------------------------------;
%put VENTA RENE;
%put------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE RENE AS 
SELECT 
&PERIODO. AS PERIODO,
SUM(CAPITAL) AS VENTA,
COUNT(RUT) AS TRX,
'VENTA RENE' as DETALLE,
CASE WHEN SUCURSAL=120 THEN 'DIGITAL'
	 ELSE 'ASISTIDA' END AS LUGAR,
'VENTA' AS APERTURA
FROM PUBLICIN.TRX_RENE_&periodo.
GROUP BY
periodo,
DETALLE,
CALCULATED LUGAR,
APERTURA
;QUIT;

%put------------------------------------------------------------------------------------------;
%put VENTA TC TDA;
%put------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE TDA_TC AS 
SELECT 
PERIODO,
SUM(CAPITAL+PIE) AS VENTA,
SUM(CASE WHEN TRANSACCION='COMPRA' THEN 1 ELSE 0 END)-SUM(CASE WHEN TRANSACCION='NOTA CREDITO' THEN 1 ELSE 0 END) as TRX,
'VENTA TDA TC (CAPITAL+PIE) TOTAL' as DETALLE,
CASE WHEN SUCURSAL=39 THEN 'DIGITAL'
	 ELSE 'PRESENCIAL' END AS LUGAR,
'VENTA' AS APERTURA
FROM publicin.TDA_ITF_&periodo.
GROUP BY
periodo,
DETALLE,
CALCULATED LUGAR,
APERTURA
;QUIT;

%put------------------------------------------------------------------------------------------;
%put VENTA TC SPOS;
%put------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE SPOS_TC AS 
SELECT 
PERIODO,
SUM(VENTA_TARJETA) AS VENTA,
SUM(CASE WHEN TRANSACCION='COMPRA' THEN 1 ELSE 0 END)-SUM(CASE WHEN TRANSACCION='NOTA CREDITO' THEN 1 ELSE 0 END) as TRX,
'VENTA SPOS TC TOTAL' as DETALLE,
CASE WHEN PRESENCIAL='PRESENCIAL' THEN 'PRESENCIAL'
	 ELSE 'DIGITAL' END AS LUGAR,
'VENTA' AS APERTURA
FROM PUBLICIN.SPOS_AUT_&periodo.
GROUP BY
periodo,
DETALLE,
CALCULATED LUGAR,
APERTURA
;QUIT;

%put------------------------------------------------------------------------------------------;
%put VENTA TC SPOS NACIONAL;
%put------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE SPOS_TC_NAC AS 
SELECT 
PERIODO,
SUM(VENTA_TARJETA) AS VENTA,
SUM(CASE WHEN TRANSACCION='COMPRA' THEN 1 ELSE 0 END)-SUM(CASE WHEN TRANSACCION='NOTA CREDITO' THEN 1 ELSE 0 END) as TRX,
'VENTA SPOS TC NACIONAL' as DETALLE,
CASE WHEN PRESENCIAL='PRESENCIAL' THEN 'PRESENCIAL'
	 ELSE 'DIGITAL' END AS LUGAR,
'VENTA' AS APERTURA
FROM PUBLICIN.SPOS_AUT_&periodo.
WHERE CODPAIS=152
GROUP BY
periodo,
DETALLE,
CALCULATED LUGAR,
APERTURA
;QUIT;

%put------------------------------------------------------------------------------------------;
%put VENTA TC SPOS INTERNACIONAL;
%put------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE SPOS_TC_INT AS 
SELECT 
PERIODO,
SUM(VENTA_TARJETA) AS VENTA,
SUM(CASE WHEN TRANSACCION='COMPRA' THEN 1 ELSE 0 END)-SUM(CASE WHEN TRANSACCION='NOTA CREDITO' THEN 1 ELSE 0 END) as TRX,
'VENTA SPOS TC INTERNACIONAL' as DETALLE,
CASE WHEN PRESENCIAL='PRESENCIAL' THEN 'PRESENCIAL'
	 ELSE 'DIGITAL' END AS LUGAR,
'VENTA' AS APERTURA
FROM PUBLICIN.SPOS_AUT_&periodo.
WHERE CODPAIS<>152
GROUP BY
periodo,
DETALLE,
CALCULATED LUGAR,
APERTURA
;QUIT;

%put------------------------------------------------------------------------------------------;
%put VENTA TD TDA;
%put------------------------------------------------------------------------------------------;

%let INI_CHAR=&INI_CHAR;
%let FIN_CHAR=&FIN_CHAR;
%put &INI_CHAR;
%put &FIN_CHAR;

%let path_ora      = '(DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SID = ripleyc)))'; 
%let user_ora      = 'RIPLEYC'; 
%let pass_ora      = 'ri99pley';
%let conexion_ora  = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 


PROC SQL  ;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );

create table MOV_CUENTA_VISTA  as
select 
*,
CASE 
when tmo_tipotra='C' then 
case 
WHEN DESCRIPCION IN ('VALOR EFECTIVO','EN EFECTIVO') AND GLS_TRANSAC ='DEPOSITO' AND  SI_ABR<>1  THEN 'Depósitos en Efectivo' 
WHEN DESCRIPCION IN ('CON DOCUMENTOS') AND GLS_TRANSAC ='DEPOSITO' AND SI_ABR<>1 THEN 'Depósitos con Documento' 
WHEN DESCRIPCION IN ('TRANSFERENCIA DESDE OTROS BANCOS') AND  SI_ABR<>1 THEN 'TEF Recibidas' 
WHEN DESCRIPCION IN ('DESDE OTROS BANCOS') AND  SI_ABR<>1 THEN 'TEF Recibidas' 
WHEN DESCRIPCION IN ('DESDE OTROS BANCOS') AND  SI_ABR=1 THEN 'Abono de Remuneraciones' 
WHEN DESCRIPCION IN ('DESDE OTROS BANCOS') AND  SI_ABR<>1 and DESC_NEGOCIO CONTAINS 'Proveedores' THEN 'TEF Recibidas' 
WHEN DESCRIPCION IN ('POR REGULARIZACION') AND  SI_ABR<>1 THEN 'Otros (pago proveedores)' 
WHEN DESCRIPCION IN ('DESDE LINEA DE CREDITO') AND GLS_TRANSAC ='TRASPASO DE FONDOS' AND  SI_ABR<>1 THEN 'Traspaso desde LCA'
WHEN DESCRIPCION IN ('AVANCE DESDE TARJETA DE CREDITO BANCO RIPLEY') AND  SI_ABR<>1 THEN 'Avance desde Tarjeta Ripley' 
WHEN DESCRIPCION IN ('DEVOLUCION COMISION') AND  SI_ABR<>1 THEN 'DEVOLUCION COMISION' 
WHEN DESCRIPCION IN ('POR TRANSFERENCIA  DE LCA A CTA VISTA') AND  SI_ABR<>1 THEN 'Traspaso desde LCA' 
else 'OTROS ABONOS' 
end else ''
END AS Descripcion_Abono,

CASE 
when tmo_tipotra='D' then 
CASE
WHEN DESCRIPCION IN ('COMPRA NACIONAL') THEN 'Compras Redcompra' 
WHEN DESCRIPCION IN ('COMPRA NACIONAL MCD') THEN 'Compras Redcompra MCD' 
WHEN DESCRIPCION IN ('COMPRA INTERNACIONAL') THEN 'Compras Internacionales' 
WHEN DESCRIPCION IN ('COMPRA INTERNACIONAL MCD') THEN 'Compras Internacionales MCD' 
WHEN DESCRIPCION IN ('CARGO POR PEC') THEN 'PEC' 
WHEN DESCRIPCION IN ('GIRO CAJERO AUTOMATICO') THEN 'Giros ATM' 
when DESCRIPCION IN ('GIRO ATM INTERNACIONAL MCD') then 'Giros internacional MCD'
when DESCRIPCION IN ('GIRO ATM NACIONAL MCD') then 'Giros ATM MCD'
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
SUBSTR(c2.cli_identifica,length(c2.cli_identifica),1)  dv,

cast(TO_CHAR( c1.tmo_fechor,'YYYYMM') as INT) as PERIODO,
cast(TO_CHAR( c1.tmo_fechor,'YYYYMMDD') as INT) as CodFecha,

c1.tmo_numcue as CUENTA, 
c1.tmo_fechcon as FECHACON, 
c1.tmo_fechor as FECHA, 
c1.rub_desc as DESCRIPCION, 
c1.tmo_val as MONTO, 
c1.con_libre as Desc_negocio, 
c1.tmo_codmod, 
c1.tmo_tipotra, 
c1.tmo_rubro, 
c1.tmo_numtra, 
c1.tmo_numcue, 
c1.tmo_codusr, 
c1.tmo_codusr, 
c1.tmo_sec, 
c1.tmo_codtra, 
(
SELECT cod_destra 
FROM tgen_codtrans 
WHERE cod_tra = tmo_codtra AND cod_mod = tmo_codmod 
) as gls_transac,

case 
when c1.tmo_tipotra='D' then 'CARGO' 
when c1.tmo_tipotra='C' then 'ABONO' 
end as Tipo_Movimiento,

case 
when c1.tmo_rubro = 1 and c1.tmo_codtra = 30 and c1.con_libre like 'Depo%' then 1 
else 0 
end as Marca_DAP,

case 
when c1.tmo_tipotra='C' 
and c1.rub_desc='DESDE OTROS BANCOS' 
and ( 
c1.con_libre like '%Remuneraciones%' OR 
c1.con_libre like '%Anticipos%' OR 
c1.con_libre like '%Sueldos%')  then 1 
ELSE 0 
END as SI_ABR ,
CASE 
WHEN  c1.tmo_tipotra='C' and c1.rub_desc='DESDE OTROS BANCOS' 
and ( c1.con_libre like '%Remuneraciones%' OR c1.con_libre like '%Anticipos%' OR c1.con_libre like '%Sueldos%')
AND c1.con_libre like '%BANCO RIPLEY%' THEN 'BANCO RIPLEY' 
WHEN  c1.tmo_tipotra='C' and c1.rub_desc='DESDE OTROS BANCOS' 
and ( c1.con_libre like '%Remuneraciones%' OR c1.con_libre like '%Anticipos%' OR c1.con_libre like '%Sueldos%')
 AND c1.con_libre like '%CAR S.A.%' THEN 'CAR' 
WHEN  c1.tmo_tipotra='C' and c1.rub_desc='DESDE OTROS BANCOS' 
and ( c1.con_libre like '%Remuneraciones%' OR c1.con_libre like '%Anticipos%' OR c1.con_libre like '%Sueldos%')
 AND c1.con_libre like '%RIPLEY STORE%' THEN 'RIPLEY STORE' 
WHEN  c1.tmo_tipotra='C' and c1.rub_desc='DESDE OTROS BANCOS' 
and ( c1.con_libre like '%Remuneraciones%' OR c1.con_libre like '%Anticipos%' OR c1.con_libre like '%Sueldos%')
 AND ( 
c1.con_libre NOT like ('%RIPLEY STORE%') or 
c1.con_libre NOT like ('%CAR S.A.%') or 
c1.con_libre NOT like ('%BANCO RIPLEY%') 
) THEN 'OTROS BANCOS' else ''
END AS Descripcion_ABR,
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
)  C2 
on (c1.tmo_numcue=c2.vis_numcue) 
where c1.rub_desc in ('COMPRA NACIONAL','COMPRA NACIONAL MCD','COMPRA INTERNACIONAL','COMPRA INTERNACIONAL MCD') 
) ;
disconnect from ORACLE;
QUIT;

proc sql;
create table td_tda_1 as 
select 
*,
case when Desc_negocio like '%RIPLEY DEBITO%' then 'DIGITAL' 
	 else 'PRESENCIAL' end as LUGAR
from MOV_CUENTA_VISTA
where COMPRA_RIPLEY is not null
;quit;

PROC SQL;
   CREATE TABLE SPOS_MCD AS 
   SELECT distinct
		  t1.Fecha, 
          t1.Nombre_Comercio, 
          t1.RUT, 
          t1.VENTA_TARJETA, 
          t1.si_digital
      FROM PUBLICIN.SPOS_MCD_&periodo. t1
where tipofac in (8050,9050)
;QUIT;

proc sql;
create table td_spos as 
select *,
	   MONOTONIC() AS ID
from MOV_CUENTA_VISTA
where COMPRA_RIPLEY is null
;quit;

proc sql;
create table CRUZA_TD_SPOS AS
SELECT DISTINCT
	A.*,
	case when MAX(COALESCE(SI_DIGITAL,0))=1 then 'DIGITAL' 
	     else 'PRESENCIAL' end as LUGAR
FROM td_spos AS A
LEFT JOIN SPOS_MCD AS B ON (a.rut=b.rut) and (a.codfecha=b.fecha) and a.monto=b.VENTA_TARJETA and upcase(substr(a.DESC_NEGOCIO,1,15))=upcase(b.nombre_comercio)
GROUP BY 
	A.ID,
	a.rut,
	a.codfecha,
	a.monto,
	a.DESC_NEGOCIO
;QUIT;

/* ripley no ripley para spos o tda */

PROC SQL;
CREATE TABLE TDA_TD AS 
SELECT 
PERIODO,
SUM(MONTO) AS VENTA,
COUNT(RUT) AS TRX,
'VENTA TDA TD TOTAL' as DETALLE,
LUGAR,
'VENTA' AS APERTURA
FROM td_tda_1
GROUP BY
periodo,
DETALLE,
LUGAR,
APERTURA
;QUIT;


%put------------------------------------------------------------------------------------------;
%put VENTA TD SPOS;
%put------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE SPOS_TD AS 
SELECT 
PERIODO,
SUM(MONTO) AS VENTA,
COUNT(RUT) AS TRX,
'VENTA SPOS TD TOTAL' as DETALLE,
LUGAR,
'VENTA' AS APERTURA
FROM CRUZA_TD_SPOS
GROUP BY
periodo,
DETALLE,
LUGAR,
APERTURA
;QUIT;

%put------------------------------------------------------------------------------------------;
%put VENTA TD SPOS NACIONAL;
%put------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE SPOS_TD_NAC AS 
SELECT 
PERIODO,
SUM(MONTO) AS VENTA,
COUNT(RUT) AS TRX,
'VENTA SPOS TD NACIONAL' as DETALLE,
LUGAR,
'VENTA' AS APERTURA
FROM CRUZA_TD_SPOS
WHERE DESCRIPCION='COMPRA NACIONAL MCD'
GROUP BY
periodo,
DETALLE,
LUGAR,
APERTURA
;QUIT;

%put------------------------------------------------------------------------------------------;
%put VENTA TD SPOS INTERNACIONAL;
%put------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE SPOS_TD_INT AS 
SELECT 
PERIODO,
SUM(MONTO) AS VENTA,
COUNT(RUT) AS TRX,
'VENTA SPOS TD INTERNACIONAL' as DETALLE,
LUGAR,
'VENTA' AS APERTURA
FROM CRUZA_TD_SPOS
WHERE DESCRIPCION='COMPRA INTERNACIONAL MCD'
GROUP BY
periodo,
DETALLE,
LUGAR,
APERTURA
;QUIT;

%put------------------------------------------------------------------------------------------;
%put VENTA CCTE TDA;
%put------------------------------------------------------------------------------------------;


PROC SQL;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );
create table MOV_CUENTA_corriente  as
select 
*,
CASE 
when tmo_tipotra='C' then 
case 
WHEN DESCRIPCION IN ('VALOR EFECTIVO','EN EFECTIVO') AND GLS_TRANSAC ='DEPOSITO' AND  SI_ABR<>1  THEN 'Depósitos en Efectivo' 
WHEN DESCRIPCION IN ('CON DOCUMENTOS') AND GLS_TRANSAC ='DEPOSITO' AND SI_ABR<>1 THEN 'Depósitos con Documento' 
WHEN DESCRIPCION IN ('TRANSFERENCIA DESDE OTROS BANCOS') AND  SI_ABR<>1 THEN 'TEF Recibidas' 
WHEN DESCRIPCION IN ('DESDE OTROS BANCOS') AND  SI_ABR<>1 THEN 'TEF Recibidas' 
WHEN DESCRIPCION IN ('DESDE OTROS BANCOS') AND  SI_ABR=1 THEN 'Abono de Remuneraciones' 
WHEN DESCRIPCION IN ('DESDE OTROS BANCOS') AND  SI_ABR<>1 and DESC_NEGOCIO CONTAINS 'Proveedores' THEN 'TEF Recibidas' 
WHEN DESCRIPCION IN ('POR REGULARIZACION') AND  SI_ABR<>1 THEN 'Otros (pago proveedores)' 
WHEN DESCRIPCION IN ('DESDE LINEA DE CREDITO') AND GLS_TRANSAC ='TRASPASO DE FONDOS' AND  SI_ABR<>1 THEN 'Traspaso desde LCA'
WHEN DESCRIPCION IN ('AVANCE DESDE TARJETA DE CREDITO BANCO RIPLEY') AND  SI_ABR<>1 THEN 'Avance desde Tarjeta Ripley' 
WHEN DESCRIPCION IN ('DEVOLUCION COMISION') AND  SI_ABR<>1 THEN 'DEVOLUCION COMISION' 
/*--  WHEN DESCRIPCION IN ('POR TRANSFERENCIA  DE LCA A CTA VISTA') AND  SI_ABR<>1 THEN 'Traspaso desde LCA'
/*-- AAG */
WHEN DESCRIPCION IN ('TRANSFERENCIA DESDE CREDITO') AND  SI_ABR<>1 THEN 'Traspaso desde LCA' 
/*-- AAG*/
else 'OTROS ABONOS' 
end else ''
END AS Descripcion_Abono,
CASE 
when tmo_tipotra='D' then 
CASE
WHEN DESCRIPCION IN ('COMPRA NACIONAL CTA CTE') THEN 'Compras Redcompra' 
WHEN DESCRIPCION IN ('COMPRA INTERNACIONAL CTA CTE') THEN 'Compras Internacionales' 
WHEN DESCRIPCION IN ('CARGO POR PEC') THEN 'PEC' 
when DESCRIPCION IN ('GIRO ATM INTERNACIONAL CTA CTE') then 'Giros internacional CTA CTE'
when DESCRIPCION IN ('GIRO ATM NACIONAL CTA CTE') then 'Giros ATM CTA CTE'
WHEN DESCRIPCION IN ('GIRO POR CAJA') THEN 'Giros Caja'
WHEN DESCRIPCION IN ('TRANSFERENCIA A OTROS BANCOS') THEN 'TEF emitidas Otros Bancos'
WHEN DESCRIPCION IN ('PAGO TARJETA DE CREDITO') THEN 'Pago de Tarjeta' 
WHEN DESCRIPCION IN ('A CUENTA BANCO RIPLEY','POR TRASPASO A CUENTA')  THEN 'Pago LCA'
WHEN  DESCRIPCION IN ('COSTO DE MANTENCION MENSUAL CTA CTE') then 'Comision planes'
WHEN DESCRIPCION IN ('IVA COSTO DE MANTENCION MENSUAL CTA CTE') then 'IVA Com cta cte'
else 'OTROS CARGOS' 
end else ''
END AS Descripcion_Cargo 
from connection to ORACLE
( select 
CAST(SUBSTR(c2.cli_identifica,1,length(c2.cli_identifica)-1) AS INT)  rut,
SUBSTR(c2.cli_identifica,length(c2.cli_identifica),1)  dv,
cast(TO_CHAR( c1.tmo_fechor,'YYYYMM') as INT) as PERIODO,
cast(TO_CHAR( c1.tmo_fechor,'YYYYMMDD') as INT) as CodFecha,
c1.tmo_numcue as CUENTA, 
c1.tmo_fechcon as FECHACON, 
c1.tmo_fechor as FECHA, 
c1.rub_desc as DESCRIPCION, 
c1.tmo_val as MONTO, 
c1.con_libre as Desc_negocio, 
c1.tmo_codmod, 
c1.tmo_tipotra, 
c1.tmo_rubro, 
c1.tmo_numtra, 
c1.tmo_numcue, 
c1.tmo_codusr, 
c1.tmo_codusr, 
c1.tmo_sec, 
c1.tmo_codtra, 
(
SELECT cod_destra 
FROM tgen_codtrans 
WHERE cod_tra = tmo_codtra AND cod_mod = tmo_codmod 
) as gls_transac,
case 
when c1.tmo_tipotra='D' then 'CARGO' 
when c1.tmo_tipotra='C' then 'ABONO' 
end as Tipo_Movimiento,
case 
when c1.tmo_tipotra='C' 
and c1.rub_desc='DESDE OTROS BANCOS' 
and ( 
c1.con_libre like '%Remuneraciones%' OR 
c1.con_libre like '%Anticipos%' OR 
c1.con_libre like '%Sueldos%')  then 1 
ELSE 0 
END as SI_ABR ,
CASE 
WHEN  c1.tmo_tipotra='C' and c1.rub_desc='DESDE OTROS BANCOS' 
and ( c1.con_libre like '%Remuneraciones%' OR c1.con_libre like '%Anticipos%' OR c1.con_libre like '%Sueldos%')
AND c1.con_libre like '%BANCO RIPLEY%' THEN 'BANCO RIPLEY' 
WHEN  c1.tmo_tipotra='C' and c1.rub_desc='DESDE OTROS BANCOS' 
and ( c1.con_libre like '%Remuneraciones%' OR c1.con_libre like '%Anticipos%' OR c1.con_libre like '%Sueldos%')
 AND c1.con_libre like '%CAR S.A.%' THEN 'CAR' 
WHEN  c1.tmo_tipotra='C' and c1.rub_desc='DESDE OTROS BANCOS' 
and ( c1.con_libre like '%Remuneraciones%' OR c1.con_libre like '%Anticipos%' OR c1.con_libre like '%Sueldos%')
 AND c1.con_libre like '%RIPLEY STORE%' THEN 'RIPLEY STORE' 
WHEN  c1.tmo_tipotra='C' and c1.rub_desc='DESDE OTROS BANCOS' 
and ( c1.con_libre like '%Remuneraciones%' OR c1.con_libre like '%Anticipos%' OR c1.con_libre like '%Sueldos%')
 AND ( 
c1.con_libre NOT like ('%RIPLEY STORE%') or 
c1.con_libre NOT like ('%CAR S.A.%') or 
c1.con_libre NOT like ('%BANCO RIPLEY%') 
) THEN 'OTROS BANCOS' else ''
END AS Descripcion_ABR,
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
/*AND (vis_status='2' or vis_status='9')*/ /*solo aquellas con estado vigente o cerrado*/ 
)  C2 
on (c1.tmo_numcue=c2.vis_numcue) 
where c1.rub_desc in ('COMPRA NACIONAL CTA CTE','COMPRA INTERNACIONAL CTA CTE')
) ;
disconnect from ORACLE;
QUIT;


proc sql;
create table CCTE_tda_1 as 
select 
*,
case when Desc_negocio like '%RIPLEY DEBITO%' then 'DIGITAL' 
	 else 'PRESENCIAL' end as LUGAR
from MOV_CUENTA_corriente
where COMPRA_RIPLEY is not null
;quit;

PROC SQL;
   CREATE TABLE SPOS_CCTE AS 
   SELECT distinct
		  t1.Fecha, 
          t1.Nombre_Comercio, 
          t1.RUT, 
          t1.VENTA_TARJETA, 
          t1.si_digital
      FROM PUBLICIN.SPOS_CTACTE_&periodo. t1
where tipofac in (8050,9050)
;QUIT;

proc sql;
create table CCTE_spos as 
select *,
	   MONOTONIC() AS ID
from MOV_CUENTA_corriente
where COMPRA_RIPLEY is null
;quit;

proc sql;
create table CRUZA_CCTE_SPOS AS
SELECT DISTINCT
	A.*,
	case when MAX(COALESCE(SI_DIGITAL,0))=1 then 'DIGITAL' 
	     else 'PRESENCIAL' end as LUGAR
FROM CCTE_spos AS A
LEFT JOIN SPOS_CCTE AS B ON (a.rut=b.rut) and (a.codfecha=b.fecha) and a.monto=b.VENTA_TARJETA and upcase(substr(a.DESC_NEGOCIO,1,15))=upcase(b.nombre_comercio)
GROUP BY 
	A.ID,
	a.rut,
	a.codfecha,
	a.monto,
	a.DESC_NEGOCIO
;QUIT;

/* ripley no ripley para spos o tda */

PROC SQL;
CREATE TABLE TDA_CCTE AS 
SELECT 
PERIODO,
SUM(MONTO) AS VENTA,
COUNT(RUT) AS TRX,
'VENTA TDA CCTE TOTAL' as DETALLE,
LUGAR,
'VENTA' AS APERTURA
FROM CCTE_tda_1
GROUP BY
periodo,
DETALLE,
LUGAR,
APERTURA
;QUIT;


%put------------------------------------------------------------------------------------------;
%put VENTA CCTE SPOS;
%put------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE SPOS_CCTE AS 
SELECT 
PERIODO,
SUM(MONTO) AS VENTA,
COUNT(RUT) AS TRX,
'VENTA SPOS CCTE TOTAL' as DETALLE,
LUGAR,
'VENTA' AS APERTURA
FROM CRUZA_CCTE_SPOS
GROUP BY
periodo,
DETALLE,
LUGAR,
APERTURA
;QUIT;

%put------------------------------------------------------------------------------------------;
%put VENTA CCTE SPOS NACIONAL;
%put------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE SPOS_CCTE_NAC AS 
SELECT 
PERIODO,
SUM(MONTO) AS VENTA,
COUNT(RUT) AS TRX,
'VENTA SPOS CCTE NACIONAL' as DETALLE,
LUGAR,
'VENTA' AS APERTURA
FROM CRUZA_CCTE_SPOS
WHERE DESCRIPCION='COMPRA NACIONAL CTA CTE'
GROUP BY
periodo,
DETALLE,
LUGAR,
APERTURA
;QUIT;

%put------------------------------------------------------------------------------------------;
%put VENTA CCTE SPOS INTERNACIONAL;
%put------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE SPOS_CCTE_INT AS 
SELECT 
PERIODO,
SUM(MONTO) AS VENTA,
COUNT(RUT) AS TRX,
'VENTA SPOS CCTE INTERNACIONAL' as DETALLE,
LUGAR,
'VENTA' AS APERTURA
FROM CRUZA_CCTE_SPOS
WHERE DESCRIPCION='COMPRA INTERNACIONAL CTA CTE'
GROUP BY
periodo,
DETALLE,
LUGAR,
APERTURA
;QUIT;


%put------------------------------------------------------------------------------------------;
%put GENERACION TABLAS VACIAS;
%put------------------------------------------------------------------------------------------;

%if (%sysfunc(exist(&libreria..REPORTE_TRANSACCIONAL))) %then %do;
 
%end;
%else %do;

PROC  SQL;
CREATE TABLE &libreria..REPORTE_TRANSACCIONAL
(
periodo	 num,
VENTA num,
TRX num,
DETALLE char(99),
LUGAR char(99),
APERTURA char(99),
PRODUCTO char(99)
)
;quit;
%end;

PROC  SQL;
CREATE TABLE AGRUPADO_FINAL 
(
periodo	 num,
VENTA num,
TRX num,
DETALLE char(99),
LUGAR char(99),
APERTURA char(99),
PRODUCTO char(99)
)
;quit;


%put------------------------------------------------------------------------------------------;
%put INSERTAR BASES;
%put------------------------------------------------------------------------------------------;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'TC' as PRODUCTO
FROM captacion_TC
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'AV' as PRODUCTO
FROM av
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'SAV' as PRODUCTO
FROM sav
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'CONSUMO' as PRODUCTO
FROM consumo
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'DAP' as PRODUCTO
FROM DAP_ACUMULADO
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'DAP' as PRODUCTO
FROM DAP_STOCK
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'REF' as PRODUCTO
FROM REF
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'RENE' as PRODUCTO
FROM RENE
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'TC' as PRODUCTO
FROM TDA_TC
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'TC' as PRODUCTO
FROM SPOS_TC
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'TC' as PRODUCTO
FROM SPOS_TC_NAC
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'TC' as PRODUCTO
FROM SPOS_TC_INT
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'TD' as PRODUCTO
FROM TDA_TD
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'TD' as PRODUCTO
FROM SPOS_TD
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'TD' as PRODUCTO
FROM SPOS_TD_NAC
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'TD' as PRODUCTO
FROM SPOS_TD_INT
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'CCTE' as PRODUCTO
FROM TDA_CCTE
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'CCTE' as PRODUCTO
FROM SPOS_CCTE
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'CCTE' as PRODUCTO
FROM SPOS_CCTE_NAC
;QUIT;

PROC SQL;
INSERT INTO AGRUPADO_FINAL
SELECT *,
'CCTE' as PRODUCTO
FROM SPOS_CCTE_INT
;QUIT;


%put------------------------------------------------------------------------------------------;
%put INSERTAR AGRUPAD;
%put------------------------------------------------------------------------------------------;

PROC SQL;
DELETE *
FROM &libreria..REPORTE_TRANSACCIONAL
WHERE PERIODO=&PERIODO.
;QUIT;

PROC SQL;
INSERT INTO &libreria..REPORTE_TRANSACCIONAL
SELECT *
FROM AGRUPADO_FINAL
;QUIT;
