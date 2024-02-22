/*PROCESO para comunicaciones diarias*/


DATA _null_;
periodo = input(put(intnx('month',today(),0,'same'),yymmn6. ),$10.);
periodo1 = input(put(intnx('month',today(),-1,'same'),yymmn6. ),$10.);
periodo2 = input(put(intnx('month',today(),-2,'same'),yymmn6. ),$10.);
periodo3 = input(put(intnx('month',today(),-3,'same'),yymmn6. ),$10.);
periodo4 = input(put(intnx('month',today(),-4,'same'),yymmn6. ),$10.);
periodo5 = input(put(intnx('month',today(),-5,'same'),yymmn6. ),$10.);
periodo6 = input(put(intnx('month',today(),-6,'same'),yymmn6. ),$10.);
DIA_MORA=input(put(intnx('day',today(),-2,'same'),ddmmyy10. ),$10.);
SALDO_FISA=input(put(intnx('day',today(),-1,'same'),ddmmyy10. ),$10.);

Call symput("periodo", periodo);
Call symput("periodo1", periodo1);
Call symput("periodo2", periodo2);
Call symput("periodo3", periodo3);
Call symput("periodo4", periodo4);
Call symput("periodo5", periodo5);
Call symput("periodo6", periodo6);
Call symput("DIA_MORA", DIA_MORA);
Call symput("SALDO_FISA", SALDO_FISA);
;
RUN;


%put &periodo;
%put &DIA_MORA;
%put &SALDO_FISA;



/*universo de contratos vigentes*/


/*contratos*/

PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table MPDT007  as 
select * 
from connection to ORACLE( 
select 
cast(B.PEMID_GLS_NRO_DCT_IDE_K as INT)  RUT,
A.CODENT,
A.CENTALTA,
A.CUENTA,
a.FECALTA  FECALTA_CTTO,
a.FECBAJA  FECBAJA_CTTO,
a.PRODUCTO,
a.SUBPRODU,
a.CONPROD
from MPDT007 a
INNER JOIN BOPERS_MAE_IDE B 
ON A.IDENTCLI=B.PEMID_NRO_INN_IDE
where a.producto in ('05','06','07','10','08','13','14')
and a.FECBAJA='0001-01-01'
) A
;QUIT;



PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table Panes as 
select * 
from connection to ORACLE(
select 
cast(B.PEMID_GLS_NRO_DCT_IDE_K as INT)  RUT,
A.CODENT,
A.CENTALTA,
A.CUENTA,
A.CALPART,
A.CODENT||A.CENTALTA||A.CUENTA  CTTO,
C.FECALTA  FECALTA_CTTO,
C.FECBAJA  FECBAJA_CTTO,

G.NUMPLASTICO,
G.PAN,
G.FECCADTAR,
G.INDULTTAR,
G.NUMBENCTA,
G.FECALTA  FECALTA_TR,
G.FECBAJA  FECBAJA_TR,
G.INDSITTAR,
g.CODMAR,
g.INDTIPT,
J.DESTIPT  TIPO_TARJETA_RSAT,
H.DESSITTAR,
G.FECULTBLQ,
g.CODBLQ,
g.TEXBLQ,
SUBSTR(G.PAN,13,4)  PAN2, 
A.CODENT||A.CENTALTA||A.CUENTA|| SUBSTR(G.PAN,13,4)   CONTRATO_PAN
FROM GETRONICS.MPDT013 A /*CONTRATO de Tarjeta*/
INNER JOIN GETRONICS.MPDT007 C /*CONTRATO*/
ON (A.CODENT=C.CODENT) AND (A.CENTALTA=C.CENTALTA) AND (A.CUENTA=C.CUENTA) 
INNER JOIN BOPERS_MAE_IDE B ON 
A.IDENTCLI=B.PEMID_NRO_INN_IDE
INNER JOIN GETRONICS.MPDT009 G /*Tarjeta*/ 
ON (A.CODENT=G.CODENT) AND (A.CENTALTA=G.CENTALTA) AND (A.CUENTA=G.CUENTA) AND (A.NUMBENCTA=G.NUMBENCTA)
INNER JOIN GETRONICS.MPDT063 H 
ON (G.CODENT=H.CODENT) AND (G.INDSITTAR=H.INDSITTAR)
LEFT JOIN GETRONICS.MPDT060 I 
ON (G.CODBLQ=I.CODBLQ)
left join GETRONICS.MPDT026 J
on(j.CODMAR=G.codmar) and (J.INDTIPT=G.INDTIPT)
where c.producto in ('10','05','06','07','13','08','14') 
and C.FECBAJA ='0001-01-01'
and G.INDULTTAR='S'
and G.INDSITTAR=5
and A.CALPART='TI'
)
;QUIT;


