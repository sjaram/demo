/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*============================= Proceso Seguimiento Diario de clientes con Uso ===============================*/
/* CONTROL DE VERSIONES
/* 2021-02-18 -- V2 -- Ximena Z. --  
					-- Cambio de 12 a 24 en Ventana_Tiempo
/* 2021-02-02 -- V1 -- Ximena Z. --  
					-- Versión Original

/******************************* Validar Proceso ************************************/

/*MEJORAS: agregar TD, agregar Nro_TRXs y Mto_TRXs, (eventual apertura por segmento)*/


/****************************** Comenzar Proceso ************************************/
     

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*Definir Macro Parametros*/
/*::::::::::::::::::::::::::*/
%let Periodo_Proceso=0; /*Periodo hasta, si es 0, toma el mes en curso*/
%let Ventana_Tiempo=39; /*Ventana para seguimiento*/
%let Ventana_Recencia=6; /*Ventana para recencia de Activacion*/
%let Base_Entregable=%nrstr('RESULT.Clientes_USO_diario_debito'); /*Nombre de Base Entregable*/
/*::::::::::::::::::::::::::*/

options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/


%put==========================================================================================;
%put [01] Determinar Periodos de analisis;
%put==========================================================================================;

/*Periodo que se usara*/
PROC SQL outobs=1 noprint;   

select 
case 
when &Periodo_Proceso>0 then &Periodo_Proceso 
else year(today())*100+month(today()) 
end as Periodo_f,
201901 as Periodo_i,
SB_mover_anomes(calculated Periodo_i,-1*(&Ventana_Recencia)) as Periodo_i2    
into 
:Periodo_f,
:Periodo_i,
:Periodo_i2 
from sashelp.vmember

;QUIT;

%put &Periodo_f;
%put &Periodo_i;
%put &Periodo_i2; 



%put==========================================================================================;
%put [02] Iterar rescatando ruteros por Periodo con detalle de uso;
%put==========================================================================================;

%macro Macro_Iteracion;

%let Periodo_Iteracion=&Periodo_f;

%do %while(&Periodo_Iteracion>=&Periodo_i2); /*inicio del while*/

%put#####################################################################;
%put######## &Periodo_f --> &Periodo_Iteracion --> &Periodo_i2 ###########;
%put#####################################################################;


%if (%sysfunc(exist(publicin.spos_mcd_&Periodo_Iteracion.))) %then %do;
PROC SQL NOERRORSTOP ;
create table spos_mcd as 
SELECT 
rut,
venta_tarjeta,
fecha
FROM publicin.spos_mcd_&Periodo_Iteracion.
;RUN; 
%end;
%else %do;
proc sql;
create table spos_mcd
(rut num,
venta_tarjeta num,
fecha num)
;QUIT;
%end;

%if (%sysfunc(exist(publicin.spos_maestro_&Periodo_Iteracion.))) %then %do;
PROC SQL NOERRORSTOP ;
create table spos_maestro as 
SELECT 
rut,
venta_tarjeta,
fecha
FROM publicin.spos_maestro_&Periodo_Iteracion.
;RUN; 
%end;
%else %do;
proc sql;
create table spos_maestro
(rut num,
venta_tarjeta num,
fecha num)
;QUIT;
%end;

%if (%sysfunc(exist(publicin.tda_mcd_&Periodo_Iteracion.))) %then %do;
PROC SQL NOERRORSTOP ;
create table tda_mcd as 
SELECT 
rut,
venta_tarjeta,
fecha
FROM publicin.tda_mcd_&Periodo_Iteracion.
;RUN; 
%end;
%else %do;
proc sql;
create table tda_mcd
(rut num,
venta_tarjeta num,
fecha num)
;QUIT;
%end;

%if (%sysfunc(exist(publicin.tda_maestro_&Periodo_Iteracion.))) %then %do;
PROC SQL NOERRORSTOP ;
create table tda_maestro as 
SELECT 
rut,
venta_tarjeta,
fecha
FROM publicin.tda_maestro_&Periodo_Iteracion.
;RUN; 
%end;
%else %do;
proc sql;
create table tda_maestro
(rut num,
venta_tarjeta num,
fecha num)
;QUIT;
%end;

