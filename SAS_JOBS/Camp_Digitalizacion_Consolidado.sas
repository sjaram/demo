

%let libreria=result;

DATA _null_;


n='0';
Call symput("n", n);
RUN;

%put &n;


DATA _null_;

cantidad_mov = 1;
suma_mov=0;

periodo_actual = input(put(intnx('month',today(),&n.,'begin'),yymmn6. ),$10.) ;
periodo_1 = input(put(intnx('month',today(),&n.-1,'begin'),yymmn6. ),$10.) ;
primer_dia= put(intnx('month',today(),&n.,'begin'),yymmddn8.); 
primer_dia_ma= put(intnx('month',today(),&n.-1,'begin'),yymmddn8.); 
ultimo_dia= put(intnx('month',today(),&n.,'end'),yymmddn8.);
ultimo_dia_ma= put(intnx('month',today(),&n.-1,'end'),yymmddn8.);

primer_dia_1m = put(intnx('month',today(),&n.-1,'begin'),yymmddn8.); 
per = put(intnx('month',today(),&n.,'end'), yymmn6.);
INI=put(intnx('month',today(),&n.-1,'begin'), date9.);
FIN=put(intnx('month',today(),&n.-1,'end'), date9.);
fec_proceso=put(intnx('day',today(),0,'same'), yymmddn8.);
INI_NUM=put(intnx('month',today(),&n.-1,'begin'), yymmddn8.);
FIN_NUM=put(intnx('month',today(),&n.-1,'end'), yymmddn8.);
ini_char = put(intnx('month',today(),&n.-1,'begin'),ddmmyy10.);
fin_char = put(intnx('month',today(),&n.-1,'end'),ddmmyy10. );
ini_fisa=put(intnx('month',today(),&n.-1,'begin'), DDMMYY10.);
fin_fisa=put(intnx('month',today(),&n.-1,'end'), DDMMYY10.);

Call symput("cantidad_mov", cantidad_mov);
Call symput("suma_mov", suma_mov);
Call symput("periodo_actual", periodo_actual);
Call symput("periodo_1", periodo_1);
Call symput("primer_dia",primer_dia);
Call symput("ultimo_dia",ultimo_dia);
Call symput("primer_dia_ma",primer_dia);
Call symput("ultimo_dia_ma",ultimo_dia);

Call symput("primer_dia_1m",primer_dia_1m);
call symput("periodo",per);
call symput("INI",INI);
call symput("FIN",FIN);
call symput("INI_NUM",INI_NUM);
call symput("FIN_NUM",FIN_NUM);
call symput("fec_proceso",fec_proceso);
call symput("INI_char",INI_char);
call symput("fin_char",fin_char);
call symput("ini_fisa",ini_fisa);
call symput("fin_fisa",fin_fisa);
RUN;

%put &cantidad_mov;
%put &suma_mov;
%put &periodo_actual;
%put &periodo_1;
%put &primer_dia;
%put &ultimo_dia;
%put &primer_dia_ma;
%put &ultimo_dia_ma;
%put &primer_dia_1m;
%put &periodo;
%put &INI;
%put &FIN;
%put &INI_NUM;
%put &FIN_NUM;
%put &fec_proceso;
%put &INI_char;
%put &fin_char;
%put &ini_fisa;
%put &fin_fisa;


%put ################################################################;
%put ########                  Login                     ############;
%put ################################################################;


proc sql;
create table log_2m as 
select distinct rut from publicin.logeo_int_&periodo_actual.
union all
select distinct rut from publicin.logeo_int_&periodo_1.
;quit;

proc sql;
create table log_2m_aux as 
select distinct rut
from log_2m 
where rut in (select distinct rut from publicin.logeo_int_&periodo_actual.) and
rut in (select distinct rut from publicin.logeo_int_&periodo_1.)
;quit;

proc sql;
create table log_m as 
select distinct rut
from publicin.logeo_int_&periodo_actual.
;quit;

