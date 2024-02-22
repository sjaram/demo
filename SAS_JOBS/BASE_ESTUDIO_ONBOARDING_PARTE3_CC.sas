/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================    BASE_ESTUDIO_ONBOARDING_PARTE3_CC===============================*/
/* CONTROL DE VERSIONES
/* 2023-07-04 -- v05	-- Sergio J.	--  Se añade exportación a AWS.
/* 2022-08-24 -- v04	-- David V.		--  Corrección a librería en el export al ftp
/* 2022-08-19 -- v03	-- David V.		--  Corrección, faltaba un punto en la variable librería
/* 2022-08-19 -- v02	-- David V.		--  Se agregan comentarios, envío al ftp para calidad y correo de notificación.
/* 2022-08-18 -- v01	-- Karina M.	--  Versión Original

/* INFORMACIÓN:
Parte 3 del flujo anterior

/* VARIABLE TIEMPO - INICIO */
%let tiempo_inicio= %sysfunc(datetime());

options validvarname=any;

/*==================================================================================================*/
/*==============================    BASE_ESTUDIO_ONBOARDING_PARTE2	 ===============================*/

%let libreria=RESULT;
%let n=0;

DATA _null_;
periodo_actual = input(put(intnx('month',today(),-&n.,'begin'),yymmn6. ),$10.) ;
fecha_hoy = input(put(intnx('day',today(),&n.,'same'),yymmddn8. ),$10.);
periodo_1 = input(put(intnx('month',today(),-&n.-1,'begin'),yymmn6. ),$10.) ;
periodo_2 = input(put(intnx('month',today(),-&n.-2,'same'),yymmn6. ),$10.) ;
periodo_3 = input(put(intnx('month',today(),-&n.-3,'same'),yymmn6. ),$10.) ;
periodo_4 = input(put(intnx('month',today(),-&n.-4,'same'),yymmn6. ),$10.) ;
periodo_5 = input(put(intnx('month',today(),-&n.-5,'same'),yymmn6. ),$10.) ;
periodo_6 = input(put(intnx('month',today(),-&n.-6,'same'),yymmn6. ),$10.) ;



ini_mes = input(put(intnx('month',today(),-&n.,'begin'),date9. ),$10.) ;
fin_mes = input(put(intnx('month',today(),-&n.,'end'),date9. ),$10.) ;



Call symput("periodo_actual", periodo_actual);
Call symput("fecha_hoy", fecha_hoy);
Call symput("periodo_1", periodo_1);
Call symput("periodo_2", periodo_2);
Call symput("periodo_3", periodo_3);
Call symput("periodo_4", periodo_4);
Call symput("periodo_5", periodo_5);
Call symput("periodo_6", periodo_6);
Call symput("dated_ant", dated_ant);
Call symput("ini_mes", ini_mes);
Call symput("fin_mes", fin_mes);
RUN;



%put &periodo_actual;
%put &fecha_hoy;
%put &periodo_1;
%put &periodo_2;
%put &periodo_3;
%put &periodo_4;
%put &periodo_5;
%put &periodo_6;
%put &ini_mes;
%put &fin_mes;

DATA _NULL_;
INI_NUM=put(intnx('month',today(),-&n.,'begin'), yymmddn8.);
FIN_NUM=put(intnx('month',today(),-&n.,'end'), yymmddn8.);
call symput("INI_NUM",INI_NUM);
call symput("FIN_NUM",FIN_NUM);
run;

%put &INI_NUM;
%put &FIN_NUM;
/*::::::::::::::::::::::::::*/
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




%let path_ora      = '(DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SID = ripleyc)))'; 
%let user_ora      = 'RIPLEYC'; 
%let pass_ora      = 'ri99pley';
%let conexion_ora  = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 


PROC SQL;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );

