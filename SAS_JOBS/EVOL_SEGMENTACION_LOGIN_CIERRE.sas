/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	EVOL_SEGMENTACION_LOGIN			 ===============================*/

/* CONTROL DE VERSIONES
/* 2023-08-25 -- v10 -- Nicolás V.	-- Se actualiza proceso eliminando tabla bsoto.ENROLADOS_RPASS
/* 2023-04-26 -- v09 -- Esteban P.  -- Nicolás V. actualiza el proceso por defecto en cambio anterior.
/* 2023-04-25 -- v08 -- Esteban P.  -- Nicolás V. actualiza el proceso por cambio en fuentes.
/* 2023-03-23 -- v07 -- Nicolás V.	-- Modificación de clasificación de clientes en base al login
/* 2023-02-23 -- v06 -- Nicolás V.	-- Se corrije "lo extenso del nombre del campo tipo, cerca de la línea 2871"
/* 2023-02-22 -- v05 -- David V.	-- Se reincorpora export to aws perdido en versiones antriores
/* 2023-02-21 -- v04 -- David V.	-- Comentarios y Versionamiento
/* 2023-02-21 -- v03 -- Nicolás V.	-- Actualización
/* 2023-02-01 -- v02 -- Nicolás V.	-- Versión renovada
/*

/* VARIABLE TIEMPO - INICIO */
%let tiempo_inicio= %sysfunc(datetime());
options validvarname=any;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
%let libreria=RESULT;

DATA _null_;


n='-1';
Call symput("n", n);
RUN;

%put &n;


DATA _null_;
periodo_actual = input(put(intnx('month',today(),&n.,'begin'),yymmn6. ),$10.) ;
periodo_12 = input(put(intnx('month',today(),&n.-12,'begin'),yymmn6. ),$10.) ;
periodo_2 = input(put(intnx('month',today(),&n.-2,'begin'),yymmn6. ),$10.) ;
periodo_1 = input(put(intnx('month',today(),&n.-1,'begin'),yymmn6. ),$10.) ;
periodo_3 = input(put(intnx('month',today(),&n.-3,'begin'),yymmn6. ),$10.) ;
periodo_4 = input(put(intnx('month',today(),&n.-4,'begin'),yymmn6. ),$10.) ;
periodo_5 = input(put(intnx('month',today(),&n.-5,'begin'),yymmn6. ),$10.) ;
periodo_6 = input(put(intnx('month',today(),&n.-6,'begin'),yymmn6. ),$10.) ;
periodo_7 = input(put(intnx('month',today(),&n.-7,'begin'),yymmn6. ),$10.) ;
periodo_8 = input(put(intnx('month',today(),&n.-8,'begin'),yymmn6. ),$10.) ;
periodo_9 = input(put(intnx('month',today(),&n.-9,'begin'),yymmn6. ),$10.) ;
periodo_10 = input(put(intnx('month',today(),&n.-10,'begin'),yymmn6. ),$10.) ;
periodo_11 = input(put(intnx('month',today(),&n.-11,'begin'),yymmn6. ),$10.) ;
periodo_siguiente = input(put(intnx('month',today(),1,'end'),yymmn6.),$10.);
primer_dia= put(intnx('month',today(),&n.,'begin'),yymmddn8.); 
ultimo_dia= put(intnx('month',today(),&n.,'end'),yymmddn8.);
primer_dia_1m = put(intnx('month',today(),&n.-1,'begin'),yymmddn8.); 
new_actual=cats(input(put(intnx('month',today(),&n.,'begin'),yymmn6. ),$10.),'_NEW');
new_1=cats(input(put(intnx('month',today(),&n.-1,'begin'),yymmn6. ),$10.),'_NEW');
dia= put(intnx('month',today(),0,'same'),day.)-1;

per = put(intnx('month',today(),&n.,'end'), yymmn6.);
INI=put(intnx('month',today(),&n.,'begin'), date9.);
FIN=put(intnx('month',today(),&n.,'end'), date9.);
fec_proceso=put(intnx('day',today(),0,'same'), yymmddn8.);
INI_NUM=put(intnx('month',today(),&n.,'begin'), yymmddn8.);
FIN_NUM=put(intnx('month',today(),&n.,'end'), yymmddn8.);
ini_char = put(intnx('month',today(),&n.,'begin'),ddmmyy10.);
fin_char = put(intnx('month',today(),&n.,'end'),ddmmyy10. );
ini_fisa=put(intnx('month',today(),&n.,'begin'), DDMMYY10.);
fin_fisa=put(intnx('month',today(),&n.,'end'), DDMMYY10.);
dia_actual=put(intnx('month',today(),&n.,'same'), date9.)-1;

 
Call symput("periodo_actual", periodo_actual);
Call symput("periodo_12", periodo_12);
Call symput("periodo_2", periodo_2);
Call symput("periodo_1", periodo_1);
Call symput("periodo_3", periodo_3);
Call symput("periodo_4", periodo_4);
Call symput("periodo_5", periodo_5);
Call symput("periodo_6", periodo_6);
Call symput("periodo_7", periodo_7);
Call symput("periodo_8", periodo_8);
Call symput("periodo_9", periodo_9);
Call symput("periodo_10", periodo_10);
Call symput("periodo_11", periodo_11);
Call symput("periodo_siguiente", periodo_siguiente);
Call symput("primer_dia",primer_dia);
Call symput("ultimo_dia",ultimo_dia);
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
call symput("new_actual",new_actual);
call symput("new_1",new_1);
call symput("dia",dia);
call symput("dia_actual",dia_actual);
RUN;


%put &periodo_actual;
%put &periodo_12;
%put &periodo_3;
%put &periodo_2;
%put &periodo_1;
%put &periodo_4;
%put &periodo_5;
%put &periodo_6;
%put &periodo_7;
%put &periodo_8;
%put &periodo_9;
%put &periodo_10;
%put &periodo_11;
%put &periodo_siguiente;
%put &primer_dia;
%put &ultimo_dia;
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
%put &new_actual;
%put &new_1;
%put &dia;
%put &dia_actual;


%put ###########################################################################;
%put ######## Generar Conjunto de clientes saldo TR, saldo o mov TD ############;
%put ###########################################################################;





%put ################################################################;
%put ########    Clientes con saldo y VU                 ############;
%put ################################################################;
    
/* Composición login */

PROC SQL noprint; 
select max(anomes) as Max_anomes_SucPref 
into :Max_anomes_SucPref 
from ( 
select *, 
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes 
from ( 
select *, 
cat(trim(libname),.,trim(memname)) as Nombre_Tabla 
from sashelp.vmember ) as a 
where upper(Nombre_Tabla) like 'PUBLICIN.TABLON_PRODUCTOS_%' and length(Nombre_Tabla)=length('PUBLICIN.TABLON_PRODUCTOS_AAAAMM') ) as x 
;QUIT; 


