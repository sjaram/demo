/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	NORMALIZAR_COMERCIOS		================================*/
/* CONTROL DE VERSIONES
/* 2021-01-26 -- V6 -- Actualizada por Pedro.	
/* 2020-10-23 -- V5 -- Actualizada por Ale.				
/* 2020-10-23 -- V4 -- Ale Marinao. --  
					-- Versión Original
/* INFORMACIÓN:
	Reporte homologa los Nombres de los comercios bajo una misma glosa, con el fin de poder agrupar 
	comercios dentro de cada Rubro y ver potenciales alianzas y/o saber cual o cuales comercios 
	esta caído en venta. Para poder comparar la venta lo ideal es dejar Mes Actual, Mes Anterior y 
	mismos meses del año anterior. 

	(IN) Tablas requeridas o conexiones a BD:
	- publicin.SPOS_aut_&periodo.
	- publicin.spos_aut_&per.
	- sbarrera.CODIGOS_ONLINE_SPOS
	- sbarrera.TABLA_ARBOL
	- AMARINAO.CONSOLIDADO_CODIGOS_MARCA
	- result.EDP_BI_DESTINATARIOS
	- DB_BOLRG		(EHENRIQUEZA)

	(OUT) Tablas de Salida o resultado:
	- RESULT.Normalizacion_Comercios_U3M
	- ORACLOUD
*/

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

%let n=0; /*indica el primeriodo que se tomara y se contara hasta -2 periodos hacia atras*/
%let libreria=result;



%put===========================================================================================;
%put [A] BORRAR TABLA DE PASO;
%put===========================================================================================;


proc sql;
drop table &libreria..Normalizacion_Comercios_U3M
;QUIT;

%put===========================================================================================;
%put [B] MAXIMA FECHA DE VENTA ENCONTRADA;
%put===========================================================================================;

DATA _null_;
periodo = input(put(intnx('month',today(),-&n.,'end'),yymmn6. ),$10.);
periodo_ant = input(put(intnx('month',today(),-&n.-1,'end'),yymmn6. ),$10.);
periodo_12ant = input(put(intnx('month',today(),-&n.-12,'end'),yymmn6. ),$10.);

INI = input(put(intnx('month',today(),-&n.,'begin'),date9. ),$10.);
INI_ant = input(put(intnx('month',today(),-&n.-1,'begin'),date9. ),$10.);
INI_12ant = input(put(intnx('month',today(),-&n.-12,'begin'),date9. ),$10.);

FIN = input(put(intnx('month',today(),-&n.,'end'),date9. ),$10.);
FIN_ant = input(put(intnx('month',today(),-&n.-1,'end'),date9. ),$10.);
FIN_12ant = input(put(intnx('month',today(),-&n.-12,'end'),date9. ),$10.);

Call symput("periodo", periodo);
Call symput("periodo_ant", periodo_ant);
Call symput("periodo_12ant", periodo_12ant);

Call symput("INI", INI);
Call symput("INI_ant", INI_ant);
Call symput("INI_12ant", INI_12ant);

Call symput("FIN", FIN);
Call symput("FIN_ant", FIN_ant);
Call symput("FIN_12ant", FIN_12ant);


RUN;
%put &periodo;
%put &periodo_ant;
%put &periodo_12ant;

%put &INI;
%put &INI_ant;
%put &INI_12ant;

%put &FIN;
%put &FIN_ant;
%put &FIN_12ant;




%put===========================================================================================;
%put [01] Sacar Venta de TC desde SPOS_AUT;
%put===========================================================================================;

%put-------------------------------------------------------------------------------------------;
%put [01.1] Extraccion de Venta (con marca de nacional/internacional);
%put-------------------------------------------------------------------------------------------;

proc sql;
create table vta_spos_tc 
(periodo num ,
fecha num ,
Tipo_Tarjeta char(99),
rut num ,
CODACT num ,
Actividad_Comercio char(99),
Nombre_Comercio char(99),
Monto num , 
Codigo_Comercio num , 
SI_Nacional num,
si_online num )
;QUIT;

%macro ejecutar(periodo);

%if %eval(&periodo.<202006) %then %do;

proc sql;
CREATE TABLE paso AS
select 
&periodo. as periodo,
fecha,
Tipo_Tarjeta,
rut,
CODACT,
Actividad_Comercio,
Nombre_Comercio,
Venta_Tarjeta as Monto, 
Codigo_Comercio, 
case when CODPAIS=152 then 1 else 0 end as SI_Nacional
from publicin.SPOS_aut_&periodo.
;QUIT;

proc sql;
create table codigos_online as 
select distinct Codigos_Online
from sbarrera.CODIGOS_ONLINE_SPOS
;QUIT;

proc sql;
insert into  Vta_SPOS_TC 
select 
a.periodo,
a.fecha,
a.Tipo_Tarjeta,
a.rut,
a.CODACT,
a.Actividad_Comercio,
a.Nombre_Comercio,
a.Monto, 
a.Codigo_Comercio, 
a.SI_Nacional,
case when b.Codigos_Online is not null then 1 else 0 end as si_online
from paso as a
left join codigos_online as b
on(a.Codigo_Comercio=b.Codigos_Online)
;QUIT;

proc sql;
DROP TABLE PASO;
;QUiT;

%end;
%else %do;


proc sql;
insert  into Vta_SPOS_TC 
select 
&periodo. as periodo,
fecha,
Tipo_Tarjeta,
rut,
CODACT,
Actividad_Comercio,
Nombre_Comercio,
Venta_Tarjeta as Monto, 
Codigo_Comercio, 
case when CODPAIS=152 then 1 else 0 end as SI_Nacional,
si_digital as si_online
from publicin.SPOS_aut_&periodo.
;QUIT;

