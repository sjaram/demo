/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*================================== 	   Comunicación SMS   		================================*/
/* CONTROL DE VERSIONES
/* 2022-03-31 -- V4 -- Esteban P. -- Actualización de correos: Se desvincula a Diego García como destinatario.
/* 2022-02-23 -- V3 -- Sergio J. --  
					-- Modificación de proceso para eliminar errores de fechas
/* 2022-02-21 -- V2 -- Sergio J. --  
					-- Modificación de librerías y correos
/* 2022-02-21 -- V1 -- Pedro M. --  
					-- Versión Original
*/
OPTIONS VALIDVARNAME=ANY;

proc sql outobs=1 noprint;
select 
year(today()-1)*10000+month(today()-1) *100+day(today()-1)  
 as Periodo_dia 
into :Periodo_dia 
from sashelp.vmember
;quit;

%let periodo_dia=&periodo_dia;
%put &Periodo_dia;

%let libreria=RESULT;

%macro sms_totalero_diario;

PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table cuentas  as 
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
a.CONPROD,
a.GRUPOLIQ,
a.INDBLQOPE,
case when a.GRUPOLIQ=1 then 5
when a.GRUPOLIQ=2 then 10
when a.GRUPOLIQ=3 then 15
when a.GRUPOLIQ=4 then 20
when a.GRUPOLIQ=5 then 25
when a.GRUPOLIQ=6 then 30
when a.GRUPOLIQ=7 then 18 end as corte 

from MPDT007 a
INNER JOIN BOPERS_MAE_IDE B 
ON A.IDENTCLI=B.PEMID_NRO_INN_IDE

where a.PRODUCTO<>'08'
and a.FECBAJA='0001-01-01'
) A
;QUIT;



/*ultima base de funcionarios*/

PROC SQL noprint;   
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
where upper(Nombre_Tabla) like 'NLAGOSG.DOTACION_%' 
and length(Nombre_Tabla)=length('NLAGOSG.DOTACION_201810')
) as x
;QUIT;

data _null_ ;
per_DOT=put(&Max_anomes,$6.);
Call symput('per_DOT',per_DOT);
run;
%put &per_DOT;


/*universo de contratos totaleros */

proc sql;
create table base_totaleros as 
select 
CONTRATO,
SUCURSAL,
sum(totalero) as nro
from pmunoz.Base_contratos_totaleros 
group by 
CONTRATO,
SUCURSAL
;QUIT;



/*base_inicial*/

proc sql;
create table base1 as 
select 
a.*
from cuentas as a 
inner join base_totaleros as b
on(input(a.cuenta,best.)=b.contrato) and (input(a.centalta,best.)=b.sucursal)
left join NLAGOSG.DOTACION_&per_DOT. as c
on(a.rut=c.rut)

where c.rut is null
;QUIT;




/*definir periodos de uso, son mes actual y mes anterior*/


DATA _NULL_;

periodo = input(put(intnx('month',today(),0,'end'),yymmn6. ),$10.);
periodo_ant = input(put(intnx('month',today(),-1,'end'),yymmn6. ),$10.);
envio = input(put(intnx('day',today(),0,'same'),yymmddn8. ),$10.);
Call symput("periodo", periodo);
Call symput("periodo_ant", periodo_ant);
Call symput("envio", envio);
run;
%put &periodo;
%put &periodo_ant;
%put &envio;



%if (%sysfunc(exist(publicin.tda_itf_&periodo.))) %then %do;
proc sql;
create table TDA as 
select distinct 
cuenta,
centalta,
year(fecha)*10000+month(fecha)*100+day(fecha) as fecha
from publicin.tda_itf_&periodo_ant.
union 
select distinct 
cuenta,
centalta,
year(fecha)*10000+month(fecha)*100+day(fecha) as fecha
from publicin.tda_itf_&periodo.
;QUIT; 
%end;
%else %do;
proc sql;
create table TDA as 
select distinct 
cuenta,
centalta,
year(fecha)*10000+month(fecha)*100+day(fecha) as fecha
from publicin.tda_itf_&periodo_ant.
;QUIT;
%end;



%if (%sysfunc(exist(publicin.SPOS_AUT_&periodo.))) %then %do;
proc sql;
create table SPOS as 
select distinct 
cuenta,
centalta,
fecha
from publicin.SPOS_AUT_&periodo_ant.
union 
select distinct 
cuenta,
centalta,
fecha
from publicin.SPOS_AUT_&periodo.
;QUIT;