/*bloqueo de contratos*/

PROC SQL;
CONNECT TO ORACLE AS ITF (PATH="REPORITF.WORLD" USER='PMUNOZC' PASSWORD='pmun2102');
CREATE TABLE BLOQUEOS_contratos AS 
SELECT * FROM CONNECTION TO ITF(
SELECT A.CODENT, A.CENTALTA, A.CUENTA, A.CODBLQ,
B.DESBLQ,B.DESBLQRED,B.INDAPLEMISOR,B.CONTCUR
FROM MPDT178 A
INNER JOIN MPDT060 B ON A.CODBLQ=B.CODBLQ 
INNER JOIN (
	SELECT A.CODENT, A.CENTALTA, A.CUENTA, MAX(B.CONTCUR) MAX_FEC
	FROM MPDT178 A
	INNER JOIN MPDT060 B ON A.CODBLQ=B.CODBLQ
	WHERE A.LINEA = '0000'
	GROUP BY A.CODENT, A.CENTALTA, A.CUENTA
	) C ON A.CODENT=C.CODENT AND A.CENTALTA=C.CENTALTA AND A.CUENTA=C.CUENTA AND B.CONTCUR=C.MAX_FEC
WHERE A.LINEA = '0000'
)A
;QUIT;




proc sql;
create table base_TRABAJABLE_1 AS 
SELECT DISTINCT 
A.*,
MAX(CASE WHEN B.CUENTA IS NOT NULL AND   B.CALPART='TI' AND 
B.CODBLQ=0 AND FECCADTAR>&periodo. THEN 1 ELSE 0 END) AS pan_vigente,
MAX(CASE WHEN C.CUENTA IS NULL THEN 1 ELSE 0 END)AS CONTRATO_VIGENTE

FROM MPDT007 AS A 
LEFT JOIN PANES AS B

ON(A.CUENTA=B.CUENTA) AND (A.CENTALTA=B.CENTALTA) AND (A.CODENT=B.CODENT)
LEFT JOIN BLOQUEOS_CONTRATOS AS C

ON(A.CUENTA=C.CUENTA) AND (A.CENTALTA=C.CENTALTA) AND (A.CODENT=C.CODENT)
GROUP BY 
A.CODENT,
A.CENTALTA,
A.CUENTA
;quit;


proc sql;
drop table MPDT007;
drop table PANES;
drop table BLOQUEOS_CONTRATOS;
;QUIT;


PROC SQL NOERRORSTOP ;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table DIAS_MORA as
select *
from connection to ORACLE(
select
b.evaam_nro_ctt,
EVAAM_DIA_MOR
from SFRIES_ALT_MOR b
where b.EVAAM_FCH_PRO =
to_date(%str(%')&dia_mora.%str(%'),'dd/mm/yyyy')
and EVAAM_DIA_MOR>0
) A
;QUIT;


/*EGP*/

PROC SQL NOERRORSTOP ;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table EGP as
select *
from connection to ORACLE(
select a.codent,
a.centalta,
a.cuenta,
a.Limcrecta*1 as EGP,
a.saldiscre*1 as SALDO_DISPUESTO
from Mpdt163 a
inner join mpdt007  b
on(a.cuenta=b.cuenta) and (a.centalta=b.centalta)
where b.producto in ('10','05','06','07') 
) A
;QUIT;