proc sql;
insert  into Vta_SPOS_TC 
select 
&periodo. as periodo,
fecha,
Tipo_Tarjeta,
rut,
CODACT,
Actividad_Comercio,
Nombre_Comercio,
Venta_Tarjeta as Monto, 
Codigo_Comercio, 
case when CODPAIS=152 then 1 else 0 end as SI_Nacional,
si_digital as si_online
from publicin.SPOS_MCD_&periodo.
;QUIT;

%end;

%mend ejecutar;

%ejecutar(&periodo.);
%ejecutar(&periodo_ant.);
%ejecutar(&periodo_12ANT.);

%put-------------------------------------------------------------------------------------------;
%put [01.2] Pegar Rubro correspondiente &periodo;
%put-------------------------------------------------------------------------------------------;

proc sql;
create table TABLA_ARBOL as  
select 
COD_ACT,
max(CATEGORIAS_RIPLEY) as RUBRO_GESTION
from sbarrera.TABLA_ARBOL /*Tabla de asignacion de rubros*/
group by 
COD_ACT
;QUIT;


PROC SQL;
CREATE INDEX COD_ACT ON work.TABLA_ARBOL (COD_ACT)
;QUIT;

PROC SQL;
CREATE INDEX CODACT ON work.Vta_SPOS_TC (CODACT)
;QUIT;

proc sql;
create table work.Vta_SPOS_TC1 as 
select 
a.Periodo,
a.Fecha,
a.Tipo_Tarjeta,
a.rut,
Actividad_Comercio,
a.Nombre_Comercio,
a.SI_Nacional,
a.si_online,
a.Monto,
a.Codigo_Comercio,  
coalesce(b.RUBRO_GESTION,'Otros Rubros SPOS') as Rubro 
from work.Vta_SPOS_TC as a 
left join TABLA_ARBOL as b 
on (a.CODACT=b.COD_ACT) 
;quit;


%put===========================================================================================;
%put [02] Sacar Venta de TD desde DEM &periodo;
%put===========================================================================================;


proc sql;
create table codigos_online as 
select distinct Codigos_Online
from sbarrera.CODIGOS_ONLINE_SPOS
;QUIT;

%put-------------------------------------------------------------------------------------------;
%put [02.1] Extraccion de Venta (con marca de nacional/internacional) &periodo;
%put-------------------------------------------------------------------------------------------;

/*Conexion para el DEM*/

%let path_ora        = '(DESCRIPTION = (ADDRESS_LIST = (ADDRESS =  (PROTOCOL = TCP) (Host = reporteslegales-bd.bancoripley.cl)        (Port = 1521)      )    )    (CONNECT_DATA =       (SID = BORLG)    )  ) '; 
%let user_ora      = 'EHENRIQUEZA'; 
%let pass_ora      = 'ehe3012';
%let Schema_ora         = 'VERGARAM';
%let conexion_ora    = ORACLE PATH=&path_ora. Schema=&Schema_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 
LIBNAME DB_BOLRG     &conexion_ora. insertbuff=10000 readbuff=10000;  

/*Generar Tabla*/

proc sql;
create table work.Vta_SPOS_TD as 
select
year(datepart(a.FECHORA_TRANSAC))*100+month(datepart(a.FECHORA_TRANSAC)) as PERIODO,
year(datepart(a.FECHORA_TRANSAC))*10000+month(datepart(a.FECHORA_TRANSAC))*100+day(datepart(a.FECHORA_TRANSAC)) as fecha,
input(SUBSTR(CTACTE_TITULAR,7,LENGTH(CTACTE_TITULAR)),best.) as cuenta,
'TD' as Tipo_Tarjeta,
1 as SI_Nacional, /*todas las transacciones de DEM son nacionales*/
a.COD_RUBRO_NAC,
DESC_RUBRO as Actividad_Comercio,
a.NOMBRE_FAN_COMERCIO as Nombre_comercio,
a.MONTO_1 as Monto, 
input(COD_COMERCIO_POS,best.) as Codigo_Comercio
FROM DB_BOLRG.TABLA_DEM as a 
WHERE a.COD_COMERCIO_DEB<>83382700 /*solo spos, si es iguAL es solo tienda*/ 
and (a.FECHORA_TRANSAC between "&INI.:00:00:00"dt and "&FIN.:00:00:00"dt
or a.FECHORA_TRANSAC between "&INI_ant.:00:00:00"dt and "&FIN_ant.:00:00:00"dt
or a.FECHORA_TRANSAC between "&INI_12ant.:00:00:00"dt and "&FIN_12ant.:00:00:00"dt)
;quit;

%let path_ora      = '(DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SID = ripleyc)))'; 
%let user_ora      = 'RIPLEYC'; 
%let pass_ora      = 'ri99pley';
%let conexion_ora  = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 
  

PROC SQL  NOERRORSTOP;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );

create table vigente  as
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
WHEN b.VIS_PRO=40 THEN 'LCA' END  DESCRIP_PRODUCTO,

CASE WHEN b.vis_status ='9' THEN 'cerrado' 
when b.vis_status ='2' then 'vigente' end as estado_cuenta,
/*c.DES_CODTAB,*/
c.DES_CODIGO COD_CIERRE_CONTRATO,
c.DES_DESCRIPCION DESC_CIERRE_CONTRATO,
d.STA_DESCRIPCION desc_est_cuenta
 
from  tcap_vista  b 
inner join  tcli_persona   a
on(a.cli_codigo=b.vis_codcli) 

left join tgen_desctabla  c
on(b.VIS_CODTAB=c.DES_CODTAB) and 	(b.VIS_CAUCIERR=c.DES_CODIGO)
left join tgen_status d
on(b.vis_status=d.STA_CODIGO) and (d.STA_MOD=4)