DATA _NULL_;
Call execute( cat(' proc sql; 
create table work.tablon_productos_completo as 
select *
from publicin.tablon_productos_',&Max_anomes_SucPref,' 
;quit; ') )
;run;


proc sql;
create table tablon_productos as
select a.rut,
case when tc_tipo ='TR'  then 1 else 0 end as tr_tenencia,
case when  tc_tipo ='TAM'  then 1 else 0 end as tam_tenencia
from work.tablon_productos_completo as a
where  tc_tipo in ('TR','TAM') and tc_saldo>0
;QUIT;


/* Agregar otra tablas de tarjetas act_tr y stro_cc ctav_ta1_stock*/


%if (%sysfunc(exist(publicin.act_tr_&periodo_actual.))) %then %do;
proc sql;
create table act_tr as
select a.rut
from  publicin.act_tr_&periodo_1. as a
where  a.saldo_contable>0
;QUIT;
 %end;

%else %do;


proc sql;
create table act_tr as
select rut
from  publicin.act_tr_&periodo_2.
where saldo_contable>0
;QUIT;
%end;

proc sql;
create table tablon_productos_aux as 
select rut from tablon_productos
union 
select rut from act_tr
;quit;

proc sql;
create table cons_tr_tam as 
select a.rut,
case when b.rut is not null and (e.tr_tenencia+e.tam_tenencia=0) then 1 else e.tam_tenencia end as tam_tenencia,
e.tr_tenencia
from tablon_productos_aux as a
left join tablon_productos as e on a.rut=e.rut
left join act_tr  as b on a.rut=b.rut
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
select rut,count(*) as cant
from SB_MOV_CUENTA_corriente
where codfecha>=&primer_dia. and rut is not null
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
select rut,count(*) as cant
from SB_MOV_CUENTA_VISTA2
where codfecha>=&primer_dia. and rut is not null
group by rut
;quit;

proc sql;
create table cons_td as 
select distinct rut from saldo_cc
union
select distinct rut from movimientos_cc
union
select distinct rut from saldo_cv
union
select distinct rut from movimientos_cv
;quit;


proc sql;
create table dist_saldo_mov_td2 as 
select a.rut,
case when b.rut is not null then 1 else 0 end as saldo_cc,
case when c.rut is not null then 1 else 0 end as movimiento_cc,
case when d.rut is not null then 1 else 0 end as saldo_cv,
case when e.rut is not null then 1 else 0 end as movimiento_cv
from  cons_td as a
left join saldo_cc as b on a.rut=b.rut
left join movimientos_cc as c on a.rut=c.rut
left join saldo_cv as d on a.rut=d.rut
left join movimientos_cv as e on a.rut=e.rut
;quit;

proc sql;
create table base_clientes_cons as 
select distinct rut from cons_tr_tam
union
select distinct rut from dist_saldo_mov_td2
;Quit;




%put ################################################################;
%put ########    Segmentación de Clientes por Login      ############;
%put ################################################################;
    

 proc sql;
create table log_mes_actual as
select distinct rut
from publicin.logeo_int_&periodo_actual.
;quit;


proc sql;
create table log_6meses as 
select  rut, count(*) as cantidad_log,&periodo_6.  as periodo from publicin.logeo_int_&periodo_6. group by rut
union
select rut, count(*) as cantidad_log,&periodo_5.  as periodo  from publicin.logeo_int_&periodo_5. group by rut
union 
select rut, count(*) as cantidad_log,&periodo_4.  as periodo from publicin.logeo_int_&periodo_4. group by rut
union 
select rut, count(*) as cantidad_log,&periodo_3.  as periodo  from publicin.logeo_int_&periodo_3. group by rut
union 
select rut, count(*) as cantidad_log,&periodo_2.  as periodo  from publicin.logeo_int_&periodo_2. group by rut
union 
select rut, count(*) as cantidad_log,&periodo_1.  as periodo  from publicin.logeo_int_&periodo_1. group by rut
;quit;

proc sql;
create table clientes_nuevos as 
select 
rut,
'Nuevo' as clasificacion_cliente
from log_mes_actual
where rut not in (select distinct rut from log_6meses)
;quit;


proc sql;
create table log_total as 
select a.rut,count(*) as login_dist_meses,
count( case when b.rut is not null and b.periodo=&periodo_1. then a.rut end) as periodo_1,
count( case when b.rut is not null and b.periodo=&periodo_2. then a.rut end) as periodo_2,
count( case when b.rut is not null and b.periodo=&periodo_3. then a.rut end) as periodo_3,
count( case when b.rut is not null and b.periodo=&periodo_4. then a.rut end) as periodo_4,
count( case when b.rut is not null and b.periodo=&periodo_5. then a.rut end) as periodo_5,
count( case when b.rut is not null and b.periodo=&periodo_6. then a.rut end) as periodo_6
from log_mes_actual as a
left join log_6meses as b
on a.rut=b.rut
where a.rut not in (select distinct rut from clientes_nuevos)
group by a.rut
;quit;

proc sql;
create table ponderador as 
select rut,
case when periodo_1>0 then 0.3 else 0 end as pond_1,
case when periodo_2>0 then 0.25 else 0 end as pond_2,
case when periodo_3>0 then 0.2 else 0 end as pond_3,
case when periodo_4>0 then 0.1 else 0 end as pond_4,
case when periodo_5>0 then 0.1 else 0 end as pond_5,
case when periodo_6>0 then 0.05 else 0 end as pond_6
from log_total
;quit;

proc sql;
create table salida_ponderador as 
select rut,sum(pond_1+pond_2+pond_3+pond_4+pond_5+pond_6) as suma_pond
from ponderador
group by rut
;quit;

proc sql;
create table salida_login as 
select rut,
case when suma_pond>=0.75 then 'Recurrente'
when suma_pond>= 0.45 and suma_pond<=0.75 then 'Otros'
when suma_pond>= 0.05 and suma_pond<=0.45 then 'Esporádico'
else 'Inactivo' end as clasificacion_cliente
from salida_ponderador 
union all
select rut,clasificacion_cliente from clientes_nuevos
;quit;




/* Variables mes actual*/

proc sql;
create table log_mes_actual2 as
select rut,min(fecha_logueo)format=date9.  as ultimo_login,count(rut) as cantidad_log
from publicin.logeo_int_&periodo_actual.
group by rut
;quit;

proc sql;
create table log_mes_actual_diario as
select min(fecha_logueo)format=date9.  as fecha_logueo,rut,count(rut) as cantidad_log
from publicin.logeo_int_&periodo_actual.
group by fecha_logueo,rut
;quit;


proc sql;
create table log_mes_actual_cantidad as
select rut,count(distinct fecha_logueo) as cantidad_log_dist_dia
from publicin.logeo_int_&periodo_actual.
where rut 
group by rut
;quit;

proc sql;
create table log_mes_actual_tipo_log as
select rut,count(distinct tipo_logueo) as tipo_log_dist, case when count(distinct tipo_logueo)>1 then 'Ambos Canales' else tipo_logueo end as tipo_log
from publicin.logeo_int_&periodo_actual.
where rut 
group by rut
;quit;

proc sql;
create table log_mes_actual_tipo_log2 as
select rut,max(tipo_log_dist) as tipo_log_dist, max(tipo_log) as tipo_log
from log_mes_actual_tipo_log
group by rut
;quit;



proc sql;
create table log_mes_actual_final1 as 
select a.rut,
a.cantidad_log as cantidad_log,
case when b.cantidad_log_dist_dia is null then 1 else b.cantidad_log_dist_dia end as cantidad_log_dist_dia,
c.tipo_log,
a.ultimo_login,
'mensual' as clasi

from log_mes_actual2 as a
left join log_mes_actual_cantidad as b on a.rut=b.rut
left join log_mes_actual_tipo_log2 as c on a.rut=c.rut
group by a.rut
;quit;

proc sql;
create table log_mes_actual_final2 as 
select rut,
cantidad_log,
0 as cantidad_log_dist_dia,
'' as tipo_log,
fecha_logueo as ultimo_login,
'diario' as clasi
from log_mes_actual_diario

;quit;

proc sql;
create table log_mes_actual_final as 
select * from log_mes_actual_final1
union
select * from log_mes_actual_final2
;quit;


proc sql;
create table WORK.segmentacion_login_&periodo_actual. as 
select 
a.clasi,
a.rut,
a.cantidad_log,
a.cantidad_log_dist_dia,
a.tipo_log,
a.ultimo_login as ultimo_log,
case when b.rut is not null then b.clasificacion_cliente
else 'Otros' end as clasificacion_cliente
from log_mes_actual_final as a
left join salida_login as b on a.rut=b.rut

;quit;





%put ################################################################;
%put ########     Clientes con saldo c/s login           ############;
%put ################################################################;
 
/*segmentacion_con_saldo*/

proc sql;
create table segmentacion_con_saldo_mensual as 
select 
b.rut,
'Login mensual' as tipo,
b.cantidad_log,
b.cantidad_log_dist_dia,
b.tipo_log,
b.ultimo_log,
b.clasificacion_cliente
from  WORK.segmentacion_login_&periodo_actual. as b
where b.clasi='mensual'
;quit;

proc sql;
create table segmentacion_con_saldo_diario as 
select 
b.rut,
'Login diario' as tipo,
b.cantidad_log,
b.cantidad_log_dist_dia,
b.tipo_log,
b.ultimo_log,
b.clasificacion_cliente
from  WORK.segmentacion_login_&periodo_actual. as b
where b.clasi='diario'
;quit;


proc sql;
create table segmentacion_con_saldo_con_login as 
select 
b.rut,
'Saldo con login' as tipo,
b.cantidad_log,
cantidad_log_dist_dia,
b.tipo_log,
b.ultimo_log,
b.clasificacion_cliente
from base_clientes_cons as a
inner join WORK.segmentacion_login_&periodo_actual. as b
on a.rut=b.rut
where b.clasi='mensual'
;quit;

proc sql;
create table segmentacion_con_saldo_sin_login as 
select 
a.rut,
'Saldo sin login' as tipo,
0 as cantidad_log,
0 as cantidad_log_dist_dia,
'Sin login' as tipo_log,
put(intnx('month',today(),&n.,'end'), date9.) as ultimo_log,
'Sin login' as clasificacion_cliente
from base_clientes_cons as a
left join WORK.segmentacion_login_&periodo_actual. as b
on a.rut=b.rut
where b.rut is null
;quit;

PROC SQL;
create table segmentacion_con_saldo_aux as 
select * from segmentacion_con_saldo_con_login
union
select rut,tipo,cantidad_log,cantidad_log_dist_dia,tipo_log,INPUT(ultimo_log, DATE9.) as ultimo_log,clasificacion_cliente from segmentacion_con_saldo_sin_login
union
select  * from segmentacion_con_saldo_mensual
union
select  * from segmentacion_con_saldo_diario
;quit;


proc sql;
create table WORK.segmentacion_con_saldo as 
select
a.rut,
tipo,
cantidad_log,
cantidad_log_dist_dia,
tipo_log,
ultimo_log,
clasificacion_cliente,
case when b.rut is not null then 1 else 0 end as saldo_credito,
case when c.rut is not null then 1 else 0 end as saldo_o_mov_debito
from segmentacion_con_saldo_aux as a
left join cons_tr_tam as b
on a.rut=b.rut
left join dist_saldo_mov_td2 as c
on a.rut=c.rut
;quit;
	

%put ################################################################;
%put ########    Composición Login por Tarjetas          ############;
%put ################################################################;
    
/* Composición login */

proc sql;
create table tablon_productos as
select a.rut,
case when tc_tipo ='TR' then 1 else 0 end as tr_tenencia,
case when  tc_tipo ='TAM' then 1 else 0 end as tam_tenencia,
case when td_tipo in('MCD','Maestro') then 1 else 0 end as vista_tenencia,
case when a.TC_VU = 'VU' then tc_fecapertura else 999999 end as tr_tam_apertura,
case when d.rut is not null then 1 else 0 end as vista_tenencia2,
case when d.rut is not null then d.fecha_apertura else 999999 end as vista_apertura,
case when c.rut is not null then 1 else 0 end as cc_tenencia,
case when c.rut is not null then c.fecha_apertura else 999999 end as cc_apertura,
0 as av_tenencia,
0 as sav_tenencia,
0 as cons_tenencia,
0 as dap_tenencia,
0 as pat_tenencia,
0 as seg_tenencia,
0 as chek_tenencia
from  work.tablon_productos_completo as a
left join(select rut,fecha_apertura,estado_cuenta from result.stock_cc  ) as c
    on a.rut=c.rut
left join (select rut,fecha_apertura,estado_cuenta  from result.ctavta1_stock  ) as d
    on a.rut=d.rut
;QUIT;

/* Agregar otra tablas de tarjetas act_tr y stro_cc ctav_ta1_stock*/



%if (%sysfunc(exist(publicin.act_tr_&periodo_actual.))) %then %do;
proc sql;
create table act_tr as
select a.rut
from  publicin.act_tr_&periodo_1. as a
;QUIT;
 %end;
%else %do;


proc sql;
create table act_tr as
select a.rut
from  publicin.act_tr_&periodo_2. as a
;QUIT;
%end;

proc sql;
create table stock_cc as 
select rut
from result.stock_cc 
;quit;

proc sql;
create table stock_cv as 
select rut
from result.ctavta1_stock  
;quit;

proc sql;
create table tablon_productos_aux as 
select rut from tablon_productos
union 
select rut from act_tr
union 
select rut from stock_cc
union 
select rut from stock_cv
;quit;

proc sql;
create table tablon_productos_aux2 as 
select distinct rut from tablon_productos_aux
;quit;

proc sql;
create table tablon_productos_cons2 as 
select a.rut,
case when b.rut is not null and (e.tr_tenencia+e.tam_tenencia=0 or (e.tr_tenencia is null and e.tam_tenencia is null)) then 1 else ( case when e.tam_tenencia is null then 0 else e.tam_tenencia end)  end as tam_tenencia,
case when d.rut is not null and ((e.vista_tenencia+e.vista_tenencia2)=0 or (e.vista_tenencia is null and e.vista_tenencia2 is null)) then 1 else  ( case when e.vista_tenencia is null then 0 else e.vista_tenencia end)  end as vista_tenencia,
case when c.rut is not null and (e.cc_tenencia=0 or e.cc_tenencia is null) then 1 else  ( case when e.cc_tenencia is null then 0 else e.cc_tenencia end) end as cc_tenencia,
case when e.tr_tenencia is null then 0 else  e.tr_tenencia end as tr_tenencia ,
e.tr_tam_apertura,
e.vista_tenencia2,
e.vista_apertura,
e.cc_apertura,
e.av_tenencia,
e.sav_tenencia,
e.cons_tenencia,
e.dap_tenencia,
e.pat_tenencia,
e.seg_tenencia,
e.chek_tenencia


from tablon_productos_aux2 as a
left join tablon_productos as e on a.rut=e.rut
left join act_tr  as b on a.rut=b.rut
left join stock_cc  as c on a.rut=c.rut
left join stock_cv as d on a.rut=d.rut
;quit;

proc sql;
create table  tablon_productos_cons as 
select 
rut,
max(tam_tenencia) as tam_tenencia,
max(vista_tenencia) as vista_tenencia,
max(cc_tenencia) as cc_tenencia,
max(tr_tenencia) as tr_tenencia,
max(tr_tam_apertura) as tr_tam_apertura,
max(vista_tenencia2) as vista_tenencia2,
max(vista_apertura) as vista_apertura,
max(cc_apertura) as cc_apertura,
max(av_tenencia) as av_tenencia,
max(sav_tenencia) as sav_tenencia,
max(cons_tenencia) as cons_tenencia,
max(dap_tenencia) as dap_tenencia,
max(pat_tenencia) as pat_tenencia,
max(seg_tenencia) as seg_tenencia,
max(chek_tenencia) as chek_tenencia

from  tablon_productos_cons2
group by rut
;Quit;





proc sql;
create table WORK.seg_login_mensual_productos as
select
a.*,
case when b.rut is not null and (b.tr_tenencia =1 or b.tam_tenencia =1) then 1 else 0 end as Credito,
case when b.rut is not null and b.tr_tenencia =1 then 1 else 0 end as TR,
case when b.rut is not null and b.tam_tenencia =1  then 1 else 0 end as TAM,
case when b.rut is not null and (b.cc_tenencia=1 or b.vista_tenencia=1 or b.vista_tenencia2=1) then 1 else 0 end as Debito,
case when b.rut is not null and b.cc_tenencia=1 then 1 else 0 end as CC,
case when b.rut is not null and (b.vista_tenencia=1 or b.vista_tenencia2=1) then 1 else 0 end as CV,
case when b.rut is not null and (b.tr_tenencia =1 or b.tam_tenencia =1) and b.cc_tenencia=1 then 1 else 0 end as TR_TAM_CC,
case when b.rut is not null and (b.tr_tenencia =1 or b.tam_tenencia =1) and (b.vista_tenencia=1 or b.vista_tenencia2=1) then 1 else 0 end as TR_TAM_CV,
case when b.rut is not null and (b.tr_tenencia =1 or b.tam_tenencia =1) and (b.vista_tenencia=1 or b.vista_tenencia2=1) and b.cc_tenencia=1 then 1 else 0 end as TR_TAM_CC_CV,
case when b.rut is not null and b.tr_tenencia =0 and b.tam_tenencia =0 and b.vista_tenencia=0 and b.vista_tenencia2=0 and b.cc_tenencia=0 then 1 else 0 end as Sin_tarjeta,
case when b.rut is not null and b.av_tenencia=1 then 1 else 0 end as av_tenencia,
case when b.rut is not null and b.sav_tenencia=1 then 1 else 0 end as sav_tenencia,
case when b.rut is not null and b.cons_tenencia=1 then 1 else 0 end as cons_tenencia,
case when b.rut is not null and b.dap_tenencia=1 then 1 else 0 end as dap_tenencia,
case when b.rut is not null and b.pat_tenencia=1 then 1 else 0 end as pat_tenencia,
case when b.rut is not null and b.seg_tenencia=1 then 1 else 0 end as seg_tenencia,
case when b.rut is not null and b.chek_tenencia=1 then 1 else 0 end as chek_tenencia
from  WORK.segmentacion_con_saldo as a
left join  tablon_productos_cons   as b
on a.rut=b.rut
;Quit;

%put ################################################################;
%put ########            Ripley Puntos GO                ############;
%put ################################################################;

    /*Fuente de datos:  PUBLICIN.SEGMENTO_COMERCIAL */

proc sql;
create table ripley_puntos as 
select 
rut, segmento
from PUBLICIN.SEGMENTO_COMERCIAL
where periodo=&periodo_actual.
;quit;


proc sql;
create table WORK.seg_login_mensual_rpgo as
select
a.*,
case when b.rut is not null and b.segmento ='RIPLEY_BAJA' then 1 else 0 end as R_baja,
case when b.rut is not null and b.segmento ='R_GOLD' then 1 else 0 end as R_gold,
case when b.rut is not null and b.segmento ='R_PLUS' then 1 else 0 end as R_plus,
case when b.rut is not null and b.segmento ='R_SILVER' then 1 else 0 end as R_silver,
case when b.rut is not null and b.segmento not in ('RIPLEY_BAJA') then 1 else 0 end as Mas_De_5k_puntos,
case when b.rut is not null and b.segmento ='RIPLEY_BAJA' then 1 else 0 end as Menos_De_5k_puntos
from  WORK.seg_login_mensual_productos as a
left join  ripley_puntos   as b
on a.rut=b.rut
;Quit;




%put ################################################################;
%put ########       Compras en SPOS,TDA,RCOM             ############;
%put ################################################################;


/* Compras últimos 30 días*/

/* Compra en SPOS*/


 proc sql;
 create table spos_aut_presencial_aux as 
 select rut, 'presencial' as tipo_compra
 from publicin.SPOS_AUT_&periodo_1.
 where presencial='PRESENCIAL'
 ;Quit;

proc sql;
create table spos_aut_presencial as 
select rut,max(tipo_compra) as tipo_compra
from spos_aut_presencial_aux
group by rut
;quit;


proc sql;
 create table spos_aut_digital_aux as 
 select rut, 'digital' as tipo_compra
 from publicin.SPOS_AUT_&periodo_1.
 where presencial='NO PRESENCIAL'
 ;Quit;

 proc sql;
create table spos_aut_digital as 
select rut,max(tipo_compra) as tipo_compra
from spos_aut_digital_aux
group by rut
;quit;

proc sql;
 create table spos_ctacte_presencial_aux as 
 select rut, 'presencial' as tipo_compra
 from publicin.SPOS_CTACTE_&periodo_1.
 where si_digital=0 
 ;Quit;

proc sql;
create table spos_ctacte_presencial as 
select rut,max(tipo_compra) as tipo_compra
from spos_ctacte_presencial_aux
group by rut
;quit;

proc sql;
 create table spos_ctacte_digital_aux as 
 select rut, 'digital' as tipo_compra
 from publicin.SPOS_CTACTE_&periodo_1.
 where si_digital=1 
 ;Quit;

proc sql;
create table spos_ctacte_digital as 
select rut,max(tipo_compra) as tipo_compra
from spos_ctacte_digital_aux
group by rut
;quit;

proc sql;
 create table spos_MCD_presencial_aux as 
 select rut, 'presencial' as tipo_compra
 from publicin.SPOS_MCD_&periodo_1.
 where si_digital=0 
 ;Quit;

proc sql;
create table spos_MCD_presencial as 
select rut,max(tipo_compra) as tipo_compra
from spos_MCD_presencial_aux
group by rut
;quit;


proc sql;
 create table spos_MCD_digital_aux as 
 select rut, 'digital' as tipo_compra
 from publicin.SPOS_MCD_&periodo_1.
 where si_digital=1 
 ;Quit;

proc sql;
create table spos_MCD_digital as 
select rut,max(tipo_compra) as tipo_compra
from spos_MCD_digital_aux
group by rut
;quit;



proc sql;
create table spos_aut_base as 
select 
rut 
from spos_aut_presencial
union
select 
rut
from spos_aut_digital
union
select 
rut 
from spos_ctacte_presencial
union
select 
rut
from spos_ctacte_digital
union
select 
rut 
from spos_mcd_presencial
union
select 
rut
from spos_mcd_digital
;quit;


proc sql;
create table WORK.base_spos_3d as 
select a.rut, 
1 as compra_spos,
case when b.rut is not null  then 1 else 0 end as compra_presencial_tr,
case when c.rut is not null  then 1 else 0 end as compra_online_tr,
case when d.rut is not null or f.rut is not null   then 1 else 0 end as compra_presencial_td,
case when e.rut is not null or g.rut is not null then 1 else 0 end as compra_online_td,
case when b.rut is not null or c.rut is not null then 1 else 0 end as compra_tr,
case when d.rut is not null or f.rut is not null or e.rut is not null or g.rut is not null  then 1 else 0 end as compra_td
from spos_aut_base as a
left join spos_aut_presencial as b on a.rut=b.rut
left join spos_aut_digital as c on a.rut=c.rut
left join spos_ctacte_presencial as d on a.rut=d.rut
left join spos_ctacte_digital as  e on a.rut=e.rut
left join spos_mcd_presencial as f on a.rut=f.rut
left join spos_mcd_digital as g on a.rut=g.rut
;quit;




/*Compra en tda*/


proc sql ; 
create table tda_itf_presencial_aux as 
select rut,'presencial' as tipo_compra
from publicin.TDA_ITF_&periodo_1.
where sucursal<>39 
;quit;

proc sql;
create table tda_itf_presencial as 
select rut,max(tipo_compra) as tipo_compra
from tda_itf_presencial_aux
group by rut
;quit;


proc sql ; 
create table tda_itf_digital_aux as 
select rut,'digital' as tipo_compra
from publicin.TDA_ITF_&periodo_1.
where sucursal=39 
;quit;

proc sql;
create table tda_itf_digital as 
select rut,max(tipo_compra) as tipo_compra
from tda_itf_digital_aux
group by rut
;quit;


proc sql ; 
create table tda_ctacte_presencial_aux as 
select rut,'presencial' as tipo_compra
from publicin.TDA_CTACTE_&periodo_1.
where si_digital=0  
;quit;

proc sql;
create table tda_ctacte_presencial as 
select rut,max(tipo_compra) as tipo_compra
from tda_ctacte_presencial_aux
group by rut
;quit;



proc sql ; 
create table tda_ctacte_digital_aux as 
select rut,'digital' as tipo_compra
from publicin.TDA_CTACTE_&periodo_1.
where si_digital=1
;quit;

proc sql;
create table tda_ctacte_digital as 
select rut,max(tipo_compra) as tipo_compra
from tda_ctacte_digital_aux
group by rut
;quit;


proc sql ; 
create table tda_MCD_presencial_aux as 
select rut,'presencial' as tipo_compra
from publicin.TDA_MCD_&periodo_1.
where si_digital=0  
;quit;

proc sql;
create table tda_MCD_presencial as 
select rut,max(tipo_compra) as tipo_compra
from tda_MCD_presencial_aux 
group by rut
;quit;

proc sql ; 
create table tda_MCD_digital_aux as 
select rut,'digital' as tipo_compra
from publicin.TDA_MCD_&periodo_1.
where si_digital=1
;quit;

proc sql;
create table tda_MCD_digital as 
select rut,max(tipo_compra) as tipo_compra
from tda_MCD_digital_aux 
group by rut
;quit;



proc sql;
create table tda_aut_base as 
select 
rut 
from tda_itf_presencial
union
select 
rut
from tda_itf_digital
union
select 
rut 
from tda_ctacte_presencial
union
select 
rut
from tda_ctacte_digital
union
select 
rut 
from tda_MCD_presencial
union
select 
rut
from tda_MCD_digital
;quit;


proc sql;
create table WORK.base_tda_3d as 
select a.rut, 
1 as compra_tda,
case when b.rut is not null  then 1 else 0 end as compra_presencial_tr,
case when c.rut is not null  then 1 else 0 end as compra_online_tr,
case when d.rut is not null or f.rut is not null   then 1 else 0 end as compra_presencial_td,
case when e.rut is not null or g.rut is not null then 1 else 0 end as compra_online_td,
case when b.rut is not null or c.rut is not null then 1 else 0 end as compra_tr,
case when d.rut is not null or f.rut is not null or e.rut is not null or g.rut is not null then 1 else 0 end as compra_td
from tda_aut_base as a
left join tda_itf_presencial as b on a.rut=b.rut
left join tda_itf_digital as c on a.rut=c.rut
left join tda_ctacte_presencial as d on a.rut=d.rut
left join tda_ctacte_digital as  e on a.rut=e.rut
left join tda_mcd_presencial as f on a.rut=f.rut
left join tda_mcd_digital as g on a.rut=g.rut
;quit;


proc sql;
create table WORK.seg_login_mensual_compras_30d as
select
a.*,
case when ((b.rut is not null and b.compra_tda=1) or( c.rut is not null and c.compra_spos=1)) then 1 else 0 end as compra_ma,
case when (b.rut is not null and b.compra_tr=1) or (c.rut is not null and c.compra_tr=1) then 1 else 0 end as compra_tr_ma,
case when (b.rut is not null and b.compra_td=1) or (c.rut is not null and c.compra_td=1) then 1 else 0 end as compra_td_ma,
case when b.rut is not null then b.compra_presencial_tr else 0 end as tda_compra_presencial_tr_ma,
case when b.rut is not null then b.compra_online_tr else 0 end as tda_compra_online_tr_ma,
case when b.rut is not null then b.compra_presencial_td else 0 end as tda_compra_presencial_td_ma,
case when b.rut is not null then b.compra_online_td else 0 end as tda_compra_online_td_ma,
case when b.rut is not null then b.compra_tr else 0 end as tda_compra_tr_ma,
case when b.rut is not null then b.compra_td else 0 end as tda_compra_td_ma,

case when c.rut is not null then c.compra_presencial_tr else 0 end as spos_compra_presencial_tr_ma,
case when c.rut is not null then c.compra_online_tr else 0 end as spos_compra_online_tr_ma,
case when c.rut is not null then c.compra_presencial_td else 0 end as spos_compra_presencial_td_ma,
case when c.rut is not null then c.compra_online_td else 0 end as spos_compra_online_td_ma,
case when c.rut is not null then c.compra_tr else 0 end as spos_compra_tr_ma,
case when c.rut is not null then c.compra_td else 0 end as spos_compra_td_ma


from  WORK.seg_login_mensual_rpgo as a
left join  WORK.base_tda_3d  as b on a.rut=b.rut
left join WORK.base_spos_3d   as c on a.rut=c.rut
;Quit;



/* Más de 5 compras ult 3 meses*/

/* Compras en SPOS*/



 proc sql;
 create table spos_aut_aux as 
 select rut,venta_tarjeta,fecha,hora,presencial
 from publicin.SPOS_AUT_&periodo_1.
 union 
 select rut,venta_tarjeta,fecha,hora,presencial
 from publicin.SPOS_AUT_&periodo_2.
 union 
 select rut,venta_tarjeta,fecha,hora,presencial
 from publicin.SPOS_AUT_&periodo_3.
 ;Quit;

 proc sql;
create table spos_aut as 
select rut,
count(case when presencial = 'PRESENCIAL' then rut end) as cant_presencial,
count(case when presencial = 'NO PRESENCIAL' then rut end) as cant_digital,
count(rut) as cant_compra
from spos_aut_aux
group by rut
;Quit;

proc sql;
 create table spos_ctacte_aux as 
 select fecha,rut,codigo_comercio,venta_tarjeta,si_digital
 from publicin.SPOS_CTACTE_&periodo_1.
 union 
 select fecha,rut,codigo_comercio,venta_tarjeta,si_digital
 from publicin.SPOS_CTACTE_&periodo_2.
 union 
 select fecha,rut,codigo_comercio,venta_tarjeta,si_digital
 from publicin.SPOS_CTACTE_&periodo_3.
 ;Quit;

 proc sql;
create table spos_ctacte as 
select rut,
count(case when si_digital=0 then rut end) as cant_presencial,
count(case when si_digital=1 then rut end) as cant_digital,
count(rut) as cant_compra
from spos_ctacte_aux
group by rut
;Quit;

proc sql;
 create table spos_mcd_aux as 
 select fecha,rut,codigo_comercio,venta_tarjeta,si_digital
 from publicin.SPOS_MCD_&periodo_1.
 union 
 select fecha,rut,codigo_comercio,venta_tarjeta,si_digital
 from publicin.SPOS_MCD_&periodo_2.
 union 
 select fecha,rut,codigo_comercio,venta_tarjeta,si_digital
 from publicin.SPOS_MCD_&periodo_3.
 ;Quit;

 proc sql;
create table spos_mcd as 
select rut,
count(case when si_digital=0 then rut end) as cant_presencial,
count(case when si_digital=1 then rut end) as cant_digital,
count(rut) as cant_compra
from spos_mcd_aux
group by rut
;Quit;





proc sql;
create table spos_aut_base_3m as 
select 
rut 
from spos_aut
union
select 
rut 
from spos_ctacte
union
select 
rut 
from spos_mcd

;quit;


proc sql;
create table WORK.base_spos_3m as 
select a.rut, 
1 as compra_spos,
case when b.rut is not null and b.cant_presencial>=5   then 1 else 0 end as compra_presencial_tr,
case when b.rut is not null and b.cant_digital>=5   then 1 else 0 end as compra_digital_tr,
case when b.rut is not null and b.cant_compra>=5   then 1 else 0 end as compra_tr,
case when (c.rut is not null or  d.rut is not null) and ((case when c.cant_presencial is not null then c.cant_presencial else 0 end) +(case when d.cant_presencial is not null then d.cant_presencial else 0 end)>=5) then 1 else 0 end as compra_presencial_td,
case when (c.rut is not null or  d.rut is not null) and ((case when c.cant_digital is not null then c.cant_digital else 0 end)+(case when d.cant_digital is not null then d.cant_digital else 0 end)>=5) then 1 else 0 end as compra_digital_td,
case when (c.rut is not null or  d.rut is not null) and ((case when c.cant_compra is not null then c.cant_compra else 0 end)+(case when d.cant_compra is not null then d.cant_compra else 0 end)>=5) then 1 else 0 end as compra_td
from spos_aut_base_3m as a
left join spos_aut as b on a.rut=b.rut
left join spos_ctacte as c on a.rut=c.rut
left join spos_mcd as d on a.rut=d.rut
;quit;






/*Compra en tda*/

 proc sql;
 create table tda_itf_aux as 
 select rut,sucursal,capital,fecha,valor_cuota
 from publicin.TDA_ITF_&periodo_1.
 union 
 select rut,sucursal,capital,fecha,valor_cuota
 from publicin.TDA_ITF_&periodo_2.
 union 
 select rut,sucursal,capital,fecha,valor_cuota
 from publicin.TDA_ITF_&periodo_3.
 ;Quit;

 proc sql;
create table tda_itf as 
select rut,
count(case when sucursal<>39 then rut end) as cant_presencial,
count(case when sucursal=39 then rut end) as cant_digital,
count(rut) as cant_compra
from tda_itf_aux
group by rut
;Quit;

proc sql;
 create table tda_ctacte_aux as 
 select fecha,rut,venta_tarjeta,si_digital,nombre_comercio
 from publicin.TDA_CTACTE_&periodo_1.
 union 
 select fecha,rut,venta_tarjeta,si_digital,nombre_comercio
 from publicin.TDA_CTACTE_&periodo_2.
 union 
 select fecha,rut,venta_tarjeta,si_digital,nombre_comercio
 from publicin.TDA_CTACTE_&periodo_3.
 ;Quit;

 proc sql;
create table tda_ctacte as 
select rut,
count(case when si_digital=0 then rut end) as cant_presencial,
count(case when si_digital=1 then rut end) as cant_digital,
count(rut) as cant_compra
from tda_ctacte_aux
group by rut
;Quit;

proc sql;
 create table tda_mcd_aux as 
 select fecha,rut,venta_tarjeta,si_digital,nombre_comercio
 from publicin.TDA_MCD_&periodo_1.
 union 
 select fecha,rut,venta_tarjeta,si_digital,nombre_comercio
 from publicin.TDA_MCD_&periodo_2.
 union 
 select fecha,rut,venta_tarjeta,si_digital,nombre_comercio
 from publicin.TDA_MCD_&periodo_3.
 ;Quit;

 proc sql;
create table tda_mcd as 
select rut,
count(case when si_digital=0 then rut end) as cant_presencial,
count(case when si_digital=1 then rut end) as cant_digital,
count(rut) as cant_compra
from tda_mcd_aux
group by rut
;Quit;



proc sql;
create table tda_aut_base_3m as 
select 
rut 
from tda_itf
union
select 
rut 
from tda_ctacte
union
select 
rut 
from tda_mcd
;quit;


proc sql;
create table WORK.base_tda_3m as 
select a.rut, 
1 as compra_tda,
case when b.rut is not null and b.cant_presencial>=5   then 1 else 0 end as compra_presencial_tr,
case when b.rut is not null and b.cant_digital>=5   then 1 else 0 end as compra_digital_tr,
case when b.rut is not null and b.cant_compra>=5   then 1 else 0 end as compra_tr,
case when (c.rut is not null or  d.rut is not null) and ((case when c.cant_presencial is not null then c.cant_presencial else 0 end )+(case when d.cant_presencial is not null then d.cant_presencial else 0 end )>=5) then 1 else 0 end as compra_presencial_td,
case when (c.rut is not null or  d.rut is not null) and ((case when c.cant_digital is not null then c.cant_digital else 0 end )+(case when d.cant_digital is not null then d.cant_digital else 0 end )>=5) then 1 else 0 end as compra_digital_td,
case when (c.rut is not null or  d.rut is not null ) and ((case when c.cant_compra is not null then c.cant_compra else 0 end )+(case when d.cant_compra is not null then d.cant_compra else 0 end ))>=5 then 1 else 0 end as compra_td,
case when (b.rut is not null or c.rut is not null or  d.rut is not null) then ((case when b.cant_digital is not null then b.cant_digital else 0 end )+(case when c.cant_digital is not null then c.cant_digital else 0 end )+(case when d.cant_digital is not null then d.cant_digital else 0 end )) end as compra_rcom

from tda_aut_base_3m as a
left join tda_itf as b on a.rut=b.rut
left join tda_ctacte as c on a.rut=c.rut
left join tda_mcd as d on a.rut=d.rut
;quit;




proc sql;
create table WORK.seg_login_mensual_compras_3m as
select
a.*,
case when ((b.rut is not null and b.compra_tda=1) or( c.rut is not null and c.compra_spos=1)) then 1 else 0 end as compra_3m,
case when (b.rut is not null and b.compra_tr=1) or (c.rut is not null and c.compra_tr=1) then 1 else 0 end as compra_tr_3m,
case when (b.rut is not null and b.compra_td=1) or (c.rut is not null and c.compra_td=1) then 1 else 0 end as compra_td_3m,
case when b.rut is not null and compra_rcom>0 then 1 else 0 end as compra_rcom_3m,
case when b.rut is not null then b.compra_presencial_tr else 0 end as tda_compra_presencial_tr_3m,
case when b.rut is not null then b.compra_digital_tr else 0 end as tda_compra_digital_tr_3m,
case when b.rut is not null then b.compra_presencial_td else 0 end as tda_compra_presencial_td_3m,
case when b.rut is not null then b.compra_digital_td else 0 end as tda_compra_digital_td_3m,
case when b.rut is not null then b.compra_tr else 0 end as tda_compra_tr_3m,
case when b.rut is not null then b.compra_td else 0 end as tda_compra_td_3m,

case when c.rut is not null then c.compra_presencial_tr else 0 end as spos_compra_presencial_tr_3m,
case when c.rut is not null then c.compra_digital_tr else 0 end as spos_compra_digital_tr_3m,
case when c.rut is not null then c.compra_presencial_td else 0 end as spos_compra_presencial_td_3m,
case when c.rut is not null then c.compra_digital_td else 0 end as spos_compra_digital_td_3m,
case when c.rut is not null then c.compra_tr else 0 end as spos_compra_tr_3m,
case when c.rut is not null then c.compra_td else 0 end as spos_compra_td_3m


from  WORK.seg_login_mensual_compras_30d as a
left join  WORK.base_tda_3m   as b on a.rut=b.rut
left join WORK.base_spos_3m   as c on a.rut=c.rut
;Quit;



%put ################################################################;
%put ########       Clientes con Rpass                   ############;
%put ################################################################;


proc sql;
create table rpass1 as 
select input(substr('Identificador Usuario'n,1,length('Identificador Usuario'n)-1),best.)  as rut
from publicin.IDNOW_REPORTEENROLAMIENTOS
where 'Descripcion Estado'n = 'OK' AND
      'Sistema Operativo'n IN ('ANDROID','IOS') AND
      'Nombre Paso'n = 'FINALIZAR ENROLAMIENTO'
		   

;Quit;

proc sql;
create table cons_rpass as 
select distinct rut from rpass1
;quit;

proc sql;
create table WORK.seg_login_mensual_rpass as
select 
a.*,
case when b.rut is not null then 1 else 0 end as rpass
from WORK.seg_login_mensual_compras_3m as a
left join cons_rpass as b
on a.rut=b.rut
;quit;


%put ################################################################;
%put ########       Oferta AV,SAV,CONS               ############;
%put ################################################################;

%if (%sysfunc(exist(jaburtom.sav_fin_&periodo_siguiente.))) %then %do;

proc sql;
create table oferta_sav as 
select 
rut_real as rut,
monto_para_canon,
RANGO_PROB,
SAV_APROBADO_FINAL
from jaburtom.sav_fin_&periodo_actual.
union 
select 
rut_real as rut,
monto_para_canon,
RANGO_PROB,
SAV_APROBADO_FINAL
from jaburtom.sav_fin_&periodo_siguiente.
where rut_real not in (select rut_real from jaburtom.sav_fin_&periodo_actual.) 
;QUIT;
 %end;
%else %do;
proc sql;
create table oferta_sav as 
select 
rut_real as rut,
monto_para_canon,
RANGO_PROB,
SAV_APROBADO_FINAL
from jaburtom.sav_fin_&periodo_actual.
;QUIT;
%end;

%if (%sysfunc(exist(kmartine.avance_&periodo_siguiente.))) %then %do;

proc sql;
create table oferta_av as 
select 
rut_registro_civil,
AVANCE_FINAL,
RANGO_PROB
from kmartine.avance_&periodo_actual.
union 
select 
rut_registro_civil,
AVANCE_FINAL,
RANGO_PROB
from kmartine.avance_&periodo_siguiente.
where rut_registro_civil not in (select rut_registro_civil from kmartine.avance_&periodo_actual.)
;QUIT;
 %end;
%else %do;
proc sql;
create table oferta_av as 
select 
rut_registro_civil,
AVANCE_FINAL,
RANGO_PROB
from kmartine.avance_&periodo_actual.
;QUIT;
%end;

%if (%sysfunc(exist(JABURTOM.OFERTA_CONS_ONLINE_&periodo_siguiente. ))) %then %do;

proc sql;
create table oferta_consumo as 
SELECT RUT,MAX(MONTO_OFERTA) AS MONTO_OFERTA 
FROM JABURTOM.OFERTA_CONS_ONLINE_&periodo_actual. 
GROUP BY RUT
union 
SELECT RUT,MAX(MONTO_OFERTA) AS MONTO_OFERTA 
FROM JABURTOM.OFERTA_CONS_ONLINE_&periodo_actual. 
where rut not in (select rut from JABURTOM.OFERTA_CONS_ONLINE_&periodo_actual. )
GROUP BY RUT
;QUIT;
 %end;
%else %do;
proc sql;
create table oferta_consumo as 
SELECT RUT,MAX(MONTO_OFERTA) AS MONTO_OFERTA 
FROM JABURTOM.OFERTA_CONS_ONLINE_&periodo_actual. 
GROUP BY RUT
;QUIT;
%end;

proc sql;
create table cons_oferta as 
select distinct a.rut from oferta_sav as a where a.SAV_APROBADO_FINAL=1
union
select distinct b.rut_registro_civil as rut from oferta_av as b where b.AVANCE_FINAL >0
union
select distinct c.rut from oferta_consumo as c where c.MONTO_OFERTA>0
;quit;


proc sql;
create table WORK.seg_login_mensual_oferta_ppff as
select a.*,
case when b.rut is not null then 1 else 0 end as oferta_ppff,
case when c.rut_registro_civil is not null then 1 else 0 end as oferta_av,
case when d.rut is not null then 1 else 0 end as oferta_sav,
case when e.rut is not null then 1 else 0 end as oferta_cons

from WORK.seg_login_mensual_rpass as a
left join cons_oferta as b
on a.rut=b.rut
left join oferta_av as c
on a.rut=c.rut_registro_civil
left join oferta_sav as d
on a.rut=d.rut
left join oferta_consumo as e
on a.rut=e.rut
;quit;


%put ################################################################;
%put ########       Variables Demográficos               ############;
%put ################################################################;

%if (%sysfunc(exist(publicin.demo_basket_&periodo_actual.))) %then %do;

proc sql;
create table demograficas as 
select 
rut,
edad,
renta,
RANGO_EDAD,
sexo,
TRAMO_RENTA,
gse,
&periodo_actual. as periodo
from publicin.demo_basket_&periodo_1.
;QUIT;
%end;
%else %do;
proc sql;
create table demograficas as 
select 
rut,
edad,
renta,
RANGO_EDAD,
sexo,
TRAMO_RENTA,
gse,
&periodo_1. as periodo
from publicin.demo_basket_&periodo_2.
;QUIT;
%end;




/* Nuevo GSE - Agregar tramos de renta*/
proc sql;
create table demograficas2 as 
select 
rut,
categoria_gse,
case 
when ingreso_familiar > 1000000 then '1MM o mas'
when ingreso_familiar between 500000 and 1000000 then '500 - 1MM'
when ingreso_familiar between 400000 and 500000 then '400 - 500'
when ingreso_familiar between 300000 and 400000 then '300 - 400'
when ingreso_familiar between 200000 and 300000 then '200 - 300'
when ingreso_familiar <= 200000 then '1 - 200' 
end as tramo_renta,
ingreso_familiar
from RSEPULV.GSE_CORP 
;QUIT;





proc sql;
create table &libreria..seg_login_total_demo_&periodo_actual. as
select 
a.*,
case when b.rut is not null then b.rango_edad else 'NA' end as rango_edad,
case when c.rut is not null then c.tramo_renta
when b.rut is not null then b.tramo_renta 
else 'NA' end as tramo_renta,
case when b.rut is not null then b.gse else 'NA' end as gse,
case when b.rut is not null then b.sexo else 'NA' end  as sexo,
case when b.rut is not null then b.edad else 0 end as edad,
case when c.rut is not null then c.ingreso_familiar
when b.rut is not null then b.renta else 0 end as renta

from WORK.seg_login_mensual_oferta_ppff as a
left join demograficas as b
on a.rut=b.rut
left join demograficas2 as c
on a.rut=c.rut
;QUIT;



%put ################################################################;
%put ########         Tarjeta Adicional y PAT               ############;
%put ################################################################;




proc sql;
create table tablon_productos_ta as
select a.rut,
ta_tenencia,
pat_tenencia
from  work.tablon_productos_completo as a
where  tc_tipo in ('TR','TAM') and tc_saldo>0
;QUIT;


proc sql;
create table work.seg_login_mensual_ta as
select 
a.*,
case when b.rut is not null then b.ta_tenencia else 0 end as ta_tenencia,
case when b.rut is not null then b.pat_tenencia else 0 end as pat_tenencia

from &libreria..seg_login_total_demo_&periodo_actual. as a
left join tablon_productos_ta as b
on a.rut=b.rut
;QUIT;



%put ################################################################;
%put ########               Gift Card                    ############;
%put ################################################################;


%if (%sysfunc(exist(BSOTO.CANJES_RP_&periodo_actual.))) %then %do;

proc sql;
create table cons_gf  as 
select distinct rut from BSOTO.CANJES_RP_&periodo_actual. where Tipo_Canje_OP = 'GIFTCARD'
union 
select distinct rut from BSOTO.CANJES_RP_&periodo_1. where Tipo_Canje_OP = 'GIFTCARD'
union 
select distinct rut from BSOTO.CANJES_RP_&periodo_2. where Tipo_Canje_OP = 'GIFTCARD'
union 
select distinct rut from BSOTO.CANJES_RP_&periodo_3. where Tipo_Canje_OP = 'GIFTCARD'
union 
select distinct rut from BSOTO.CANJES_RP_&periodo_4. where Tipo_Canje_OP = 'GIFTCARD'
union 
select distinct rut from BSOTO.CANJES_RP_&periodo_5. where Tipo_Canje_OP = 'GIFTCARD'
;quit;
 %end;

%else %do;

proc sql;
create table cons_gf  as 
select distinct rut from BSOTO.CANJES_RP_&periodo_1. where Tipo_Canje_OP = 'GIFTCARD'
union 
select distinct rut from BSOTO.CANJES_RP_&periodo_2. where Tipo_Canje_OP = 'GIFTCARD'
union 
select distinct rut from BSOTO.CANJES_RP_&periodo_3. where Tipo_Canje_OP = 'GIFTCARD'
union 
select distinct rut from BSOTO.CANJES_RP_&periodo_4. where Tipo_Canje_OP = 'GIFTCARD'
union 
select distinct rut from BSOTO.CANJES_RP_&periodo_5. where Tipo_Canje_OP = 'GIFTCARD'
union 
select distinct rut from BSOTO.CANJES_RP_&periodo_6. where Tipo_Canje_OP = 'GIFTCARD'
;quit;
%end;


proc sql;
create table work.seg_login_mensual_gc as
select 
a.*,
case when b.rut is not null then 1 else 0 end as canje_gf_ult_6m
from work.seg_login_mensual_ta as a
left join cons_gf as b
on a.rut=b.rut
;QUIT;


%put ################################################################;
%put ########               Arreglo DAP                  ############;
%put ################################################################;


%if (%sysfunc(exist(PUBLICIN.STOCK_DAP_&periodo_actual.))) %then %do;

proc sql;
create table dap  as 
select rut,count(case when Sucursal = 70 then 1 else 0 end) as dap_digital,sum(Capital_Vigente) as monto_dap
from PUBLICIN.STOCK_DAP_&periodo_actual. 
where Composicion_Institucional = 'PERSONAS NATURALES'
group by rut

;quit;
 %end;

%else %do;

proc sql;
create table dap  as 
select rut,
count(case when Sucursal = 70 then 1 else 0 end) as dap_digital,
sum(Capital_Vigente) as monto_dap
from PUBLICIN.STOCK_DAP_&periodo_1. 
where Composicion_Institucional = 'PERSONAS NATURALES'
group by rut
;quit;
%end;

proc sql;
create table work.seg_login_mensual_dap as
select 
a.*,
case when b.rut is not null then 1 else 0 end as dap_tenencia_cor,
case when b.rut is not null and dap_digital = 1 then 1 else 0 end as dap_digital,
case when b.rut is not null then monto_dap else 0 end as monto_dap

from work.seg_login_mensual_gc as a
left join dap as b
on a.rut=b.rut
;QUIT;


LIBNAME BOTGEN ORACLE PATH='REPORITF.WORLD' SCHEMA='BOTGEN_ADM' USER='JABURTOM' PASSWORD='JABU#_1107';


%put ################################################################;
%put ########          Tenencia MC BLACK                 ############;
%put ################################################################;


LIBNAME SFA  	ORACLE PATH='REPORITF.WORLD' SCHEMA='SFADMI_ADM' USER='JABURTOM'  PASSWORD='JABU#_1107' /*dbmax_text=7025*/;
LIBNAME R_bopers ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='JABURTOM' PASSWORD='JABU#_1107';
LIBNAME R_botgen ORACLE PATH='REPORITF.WORLD' SCHEMA='BOTGEN_ADM' USER='JABURTOM' PASSWORD='JABU#_1107';
LIBNAME MPDT  	ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='JABURTOM'  PASSWORD='JABU#_1107';

proc sql;
create table mc_black as
select distinct input(a.PEMID_GLS_NRO_DCT_IDE_K,best.) as RUT,
b.*
from R_bopers.bopers_mae_ide a, MPDT.mpdt007 b
where producto = '14'
and b.fecbaja = '0001-01-01'
and b.codestcta not in (6)
and a.pemid_nro_inn_ide = input(b.identcli,best.)
;QUIT;

proc sql;
create table work.seg_login_mensual_mc_black as
select 
a.*,
case when b.rut is not null then 1 else 0 end as mc_black_tenencia
from work.seg_login_mensual_dap as a
left join mc_black as b
on a.rut=b.rut
;QUIT;


%put ################################################################;
%put ########               Pago EPU                     ############;
%put ################################################################;


%if (%sysfunc(exist(RESULT.PAGOS_DIGITALES_&periodo_actual.))) %then %do;

proc sql;
create table pagos_epu  as 
select 
rut,
fecha,
input(put(input(fecha,yymmdd10.),date9.),date9.) format=date9. as fecha_pago,
sucursal,
monto,
case 
when nomcomred = 'RIPLEY CAR S.A' and tipo = 'BANCO' THEN 'Banco'
when nomcomred = 'RIPLEY CAR S.A' and tipo = 'CCSS'  THEN 'Tienda'
when nomcomred = 'RIPLEY CAR S.A' and tipo = 'TIENDA'  THEN 'Tienda'
when nomcomred = 'Servipag' and tipo = 'HB_SERV'  THEN 'Internet'
when nomcomred = 'Servipag' and tipo = 'SERV_fisico'  THEN 'Servipag'
when nomcomred = 'UNIRED' and tipo = 'UNIRED'  THEN 'Batch'
when nomcomred = 'Khipu' and tipo = 'KIPHU'  THEN 'Internet'
when nomcomred = 'Sencillito Provincia' and tipo = 'OTROS_PRESENCIALES'  THEN 'Batch'
when nomcomred = 'Abono Provincia Chilexpress' and tipo = 'CHILEEXPRESS'  THEN 'Batch'
when nomcomred = 'BANCO ESTADO' and tipo = 'CAJA_VECINA'  THEN 'Batch'
when nomcomred = 'Banco Ripley' and tipo = 'HB_SERV'  THEN 'Internet'
when nomcomred = 'Boton de Pago Santander' and tipo = 'SANTANDER'  THEN 'Internet'
when nomcomred = '' and tipo = 'BANCO'  THEN 'Banco'
when nomcomred = '' and tipo = 'TIENDA'  THEN 'Tienda'
when nomcomred = '' and tipo = 'CCSS'  THEN 'Tienda'
when tipo = 'TIENDA' then 'Tienda'
else 'Otros' end as clasificacion_pago_epu,
nomcomred,
tipo
from  RESULT.PAGOS_DIGITALES_&periodo_actual.
union all
select 
rut,
fecha,
input(put(input(fecha,yymmdd10.),date9.),date9.) format=date9. as fecha_pago,
sucursal,
monto,
case 
when nomcomred = 'RIPLEY CAR S.A' and tipo = 'BANCO' THEN 'Banco'
when nomcomred = 'RIPLEY CAR S.A' and tipo = 'CCSS'  THEN 'Tienda'
when nomcomred = 'RIPLEY CAR S.A' and tipo = 'TIENDA'  THEN 'Tienda'
when nomcomred = 'Servipag' and tipo = 'HB_SERV'  THEN 'Internet'
when nomcomred = 'Servipag' and tipo = 'SERV_fisico'  THEN 'Servipag'
when nomcomred = 'UNIRED' and tipo = 'UNIRED'  THEN 'Batch'
when nomcomred = 'Khipu' and tipo = 'KIPHU'  THEN 'Internet'
when nomcomred = 'Sencillito Provincia' and tipo = 'OTROS_PRESENCIALES'  THEN 'Batch'
when nomcomred = 'Abono Provincia Chilexpress' and tipo = 'CHILEEXPRESS'  THEN 'Batch'
when nomcomred = 'BANCO ESTADO' and tipo = 'CAJA_VECINA'  THEN 'Batch'
when nomcomred = 'Banco Ripley' and tipo = 'HB_SERV'  THEN 'Internet'
when nomcomred = 'Boton de Pago Santander' and tipo = 'SANTANDER'  THEN 'Internet'
when nomcomred = '' and tipo = 'BANCO'  THEN 'Banco'
when nomcomred = '' and tipo = 'TIENDA'  THEN 'Tienda'
when nomcomred = '' and tipo = 'CCSS'  THEN 'Tienda'
when tipo = 'TIENDA' then 'Tienda'
else 'Otros' end as clasificacion_pago_epu,
nomcomred,
tipo
from  RESULT.PAGOS_DIGITALES_&periodo_1.
;quit;
 %end;

%else %do;

proc sql;
create table pagos_epu  as 
select 
rut,
fecha,
input(put(input(fecha,yymmdd10.),date9.),date9.) format=date9. as fecha_pago,
sucursal,
monto,
case 
when nomcomred = 'RIPLEY CAR S.A' and tipo = 'BANCO' THEN 'Banco'
when nomcomred = 'RIPLEY CAR S.A' and tipo = 'CCSS'  THEN 'Tienda'
when nomcomred = 'RIPLEY CAR S.A' and tipo = 'TIENDA'  THEN 'Tienda'
when nomcomred = 'Servipag' and tipo = 'HB_SERV'  THEN 'Internet'
when nomcomred = 'Servipag' and tipo = 'SERV_fisico'  THEN 'Servipag'
when nomcomred = 'UNIRED' and tipo = 'UNIRED'  THEN 'Batch'
when nomcomred = 'Khipu' and tipo = 'KIPHU'  THEN 'Internet'
when nomcomred = 'Sencillito Provincia' and tipo = 'OTROS_PRESENCIALES'  THEN 'Batch'
when nomcomred = 'Abono Provincia Chilexpress' and tipo = 'CHILEEXPRESS'  THEN 'Batch'
when nomcomred = 'BANCO ESTADO' and tipo = 'CAJA_VECINA'  THEN 'Batch'
when nomcomred = 'Banco Ripley' and tipo = 'HB_SERV'  THEN 'Internet'
when nomcomred = 'Boton de Pago Santander' and tipo = 'SANTANDER'  THEN 'Internet'
when nomcomred = '' and tipo = 'BANCO'  THEN 'Banco'
when nomcomred = '' and tipo = 'TIENDA'  THEN 'Tienda'
when nomcomred = '' and tipo = 'CCSS'  THEN 'Tienda'
when tipo = 'TIENDA' then 'Tienda'
else 'Otros' end as clasificacion_pago_epu,
nomcomred,
tipo
from  RESULT.PAGOS_DIGITALES_&periodo_1.
union all
select 
rut,
fecha,
input(put(input(fecha,yymmdd10.),date9.),date9.) format=date9. as fecha_pago,
sucursal,
monto,
case 
when nomcomred = 'RIPLEY CAR S.A' and tipo = 'BANCO' THEN 'Banco'
when nomcomred = 'RIPLEY CAR S.A' and tipo = 'CCSS'  THEN 'Tienda'
when nomcomred = 'RIPLEY CAR S.A' and tipo = 'TIENDA'  THEN 'Tienda'
when nomcomred = 'Servipag' and tipo = 'HB_SERV'  THEN 'Internet'
when nomcomred = 'Servipag' and tipo = 'SERV_fisico'  THEN 'Servipag'
when nomcomred = 'UNIRED' and tipo = 'UNIRED'  THEN 'Batch'
when nomcomred = 'Khipu' and tipo = 'KIPHU'  THEN 'Internet'
when nomcomred = 'Sencillito Provincia' and tipo = 'OTROS_PRESENCIALES'  THEN 'Batch'
when nomcomred = 'Abono Provincia Chilexpress' and tipo = 'CHILEEXPRESS'  THEN 'Batch'
when nomcomred = 'BANCO ESTADO' and tipo = 'CAJA_VECINA'  THEN 'Batch'
when nomcomred = 'Banco Ripley' and tipo = 'HB_SERV'  THEN 'Internet'
when nomcomred = 'Boton de Pago Santander' and tipo = 'SANTANDER'  THEN 'Internet'
when nomcomred = '' and tipo = 'BANCO'  THEN 'Banco'
when nomcomred = '' and tipo = 'TIENDA'  THEN 'Tienda'
when nomcomred = '' and tipo = 'CCSS'  THEN 'Tienda'
when tipo = 'TIENDA' then 'Tienda'
else 'Otros' end as clasificacion_pago_epu,
nomcomred,
tipo
from  RESULT.PAGOS_DIGITALES_&periodo_2.
;quit;
%end;

proc sql;
create table pago_epu_presencial as 
select rut,case when clasificacion_pago_epu in ('Tienda','Banco') then 1 else 0 end as pago_epu_presencial
from pagos_epu
group by rut 
;quit;

proc sql;
create table pago_epu_presencial_aux as 
select rut,max(pago_epu_presencial) as pago_epu_presencial
from pago_epu_presencial
group by rut
;quit;


proc sql;
create table pagos_epu_fecha_max as 
select rut,
max(fecha_pago) FORMAT= date9. as fecha_pago
from pagos_epu
group by rut
;quit;


proc sql;
create table pagos_epu_final as 
select 
a.rut,
a.fecha_pago,
a.clasificacion_pago_epu,
a.monto,
a.sucursal,
a.nomcomred,
a.tipo,
b.fecha_pago as fecha_pago_max,
c.pago_epu_presencial
from pagos_epu as a
inner join pagos_epu_fecha_max as b
on a.rut=b.rut and a.fecha_pago=b.fecha_pago
left join pago_epu_presencial_aux  as c
on a.rut=c.rut
;quit;

proc sql;
create table pagos_epu_final_unicos as 
select
rut,
max(fecha_pago) format=date9. as fecha_pago,
max(clasificacion_pago_epu) as clasificacion_pago_epu,
max(monto) as monto,
max(sucursal) as sucursal,
max(nomcomred) as nomcomred,
max(tipo) as tipo,
max(pago_epu_presencial) as pago_epu_presencial
from pagos_epu_final
group by rut
;quit;

proc sql;
create table work.seg_login_mensual_pago_epu as
select 
a.*,
case when b.rut is not null then 1 else 0 end as pago_epu,
case when b.rut is not null then clasificacion_pago_epu else 'Sin pago epu' end as clasificacion_pago_epu,
b.fecha_pago as fecha_ult_pago_epu,
b.pago_epu_presencial
from work.seg_login_mensual_mc_black as a
left join pagos_epu_final_unicos as b
on a.rut=b.rut
;QUIT;


%put ################################################################;
%put ########               Data IDNOW                   ############;
%put ################################################################;


proc sql;
create table transacciones_idnow as 
select 
input(substr(cliente,1,length(cliente)-1),best.)  as rut,
'Fecha Autorizacion'n format=date9. as fecha_transaccion,
'Nombre Transaccion'n as nombre_trx,
case when 'Metodo Aplicado'n='PUSH AUTH' then 'RPASS'
   when 'Metodo Aplicado'n='CLAVE COORDENADA' then 'CC'
   when 'Metodo Aplicado'n='SMS OTP' then 'SMS'
   when 'Metodo Aplicado'n='SINACOFI' then 'SINACOFI'
   when 'Metodo Aplicado'n='EMAIL OTP' then 'EMAIL'
   else 'OTRO' end as metodo_aplicado
from PUBLICIN.IDNOW_REPORTETRANSACCIONES
where 'Descripcion Estado'n = 'OK'
;quit;

proc sql;
create table trx_pat_pec_aux as 
select 
rut,
nombre_trx
from transacciones_idnow
where nombre_trx in ('PAT','PEC')
group by rut,nombre_trx
;quit;

proc sql;
create table trx_pat_pec_aux_2 as 
select 
rut,
case when nombre_trx='PAT' THEN 1 ELSE 0 END AS pat_tenencia,
case when nombre_trx='PEC' THEN 1 ELSE 0 END AS pec_tenencia
from trx_pat_pec_aux
group by rut
;quit;

proc sql;
create table trx_pat_pec as 
select
rut,
max(pat_tenencia) as pat_tenencia_idnow,
max(pec_tenencia) as pec_tenencia
from trx_pat_pec_aux_2
group by rut 
;quit;

proc sql;
create table trx_metodo_aux as 
select rut,
count(rut) as cantidad_trx,
case when metodo_aplicado = 'RPASS' THEN 1 ELSE 0 END AS uso_rpass,
case when metodo_aplicado = 'CC' THEN 1 ELSE 0 END AS uso_cc,
case when metodo_aplicado = 'SMS' THEN 1 ELSE 0 END AS uso_sms,
case when metodo_aplicado = 'SINACOFI' THEN 1 ELSE 0 END AS uso_sinacofi,
case when metodo_aplicado = 'EMAIL' THEN 1 ELSE 0 END AS uso_email
from transacciones_idnow
where fecha_transaccion >= "&INI"d and fecha_transaccion <= "&FIN"d
group by rut
;quit;

proc sql;
create table trx_metodo as 
select 
rut,
max(uso_rpass) as uso_rpass,
max(uso_cc) as uso_cc,
max(uso_sms) as uso_sms,
max(uso_sinacofi) as uso_sinacofi,
max(uso_email) as uso_email
from trx_metodo_aux
group by rut
;quit;

proc sql;
create table trx_tipo_aux as 
select rut,
nombre_trx,
count(*) as cantidad_trx
from transacciones_idnow
where fecha_transaccion >= "&INI"d and fecha_transaccion <= "&FIN"d
group by rut,nombre_trx
;quit;


proc sql;
create table trx_tipo_aux2 as 
select 
rut,
count(*) as cantidad_trx2,
case when nombre_trx = 'ACTIVACION_NFC' then 1 else 0 end as trx_nfc,
case when nombre_trx = 'ACTUALIZA DATOS' then 1 else 0 end as trx_act_datos,
case when nombre_trx = 'TRANSFERENCIA' then 1 else 0 end as trx_transferencia,
case when nombre_trx = 'VISUALIZACIONTARJETA' then 1 else 0 end as trx_visuali_tarjeta,
case when nombre_trx = 'WEBPAY' then 1 else 0 end as trx_webpay,
case when nombre_trx = 'VISUAL_CODIGO_CANJE' then 1 else 0 end as trx_cod_canje
from trx_tipo_aux
group by rut
;quit;

proc sql;
create table trx_tipo as 
select rut,
max(trx_nfc) as trx_nfc,
max(trx_act_datos) as trx_act_datos,
max(trx_transferencia) as trx_transferencia,
max(trx_visuali_tarjeta) as trx_visuali_tarjeta,
max(trx_webpay) as trx_webpay,
max(trx_cod_canje) as trx_cod_canje
from trx_tipo_aux2
group by rut
;quit;


proc sql;
create table &libreria..seg_login_mensual_idnow_&periodo_actual. as 
select a.*,
case when b.rut is not null and a.pat_tenencia= 0 then b.pat_tenencia_idnow
else a.pat_tenencia end as pat_tenencia_cons,
case when b.rut is not null then b.pec_tenencia else 0 end as pec_tenencia,
case when c.rut is not null then uso_rpass else 0 end as uso_rpass,
case when c.rut is not null then uso_cc else 0 end as uso_cc,
case when c.rut is not null then uso_sms else 0 end as uso_sms,
case when c.rut is not null then uso_sinacofi else 0 end as uso_sinacofi,
case when c.rut is not null then uso_email else 0 end as uso_email,
case when d.rut is not null then trx_nfc else 0 end as trx_nfc,
case when d.rut is not null then trx_act_datos else 0 end as trx_act_datos,
case when d.rut is not null then trx_transferencia else 0 end as trx_transferencia,
case when d.rut is not null then trx_visuali_tarjeta else 0 end as trx_visuali_tarjeta,
case when d.rut is not null then trx_webpay else 0 end as trx_webpay,
case when d.rut is not null then trx_cod_canje else 0 end as trx_cod_canje
from work.seg_login_mensual_pago_epu as a
left join trx_pat_pec as b
on a.rut = b.rut
left join trx_metodo as c
on a.rut = c.rut
left join trx_tipo as d
on a.rut = d.rut
;Quit;






%put ################################################################;
%put ########         Construir Tabla Final              ############;
%put ################################################################;


/* Análisis Clientes con saldo sin login mes anterior*/




proc sql;
create table seg_login_total_demo_Mes_Ant as
select *
from &libreria..seg_login_mensual_idnow_&periodo_1.
where tipo='Saldo sin login'
;quit;



proc sql;
create table seg_login_total_demo_mes_ant2_ as
select a.*,
case when b.rut is not null then 1 else 0 end as hizo_login,
case when b.rut is not null then b.tipo_log else a.tipo_log end as tipo_log2,
b.ultimo_log as fecha_log2
from seg_login_total_demo_Mes_Ant as a
left join (
select rut,ultimo_log,tipo_log
from &libreria..seg_login_mensual_idnow_&periodo_actual.
where tipo='Login mensual')as b
on a.rut=b.rut
;quit;

proc sql;
create table seg_login_mes_ant2_con_log as
select 
RUT,
case when hizo_login=1 then 'Saldo c/login mes ant' else 'Saldo s/login mes ant' end as tipo, 
cantidad_log,	
cantidad_log_dist_dia,	
case when hizo_login=1 then tipo_log2 else tipo_log end as tipo_log,	
case when hizo_login=1 then put(fecha_log2 ,date9.)  else put(ultimo_log+1,date9.)  end as ultimo_log,
clasificacion_cliente,
saldo_credito,
saldo_o_mov_debito,
Credito,
TR,
TAM,
Debito,
CC,
CV,
TR_TAM_CC,
TR_TAM_CV,
TR_TAM_CC_CV,
Sin_tarjeta,
av_tenencia,
sav_tenencia,
cons_tenencia,
dap_tenencia,
pat_tenencia,
seg_tenencia,
chek_tenencia,
R_baja,
R_gold,
R_plus,
R_silver,
Mas_De_5k_puntos,
Menos_De_5k_puntos,
compra_ma,
compra_tr_ma,
compra_td_ma,
tda_compra_presencial_tr_ma,
tda_compra_online_tr_ma,
tda_compra_presencial_td_ma,
tda_compra_online_td_ma,
tda_compra_tr_ma,
tda_compra_td_ma,
spos_compra_presencial_tr_ma,
spos_compra_online_tr_ma,
spos_compra_presencial_td_ma,
spos_compra_online_td_ma,
spos_compra_tr_ma,
spos_compra_td_ma,
compra_3m,
compra_tr_3m,
compra_td_3m,
compra_rcom_3m,
tda_compra_presencial_tr_3m,
tda_compra_digital_tr_3m,
tda_compra_presencial_td_3m,
tda_compra_digital_td_3m,
tda_compra_tr_3m,
tda_compra_td_3m,
spos_compra_presencial_tr_3m,
spos_compra_digital_tr_3m,
spos_compra_presencial_td_3m,
spos_compra_digital_td_3m,
spos_compra_tr_3m,
spos_compra_td_3m,
rpass,
oferta_ppff,
oferta_av,
oferta_sav,
oferta_cons,
rango_edad,
tramo_renta,
gse,
sexo,
edad,
renta,
ta_tenencia,
canje_gf_ult_6m,
dap_tenencia_cor,
dap_digital,
monto_dap,
mc_black_tenencia,
pago_epu,
clasificacion_pago_epu,
fecha_ult_pago_epu,
pago_epu_presencial,
pat_tenencia_cons,
pec_tenencia,
uso_rpass,
uso_cc,
uso_sms,
uso_sinacofi,
uso_email,
trx_nfc,
trx_act_datos,
trx_transferencia,
trx_visuali_tarjeta,
trx_webpay,
trx_cod_canje
from seg_login_total_demo_mes_ant2_ 
;quit;

proc sql;
create table seg_analisis_login_con_mes_ant  as 
select * from &libreria..seg_login_mensual_idnow_&periodo_actual.
union all
select 
RUT,tipo, cantidad_log,	cantidad_log_dist_dia,	tipo_log,	input(ultimo_log,date9.) as ultimo_log,clasificacion_cliente,saldo_credito,saldo_o_mov_debito,Credito,
TR,TAM,Debito,CC,CV,TR_TAM_CC,TR_TAM_CV,TR_TAM_CC_CV,Sin_tarjeta,av_tenencia,sav_tenencia,cons_tenencia,dap_tenencia,pat_tenencia,seg_tenencia,chek_tenencia,
R_baja,R_gold,R_plus,R_silver,Mas_De_5k_puntos,Menos_De_5k_puntos,compra_ma,compra_tr_ma,compra_td_ma,tda_compra_presencial_tr_ma,tda_compra_online_tr_ma,
tda_compra_presencial_td_ma,tda_compra_online_td_ma,tda_compra_tr_ma,tda_compra_td_ma,spos_compra_presencial_tr_ma,spos_compra_online_tr_ma,
spos_compra_presencial_td_ma,spos_compra_online_td_ma,spos_compra_tr_ma,spos_compra_td_ma,compra_3m,compra_tr_3m,compra_td_3m,
compra_rcom_3m,tda_compra_presencial_tr_3m,tda_compra_digital_tr_3m,tda_compra_presencial_td_3m,tda_compra_digital_td_3m,tda_compra_tr_3m,
tda_compra_td_3m,spos_compra_presencial_tr_3m,spos_compra_digital_tr_3m,spos_compra_presencial_td_3m,spos_compra_digital_td_3m,spos_compra_tr_3m,
spos_compra_td_3m,rpass,oferta_ppff,oferta_av,oferta_sav,oferta_cons,rango_edad,tramo_renta,gse,sexo,edad,renta,
ta_tenencia,canje_gf_ult_6m,dap_tenencia_cor,dap_digital,monto_dap,mc_black_tenencia,pago_epu,clasificacion_pago_epu,fecha_ult_pago_epu,pago_epu_presencial,
pat_tenencia_cons,pec_tenencia,uso_rpass,uso_cc,uso_sms,uso_sinacofi,uso_email,trx_nfc,trx_act_datos,trx_transferencia,trx_visuali_tarjeta,trx_webpay,trx_cod_canje
from seg_login_mes_ant2_con_log
;quit;


/* Análisis Clientes con saldo con login mes anterior que mantienen saldo este periodo evaluados sobre login del mes actual*/


proc sql;
create table seg_saldo_con_login_mes_ant as
select *
from &libreria..seg_login_mensual_idnow_&periodo_1.
where tipo='Saldo con login' and rut in ( select distinct rut from base_clientes_cons)
;quit;



proc sql;
create table seg_saldo_con_login_mes_ant2_ as
select a.*,
case when b.rut is not null then 1 else 0 end as hizo_login,
case when b.rut is not null then b.tipo_log else a.tipo_log end as tipo_log2,
b.ultimo_log as fecha_log2
from seg_saldo_con_login_mes_ant as a
left join (
select rut,ultimo_log,tipo_log
from &libreria..seg_login_mensual_idnow_&periodo_actual.
where tipo='Login mensual')as b
on a.rut=b.rut
;quit;

proc sql;
create table seg_saldo_con_login_mes_ant3_ as
select 
RUT,
case when hizo_login=1 then 'Saldo c/l m/ant' else 'Saldo s/l m/ant' end as tipo,
cantidad_log,	
cantidad_log_dist_dia,	
case when hizo_login=1 then tipo_log2 else tipo_log end as tipo_log,	
case when hizo_login=1 then put(fecha_log2 ,date9.)  else put(intnx('month',today(),&n.,'end'), date9.)  end as ultimo_log,
clasificacion_cliente,
saldo_credito,
saldo_o_mov_debito,
Credito,
TR,
TAM,
Debito,
CC,
CV,
TR_TAM_CC,
TR_TAM_CV,
TR_TAM_CC_CV,
Sin_tarjeta,
av_tenencia,
sav_tenencia,
cons_tenencia,
dap_tenencia,
pat_tenencia,
seg_tenencia,
chek_tenencia,
R_baja,
R_gold,
R_plus,
R_silver,
Mas_De_5k_puntos,
Menos_De_5k_puntos,
compra_ma,
compra_tr_ma,
compra_td_ma,
tda_compra_presencial_tr_ma,
tda_compra_online_tr_ma,
tda_compra_presencial_td_ma,
tda_compra_online_td_ma,
tda_compra_tr_ma,
tda_compra_td_ma,
spos_compra_presencial_tr_ma,
spos_compra_online_tr_ma,
spos_compra_presencial_td_ma,
spos_compra_online_td_ma,
spos_compra_tr_ma,
spos_compra_td_ma,
compra_3m,
compra_tr_3m,
compra_td_3m,
compra_rcom_3m,
tda_compra_presencial_tr_3m,
tda_compra_digital_tr_3m,
tda_compra_presencial_td_3m,
tda_compra_digital_td_3m,
tda_compra_tr_3m,
tda_compra_td_3m,
spos_compra_presencial_tr_3m,
spos_compra_digital_tr_3m,
spos_compra_presencial_td_3m,
spos_compra_digital_td_3m,
spos_compra_tr_3m,
spos_compra_td_3m,
rpass,
oferta_ppff,
oferta_av,
oferta_sav,
oferta_cons,
rango_edad,
tramo_renta,
gse,
sexo,
edad,
renta,
ta_tenencia,
canje_gf_ult_6m,
dap_tenencia_cor,
dap_digital,
monto_dap,
mc_black_tenencia,
pago_epu,
clasificacion_pago_epu,
fecha_ult_pago_epu,
pago_epu_presencial,
pat_tenencia_cons,
pec_tenencia,
uso_rpass,
uso_cc,
uso_sms,
uso_sinacofi,
uso_email,
trx_nfc,
trx_act_datos,
trx_transferencia,
trx_visuali_tarjeta,
trx_webpay,
trx_cod_canje
from seg_saldo_con_login_mes_ant2_
;quit;



proc sql;
create table seg_analisis_login_con_mes_ant_2  as 
select * from seg_analisis_login_con_mes_ant
union all
select 
RUT,tipo, cantidad_log,	cantidad_log_dist_dia,	tipo_log,	input(ultimo_log,date9.) as ultimo_log,clasificacion_cliente,saldo_credito,saldo_o_mov_debito,Credito,
TR,TAM,Debito,CC,CV,TR_TAM_CC,TR_TAM_CV,TR_TAM_CC_CV,Sin_tarjeta,av_tenencia,sav_tenencia,cons_tenencia,dap_tenencia,pat_tenencia,seg_tenencia,chek_tenencia,
R_baja,R_gold,R_plus,R_silver,Mas_De_5k_puntos,Menos_De_5k_puntos,compra_ma,compra_tr_ma,compra_td_ma,tda_compra_presencial_tr_ma,tda_compra_online_tr_ma,
tda_compra_presencial_td_ma,tda_compra_online_td_ma,tda_compra_tr_ma,tda_compra_td_ma,spos_compra_presencial_tr_ma,spos_compra_online_tr_ma,
spos_compra_presencial_td_ma,spos_compra_online_td_ma,spos_compra_tr_ma,spos_compra_td_ma,compra_3m,compra_tr_3m,compra_td_3m,
compra_rcom_3m,tda_compra_presencial_tr_3m,tda_compra_digital_tr_3m,tda_compra_presencial_td_3m,tda_compra_digital_td_3m,tda_compra_tr_3m,
tda_compra_td_3m,spos_compra_presencial_tr_3m,spos_compra_digital_tr_3m,spos_compra_presencial_td_3m,spos_compra_digital_td_3m,spos_compra_tr_3m,
spos_compra_td_3m,rpass,oferta_ppff,oferta_av,oferta_sav,oferta_cons,rango_edad,tramo_renta,gse,sexo,edad,renta,
ta_tenencia,canje_gf_ult_6m,dap_tenencia_cor,dap_digital,monto_dap,mc_black_tenencia,pago_epu,clasificacion_pago_epu,fecha_ult_pago_epu,pago_epu_presencial,
pat_tenencia_cons,pec_tenencia,uso_rpass,uso_cc,uso_sms,uso_sinacofi,uso_email,trx_nfc,trx_act_datos,trx_transferencia,trx_visuali_tarjeta,trx_webpay,trx_cod_canje
from seg_saldo_con_login_mes_ant3_
;quit;






proc sql;
delete from &libreria..seg_analisis_login
where periodo=&periodo_actual.
;quit;

/* Resumen */

proc sql;
create table &libreria..seg_analisis_login_&periodo_actual.  as 
select
ultimo_log as fecha,
tipo,
&periodo_actual. as periodo,
count(rut) as cantidad_login,
count(case when clasificacion_cliente='Recurrente' then rut end) as Recurrente,
count(case when clasificacion_cliente='Nuevo' then rut end) as Nuevos,
count(case when clasificacion_cliente='Esporádico' then rut end) as Esporadicos,
count(case when clasificacion_cliente='Inactivo' then rut end) as Inactivos,
count(case when clasificacion_cliente='Otros' then rut end) as Otros,
count(case when saldo_credito=1 then rut end) as saldo_credito,
count(case when saldo_o_mov_debito=1 then rut end) as saldo_o_mov_debito,
count(case when Credito=1 then rut end) as Credito,
count(case when Debito=1 then rut end) as Debito,
count(case when TR=1 then rut end) as TR,
count(case when TAM=1 then rut end) as TAM,
count(case when CC=1 then rut end) as CC,
count(case when CV=1 then rut end) as Cv,
count(case when TR_TAM_CC=1 then rut end) as TR_TAM_CC,
count(case when TR_TAM_CV=1 then rut end) as TR_TAM_CV,
count(case when TR_TAM_CC_CV=1 then rut end) as TR_TAM_CC_CV,
count(case when Sin_tarjeta=1 then rut end) as Sin_tarjeta,
count(case when av_tenencia=1 then rut end) as av_tenencia,
count(case when sav_tenencia=1 then rut end) as sav_tenencia,
count(case when cons_tenencia=1 then rut end) as cons_tenencia,
count(case when dap_tenencia=1 then rut end) as dap_tenencia,
count(case when pat_tenencia=1 then rut end) as pat_tenencia,
count(case when seg_tenencia=1 then rut end) as seg_tenencia,
count(case when chek_tenencia=1 then rut end) as chek_tenencia,
count(case when R_baja=1 then rut end) as R_baja,
count(case when R_gold=1 then rut end) as R_gold,
count(case when R_plus=1 then rut end) as R_plus,
count(case when R_silver=1 then rut end) as R_silver,
count(case when Mas_De_5k_puntos=1 then rut end) as Mas_De_5k_puntos,
count(case when Menos_De_5k_puntos=1 then rut end) as Menos_De_5k_puntos,
count(case when compra_ma=1 then rut end) as compra_ma,
count(case when compra_tr_ma=1 then rut end) as compra_tr_ma,
count(case when compra_td_ma=1 then rut end) as compra_td_ma,
count(case when tda_compra_presencial_tr_ma=1 then rut end) as tda_compra_presencial_tr_ma,
count(case when tda_compra_online_tr_ma=1 then rut end) as tda_compra_online_tr_ma,
count(case when tda_compra_presencial_td_ma=1 then rut end) as tda_compra_presencial_td_ma,
count(case when tda_compra_online_td_ma=1 then rut end) as tda_compra_online_td_ma,
count(case when tda_compra_tr_ma=1 then rut end) as tda_compra_tr_ma,
count(case when tda_compra_td_ma=1 then rut end) as tda_compra_td_ma,
count(case when spos_compra_presencial_tr_ma=1 then rut end) as spos_compra_presencial_tr_ma,
count(case when spos_compra_online_tr_ma=1 then rut end) as spos_compra_online_tr_ma,
count(case when spos_compra_presencial_td_ma=1 then rut end) as spos_compra_presencial_td_ma,
count(case when spos_compra_online_td_ma=1 then rut end) as spos_compra_online_td_ma,
count(case when spos_compra_tr_ma=1 then rut end) as spos_compra_tr_ma,
count(case when spos_compra_td_ma=1 then rut end) as spos_compra_td_ma,
count(case when compra_3m=1 then rut end) as compra_3m,
count(case when compra_tr_3m=1 then rut end) as compra_tr_3m,
count(case when compra_td_3m=1 then rut end) as compra_td_3m,
count(case when compra_rcom_3m=1 then rut end) as compra_rcom_3m,
count(case when tda_compra_presencial_tr_3m=1 then rut end) as tda_compra_presencial_tr_3m,
count(case when tda_compra_digital_tr_3m=1 then rut end) as tda_compra_digital_tr_3m,
count(case when tda_compra_presencial_td_3m=1 then rut end) as tda_compra_presencial_td_3m,
count(case when tda_compra_digital_td_3m=1 then rut end) as tda_compra_digital_td_3m,
count(case when tda_compra_tr_3m=1 then rut end) as tda_compra_tr_3m,
count(case when tda_compra_td_3m=1 then rut end) as tda_compra_td_3m,
count(case when spos_compra_presencial_tr_3m=1 then rut end) as spos_compra_presencial_tr_3m,
count(case when spos_compra_digital_tr_3m=1 then rut end) as spos_compra_digital_tr_3m,
count(case when spos_compra_presencial_td_3m=1 then rut end) as spos_compra_presencial_td_3m,
count(case when spos_compra_digital_td_3m=1 then rut end) as spos_compra_digital_td_3m,
count(case when spos_compra_tr_3m=1 then rut end) as spos_compra_tr_3m,
count(case when spos_compra_td_3m=1 then rut end) as spos_compra_td_3m,
count(case when rpass=1 then rut end) as con_rpass,
count(case when rpass=0 then rut end) as sin_rpass,
count(case when oferta_ppff=1 then rut end) as oferta_ppff,
count(case when oferta_av=1 then rut end) as oferta_av,
count(case when oferta_sav=1 then rut end) as oferta_sav,
count(case when oferta_cons=1 then rut end) as oferta_cons,
count(case when rango_edad='18 - 25' then rut end) as rango_18_25,
count(case when rango_edad='26 - 30' then rut end) as rango_26_30,
count(case when rango_edad='31 - 35' then rut end) as rango_31_35,
count(case when rango_edad='36 - 40' then rut end) as rango_36_40,
count(case when rango_edad='41 - 45' then rut end) as rango_41_45,
count(case when rango_edad='46 - 50' then rut end) as rango_46_50,
count(case when rango_edad='51 - 55' then rut end) as rango_51_55,
count(case when rango_edad='56 - 60' then rut end) as rango_56_60,
count(case when rango_edad='61 - 65' then rut end) as rango_61_65,
count(case when rango_edad='66 - 70' then rut end) as rango_66_70,
count(case when rango_edad='71 - 75' then rut end) as rango_71_75,
count(case when rango_edad='76 - 80' then rut end) as rango_76_80,
count(case when rango_edad in ('81 - 85','81 - 85','86 - 90','91 - 95','96 - 100') then rut end) as rango_mayor_80,
count(case when rango_edad='menorDe18' then rut end) as rango_menor_18,
count(case when rango_edad='NA' then rut end) as rango_NA,
count(case when tramo_renta='1 - 200' then rut end) as tramo_renta_menor_200,
count(case when tramo_renta='200 - 300' then rut end) as tramo_renta_200_300,
count(case when tramo_renta='300 - 400' then rut end) as tramo_renta_300_400,
count(case when tramo_renta='400 - 500' then rut end) as tramo_renta_400_500,
count(case when tramo_renta='500 - 1MM' then rut end) as tramo_renta_500_1000,
count(case when tramo_renta='1MM o mas' then rut end) as tramo_renta_mayor_1000,
count(case when tramo_renta in ('0','NA','') then rut end) as tramo_renta_NA,
count(case when gse='AB' then rut end) as gse_AB,
count(case when gse='C1a' then rut end) as gse_C1a,
count(case when gse='C1b' then rut end) as gse_C1b,
count(case when gse='C2' then rut end) as gse_C2,
count(case when gse='C3' then rut end) as gse_C3,
count(case when gse='D' then rut end) as gse_D,
count(case when gse='E' then rut end) as gse_E,
count(case when gse in ('NA','') then rut end) as gse_NA,
count(case when sexo='F' then rut end) as sexo_femenino,
count(case when sexo='M' then rut end) as sexo_masculino,
count(case when sexo in ('N','NA','') then rut end) as sexo_NA,
count(case when tipo_log='APP' then rut end) as log_APP,
count(case when tipo_log='HB' then rut end) as log_HB,
count(case when tipo_log='Ambos Canales' then rut end) as log_Ambos_Canales,
count(case when ta_tenencia=1 then rut end) as ta_tenencia,
count(case when canje_gf_ult_6m=1 then rut end) as canje_gf_ult_6m,
count(case when dap_tenencia_cor=1 then rut end) as dap_tenencia_cor,
count(case when dap_digital=1 then rut end) as dap_digital,
sum(case when dap_tenencia_cor=1 then monto_dap end) as monto_dap,
sum(case when dap_digital=1 then monto_dap end) as monto_dap_digital,
count(case when mc_black_tenencia=1 then rut end) as mc_black_tenencia,
count(case when pago_epu=1 then rut end) as pago_epu,
count(case when pago_epu=1 and clasificacion_pago_epu='Banco' then rut end) as pago_epu_banco,
count(case when pago_epu=1 and clasificacion_pago_epu='Tienda' then rut end) as pago_epu_tienda,
count(case when pago_epu=1 and clasificacion_pago_epu='Internet' then rut end) as pago_epu_internet,
count(case when pago_epu=1 and clasificacion_pago_epu='Servipag' then rut end) as pago_epu_servipag,
count(case when pago_epu=1 and clasificacion_pago_epu='Batch' then rut end) as pago_epu_batch,
count(case when pago_epu=1 and clasificacion_pago_epu='Otros' then rut end) as pago_epu_otros,
count(case when pago_epu_presencial=1 then rut end) as pago_epu_presencial,
count(case when pat_tenencia_cons=1 then rut end) as pat_tenencia_cons,
count(case when pec_tenencia=1 then rut end) as pec_tenencia,
count(case when uso_rpass=1 then rut end) as uso_rpass,
count(case when uso_cc=1 then rut end) as uso_cc,
count(case when uso_sms=1 then rut end) as uso_sms,
count(case when uso_sinacofi=1 then rut end) as uso_sinacofi,
count(case when uso_email=1 then rut end) as uso_email,
count(case when trx_nfc=1 then rut end) as trx_nfc,
count(case when trx_act_datos=1 then rut end) as trx_act_datos,
count(case when trx_transferencia=1 then rut end) as trx_transferencia,
count(case when trx_visuali_tarjeta=1 then rut end) as trx_visuali_tarjeta,
count(case when trx_webpay=1 then rut end) as trx_webpay,
count(case when trx_cod_canje=1 then rut end) as trx_cod_canje
from seg_analisis_login_con_mes_ant_2
group by ultimo_log,tipo
;QUIT;

proc sql;
insert into &libreria..seg_analisis_login
select * 
from &libreria..seg_analisis_login_&periodo_actual.
;quit;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(dgtl_seg_analisis_login,raw,oracloud,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(dgtl_seg_analisis_login,&libreria..seg_analisis_login,raw,oracloud,0);

%put ################################################################;
%put ########      Construir Tabla Final por Rut         ############;
%put ################################################################;


proc sql;
delete from &libreria..seg_perfilamiento_login
;quit;


proc sql;
create table &libreria..seg_perfilamiento_login as 
select RUT,tipo,cantidad_log,cantidad_log_dist_dia,tipo_log,put(ultimo_log,e8601da.) as ultimo_log,clasificacion_cliente,saldo_credito,saldo_o_mov_debito,Credito,TR,TAM,Debito,CC,CV,TR_TAM_CC,TR_TAM_CV,TR_TAM_CC_CV,Sin_tarjeta,av_tenencia,sav_tenencia,cons_tenencia,dap_tenencia,pat_tenencia,seg_tenencia,chek_tenencia,R_baja,R_gold,R_plus,R_silver,Mas_De_5k_puntos,Menos_De_5k_puntos,compra_ma,compra_tr_ma,compra_td_ma,tda_compra_presencial_tr_ma,tda_compra_online_tr_ma,tda_compra_presencial_td_ma,tda_compra_online_td_ma,tda_compra_tr_ma,tda_compra_td_ma,spos_compra_presencial_tr_ma,spos_compra_online_tr_ma,spos_compra_presencial_td_ma,spos_compra_online_td_ma,spos_compra_tr_ma,spos_compra_td_ma,compra_3m,compra_tr_3m,compra_td_3m,compra_rcom_3m,tda_compra_presencial_tr_3m,tda_compra_digital_tr_3m,tda_compra_presencial_td_3m,tda_compra_digital_td_3m,tda_compra_tr_3m,tda_compra_td_3m,spos_compra_presencial_tr_3m,spos_compra_digital_tr_3m,spos_compra_presencial_td_3m,spos_compra_digital_td_3m,spos_compra_tr_3m,
spos_compra_td_3m,rpass,oferta_ppff,oferta_av,oferta_sav,oferta_cons,rango_edad,tramo_renta,gse,sexo,edad,renta,ta_tenencia,canje_gf_ult_6m,dap_tenencia_cor,dap_digital,monto_dap,mc_black_tenencia,pago_epu,clasificacion_pago_epu,put(fecha_ult_pago_epu,e8601da.) as  fecha_ult_pago_epu,pago_epu_presencial,pat_tenencia_cons,pec_tenencia,uso_rpass,uso_cc,uso_sms,uso_sinacofi,uso_email,trx_nfc,trx_act_datos,trx_transferencia,trx_visuali_tarjeta,trx_webpay,trx_cod_canje,put(ultimo_log,e8601da.) as fecha
from &libreria..seg_login_mensual_idnow_&periodo_actual.
where tipo in ('Login mensual','Saldo sin login')
union all
select RUT,tipo,cantidad_log,cantidad_log_dist_dia,tipo_log,put(ultimo_log,e8601da.) as ultimo_log,clasificacion_cliente,saldo_credito,saldo_o_mov_debito,Credito,TR,TAM,Debito,CC,CV,TR_TAM_CC,TR_TAM_CV,TR_TAM_CC_CV,Sin_tarjeta,av_tenencia,sav_tenencia,cons_tenencia,dap_tenencia,pat_tenencia,seg_tenencia,chek_tenencia,R_baja,R_gold,R_plus,R_silver,Mas_De_5k_puntos,Menos_De_5k_puntos,compra_ma,compra_tr_ma,compra_td_ma,tda_compra_presencial_tr_ma,tda_compra_online_tr_ma,tda_compra_presencial_td_ma,tda_compra_online_td_ma,tda_compra_tr_ma,tda_compra_td_ma,spos_compra_presencial_tr_ma,spos_compra_online_tr_ma,spos_compra_presencial_td_ma,spos_compra_online_td_ma,spos_compra_tr_ma,spos_compra_td_ma,compra_3m,compra_tr_3m,compra_td_3m,compra_rcom_3m,tda_compra_presencial_tr_3m,tda_compra_digital_tr_3m,tda_compra_presencial_td_3m,tda_compra_digital_td_3m,tda_compra_tr_3m,tda_compra_td_3m,spos_compra_presencial_tr_3m,spos_compra_digital_tr_3m,spos_compra_presencial_td_3m,spos_compra_digital_td_3m,spos_compra_tr_3m,
spos_compra_td_3m,rpass,oferta_ppff,oferta_av,oferta_sav,oferta_cons,rango_edad,tramo_renta,gse,sexo,edad,renta,ta_tenencia,canje_gf_ult_6m,dap_tenencia_cor,dap_digital,monto_dap,mc_black_tenencia,pago_epu,clasificacion_pago_epu,put(fecha_ult_pago_epu,e8601da.) as  fecha_ult_pago_epu,pago_epu_presencial,pat_tenencia_cons,pec_tenencia,uso_rpass,uso_cc,uso_sms,uso_sinacofi,uso_email,trx_nfc,trx_act_datos,trx_transferencia,trx_visuali_tarjeta,trx_webpay,trx_cod_canje,put(ultimo_log,e8601da.) as fecha
from &libreria..seg_login_mensual_idnow_&periodo_1.
where tipo in ('Login mensual','Saldo sin login')
union all
select RUT,tipo,cantidad_log,cantidad_log_dist_dia,tipo_log,put(ultimo_log,e8601da.) as ultimo_log,clasificacion_cliente,saldo_credito,saldo_o_mov_debito,Credito,TR,TAM,Debito,CC,CV,TR_TAM_CC,TR_TAM_CV,TR_TAM_CC_CV,Sin_tarjeta,av_tenencia,sav_tenencia,cons_tenencia,dap_tenencia,pat_tenencia,seg_tenencia,chek_tenencia,R_baja,R_gold,R_plus,R_silver,Mas_De_5k_puntos,Menos_De_5k_puntos,compra_ma,compra_tr_ma,compra_td_ma,tda_compra_presencial_tr_ma,tda_compra_online_tr_ma,tda_compra_presencial_td_ma,tda_compra_online_td_ma,tda_compra_tr_ma,tda_compra_td_ma,spos_compra_presencial_tr_ma,spos_compra_online_tr_ma,spos_compra_presencial_td_ma,spos_compra_online_td_ma,spos_compra_tr_ma,spos_compra_td_ma,compra_3m,compra_tr_3m,compra_td_3m,compra_rcom_3m,tda_compra_presencial_tr_3m,tda_compra_digital_tr_3m,tda_compra_presencial_td_3m,tda_compra_digital_td_3m,tda_compra_tr_3m,tda_compra_td_3m,spos_compra_presencial_tr_3m,spos_compra_digital_tr_3m,spos_compra_presencial_td_3m,spos_compra_digital_td_3m,spos_compra_tr_3m,
spos_compra_td_3m,rpass,oferta_ppff,oferta_av,oferta_sav,oferta_cons,rango_edad,tramo_renta,gse,sexo,edad,renta,ta_tenencia,canje_gf_ult_6m,dap_tenencia_cor,dap_digital,monto_dap,mc_black_tenencia,pago_epu,clasificacion_pago_epu,put(fecha_ult_pago_epu,e8601da.) as  fecha_ult_pago_epu,pago_epu_presencial,pat_tenencia_cons,pec_tenencia,uso_rpass,uso_cc,uso_sms,uso_sinacofi,uso_email,trx_nfc,trx_act_datos,trx_transferencia,trx_visuali_tarjeta,trx_webpay,trx_cod_canje,put(ultimo_log,e8601da.) as fecha
from &libreria..seg_login_mensual_idnow_&periodo_2.
where tipo in ('Login mensual','Saldo sin login')
union all
select RUT,tipo,cantidad_log,cantidad_log_dist_dia,tipo_log,put(ultimo_log,e8601da.) as ultimo_log,clasificacion_cliente,saldo_credito,saldo_o_mov_debito,Credito,TR,TAM,Debito,CC,CV,TR_TAM_CC,TR_TAM_CV,TR_TAM_CC_CV,Sin_tarjeta,av_tenencia,sav_tenencia,cons_tenencia,dap_tenencia,pat_tenencia,seg_tenencia,chek_tenencia,R_baja,R_gold,R_plus,R_silver,Mas_De_5k_puntos,Menos_De_5k_puntos,compra_ma,compra_tr_ma,compra_td_ma,tda_compra_presencial_tr_ma,tda_compra_online_tr_ma,tda_compra_presencial_td_ma,tda_compra_online_td_ma,tda_compra_tr_ma,tda_compra_td_ma,spos_compra_presencial_tr_ma,spos_compra_online_tr_ma,spos_compra_presencial_td_ma,spos_compra_online_td_ma,spos_compra_tr_ma,spos_compra_td_ma,compra_3m,compra_tr_3m,compra_td_3m,compra_rcom_3m,tda_compra_presencial_tr_3m,tda_compra_digital_tr_3m,tda_compra_presencial_td_3m,tda_compra_digital_td_3m,tda_compra_tr_3m,tda_compra_td_3m,spos_compra_presencial_tr_3m,spos_compra_digital_tr_3m,spos_compra_presencial_td_3m,spos_compra_digital_td_3m,spos_compra_tr_3m,
spos_compra_td_3m,rpass,oferta_ppff,oferta_av,oferta_sav,oferta_cons,rango_edad,tramo_renta,gse,sexo,edad,renta,ta_tenencia,canje_gf_ult_6m,dap_tenencia_cor,dap_digital,monto_dap,mc_black_tenencia,pago_epu,clasificacion_pago_epu,put(fecha_ult_pago_epu,e8601da.) as  fecha_ult_pago_epu,pago_epu_presencial,pat_tenencia_cons,pec_tenencia,uso_rpass,uso_cc,uso_sms,uso_sinacofi,uso_email,trx_nfc,trx_act_datos,trx_transferencia,trx_visuali_tarjeta,trx_webpay,trx_cod_canje,put(ultimo_log,e8601da.) as fecha
from &libreria..seg_login_mensual_idnow_&periodo_3.
where tipo in ('Login mensual','Saldo sin login')
;quit;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(dgtl_seg_perfilamiento_login,raw,oracloud,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(dgtl_seg_perfilamiento_login,&libreria..seg_perfilamiento_login,raw,oracloud,0);