PROC SQL NOERRORSTOP ;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table CUPO_LINEA as
select *
from connection to ORACLE(
select 
a.CODENT,
a.CENTALTA,
a.CUENTA,
max(case when a.linea='0050' then a.LIMCRELNA*1 else 0 end ) as cupo_compra,
max(case when a.linea='0053' then a.LIMCRELNA*1 else 0 end ) as cupo_Spos

from MPDT450 a
inner join mpdt007  b
on(a.cuenta=b.cuenta) and (a.centalta=b.centalta)
where b.producto in ('10','05','06','07','14')
group by 
a.CODENT,
a.CENTALTA,
a.CUENTA

) A
;QUIT;

PROC SQL NOERRORSTOP ;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table saldo_linea as
select *
from connection to ORACLE(
select 
a.codent,
a.centalta,
a.cuenta,
sum(case when linea='0050' and SITIMP in('D','A')  then  IMPDEUDA1	+
IMPDEUDA2	+
 IMPDEUDA3	+
IMPDEUDA4	+
 IMPDEUDA5	+
IMPDEUDA6	+
IMPDEUDA7	+
 IMPDEUDA8	+
IMPDEUDA9	+
IMPDEUDA10	
 else 0 end )-
sum(case when linea='0050' and SITIMP in('D','A')  then   IMPAPL1	+
IMPAPL2	+
 IMPAPL3	+
 IMPAPL4	+
 IMPAPL5	+
IMPAPL6	+
 IMPAPL7	+
IMPAPL8	+
IMPAPL9	+
IMPAPL10		
 else 0 end )
as SALDO_compra,
sum(case when linea='0053' and SITIMP in('D','A') then   IMPDEUDA1	+
IMPDEUDA2	+
 IMPDEUDA3	+
IMPDEUDA4	+
 IMPDEUDA5	+
IMPDEUDA6	+
IMPDEUDA7	+
 IMPDEUDA8	+
IMPDEUDA9	+
IMPDEUDA10 else 0 end ) -
sum(case when linea='0053' and SITIMP in('D','A')  then   IMPAPL1	+
IMPAPL2	+
 IMPAPL3	+
 IMPAPL4	+
 IMPAPL5	+
IMPAPL6	+
 IMPAPL7	+
IMPAPL8	+
IMPAPL9	+
IMPAPL10		
 else 0 end ) as SALDO_Spos
from MPDT460 a 
inner join mpdt007  b
on(a.cuenta=b.cuenta) and (a.centalta=b.centalta)
where b.producto in ('10','05','06','07','14')
group by
a.codent,
a.centalta,
a.cuenta
) A
;QUIT;


proc sql;
create table base_trabajable_2 as
select 
a.*,
case when b.evaam_nro_ctt is null then 0 else 1 end as CON_MORA,
c.EGP,
c.SALDO_DISPUESTO,
d.cupo_compra,
d.cupo_Spos,
e.SALDO_compra,
e.SALDO_Spos
from base_trabajable_1 as a 
left join DIAS_MORA as b
on(cat(a.codent,a.centalta,a.cuenta)=b.evaam_nro_ctt)
left join EGP as c
on(a.cuenta=c.cuenta) and (a.centalta=c.centalta)
left join CUPO_LINEA as d
on(a.cuenta=d.cuenta) and (a.centalta=d.centalta)
left join saldo_linea as e
on(a.cuenta=e.cuenta) and (a.centalta=e.centalta)
;QUIT;


proc sql;
drop table DIAS_MORA;
drop table EGP;
drop table CUPO_LINEA;
drop table saldo_linea;
drop table base_trabajable_1;
;QUIT;


/*saldo de debito*/

	
%let path_ora2       = '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=192.168.84.76)(PORT=1521))(CONNECT_DATA=(SERVER=dedicated)(SID=SEGCOM)))';
%let user_ora2        = 'PMUNOZC';
%let pass_ora2        = 'pmun3012';

%let conexion_ora2    = ORACLE PATH=&path_ora2. USER=&user_ora2. PASSWORD=&pass_ora2.;
%put &conexion_ora2.;



PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER=&user_ora2. PASSWORD=&pass_ora2. path =&path_ora2. );

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