where 
b.vis_mod=4
and (b.VIS_PRO=4 or b.VIS_PRO=40)
and b.vis_tip=1  
/*AND (b.vis_status='2' or b.vis_status='9') */
) ;
disconnect from ORACLE;
QUIT;


proc sql;
create table rubro as 
select 
COD_RUB,
max(CATEGORIAS_RIPLEY) as RUBRO_GESTION 
from sbarrera.TABLA_ARBOL /*Tabla de asignacion de rubros*/
group by 
COD_RUB
;QUIT;

PROC SQL;
CREATE INDEX cuenta ON work.Vta_SPOS_TD (cuenta)
;QUIT;

PROC SQL;
CREATE INDEX cuenta ON work.vigente (cuenta)
;QUIT;

proc sql;
create table Vta_SPOS_TD2 as 
select 
a.periodo,
a.fecha,
a.Tipo_Tarjeta,
a.SI_Nacional, /*todas las transacciones de DEM son nacionales*/
case when c.codigos_online is not null then 1 else 0 end as SI_online,
a.COD_RUBRO_NAC,
a.Actividad_Comercio,
a.Nombre_Comercio, 
a.Monto, 
a.Codigo_Comercio,
coalesce(b.rut,0) as rut
from Vta_SPOS_TD as a
left join vigente as b
on(a.cuenta=b.cuenta)
left join codigos_online as c
on(a.codigo_comercio=c.codigos_online)
;quit;

PROC SQL;
CREATE INDEX COD_RUBRO_NAC ON work.Vta_SPOS_TD2 (COD_RUBRO_NAC)
;QUIT;

PROC SQL;
CREATE INDEX COD_RUB ON work.rubro (COD_RUB)
;QUIT;

proc sql;
create table Vta_SPOS_TD3 as 
select 
a.*,
coalesce(c.RUBRO_GESTION,'Otros Rubros SPOS') as rubro
from Vta_SPOS_TD2 as a
left join rubro as c
on (a.COD_RUBRO_NAC=c.COD_RUB)
;QUIT;


proc sql;
CREATE TABLE Vta_SPOS AS
select 
Periodo  ,
Fecha ,
Tipo_Tarjeta ,
rut  ,
SI_Nacional ,
si_online,
Actividad_Comercio,
Nombre_Comercio,
Monto  ,
Codigo_Comercio ,  
Rubro 
from Vta_SPOS_TC1
;quit;

proc sql;
insert into Vta_SPOS
select 
Periodo  ,
Fecha ,
Tipo_Tarjeta ,
rut  ,
SI_Nacional ,
si_online,
Actividad_Comercio,
Nombre_Comercio,
Monto  ,
Codigo_Comercio ,  
Rubro 
from Vta_SPOS_TD3
;quit;


%put===========================================================================================;
%put [04] Pegar Marcas &periodo;
%put===========================================================================================;


%put-------------------------------------------------------------------------------------------;
%put [04.1] Marcas  &periodo;
%put-------------------------------------------------------------------------------------------;

proc sql;
create table work.Vta_SPOS2 as 
select 
*,
CASE WHEN RUBRO in ('SERVICIOS','SERVICIOS BASICOS','TRANSPORTE') THEN 'Servicios'
WHEN RUBRO IN  ('OTROS COMERCIOS','Otros Rubros SPOS','BELLEZA') THEN 'Otros Comercios'
WHEN RUBRO IN ('VIAJES','ENTRETENCION') THEN 'Viajes&Entretencion'
WHEN  RUBRO IN ('ALIMENTACION Y FAST FOOD','RESTAURANTES') THEN 'Alimentacion'
WHEN RUBRO IN ('RECAUDACION SECTOR PUBLICO','RECAUDACION','INSTITUCIONES FINANCIERAS') THEN 'Recaudacion&Inst_Finan'
ELSE RUBRO END AS RUBRO2,
mdy(mod(int(fecha/100),100),mod(fecha,100),int(fecha/10000)) format=date9. as fecha_tableau
from work.Vta_SPOS 
;quit;


proc sql;
create table work.Vta_SPOS3 as 
select 
*,
day(fecha_tableau) as dia_nro,
weekday(fecha_tableau) as dia_glosa
from work.Vta_SPOS2
;quit;


%put-------------------------------------------------------------------------------------------;
%put [04.3] MARCA NOMBRE APPS &periodo;
%put-------------------------------------------------------------------------------------------;


PROC SQL;
CREATE TABLE Vta_SPOS4 AS
SELECT  
A.*,
CASE
WHEN (Actividad_Comercio='HOTELS/MOTELS/RESORTS' AND UPPER(Nombre_Comercio) LIKE '%AIRBNB%')  THEN 'AIRBNB'
WHEN Nombre_Comercio IN (SELECT Nombre_Comercio FROM SBARRERA.COMERCIOS_APPS_SPOS WHERE upper(Comercio_APP)='AIRBNB') THEN 'AIRBNB'
WHEN Codigo_Comercio IN (SELECT Codigo_Comercio FROM SBARRERA.COMERCIOS_APPS_SPOS_V2 WHERE upper(Comercio_APP)='AIRBNB') THEN 'AIRBNB'

WHEN UPPER(Nombre_Comercio) LIKE 'GOOGLE *ALIEN %'	THEN 'OTRO'
WHEN UPPER(Nombre_Comercio) LIKE 'ALIEXPRES%' THEN 'ALIEXPRES'
WHEN Nombre_Comercio IN (SELECT Nombre_Comercio FROM SBARRERA.COMERCIOS_APPS_SPOS WHERE upper(Comercio_APP)='ALIEXPRESS') THEN 'ALIEXPRES'
WHEN Codigo_Comercio IN (SELECT Codigo_Comercio FROM SBARRERA.COMERCIOS_APPS_SPOS_V2 WHERE upper(Comercio_APP)='ALIEXPRESS') THEN 'ALIEXPRES'