create table &libreria..MOV_CUENTA_&periodo_actual  as
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
/*--  AAG    Los Giros Nac. e InterN. esta abajo */
/*---  WHEN DESCRIPCION IN ('GIRO CAJERO AUTOMATICO') THEN 'Giros ATM'    
/*-- AAG      */
when DESCRIPCION IN ('GIRO ATM INTERNACIONAL CTA CTE') then 'Giros internacional CTA CTE'
when DESCRIPCION IN ('GIRO ATM NACIONAL CTA CTE') then 'Giros ATM CTA CTE'
WHEN DESCRIPCION IN ('GIRO POR CAJA') THEN 'Giros Caja'
/*--  AAG  el Giro Int esta arriba  */
/*-- WHEN DESCRIPCION IN ('GIRO INTERNACIONAL') THEN 'Giro Internacional'
/*-- AAG */ 
WHEN DESCRIPCION IN ('TRANSFERENCIA A OTROS BANCOS') THEN 'TEF emitidas Otros Bancos'
WHEN DESCRIPCION IN ('PAGO TARJETA DE CREDITO') THEN 'Pago de Tarjeta' 
WHEN DESCRIPCION IN ('A CUENTA BANCO RIPLEY','POR TRASPASO A CUENTA')  THEN 'Pago LCA'
/*--   WHEN DESCRIPCION IN ('COSTO DE MANTENCION MENSUAL CUENTA VISTA') then 'Comision planes'
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

and tmo_fechcon >= to_date(%str(%')&ini_char.%str(%'),'dd/mm/yyyy')
and tmo_fechcon <= to_date(%str(%')&fin_char.%str(%'),'dd/mm/yyyy')
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

/*Exportación a AWS*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_ppff_mov_cuenta,raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_ppff_mov_cuenta,result.mov_cuenta_&periodo_actual.,raw,sasdata,0)

%macro concrecion_3M_fecha_max_cc(N,libreria);

DATA _null_;
periodo_actual = input(put(intnx('month',today(),-&n.,'begin'),yymmn6. ),$10.) ;
periodo_1 = input(put(intnx('month',today(),-&n.+1,'begin'),yymmn6. ),$10.) ;
periodo_2 = input(put(intnx('month',today(),-&n.+2,'same'),yymmn6. ),$10.) ;
periodo_3 = input(put(intnx('month',today(),-&n.+3,'same'),yymmn6. ),$10.) ;
periodo_4 = input(put(intnx('month',today(),-&n.+4,'same'),yymmn6. ),$10.) ;
periodo_5 = input(put(intnx('month',today(),-&n.+5,'same'),yymmn6. ),$10.) ;
periodo_6 = input(put(intnx('month',today(),-&n.+6,'same'),yymmn6. ),$10.) ;



ini_mes = input(put(intnx('month',today(),-&n.,'begin'),date9. ),$10.) ;
fin_mes = input(put(intnx('month',today(),-&n.,'end'),date9. ),$10.) ;



Call symput("periodo_actual", periodo_actual);
Call symput("periodo_1", periodo_1);
Call symput("periodo_2", periodo_2);
Call symput("periodo_3", periodo_3);
Call symput("periodo_4", periodo_4);
Call symput("periodo_5", periodo_5);
Call symput("periodo_6", periodo_6);
Call symput("dated_ant", dated_ant);
Call symput("ini_mes", ini_mes);
Call symput("fin_mes", fin_mes);
RUN;




proc sql;
create table captados as
select
/*a.ind,*/
rut,
PRODUCTO,
FECHA	,
fecha_numero,
dia_30,
dia_60,
dia_90,
CODENT,	CENTALTA,	CUENTA
from result.ONBOARDING
where
fecha between "&ini_mes."d and "&fin_mes."d
AND producto = ('CUENTA CORRIENTE')
;QUIT;




%macro recopilar_USOS(periodo,i);

/*SPOS TC*/
%if (%sysfunc(exist(publicin.spos_aut_&periodo.))) %then %do;
PROC SQL ;
create table cc&i as 
SELECT 
a.rut,
a.CODFECHA AS fecha,
/*a.hora,*/
/*a.codact,*/
a.MONTO AS venta_tarjeta
FROM &libreria..MOV_CUENTA_&periodo. as a 
inner join captados as b
on(a.rut=b.rut)
WHERE A.TIPO_MOVIMIENTO = 'ABONO'
;quit;
%end;
%else %do;
PROC SQL ;
create table cc&i 
(rut num,
fecha num,
/*hora char(10),*/
/*codact num,*/
venta_tarjeta num/*,
Nombre_Comercio char(10)*/
)
;quit;
%end;

%mend recopilar_USOS;


%recopilar_USOS(&periodo_actual.,1);
%recopilar_USOS(&periodo_1.,2);
%recopilar_USOS(&periodo_2.,3);
%recopilar_USOS(&periodo_3.,4);