proc sql;
create table cons_log as
select distinct rut from log_2m_aux
union all
select distinct rut from log_m
;quit;




%put ################################################################;
%put ########    Saldos y Movimientos CC/CV              ############;
%put ################################################################;


/*Saldo CC*/

%let path_ora      = '(DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SID = ripleyc)))'; 
%let user_ora      = 'RIPLEYC'; 
%let pass_ora      = 'ri99pley';
%let conexion_ora  = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 



PROC SQL ;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );
create table Saldos_Cuenta_corriente  as
select 
*
from connection to ORACLE( select 
CAST(SUBSTR(b.cli_identifica,1,length(b.cli_identifica)-1) AS INT)  rut,
cast(TO_CHAR( a.ACP_FECHA,'YYYYMMDD') as INT) as CodFecha,
a.ACP_FECHA, 
a.ACP_NUMCUE, 
sum(a.acp_salefe + a.acp_sal12h + a.acp_sal24h + a.acp_sal48h) as Saldo 
from tcap_acrpas  a
left join ( select 
distinct cli_identifica ,vis_numcue
from tcli_persona 
,tcap_vista 
where cli_codigo=vis_codcli 
and vis_mod=4
and (VIS_PRO=1) 
and vis_tip=1  
AND (vis_status='2' or vis_status='9')) b
on(a.ACP_NUMCUE=b.vis_numcue)
where a.acp_pro = 1 and a.acp_tip = 1 
and a.acp_fecha >=  to_date(%str(%')&ini_char.%str(%'),'dd/mm/yyyy')
and a.acp_fecha <= to_date(%str(%')&fin_char.%str(%'),'dd/mm/yyyy')
group by 
a.ACP_FECHA, 
a.ACP_NUMCUE,
b.cli_identifica
) ;
disconnect from ORACLE;
QUIT;


proc sql;
create table Saldos_Cuenta_corriente2 as
select 
a.*,
b.Saldo as Ultimo_Saldo 
from (
select 
ACP_NUMCUE as cuenta,
max(rut) as rut,
sum(case when Saldo>1 then 1 else 0 end) as Nro_Dias_Saldo_mayor_1,
sum(case when Saldo>1 then Saldo else 0 end) as SUM_SALDO_FECHA
from work.Saldos_Cuenta_corriente
group by 
ACP_NUMCUE 
) as a 
left join (
select distinct 
ACP_NUMCUE,
Saldo 
from Saldos_Cuenta_corriente
where CodFecha=(select max(CodFecha) from Saldos_Cuenta_corriente)
) as b 
on (a.cuenta=b.ACP_NUMCUE)

;QUIT;

proc sql;
create table saldo_cc as 
select rut,count(*) as  cant
from saldos_cuenta_corriente
where Saldo>1 and rut is not null
group by rut
;quit;

/*Movimientos cc*/




PROC SQL;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );

create table SB_MOV_CUENTA_corriente  as
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
/*--  AAG    Los Giros Nac. e InterN. esta abajo */
WHEN DESCRIPCION IN ('GIRO CAJERO AUTOMATICO') THEN 'Giros ATM'    
/*-- AAG      */
when DESCRIPCION IN ('GIRO ATM INTERNACIONAL CTA CTE') then 'Giros internacional CTA CTE'
when DESCRIPCION IN ('GIRO ATM NACIONAL CTA CTE') then 'Giros ATM CTA CTE'
WHEN DESCRIPCION IN ('GIRO POR CAJA') THEN 'Giros Caja'
/*--  AAG  el Giro Int esta arriba  */
WHEN DESCRIPCION IN ('GIRO INTERNACIONAL') THEN 'Giro Internacional'
/*-- AAG */ 
WHEN DESCRIPCION IN ('TRANSFERENCIA A OTROS BANCOS') THEN 'TEF emitidas Otros Bancos'
WHEN DESCRIPCION IN ('PAGO TARJETA DE CREDITO') THEN 'Pago de Tarjeta' 
WHEN DESCRIPCION IN ('A CUENTA BANCO RIPLEY','POR TRASPASO A CUENTA')  THEN 'Pago LCA'
WHEN DESCRIPCION IN ('COSTO DE MANTENCION MENSUAL CUENTA VISTA') then 'Comision planes'
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