WHEN (CODIGO_COMERCIO IN (372452049888,
6172000156182,
57181000156182,
89047000762203,
196149000156182,
539601000001088,
244555000156182,
244559000156182,
273174000156182,
285182000762203,
160146000762203) 
AND (UPPER(A.Nombre_Comercio) LIKE '%AMAZON VIDEO%'
OR UPPER(A.Nombre_Comercio) LIKE '%AMAZON-VIDEO%'
OR UPPER(A.Nombre_Comercio) LIKE '%AMAZON_VIDEO%'
OR UPPER(A.Nombre_Comercio) LIKE '%AMAZONVIDEO%'

OR UPPER(A.Nombre_Comercio) LIKE '%AMAZON PRIME%'
OR UPPER(A.Nombre_Comercio) LIKE '%AMAZON-PRIME%'
OR UPPER(A.Nombre_Comercio) LIKE '%AMAZON_PRIME%'
OR UPPER(A.Nombre_Comercio) LIKE '%AMAZONPRIME%'

OR UPPER(A.Nombre_Comercio) LIKE '%AMZNPREMIUM%'

OR UPPER(A.Nombre_Comercio) LIKE '%AMZN PRIME%'
OR UPPER(A.Nombre_Comercio) LIKE '%AMZN-PRIME%'
OR UPPER(A.Nombre_Comercio) LIKE '%AMZN_PRIME%'
OR UPPER(A.Nombre_Comercio) LIKE '%AMZNPRIME%')) THEN 'AMAZON_PRIME'


WHEN (CODIGO_COMERCIO IN (7979112	,
7979128	,
8098225	,
34160597	,
345120163885	,
372176392887	,
372176393885	,
372181910889	,
372181913883	,
372452072880	,
372452074886	,
372730550889	,
372791170882	,
372791190880	,
372791240883	,
5602101000059	,
19291000156182	,
22518000156182	,
57186000156182	,
57193000156182	,
160146000762203	,
182571000156182	,
185119000762203	,
190099000156182	,
194651000156182	,
206838000156182	,
206887000156182	,
206937000156182	,
217574000156182	,
219937000762203	,
221312000156182	,
221331000156182	,
221336000156182	,
221355000156182	,
221360000156182	,
221405000156182	,
221410000156182	,
221437000156182	,
221455000156182	,
222288000156182	,
222297000156182	,
222339000156182	,
222351000156182	,
227431000156182	,
227456000156182	,
227497000156182	,
228894000156182	,
228895000156182	,
235152000762203	,
235251000762203	,
235726000762203	,
243421000762203	,
244531000762203	,
246071000762203	,
249204000762203	,
270595000762203	,
273141000156182	,
273176000156182	,
274489000156182	,
350646000156182	,
350676000156182	,
350862000156182	,
350865000156182	,
351481000762203	,
372638000156182	,
517649000200578	,
539601000002714	,
554261000156182	,
784959000762203	,
847566000156182	,
878918000156182,
980021563997) 
AND (UPPER(A.Nombre_Comercio) LIKE '%AMAZON%'
OR UPPER(A.Nombre_Comercio) LIKE '%AMZN%'
OR UPPER(A.Nombre_Comercio) LIKE '%AMZ%')) THEN 'AMAZON'

WHEN (Actividad_Comercio IN ('SVCS - DEFAULT','TRANSPORTATION SVCS - DEFAULT','TAXICABS/LIMOUSINES') AND UPPER(Nombre_Comercio) LIKE 'BEAT%')  THEN 'BEAT'
WHEN (Actividad_Comercio IN ('SVCS - DEFAULT','TRANSPORTATION SVCS - DEFAULT','TAXICABS/LIMOUSINES') AND UPPER(Nombre_Comercio) LIKE 'TAXIBEAT%')  THEN 'BEAT'
WHEN UPPER(Nombre_Comercio) LIKE 'TAXIBEAT%'  THEN 'BEAT'
WHEN UPPER(Nombre_Comercio) LIKE 'TAXI BEAT%'  THEN 'BEAT'

WHEN (Actividad_Comercio IN (
'HOTELS/MOTELS/RESORTS',
'TOURIST ATTRACTIONS AND XHBT',
'TRAVEL AGENCIES',
'AUTOMOBILE RENTAL AGENCY',
'REAL EST AGNTS Y MGRS RENTALS',
'TAXICABS/LIMOUSINES',
'AUTOMOBILE RENTAL AGENCY',
'COMBINATION CATALOG Y RETAIL',
'RESTAURANTS',
'CONSUMER CR REPORTING AGEN') AND UPPER(Nombre_Comercio) LIKE '%BOOKING%') THEN 'BOOKING'

WHEN (Actividad_Comercio IN ('LOCAL COMMUTER TRANSPORT','PROFESSIONAL SERVICES - DEF','TAXICABS/LIMOUSINES','TRANSPORTATION SVCS - DEFAULT','VARIOS MERCANCIA GENERAL') AND UPPER(Nombre_Comercio)= 'CABIFY')  THEN 'CABIFY'
WHEN CODIGO_Comercio IN (SELECT DISTINCT codigo_comercio FROM RESULT.CODCOM_CAMPS_SPOS WHERE UPPER(Marca_Campana)= 'CABIFY') THEN 'CABIFY'