%end;
%else %do;
proc sql;
create table SPOS as 
select distinct 
cuenta,
centalta,
fecha
from publicin.SPOS_AUT_&periodo_ant.
;QUIT;

%end;


%if (%sysfunc(exist(publicin.TRX_SEGUROS_&periodo.))) %then %do;

proc sql;
create table SEGUROS as 
select distinct 
cuenta,
centalta,
input(compress(FECMOV,'-'),best.) as fecha
from publicin.TRX_SEGUROS_&periodo_ant.
where TIPOFAC=5054
union 
select distinct 
cuenta,
centalta,
input(compress(FECMOV,'-'),best.) as fecha
from publicin.TRX_SEGUROS_&periodo.
where TIPOFAC=5054
;QUIT;

%end;
%else %do;

proc sql;
create table SEGUROS as 
select distinct 
cuenta,
centalta,
input(compress(FECMOV,'-'),best.) as fecha
from publicin.TRX_SEGUROS_&periodo_ant.
where TIPOFAC=5054
;QUIT;

%end;





proc sql;
create table base2 as 
select distinct 
a.*,
max(case when b.cuenta is not null
and b.fecha between &periodo_ant.*100+a.CORTE +1 and &periodo.*100+a.CORTE -1
then 1 else 0 end )  as A_F_TDA,

min(case when b.cuenta is not null
and b.fecha between &periodo_ant.*100+a.CORTE +1 and &periodo.*100+a.CORTE -1 then b.fecha end) as FEC_A_F_TDA,

max(case when c.cuenta is not null
and c.fecha between &periodo_ant.*100+a.CORTE +1 and &periodo.*100+a.CORTE -1
then 1 else 0 end )  as A_F_SPOS,

min(case when c.cuenta is not null
and c.fecha between &periodo_ant.*100+a.CORTE +1 and &periodo.*100+a.CORTE -1 then c.fecha end) as FEC_A_F_SPOS,


max(case when d.cuenta is not null
and d.fecha between &periodo_ant.*100+a.CORTE +1 and &periodo.*100+a.CORTE -1
then 1 else 0 end )  as A_F_SEG,

min(case when d.cuenta is not null
and d.fecha between &periodo_ant.*100+a.CORTE +1 and &periodo.*100+a.CORTE -1 then d.fecha end) as FEC_A_F_seg,

max(case when b.cuenta is not null
and b.fecha >= &periodo.*100+a.CORTE +1 
then 1 else 0 end )  as D_F_TDA,

min(case when b.cuenta is not null
and b.fecha >=&periodo.*100+a.CORTE +1 then b.fecha end) as FEC_D_F_TDA,

max(case when c.cuenta is not null
and c.fecha >= &periodo.*100+a.CORTE +1 
then 1 else 0 end )  as D_F_SPOS,

min(case when c.cuenta is not null
and c.fecha >=&periodo.*100+a.CORTE +1 then c.fecha end) as FEC_D_F_SPOS,

max(case when d.cuenta is not null
and d.fecha >= &periodo.*100+a.CORTE +1 
then 1 else 0 end )  as D_F_SEG,

min(case when d.cuenta is not null
and d.fecha>= &periodo.*100+a.CORTE +1 then d.fecha end) as FEC_D_F_SEG

from base1 as a 
left join (select * from  TDA where fecha>=20210416) as b
on(a.cuenta=b.cuenta) and (a.centalta=b.centalta)

left join (select * from  SPOS where fecha>=20210416) as c
on(a.cuenta=c.cuenta) and (a.centalta=c.centalta)

left join (select * from  SEGUROS where fecha>=20210416) as d
on(a.cuenta=d.cuenta) and (a.centalta=d.centalta)


group by 
a.cuenta,
a.centalta
;QUIT;




proc sql;
create table base3 as 
select distinct 
RUT	,
CODENT,
CENTALTA,
CUENTA,
FECALTA_CTTO,
FECBAJA_CTTO,
PRODUCTO,
SUBPRODU,
CONPROD,
GRUPOLIQ,
INDBLQOPE,
CORTE,
max(case when A_F_TDA+A_F_SPOS+	A_F_SEG>0 then 1 else 0 end) as USO_ANTES_FACT,
min(FEC_A_F_TDA,
FEC_A_F_SPOS,
FEC_A_F_seg) as FEC_ANTES_FACT,
max(case when D_F_TDA+D_F_SPOS+D_F_SEG>0 then 1 else 0 end) as USO_DES_FACT,
min(FEC_D_F_TDA,
FEC_D_F_SPOS,
FEC_D_F_seg) as FEC_DES_FACT
from base2
group by 

