/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	SALDO_RP			================================*/
/* CONTROL DE VERSIONES
/* 2022-08-19 -- V7 -- SERGIO J.  -- Se agrega código de exportación a aws
/* 2022-07-28 -- V6 -- Esteban P. -- Se agrega nueva query de obtención de puntos del cliente y Puntos a vencer en su próximo mes

/* 2022-03-31 -- V5 -- Esteban P. -- Se actualizan los correos: Se desvincula a Osvaldo Ugarte de los destinatarios.

/* 2020-11-24 -- V4 -- SERGIO JARA -- Nueva Versión Automática Equipo Datos y Procesos BI	
								   -- Modificaciones al código agregando noprint y eliminando la doble variable dentro de %base_entregable
								   -- Se añade a Benjamin Soto como destinatario

/* 2020-11-19 -- V3 -- SERGIO JARA -- Nueva Versión Automática Equipo Datos y Procesos BI
									-- Se agrega statement noprint despues de proc sql para adaptar proceso al servidor

/* 2020-11-19 -- V2 -- SERGIO JARA -- Nueva Versión Automática Equipo Datos y Procesos BI
									-- Se agrega variable Libreria
									-- Envio de correo automático

/* 2020-11-19 -- V1 -- BENJAMIN SOTO -- Nueva Versión Automática Equipo Datos y Procesos BI
									-- CODIGO  ORIGINAL BENJA

/* INFORMACIÓN:
	Programa tipo con comentarios e instrucciones básicas para ser estandarizadas al equipo.

	(IN) Tablas requeridas o conexiones a BD:
	- db2 (user_sas)
	- LOYALTY_NOVEDADES

	(OUT) Tablas de Salida o resultado:
	- RESULT.Saldo_RPtos_Disp
    - RESULT.Saldo_RPtos_Disp_AGG
*/
	
/*###################################################################################*/
/*Reporte de saldo de Ripley puntos por tramo*/
/*###################################################################################*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria=Result;


%put &libreria;

/******************************** Validar Proceso ************************************/

/* entregable del proceso

proc sql outobs=10;

create table SB_temp as 
select * 
from sbarrera.Saldo_RPtos_Disp_Rutero 
 
;quit; 


proc sql outobs=10;

create table SB_temp as 
select * 
from sbarrera.Saldo_RPtos_Disp_Reporte  
 
;quit;



*/


/******************************** Comenzar Proceso ***********************************/


/*Definir Parametros*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
%let Base_Entregable=%nrstr("result.Saldo_RPtos_Disp");
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::*/


options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/


%put==========================================================================================;
%put [01] Extraer Clientes con Saldo de RPtos;
%put==========================================================================================;


proc sql;

connect to SQLSVR as mydb
      (datasrc="SQL_Datawarehouse" user="user_sas" PASSWORD="{sas002}AC224E474B8742BD13124A965275013020A60F8D15DCC25A52A5D43F49A76B4D");

create table work.Rutero_Saldo_RPtos as
select input(substr(DOCUMENT,1,length(document)-1),best.) as rut,max(POINTS) as Saldo_RPtos ,max(POINTS_M0) as Saldo_Vencer
from connection to mydb (
Select  
*
from (select document,max(points) as points from db2.LOYALTY_SALDO_PUNTOS group by document) as a
left join (select document,max(points_m0) as points_m0 from db2.LOYALTY_VENCIMIENTO_PUNTOS group by document) b on a.document=b.document 

) as conexion
group by calculated rut
;quit;


%put==========================================================================================;
%put [02] Tramificar saldo de puntos disponibles;
%put==========================================================================================;


PROC SQL;

create table work.Rutero_Saldo_RPtos as
SELECT 
*,
SB_Tramificar(coalesce(Saldo_RPtos,0),500,0,200000,'') as Tramo1_Saldo_RPtos, 
case 
when index(calculated Tramo1_Saldo_RPtos,'.')>=4 then calculated Tramo1_Saldo_RPtos 
else '0'||calculated Tramo1_Saldo_RPtos
end as Tramo2_Saldo_RPtos 
FROM work.Rutero_Saldo_RPtos 

;QUIT;




%put==========================================================================================;
%put [03] Pegar datos del cliente;
%put==========================================================================================;