WHEN Codigo_Comercio IN (31637929) THEN 'CORNERSHOP'
WHEN Codigo_Comercio IN (32812465,33450095,445354337997) AND UPPER(Nombre_Comercio) LIKE 'CORNER%' THEN 'CORNERSHOP'

WHEN (Actividad_Comercio IN ('TAXICABS/LIMOUSINES','SECURITIES BROKERS/DEALERS','GEN CONTRACTORS RESIDENTL/COML') 
AND (UPPER(Nombre_Comercio) LIKE '%DIDI%' OR UPPER(NOMBRE_COMERCIO) LIKE '%DIDI %'))  THEN 'DIDI'


WHEN (Actividad_Comercio IN ('CABLE, SAT, PAY TV/RADIO SVCS') AND UPPER(A.Nombre_Comercio) LIKE '%DIRECTVGO%') THEN 'DIRECTVGO'
WHEN (Actividad_Comercio IN ('CABLE, SAT, PAY TV/RADIO SVCS') AND UPPER(A.Nombre_Comercio) LIKE '%DIRECTV%') THEN 'DIRECTV'


WHEN (Actividad_Comercio IN ('ADVERTISING SERVICES') AND UPPER(Nombre_Comercio) LIKE 'FACEBK%') THEN 'FACEBOOK'
WHEN (Actividad_Comercio IN ('ADVERTISING SERVICES') AND UPPER(Nombre_Comercio) LIKE 'FACEBOOK %') THEN 'FACEBOOK'
WHEN (Actividad_Comercio IN ('ADVERTISING SERVICES') AND UPPER(Nombre_Comercio) LIKE 'FACEBOOK%') THEN 'FACEBOOK'
WHEN Nombre_Comercio IN (SELECT DISTINCT Nombre_Comercio FROM SBARRERA.COMERCIOS_APPS_SPOS WHERE Comercio_APP='FACEBOOK') THEN 'FACEBOOK'
WHEN Codigo_Comercio IN (SELECT DISTINCT Codigo_Comercio FROM SBARRERA.COMERCIOS_APPS_SPOS_V2 WHERE Comercio_APP='FACEBOOK') THEN 'FACEBOOK'

WHEN (Actividad_Comercio IN ('TAXICABS/LIMOUSINES','COMPUTER SOFTWARE STORES') AND UPPER(Nombre_Comercio) LIKE 'FROG SCOOTERS%') THEN 'FROG'
WHEN (Actividad_Comercio IN ('TAXICABS/LIMOUSINES','COMPUTER SOFTWARE STORES') AND UPPER(Nombre_Comercio) LIKE 'FROG SCOOTERS %') THEN 'FROG'


WHEN UPPER(Nombre_Comercio) LIKE 'GOOGLE*%'  THEN 'GOOGLE'
WHEN UPPER(Nombre_Comercio) LIKE 'GOOGLE *%'  THEN 'GOOGLE'
WHEN UPPER(Nombre_Comercio) LIKE 'GOOGLE %'  THEN 'GOOGLE'
WHEN Nombre_Comercio IN (SELECT Nombre_Comercio FROM SBARRERA.COMERCIOS_APPS_SPOS WHERE Comercio_APP='GOOGLE') THEN 'GOOGLE'
WHEN Codigo_Comercio IN (SELECT Codigo_Comercio FROM SBARRERA.COMERCIOS_APPS_SPOS_V2 WHERE Comercio_APP='GOOGLE') THEN 'GOOGLE'


WHEN (Actividad_Comercio IN ('TRANSPORTATION SVCS - DEFAULT') AND UPPER(Nombre_Comercio) LIKE 'SANTA MONICA MO%') THEN 'GRIN'
WHEN (Actividad_Comercio IN (
'GEN CONTRACTORS RESIDENTL/COML',
'OTHER DIRECT MARKETERS',
'PROFESSIONAL SERVICES - DEF',
'SECURITIES BROKERS/DEALERS',
'TRANSPORTATION SVCS - DEFAULT'
) AND (UPPER(Nombre_Comercio) LIKE '%GRIN'
OR UPPER(NOMBRE_COMERCIO) LIKE '% GRIN')) THEN 'GRIN'


WHEN (Actividad_Comercio IN ('BUSINESS SERVICES - DEFAULT',
'CABLE, SAT, PAY TV/RADIO SVCS',
'COMPUTER PROGRAM/SYS DESIGN',
'CONTINUITY/SUBSCRIPTION MERCHT',
'DIGITAL GOODS ? MULTI-CATEGORY',
'DIGITAL GOODS ? SOFTWARE APPLI',
'DIGITAL GOODS?MEDIA, BOOKS, MO',
'DIGITAL GOODS ? GAMES'
) AND UPPER(Nombre_Comercio) IN ('GOOGLE *HBO DIG','GOOGLE*HBO DIGI','ROKU FOR HBO DI') ) THEN 'HBO'


WHEN (Actividad_Comercio IN ('RECORD STORES','DIGITAL GOODS?MEDIA, BOOKS, MO') AND UPPER(Nombre_Comercio) LIKE '%ITUNES%') THEN 'ITUNES'
WHEN (Actividad_Comercio IN ('RECORD STORES','DIGITAL GOODS?MEDIA, BOOKS, MO') AND UPPER(Nombre_Comercio) LIKE '%APPLE.COM/BILL%') THEN 'ITUNES'
WHEN Nombre_Comercio IN (SELECT Nombre_Comercio FROM SBARRERA.COMERCIOS_APPS_SPOS WHERE Comercio_APP='ITUNES') THEN 'ITUNES'
WHEN Codigo_Comercio IN (SELECT Codigo_Comercio FROM SBARRERA.COMERCIOS_APPS_SPOS_V2 WHERE Comercio_APP='ITUNES') THEN 'ITUNES'

