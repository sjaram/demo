* Inicio del código EG generado (no editar esta línea);
*
*  Procedimiento almacenado registrado por
*  Enterprise Guide Stored Process Manager V7.1
*
*  ====================================================================
*  Nombre del proceso almacenado: TABLAS_CTA_VISTA
*  ====================================================================
*;


*ProcessBody;

* Start before STPBEGIN code [9e723ea299304131a2fbd067f1971770];/* Insertar código personalizado ejecutado delante de la macro STPBEGIN */
%global _ODSDEST;
%let _ODSDEST=none;
* End before STPBEGIN code [9e723ea299304131a2fbd067f1971770];

%STPBEGIN;

* Fin del código EG generado (no editar esta línea);


/*############################################################################################*/
/* 27 - 12 - 2018     Tablas de cuenta Vista                                                  */
/*############################################################################################*/

/***************************************** Validar Proceso ************************************************/

/***************************************** Comenzar Proceso ************************************************/




/*Definir Macro Parametros*/
/*::::::::::::::::::::::::::*/
%let Libreria=%nrstr('result'); /*Libreria donde quedara entregable*/
/*::::::::::::::::::::::::::*/

options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/


%put==================================================================================================;
%put [00] Calculos y Conexiones Preliminares;
%put==================================================================================================;


%put--------------------------------------------------------------------------------------------------;
%put [00.1] Calcular de fechas a utilizar;
%put--------------------------------------------------------------------------------------------------;


/*Fecha del Periodo*/
PROC SQL outobs=1;   

select 
SB_Ahora('DD/MM/AAAA_HH:MM') as Fecha_Proceso,
input(SB_Ahora('AAAAMMDD'),best.) as Fecha2_Proceso
into :Fecha_Proceso,:Fecha2_Proceso
from sbarrera.SB_Status_Tablas_IN

;QUIT;
%let Fecha_Proceso="&Fecha_Proceso";




/*Para obtener Movimientos de cuenta vista de los ultimos 3 meses*/

PROC SQL outobs=1;   

select 
input(SB_Ahora('AAAAMMDD'),best.) as anomesdia1_hasta,
SB_mover_anomes(input(SB_Ahora('AAAAMM'),best.),-2)*100+01 as anomesdia1_desde 
into 
:anomesdia1_hasta,
:anomesdia1_desde 
from sbarrera.SB_Status_Tablas_IN

;QUIT;



PROC SQL outobs=1;   

select 
cat(substr(compress(put(&anomesdia1_desde,best.)),7,2),'/',substr(compress(put(&anomesdia1_desde,best.)),5,2),'/',substr(compress(put(&anomesdia1_desde,best.)),1,4)) as Fecha1_desde,
cat(substr(compress(put(&anomesdia1_hasta,best.)),7,2),'/',substr(compress(put(&anomesdia1_hasta,best.)),5,2),'/',substr(compress(put(&anomesdia1_hasta,best.)),1,4)) as Fecha1_hasta 
into :Fecha1_desde,:Fecha1_hasta
from sbarrera.SB_Status_Tablas_IN

;QUIT;
%let Fecha1_desde="&Fecha1_desde";
%let Fecha1_hasta="&Fecha1_hasta";



PROC SQL outobs=1;   

select 
input(SB_Ahora('AAAAMM'),best.) as anomes1_T,
SB_mover_anomes(input(SB_Ahora('AAAAMM'),best.),-1) as anomes1_Tmenos1,
SB_mover_anomes(input(SB_Ahora('AAAAMM'),best.),-2) as anomes1_Tmenos2 
into 
:anomes1_T,
:anomes1_Tmenos1,
:anomes1_Tmenos2
from sbarrera.SB_Status_Tablas_IN

;QUIT;



/*Para obtener saldos de cuenta vista de los ultimos 3 meses*/


PROC SQL outobs=1;   

select 
SB_mover_anomesdia(input(SB_Ahora('AAAAMMDD'),best.),-1) as anomesdia2_T,
SB_mover_anomesdia(100*input(SB_Ahora('AAAAMM'),best.)+01,-1) as anomesdia2_Tmenos1,
SB_mover_anomesdia(100*SB_mover_anomes(input(SB_Ahora('AAAAMM'),best.),-1)+01,-1) as anomesdia2_Tmenos2 
into 
:anomesdia2_T,
:anomesdia2_Tmenos1, 
:anomesdia2_Tmenos2 
from sbarrera.SB_Status_Tablas_IN

;QUIT;



PROC SQL outobs=1;   

