/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	EDP_LOG_ESPACIO_SAS			================================*/
/* CONTROL DE VERSIONES
/* 2021-04-21 -- V3 -- Lucas M. --  
					-- Cambios menores de formato del archivo fuente (ind=3)
/* 2020-11-18 -- V3 -- David V. --  
					-- Cambios menores para subir a Server SAS
/* 2020-11-17 -- V2 -- Ana Muñoz --  
					-- Corrección a campo espacio utilizado en tabla resultado
/* 2020-10-20 -- V1 -- Ana Muñoz --  
					-- Versión Original
/* INFORMACIÓN:
	Programa para lectura de log.

	(IN) Tablas requeridas o conexiones a BD:
	- Archivo /sasdata/users94/userauto/sas-fs.log/

	(OUT) Tablas de Salida o resultado:
	- RESULT.EDP_ESPACIO_SAS
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

%let arch="/sasdata/users94/userauto/sas-fs.log/";
/*%let arch_log="/sasdata/users94/amunoz/temp/log/sas-fs_log.txt/";*/
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
   infile  "/sasdata/users94/userauto/sas-fs.log" truncover;
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
%else %do;
%PUT "No se Cargara Archivo "&arch "Por que no existe en la Ruta.....";

			proc sql noprint;                              
			SELECT EMAIL into :EDP_BI 
				FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

			SELECT EMAIL into :DEST_1 
				FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

			SELECT EMAIL into :DEST_2
				FROM result.EDP_BI_DESTINATARIOS  WHERE CODIGO = 'ANA_MUNOZ';
			quit;

			%put &=EDP_BI;
			%put &=DEST_1;
			%put &=DEST_2;

			data _null_;
			FILENAME OUTBOX EMAIL
			FROM = ("&EDP_BI")
			TO = ("&DEST_1")
			/*TO = ("&DEST_1","&DEST_2")*/
			SUBJECT="MAIL_AUTOM: PROCESO ESPACIO UTILIZADO EN SAS - NOK" ;
			FILE OUTBOX;
			PUT 'Estimados:';
			PUT ; 
			 put "Proceso Espacio utilizado en SAS, ejecutado con fecha: &fechaeDVN";  
			 put ;
			 put ; 
			 put ; 
			 PUT " --- SIN ARCHIVO EN LA RUTA PARA PROCESAR --- ";
			 put ; 
			 PUT ;
			 PUT ;
			 PUT ;
			 PUT ;
			 put 'Proceso Vers. 04'; 
			 PUT ;
			 PUT ;
			PUT 'Atte.';
			Put 'Equipo Datos y Procesos BI';
			PUT ;
			PUT ;
			PUT ;
			RUN;
			FILENAME OUTBOX CLEAR;
%end;

%put===========================================;
%put[04] Confirmar existencia de tabla en sas  ;
%put============================================;

%let var_existe =  0;

%if (%sysfunc(exist(&libreria..EDP_ESPACIO_SAS ))) %then %do;
	%PUT "Archivo " &libreria..EDP_ESPACIO_SAS".....";

	%let var_existe =  1;
	%end;
%else %do;
	%PUT "Crear archivo SAS" &libreria..EDP_ESPACIO_SAS ".....";
	%let var_existe =  0;
	proc sql noprint;
		create table &libreria..EDP_ESPACIO_SAS(
		fecha_carga char(99),
		fecha char(99),
		hora char(99),
		Filesystem char(99),
		MB_bloks char(99),
		Free char(99),
		por_Used char(99),
		Iused char(99),
		por_Iused char(99),
		Mounted_on CHAR(99)
		)
	;QUIT;

%end;


PROC SQL noprint;
SELECT COUNT(*)  AS TOTAL  INTO :TOTAL_INI
FROM &libreria..EDP_ESPACIO_SAS
;QUIT;

%put exite : &var_existe ;
/*
Data _tmp_;
tiempo_inicio= %sysfunc(datetime());
Call symput("tiempo_inicio",tiempo_inicio) ;
exec_n = compress(input(put(today(),yymmdd10.),$10.),"-");
Call symput("fecha_n",exec_n);
;run;
*/
%put===========================================;
%put[05]Asigna datos a base temporal ;
%put============================================;