%put------------------------------------------------------------------------------------------;
%put [03.1] Segmento Comercial;
%put------------------------------------------------------------------------------------------;



PROC SQL;

create table work.Rutero_Saldo_RPtos as
SELECT 
a.*,
case 
when b.Segmento is null then '0. S.I.' 
when b.Segmento='R_GOLD' then '1. Gold' 
when b.Segmento='R_SILVER' then '2. Silver'  
when b.Segmento='R_PLUS' then '3. Plus'   
when b.Segmento='RIPLEY_BAJA' then '4. G.B'   
else '0. S.I.' 
end as Segmento_Comercial 
FROM work.Rutero_Saldo_RPtos as a 
left join publicin.Segmento_Comercial as b 
on (a.rut=b.rut) 

;QUIT;



%put------------------------------------------------------------------------------------------;
%put [03.2] Segmento Gestion;
%put------------------------------------------------------------------------------------------;


/*determinar Ultimo Periodo disponible*/

PROC SQL noprint;   

select max(anomes) as Max_anomes_SegGes
into :Max_anomes_SegGes
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-9,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'NLAGOSG.SEGM_GEST_TODAS_PART_%' 
and length(Nombre_Tabla)=length('NLAGOSG.SEGM_GEST_TODAS_PART_AAAAMM_NEW')
) as x

;QUIT;


/*Pegar en base*/

DATA _NULL_;
Call execute(
cat('
proc sql; 

create table work.Rutero_Saldo_RPtos as 
select 
a.*, 
case 
when b.Segmento is null then ''0. S.I.'' 
when b.Segmento=''R_GOLD'' then ''1. Gold'' 
when b.Segmento=''R_SILVER'' then ''2. Silver'' 
when b.Segmento=''R_PLUS'' then ''3. Plus''  
when b.Segmento=''R_PLUS'' then ''4. G.B''  
else ''0. S.I.'' 
end as Segmento_Gestion 
from work.Rutero_Saldo_RPtos as a 
left join nlagosg.segm_gest_todas_part_',&Max_anomes_SegGes,'_new as b 
on (a.rut=b.rut) 

;quit; 
')
);
run;




%put------------------------------------------------------------------------------------------;
%put [03.3] Sucursal Preferente;
%put------------------------------------------------------------------------------------------;


/*determinar Ultimo Periodo disponible*/


PROC SQL noprint;   

select max(anomes) as Max_anomes_SucPref
into :Max_anomes_SucPref 
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'PUBLICIN.SUCURSAL_PREFERENTE_%' 
and length(Nombre_Tabla)=length('PUBLICIN.SUCURSAL_PREFERENTE_AAAAMM')
) as x

;QUIT;


/*Pegar en base*/

DATA _NULL_;
Call execute(
cat('
proc sql; 

create table work.Rutero_Saldo_RPtos as 
select  
a.*, 
coalesce(b.NomSuc_TotalTMP,''0. S.I.'') as NomSuc_TotalTMP 
from work.Rutero_Saldo_RPtos as a 
left join PUBLICIN.SUCURSAL_PREFERENTE_',&Max_anomes_SucPref,' as b 
on (a.rut=b.rut) 

;quit; 
')
);
run;



%put------------------------------------------------------------------------------------------;
%put [03.4] Tenencia de Tarjeta Credito, Tipo de TC y Actividad TR;
%put------------------------------------------------------------------------------------------;



/*determinar Ultimo Periodo disponible*/


PROC SQL noprint;   

select max(anomes) as Max_anomes_ActTR
into :Max_anomes_ActTR 
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'PUBLICIN.ACT_TR_%' 
and length(Nombre_Tabla)=length('PUBLICIN.ACT_TR_AAAAMM')
) as x

;QUIT;


/*Pegar en base*/