/*    Esto no va 
case 
-- when c1.tmo_rubro = 1 and c1.tmo_codtra = 30 and c1.con_libre like 'Depo%' then 1
-- AAG Esto es el abono hacia CC.    transaccion 27 abono a CC desde LC
 when c1.tmo_rubro = 1 and c1.tmo_codtra = 27  then 1
then 1
-- AAG  
else 0 
end as Marca_DAP, /* no es posible identificar marca dAP*/


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

and tmo_fechcon >= to_date(%str(%')&ini_fisa.%str(%'),'dd/mm/yyyy') 
and tmo_fechcon <= to_date(%str(%')&fin_fisa.%str(%'),'dd/mm/yyyy')

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


PROC SQL;
create table movimientos_cc as 
select rut,count(*) as cant,sum(monto) as monto
from SB_MOV_CUENTA_corriente
where codfecha>=&primer_dia_1m. and rut is not null
group by rut
;quit;



/* Saldo CV*/

proc sql   noprint inobs=1;
select 
put(cat(substr(put(&INI_NUM,8.),7,2),'/',substr(put(&INI_NUM,8.),5,2),'/',substr(put(&INI_NUM,8.),1,4)),$10. ) format=$10. as INI_CHAR,
put(cat(substr(put(&FIN_NUM,8.),7,2),'/',substr(put(&FIN_NUM,8.),5,2),'/',substr(put(&FIN_NUM,8.),1,4)),$10.)  format=$10. as FIN_CHAR
into
:INI_CHAR,
:FIN_CHAR
from pmunoz.codigos_capta_cdp
;QUIT;

%let INI_CHAR=&INI_CHAR;
%let FIN_CHAR=&FIN_CHAR;
%put &INI_CHAR;
%put &FIN_CHAR;





PROC SQL ;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );
create table SB_Saldos_Cuenta_Vista  as
select 
*
from connection to ORACLE( select 
CAST(SUBSTR(b.cli_identifica,1,length(b.cli_identifica)-1) AS INT)  rut,
cast(TO_CHAR( a.ACP_FECHA,'YYYYMMDD') as INT) as CodFecha,
a.ACP_FECHA, 
a.ACP_NUMCUE, 
sum(a.acp_salefe + a.acp_sal12h + a.acp_sal24h + a.acp_sal48h) as Saldo 
from tcap_acrpas  a
left join ( select 
distinct cli_identifica ,vis_numcue
from tcli_persona 
,tcap_vista 
where cli_codigo=vis_codcli 
and vis_mod=4
and (VIS_PRO=4 or VIS_PRO=40) 
and vis_tip=1  
AND (vis_status='2' or vis_status='9')) b
on(a.ACP_NUMCUE=b.vis_numcue)
where a.acp_pro = 4 and a.acp_tip = 1 
and a.acp_fecha >=  to_date(%str(%')&ini_char.%str(%'),'dd/mm/yyyy')
and a.acp_fecha <= to_date(%str(%')&fin_char.%str(%'),'dd/mm/yyyy')
group by 
a.ACP_FECHA, 
a.ACP_NUMCUE,
b.cli_identifica
) ;
disconnect from ORACLE;
QUIT;

