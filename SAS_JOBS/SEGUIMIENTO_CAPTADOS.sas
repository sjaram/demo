/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	SEGUIMIENTO_CAPTADOS		================================*/
/* CONTROL DE VERSIONES
/* 2022-08-25 -- V04-- Sergio J. 
					 -- Se añade sentencia include para borrar y exportar a RAW
/* 2022-07-12 -- V03 -- Sergio J. 
					 -- Se agrega código de exportación para alimentar a Tableau
/* 2021-26-01 -- V02 -- Pedro M. -- Versión Original 

/* 2020-10-09 -- V01 -- Pedro M. -- Versión Original 
					 -- Comentarios EDYP (Al inicio y al final)
					 -- Agregar destinatarios al envío de email notificando ejecución
/* INFORMACIÓN:
Tablas requeridas o conexiones a BD
	- REPORITF
	- REPLICA CAMPAÑAS
	- result.capta_salida
	- pmunoz.mpdt043
	- pmunoz.codigos_capta_cdp
	- result.EDP_BI_DESTINATARIOS

Tabla de Salida
	- &lib..seguimiento_captados
	- ORACLOUD
*/

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/

%let libreria=RESULT;

%macro seg_capta_salida(N,lib);

%put==================================================================================================;
%put MACRO FECHAS ;
%put==================================================================================================;

DATA _null_;
INI = input(put(intnx('month',today(),-&N.,'begin'),date9. ),$10.);
FIN = input(put(intnx('month',today(),-&N.,'end'),date9. ),$10.);
periodo = input(put(intnx('month',today(),-&N.,'end'),yymmn6. ),$10.);
Call symput("INI", INI);
Call symput("FIN", FIN);
Call symput("periodo", periodo);
RUN;

%put &INI; 
%put &FIN;
%put &periodo;

%put==================================================================================================;
%put captados &periodo. ;
%put==================================================================================================;

proc sql;
create table captados as 
select
RUT_CLIENTE as rut, 
cod_prod,
PRODUCTO,
COD_SUCURSAL,
COD_CANAL,
CANAL,
FECHA,
ORIGEN,
LINEA_CREDITO,
CODENT,
CENTALTA,
CUENTA,
VIA,
NRO_SOLICITUD,
ID_OFERTA
from result.capta_salida 
where fecha between "&ini."d and "&fin."D

;QUIT;

%put==================================================================================================;
%put contratos ;
%put==================================================================================================;


PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table cuentas  as 
select * 
from connection to ORACLE( 
select 
A.CODENT,
A.CENTALTA,
A.CUENTA,
a.FECALTA  FECALTA_CTTO,
a.FECBAJA  FECBAJA_CTTO,
a.PRODUCTO,
a.SUBPRODU,
a.CONPROD

from MPDT007 a
) A
;QUIT;


proc sql;
create table info_contratos as 
select distinct 
a.*,
b.PRODUCTO as producto_rsat,
b.SUBPRODU as subprodu_rsat,
b.CONPROD as condprod_rsat
from captados as a
left join cuentas as b
on(A.CUENTA=b.cuenta) and (A.CODENT=b.codent) and (A.CENTALTA=b.centalta)
;QUIT;


%put==================================================================================================;
%put Nombre sucursal ;
%put==================================================================================================;


LIBNAME CAMP ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="BRTEFGESTIONP.WORLD"  SCHEMA=CAMP_ADM  USER='CAMP_COMERCIAL'  PASSWORD='ccomer2409' ;

proc sql;
create table sucursal as 
select distinct 
c.CAMP_DAT_VALOR1 as codigo,
c.CAMP_DAT_TEXTO1 as sucursal
from CAMP.CBCAMP_PAR_TABLAS a
INNER JOIN CAMP.CBCAMP_PAR_COLUMNAS B ON A.CAMP_COD_TABLA = B.CAMP_COD_TABLA_K
INNER JOIN CAMP.CBCAMP_PAR_DATOS C ON A.CAMP_COD_TABLA = C.CAMP_COD_TABLA_K
WHERE CAMP_COD_TABLA = 2
;QUIT;

proc sql;
create table info_sucursal as 
select distinct 
a.*,
b.sucursal as nombre_sucursal
from info_contratos as a
left join sucursal as b
on(a.cod_sucursal=b.codigo)
;QUIT;


%put==================================================================================================;
%put TIPO CONTRATO ;
%put==================================================================================================;

proc sql;
create table cruce2 as 
select distinct 
a.*,
b.DESPROD,	
b.DESPRODRED
from info_sucursal as a
left join pmunoz.mpdt043 as b
on(a.producto_rsat=b.producto) and (a.SUBPRODU_rsat=b.SUBPRODU)
;QUIT;


%put==================================================================================================;
%put oferta de campaña ;
%put==================================================================================================;

proc sql;
create table llenado (
CAMP_ID_OFE_K num,
CAMP_COD_CAMP_FK char(99),
CAMP_RUT_CLI num,
CAMP_DV_CLI char(99),
CAMP_COD_TIP_PROD char(99),
CAMP_COD_CND_PROD char(99),
CAMP_COD_ORI_BASE char(99)

)
;QUIT;