DATA _NULL_;
Call execute(
cat('
proc sql; 

create table work.Rutero_Saldo_RPtos as 
select  
a.*, 
case when b.VU_RIESGO=1 then 1 else 0 end as SI_TC, 
case 
when b.VU_RIESGO<>1 then ''N.A.'' 
when b.MARCA_BASE in (''CREDITO_2000'',''ITF'') then ''TR'' 
else ''TAM'' 
end as Tipo_TC,
b.ACTIVIDAD_TR 
from work.Rutero_Saldo_RPtos as a 
left join PUBLICIN.ACT_TR_',&Max_anomes_ActTR,' as b 
on (a.rut=b.rut) 

;quit; 
')
);
run;


%put------------------------------------------------------------------------------------------;
%put [03.5] Tenencia de Tarjeta Debito;
%put------------------------------------------------------------------------------------------;


PROC SQL;

create table work.Rutero_Saldo_RPtos as
SELECT 
a.*,
case when b.Rut is not null then 1 else 0 end as SI_TD   
FROM work.Rutero_Saldo_RPtos as a 
left join (
select distinct rut 
from result.CTAVTA1_STOCK 
where Estado_Cuenta='vigente' 
) as b 
on (a.rut=b.rut) 

;QUIT;


%put------------------------------------------------------------------------------------------;
%put [03.6] Info de Demo Basquet;
%put------------------------------------------------------------------------------------------;



/*determinar Ultimo Periodo disponible*/


PROC SQL noprint;   

select max(anomes) as Max_anomes_DemoB
into :Max_anomes_DemoB 
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'PUBLICIN.DEMO_BASKET_%' 
and length(Nombre_Tabla)=length('PUBLICIN.DEMO_BASKET_AAAAMM')
) as x

;QUIT;


/*Pegar en base*/

DATA _NULL_;
Call execute(
cat('
proc sql; 

create table work.Rutero_Saldo_RPtos as 
select  
a.*, 
b.TIPO_ACTIVIDAD,
b.SEXO,
b.RANGO_EDAD 
from work.Rutero_Saldo_RPtos as a 
left join PUBLICIN.DEMO_BASKET_',&Max_anomes_DemoB,' as b 
on (a.rut=b.rut) 

;quit; 
')
);
run;



%put------------------------------------------------------------------------------------------;
%put [03.7] Region del Cliente;
%put------------------------------------------------------------------------------------------;


PROC SQL;

create table work.Rutero_Saldo_RPtos as
SELECT 
a.*,
b.Region  
FROM work.Rutero_Saldo_RPtos as a 
left join publicin.Direcciones as b 
on (a.rut=b.rut) 

;QUIT;



%put------------------------------------------------------------------------------------------;
%put [03.8] Division TDA Preferente;
%put------------------------------------------------------------------------------------------;




/*determinar Ultimo Periodo disponible*/


PROC SQL noprint;   

select max(anomes) as Max_anomes_DivPref
into :Max_anomes_DivPref 
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'PUBLICIN.DIVISION_PREFERENTE_%' 
and length(Nombre_Tabla)=length('PUBLICIN.DIVISION_PREFERENTE_AAAAMM')
) as x

;QUIT;


/*Pegar en base*/





%put------------------------------------------------------------------------------------------;
%put [03.9] Rubro SPOS Preferente;
%put------------------------------------------------------------------------------------------;






/*determinar Ultimo Periodo disponible*/


PROC SQL noprint;   

select max(anomes) as Max_anomes_RubPref
into :Max_anomes_RubPref  
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'PUBLICIN.RUBRO_PREFERENTE_%' 
and length(Nombre_Tabla)=length('PUBLICIN.RUBRO_PREFERENTE_AAAAMM') 
) as x

;QUIT;


/*Pegar en base*/