proc sql;
create table work.SB_Saldos_Cuenta_Vista2 as
select 
a.*,
b.Saldo as Ultimo_Saldo 
from (
select 
ACP_NUMCUE as cuenta,
max(rut) as rut,
sum(case when Saldo>1 then 1 else 0 end) as Nro_Dias_Saldo_mayor_1,
sum(case when Saldo>1 then Saldo else 0 end) as SUM_SALDO_FECHA
from work.SB_Saldos_Cuenta_Vista 
group by 
ACP_NUMCUE 
) as a 
left join (
select distinct 
ACP_NUMCUE,
Saldo 
from work.SB_Saldos_Cuenta_Vista 
where CodFecha=(select max(CodFecha) from work.SB_Saldos_Cuenta_Vista)
) as b 
on (a.cuenta=b.ACP_NUMCUE)
;QUIT;

proc sql;
create table saldo_cv as 
select rut,count(*) as cant
from SB_Saldos_Cuenta_Vista
where Saldo>1 and rut is not null
group by rut
;quit;



/* Movimientos CV */



proc sql   noprint inobs=1;
select 
put(cat(substr(put(&INI_NUM,8.),7,2),'/',substr(put(&INI_NUM,8.),5,2),'/',substr(put(&INI_NUM,8.),1,4)),$10. ) format=$10. as INI_CHAR,
put(cat(substr(put(&FIN_NUM,8.),7,2),'/',substr(put(&FIN_NUM,8.),5,2),'/',substr(put(&FIN_NUM,8.),1,4)),$10.)  format=$10. as FIN_CHAR
into
:INI_CHAR,
:FIN_CHAR
from pmunoz.codigos_capta_cdp
;QUIT;

%let INI_CHAR=&INI_CHAR;
%let FIN_CHAR=&FIN_CHAR;
%put &INI_CHAR;
%put &FIN_CHAR;




PROC SQL  ;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );

create table SB_MOV_CUENTA_VISTA2  as
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

and tmo_fechcon >= to_date(%str(%')&ini_char.%str(%'),'dd/mm/yyyy')
and tmo_fechcon <= to_date(%str(%')&fin_char.%str(%'),'dd/mm/yyyy')

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

) ;
disconnect from ORACLE;
QUIT;





PROC SQL;
create table movimientos_cv as 
select rut,count(*) as cant,sum(monto) as monto
from SB_MOV_CUENTA_VISTA2
where codfecha>=&primer_dia_1m. and rut is not null
group by rut
;quit;


proc sql;
create table cons_td as 
select distinct rut from movimientos_cc where cant>= &cantidad_mov. and monto >= &suma_mov.
union
select distinct rut from movimientos_cv where cant>= &cantidad_mov. and monto >= &suma_mov.
union
select distinct rut from saldo_cv 
union
select distinct rut from saldo_cc
;quit;

proc sql;
create table cons_tc as 
select distinct rut from  publicin.act_tr_&periodo_1. where  saldo_contable>0 and VU_IC=1
;quit;

proc sql;
create table cons_td_tc as 
select distinct rut from cons_td
union 
select distinct rut from cons_tc
;quit;



%put ################################################################;
%put ########               Oferta PPFF                  ############;
%put ################################################################;


proc sql;
create table oferta_sav as 
select 
rut_real as rut,
monto_para_canon,
RANGO_PROB,
SAV_APROBADO_FINAL
from jaburtom.sav_fin_&periodo_actual.
;QUIT;



proc sql;
create table oferta_av as 
select 
rut_registro_civil,
AVANCE_FINAL,
RANGO_PROB
from kmartine.avance_&periodo_actual.
;QUIT;



proc sql;
create table oferta_consumo as 
SELECT RUT,MAX(MONTO_OFERTA) AS MONTO_OFERTA 
FROM JABURTOM.OFERTA_CONS_ONLINE_&periodo_actual.
GROUP BY RUT
;QUIT;

proc sql;
create table cons_oferta as 
select distinct a.rut from oferta_sav as a where a.SAV_APROBADO_FINAL=1
union
select distinct b.rut_registro_civil as rut from oferta_av as b where b.AVANCE_FINAL >0
union
select distinct c.rut from oferta_consumo as c where c.MONTO_OFERTA>0
;quit;