WHEN CODIGO_Comercio=32078079 THEN 'OTRO'
WHEN CODIGO_Comercio IN (445525780992,445526855991,445528967992,445528969998,445564212998) THEN 'LIME'
WHEN (CODIGO_Comercio IN (980020310994) AND UPPER(Nombre_Comercio) LIKE 'PAYPAL *LIME %') THEN 'LIME'
WHEN (Actividad_Comercio IN ('RECREATION SERVICES','TRANSPORTATION SVCS - DEFAULT') AND UPPER(Nombre_Comercio) LIKE '%LIM%') THEN 'LIME'
WHEN (Actividad_Comercio IN ('COMPUTER SOFTWARE STORES') AND UPPER(Nombre_Comercio)= 'LIMEBIKE') THEN 'LIME'

WHEN (Actividad_Comercio IN (
'SECURITIES BROKERS/DEALERS',
'MISC PERSONAL SERV - DEF',
'COMPUTER MAINT/SVCS - DEF',
'COMPUTER SOFTWARE STORES',
'COMPUTERS/PERIPHERALS/SOFTWARE',
'FAST FOOD RESTAURANTS',
'HOTELS/MOTELS/RESORTS',
'OUTBOUND TELEMARKETING MERCHNT',
'PRECIOUS STONES/METALS/JEWELRY',
'SECURITIES BROKERS/DEALERS',
'SPORTING GOODS STORES',
'TAXICABS/LIMOUSINES',
'PROFESSIONAL SERVICES - DEF',
'OTHER DIRECT MARKETERS') AND UPPER(Nombre_Comercio) LIKE '%MERCADO PAGO%') THEN 'MERCADOPAGO'


WHEN (Actividad_Comercio IN ('LOCAL COMMUTER TRANSPORT') AND UPPER(Nombre_Comercio) LIKE 'MOBIKE%') THEN 'MOBIKE'

WHEN (Actividad_Comercio IN (
'CABLE, SAT, PAY TV/RADIO SVCS',
'COMPUTERS/PERIPHERALS/SOFTWARE',
'CONTINUITY/SUBSCRIPTION MERCHT',
'DIGITAL GOODS?MEDIA, BOOKS, MO',
'DIGITAL GOODS ? GAMES'
) AND (UPPER(Nombre_Comercio) LIKE '%NETFLIX%') ) THEN 'NETFLIX'

WHEN (CODIGO_COMERCIO IN (217000000144509,
527021000201451,
342478000144509,
145376000144509,
980020883990,
63975000144509,
342475000144509,
342476000144509

) AND UPPER(Nombre_Comercio) LIKE '%PLAYSTA%') THEN 'PLAYSTATION'

WHEN UPPER(NOMBRE_Comercio) LIKE '%PEDIDOSYA%' THEN 'PEDIDOSYA'

WHEN CODIGO_Comercio=28 THEN 'OTRO'
WHEN UPPER(NOMBRE_COMERCIO) LIKE '%TRAPPI%' THEN 'OTRO' 
WHEN (Actividad_Comercio IN ('RESTAURANTS') AND UPPER(Nombre_Comercio) IN ('LE TRAPPISTE') ) THEN 'OTRO'
WHEN (UPPER(Nombre_Comercio) LIKE '%RAPPI%') THEN 'RAPPI'
WHEN CODIGO_Comercio IN (SELECT DISTINCT codigo_comercio FROM RESULT.CODCOM_CAMPS_SPOS WHERE UPPER(Marca_Campana)='RAPPI') THEN 'RAPPI'


WHEN (Actividad_Comercio IN ('TRANSPORTATION SVCS - DEFAULT') AND UPPER(Nombre_Comercio) LIKE 'SCOOT%') THEN 'SCOOT'


WHEN (Actividad_Comercio IN (
'COMPUTER NETWORK/INFO SVCS',
'CONTINUITY/SUBSCRIPTION MERCHT',
'DIGITAL GOODS?MEDIA, BOOKS, MO',
'MISC SPECIALTY RETAIL'
) AND UPPER(Nombre_Comercio) LIKE '%SPOTIFY%') THEN 'SPOTIFY'


WHEN (Actividad_Comercio IN ('DIGITAL GOODS?MEDIA, BOOKS, MO','MISC SPECIALTY RETAIL') AND UPPER(Nombre_Comercio) LIKE '%TIDAL%' ) THEN 'TIDAL'


WHEN UPPER(Nombre_Comercio) LIKE 'AUBERGE%' THEN 'OTRO'
WHEN UPPER(Nombre_Comercio) LIKE 'UBERLINDA%' THEN 'OTRO'
WHEN (Actividad_Comercio IN ('TAXICABS/LIMOUSINES','RESTAURANTS') AND UPPER(Nombre_Comercio) IN ('LE FLAUBERT PRO','ORUBERRY','PAG*UberlanLuci','YUBERKA ALTAGRA')) THEN 'OTRO'
WHEN ((Actividad_Comercio IN ('TAXICABS/LIMOUSINES','RESTAURANTS') AND UPPER(Nombre_Comercio)='UBER   *EATS')
OR (Actividad_Comercio IN ('TAXICABS/LIMOUSINES','RESTAURANTS') AND UPPER(Nombre_Comercio) LIKE 'UBER *EATS%')
OR (Actividad_Comercio IN ('TAXICABS/LIMOUSINES','RESTAURANTS') AND UPPER(Nombre_Comercio) LIKE 'UBER *EATS %')
OR (Actividad_Comercio IN ('TAXICABS/LIMOUSINES','RESTAURANTS') AND UPPER(Nombre_Comercio) LIKE 'UBER   *EATS %')
OR (Actividad_Comercio IN ('TAXICABS/LIMOUSINES','RESTAURANTS') AND UPPER(Nombre_Comercio) in ('UBER EATS HELP.','UBERBR UBER EAT','UBERUAE_EATS','UBER EATS','UBERUS_EATS','UBERJP_EATS')
)) THEN 'UBER EATS'