CENTALTA,
CUENTA

having calculated USO_ANTES_FACT=1 or calculated USO_DES_FACT=1
;QUIT;


proc sql;
create table base4 as 
select 
a.*,
cat('569',b.telefono) as telefono,
c.primer_nombre as nombre 
from base3 as a 
inner join publicin.fonos_movil_final as b
on(a.rut=b.clirut)
inner join publicin.base_nombres as c
on(a.rut=c.rut)
left join publicin.lnegro_car as d
on(a.rut=d.rut)
left join publicin.lnegro_sms as e
on(a.rut=e.rut)
where 
d.rut is null and e.rut is null
;QUIT;


PROC SQL;
   CREATE TABLE WORK.base5 AS 
   SELECT distinct t1.RUT, 
          t1.CORTE, 
          t1.USO_ANTES_FACT, 
          t1.FEC_ANTES_FACT, 
          t1.USO_DES_FACT, 
          t1.FEC_DES_FACT, 
          t1.telefono, 
          t1.nombre
      FROM WORK.BASE4 t1
where t1.INDBLQOPE='N'
;QUIT;


%if (%sysfunc(exist(&libreria..sms_comunicA_totalero2))) %then %do;
 
%end;
%else %do;
PROC  SQL;
CREATE TABLE &libreria..sms_comunicA_totalero2 (
periodo num,
fec_envio num,
RUT	num,
CORTE num,
USO_ANTES_FACT  num,
FEC_ANTES_FACT  num,
USO_DES_FACT  num,
FEC_DES_FACT  num,
telefono char(99),
nombre char(99),
comunicado_antes num,
comunicado_despues num
)
;QUIT;
%end;


 proc sql;
 create table fin as 
select 
 rut,
 max(comunicado_antes) as comunicado_antes,
max(comunicado_despues) as comunicado_despues
from  &libreria..sms_comunicA_totalero2
where periodo in (&periodo.,&periodo_ant.)
group by rut
;QUIT;


proc sql;
create table base6 as 
select 
a.*,
coalesce(b.comunicado_antes,0) as comunicado_antes,
coalesce(b.comunicado_despues,0) as comunicado_despues
from base5 as a 
left join fin as b
on(a.rut=b.rut)
;QUIT;


proc sql noprint inobs=1;
select 
year(today())*10000+month(today())*100+day(today()) as hoy
into: hoy
from pmunoz.codigos_capta_cdp
;QUIT;

%put &hoy;

proc sql;
create table base7 as
select
*,
case when comunicado_antes=0 and USO_ANTES_FACT=1 and corte<&hoy.-floor(&hoy./100)*100 then 'COMUNICAR_ANTES' else 'NULL' end as antes,
case when comunicado_despues=0 and USO_DES_FACT=1 and   corte<&hoy.-floor(&hoy./100)*100 then 'COMUNICAR_DESPUES' else 'NULL' end as despues 
from base6 
;QUIT;




proc sql;
create table base8 as 
select distinct *
from base7 

;QUIT;

proc sql noprint;
select distinct 
weekday(today()) as dia_semana
into:dia_semana
from pmunoz.codigos_capta_cdp
;QUIT;

%let dia_semana=&dia_semana;

%macro ejecutar;
%if %eval(&dia_semana=2) %then %do;

proc sql ;
create table base_fin as 
select 
RUT,
CORTE,
USO_ANTES_FACT,
FEC_ANTES_FACT,
USO_DES_FACT,
FEC_DES_FACT,
telefono,
nombre,
0 as comunicado_antes,
1 as comunicado_despues

from base8
where USO_ANTES_FACT=1	 and USO_DES_FACT=1	 and comunicado_antes>0	 and comunicado_despues=0
and despues=
'COMUNICAR_DESPUES'

union 
select 
RUT,
CORTE,
USO_ANTES_FACT,
FEC_ANTES_FACT,
USO_DES_FACT,
FEC_DES_FACT,
telefono,
nombre,
0 as comunicado_antes,
1 as comunicado_despues
from base8 
where USO_ANTES_FACT=0 and	USO_DES_FACT=1	 and comunicado_antes=0 and	comunicado_despues=0
and despues=
'COMUNICAR_DESPUES'
union select 
RUT,
CORTE,
USO_ANTES_FACT,
FEC_ANTES_FACT,
USO_DES_FACT,
FEC_DES_FACT,
telefono,
nombre,
1 as comunicado_antes,
0 as comunicado_despues