DATA _NULL_;
Call execute(
cat('
proc sql; 

create table work.Rutero_Saldo_RPtos as 
select  
a.*, 
b.Rubro_Fuerte1  
from work.Rutero_Saldo_RPtos as a 
left join PUBLICIN.RUBRO_PREFERENTE_',&Max_anomes_RubPref,' as b 
on (a.rut=b.rut) 

;quit; 
')
);
run;


%put------------------------------------------------------------------------------------------;
%put [03.10] Tenencia de Datos de Contacto (Email+Telefono);
%put------------------------------------------------------------------------------------------;

/*eMail*/

PROC SQL;

create table work.Rutero_Saldo_RPtos as
SELECT 
a.*,
b.EMAIL  
FROM work.Rutero_Saldo_RPtos as a 
left join publicin.BASE_TRABAJO_EMAIL as b 
on (a.rut=b.rut) 

;QUIT;


/*Telefono*/


PROC SQL;

create table work.Rutero_Saldo_RPtos as
SELECT 
a.*,
b.TELEFONO   
FROM work.Rutero_Saldo_RPtos as a 
left join publicin.FONOS_MOVIL_FINAL as b 
on (a.rut=b.CLIRUT) 

;QUIT;



%put------------------------------------------------------------------------------------------;
%put [03.11] Marca de Libro Negro;
%put------------------------------------------------------------------------------------------;



PROC SQL;

create table work.Rutero_Saldo_RPtos as
SELECT 
a.*,
case when b.rut is not null then 1 else 0 end as LNegro_CAR 
FROM work.Rutero_Saldo_RPtos as a 
left join publicin.LNEGRO_CAR as b 
on (a.rut=b.rut) 

;QUIT;



%put==========================================================================================;
%put [04] Vaciar Resultados en Tabla entregable;
%put==========================================================================================;

/*Sacar Fecha del proceso*/
PROC SQL noprint outobs=1;   

select 
SB_Ahora('DD/MM/AAAA_HH:MM') as Fecha_Proceso 
into :Fecha_Proceso 
from sashelp.vmember

;QUIT;
%let Fecha_Proceso="&Fecha_Proceso";


%put------------------------------------------------------------------------------------------;
%put [04.1] Rutero Total con todo el detalle;
%put------------------------------------------------------------------------------------------;


DATA _NULL_;
Call execute(
cat('
proc sql;

create table ',&Base_Entregable,' as 
SELECT 
''',&Fecha_Proceso,''' as Fecha_Proceso, 
* 
from work.Rutero_Saldo_RPtos  

;quit;
')
);
run;





%put------------------------------------------------------------------------------------------;
%put [04.2] Version Agrupada de cara a reporte diario;
%put------------------------------------------------------------------------------------------;



DATA _NULL_;
Call execute(
cat('
proc sql;

create table ',&Base_Entregable,'_AGG as 
SELECT 
''',&Fecha_Proceso,''' as Fecha_Proceso, 
Tramo2_Saldo_RPtos,
Segmento_Comercial,
/*Segmento_Gestion,*/ 
/*NomSuc_TotalTMP,*/
case 
when SI_TC=1 and SI_TD=1 then ''1. TC+TD'' 
when SI_TC=1 then ''2. Solo TC'' 
when SI_TD=1 then ''3. Solo TD'' 
else ''4. N.A.'' 
end as Tenencia_Tarjeta, 
Tipo_TC,
ACTIVIDAD_TR,
/*TIPO_ACTIVIDAD,*/ 
SEXO,
RANGO_EDAD,
/*REGION,*/   
Rubro_Fuerte1,
case 
when EMAIL is not null and TELEFONO is not null then ''1. eMail+Fono'' 
when EMAIL is not null then ''2. Solo eMail'' 
when TELEFONO is not null then ''3. Solo Fono'' 
else ''S.I.'' 
end as Contactabilidad, 
LNegro_CAR, 
count(*) as Nro_Clientes 
from work.Rutero_Saldo_RPtos  
group by 
Tramo2_Saldo_RPtos,
Segmento_Comercial,
/*Segmento_Gestion,*/ 
/*NomSuc_TotalTMP,*/ 
calculated Tenencia_Tarjeta, 
Tipo_TC,
ACTIVIDAD_TR,
/*TIPO_ACTIVIDAD,*/ 
SEXO,
RANGO_EDAD,
/*REGION,*/   
Rubro_Fuerte1,
calculated Contactabilidad, 
LNegro_CAR 

;quit;
')
);
run;



/*Eliminar tablas de paso*/

proc sql noprint;

drop table work.Rutero_Saldo_RPtos   

;quit;


/*==============================    	EXPORT_TO_AWS - START		 ===============================*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(sas_earq_saldo_rptos_disp,raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(sas_earq_saldo_rptos_disp,result.Saldo_RPtos_Disp,raw,sasdata,0);

/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

SELECT EMAIL into :DEST_4
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'BENJAMIN_SOTO';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_4;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1", "&DEST_2","&DEST_4")
SUBJECT = ("MAIL_AUTOM - TEST: Proceso Saldo_RP");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso Saldo_RP, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put ; 
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 07'; 
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


