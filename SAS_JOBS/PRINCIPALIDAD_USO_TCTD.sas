/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PRINCIPALIDAD_USO_TCTD		================================*/
/* CONTROL DE VERSIONES
/* 2020-12-09 -- V2 -- David V. -- 
					-- Agregado código noprint para evitar error en server SAS
/* 2020-10-08 -- V1 -- Nicole L. -- Versión Original 
					-- Comentarios EDYP (Al inicio y al final)
					-- Tiempo de ejecución
					-- Envío de email notificando ejecución
/* INFORMACIÓN:
/* Tablas necesarias o requeridas:
	- publicin.SPOS_AUT_AAAAMM
	- publicin.TDA_ITF_AAAAMM
	- publicin.TRX_AV_AAAAMM
	- BD GESTIÓN / QA_NEW / FISA

/* Tablas que genera o actualiza el proceso:
	- PUBLICIN.PRINCIPALIDAD_TCTD

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/


/*##################################################################################*/
/*Proceso Principalidad Uso de Tarjetas (TC y TD) */
/*##################################################################################*/

/******************************* Validar Proceso ************************************/


/****************************** Comenzar Proceso ************************************/


/*Definir Macro Parametros*/
/*::::::::::::::::::::::::::*/
%let Periodo_Proceso=0; /*Periodo*/
%let Ventana_Tiempo=12; /*Ventana de tiempo hacia atras a considerar*/
%let Parametros_RFM=%nrstr('R:0.35|F:0.50|M:0.15'); /*Parametros para ponderacion RFM*/
%let Base_Entregable=%nrstr('PUBLICIN.PRINCIPALIDAD_TCTD'); /*Nombre de Base Entregable*/
/*::::::::::::::::::::::::::*/


options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/


%put==========================================================================================;
%put [00] Definir Periodos a Utilizar;
%put==========================================================================================;


/*Periodo Global del proceso*/
PROC SQL outobs=1 noprint;   

select 
case when &Periodo_Proceso>0 then &Periodo_Proceso 
else SB_mover_anomes(input(SB_AHORA('AAAAMM'),best.),-1) 
end as Periodo 
into 
:Periodo 
from sashelp.vmember

;QUIT;


/*Fechas para bases de TC*/
PROC SQL outobs=1 noprint;   

select 
&Periodo as Periodo_f,
SB_mover_anomes(&Periodo,-1*(&Ventana_Tiempo-1)) as Periodo_i  
into 
:Periodo_f,
:Periodo_i 
from sashelp.vmember 

;QUIT;
%put &Periodo_f.;
%put &Periodo_i.;



/*Fechas para bases de TD*/
PROC SQL outobs=1 noprint;   

select 
100*&Periodo+SB_Dias_mes(&Periodo) as anomesdia1_f,
100*SB_mover_anomes(&Periodo,-1*(&Ventana_Tiempo-1))+01 as anomesdia1_i  
into 
:anomesdia1_f,
:anomesdia1_i 
from sashelp.vmember 

;QUIT;
%put &anomesdia1_f.;
%put &anomesdia1_i.;


PROC SQL outobs=1 noprint;   

select 
cat(substr(compress(put(&anomesdia1_f,best.)),7,2),'/',substr(compress(put(&anomesdia1_f,best.)),5,2),'/',substr(compress(put(&anomesdia1_f,best.)),1,4)) as Fecha1_f,
cat(substr(compress(put(&anomesdia1_i,best.)),7,2),'/',substr(compress(put(&anomesdia1_i,best.)),5,2),'/',substr(compress(put(&anomesdia1_i,best.)),1,4)) as Fecha1_i 
into 
:Fecha1_f,
:Fecha1_i  
from sashelp.vmember 

;QUIT;
%let Fecha1_f="&Fecha1_f";
%let Fecha1_i="&Fecha1_i";
%put &Fecha1_i.;
%put &Fecha1_f.;


%put==========================================================================================;
%put [01] Movimientos de TC;
%put==========================================================================================;


options sasmstore=publicin Mstored;