proc sql;
create table CC_fin as 
select *
from CC1
outer union corr 
select *
from CC2
outer union corr 
select *
from CC3
outer union corr 
select *
from CC4
;QUIT;


PROC SQL;
   CREATE TABLE WORK.CC_FIN2 AS 
   SELECT t1.RUT, 
          /* COUNT_of_RUT */
            (COUNT(t1.RUT)) AS trx, 
          /* MIN_of_Fecha */
            (MIN(t1.Fecha)) AS Fecha, 
          /* MAX_of_Fecha */
            (MAX(t1.Fecha)) AS Fecha_max
      FROM WORK.CC_FIN t1
      GROUP BY t1.RUT;
QUIT;


/*53746*/
proc sql;
create table captados2 as 
select distinct 
a.*,
case 
when a.producto in ('CUENTA CORRIENTE')
and b.rut is not null 
and (b.fecha between a.fecha_numero	and a.dia_30 ) then 1 
else 0 end  as concreta_30_CC,

case 
when a.producto in ('CUENTA CORRIENTE')
and b.rut is not null 
and (b.fecha between a.fecha_numero	and a.dia_60 ) then 1 
else 0 end  as concreta_60_CC,

case 
when a.producto in ('CUENTA CORRIENTE')
and b.rut is not null 
and (b.fecha between a.fecha_numero	and a.dia_90 ) then 1 
else 0 end  as concreta_90_CC,

case 
when b.rut is not null and a.producto in ('CUENTA CORRIENTE')
and b.Fecha between a.fecha_numero	and a.dia_90 then b.Fecha
else 0 end
as fecha_concreta_CC,

case 
when b.rut is not null and a.producto in ('CUENTA CORRIENTE')
/*and b.Fecha_max between a.fecha_numero	and a.dia_90*/ then b.Fecha_max
else 0 end
as fecha_concreta_cc_max,


case 
when a.producto in ('CUENTA CORRIENTE')
and b.rut is not null 
 then b.trx  
else 0 end   as n_Trx,

case 
when a.producto in ('CUENTA CORRIENTE')
and c.rut is not null 
and c.fecha between a.dia_30	and a.dia_60 
 then 1 
else 0 end  as concreta_31_60_T



from captados as a 
left join CC_FIN2 as b on(a.rut=b.rut)
left join CC_FIN as c on(a.rut=c.rut)
order by
/*a.ind,*/
a.rut,
a.PRODUCTO,
a.FECHA	,
a.fecha_numero,
a.dia_30,
a.dia_60,
a.dia_90,
a.CODENT,	a.CENTALTA,	a.CUENTA
;QUIT;



/*53746*/
proc sql;
create table onboarding_3M_v2_&periodo_actual. as
select t1.rut, 
          t1.PRODUCTO, 
          t1.FECHA, 
          t1.fecha_numero, 
          t1.dia_30, 
          t1.dia_60, 
          t1.dia_90, 
          t1.CODENT, 
          t1.CENTALTA, 
          t1.CUENTA, 
          t1.concreta_30_CC, 
          t1.concreta_60_CC, 
          t1.concreta_90_CC, 
          t1.fecha_concreta_CC, 
          t1.fecha_concreta_cc_max, 
          t1.n_Trx, 
          /* MAX_of_concreta_31_60_T */
            (MAX(t1.concreta_31_60_T)) AS MAX_of_concreta_31_60_T
      FROM WORK.CAPTADOS2 t1
      GROUP BY t1.rut,
               t1.PRODUCTO,
               t1.FECHA,
               t1.fecha_numero,
               t1.dia_30,
               t1.dia_60,
               t1.dia_90,
               t1.CODENT,
               t1.CENTALTA,
               t1.CUENTA,
               t1.concreta_30_CC,
               t1.concreta_60_CC,
               t1.concreta_90_CC,
               t1.fecha_concreta_CC,
               t1.fecha_concreta_cc_max,
               t1.n_Trx
;QUIT;


%mend concrecion_3M_fecha_max_cc;


%concrecion_3M_fecha_max_cc(0,&libreria.);
%concrecion_3M_fecha_max_cc(1,&libreria.);
%concrecion_3M_fecha_max_cc(2,&libreria.);
%concrecion_3M_fecha_max_cc(3,&libreria.);