from base8 
where 
USO_ANTES_FACT=1 and  USO_DES_FACT=0 and comunicado_antes=0 and  comunicado_despues=0 and antes='NULL' and  despues='NULL' 
  and FEC_ANTES_FACT between year(today()-3)*10000+month(today()-3)*100+day(today()-3) and 
year(today()-1)*10000+month(today()-1)*100+day(today()-1)
;QUIT;

%end;
%else %do;
proc sql ;
create table base_fin as 
select 
RUT,
CORTE,
USO_ANTES_FACT,
FEC_ANTES_FACT,
USO_DES_FACT,
FEC_DES_FACT,
telefono,
nombre,
0 as comunicado_antes,
1 as comunicado_despues

from base8
where USO_ANTES_FACT=1	 and USO_DES_FACT=1	 and comunicado_antes>0	 and comunicado_despues=0
and despues=
'COMUNICAR_DESPUES'

union 
select 
RUT,
CORTE,
USO_ANTES_FACT,
FEC_ANTES_FACT,
USO_DES_FACT,
FEC_DES_FACT,
telefono,
nombre,
0 as comunicado_antes,
1 as comunicado_despues
from base8 
where USO_ANTES_FACT=0 and	USO_DES_FACT=1	 and comunicado_antes=0 and	comunicado_despues=0
and despues=
'COMUNICAR_DESPUES'
union select 
RUT,
CORTE,
USO_ANTES_FACT,
FEC_ANTES_FACT,
USO_DES_FACT,
FEC_DES_FACT,
telefono,
nombre,
1 as comunicado_antes,
0 as comunicado_despues

from base8 
where 
USO_ANTES_FACT=1 and USO_DES_FACT=0 and comunicado_antes=0 and comunicado_despues=0 and antes='NULL'
and despues='NULL' and FEC_ANTES_FACT in (&Periodo_dia);
/*(year(today()-1)*10000+month(today()-1)*100+day(today()-1)) ;*/
QUIT;
%end;
%mend ejecutar;
%ejecutar;

proc sql noprint ;
select distinct 
cats(&envio.,'MDPINF') as CAMPCODE
into:CAMPCODE
from pmunoz.codigos_capta_cdp
;QUIT;

%let CAMPCODE=&CAMPCODE;


%let USUARIO 	= PMUNOZ;

%let MI_CORREO 	= pmunozc@bancoripley.com;
%let CAMPANA 	= SMS_EPU_TOTALERO;
%let CAMP_AREA 	= MEDIOS DE PAGO;
%let CAMP_PROD 	= INF;
%let BASE_LIB	= work.;
%let BASE_TAB	= base_fin;

%put &USUARIO;		%put &CAMPCODE;		%put &MI_CORREO;		%put &CAMPANA;		
%put &CAMP_AREA;	%put &CAMP_PROD;	%put &BASE_LIB;			%put &BASE_TAB;

OPTIONS VALIDVARNAME=ANY;

DATA _null_;
hoy= compress(tranwrd(put(INTNX('DAY',today() , 0),mmddyy10.),"-",""));
Call symput("fecha", hoy);
RUN;
%put &fecha;

proc sql;
Create table UNICA_CARGA_CAMP_SMS (
	'CAMPANA-CAMPCODE'n 			CHAR(200), 		/* OBLIGATORIO SMS / PUSH / EMAIL */
	'CAMPANA-AREA'n 				CHAR(200), 		/* SMS / PUSH / EMAIL */
	'CAMPANA-PRODUCTO'n 			CHAR(200), 		/* SMS / PUSH / EMAIL */
	'CAMPANA-CAMPANA'n 				CHAR(200), 		/* OBLIGATORIO SMS / PUSH / EMAIL */
	'CAMPANA-FECHA'n 				CHAR(38), 		/* SMS / PUSH / EMAIL */
	'CAMPANA-CUSTOMERID'n 			NUMERIC(38),	/* SMS / PUSH / EMAIL */
	'CLIENTE-NOMBRE'n 				CHAR(50), 		/* SMS / EMAIL */
	'CAMPANA-CANAL'n 				CHAR(50), 		/* SMS / PUSH / EMAIL */
	'CLIENTE-TELEFONO_MOVIL'n 		CHAR(200),		/* SMS */
	'CAMPANA-ID_USUARIO'n 			NUMERIC(38),	/* OBLIGATORIO SMS / PUSH / EMAIL */
	'CLIENTE-ID_USUARIO'n 			NUMERIC(38),	/* OBLIGATORIO SMS / PUSH / EMAIL */
	'CAMPANA-IND_RUT_DUP_CAMP'n 	NUMERIC(38),	/* OBLIGATORIO SMS / PUSH / EMAIL */
	'CLIENTE-SMS_CONSENT_STATUS'n 	CHAR(200)		/* OBLIGATORIO SMS */
)
;quit;