proc sql noprint;
create table &libreria..TMP_VISTA as 
select 
/*year(today())*10000+month(today())*100+day(today())*/  
"&fecha_c" as fecha_carga,
monotonic() as ind,
*
from tmp_ESPACIO_SAS2
;QUIT;


proc sql noprint;
select 
fecha_carga as fecha_carga,
campo1 as campo1,
compress(campo4,'.') as FECHA,
campo5 as HORA
into
:fecha_carga,
:campo1,
:FECHA,
:HORA
from  &libreria..TMP_VISTA 
where ind=1
;QUIT;

%let fecha_carga_x=&fecha_carga;
%let FECHA_x=&FECHA;

%put fecha_carga_x : &fecha_carga_x;
%put FECHA_x : &FECHA;

/*Filesystem	MB	Free	used	por_Used	Iused	por_Iused
/dev/fslv06	6541312.00	455709.52	94%	41307	1%	/sasdata
*/
/*proc sql  noprint;*/

proc sql noprint;

select 
campo1 as Filesystem,
campo2 as MB_blocks,
campo3    as  free,
campo4    as  por_Used,
campo5    as  Ised,
campo6    as por_Iused, 
campo7 as Mounted_on
into 
:Filesystem,
:MB_blocks,
:free,
:por_Used,
:Iused,
:por_Iused, 
:Mounted_on
from &libreria..TMP_VISTA 
where ind=3
;QUIT;

%let Filesystem=&Filesystem;
%let MB_blocks=&MB_blocks;
%let Free=&Free;
%let por_Used=&por_Used;
%let Iused=&Iused;
%let por_Iused=&por_Iused;
%let Mounted_on =&Mounted_on;

	
%if (%sysfunc(exist(&libreria..EDP_ESPACIO_SAS)))  %then 
%do;
	%put 'crear registro';
	proc sql;
	insert into &libreria..EDP_ESPACIO_SAS
	values ("&fecha_carga_x",
	"&FECHA_x.",
	"&HORA.",
	"&Filesystem." ,
	"&MB_blocks.",
	"&Free.",
	"&por_Used.",
	"&Iused.",
	"&por_Iused.",
    "&Mounted_on.")
	;QUIT;

	%let  v_existe_x = &v_existe;

%end;
%else %do;
	%PUT "No existe archivo.....";
%end;


PROC SQL noprint;
SELECT COUNT(*)  AS TOTAL  INTO :TOTAL_FIN
FROM &libreria..EDP_ESPACIO_SAS 
;QUIT;



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

TOTAL_FINAL = &TOTAL_FIN - &TOTAL_INI;
    Call symput("TOTAL_FINAL",TOTAL_FINAL) ;
;RUN;

%PUT "Registros existentes" &TOTAL_INI; 
%PUT "Registros existentesalfinaldelproceso " &TOTAL_FIN;
%PUT "Registros cargados " &TOTAL_FINAL;

%put &fechaeDVN;/*fecha ejecucion proceso */

%put==============================================================;
%put[08] FECHA FIN PROCESO  &ftiempo_fin_c;
%put==============================================================;


%put=============================================;
%put[09] ENVÍO DE CORREO CON MAIL VARIABLE ; 
%put============================================;

/*			FIN : CONTROL ANA MUÑOZ			*/
/*	=========================================================================	*/


/*	=========================================================================	*/
/*			INI : CONTROL TIEMPO Y CORREO			*/

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/

proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2
	FROM result.EDP_BI_DESTINATARIOS  WHERE CODIGO = 'ANA_MUNOZ';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
/*TO = ("&DEST_1")*/
TO = ("&DEST_1","&DEST_2")
SUBJECT="MAIL_AUTOM: PROCESO ESPACIO UTILIZADO EN SAS" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso Espacio utilizado en SAS, ejecutado con fecha: &fechaeDVN";  
 put ;
 put ; 
 put ; 
 PUT "Total de Registros Cargados &TOTAL_FINAL";
 put ; 
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 04'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

%put===========================================;
%put[10] FIN PROCESO ;
%put============================================;


proc sql noprint;
create table ver as 
select * from &libreria..EDP_ESPACIO_SAS
;quit;