proc sql;
create table Unir_bases_captaciones_NVO_CAMP as
select *, &fecha_hoy as FECHA_HOY_NUMERO,
mdy(mod(int(fecha_concreta_cc_max/100),100),mod(fecha_concreta_cc_max,100),int(fecha_concreta_cc_max/10000)) format=date9. as concreta_MAX_FECHA_SAS,
mdy(mod(int(&fecha_hoy/100),100),mod(&fecha_hoy,100),int(&fecha_hoy/10000)) format=date9. as FECHA_hoy_SAS,

case when fecha_concreta_cc_max>0 then intck("day",calculated concreta_MAX_FECHA_SAS,calculated FECHA_hoy_SAS) else 999 end as dias_ultima_Compra

FROM ( select *
from ONBOARDING_3M_v2_&periodo_actual
union  select *
from ONBOARDING_3M_v2_&periodo_1
union  select *
from ONBOARDING_3M_v2_&periodo_2
union  select *
from ONBOARDING_3M_v2_&periodo_3) 
;quit;



/*175669*/
/*SE AGREGAN NUEVAS VARIABLES CUENTA CORRIENTE*/
proc sql;
create table &libreria..BASE_ONBOARDING_ESTUDIO_CC as
select distinct t1.*,

          t2.concreta_30_CC, 
          t2.concreta_60_CC, 
          t2.concreta_90_CC, 
          t2.fecha_concreta_CC, 
          t2.fecha_concreta_cc_max, 
          t2.n_Trx AS n_Trx_CC , 
          t2.MAX_of_concreta_31_60_T, 
          t2.FECHA_HOY_NUMERO AS FECHA_HOY_NUMERO_CC, 
          t2.concreta_MAX_FECHA_SAS AS concreta_MAX_FECHA_SAS_CC, 
/*          t1.FECHA_hoy_SAS, */
          t2.dias_ultima_Compra AS dias_ultima_Compra_CC

from   RESULT.ONBOARDING  t1 /* proceso pedro*/
INNER join Unir_bases_captaciones_NVO_CAMP t2 on /* proceso + variables bases laura CC*/
 (t1.rut = t2.rut AND t1.PRODUCTO = t2.PRODUCTO AND t1.FECHA = t2.FECHA )
ORDER BY T1.fecha_numero
;quit;



/* GENERACION DE LAS BASES DE SALIDA PARA COMPARTIR EN FTP AL AREA DE EXPERIENCIA */
/*
Contratación online, clientes que hayan contratado la cuenta corriente de manera online. ok
1-Uso 30 días, Clientes que hayan realizado un abono en su cuenta en los primeros 30 días desde la contratación ok
2-Uso 90 días, Clientes que hayan mantenido un saldo promedio diario en los últimos 90 días igual al promedio del stock de la base
3-Dejó de usar 30 días, antigüedad 90 días, clientes que hayan realizado un  abono en su cuenta en los primeros 30 días ok, y los próximos 60 días no realizaron.
4-Dejó de usar a los 60 días, antigüedad 90 días, clientes que hayan realizado abonos en los primeros 30 y 60 días, y en los últimos 30 días no realizó abonos.
5-No uso 90 días, clientes que no han realizado abonos en sus cuentas en los primero 90 días.

*/



%let n=0;

DATA _null_;
periodo_2 = input(put(intnx('month',today(),-&n.-2,'same'),yymmn6. ),$10.) ;
periodo_1 = input(put(intnx('month',today(),-&n.-1,'begin'),yymmn6. ),$10.) ;
Call symput("periodo_2", periodo_2);
Call symput("periodo_1", periodo_1);
RUN;
%put &periodo_2;
%put &periodo_1;


/*1- Uso 30 días, Clientes que hayan realizado un abono en su cuenta en los primeros 30 días desde la contratación*/ /*OK*/
/*719*/
proc sql;
create table &libreria..ONBOARDING_USO_CC_30D as
select t1.*, case when t2.rut not is null then 1 else 0 end as Marca_Funcionario/*,
case when T1.FECHA>0 then intck("day",T1.FECHA, T1.FECHA_hoy_SAS) else 999 end as dias_DESDE_CAPTACION*/
from &libreria..BASE_ONBOARDING_ESTUDIO_CC t1
 left join  NLAGOSG.DOTACION_&periodo_2 t2 on t1.rut=t2.rut
WHERE T1.rut not in (select rut from publicin.LNEGRO_CAR)
  and T1.concreta_30_CC =1 /* tiene concrecion (abono  dentro de los primeros 30 dias */