/*Definir Comando Query para crear o insertar valores*/
proc sql outobs=1 noprint;

select 
case 
when &Periodo_Iteracion=&Periodo_f then 'create table work.Cli_Uso as ' 
else 'insert into work.Cli_Uso ' 
end as Comando_Query 
into :Comando_Query 
from sashelp.vmember

;quit;
%let Comando_Query="&Comando_Query"; 



/*Rescatar Clientes con Uso*/ 
DATA _NULL_;
Call execute(
cat('
proc sql; 

',&Comando_Query,' 
select  
',&Periodo_Iteracion,' as Periodo, 
rut, 
min(Fecha) as Min_Fecha, 
min(case when base=''SPOS'' then Fecha end) as Min_Fecha_SPOS, 
min(case when base=''TDA'' then Fecha end) as Min_Fecha_TDA, 
sum(Nro) as Nro_TRXs,
sum(case when base=''SPOS'' then Nro end) as Nro_TRXs_SPOS, 
sum(case when base=''TDA'' then Nro end) as Nro_TRXs_TDA, 
sum(Mto) as Mto_TRXs,
sum(case when base=''SPOS'' then Mto end) as Mto_TRXs_SPOS, 
sum(case when base=''TDA'' then Mto end) as Mto_TRXs_TDA 

from ( 


select  
''SPOS'' as base, 
rut,  
sum(venta_tarjeta) as Mto, 
sum(1) as Nro,
min(Fecha) as Fecha   
from (select rut, venta_tarjeta, fecha from  spos_mcd outer union corr 
select rut, venta_tarjeta, fecha from  spos_maestro  ) 
group by  
rut  

outer union corr  

select  
''TDA'' as base, 
rut,
sum(venta_tarjeta) as Mto,
sum(1) as Nro,
min(fecha) as Fecha   
from (select rut, venta_tarjeta, fecha from  tda_mcd outer union corr  
select rut, venta_tarjeta, fecha from  tda_maestro  ) 
group by  
rut  

) as x  
group by  
rut  

;quit;  
')
);
run;


/*actualizar variable de iteracion del while*/
%let Periodo_Iteracion=%sysfunc(SB_Mover_anomes(&Periodo_Iteracion,-1));

%end; /*final del while*/

%mend Macro_Iteracion;

%Macro_Iteracion;



%put==========================================================================================;
%put [03] Pegar Combinatoria de uso (Total y dia);
%put==========================================================================================;

/*Obtener dia de hoy*/
PROC SQL outobs=1 noprint;   

select input(SB_AHORA('DD'),best.) as dia
into :dia 
from sashelp.vmember

;QUIT;



/*Crear Marca*/
PROC SQL;   

create table work.Cli_Uso as  
select 
*,
compress(substr(cats(
case when Min_Fecha_SPOS is not null then '+SPOS' else '' end,
case when Min_Fecha_TDA is not null then '+TDA' else '' end
),2,99)) as Combinatoria_uso_mes,
compress(substr(cats(
case when coalesce(Min_Fecha_SPOS-100*floor(Min_Fecha_SPOS/100),99)<=&dia then '+SPOS' else '' end,
case when coalesce(Min_Fecha_TDA-100*floor(Min_Fecha_TDA/100),99)<=&dia then '+TDA' else '' end,
case when coalesce(Min_Fecha_TDA,0)+coalesce(Min_Fecha_SPOS,0)=0 then '+Sin Uso aun' else '' end 
),2,99)) as Combinatoria_uso_dia 
from work.Cli_Uso 

;QUIT;


%put==========================================================================================;
%put [04] Agregar Iterativamente recencias de USo (Totales y por negocio);
%put==========================================================================================;


%macro Macro_Iteracion;

%let Periodo_Iteracion=&Periodo_f;

%do %while(&Periodo_Iteracion>=&Periodo_i); /*inicio del while*/

%put#####################################################################;
%put######## &Periodo_f --> &Periodo_Iteracion --> &Periodo_i ###########;
%put#####################################################################;


/*Definir Comando Query para crear o insertar valores*/
proc sql outobs=1 noprint;

select 
case 
when &Periodo_Iteracion=&Periodo_f then 'create table work.Cli_Uso2 as ' 
else 'insert into work.Cli_Uso2 ' 
end as Comando_Query 
into :Comando_Query 
from sashelp.vmember

;quit;
%let Comando_Query="&Comando_Query"; 



/*Pegar dato de Recencia por Negocio*/ 
DATA _NULL_;
Call execute(
cat('
proc sql; 

',&Comando_Query,' 
select  
a.*, 
coalesce(SB_meses_entre(b.Max_Periodo,',&Periodo_Iteracion,'),99) as Recencia_Total,
coalesce(SB_meses_entre(b.Max_Periodo_SPOS,',&Periodo_Iteracion,'),99) as Recencia_SPOS,
coalesce(SB_meses_entre(b.Max_Periodo_TDA,',&Periodo_Iteracion,'),99) as Recencia_TDA  
from work.Cli_Uso as a 
left join (
select 
rut,
max(Periodo) as Max_Periodo,
max(case when Min_Fecha_SPOS is not null then Periodo end) as Max_Periodo_SPOS,
max(case when Min_Fecha_TDA is not null then Periodo end) as Max_Periodo_TDA 
from work.Cli_Uso  
where Periodo<',&Periodo_Iteracion,' 
and Periodo>=',%sysfunc(SB_Mover_anomes(&Periodo_Iteracion,-1*&Ventana_Recencia)),'
group by  
rut  
) as b    
on (a.rut=b.rut) 
where Periodo=',&Periodo_Iteracion,' 

;quit;  
')
);
run;


/*actualizar variable de iteracion del while*/
%let Periodo_Iteracion=%sysfunc(SB_Mover_anomes(&Periodo_Iteracion,-1));

%end; /*final del while*/

%mend Macro_Iteracion;

%Macro_Iteracion;


%put==========================================================================================;
%put [05] Agrupar Resultados;
%put==========================================================================================;


proc sql;

create table work.Cli_Uso3 as 
select 
Periodo, 
Combinatoria_uso_mes,
Combinatoria_uso_dia,
Recencia_Total,
Recencia_SPOS,
Recencia_TDA,
count(*) as Nro_Clientes,
sum(Nro_TRXs) as sum_Nro_TRXs,
sum(Nro_TRXs_SPOS) as sum_Nro_TRXs_SPOS, 
sum(Nro_TRXs_TDA) as sum_Nro_TRXs_TDA, 
sum(Mto_TRXs) as sum_Mto_TRXs,
sum(Mto_TRXs_SPOS) as sum_Mto_TRXs_SPOS, 
sum(Mto_TRXs_TDA) as sum_Mto_TRXs_TDA 
from work.Cli_Uso2 
group by 
Periodo, 
Combinatoria_uso_mes,
Combinatoria_uso_dia,
Recencia_Total,
Recencia_SPOS,
Recencia_TDA

;quit; 



%put==========================================================================================;
%put [06] Guardar en base entregable;
%put==========================================================================================;


/*rescatar Fecha del Proceso*/ 
PROC SQL outobs=1 noprint;   

select 
SB_Ahora('DD/MM/AAAA_HH:MM') as Fecha_Proceso 
into :Fecha_Proceso
from sashelp.vmember

;QUIT;
%let Fecha_Proceso="&Fecha_Proceso";


/*Vaciar resultados en tabla entregable*/
DATA _NULL_;
Call execute(
cat('
proc sql; 

CREATE TABLE ',&Base_Entregable,' AS 
select 
''',&Fecha_Proceso,''' as Fecha_Proceso, 
* 
from Cli_Uso3 

;quit; 
')
);
run;



/*Eliminar tabla de paso*/
proc sql; drop table work.Cli_Uso3 ;quit; 
proc sql; drop table work.Cli_Uso2 ;quit; 
proc sql; drop table work.Cli_Uso ;quit; 

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


quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("XIMENA_ZAMORA")
CC = ("&DEST_1", "&DEST_2")
SUBJECT = ("MAIL_AUTOM: Proceso Seguimiento Diario de clientes con Uso");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso Seguimiento Diario de clientes con Uso, ejecutado con fecha: &fechaeDVN";  
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