%let path_ora      = '(DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SID = ripleyc)))'; 
%let user_ora      = 'RIPLEYC'; 
%let pass_ora      = 'ri99pley';
%let conexion_ora  = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 
 

PROC SQL ;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );
create table SB_Saldos_Cuenta_Vista  as
select 
INPUT((SUBSTR(cli_identifica,1,(LENGTH(cli_identifica)-1))),BEST.) AS RUT, 
input(SUBSTR(put(datepart(acp_fecha),yymmddn8.),1,8),best.) as CodFecha,
ACP_FECHA,
ACP_NUMCUE,
Saldo
from connection to ORACLE( select 
b.cli_identifica,
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
and a.acp_fecha >=  to_date(%str(%')&SALDO_FISA.%str(%'),'dd/mm/yyyy')
and a.acp_fecha <= to_date(%str(%')&SALDO_FISA.%str(%'),'dd/mm/yyyy')
group by 
a.ACP_FECHA, 
a.ACP_NUMCUE,
b.cli_identifica
) ;
disconnect from ORACLE;
QUIT;


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
and a.acp_fecha >=  to_date(%str(%')&SALDO_FISA.%str(%'),'dd/mm/yyyy')
and a.acp_fecha <= to_date(%str(%')&SALDO_FISA.%str(%'),'dd/mm/yyyy')
group by 
a.ACP_FECHA, 
a.ACP_NUMCUE,
b.cli_identifica
) ;
disconnect from ORACLE;
QUIT;


proc sql;
create table base_trabajable3 as 
select 
a.*,
coalesce(coalesce(c.SALDO,c1.saldo),0) as saldo_cv,
coalesce(coalesce(d.SALDO,d1.saldo),0) as saldo_CTACTE
from base_trabajable_2 as a 

left join mpdt666 as b
on(a.cuenta=b.cuenta1) and (a.centalta=b.centalta1)

left join SB_Saldos_Cuenta_Vista as c
on(b.cv=c.ACP_NUMCUE)

left join (select a.*
from SB_Saldos_Cuenta_Vista as a 
left join mpdt666 as b
on(b.cv=a.ACP_NUMCUE)
where b.cv is null) as c1
on(a.rut=c1.rut) and a.producto='08'

left join Saldos_Cuenta_corriente as d
on(b.cv=d.ACP_NUMCUE)

left join (select a.*
from Saldos_Cuenta_corriente as a 
left join mpdt666 as b
on(b.cv=a.ACP_NUMCUE)
where b.cv is null) as d1
on(a.rut=d1.rut) and a.producto='13'
;QUIT;


/*dejar inofrmacion a nivel de rut unico*/
options cmplib=sbarrera.funcs; 

proc sql;
create table RUTERO_UNICOS as 
select 
rut,
SB_DV(rut) as dv,
MAX(case when PRODUCTO in ('05','06','07','10','14') then 1 else 0 end ) as  SI_TAM,
MAX(case when PRODUCTO in ('08') then 1 else 0 end ) as   SI_CV,
MAX(case when PRODUCTO in ('13') then 1 else 0 end ) as   SI_CTACTE,

MAX(case when PRODUCTO in ('05','06','07','10','14') then input(compress(FECALTA_CTTO,'-'),best.) end ) as   apertura_TAM,
MAX(case when PRODUCTO in ('08') then input(compress(FECALTA_CTTO,'-'),best.) end ) as   apertura_CV,
MAX(case when PRODUCTO in ('13') then input(compress(FECALTA_CTTO,'-'),best.) end ) as   apertura_CTACTE,

MAX(case when PRODUCTO in ('05','06','07','10','14')  and pan_vigente=1 and 	CONTRATO_VIGENTE=1 and 	CON_MORA=0 then 1 else 0 end ) as   producto_vigente_TAM,
MAX(case when PRODUCTO in ('08') and pan_vigente=1 and 	CONTRATO_VIGENTE=1 and 	CON_MORA=0 then 1 else 0  end ) as   producto_vigente_CV,
MAX(case when PRODUCTO in ('13') and pan_vigente=1 and 	CONTRATO_VIGENTE=1 and 	CON_MORA=0  then 1 else 0  end ) as   producto_vigente_CTACTE,