/* BASE DE ORIGEN */
DATA _null_;
BASE = CAT("&BASE_LIB","&BASE_TAB");
Call symput("var_BASE", BASE);
RUN;

%put &var_BASE;

/* INSERT CAMPAÑA --> EMAIL */
proc sql NOPRINT;
INSERT INTO UNICA_CARGA_CAMP_SMS
('CAMPANA-CAMPCODE'n, 'CAMPANA-AREA'n, 'CAMPANA-PRODUCTO'n, 'CAMPANA-CAMPANA'n, 'CAMPANA-FECHA'n, 'CAMPANA-CUSTOMERID'n, 'CLIENTE-NOMBRE'n, 'CAMPANA-CANAL'n, 'CLIENTE-TELEFONO_MOVIL'n, 'CAMPANA-ID_USUARIO'n, 'CLIENTE-ID_USUARIO'n, 'CAMPANA-IND_RUT_DUP_CAMP'n,'CLIENTE-SMS_CONSENT_STATUS'n)
SELECT DISTINCT "&CAMPCODE.", "&CAMP_AREA.", "&CAMP_PROD.", "&CAMPANA.",  "&FECHA.", RUT, NOMBRE, 'SMS', telefono, RUT, RUT, 0, 'OPTED-IN'
from &var_BASE;
;quit;

/*	EXPORT --> Generación archivo CSV */
PROC EXPORT DATA = UNICA_CARGA_CAMP_SMS
OUTFILE="/sasdata/users94/user_bi/unica/input/INPUT-TR_CAMPANAS-&USUARIO..csv"
DBMS=dlm REPLACE;
delimiter=',';
PUTNAMES=YES;
RUN;

PROC SQL;
CREATE TABLE COUNT_DE_TABLA_TMP AS
SELECT COUNT('CAMPANA-ID_CLIENTE') AS CANTIDAD_DE_REGISTROS_CARGADOS
from UNICA_CARGA_CAMP_SMS
;QUIT;

/* IDENTIFICADOR PARA EL EQUIPO CAMPAÑAS */
DATA _null_;
ID = CAT("&CAMPCODE",' - ',"&CAMPANA");
Call symput("var_ID_CAMP", ID);
RUN;

%put &var_ID_CAMP;

/* ENVÍO DE CORREO CON MAIL VARIABLE */
proc sql noprint;
SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ_CAMP';
SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA_CAMP';
SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CAMP_1';
SELECT EMAIL into :DEST_7 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CAMP_2';
quit;

%put &=EDP_BI; %put &=DEST_1; %put &=DEST_2; %put &=DEST_6;%put &=DEST_7;

FILENAME output EMAIL
SUBJECT = "MAIL_AUTOM: Campaña depositada: &var_ID_CAMP."
FROM = ("&EDP_BI")
TO = ("&DEST_6","&DEST_7")
CC = ("&DEST_1","&DEST_2","&MI_CORREO",'poportusg@bancoripley.com')
CT= "text/html" ;
ODS HTML
BODY=output
style=sasweb;
ods escapechar='~';
title1 "Estimados:";
title2 font='helvetica/italic' height=10pt
"
Les informo que se ha depositado archivo de campaña:
~n
~n
IDENTIFICADOR: &var_ID_CAMP
~n
~n
Ruta: /sasdata/users94/user_bi/unica/input/INPUT-TR_CAMPANAS-&USUARIO..csv
~n
~n
~n
~n
Saludos
Atte.
&USUARIO.
~n
~n
";
PROC REPORT DATA=COUNT_DE_TABLA_TMP NOWD
STYLE(REPORT)=[PREHTML="<hr>"];
RUN;
ODS HTML CLOSE;
/* ==================================| FIN CODIGO NUEVO |==================================*/

proc sql;
insert into &libreria..sms_comunicA_totalero2 
select 
&periodo. as periodo,
year(today())*10000+month(today())*100+day(today())  as fec_envio,
*
from base_fin
;QUIT;

proc sql;
drop table cuentas;
drop table base_totaleros;
drop table tda;
drop table spos;
drop table seguros;
drop table base1;
drop table base2;
drop table base3;
drop table base4;
drop table base5;
drop table fin;
drop table base6;
drop table base7;
drop table base8;
drop table base_fin;
;QUIT;

%mend sms_totalero_diario;
%sms_totalero_diario;