WHEN (Actividad_Comercio IN ('TAXICABS/LIMOUSINES','RESTAURANTS') AND UPPER(Nombre_Comercio) LIKE 'UBR%') THEN 'UBER'
WHEN (Actividad_Comercio IN ('TAXICABS/LIMOUSINES','RESTAURANTS') AND UPPER(Nombre_Comercio) LIKE '%UBER%') THEN 'UBER'

WHEN (Actividad_Comercio IN (
'TIENDAS POR DEPARTAMENTOS',
'VARIETY STORES',
'MISC SPECIALTY RETAIL',
'MENS/WOMENS CLOTHING STORES',
'DISCOUNT STORES',
'COSMETIC STORES') AND UPPER(Nombre_Comercio) LIKE '%WISH%') THEN 'WISH'


ELSE 'OTRO' END AS APPS
FROM Vta_SPOS3 A
;QUIT;


%put-------------------------------------------------------------------------------------------;
%put [04.4] MARCA NOMBRE APPS &periodo;
%put-------------------------------------------------------------------------------------------;


proc sql;
create table work.vta_spos5 as
select *,
today() format=date9. as Fecha_Proceso, 
case  when Apps NOT='OTRO' THEN A.APPS
when (a.codigo_comercio=b.codigo_comercio and b.Marca_Comercio= '') then a.Nombre_Comercio  
when (a.codigo_comercio=b.codigo_comercio and b.Marca_Comercio NOT = '') then b.Marca_Comercio else b.Marca_Comercio end as Comercio,
case when Apps NOT='OTRO' THEN 1 else 0 end as T_Apps,
case when Apps NOT='OTRO' then 'Normalizada*Apps' when (a.codigo_comercio=b.codigo_comercio and b.Marca_Comercio NOT = '') then 'Normalizada' else 'Sin Normalizar' end as T_Mineria
from work.vta_spos4 a left join AMARINAO.CONSOLIDADO_CODIGOS_MARCA b
on a.codigo_comercio=b.codigo_comercio
;quit;


proc sql;
create table work.vta_spos6 as
select *,
coalesce(Comercio,Nombre_Comercio) as Comercio_FIN
from work.vta_spos5 a 
;quit;


%put===========================================================================================;
%put [05] AGRUPAMIENTO &periodo;
%put===========================================================================================;

proc sql;
create table Agrupamiento as 
select 
Fecha_Proceso, 
Periodo,
Tipo_Tarjeta,
SI_Nacional,
SI_online,
dia_nro,
Rubro,
RUBRO2,
Codigo_Comercio,
Actividad_Comercio,
Nombre_Comercio,
Comercio_FIN as Comercio,
T_Apps, 
T_Mineria,
count(rut) as Nro_TRXs,
count(distinct rut) as Nro_Clientes,
sum(Monto) as Mto_TRXs 
from Vta_SPOS6
group by 
Fecha_Proceso, 
Periodo,
Tipo_Tarjeta,
SI_Nacional,
SI_online,
dia_nro,
Rubro,
RUBRO2,
Codigo_Comercio,
Actividad_Comercio,
Nombre_Comercio,
Comercio_FIN,
T_Apps, 
T_Mineria
;QUIT;





%put===========================================================================================;
%put [06] CREACION DE TABLA DE LLENADO &periodo;
%put===========================================================================================;



%if (%sysfunc(exist(&libreria..Normalizacion_Comercios_U3M))) %then %do;

%end;
%else %do;

PROC SQL;
CREATE TABLE &libreria..Normalizacion_Comercios_U3M 
(Fecha_Proceso date , 
periodo num , 
Tipo_Tarjeta char(99), 
SI_Nacional num, 
si_online num , 
dia_nro num, 
Rubro char(99) , 
RUBRO2 char(99), 
codigo_comercio num , 
Actividad_Comercio char(99), 
Nombre_Comercio char(99), 
Comercio char(99), 
T_Apps num, 
T_Mineria char(99), 
Nro_TRXs num, 
Nro_Clientes num, 
Mto_TRXs num , 
Dia_Comparable num)
;QUIT;

%end;


proc sql noprint;
select   
max(dia_nro) as MAX_TR 
into :MAX_TR
from Agrupamiento
where periodo=&periodo.
and Tipo_Tarjeta='TR'
;QUIT;

proc sql noprint;
select   
max(dia_nro) as MAX_TAM
into :MAX_TAM
from Agrupamiento
where periodo=&periodo.
and Tipo_Tarjeta='TAM'
;QUIT;

proc sql noprint;
select   
max(dia_nro) as MAX_MCD 
into :MAX_MCD
from Agrupamiento
where periodo=&periodo.
and Tipo_Tarjeta='MCD'
;QUIT;

proc sql noprint;
select   
max(dia_nro) as MAX_TD 
into :MAX_TD
from Agrupamiento
where periodo=&periodo.
and Tipo_Tarjeta='TD'
;QUIT;

%let MAX_TR=&MAX_TR;
%let MAX_TAM=&MAX_TAM;
%let MAX_MCD=&MAX_MCD;
%let MAX_TD=&MAX_TD;