and T1.FECHA_HOY_NUMERO_CC <=T1.dia_30 /* <= 30 dias DE ANTIGUEDAD */
ORDER BY T1.fecha_numero
;quit;



/*3- Dejó de usar 30 días, antigüedad 90 días, clientes que hayan realizado un  abono en su cuenta en los primeros 30 días ok,
y los próximos 60 días no realizaron*/ 
/*489*/
proc sql;
create table &libreria..ONBOARDING_DEJO_DE_USAR_CC_30D_ as
select t1.*, case when t2.rut not is null then 1 else 0 end as Marca_Funcionario/*,
case when T1.FECHA>0 then intck("day",T1.FECHA, T1.FECHA_hoy_SAS) else 999 end as dias_DESDE_CAPTACION*/
from &libreria..BASE_ONBOARDING_ESTUDIO_CC t1
left join  NLAGOSG.DOTACION_&periodo_2 t2 on t1.rut=t2.rut
WHERE T1.rut not in (select rut from publicin.LNEGRO_CAR)
and T1.concreta_30_CC =1 /* tiene concrecion (abono)  dentro de los primeros 30 dias */
AND T1.fecha_concreta_cc_max<=T1.dia_30  /* fecha de ultima concrecion (abono) menor o igual a 30 dias */
and T1.FECHA_HOY_NUMERO_CC >=T1.dia_90 /* >= A  90 dias o mas DE ANTIGUEDAD*/
and T1.MAX_of_concreta_31_60_T =0 /*marca si tiene concrecion entre 31 a 60 de su captacion*/
ORDER BY T1.fecha_numero
;quit;


/*4- Dejó de usar a los 60 días, antigüedad 90 días, clientes que hayan realizado abonos en los primeros 30 y 60 días, 
y en los últimos 30 días no realizó abonos.*/
/*260 */
proc sql;
create table &libreria..ONBOARDING_DEJO_DE_USAR_CC_60D as
select t1.*,case when t2.rut not is null then 1 else 0 end as Marca_Funcionario/*,
case when T1.FECHA>0 then intck("day",T1.FECHA, T1.FECHA_hoy_SAS) else 999 end as dias_DESDE_CAPTACION*/
from &libreria..BASE_ONBOARDING_ESTUDIO_CC t1
left join  NLAGOSG.DOTACION_&periodo_2 t2 on t1.rut=t2.rut
WHERE T1.rut not in (select rut from publicin.LNEGRO_CAR)
and concreta_30_CC =1 /* tiene concrecion (abono)  dentro de los primeros 30 dias */
AND fecha_concreta_cc_max<=dia_60 /* fecha de ultima concrecion (abono) menor o igual a 60 dias */
and FECHA_HOY_NUMERO_CC >=dia_90 /* antiguedad 90 dias o mas */
and MAX_of_concreta_31_60_T =1 /*marca si tiene concrecion entre 31 a 60 de su captacion*/
ORDER BY T1.fecha_numero
;quit;



/*6- No uso 30 días, antigüedad 30 días y no han realizado abonos en su cuenta*/
/* 12120*/

proc sql;
create table &libreria..ONBOARDING_SIN_USO_CC_30D as
select t1.*,case when t2.rut not is null then 1 else 0 end as Marca_Funcionario/*,
case when T1.FECHA>0 then intck("day",T1.FECHA, T1.FECHA_hoy_SAS) else 999 end as dias_DESDE_CAPTACION*/
from &libreria..BASE_ONBOARDING_ESTUDIO_CC t1
left join  NLAGOSG.DOTACION_&periodo_2 t2 on t1.rut=t2.rut
WHERE T1.rut not in (select rut from publicin.LNEGRO_CAR)
and concreta_30_CC =0
and FECHA_HOY_NUMERO_CC >=dia_30/* antiguedad 30 dias o mas */
and FECHA_HOY_NUMERO_CC <dia_90/* antiguedad 90 dias o mas */
ORDER BY T1.fecha_numero
;quit;

/*5- No uso 90 días, clientes que no han realizado abonos en sus cuentas en los primero 90 días.*/
/* 4636*/
proc sql;
create table &libreria..ONBOARDING_SIN_USO_CC_90D as
select t1.*,case when t2.rut not is null then 1 else 0 end as Marca_Funcionario
from &libreria..BASE_ONBOARDING_ESTUDIO_CC t1
left join  NLAGOSG.DOTACION_&periodo_2 t2 on t1.rut=t2.rut
WHERE T1.rut not in (select rut from publicin.LNEGRO_CAR)
and concreta_90_CC =0
and FECHA_HOY_NUMERO_CC >=dia_90/* antiguedad 90 dias o mas */
ORDER BY T1.fecha_numero
;quit;