select 
cat(substr(compress(put(&anomesdia2_T,best.)),7,2),'/',substr(compress(put(&anomesdia2_T,best.)),5,2),'/',substr(compress(put(&anomesdia2_T,best.)),1,4)) as Fecha2_T,
cat(substr(compress(put(&anomesdia2_Tmenos1,best.)),7,2),'/',substr(compress(put(&anomesdia2_Tmenos1,best.)),5,2),'/',substr(compress(put(&anomesdia2_Tmenos1,best.)),1,4)) as Fecha2_Tmenos1,
cat(substr(compress(put(&anomesdia2_Tmenos2,best.)),7,2),'/',substr(compress(put(&anomesdia2_Tmenos2,best.)),5,2),'/',substr(compress(put(&anomesdia2_Tmenos2,best.)),1,4)) as Fecha2_Tmenos2 
into 
:Fecha2_T,
:Fecha2_Tmenos1,
:Fecha2_Tmenos2 
from sbarrera.SB_Status_Tablas_IN

;QUIT;
%let Fecha2_T="&Fecha2_T";
%let Fecha2_Tmenos1="&Fecha2_Tmenos1";
%let Fecha2_Tmenos2="&Fecha2_Tmenos2";




/*Para obtener Movimientos de cuenta vista de los ultimos 33 dias*/



PROC SQL outobs=1;   

select 
SB_mover_anomesdia(input(SB_Ahora('AAAAMMDD'),best.),-33) as anomesdia2_i  
into 
:anomesdia2_i
from sbarrera.SB_Status_Tablas_IN

;QUIT;




/*Para obtener Saldos de cuenta vista de los ultimos 12 meses*/


PROC SQL outobs=1;   

select 
input(SB_Ahora('AAAAMMDD'),best.) as anomesdia3_f,
100*SB_mover_anomes(input(SB_Ahora('AAAAMM'),best.),-12)+01 as anomesdia3_i 
into 
:anomesdia3_f,
:anomesdia3_i 
from sbarrera.SB_Status_Tablas_IN

;QUIT;



PROC SQL outobs=1;   

select 
cat(substr(compress(put(&anomesdia3_f,best.)),7,2),'/',substr(compress(put(&anomesdia3_f,best.)),5,2),'/',substr(compress(put(&anomesdia3_f,best.)),1,4)) as Fecha3_f,
cat(substr(compress(put(&anomesdia3_i,best.)),7,2),'/',substr(compress(put(&anomesdia3_i,best.)),5,2),'/',substr(compress(put(&anomesdia3_i,best.)),1,4)) as Fecha3_i 
into 
:Fecha3_f,
:Fecha3_i  
from sbarrera.SB_Status_Tablas_IN

;QUIT;
%let Fecha3_f="&Fecha3_f";
%let Fecha3_i="&Fecha3_i";




%put--------------------------------------------------------------------------------------------------;
%put [00.2] Conexion a FISA;
%put--------------------------------------------------------------------------------------------------;


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



%put==================================================================================================;
%put [01] Stock de Cuenta Vista Total;
%put==================================================================================================;


%put--------------------------------------------------------------------------------------------------;
%put [01.1] Sacar total de Stock de cuenta Vista;
%put--------------------------------------------------------------------------------------------------;



proc sql;

&mz_connect_BANCO;
create table work.Stock_CtaVta as
SELECT 
INPUT((SUBSTR(cli_identifica,1,(LENGTH(cli_identifica)-1))),BEST.) AS RUT,
vis_numcue as cuenta, 
CASE 
WHEN VIS_PRO=4 THEN 'CUENTA_VISTA' 
WHEN VIS_PRO=40 THEN 'LCA' 
END AS DESCRIPCION_PRODUCTO,
CASE 
WHEN vis_status ='9' THEN 'cerrado'
WHEN vis_status ='2' THEN 'vigente' 
end as Estado_Cuenta,
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



%put--------------------------------------------------------------------------------------------------;
%put [01.2] Sacar Movimientos de cuenta Vista (ultimos 3 meses);
%put--------------------------------------------------------------------------------------------------;


/*Sacar Movimientos*/