proc sql noprint ;
select
ceil (count(distinct case when ID_OFERTA is not null then ID_OFERTA end )/500) as corte
into: corte
from cruce2
;QUIT;

%let corte=&corte;
%put &corte;

%macro sacar_data(N);

proc sql;
create table base_cortar as 
select 
monotonic() as ind,
ID_OFERTA
from cruce2
where ID_OFERTA is not null
;QUIT;

%do i=1 %to &n.;

%put==================================================================================================;
%put CICLO &I. ;
%put==================================================================================================;

proc sql;
create table base_paso_in as 
select 
ID_OFERTA
from base_cortar
where ind between 500*(&i.-1)+1 and 500*&i.
;QUIT;

data work.Valor_Concatenado(keep=Listado); /*base de salida con campo*/
length Listado $9999; /*largo del campo*/
do until(eof);
set work.base_paso_in end=eof; /*base de entrada: (Base detalle de codigos LATAM)*/
Listado = catx(",", Listado, ID_OFERTA); /*concatenacion*/
end;
run;

proc sql outobs=1 noprint ;
select Listado
into :Listado 
from work.Valor_Concatenado 
;quit;
%let Listado="&Listado";

DATA _NULL_;
Call execute(
cat('
PROC SQL ;
CONNECT TO ORACLE  (PATH=''BRTEFGESTIONP.WORLD'' USER=''CAMP_COMERCIAL'' PASSWORD=''ccomer2409'');
CREATE TABLE cod_camp AS   
SELECT 
* 
FROM CONNECTION TO ORACLE(
SELECT 
CAMP_ID_OFE_K,
CAMP_COD_CAMP_FK,
CAMP_RUT_CLI,
CAMP_DV_CLI,
CAMP_COD_TIP_PROD,
CAMP_COD_CND_PROD,
CAMP_COD_ORI_BASE 

from cbcamp_mae_ofertas 
where CAMP_ID_OFE_K in ( ',&Listado.,' ) ) A 
;QUIT;
')
);
run;  

proc sql;
insert into llenado
select *
from cod_camp 
;QUIT;

proc sql;
drop table base_paso_in;
drop table Valor_Concatenado;
drop table cod_camp;
;QUIT;

%end;

proc sql;
drop table base_cortar
;QUIT;

%mend sacar_data;

%sacar_data(&corte.);


proc sql;
create table info_camp as 
select distinct 
a.*,
b.CAMP_COD_CAMP_FK,
b.CAMP_DV_CLI,
b.CAMP_COD_TIP_PROD,
b.CAMP_COD_CND_PROD,
b.CAMP_COD_ORI_BASE

from cruce2 as a
left join  llenado as b
on(a.ID_OFERTA=b.CAMP_ID_OFE_K)
;QUIT;

%put==================================================================================================;
%put TIPO DE CLIENTE ;
%put==================================================================================================;

proc sql;
create table info_cliente as 
select distinct 
a.*,
b.detalle as tipo_cliente_camp
from info_camp as a
left join pmunoz.tipo_cliente_camp as b
on(input(a.CAMP_COD_ORI_BASE,best.)=b.codigo)
;QUIT;

%put==================================================================================================;
%put DETALLE TIPO DE PRODUCTO ;
%put==================================================================================================;

proc sql;
create table TIPO_PRODUCTO as 
select distinct 
CAMP_DAT_TEXTO1 as cod_prod,
CAMP_DAT_TEXTO2 as cod_cond_prod ,
CAMP_DAT_TEXTO3 as text_prod

from CAMP.CBCAMP_PAR_TABLAS a
INNER JOIN CAMP.CBCAMP_PAR_COLUMNAS B ON A.CAMP_COD_TABLA = B.CAMP_COD_TABLA_K
INNER JOIN CAMP.CBCAMP_PAR_DATOS C ON A.CAMP_COD_TABLA = C.CAMP_COD_TABLA_K
WHERE CAMP_COD_TABLA = 13
;QUIT;


proc sql;
create table info_con_prod as 
select distinct 
a.*,
b.text_prod
from info_cliente as a
left join TIPO_PRODUCTO as b
on(a.CAMP_COD_TIP_PROD=b.cod_prod) and (a.CAMP_COD_CND_PROD=b.cod_cond_prod)

;QUIT;

%put==================================================================================================;
%put AGRUPADO ;
%put==================================================================================================;


proc sql;
create table agrupado as 
select 
fecha,
producto,
FECHA,
ORIGEN,
VIA,
DESPROD,
case when CAMP_COD_TIP_PROD is not null then CAMP_COD_TIP_PROD else 'SIN INFO' end as COD_TIP_PROD,
case when CAMP_COD_CND_PROD is not null then CAMP_COD_CND_PROD else 'SIN INFO' end as COD_CND_PROD,
case when  text_prod is not null then upcase(text_prod) else 'SIN INFO' end as text_prod ,

case when tipo_cliente_camp is null then 'SIN INFO' else tipo_cliente_camp end as TIPO_CLIENTE,
case when cod_sucursal between 500 and 799 then 'BANCO' else CANAL end as CANAL,
cats(cod_sucursal,'|', nombre_sucursal) as sucursal,
via,
count(rut) as clientes 
from info_con_prod 
group by 
fecha,
producto,
FECHA,
ORIGEN,
VIA,
DESPROD,
calculated COD_TIP_PROD,
calculated COD_CND_PROD,
calculated text_prod ,
calculated TIPO_CLIENTE,
calculated CANAL,
calculated sucursal
;QUIT;

%put==================================================================================================;
%put guardar en duro ;
%put==================================================================================================;

%if (%sysfunc(exist(&lib..seguimiento_captados))) %then %do;
%end;
%else %do;
proc sql;
create table &lib..seguimiento_captados (
periodo num,
fecha date,
producto char(99),
origen char(99),
via char(99),
desprod char(99),
 COD_TIP_PROD char(99),
 COD_CND_PROD char(99),
 text_prod char(99),
tipo_cliente char(99),
canal char(99),
sucursal char(99),
clientes num
)
;QUIT;
%end;

proc sql;
delete *
from &lib..seguimiento_captados
where periodo=&periodo.
;QUIT;

proc sql;
insert into  &lib..seguimiento_captados
select 
&periodo. as periodo,
*
from agrupado
;QUIT;
	
%put==================================================================================================;
%put BORRADO DE TABLAS DE PASO ;
%put==================================================================================================;

proc sql;
drop table captados;
drop table cuentas;
drop table info_contratos;
drop table sucursal;
drop table info_sucursal;
drop table cruce2;
drop table llenado;
drop table info_camp;
drop table info_cliente;
drop table agrupado;
drop table info_con_prod;
drop table tipo_producto;
;QUIT;

%put==================================================================================================;
%put SUBIR A TABLEAU ;
%put==================================================================================================;


LIBNAME ORACLOUD ORACLE sql_functions=all  READBUFF=1000  INSERTBUFF=1000  PATH="REPORTSAS.WORLD"  SCHEMA=SAS_ADM authdomain=DBOracleCloud_Auth;

%if (%sysfunc(exist(oracloud.pmunoz_seguimiento_captados ))) %then %do;
 
%end;
%else %do;
proc sql;
connect using oracloud;
create table  oracloud.pmunoz_seguimiento_captados (
periodo num,
fecha date,
producto char(99),
origen char(99),
via char(99),
desprod char(99),
 COD_TIP_PROD char(99),
 COD_CND_PROD char(99),
 text_prod char(99),
tipo_cliente char(99),
canal char(99),
sucursal char(99),
clientes num
);
disconnect from oracloud;run;
%end;


proc sql;
connect using oracloud;
execute by oracloud ( delete from   pmunoz_seguimiento_captados    where periodo=&periodo. );
disconnect from oracloud;
;quit;


proc sql; 
connect using oracloud;
insert into   oracloud.pmunoz_seguimiento_captados (
periodo ,
fecha ,
producto ,
origen ,
via ,
desprod ,
 COD_TIP_PROD ,
 COD_CND_PROD ,
 text_prod ,
tipo_cliente ,
canal ,
sucursal ,
clientes  )

select 
periodo ,
DHMS(fecha,0,0,0) as fecha format=datetime20. ,
producto ,
origen ,
via ,
desprod ,
 COD_TIP_PROD ,
 COD_CND_PROD ,
 text_prod ,
tipo_cliente ,
canal ,
sucursal ,
clientes 
from &lib..seguimiento_captados
where periodo=&periodo.; 
disconnect from oracloud;run;

%mend seg_capta_salida;

%put==================================================================================================;
%put EJECUCION ;
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

%if %eval(&todays_date.=&PRIMER_DIAL_LABORAL.) %then %do;
%seg_capta_salida(1,&libreria.);
%seg_capta_salida(0,&libreria.);
%end;
%else %do;

%seg_capta_salida(0,&libreria.);
%end;

%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_DELETE.sas";
%borrarOracleRaw(PPFF_SEGUIMIENTO_CAPTADOS);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_EXPORT.sas";
%ExportacionOracleRaw(PPFF_SEGUIMIENTO_CAPTADOS,RESULT.seguimiento_captados);




data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */

%put==================================================================================================;
%put EMAIL AUTOMATICO ;
%put==================================================================================================;

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

SELECT EMAIL into :DEST_3 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'CLAUDIA_PAREDES';

SELECT EMAIL into :DEST_4 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'RODRIGO_LAIZ';

SELECT EMAIL into :DEST_5 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;
%put &=DEST_5;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_2","&DEST_3","&DEST_4")
CC = ("&DEST_1","&DEST_5")
SUBJECT="MAIL_AUTOM: PROCESO SEGUIMIENTO CAPTADOS %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso SEGUIMIENTO CAPTADOS, ejecutado con fecha: &fechaeDVN";  
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
