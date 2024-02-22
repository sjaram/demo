/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*============================= Proceso Seguimiento Diario de clientes con Uso ===============================*/
/* CONTROL DE VERSIONES

/*2022-04-28  -- V3 --  Pedro Muñoz -- fijación de periodo inicial y periodo final*/
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
%let Ventana_Tiempo=24; /*Ventana para seguimiento*/
%let Ventana_Recencia=6; /*Ventana para recencia de Activacion*/
%let Base_Entregable=%nrstr('result.Clientes_USO_diario'); /*Nombre de Base Entregable*/
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
min(case when base=''PPFF'' then Fecha end) as Min_Fecha_PPFF,
sum(Nro) as Nro_TRXs,
sum(case when base=''SPOS'' then Nro end) as Nro_TRXs_SPOS, 
sum(case when base=''TDA'' then Nro end) as Nro_TRXs_TDA, 
sum(case when base=''PPFF'' then Nro end) as Nro_TRXs_PPFF, 
sum(Mto) as Mto_TRXs,
sum(case when base=''SPOS'' then Mto end) as Mto_TRXs_SPOS, 
sum(case when base=''TDA'' then Mto end) as Mto_TRXs_TDA, 
sum(case when base=''PPFF'' then Mto end) as Mto_TRXs_PPFF 

from (


select 
''SPOS'' as base,
rut, 
sum(venta_tarjeta) as Mto,
sum(1) as Nro,
min(Fecha) as Fecha  
from publicin.SPOS_AUT_',&Periodo_Iteracion,'  
group by 
rut 

outer union corr 

select 
''TDA'' as base, 
rut,
sum(capital+pie) as Mto,
sum(case when capital>=0 then 1 else -1 end) as Nro,
min(10000*year(FECHA)+100*month(FECHA)+day(FECHA)) as Fecha  
from publicin.TDA_ITF_',&Periodo_Iteracion,' 
group by 
rut 

outer union corr 

select 
''PPFF'' as base, 
rut,
sum(capital) as Mto,
count(*) as Nro, 
min(input(compress(FECFAC,''-''),best.)) as Fecha  
from publicin.TRX_SAV_',&Periodo_Iteracion,' 
group by 
rut 

outer union corr 

select 
''PPFF'' as base, 
rut,
sum(capital) as Mto,
count(*) as Nro, 
min(input(compress(FECFAC,''-''),best.)) as Fecha  
from publicin.TRX_AV_',&Periodo_Iteracion,' 
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
case when Min_Fecha_TDA is not null then '+TDA' else '' end,
case when Min_Fecha_PPFF is not null then '+PPFF' else '' end 
),2,99)) as Combinatoria_uso_mes,
compress(substr(cats(
case when coalesce(Min_Fecha_SPOS-100*floor(Min_Fecha_SPOS/100),99)<=&dia then '+SPOS' else '' end,
case when coalesce(Min_Fecha_TDA-100*floor(Min_Fecha_TDA/100),99)<=&dia then '+TDA' else '' end,
case when coalesce(Min_Fecha_PPFF-100*floor(Min_Fecha_PPFF/100),99)<=&dia then '+PPFF' else '' end,
case when coalesce(Min_Fecha_PPFF,0)+coalesce(Min_Fecha_TDA,0)+coalesce(Min_Fecha_SPOS,0)=0 then '+Sin Uso aun' else '' end 
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
coalesce(SB_meses_entre(b.Max_Periodo_TDA,',&Periodo_Iteracion,'),99) as Recencia_TDA,
coalesce(SB_meses_entre(b.Max_Periodo_PPFF,',&Periodo_Iteracion,'),99) as Recencia_PPFF 
from work.Cli_Uso as a 
left join (
select 
rut,
max(Periodo) as Max_Periodo,
max(case when Min_Fecha_SPOS is not null then Periodo end) as Max_Periodo_SPOS,
max(case when Min_Fecha_TDA is not null then Periodo end) as Max_Periodo_TDA,
max(case when Min_Fecha_PPFF is not null then Periodo end) as Max_Periodo_PPFF 
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
Recencia_PPFF,
count(*) as Nro_Clientes,
sum(Nro_TRXs) as sum_Nro_TRXs,
sum(Nro_TRXs_SPOS) as sum_Nro_TRXs_SPOS, 
sum(Nro_TRXs_TDA) as sum_Nro_TRXs_TDA, 
sum(Nro_TRXs_PPFF) as sum_Nro_TRXs_PPFF, 
sum(Mto_TRXs) as sum_Mto_TRXs,
sum(Mto_TRXs_SPOS) as sum_Mto_TRXs_SPOS, 
sum(Mto_TRXs_TDA) as sum_Mto_TRXs_TDA, 
sum(Mto_TRXs_PPFF) as sum_Mto_TRXs_PPFF 
from work.Cli_Uso2 
group by 
Periodo, 
Combinatoria_uso_mes,
Combinatoria_uso_dia,
Recencia_Total,
Recencia_SPOS,
Recencia_TDA,
Recencia_PPFF 

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