/**********************************************************************************************/
/**********************************************************************************************/
/*********************************PARTE PARA EXTRAER SALDOS************************************/
/**********************************************************************************************/
/**********************************************************************************************/


%let n=1; 
DATA _null_;
ini_char = put(intnx('month',today(),-&N.,'begin'),ddmmyy10.);
fin_char = put(intnx('month',today(),-&N.,'end'),ddmmyy10. );
call symput("INI_char",INI_char);
call symput("fin_char",fin_char);
run;
%put &INI_char;
%put &fin_char;

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
create table &libreria..Saldos_Cuenta_corriente2 as
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



PROC SQL;
   CREATE TABLE WORK.saldo_prom_eop AS 
   SELECT  (AVG(t1.Ultimo_Saldo)) AS AVG_of_Ultimo_Saldo
      FROM &libreria..Saldos_Cuenta_corriente2 t1
      WHERE t1.rut NOT = . AND t1.Ultimo_Saldo > 0 and Nro_Dias_Saldo_mayor_1>0;
QUIT;

/* prom Cuentas con Saldo >$0 EOP y cuentas activas*/

PROC SQL;
   CREATE TABLE WORK.saldo_prom_cc_Activas AS 
   SELECT  (COUNT(t1.rut)) AS COUNT_of_rut, (AVG(t1.Ultimo_Saldo)) AS AVG_of_Ultimo_Saldo
      FROM &libreria..Saldos_Cuenta_corriente2 t1
      WHERE t1.rut NOT = . 
and t1.rut in (select rut from &libreria..MOV_CUENTA_&periodo_1);
QUIT;


/* prom Cuentas con Saldo >$0 EOP */
PROC SQL noprint;    
select AVG_of_Ultimo_Saldo as Ultimo_Saldo 
into :Ultimo_Saldo
from ( SELECT  (AVG(t1.Ultimo_Saldo)) AS AVG_of_Ultimo_Saldo
      FROM &libreria..Saldos_Cuenta_corriente2 t1
      WHERE t1.rut NOT = . AND t1.Ultimo_Saldo > 0 and Nro_Dias_Saldo_mayor_1>0
) as x 
;QUIT;

%let avg_saldo_eop=&Ultimo_Saldo;

%put &avg_saldo_eop;



/* prom Cuentas con Saldo de  activa*/
PROC SQL noprint;    
select AVG_of_Ultimo_Saldo as Ultimo_Saldo 
into :Ultimo_Saldo
from (select  (AVG(t1.Ultimo_Saldo)) AS AVG_of_Ultimo_Saldo
      FROM &libreria..Saldos_Cuenta_corriente2 t1
      WHERE t1.rut NOT = . 
and t1.rut in (select rut from &libreria..MOV_CUENTA_&periodo_1)
) as x 
;QUIT;

%let avg_saldo_activas=&Ultimo_Saldo;

%put &avg_saldo_activas;

proc sql;
create table saldos as 
select *
from  
&libreria..Saldos_Cuenta_corriente2 t1
      WHERE t1.rut NOT = . and t1.Ultimo_Saldo>=&avg_saldo_eop
;quit;


proc sql;
create table saldos_activas as 
select *
from  
&libreria..Saldos_Cuenta_corriente2 t1
      WHERE t1.rut NOT = . and t1.Ultimo_Saldo>=&avg_saldo_activas
;quit;

/*
proc sql;
create table clientes_con_saldo  as
select coalesce(a.rut,b.rut) as rut,
coalesce(a.Ultimo_Saldo,0) as saldo_eop,
coalesce(b.Ultimo_Saldo,0) as saldo_activa
from saldos a
full outer join saldos_activas as b 
on (a.rut=b.rut)  
;quit;*/