%put ################################################################;
%put ########             Salida Oferta PPFF             ############;
%put ################################################################;


options cmplib=sbarrera.funcs;

proc sql;
create table salida_oferta_ppff as
select rut,CATS(put(RUT,commax10.),'-',SB_DV(RUT)) as rut_dv
from cons_td_tc
where rut not in (select rut from cons_log)
and rut in (select rut from cons_oferta)
;quit;


proc sql;
create table &libreria..campanha_digitali_oferta_ppff as 
select a.rut,a.rut_dv,
case when b.rut_registro_civil is not null then 1 else 0 end as oferta_av,
case when b.rut_registro_civil is not null then b.AVANCE_FINAL else 0 end as monto_oferta_av,
case when c.rut is not null then 1 else 0 end as oferta_sav,
case when c.rut is not null then c.monto_para_canon else 0 end as monto_oferta_sav,
case when d.rut is not null then 1 else 0 end as oferta_cons,
case when d.rut is not null then d.MONTO_OFERTA else 0 end as monto_oferta_cons,
case when e.rut is not null then e.edad else 0 end as edad
from salida_oferta_ppff as a
left join oferta_av as b
on a.rut=b.rut_registro_civil
left join oferta_sav as c
on a.rut=c.rut
left join oferta_consumo as d
on a.rut=d.rut
left join publicin.demo_basket_&periodo_1. as e
on a.rut=e.rut
;quit;



%put ################################################################;
%put ########             Salida Crédito                 ############;
%put ################################################################;


proc sql;
create table salida_credito as 
select distinct rut,CATS(put(RUT,commax10.),'-',SB_DV(RUT)) as rut_dv
from  publicin.act_tr_&periodo_1.
where  saldo_contable>0 and VU_IC=1
and rut not in (select distinct rut from cons_log)
;quit;

proc sql;
create table &libreria..campanha_digitali_credito as 
select a.rut,a.rut_dv,
b.saldo_contable,
b.vu_ic,
b.VU_RIESGO,
b.VU_C_PRIMA,
case when e.rut is not null then e.edad else 0 end as edad
from salida_credito as a
left join publicin.act_tr_&periodo_1. as b
on a.rut=b.rut
left join publicin.demo_basket_&periodo_1. as e
on a.rut=e.rut
;quit;


%put ################################################################;
%put ########               Salida Débito                ############;
%put ################################################################;

proc sql;
create table salida_debito as
select 
distinct rut,CATS(put(RUT,commax10.),'-',SB_DV(RUT)) as rut_dv
from cons_td
where  rut not in (select rut from cons_log)
;quit;

proc sql;
create table &libreria..campanha_digitali_debito as 
select a.rut,a.rut_dv,
case when b.rut is not null then b.cant else 0 end as cantidad_mov_cv,
case when b.rut is not null then b.monto else 0 end as sum_movimiento_cv,
case when d.rut is not null then d.cant else 0 end as cantidad_mov_cc,
case when d.rut is not null then d.monto else 0 end as sum_movimiento_cc,
case when f.rut is not null then f.edad else 0 end as edad
from salida_debito as a
left join movimientos_cv as b
on a.rut=b.rut 
left join movimientos_cc as d
on a.rut=d.rut 
left join publicin.demo_basket_&periodo_1. as f
on a.rut=f.rut
;quit;


%put ################################################################;
%put ########        Salida Ripley Puntos GO             ############;
%put ################################################################;


proc sql;
create table salida_rpgo as
select 
distinct rut,CATS(put(RUT,commax10.),'-',SB_DV(RUT)) as rut_dv
from NLAGOSG.SEGMENTO_COMERCIAL_&periodo_1.
where  periodo = &periodo_1. and ptos_nvos>= 5000
and  rut not in (select rut from cons_log)
;quit;