%SB_Apilador_Bases_Mensuales(
&Periodo_i, /*anomes desde de ventas que se quiere*/
&Periodo_f, /*anomes hasta de ventas que se quiere*/
'
select 
rut,
sum(Mto) as Monto 
from ( 

select 
rut, 
sum(venta_tarjeta) as Mto 
from publicin.SPOS_AUT_AAAAMM  
group by 
rut 

outer union corr 

select 
rut,
sum(capital) as Mto 
from publicin.TDA_ITF_AAAAMM  
group by 
rut 

outer union corr 

select 
rut,
sum(capital) as Mto 
from publicin.TRX_AV_AAAAMM  
group by 
rut  

) as X  
group by 
rut 

', /*query a agregar, debe comenzar con select..., y terminar sin ;quit;*/
'work.Periodo_rut_TC' /*Nombre de base entregable donde quedaran los resultados */
);


%put==========================================================================================;
%put [02] Movimientos de TD;
%put==========================================================================================;


/*Conexion a FISA*/
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


/*Sacar base de movimientos global (solo cargos relacionados a uso de TD)*/
DATA _NULL_;
Call execute(
cat('
proc sql; 

&mz_connect_BANCO; 
create table work.Periodo_rut_TD as 
SELECT 
input(SUBSTR(put(datepart(c1.FECHA),yymmddn8.),1,6),best.) as PERIODO,
coalesce(INPUT((SUBSTR(c2.cli_identifica,1,(LENGTH(c2.cli_identifica)-1))),BEST.),0) AS RUT, 
sum(c1.MONTO) as Monto 

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
and tmo_tipotra in (''D'') /*D=Cargo, C=Abono*/ 
and tmo_codpro = 4 
and tmo_codtip = 1 
and tmo_modo = ''N'' 
and tmo_val > 1 /*solo montos mayores a 1 peso (mov de prueba)*/ 

and tmo_fechcon >= to_date(''',&Fecha1_i,''',''dd/mm/yyyy'') 
and tmo_fechcon <= to_date(''',&Fecha1_f,''',''dd/mm/yyyy'') 

and rub_desc IN ( /*solo movs para uso de actividad TD*/ 
''COMPRA NACIONAL'',
''COMPRA INTERNACIONAL'',
''GIRO CAJERO AUTOMATICO'',
''GIRO POR CAJA'',
''GIRO INTERNACIONAL'' 
) 

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
group by 
calculated PERIODO,
calculated RUT

;QUIT;
')
);
run;


%put==========================================================================================;
%put [03] Unificacion de Bases;
%put==========================================================================================;

proc sql;

create table work.Periodo_rut as 
select * 
from (
select 'TC' as Categoria,* from work.Periodo_rut_TC
outer union corr 
select 'TD' as Categoria,* from work.Periodo_rut_TD 
) as x 

;quit;


/*Eliminar tabla de paso*/
proc sql; drop table work.Periodo_rut_TC ;quit;
proc sql; drop table work.Periodo_rut_TD ;quit;


%put==========================================================================================;
%put [04] Llevar a Nivel de rut-categoria UNICO;
%put==========================================================================================;


proc sql;

create table work.Rutero_Movs as 
select * 
from (

select 
Categoria,
rut,
count(distinct Periodo) as F,
SB_Meses_entre(max(Periodo),&Periodo_f) as R,
sum(Monto)/(count(distinct Periodo)+0.001) as M 
from work.Periodo_rut 
group by 
Categoria,
rut 

outer union corr 

select 
'Total' as Categoria,
rut,
count(distinct Periodo) as F,
SB_Meses_entre(max(Periodo),&Periodo_f) as R,
sum(Monto)/(count(distinct Periodo)+0.001) as M 
from work.Periodo_rut 
group by 
rut 

) as x 

;quit;


/*Eliminar tablas de paso*/
proc sql; drop table work.Periodo_rut ;quit;

%put==========================================================================================;
%put [05] Normalizar R F y M;
%put==========================================================================================;

%put-------------------------------------------------------------------------------------------;
%put [05.1] Calcular veintiles de cada categoria Monto;
%put-------------------------------------------------------------------------------------------;

/*
proc means data=work.Rutero_Movs StackODSOutput  Mean Min P5 P10 P25 P50 P75 P90 P95 Max; 
CLASS Categoria;
var M;
ods output summary=work.Rutero_Movs_Perc;
run;
*/

/*Sacar Veintil*/
proc rank data=work.Rutero_Movs groups=20 descending out=work.Rutero_Movs2;
by Categoria;
var M;
ranks Mv;
run;


/*Corregir Marca*/
proc sql;

create table work.Rutero_Movs2 as 
select 
a.Categoria,
a.rut,
a.F,
a.R,
a.M,
a.Mv+1 as Mv 
from work.Rutero_Movs2 as a 

;quit;


/*Eliminar tablas de paso*/
proc sql; drop table work.Rutero_Movs ;quit;


%put-------------------------------------------------------------------------------------------;
%put [05.2] Calcular Variables Normalizadas;
%put-------------------------------------------------------------------------------------------;


proc sql;

create table work.Rutero_Movs2 as 
select 
a.*,
SB_Valor_Interpolado(a.R,1,&Ventana_Tiempo,0,0,1) as R2,
SB_Valor_Interpolado(a.F,1,0,&Ventana_Tiempo,0,1) as F2,
SB_Valor_Interpolado(a.Mv,1,20,1,0,1) as M2 
from work.Rutero_Movs2 as a 

;quit;



%put===========================================================================================;
%put [06] Calcular RFM segun peso de cada Variable ;
%put===========================================================================================;


%put-------------------------------------------------------------------------------------------;
%put [06.1] Rescatar desde Parametros valores de RFM;
%put-------------------------------------------------------------------------------------------;


PROC SQL outobs=1 noprint;   

select 
input(substr(&Parametros_RFM,03,04),best.) as Peso_R,
input(substr(&Parametros_RFM,10,04),best.) as Peso_F,
input(substr(&Parametros_RFM,17,04),best.) as Peso_M 
into 
:Peso_R,
:Peso_F,
:Peso_M 
from sashelp.vmember 

;QUIT;


%put-------------------------------------------------------------------------------------------;
%put [06.2] Calcular RFM;
%put-------------------------------------------------------------------------------------------;


proc sql;

create table work.Rutero_Movs2 as 
select 
*,
&Peso_R*R2+&Peso_F*F2+&Peso_M*M2 as RFM 
from work.Rutero_Movs2  

;quit;


%put===========================================================================================;
%put [07] Pivotear Tabla con variables relevantes;
%put===========================================================================================;


proc sql;

create table work.Rutero_Movs3 as 
select 
rut,
max(case when Categoria='Total' then R end) as R_Total,
max(case when Categoria='Total' then F end) as F_Total,
max(case when Categoria='Total' then M end) as M_Total,
max(case when Categoria='Total' then Mv end) as Mv_Total,
max(case when Categoria='TC' then R end) as R_TC,
max(case when Categoria='TC' then F end) as F_TC,
max(case when Categoria='TC' then M end) as M_TC,
max(case when Categoria='TC' then Mv end) as Mv_TC,
max(case when Categoria='TD' then R end) as R_TD,
max(case when Categoria='TD' then F end) as F_TD,
max(case when Categoria='TD' then M end) as M_TD,
max(case when Categoria='TD' then Mv end) as Mv_TD,
max(case when Categoria='Total' then RFM end) as RFM_Total,
max(case when Categoria='TC' then RFM end) as RFM_TC,
max(case when Categoria='TD' then RFM end) as RFM_TD  
from work.Rutero_Movs2  
group by 
rut 

;quit;


%put===========================================================================================;
%put [08] Guardar resultados en tabla entregable ;
%put===========================================================================================;


DATA _NULL_;
Call execute(
cat('
proc sql; 

create table ',&Base_Entregable,'_',&Periodo,' as 
SELECT * 
from work.Rutero_Movs3   

;quit;
')
);
run;

/*Eliminar tablas de paso*/
proc sql; drop table work.Rutero_Movs3 ;quit;



/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	FECHA PROCESO Y ENVÍO DE EMAIL =============================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'NICOLE_LAGOS';

SELECT EMAIL into :DEST_3
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

quit;

%put &=EDP_BI;
%put &=DEST_1;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_2")
CC = ("&DEST_1", "&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso PRINCIPALIDAD USO TCTD");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso PRINCIPALIDAD USO TCTD, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put ; 
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 02'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