max(coalesce(EGP,0)) as EGP,
max(coalesce(SALDO_DISPUESTO,0)) as SALDO_DISPUESTO_TAM,

max(case when producto in ('05','06','07','14') then  CUPO_COMPRA-SALDO_COMPRA 
when ('10') then  CUPO_spos-SALDO_spos 
else 0  end ) as DISPONIBLE_TAM,
max(saldo_cv) as saldo_cv,
max(saldo_CTACTE) as saldo_CTACTE



from base_trabajable3
group by rut
;QUIT;


/*borrado de tablas*/

proc sql;
drop table base_trabajable_2;
drop table base_trabajable3;
drop table mpdt666;
drop table saldos_cuenta_corriente;
drop table sb_saldos_cuenta_vista;
;QUIT;


/*informacion demografica y data de contactabilidad*/


proc sql;
create table RUTERO_UNICOS2 as 
select distinct 
a.*,
case when b.rut is not null then 1 else 0 end as lnegro_car,
case when b1.rut is not null then 1 else 0 end as lnegro_email,
case when b2.rut is not null then 1 else 0 end as lnegro_sms,
case when c.rut is not null then 1 else 0 end as si_email,
case when c.rut is not null then c.email end as email,
case when d.clirut is not null then 1 else 0 end as si_telefono,
case when d.clirut is not null then cat('596',d.telefono) end as telefono,
e.region
from RUTERO_UNICOS as a 
left join publicin.lnegro_car as b
on(a.rut=b.rut)
left join publicin.lnegro_email as b1 
on(a.rut=b1.rut)
left join publicin.lnegro_sms as b2
on(a.rut=b2.rut)
left join publicin.base_trabajo_email as c
on(a.rut=c.rut)
left join publicin.fonos_movil_final as d
on(a.rut=d.clirut)
left join publicin.direcciones as e
on(a.rut=e.rut)
;QUIT;

/*ultima informacion de modelo y segmento observada*/

/*actividad TR*/
  
PROC SQL NOPRINT;    
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
where upper(Nombre_Tabla) like '%PUBLICIN.ACT_TR_%'
and length(Nombre_Tabla)=length('PUBLICIN.ACT_TR_AAAAMM') 
) as x 
;QUIT; 

%LET PERIODO_ACT=&Max_anomes;
%put &PERIODO_ACT;

/*recomendador*/

PROC SQL NOPRINT;    
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
where upper(Nombre_Tabla) like '%RSEPULV.RECOM_SPOS_%'
and length(Nombre_Tabla)=length('RSEPULV.RECOM_SPOS_202208') 
) as x 
;QUIT; 

%LET PERIODO_RECOMENDADOR=&Max_anomes;
%put &PERIODO_RECOMENDADOR;

/*periodo clones*/

PROC SQL NOPRINT;    
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
where upper(Nombre_Tabla) like '%RSEPULV.CLONES_PROB_%'
and length(Nombre_Tabla)=length('RSEPULV.CLONES_PROB_202208') 
) as x 
;QUIT; 

%LET PERIODO_CLONES=&Max_anomes;
%put &PERIODO_CLONES;

/*periodo rfm*/

PROC SQL NOPRINT;    
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
where upper(Nombre_Tabla) like '%PUBLICIN.RUBRO_PREFERENTE_%'
and length(Nombre_Tabla)=length('PUBLICIN.RUBRO_PREFERENTE_202208') 
) as x 
;QUIT; 

%LET PERIODO_RFM=&Max_anomes;
%put &PERIODO_RFM;


proc sql;
create table recomendador as 
select 
rut,
max(case when rank=1 then rhs_nom end) as NOMBRE_1,
max(case when rank=1 then confidence end) as confidence_1,

max(case when rank=2 then rhs_nom end) as NOMBRE_2,
max(case when rank=2 then confidence end) as confidence_2,


max(case when rank=3 then rhs_nom end) as NOMBRE_3,
max(case when rank=3 then confidence end) as confidence_3,