DATA _NULL_;
Call execute(
cat('
proc sql; 

&mz_connect_BANCO; 
create table work.Movs_CtaVta as 
SELECT 
C1.*, 
c2.cli_identifica as RUT_DV, 
INPUT((SUBSTR(c2.cli_identifica,1,(LENGTH(c2.cli_identifica)-1))),BEST.) AS RUT, 
input(SUBSTR(put(datepart(c1.FECHA),yymmddn8.),1,6),best.) as PERIODO, 
input(SUBSTR(put(datepart(c1.FECHA),yymmddn8.),1,8),best.) as CodFecha, 
case 
when c1.tmo_tipotra=''D'' then ''CARGO'' 
when c1.tmo_tipotra=''C'' then ''ABONO'' 
end as Tipo_Movimiento, 
case 
when tmo_rubro = 1 and tmo_codtra = 30 and c1.DESC_NEGOCIO like ''Depo%'' then 1 
else 0 
end as Marca_DAP, 
case 
when calculated Tipo_Movimiento=''ABONO'' 
and c1.DESCRIPCION=''DESDE OTROS BANCOS'' 
and ( 
c1.DESC_NEGOCIO CONTAINS ''Remuneraciones'' OR 
c1.DESC_NEGOCIO CONTAINS ''Anticipos'' OR 
c1.DESC_NEGOCIO CONTAINS ''Sueldos'')  then 1 
ELSE 0 
END as SI_ABR, 
CASE 
WHEN CALCULATED SI_ABR =1 AND c1.DESC_NEGOCIO CONTAINS ''BANCO RIPLEY'' THEN ''BANCO RIPLEY'' 
WHEN CALCULATED SI_ABR =1 AND c1.DESC_NEGOCIO CONTAINS ''CAR S.A.'' THEN ''CAR'' 
WHEN CALCULATED SI_ABR =1 AND c1.DESC_NEGOCIO CONTAINS ''RIPLEY STORE'' THEN ''RIPLEY STORE'' 
WHEN CALCULATED SI_ABR =1 AND ( 
c1.DESC_NEGOCIO NOT CONTAINS (''RIPLEY STORE'') or 
c1.DESC_NEGOCIO NOT CONTAINS (''CAR S.A.'') or 
c1.DESC_NEGOCIO NOT CONTAINS (''BANCO RIPLEY'') 
) THEN ''OTROS BANCOS'' 
END AS Descripcion_ABR, 
CASE 
WHEN calculated Tipo_Movimiento IN (''CARGO'') 
and (c1.DESC_NEGOCIO CONTAINS ''Ripley'' OR c1.DESC_NEGOCIO CONTAINS ''RIPLEY'') 
AND  c1.DESC_NEGOCIO NOT CONTAINS ''PAGO'' 
THEN ''COMPRA_RIPLEY'' 
END AS COMPRA_RIPLEY, 
CASE 
when calculated Tipo_Movimiento=''ABONO'' then 
case 
WHEN c1.DESCRIPCION IN (''VALOR EFECTIVO'',''EN EFECTIVO'') AND c1.GLS_TRANSAC =''DEPOSITO'' AND CALCULATED SI_ABR  NOT=1  THEN ''Depósitos en Efectivo'' 
WHEN c1.DESCRIPCION IN (''CON DOCUMENTOS'') AND c1.GLS_TRANSAC =''DEPOSITO'' AND CALCULATED SI_ABR  NOT=1 THEN ''Depósitos con Documento'' 
WHEN c1.DESCRIPCION IN (''TRANSFERENCIA DESDE OTROS BANCOS'') AND CALCULATED SI_ABR NOT =1 THEN ''TEF Recibidas'' 
WHEN c1.DESCRIPCION IN (''DESDE OTROS BANCOS'') AND CALCULATED SI_ABR NOT =1 THEN ''TEF Recibidas'' 
WHEN c1.DESCRIPCION IN (''DESDE OTROS BANCOS'') AND CALCULATED SI_ABR  =1 THEN ''Abono de Remuneraciones'' 
WHEN c1.DESCRIPCION IN (''DESDE OTROS BANCOS'') AND CALCULATED SI_ABR  not =1 and c1.DESC_NEGOCIO CONTAINS ''Proveedores'' THEN ''TEF Recibidas'' 
WHEN c1.DESCRIPCION IN (''POR REGULARIZACION'') AND CALCULATED SI_ABR  NOT=1 THEN ''Otros (pago proveedores)'' 
WHEN c1.DESCRIPCION IN (''DESDE LINEA DE CREDITO'') AND c1.GLS_TRANSAC =''TRASPASO DE FONDOS'' AND CALCULATED SI_ABR  NOT=1 THEN ''Traspaso desde LCA'' 
WHEN c1.DESCRIPCION IN (''AVANCE DESDE TARJETA DE CREDITO BANCO RIPLEY'') AND CALCULATED SI_ABR  NOT=1 THEN ''Avance desde Tarjeta Ripley'' 
WHEN c1.DESCRIPCION IN (''DEVOLUCION COMISION'') AND CALCULATED SI_ABR  NOT=1 THEN ''DEVOLUCION COMISION'' 
WHEN c1.DESCRIPCION IN (''POR TRANSFERENCIA  DE LCA A CTA VISTA'') AND CALCULATED SI_ABR  NOT=1 THEN ''Traspaso desde LCA'' 
else ''OTROS ABONOS'' 
end 
END AS Descripcion_Abono, 
CASE 
when calculated Tipo_Movimiento=''CARGO'' then 
CASE 
WHEN c1.DESCRIPCION IN (''COMPRA NACIONAL'') THEN ''Compras Redcompra'' 
WHEN c1.DESCRIPCION IN (''COMPRA INTERNACIONAL'') THEN ''Compras Internacionales'' 
WHEN c1.DESCRIPCION IN (''CARGO POR PEC'') THEN ''PEC'' 
WHEN c1.DESCRIPCION IN (''GIRO CAJERO AUTOMATICO'') THEN ''Giros ATM'' 
WHEN c1.DESCRIPCION IN (''GIRO POR CAJA'') THEN ''Giros Caja'' 
WHEN c1.DESCRIPCION IN (''GIRO INTERNACIONAL'') THEN ''Giro Internacional'' 
WHEN c1.DESCRIPCION IN (''TRANSFERENCIA A OTROS BANCOS'') THEN ''TEF emitidas Otros Bancos'' 
WHEN c1.DESCRIPCION IN (''PAGO TARJETA DE CREDITO'') THEN ''Pago de Tarjeta'' 
WHEN c1.DESCRIPCION IN (''A CUENTA BANCO RIPLEY'',''POR TRASPASO A CUENTA'')  THEN ''Pago LCA'' 
WHEN c1.DESCRIPCION IN (''COSTO DE MANTENCION MENSUAL CUENTA VISTA'') then ''Comision planes'' 
else ''OTROS CARGOS'' 
end 
END AS Descripcion_Cargo 

from  connection to BANCO( 
/*INICIO: QUERY DESDE OPERACIONES*/ 
select 
tmo_numcue as CUENTA, 
tmo_fechcon as FECHACON, 
tmo_fechor as FECHA, 
rub_desc as DESCRIPCION, 
tmo_val as MONTO, 
con_libre as Desc_negocio, 
tmo_codmod, 
tmo_tipotra, 
tmo_rubro, 
tmo_numtra, 
tmo_numcue, 
tmo_codusr, 
tmo_codusr, 
tmo_sec, 
tmo_codtra, 
(
SELECT cod_destra 
FROM tgen_codtrans 
WHERE cod_tra = tmo_codtra AND cod_mod = tmo_codmod 
) as gls_transac 
from tcap_tramon /*base de movimientos*/ 
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
and tmo_tipotra in (''D'',''C'') /*D=Cargo, C=Abono*/ 
and tmo_codpro = 4 
and tmo_codtip = 1 
and tmo_modo = ''N'' 
and tmo_val > 1 /*solo montos mayores a 1 peso (mov de prueba)*/ 

and tmo_fechcon >= to_date(''',&Fecha1_desde,''',''dd/mm/yyyy'') 
and tmo_fechcon <= to_date(''',&Fecha1_hasta,''',''dd/mm/yyyy'') 

/*FINAL: QUERY DESDE OPERACIONES*/ 
) as C1  
left join ( 

SELECT distinct cli_identifica ,vis_numcue 
from  connection to BANCO( 

select * 
from tcli_persona /*MAESTRA DE CLIENTES BANCO*/ 
,tcap_vista /*SALDOS CUENTAS VISTAS */ 
where cli_codigo=vis_codcli 
and vis_mod=4/*cuenta vista*/ 
and (VIS_PRO=4/*CV*/ or VIS_PRO=40/*LCA*/) 
and vis_tip=1  /*persona no juridica*/ 
AND (vis_status=''2'' or vis_status=''9'') /*solo aquellas con estado vigente o cerrado*/ 

) as conexion 

) as C2 
on (c1.tmo_numcue=c2.vis_numcue) 

;QUIT;
')
);
run;


/*llevar tabla a nivel de rut unico con principales variables*/

proc sql;

create table work.Movs_CtaVta2 as 
select 
CUENTA,

sum(case when PERIODO=&anomes1_T and Tipo_Movimiento='CARGO' then 1 else 0 end) as Nro_Cargos_T,
sum(case when PERIODO=&anomes1_T and Tipo_Movimiento='CARGO' then MONTO else 0 end) as Mto_Cargos_T,
sum(case when PERIODO=&anomes1_T and Tipo_Movimiento='ABONO' then 1 else 0 end) as Nro_Abonos_T,
sum(case when PERIODO=&anomes1_T and Tipo_Movimiento='ABONO' then MONTO else 0 end) as Mto_Abonos_T,
sum(case when PERIODO=&anomes1_T and SI_ABR=1 then MONTO else 0 end) as Mto_AR_T,

sum(case when PERIODO=&anomes1_Tmenos1 and Tipo_Movimiento='CARGO' then 1 else 0 end) as Nro_Cargos_Tmenos1,
sum(case when PERIODO=&anomes1_Tmenos1 and Tipo_Movimiento='CARGO' then MONTO else 0 end) as Mto_Cargos_Tmenos1,
sum(case when PERIODO=&anomes1_Tmenos1 and Tipo_Movimiento='ABONO' then 1 else 0 end) as Nro_Abonos_Tmenos1,
sum(case when PERIODO=&anomes1_Tmenos1 and Tipo_Movimiento='ABONO' then MONTO else 0 end) as Mto_Abonos_Tmenos1,
sum(case when PERIODO=&anomes1_Tmenos1 and SI_ABR=1 then MONTO else 0 end) as Mto_AR_Tmenos1,

sum(case when PERIODO=&anomes1_Tmenos2 and Tipo_Movimiento='CARGO' then 1 else 0 end) as Nro_Cargos_Tmenos2,
sum(case when PERIODO=&anomes1_Tmenos2 and Tipo_Movimiento='CARGO' then MONTO else 0 end) as Mto_Cargos_Tmenos2,
sum(case when PERIODO=&anomes1_Tmenos2 and Tipo_Movimiento='ABONO' then 1 else 0 end) as Nro_Abonos_Tmenos2,
sum(case when PERIODO=&anomes1_Tmenos2 and Tipo_Movimiento='ABONO' then MONTO else 0 end) as Mto_Abonos_Tmenos2,
sum(case when PERIODO=&anomes1_Tmenos2 and SI_ABR=1 then MONTO else 0 end) as Mto_AR_Tmenos2 

from work.Movs_CtaVta 
group by 
CUENTA 

;quit;



%put--------------------------------------------------------------------------------------------------;
%put [01.3] Sacar Saldos de cuenta Vista (ultimos 3 meses);
%put--------------------------------------------------------------------------------------------------;


/*Sacar Base de Saldos*/

DATA _NULL_;
Call execute(
cat('
proc sql; 

&mz_connect_BANCO; 
create table work.Saldos_CtaVta as 
SELECT 
INPUT((SUBSTR(c2.cli_identifica,1,(LENGTH(c2.cli_identifica)-1))),BEST.) AS RUT, 
input(SUBSTR(put(datepart(c1.acp_fecha),yymmddn8.),1,8),best.) as CodFecha, 
C1.* 
from  connection to BANCO( 
/*INICIO: QUERY DESDE OPERACIONES*/ 
select 
ACP_FECHA, 
ACP_NUMCUE, 
sum(acp_salefe + acp_sal12h + acp_sal24h + acp_sal48h) as Saldo 
from tcap_acrpas 
where acp_pro = 4 and acp_tip = 1 
and ( 
acp_fecha=to_date(''',&Fecha2_T,''',''dd/mm/yyyy'') or 
acp_fecha=to_date(''',&Fecha2_Tmenos1,''',''dd/mm/yyyy'') or 
acp_fecha=to_date(''',&Fecha2_Tmenos2,''',''dd/mm/yyyy'') 
)
group by 
ACP_FECHA, 
ACP_NUMCUE 
/*FINAL: QUERY DESDE OPERACIONES*/ 
) as C1 
left join ( 

SELECT distinct cli_identifica ,vis_numcue 
from  connection to BANCO( 

select * 
from tcli_persona /*MAESTRA DE CLIENTES BANCO*/ 
,tcap_vista /*SALDOS CUENTAS VISTAS */ 
where cli_codigo=vis_codcli 
and vis_mod=4/*cuenta vista*/ 
and (VIS_PRO=4/*CV*/ or VIS_PRO=40/*LCA*/) 
and vis_tip=1  /*persona no juridica*/ 
AND (vis_status=''2'' or vis_status=''9'') /*solo aquellas con estado vigente o cerrado*/ 

) as conexion 

) as C2 
on (c1.ACP_NUMCUE=c2.vis_numcue) 

;QUIT;
')
);
run;


/*Llevar info a Nivel de rut unico*/ 


proc sql;

create table work.Saldos_CtaVta2 as 
select 
ACP_NUMCUE as Cuenta,

sum(case when CodFecha=&anomesdia2_T then Saldo else 0 end) as Saldo_T,
sum(case when CodFecha=&anomesdia2_Tmenos1 then Saldo else 0 end) as Saldo_Tmenos1,
sum(case when CodFecha=&anomesdia2_Tmenos2 then Saldo else 0 end) as Saldo_Tmenos2 

from work.Saldos_CtaVta  
group by 
ACP_NUMCUE 

;quit;


/*Borrar Tabla de Paso*/

proc sql;

drop table work.Saldos_CtaVta

;quit;


%put--------------------------------------------------------------------------------------------------;
%put [01.4] Consolidar todo en una sola tabla;
%put--------------------------------------------------------------------------------------------------;



proc sql;

create table work.Stock_CtaVta as  
select 
a.*,
d.Duplicidad_rut,

coalesce(b.Nro_Cargos_T,0) as Nro_Cargos_T,
coalesce(b.Mto_Cargos_T,0) as Mto_Cargos_T,
coalesce(b.Nro_Abonos_T,0) as Nro_Abonos_T,
coalesce(b.Mto_Abonos_T,0) as Mto_Abonos_T,
coalesce(b.Mto_AR_T,0) as Mto_AR_T,
coalesce(c.Saldo_T,0) as Saldo_T, 

coalesce(b.Nro_Cargos_Tmenos1,0) as Nro_Cargos_Tmenos1,
coalesce(b.Mto_Cargos_Tmenos1,0) as Mto_Cargos_Tmenos1,
coalesce(b.Nro_Abonos_Tmenos1,0) as Nro_Abonos_Tmenos1,
coalesce(b.Mto_Abonos_Tmenos1,0) as Mto_Abonos_Tmenos1,
coalesce(b.Mto_AR_Tmenos1,0) as Mto_AR_Tmenos1,
coalesce(c.Saldo_Tmenos1,0) as Saldo_Tmenos1,

coalesce(b.Nro_Cargos_Tmenos2,0) as Nro_Cargos_Tmenos2,
coalesce(b.Mto_Cargos_Tmenos2,0) as Mto_Cargos_Tmenos2,
coalesce(b.Nro_Abonos_Tmenos2,0) as Nro_Abonos_Tmenos2,
coalesce(b.Mto_Abonos_Tmenos2,0) as Mto_Abonos_Tmenos2,
coalesce(b.Mto_AR_Tmenos2,0) as Mto_AR_Tmenos2,
coalesce(c.Saldo_Tmenos2,0) as Saldo_Tmenos2 

from work.Stock_CtaVta as a 
left join work.Movs_CtaVta2 as b 
on (a.cuenta=b.cuenta) 
left join work.Saldos_CtaVta2 as c 
on (a.cuenta=c.cuenta) 
left join (
select rut,count(*) as Duplicidad_rut 
from work.Stock_CtaVta 
group by rut
) as d 
on (a.rut=d.rut)

;quit;


/*eliminar tablas de paso*/


proc sql;

drop table work.Movs_CtaVta2

;quit; 


proc sql;

drop table work.Saldos_CtaVta2

;quit;



%put--------------------------------------------------------------------------------------------------;
%put [01.5] Pegar info de segmento comercial;
%put--------------------------------------------------------------------------------------------------;

/*determinar maximos periodos de tablas de segmentos*/


/*Crear Tabla*/


DATA _NULL_;
Call execute(
cat('
proc sql; 

CREATE TABLE work.Stock_CtaVta AS 
SELECT 
a.*,
coalesce(b.SEGMENTO,''S.I.'') as segmento_comercial 
from work.Stock_CtaVta as a 
left join PUBLICIN.SEGMENTO_COMERCIAL as b 
on (a.rut=b.rut) 

;quit; 
')
);
run;



%put--------------------------------------------------------------------------------------------------;

%put [01.6] Pegar info de segmento real;
%put--------------------------------------------------------------------------------------------------;



/*determinar maximos periodos de tablas de segmentos*/

PROC SQL;   

select max(anomes) as Max_anomes_SegReal
into :Max_anomes_SegReal
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'PUBLICIN.SEGMENTOS_RPTOS_%' 
and length(Nombre_Tabla)=length('PUBLICIN.SEGMENTOS_RPTOS_201807')
) as x

;QUIT;


/*Crear Tabla*/


DATA _NULL_;
Call execute(
cat('
proc sql; 

CREATE TABLE work.Stock_CtaVta AS 
select 
a.*,
coalesce(b.SEGMENTO,''S.I.'') as segmento_real 
from work.Stock_CtaVta as a 
left join PUBLICIN.SEGMENTOS_RPTOS_',&Max_anomes_SegReal,' as b 
on (a.rut=b.rut) 

;quit; 
')
);
run;


%put--------------------------------------------------------------------------------------------------;
%put [01.7] Pegar saldo de puntos disponibles a la fecha;
%put--------------------------------------------------------------------------------------------------;



/*Sacar Base*/ 

LIBNAME PSFC1 ORACLE PATH='PSFC1' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD= 'amarinaoc2017';

PROC SQL;

CREATE TABLE work.PuntosDisp AS 
SELECT 
INPUT(CODCUENT,BEST.) AS RUT,
max(CANTPUNT) as Puntos_Disponibles
FROM PSFC1.T7542700
WHERE TIPOPUNT = '01' 
group by 
INPUT(CODCUENT,BEST.)

;QUIT;


/*Pegar data*/

PROC SQL;

CREATE TABLE work.Stock_CtaVta AS 
SELECT 
a.*,
coalesce(b.Puntos_Disponibles,0) as Puntos_Disponibles 
FROM work.Stock_CtaVta as a 
left join work.PuntosDisp as b 
on (a.rut=b.rut)

;QUIT;



/*Borrar tabla de paso*/

PROC SQL;

drop TABLE work.PuntosDisp 

;QUIT;



%put--------------------------------------------------------------------------------------------------;
%put [01.8] Pegar puntos bonificados dentro del año;
%put--------------------------------------------------------------------------------------------------;



/*Definir ventana acumulada*/


PROC SQL outobs=1;   

select 10000*floor(input(SB_Ahora('AAAAMM'),best.)/100)+0101 as Fecha_Bonif_i
into :Fecha_Bonif_i
from sbarrera.SB_Status_Tablas_IN

;QUIT;


PROC SQL outobs=1;   

select input(SB_Ahora('AAAAMMDD'),best.) as Fecha_Bonif_f
into :Fecha_Bonif_f
from sbarrera.SB_Status_Tablas_IN

;QUIT;


/*Crear Rutero*/


LIBNAME PSFC1 ORACLE PATH='PSFC1' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD= 'amarinaoc2017';

PROC SQL;

CREATE TABLE work.Puntos_Bonificados AS 
SELECT 
RUT, 
max(Fecha_Puntos) as Max_Fecha_Puntos,
SUM(Puntos) FORMAT=14. AS Puntos_Bonificados
FROM (
select 
INPUT(LEFT(CODCUENT),BEST.) as RUT,
FECTRX as Fecha_Puntos,
PUNOBTEN as Puntos
from PSFC1.T7542350 
where INDICADOR NOT= 5  /* CADUCIDAD*/
and CONCONCE IN (
'00000105', /*TDA TR*/ 
'00000106', /*TDA TR*/ 
'00000107', /*INTERNET TR*/ 
'00000109', /*SPOS*/
'00000110', /*TDA EFEC*/
'00000111', /*TDA CHEQUE*/
'00000114', /*SAV*/
'00000115', /*AV*/
'00000116', /*RECARGA SPOS*/
'00000123', /*TDA DEBITO*/
'00000124', /*TDA TAR BANCO*/
'00000125', /*RECARGA TDA*/
'00000131', /*AV ATM*/
'00000148', /*SEG*/ 
'00000305', /*TDA ANULACION*/ 
'00000306', /*TDA ANULACION*/ 
'00000307', /*ANULACION INT*/ 
'00000309', /*ANULA SPOS*/ 
'00000310', /*ANULA EFECT*/ 
'00000314', /*ANULA SAV*/ 
'00000315', /*ANULA AV*/ 
'00000316', /*ANULA RECARGA SPOS*/ 
'00000324'  /*ANULA TDA TARJETA BCO*/
)
AND FECTRX>=&Fecha_Bonif_i
and FECTRX<=&Fecha_Bonif_f
) as X 
GROUP BY 
RUT

;QUIT;


/*Pegar Info*/



proc sql; 

CREATE TABLE WORK.Stock_CtaVta AS 
SELECT 
a.*, 
b.Puntos_Bonificados 
FROM WORK.Stock_CtaVta as a 
left join work.Puntos_Bonificados as b 
on (a.rut=b.rut) 

;quit; 


/*Borrar tabla de paso*/

proc sql;

drop table work.Puntos_Bonificados

;quit;



%put--------------------------------------------------------------------------------------------------;
%put [01.9] Guardar Resultados en tabla entregable;
%put--------------------------------------------------------------------------------------------------;



DATA _NULL_;
Call execute(
cat('
proc sql;

create table ',&Libreria,'.CtaVta1_Stock as 
SELECT 
''',&Fecha_Proceso,''' as Fecha_Proceso, 
',&anomes1_T,' as Periodo_Movs, 
* 
from work.Stock_CtaVta  

;quit;
')
);
run;


/*eliminar tablas de paso*/


proc sql;

drop table work.Stock_CtaVta

;quit; 


%put==================================================================================================;
%put [02] Detalle de Movimientos de Cuenta Vista (ultimos 33 dias);
%put==================================================================================================;


DATA _NULL_;
Call execute(
cat('
proc sql;

create table ',&Libreria,'.CtaVta2_Movs as 
SELECT 
''',&Fecha_Proceso,''' as Fecha_Proceso, 
* 
from work.Movs_CtaVta 
where CodFecha>=',&anomesdia2_i,' 

;quit;
')
);
run;



/*eliminar tablas de paso*/


proc sql;

drop table work.Movs_CtaVta

;quit; 


%put==================================================================================================;
%put [03] Evolutivo de Saldos cuenta vista (ultimos 12 meses);
%put==================================================================================================;



/*Sacar Base de Saldos*/

DATA _NULL_;
Call execute(
cat('
proc sql; 

&mz_connect_BANCO; 
create table work.Saldos_CtaVta3 as 

select 
floor(CodFecha/100) as Periodo, 
CodFecha, 
case 
when Saldo<0 then ''00. <0'' 
when Saldo=0 then ''01. 0'' 
when Saldo=1 then ''02. 1'' 
when Saldo<=10000 then ''03. (1-10M]''  
when Saldo<=50000 then ''04. (10M-50M]''  
when Saldo<=100000 then ''05. (50M-100M]''  
when Saldo<=200000 then ''06. (100M-200M]''  
when Saldo<=300000 then ''07. (200M-300M]''  
when Saldo<=500000 then ''08. (300M-500M]''  
when Saldo<=750000 then ''09. (500M-750M]''  
when Saldo<=1000000 then ''10. (750M-1MM]''  
when Saldo<=1500000 then ''11. (1MM-1,5MM]''  
else ''12. >1,5MM'' 
end as Tramo_Saldo, 
sum(Saldo) as SUM_Saldo,
count(*) as Nro_Cuentas 
from ( 

SELECT 
input(SUBSTR(put(datepart(c1.acp_fecha),yymmddn8.),1,8),best.) as CodFecha, 
C1.* 
from  connection to BANCO( 
/*INICIO: QUERY DESDE OPERACIONES*/ 
select 
ACP_FECHA, 
ACP_NUMCUE, 
sum(acp_salefe + acp_sal12h + acp_sal24h + acp_sal48h) as Saldo 
from tcap_acrpas 
where acp_pro = 4 and acp_tip = 1 
and acp_fecha>=to_date(''',&Fecha3_i,''',''dd/mm/yyyy'')  
and acp_fecha<=to_date(''',&Fecha3_f,''',''dd/mm/yyyy'') 
group by 
ACP_FECHA, 
ACP_NUMCUE 
/*FINAL: QUERY DESDE OPERACIONES*/ 
) as C1 

) as X 
group by 
calculated Periodo, 
CodFecha, 
calculated Tramo_Saldo 

;QUIT;
')
);
run;


/*Pegar Marca de Ultimo Dia del mes*/

proc sql; 

create table work.Saldos_CtaVta3 as 
select 
a.*,
case when b.Periodo is not null and b.Max_CodFecha is not null then 1 else 0 end as SI_Ultima_Fecha 
from work.Saldos_CtaVta3 as a 
left join (
select 
Periodo,
max(CodFecha) as Max_CodFecha 
from work.Saldos_CtaVta3 
group by 
Periodo 
) as b 
on (a.Periodo=b.Periodo and a.CodFecha=b.Max_CodFecha)

;quit;


/*Guardar Entregable*/ 


DATA _NULL_;
Call execute(
cat('
proc sql;

create table ',&Libreria,'.CtaVta3_Saldos as 
SELECT 
''',&Fecha_Proceso,''' as Fecha_Proceso, 
* 
from work.Saldos_CtaVta3 

;quit;
')
);
run;



/*Eliminar tabla de paso auxiliar*/ 


proc sql;

drop table work.Saldos_CtaVta3

;quit;

* Inicio del código EG generado (no editar esta línea);
;*';*";*/;quit;
%STPEND;

* Fin del código EG generado (no editar esta línea);