proc sql;
create table &libreria..campanha_digitali_rpgo as 
select a.rut,a.rut_dv,
b.ptos_nvos,
b.SEGMENTO_FINAL as segmento,
case when c.rut is not null then c.edad else 0 end as edad
from salida_rpgo as a
left join NLAGOSG.SEGMENTO_COMERCIAL_&periodo_1. as b
on a.rut =b.rut
left join publicin.demo_basket_&periodo_1. as c
on a.rut=c.rut
where b.periodo = &periodo_1.
;quit;


%put ################################################################;
%put ########                 Salida Compras             ############;
%put ################################################################;


proc sql;
create table cons_compra as 
select distinct RUT from PUBLICIN.SPOS_AUT_&periodo_1.
union 
select distinct rut from publicin.TDA_ITF_&periodo_1.
union 
select distinct rut from publicin.TDA_ITF_&periodo_actual.
union
select distinct RUT from PUBLICIN.SPOS_AUT_&periodo_actual.
;quit;

proc sql;
create table salida_compras as
select rut,CATS(put(RUT,commax10.),'-',SB_DV(RUT)) as rut_dv
from cons_td_tc
where rut not in (select distinct rut from cons_log)
and rut in (select distinct rut from cons_compra)
;quit;


proc sql;
create table &libreria..campanha_digitali_compras as 
select a.rut,a.rut_dv,
case when b.rut is not null then b.edad else 0 end as edad
from salida_compras as a
left join publicin.demo_basket_&periodo_1. as b
on a.rut=b.rut
;quit;



%put ################################################################;
%put ########                Grupos facturación          ############;
%put ################################################################;

LIBNAME SFA  	ORACLE PATH='REPORITF.WORLD' SCHEMA='SFADMI_ADM' USER='JABURTOM'  PASSWORD='JABU#_1107' /*dbmax_text=7025*/;
LIBNAME R_bopers ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='JABURTOM' PASSWORD='JABU#_1107';
LIBNAME R_botgen ORACLE PATH='REPORITF.WORLD' SCHEMA='BOTGEN_ADM' USER='JABURTOM' PASSWORD='JABU#_1107';
LIBNAME MPDT  	ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='JABURTOM'  PASSWORD='JABU#_1107';




proc sql;
create table grupos_fact as
select b.pemid_gls_nro_dct_ide_k as rut,
a.GRUPOLIQ as grupo_facturacion,
case when a.GRUPOLIQ=4 then 5
when a.GRUPOLIQ=5 then 10
when a.GRUPOLIQ=6 then 15
when a.GRUPOLIQ=1 then 20
when a.GRUPOLIQ=2 then 25
when a.GRUPOLIQ=3 then 30
when a.GRUPOLIQ=7 then 5
else 0 end as vencimiento_pago,
case when a.GRUPOLIQ=4 then '18/20-5'
when a.GRUPOLIQ=5 then '25-10'
when a.GRUPOLIQ=6 then '30-15'
when a.GRUPOLIQ=1 then '5-20'
when a.GRUPOLIQ=2 then '10-25'
when a.GRUPOLIQ=3 then '15-30'
when a.GRUPOLIQ=7 then '18/20-5'
else '0-0' end as periodo_facturacion
from MPDT.MPDT007 as a
inner join  R_bopers.BOPERS_MAE_IDE as b
on input(trim(a.identcli),best.) = b.pemid_nro_inn_ide
where fecbaja = '0001-01-01' and producto not in ('8','12','13' )
and a.GRUPOLIQ not in (0) 
;quit;

%put ################################################################;
%put ########                      Login                 ############;
%put ################################################################;


proc sql;
create table log_m as 
select distinct rut
from publicin.logeo_int_&periodo_actual.
;quit;

%put ################################################################;
%put ########       Consolidado Pagos MA Y MES ACTUAL    ############;
%put ################################################################;