/*2- Uso 90 días, Clientes que hayan mantenido un saldo promedio diario en los últimos 90 días igual al promedio del stock de la base  NO OK*/
/*293*/
proc sql;
create table &libreria..ONBOARDING_USO_CC_90D as
select t1.*,case when b.rut not is null then  1 else  0 end as Saldo_cc_Activa,
case when T1.FECHA>0 then intck("day",T1.FECHA, T1.FECHA_hoy_SAS) else 999 end as dias_DESDE_CAPTACION
from &libreria..BASE_ONBOARDING_ESTUDIO_CC t1
left join saldos_activas b on t1.rut=b.rut
WHERE T1.rut not in (select rut from publicin.LNEGRO_CAR)
and FECHA_HOY_NUMERO_CC >=dia_90 /* antiguead 90 dias*/
and t1.rut in (select rut from saldos)
ORDER BY T1.fecha_numero
;quit;

/* BASES DE SALIDA PARA DEJAR FTP */
/*
&libreria..ONBOARDING_USO_CC_30D
&libreria..ONBOARDING_DEJO_DE_USAR_CC_30D_
&libreria..ONBOARDING_DEJO_DE_USAR_CC_60D
&libreria..ONBOARDING_SIN_USO_CC_90D
&libreria..ONBOARDING_USO_CC_90D
&libreria..ONBOARDING_SIN_USO_CC_30D*/


/*==================================================================================================*/
/*== INICIO : Macro para export al ftp de Control comercial donde los tomará el equipo de Calidad ==*/
%macro ciclos(tabla, archivo);

	PROC EXPORT DATA=&tabla.
	OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/TO_CALIDAD/&archivo."
	DBMS=dlm replace;
	delimiter=';';
	PUTNAMES=YES;
	RUN;

	filename server ftp "&archivo." CD='/'
	HOST='192.168.82.171' user='17457765K' pass='17457765K' PORT=21;

	data _null_;
	infile "/sasdata/users94/user_bi/TRASPASO_DOCS/TO_CALIDAD/&archivo.";
	file server;
	input;
	put _infile_;
	run;

%mend ciclos;

%ciclos(&libreria..ONBOARDING_USO_CC_30D,ONBOARDING_USO_CC_30D.csv);
%ciclos(&libreria..ONBOARDING_DEJO_DE_USAR_CC_30D_,ONBOARDING_DEJO_DE_USAR_CC_30D_.csv);
%ciclos(&libreria..ONBOARDING_DEJO_DE_USAR_CC_60D,ONBOARDING_DEJO_DE_USAR_CC_60D.csv);
%ciclos(&libreria..ONBOARDING_SIN_USO_CC_90D,ONBOARDING_SIN_USO_CC_90D.csv);
%ciclos(&libreria..ONBOARDING_USO_CC_90D,ONBOARDING_USO_CC_90D.csv);
%ciclos(&libreria..ONBOARDING_SIN_USO_CC_30D,ONBOARDING_SIN_USO_CC_30D.csv);

/*== FINAL : Macro para export al ftp de Control comercial donde los tomará el equipo de Calidad  ==*/
/*==================================================================================================*/

/*==================================================================================================*/
/*== Envío correo notificación ==== EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/

data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_CLIENTES';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CLIENTES_2';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'MARCELO_ANTONELLI';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3; %put &=DEST_4;	%put &=DEST_5;	%put &=DEST_6;


/* VARIABLE TIEMPO - FIN */
data _null_;
dur = datetime() - &tiempo_inicio;
put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
/*TO = ("&DEST_1")*/
TO = ("&DEST_6")
CC = ("&DEST_1", "&DEST_2", "&DEST_3", "&DEST_4", "&DEST_5")
SUBJECT = ("MAIL_AUTOM: Proceso BASE_ESTUDIO_ONBOARDING_PARTE3_CC");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "		Proceso BASE_ESTUDIO_ONBOARDING_PARTE2, ejecutado con fecha: &fechaeDVN";  
 PUT "		Información disponible en:";  
 PUT "			- SAS, librería &libreria_final. ";
 PUT "			- Ftp 192.168.82.171, archivos con extensión .csv";
 PUT ;
 PUT "		Nombres de tablas y archivos:";
 PUT "			- ONBOARDING_USO_CC_30D";
 PUT "			- ONBOARDING_DEJO_DE_USAR_CC_30D_";
 PUT "			- ONBOARDING_DEJO_DE_USAR_CC_60D";
 PUT "			- ONBOARDING_SIN_USO_CC_90D";
 PUT "			- ONBOARDING_USO_CC_90D";
 PUT "			- ONBOARDING_SIN_USO_CC_30D";
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 05'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