max(case when rank=4 then rhs_nom end) as NOMBRE_4,
max(case when rank=4 then confidence end) as confidence_4,


max(case when rank=5 then rhs_nom end) as NOMBRE_5,
max(case when rank=5 then confidence end) as confidence_5
from RSEPULV.RECOM_SPOS_&PERIODO_RECOMENDADOR.
group by rut
;QUIT;

/*logueo app*/

proc sql;
create table app as 
select distinct 
rut 
from publicin.logeo_int_&periodo.
where TIPO_LOGUEO='APP'
union 
select distinct 
rut 
from publicin.logeo_int_&periodo1.
where TIPO_LOGUEO='APP'
union 
select distinct 
rut 
from publicin.logeo_int_&periodo2.
where TIPO_LOGUEO='APP'
union 
select distinct 
rut 
from publicin.logeo_int_&periodo3.
where TIPO_LOGUEO='APP'
union 
select distinct 
rut 
from publicin.logeo_int_&periodo4.
where TIPO_LOGUEO='APP'
union 
select distinct 
rut 
from publicin.logeo_int_&periodo5.
where TIPO_LOGUEO='APP'
union 
select distinct 
rut 
from publicin.logeo_int_&periodo6.
where TIPO_LOGUEO='APP'
;QUIT;


proc sql;
create table RESULT.UNIVERSO_COMUNICABLE_RIPLEY as 
select distinct 
a.*,
b.NOMBRE_1,
b.confidence_1,
b.NOMBRE_2,
b.confidence_2,
b.NOMBRE_3,
b.confidence_3,
b.NOMBRE_4,
b.confidence_4,
b.NOMBRE_5,
b.confidence_5,
c.RFM_SUPERMERCADOS,
c.RFM_RETAIL	,
c.RFM_SERVICIOS,
c.RFM_OTROS_COMERCIOS,
c.RFM_SERVICIOS_BASICOS,
c.RFM_COMBUSTIBLES,
c.RFM_VIAJES,
c.RFM_ALIMENTACION_FASTFOOD,
c.RFM_MEJORA_HOGAR,
c.RFM_CLINICAS,
c.RFM_AUTOMOTRIZ	,
c.RFM_FARMACIAS	,
c.RFM_RECAUD_SECTOR_PUBLICO,
c.RFM_RESTAURANTES,
c.RFM_ENTRETENCION	,
c.RFM_EDUCACION	,
c.RFM_TRANSPORTE	,
c.RFM_BELLEZA,
c.RFM_RECAUDACION	,
c.RFM_INST_FINANCIERAS,
c.RFM_Otros_Rubros_SPOS,
c.Rubro_Fuerte1,
c.Rubro_Fuerte2	,
c.Rubro_Fuerte3,
d.*,
case when e.vu_C_PRIMA='VU' then 1 else 0 end as vu_c_PRIMA,
coalesce(e.vu_riesgo,0) as vu,
coalesce(f.segmento,'SIN SEGMENTO') as segmento_COMERCIAL,
case when g.rut is not null then 1 else 0 end as logueo_int


from RUTERO_UNICOS2 as a 
left join recomendador as b
on(a.rut=b.rut)
left join publicin.rubro_preferente_&PERIODO_RFM. as c
on(a.rut=c.rut)

left join rsepulv.clones_prob_&PERIODO_CLONES. as d
on(a.rut=d.rut)
left join publicin.act_tr_&periodo_act. as e
on(a.rut=e.rut)

left join publicin.segmento_comercial as f
on(a.rut=f.rut)
left join app as g
on(a.rut=g.rut)

;QUIT;


proc sql;
drop table app;
drop table recomendador;
drop table rutero_unicos;
drop table rutero_unicos2;
;QUIT;


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
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';

SELECT EMAIL into :DEST_4
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_4;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO =("&DEST_1","&DEST_2","&DEST_4","kgonzalezi@bancoripley.com")

SUBJECT="MAIL_AUTOM: PROCESO UNIVERSO COMUNICABLE %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "PROCESO UNIVERSO COMUNICABLE, ejecutado con fecha: &fechaeDVN";  
 put "Version 1 "; 
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