proc sql;
create table pagos as 
select 
distinct rut 
from RESULT.PAGOS_DIGITALES_&periodo_1. 
where monto>0
union 
select 
distinct rut 
from RESULT.PAGOS_DIGITALES_&periodo_actual. 
where monto>0
;quit;



proc sql;
create table pago_epu as 
select 
a.*
from grupos_fact as a
where input(trim(a.rut),best.) not in (select distinct rut from log_m)
and input(trim(a.rut),best.) not in (select distinct rut from pagos)
and input(trim(a.rut),best.) in (select distinct rut from  cons_tc)
;quit;

%put ################################################################;
%put ########                  Salida Pago EPU           ############;
%put ################################################################;


options cmplib=sbarrera.funcs;

proc sql;
create table salida_pago_epu as
select DISTINCT input(trim(rut),best.) as rut,CATS(put(input(trim(rut),best.),commax10.),'-',SB_DV(input(trim(rut),best.))) as rut_dv
from pago_epu
;quit;


proc sql;
create table &libreria..campanha_digitali_pago_epu as 
select a.rut,a.rut_dv,
c.vencimiento_pago,
d.saldo_contable,
case when b.rut is not null then b.edad else 0 end as edad
from salida_compras as a
left join publicin.demo_basket_&periodo_1. as b
on a.rut=b.rut
left join grupos_fact as c
on a.rut=input(trim(c.rut),best.)
left join publicin.act_tr_&periodo_1. as d
on a.rut=d.rut
;quit;




%put ################################################################;
%put ########               Consolidado Campañas         ############;
%put ################################################################;


proc sql;
create table work.consolidado_rut as 
select distinct rut from &libreria..campanha_digitali_oferta_ppff
union 
select distinct rut from &libreria..campanha_digitali_credito
union 
select distinct rut from &libreria..campanha_digitali_debito
union 
select distinct rut from &libreria..campanha_digitali_rpgo
union 
select distinct rut from &libreria..campanha_digitali_compras
union 
select distinct rut from &libreria..campanha_digitali_pago_epu
;quit;

options cmplib=sbarrera.funcs;


proc sql;
create table &libreria..cons_campanha_digitali_&periodo_actual. as 
select
a.rut,
CATS(put(a.RUT,commax10.),'-',SB_DV(a.RUT)) as rut_dv,
b.oferta_av,
b.monto_oferta_av,
b.oferta_sav,
b.monto_oferta_sav,
b.oferta_cons,
b.monto_oferta_cons,
c.saldo_contable,
c.vu_ic,
c.VU_RIESGO,
c.VU_C_PRIMA,
d.cantidad_mov_cv,
d.sum_movimiento_cv,
d.cantidad_mov_cc,
d.sum_movimiento_cc,
e.ptos_nvos,
e.segmento,
case when f.rut is not null then 1 else 0 end as compras,
g.vencimiento_pago,
case when h.rut is not null then h.edad else 0 end as edad,
case when b.rut is not null then 1 else 0 end as campanha_ppff,
case when c.rut is not null then 1 else 0 end as campanha_credito,
case when d.rut is not null then 1 else 0 end as campanha_debito,
case when e.rut is not null then 1 else 0 end as campanha_rpgo,
case when f.rut is not null then 1 else 0 end as campanha_compras,
case when g.rut is not null then 1 else 0 end as campanha_pago_epu
from work.consolidado_rut as a
left join &libreria..campanha_digitali_oferta_ppff as b
on a.rut=b.rut
left join &libreria..campanha_digitali_credito as c
on a.rut=c.rut
left join &libreria..campanha_digitali_debito as d
on a.rut=d.rut
left join &libreria..campanha_digitali_rpgo as e
on a.rut=e.rut
left join &libreria..campanha_digitali_compras as f
on a.rut=f.rut
left join &libreria..campanha_digitali_pago_epu as g
on a.rut=g.rut
left join publicin.demo_basket_&periodo_1. as h
on a.rut=h.rut
;quit;