proc sql;
insert into &libreria..Normalizacion_Comercios_U3M 
select *,
case when Tipo_Tarjeta ='TAM' and dia_nro<=&MAX_TAM.  then 1 
when Tipo_Tarjeta ='TR' and dia_nro<=&MAX_TR.  then 1
when Tipo_Tarjeta ='MCD' and dia_nro<=&MAX_MCD. then 1
when Tipo_Tarjeta ='TD' and dia_nro<=&MAX_TD. then 1
else 0 end as Dia_Comparable
from Agrupamiento
;QUIT;

%put===========================================================================================;
%put [07] BORRADO DE TABLAS DE PASO &periodo;
%put===========================================================================================;

proc sql;
drop table agrupamiento;
drop table codigos_online;
drop table rubro;
drop table tabla_arbol;
drop table vigente;
drop table vta_spos;
drop table vta_spos_tc;
drop table vta_spos_tc1;
drop table vta_spos_td;
drop table vta_spos_td2;
drop table vta_spos_td3;
drop table vta_spos2;
drop table vta_spos3;
drop table vta_spos4;
drop table vta_spos5;
drop table vta_spos6;
;QUIT;

data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */

proc sql;
create table &libreria..NORMALIZACION_COMERCIO_U3M_PM (
fecha_proceso date,
periodo	num,
Tipo_Tarjeta char(99),
SI_Nacional num,
si_online num,
dia_nro num ,
Rubro char(99)	,
RUBRO2 char(99),
codigo_comercio num,
Actividad_Comercio char(99),
Nombre_Comercio	char(99),
Comercio char(99),
T_Apps	num ,
T_Mineria  char(99) ,
Nro_TRXs num ,
Nro_Clientes num ,
Mto_TRXs num ,
Dia_Comparable num ,
rank num)
;QUIT;


%macro top100 (TARJETA,periodo,LIBRERIA);

proc sqL;
create table top100 as 
select 
Comercio,
sum(Mto_TRXs) as MONTO
from &libreria..Normalizacion_Comercios_U3M  
where 
periodo=&periodo.
and Tipo_Tarjeta=&tarjeta.
group by comercio
order by MONTO desc
;QUIT;

proc sql;
create table top100 as 
select 
monotonic() as ind,
*
from top100 
;QUIT;

proc sql;
create table top100 as 
select 
*,
case when ind between 1 and 100 then comercio else 'OTROS' end as comercio2
from top100
;QUIT;


proc sql;
create table paso as 
select 
a.*,
b.ind
from &libreria..Normalizacion_Comercios_U3M  as a 
inner join top100 as b
on(a.comercio=b.comercio) and a.periodo=&periodo. and a.Tipo_Tarjeta='TAM'
where b.ind between 1 and 100
;QUIT;

proc sql;
create table paso2 as 
select 
a.fecha_proceso ,
a.periodo	,
a.Tipo_Tarjeta ,
a.SI_Nacional ,
a.si_online ,
a.dia_nro  ,
'OTROS' as Rubro 	,
'OTROS' as RUBRO2 ,
. as codigo_comercio ,
'OTROS' as Actividad_Comercio ,
'OTROS' as Nombre_Comercio	,
'OTROS' as Comercio ,
a.T_Apps	 ,
a.T_Mineria   ,
sum(a.Nro_TRXs)  as Nro_TRXs,
sum(a.Nro_Clientes)  as Nro_Clientes ,
sum(a.Mto_TRXs)  as Mto_TRXs,
a.Dia_Comparable ,
101 as ind
from &libreria..Normalizacion_Comercios_U3M  as a 
inner  join top100 as b
on(a.comercio=b.comercio) and a.periodo=&periodo. and a.Tipo_Tarjeta=&tarjeta.
where b.ind>100
group by 
a.fecha_proceso ,
a.periodo	,
a.Tipo_Tarjeta ,
a.SI_Nacional ,
a.si_online ,
a.dia_nro   ,
a.T_Apps	 ,
a.T_Mineria   ,

a.Dia_Comparable
;QUIT;

proc sql;
insert into  &libreria..NORMALIZACION_COMERCIO_U3M_PM 
select 
*
from paso
;QUIT;

proc sql;
insert into  &libreria..NORMALIZACION_COMERCIO_U3M_PM 
select 
*
from paso2 
;QUIT;

proc sql;
drop table top100;
drop table paso;
drop table paso2;
;QUIT;



%mend top100;

%top100('TAM',&periodo.,&libreria.);
%top100('TR',&periodo.,&libreria.);
%top100('TD',&periodo.,&libreria.);
%top100('MCD',&periodo.,&libreria.);

%top100('TAM',&periodo_Ant.,&libreria.);
%top100('TR',&periodo_Ant.,&libreria.);
%top100('TD',&periodo_Ant.,&libreria.);
%top100('MCD',&periodo_Ant.,&libreria.);

%top100('TAM',&periodo_12Ant.,&libreria.);
%top100('TR',&periodo_12Ant.,&libreria.);
%top100('TD',&periodo_12Ant.,&libreria.);
%top100('MCD',&periodo_12Ant.,&libreria.);



/*Fecha ejecución del proceso	*/

data _null_;
execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechaeDVN", execDVN) ;
RUN;

%put &fechaeDVN;/*fecha ejecucion proceso 

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';

SELECT EMAIL into :DEST_3 
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'ALEJANDRA_MARINAO';

SELECT EMAIL into :DEST_4 
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO 	 = ("&DEST_2","&DEST_3")
CC 	 = ("&DEST_1","&DEST_4")
SUBJECT = "MAIL_AUTOM: Proceso Normalizacion de Comercios";
FILE OUTBOX;
PUT 'Estimados:';
 put "        Proceso Normalizacion de Comercio , ejecutado con fecha: &fechaeDVN";  
 put ; 
 put ; 
 put ; 
 PUT ;
 put ; 
 put "        Proceso Vers. 05"; 
 put ; 
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

