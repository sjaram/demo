/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	EDP_LOG_ESPACIO_SAS			================================*/
/* CONTROL DE VERSIONES

/* 2021-04-23 -- V1 -- Lucas Montalba --  
					-- Versión Original
/* INFORMACIÓN:
	Programa para lectura de hitorial de usuarios SAS.

	(IN) Tablas requeridas o conexiones a BD:
	- Archivo /sasdata/users94/userauto/sas-session.log/
*/

/*	VARIABLE LIBRERÍA			*/
%let libreria=RESULT;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/

/* Crear vacía la primera vez en caso de cambiar de librería para que no de error en ejecución */
proc sql noprint;
drop table &libreria..TMP_VISTA;
;quit;

%put====================================================;
%put [01] Declaración variables tiempo;
%put====================================================;

Data _null_;
tiempo_inicio= %sysfunc(datetime());/* inicio del proceso de conteo*/
Call symput("tiempo_inicio",tiempo_inicio) ;
tiempo_inicio_c =  put(tiempo_inicio,NLDATML32.);
Call symput("ftiempo_inicio_c", tiempo_inicio_c);
time_h =  time() ;
Call symput("ftime_h", time_h) ;
time_c = compress(put(time_h,Time10.));
Call symput("ftime_c", time_c) ;
exec_n = compress(input(put(today(),yymmdd10.),$10.),"-");
Call symput("fecha_n",exec_n);
/*exec_c = INPUT(compress(input(put(today(),yymmdd10.),$10.),"-",c),BEST.);*/
exec_n = compress(INPUT(compress(input(put(today(),yymmdd10.),$10.),"-"),BEST.));
Call symput("fecha_c",exec_n);
;run;

	%let arch="/sasdata/users94/userauto/sas-session.log/";
	/*%let arch_log="/sasdata/users94/amunoz/temp/log/sas-session.txt/";*/
	%PUT	&libreria..EDP_ESPACIO_SAS;
	%PUT	&arch;
	%PUT	&arch_log;
	%PUT 	tiempo inicio: &ftiempo_inicio_c;

/*CREAR  CARPETA LOG*/
/*
data _null_;
x rm &arch_log;  
run;

PROC PRINTTO LOG=&arch_log;
RUN;
*/

%put======================================================;
%put[02] FECHA Inicio PROCESO  &ftiempo_inicio_c  ;
%put======================================================;

%put===========================================;
%put[03] Confirmar existencia de log  ;
%put============================================;

%if %sysfunc(fileexist( &arch)) %then %do;
%PUT "Se Cargara Archivo Espacio utilizado en SAS...";
data work.TMP_ESPACIO_SAS;
   infile  "/sasdata/users94/userauto/sas-session.log" truncover;
/*	infile  "/sasdata/users94/amunoz/temp/Entrada/sas-fs.log" truncover;*/
    input variable  $2000.;   
run;


proc sql  noprint;
create table  work.tmp_ESPACIO_SAS2 as 
select 
variable, 
scan(variable,1,"    ") as campo1,
scan(variable,2," ") as campo2,
scan(variable,3,"      ") as campo3,
scan(variable,4,"   ") as campo4,
scan(variable,5,"   ") as campo5,
scan(variable,6,"    ") as campo6,
scan(variable,7,"    ") as campo7,
scan(variable,8,"    ") as campo8,
scan(variable,9,"    ") as campo9,
scan(variable,10,"    ") as campo10
from work.TMP_ESPACIO_SAS;
quit;

%end;


%put===========================================;
%put[04] Confirmar existencia de tabla en sas  ;
%put============================================;

%let var_existe =  0;

%if (%sysfunc(exist(&libreria..EDP_USERS_SAS ))) %then %do;
	%PUT "Archivo " &libreria..EDP_USERS_SAS".....";

	%let var_existe =  1;
	%end;
%else %do;
	%PUT "Crear archivo SAS" &libreria..EDP_USERS_SAS ".....";
	%let var_existe =  0;
	proc sql noprint;
		create table &libreria..EDP_USERS_SAS(
		fecha_carga char(99),
		fecha char(99),
		hora char(99),
		cantidad_sesiones char(99),
		user_id char(99)
		)
	;QUIT;

%end;


%put===========================================;
%put[05]Asigna datos a base temporal ;
%put============================================;

proc sql noprint;
create table &libreria..TMP_VISTA as 
select 

"&fecha_c" as fecha_carga,
monotonic() as ind,
*
from tmp_ESPACIO_SAS2
;QUIT;


proc sql noprint;
select 
fecha_carga as fecha_carga,

compress(campo4,'.') as FECHA,
campo5 as HORA
into
:fecha_carga,

:FECHA,
:HORA
from  &libreria..TMP_VISTA 
where ind=1
;QUIT;

%let fecha_carga_x=&fecha_carga;
%let FECHA_x=&FECHA;

%put fecha_carga_x : &fecha_carga_x;
%put FECHA_x : &FECHA;

proc sql;
create table &libreria..EDP_ESPACIO_SAS_FINAL as 
select "&fecha_carga_x" as fecha_carga,
"&FECHA_x." as fecha,
"&HORA." as hora,
campo1 as cantidad_sesiones,
campo2 as user_id
from &libreria..TMP_VISTA
where ind > 2
;QUIT;

	
%if (%sysfunc(exist(&libreria..EDP_USERS_SAS)))  %then 
%do;
	%put 'crear registro';
	proc sql;
	insert into &libreria..EDP_USERS_SAS
	select 	fecha_carga,
		fecha,
		hora,
		cantidad_sesiones,
		user_id
	from &libreria..EDP_ESPACIO_SAS_FINAL 	
	;QUIT;

	%let  v_existe_x = &v_existe;

%end;
%else %do;
	%PUT "No existe archivo.....";
%end;


%put==============================================;
%put[07] declaracion variables  Bitacora;
%put==============================================;

Data _null_;
  tiempo_fin= %sysfunc(datetime());/* inicio del proceso de conteo*/
  Call symput("tiempo_fin",tiempo_fin) ;
  tiempo_fin_c =  put(tiempo_fin,NLDATML32.);
  Call symput("ftiempo_fin_c", tiempo_fin_c) ;
  time_h =  time() ;
  Call symput("ftime_h", time_h) ;
  time_c = put(time_h,Time10.); /*time_h_x = put(time(),IS8601TM8.);*/
  Call symput("ftime_c", time_c) ;
  /*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
  dur_c = compress(put(datetime() - &tiempo_inicio,time13.2));
  Call symput("dur_c", dur_c) ;

 dur_n = input(scan(compress(put(datetime() - &tiempo_inicio,time13.2)),1,":")||"."||scan(compress(put(datetime() - &tiempo_inicio,time13.2)),2,":") ,best32.  );
   Call symput("dur_n", dur_n) ;
  /*put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';*/
  tdur = datetime() - &tiempo_inicio;
   Call symput("tdur",tdur) ;

  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
  execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
  Call symput("fechaeDVN", execDVN) ;

;RUN;

%put &fechaeDVN;/*fecha ejecucion proceso */

%put==============================================================;
%put[08] FECHA FIN PROCESO  &ftiempo_fin_c;
%put==============================================================;


%put===========================================;
%put[09] FIN PROCESO ;
%put============================================;

/*
proc sql noprint;
create table ver as 
select * from &libreria..EDP_USERS_SAS
;quit;
*/
