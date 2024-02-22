/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	TRANSACCIONES_MAESTRO.sas	================================*/
/* CONTROL DE VERSIONES
/* 	2021-02-23 -- V1 -- Pedro Muñoz -- Nueva Versión Automática Equipo Datos y Procesos BI */


%let libreria=PUBLICIN;

%macro EVALUAR_MAESTRO(i,libreria);

%let path_ora        = '(DESCRIPTION = (ADDRESS_LIST = (ADDRESS =  (PROTOCOL = TCP) (Host = reporteslegales-bd.bancoripley.cl)        (Port = 1521)      )    )    (CONNECT_DATA =       (SID = BORLG)    )  ) '; 
%let user_ora      = 'SAS_USR'; 
%let pass_ora      = ' sas2020$';
%let Schema_ora         = 'VERGARAM';
%let conexion_ora    = ORACLE PATH=&path_ora. Schema=&Schema_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 
LIBNAME DB_BOLRG     &conexion_ora. insertbuff=10000 readbuff=10000;  

%put ##################MACRO FECHAS################;

DATA _NULL_;
fin = put(intnx('month',today(),-&i.,'end'),date9.);
ini = put(intnx('month',today(),-&i.,'begin'),date9.);
periodo = put(intnx('month',today(),-&i.,'begin'),yymmn6.);

Call symput("fin",fin);
Call symput("ini",ini);
Call symput("periodo",periodo);
run;

%put &ini;
%put &fin;
%put &periodo;

%put ################### Extraer info DEM &periodo. ########################;

PROC SQL;
CREATE TABLE DATA_CONSULTABLE AS 
SELECT 
*
FROM DB_BOLRG.TABLA_DEM /* Tabla DEM de movimientos de CTaVTa */
WHERE FECHORA_TRANSAC between "&ini:00:00:00"dt and "&fin:23:59:59"dt;
QUIT;


proc sql;
create table DATA_CONSUlTABLE2 as 
select 
year(datepart(FECHORA_TRANSAC))*10000+month(datepart(FECHORA_TRANSAC))*100+day(datepart(FECHORA_TRANSAC)) as fecha,
year(datepart(FECHORA_TRANSAC))*100+month(datepart(FECHORA_TRANSAC)) as periodo,
INPUT(COD_COMERCIO_POS,BEST.) AS codigo_comercio,
NOMBRE_FAN_COMERCIO as Nombre_Comercio,
DESC_RUBRO as Actividad_Comercio,
. as RUT,
input(CTACTE_TITULAR,best32.) as cuenta,
MONTO_1*1 as VENTA_TARJETA,
152 as CODPAIS,
0 as TOTCUOTAS,
NRO_TERJETA_DEB as PAN,
input(COD_RUBRO_NAC,best.) as  CODACT,
0 as PORINT,
'MAESTRO' as 	Tipo_Tarjeta,
IND_COMERCIO,
COD_AUTORIZ as numaut,
case when COD_COMERCIO_DEB<>83382700 then 'SPOS' else 'TDA' end as TIPO
from DATA_CONSULTABLE
;QUIT;



%let path_ora      = '(DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SID = ripleyc)))'; 
%let user_ora      = 'RIPLEYC'; 
%let pass_ora      = 'ri99pley';
%let conexion_ora  = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 
  

PROC SQL  NOERRORSTOP;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );

create table cuentas  as
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

%put ################### TRAER RUT &periodo. ########################;

proc sqL;
create table DATA_CONSUlTABLE3 as 
select 
a.fecha,
a.periodo,
a.codigo_comercio,
a.Nombre_Comercio,
a.Actividad_Comercio,
b.RUT,
a.cuenta,
a.VENTA_TARJETA,
a.CODPAIS,
a.TOTCUOTAS,
a.PAN,
a.CODACT,
a.PORINT,
a.Tipo_Tarjeta,
a.IND_COMERCIO,
a.numaut,
a.TIPO
from data_consultable2 as a
left join cuentas as b
on(a.cuenta=b.cuenta)
order by a.fecha
;QUIT;

%put ################### GUARDAR EN DURO &periodo. ########################;

proc sql;
create table &libreria..SPOS_MAESTRO_&periodo. as 
select 
t1.fecha, 
t1.periodo, 
t1.codigo_comercio, 
t1.Nombre_Comercio, 
t1.Actividad_Comercio, 
t1.RUT, 
t1.cuenta, 
t1.VENTA_TARJETA, 
t1.CODPAIS, 
t1.TOTCUOTAS, 
t1.PAN, 
t1.CODACT, 
t1.PORINT, 
t1.Tipo_Tarjeta, 
t1.IND_COMERCIO, 
t1.numaut
FROM WORK.DATA_CONSULTABLE3 as t1
where t1.TIPO='SPOS'
;QUIT;


proc sql;
create table &libreria..TDA_MAESTRO_&periodo. as 
select 
t1.fecha, 
t1.periodo, 
t1.codigo_comercio, 
t1.Nombre_Comercio, 
t1.Actividad_Comercio, 
t1.RUT, 
t1.cuenta, 
t1.VENTA_TARJETA, 
t1.CODPAIS, 
t1.TOTCUOTAS, 
t1.PAN, 
t1.CODACT, 
t1.PORINT, 
t1.Tipo_Tarjeta, 
t1.IND_COMERCIO, 
t1.numaut
FROM WORK.DATA_CONSULTABLE3 as t1
where t1.TIPO='TDA'
;QUIT;

%put ################### GUARDAR EN DURO &periodo. ########################;

proc sql;
drop table cuentas;
drop table data_consultable;
drop table data_consultable2;
drop table data_consultable3;
;QUIT;

%mend EVALUAR_MAESTRO;



%macro ejecutar(A);


DATA _null_;
HOY = day(today());
Call symput("HOY", HOY);
RUN;
%put &HOY;

%if %eval(&HOY.<=5) %then %do;

%EVALUAR_MAESTRO(0,&libreria.);
%EVALUAR_MAESTRO(1,&libreria.);

%end;
%else %DO;

%EVALUAR_MAESTRO(0,&libreria.);

%end;

%mend ejecutar;

%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

%ejecutar(A);

data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */


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
TO = ("&DEST_1","&DEST_2","&DEST_3","&DEST_4")
SUBJECT="MAIL_AUTOM: PROCESO MAESTRO %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso MAESTRO, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put 'Tabla resultante en: PUBLICIN.SPOS_MAESTRO_PERIODO'; 
 put 'Tabla resultante en: PUBLICIN.TDA_MAESTRO_PERIODO'; 
 put ;
 put 'Vers.1'; 
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

