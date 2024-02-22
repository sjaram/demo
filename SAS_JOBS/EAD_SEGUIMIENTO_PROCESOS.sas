/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================    EAD_SEGUIMIENTO_PROCESOS	================================*/
/* CONTROL DE VERSIONES
/* 2023-06-08 -- v15 -- Esteban P	-- Se añade nuevo destinatario para tabla de salida vía correo para procesos ejecutados.
/* 2022-10-28 -- v14 -- David V.	-- Se actualizar export a AWS, según nuevas definiciones a RAW.
/* 2022-09-30 -- v13 -- Sergio J.	-- Se agrega envío por correo de procesos no ejecutados.
/* 2022-08-24 -- v11 -- David V.	-- Nueva versión de eliminación/export a AWS.
/* 2022-07-15 -- V10 -- David V.	-- Corrección a archivos de salida para nuevo "flujo oracloud".
/* 2022-04-25 -- V01 -- Esteban P. 	-- Versión Original
Descripcion:
Genera un seguimiento general de la información contenida en los logs de los procesos automáticos y su
estado de ejecución.
*/

/*comando necesario para invocar funciones dentro de proc sql*/
options cmplib=sbarrera.funcs; 

/* --- Generamos la tabla con la hora a la que se ejecutó el proceso. --- */
PROC SQL OUTOBS=1 NOPRINT;
	CREATE TABLE EAD_FECHA_ACT AS
		SELECT
		SB_AHORA('DD/MM/AAAA_HH:MM') AS ULTIMA_ACTUALIZACION
		FROM SASHELP.VMEMBER;
QUIT;

/* --- Se asigna la variable librería. ---*/
%let libreria=RESULT;
/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

options validvarname=any;

/* --- Se crea la variable fecha del día de hoy con el formato que necesitamos. --- */
data _null_;
length fecha $ 10;
fecha = TRIM(substr(compress(input(put(today(),yymmdd10.),$10.),"-",""),1,4)||"."||
			substr(compress(input(put(today(),yymmdd10.),$10.),"-",""),5,2)||"."||
			substr(compress(input(put(intnx('day',today(),-0),yymmdd10.),$10.),"-",""),7,2));
Call symput("fecha", fecha) ; 
RUN;

/* --- Se recopila la información de los procesos ejecutados hasta el momento del día de hoy. --- */
/* --- Se utiliza para obtener principalmente la última hora de modificación del proceso. --- */
/* --- Se almacena en el archivo de texto procesos_fecha_termino.txt en SFTP. --- */
x 'cd /sasbin/SASConfig/Lev1/SASApp/BatchServer/Logs';
%let cmd2=ls -l *&fecha*.log > procesos_fecha_termino.txt;
x &cmd2;

/* --- Importamos desde el archivo de texto que está en el SFTP. --- */
proc import file="/sasbin/SASConfig/Lev1/SASApp/BatchServer/Logs/procesos_fecha_termino.txt" 
out=procesos_fecha_termino
dbms=tab
replace;
getnames=NO;
guessingrows=max;
run;

/* --- Utilizamos la tabla importada para crear otra en la que estarán los datos transformados y formateados. --- */
proc sql;
	create table HORA_TERMINO as
		select  UPCASE(substr(scan(var1, 9, " "), 1, length(scan(var1, 9, " "))-24)) as NOMBRE_PROCESO,
				/*input(scan(var1,8," ") || ":" || "00", time10.) format = time10. as hora_termino,*/
				time()format=time10. as hora_inicio,
				time()-input(scan(var1,8," ") || ":" || "00", time10.) format=time10. as diferencia_hora5,
				IFC(SUBSTR(scan(var1,8," "),1,2)= "00", "12:" || SUBSTR(scan(var1,8," "),4,2),scan(var1,8," ")) as HORA_TERMINO
		from procesos_fecha_termino;
quit;



/* --- Nos dirigimos al directorio donde se encuentran los logs. --- */
/* --- Filtramos los registros a la fecha de hoy y que dentro de su conenido contengan "Sistema SAS" para obtener la hora interna. --- */
/* --- Finalmente se guardan los registros en un archivo de texto llamado "hora_interna.txt". --- */
x 'cd /sasbin/SASConfig/Lev1/SASApp/BatchServer/Logs';
%let cmd=grep "Sistema SAS" *&fecha*.log > hora_interna.txt;
x &cmd.;


/* --- Importamos el archivo de texto que generamos con los registros. --- */
/* --- Los registros quedan guardados y se sobreescriben en "procesos_hora_interna". --- */
proc import file="/sasbin/SASConfig/Lev1/SASApp/BatchServer/Logs/hora_interna.txt" 
out=procesos_hora_interna
dbms=tab
replace;
getnames=NO;
guessingrows=max;
run;

/* --- Creamos la tabla en SAS con los registros y los dividimos los campos que requerimos. --- */
/* --- NOMBRE_PROCESO, HORA_INICIO--- */
proc sql;
	CREATE TABLE PROCESO_HORA_INICIO_INTERNA AS
		SELECT UPCASE(substr(var1, 1, find(var1, "_" || put(year(today()),4.))-1)) as NOMBRE_PROCESO,
				compress(scan(var1, 4, " ")) AS HORA_INICIO_I,
				var1
		FROM PROCESOS_HORA_INTERNA;

quit;

/*----------------------------------------------------------------------------*/

/*-------- INICIO PROCESO PARTE 1 ERRORES EN EJECUCIÓN DE LOS PROCESOS -------*/

/*----------------------------------------------------------------------------*/

/* --- Nos dirigimos al directorio donde se almacenan los logs. --- */
/* --- Filtramos para obtener los logs que contengan "ERROR" en su script y que correspondan a la fecha del día de hoy.--- */
/* --- Se crea un archivo de texto "salida_logs_error.txt" con los registros que coinciden con el filtro. --- */
x 'cd /sasbin/SASConfig/Lev1/SASApp/BatchServer/Logs';
%let cmd=grep "ERROR:" *&fecha*.log > salida_logs_error.txt;
x &cmd.;


/* --- Importamos el archivo de texto que generamos con los registros. --- */
/* --- Los registros quedan guardados y se sobreescriben en "salida_errores". --- */
proc import file="/sasbin/SASConfig/Lev1/SASApp/BatchServer/Logs/salida_logs_error.txt" 
out=salida_errores
dbms=tab
replace;
getnames=NO;
run;



/* --- Se crea una tabla con una consulta que divide el registro log en varios campos: --- */
/* --- NOMBRE_PROCESO, ESTADO, FECHA_EXEC_PROCESO y HORA_EXEC_PROCESO. --- */
proc sql;
	create table REG_PROC_ERRORES_HOY as
		select UPCASE(substr(var1, 1, find(var1, "_" || put(year(today()),4.))-1)) as NOMBRE_PROCESO,
				substr(var1, find(var1, "ERROR:"), length(var1)) as ESTADO,
				"&fecha" as FECHA_EXEC_PROCESO,
				compress(substr(var1, find(var1,put(year(today()),4.))+11,5)) as HORA_EXEC_PROCESO
		from salida_errores;
quit;


/* --- Se importan los datos de todos los procesos como tabla madre. --- */

DATA WORK.EDP_TABLA_MADRE_PROCESOS;
    LENGTH
        NOMBRE           $ 100
        PLANIFICACION    $ 25
        HORA_PLANIFICADA $ 5 
		TIPO_PROCESO	 $ 1;
    FORMAT
        NOMBRE           $CHAR100.
        PLANIFICACION    $CHAR25.
        HORA_PLANIFICADA $CHAR5. 
		TIPO_PROCESO	 $CHAR1. ;
    INFORMAT
        NOMBRE           $CHAR100.
        PLANIFICACION    $CHAR25.
        HORA_PLANIFICADA $CHAR5. 
		TIPO_PROCESO	 $CHAR1. ;
    INFILE '/sasdata/users94/user_bi/EAD_Seguimiento_Procesos/EDP_TABLA_MADRE_PROCESOS.csv'
        DELIMITER=';'
		;
    INPUT
        NOMBRE           : $CHAR100.
        PLANIFICACION    : $CHAR25.
        HORA_PLANIFICADA : $CHAR5. 
		TIPO_PROCESO	 : $CHAR1. ;
RUN;


/* --- Cruce de tablas entre madre y errores. --- */
proc sql;
	create table CRUCE_MADRE_ERROR as
		select *
		from EDP_TABLA_MADRE_PROCESOS A
		left join REG_PROC_ERRORES_HOY V
		on UPCASE(A.NOMBRE)=V.NOMBRE_PROCESO;
quit;

/* FIN PARTE 1 PROCESOS_ERROR*/

/*----------------------------------------------------------------------------*/

/*-------- INICIO PROCESO PARTE 2 EJECUCIÓN Y FINALIZACIÓN DE PROCESOS -------*/

/*----------------------------------------------------------------------------*/

/* --- Se crea la variable fecha del día de hoy con el formato que necesitamos. --- */
data _null_;
length fecha $ 10;
fecha = TRIM(substr(compress(input(put(today(),yymmdd10.),$10.),"-",""),1,4)||"."||
			substr(compress(input(put(today(),yymmdd10.),$10.),"-",""),5,2)||"."||
			substr(compress(input(put(today(),yymmdd10.),$10.),"-",""),7,2));
Call symput("fecha", fecha) ; 
RUN;

/* --- Nos dirigimos al directorio donde se almacenan los logs. --- */
/* --- Filtramos para obtener los logs que contengan "NOTE: SAS Institute Inc." en su script y que correspondan a la fecha del día de hoy.--- */
/* --- Se crea un archivo de texto "salida_logs_ejecucion_ok.txt" con los registros que coinciden con el filtro. --- */
x 'cd /sasbin/SASConfig/Lev1/SASApp/BatchServer/Logs';
%let cmd=grep "NOTE: SAS Institute Inc." *&fecha*.log > salida_logs_ejecucion_ok.txt;
x &cmd.;

/* --- Importamos el archivo de texto que generamos con los registros. --- */
/* --- Los registros quedan guardados y se sobreescriben en "salida_ejecucion_ok". --- */
proc import file="/sasbin/SASConfig/Lev1/SASApp/BatchServer/Logs/salida_logs_ejecucion_ok.txt" 
out=salida_ejecucion_ok
dbms=tab
replace;
getnames=NO;
run;



/* --- Se crea una tabla con una consulta que divide el registro log en varios campos: --- */
/* --- NOMBRE_PROCESO, ESTADO, FECHA_EXEC_PROCESO y HORA_EXEC_PROCESO. --- */
proc sql;
	create table REC_PROC_EJEC_HOY as
		select UPCASE(substr(var1, 1, find(var1, "_" || put(year(today()),4.))-1)) as NOMBRE_PROCESO,
				"Proceso finalizado correctamente" as ESTADO,
				"&fecha" as FECHA_EXEC_PROCESO,
				compress(substr(var1, find(var1,put(year(today()),4.))+11,5)) as HORA_EXEC_PROCESO
		from salida_ejecucion_ok;
quit;


/* --- Se importan los datos de todos los procesos como tabla madre. --- */
DATA WORK.EDP_TABLA_MADRE_PROCESOS;
    LENGTH
        NOMBRE           $ 100
        PLANIFICACION    $ 25
        HORA_PLANIFICADA $ 5 
		TIPO_PROCESO	 $ 1;
    FORMAT
        NOMBRE           $CHAR100.
        PLANIFICACION    $CHAR25.
        HORA_PLANIFICADA $CHAR5. 
		TIPO_PROCESO	 $CHAR1. ;
    INFORMAT
        NOMBRE           $CHAR100.
        PLANIFICACION    $CHAR25.
        HORA_PLANIFICADA $CHAR5. 
		TIPO_PROCESO	 $CHAR1. ;
    INFILE '/sasdata/users94/user_bi/EAD_Seguimiento_Procesos/EDP_TABLA_MADRE_PROCESOS.csv'
        DELIMITER=';'
		;
    INPUT
        NOMBRE           : $CHAR100.
        PLANIFICACION    : $CHAR25.
        HORA_PLANIFICADA : $CHAR5. 
		TIPO_PROCESO	 : $CHAR1. ;
RUN;



/* --- Cruce de tablas entre madre y errores. --- */
proc sql;
	create table CRUCE_MADRE_EJEC as
		select *
		from EDP_TABLA_MADRE_PROCESOS A
		left join REC_PROC_EJEC_HOY V
		on UPCASE(A.NOMBRE)=V.NOMBRE_PROCESO;
quit;

/* FIN PARTE 2 PROCESOS_EJEC */

/*----------------------------------------------------------------------------*/

/*-------- INICIO PROCESO PARTE 3 INICIALIZACIÓN DE PROCESOS -----------------*/

/*----------------------------------------------------------------------------*/

/* --- Se crea la variable fecha del día de hoy con el formato que necesitamos. --- */
data _null_;
length fecha $ 10;
fecha = TRIM(substr(compress(input(put(today(),yymmdd10.),$10.),"-",""),1,4)||"."||
			substr(compress(input(put(today(),yymmdd10.),$10.),"-",""),5,2)||"."||
			substr(compress(input(put(today(),yymmdd10.),$10.),"-",""),7,2));
Call symput("fecha", fecha) ; 
RUN;

/* --- Nos dirigimos al directorio donde se almacenan los logs. --- */
/* --- Filtramos para obtener los logs que contengan "You are running SAS 9." en su script y que correspondan a la fecha del día de hoy.--- */
/* --- Se crea un archivo de texto "salida_logs_ejecucion_ok.txt" con los registros que coinciden con el filtro. --- */
x 'cd /sasbin/SASConfig/Lev1/SASApp/BatchServer/Logs';
%let cmd=grep "You are running SAS 9." *&fecha*.log > salida_logs_inicializados.txt;
x &cmd.;

/* --- Importamos el archivo de texto que generamos con los registros. --- */
/* --- Los registros quedan guardados y se sobreescriben en "salida_inicializados". --- */
proc import file="/sasbin/SASConfig/Lev1/SASApp/BatchServer/Logs/salida_logs_inicializados.txt" 
out=salida_inicializados
dbms=tab
replace;
getnames=NO;
run;



/* --- Se crea una tabla con una consulta que divide el registro log en varios campos: --- */
/* --- NOMBRE_PROCESO, ESTADO, FECHA_EXEC_PROCESO y HORA_EXEC_PROCESO. --- */
proc sql;
	create table REC_PROC_INI_HOY as
		select UPCASE(substr(var1, 1, find(var1, "_" || put(year(today()),4.))-1)) as NOMBRE_PROCESO,
				"Proceso inicializado correctamente" as ESTADO,
				"&fecha" as FECHA_EXEC_PROCESO,
				compress(substr(var1, find(var1,put(year(today()),4.))+11,5)) as HORA_EXEC_PROCESO
		from salida_inicializados;
quit;


/* --- Se importan los datos de todos los procesos como tabla madre. --- */
DATA WORK.EDP_TABLA_MADRE_PROCESOS;
    LENGTH
        NOMBRE           $ 100
        PLANIFICACION    $ 25
        HORA_PLANIFICADA $ 5 
		TIPO_PROCESO	 $ 1;
    FORMAT
        NOMBRE           $CHAR100.
        PLANIFICACION    $CHAR25.
        HORA_PLANIFICADA $CHAR5. 
		TIPO_PROCESO	 $CHAR1. ;
    INFORMAT
        NOMBRE           $CHAR100.
        PLANIFICACION    $CHAR25.
        HORA_PLANIFICADA $CHAR5. 
		TIPO_PROCESO	 $CHAR1. ;
    INFILE '/sasdata/users94/user_bi/EAD_Seguimiento_Procesos/EDP_TABLA_MADRE_PROCESOS.csv'
        DELIMITER=';'
		;
    INPUT
        NOMBRE           : $CHAR100.
        PLANIFICACION    : $CHAR25.
        HORA_PLANIFICADA : $CHAR5. 
		TIPO_PROCESO	 : $CHAR1. ;
RUN;



/* --- Cruce de tablas entre madre e inicializados. --- */
proc sql;
	create table CRUCE_MADRE_INI as
		select *
		from EDP_TABLA_MADRE_PROCESOS A
		left join REC_PROC_INI_HOY V
		on UPCASE(A.NOMBRE)=V.NOMBRE_PROCESO;
quit;

/* FIN PARTE 3 PROCESOS_INI*/

/*----------------------------------------------------------------------------*/

/*-------- INICIO PROCESO PARTE 4 (FINAL) UNION DE TODAS LAS TABLAS ----------*/

/*----------------------------------------------------------------------------*/

/* --- Captura de inicializados. --- */
proc sql;
	create table ini_only as
		select *
		from cruce_madre_ini
		where nombre_proceso is not null;
quit;

/* --- Captura de errores. --- */
proc sql;
	create table errores_only as
		select *
		from cruce_madre_error
		where nombre_proceso is not null;
quit;

/* --- Captura de ejecutados/finalizados. --- */
proc sql;
	create table ejec_only as
		select *
		from cruce_madre_ejec
		where nombre_proceso is not null;
quit;

/* --- Ejecutados sin errores --- */
proc sql;
	create table ejecutados_sin_errores as
		select *
		from ejec_only
		where nombre not in (select nombre from errores_only);
quit;

/* --- Inicializados sin errores ni finalizados. --- */
proc sql;
	create table ini_sin_fin_ni_error as
		select *
		from ini_only
		where nombre not in (select nombre from errores_only) and nombre not in (select nombre from ejecutados_sin_errores);
quit;

/* --- Enviamos la información deseada a RESULT. --- */
proc sql;
	create table &libreria..SOLO_INI as
		select *
		from ini_sin_fin_ni_error;
quit;

proc sql;
	create table &libreria..SOLO_ERROR as
		select *
		from errores_only;
quit;

proc sql;
	create table &libreria..SOLO_EJEC as
		select *
		from ejecutados_sin_errores;
quit;

proc sql;
	create table &libreria..EAD_FECHA_EJEC as
		select *
		from EAD_FECHA_ACT;
quit;

/* --- Unión de los procesos que: --- */
/* --- Arrojaron error. --- */
/* --- Se ejecutaron/finalizaron sin errores. --- */
/* --- Se iniciaron sin errores ni han finalizado. --- */
proc sql;
	create table union_procesos_all as
		select *
		from ini_sin_fin_ni_error
		union
		select *
		from ejecutados_sin_errores
		union
		select *
		from errores_only;
quit;

/* --- ESTADO_CODIGO. B. --- */
proc sql;
	create table union_procesos_all_final as
		SELECT NOMBRE, PLANIFICACION, HORA_PLANIFICADA, NOMBRE_PROCESO, ESTADO, FECHA_EXEC_PROCESO, HORA_EXEC_PROCESO, TIPO_PROCESO,
		CASE
		WHEN ESTADO LIKE '%ERROR%' THEN 'ERROR'
		WHEN ESTADO LIKE '%inicializado%' THEN 'INICIADO'
		WHEN ESTADO LIKE '%finalizado%' THEN 'FINALIZADO' END AS ESTADO_PROCESO,
		CASE
		WHEN ESTADO LIKE '%ERROR%' THEN 0
		WHEN ESTADO LIKE '%inicializado%' THEN 1
		WHEN ESTADO LIKE '%finalizado%' THEN 2 END AS ESTADO_CODIGO
		FROM union_procesos_all;
quit;

/* --- Tabla final con hora término implementada. --- */
proc sql;
	create table union_procesos_all_final_2 as
		SELECT INPUT(COMPRESS(TRANWRD(HORA_EXEC_PROCESO, ".", ":") || ":" || "00"), time10.) format=time10. as HORA_INICIO,
		A.*, B.HORA_TERMINO,
		INPUT(B.HORA_TERMINO, time10.) - INPUT(COMPRESS(TRANWRD(HORA_EXEC_PROCESO, ".", ":") || ":" || "00"), time10.) format=time10. as TIEMPO_DE_EJECUCION
		FROM UNION_PROCESOS_ALL_FINAL A
		LEFT JOIN HORA_TERMINO B
		ON (A.NOMBRE_PROCESO=B.NOMBRE_PROCESO);
quit;

/* --- Tabla con DISTINCT de la hora inicial interna de los procesos. --- */
proc sql;
	create table hora_inicio_interna_dist as
		SELECT DISTINCT(nombre_proceso), hora_inicio_i
		FROM PROCESO_HORA_INICIO_INTERNA;
quit;

/* --- Tabla final con hora inicio interna implementada (Matching de procesos). --- */
proc sql;
	create table union_procesos_all_final_3 as
		SELECT DISTINCT NOMBRE, PLANIFICACION, HORA_PLANIFICADA, ESTADO_CODIGO, ESTADO_PROCESO, ESTADO, TIPO_PROCESO,
		FECHA_EXEC_PROCESO, HORA_EXEC_PROCESO, HORA_INICIO_I, HORA_TERMINO, HORA_INICIO,
		INPUT(HORA_TERMINO, time10.) - INPUT(HORA_INICIO_I, time10.) format=time10. as TIEMPO_DE_EJECUCION
		FROM UNION_PROCESOS_ALL_FINAL_2 A
		INNER JOIN HORA_INICIO_INTERNA_DIST B
		ON A.NOMBRE_PROCESO=B.NOMBRE_PROCESO;
quit;

/* --- Se envía la tabla final a RESULT. --- */
proc sql;
	create table &libreria..ESTADO_PROCESO_ACTUAL as
		select *
		from union_procesos_all_final_3
		where HORA_PLANIFICADA NE "NA";
quit;

proc sql;
drop table union_procesos_all_final_3;
quit;

/* FIN PARTE FINAL PROCESOS_UNION_TODOS*/

/* ---------------------------------------- */
/* --- PARTE 5 --- */
/* --- SEGUIMIENTO DE EJECUCIÓN DIARIA. --- */

proc sql;
	CREATE TABLE EDP_TM_EJEC_DIARIA AS
		SELECT *
		FROM EDP_TABLA_MADRE_PROCESOS
		WHERE PLANIFICACION="todos los días";

quit;

proc sql;
	CREATE TABLE CRUCE_TM_INI_ONLY AS
		SELECT *
		FROM EDP_TM_EJEC_DIARIA A
		LEFT JOIN INI_ONLY B
		ON A.NOMBRE=B.NOMBRE;
quit;

proc sql;
	CREATE TABLE SEGUIM_EJEC_NO_EJEC AS
		SELECT NOMBRE, PLANIFICACION, TIPO_PROCESO, HORA_PLANIFICADA, ESTADO,
				FECHA_EXEC_PROCESO, HORA_EXEC_PROCESO,
				CASE
					WHEN ESTADO = "Proceso inicializado correctamente" THEN 1
					ELSE 0
					END AS ESTADO_COD
		FROM CRUCE_TM_INI_ONLY;
quit;

DATA NO_EJECUTADOS;
SET SEGUIM_EJEC_NO_EJEC;
WHERE ESTADO="";
RUN;

/* --- Enviamos la información a RESULT y a ORACLOUD. --- */
proc sql;
	CREATE TABLE &libreria..SEGUIM_EJEC_NO_EJEC AS
		SELECT *
		FROM SEGUIM_EJEC_NO_EJEC;
quit;

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================        EXPORT_TO_AWS - INI          ===============================*/

/*Tabla_1*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(earq_estado_proceso_actual,raw,oracloud,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(earq_estado_proceso_actual,&libreria..estado_proceso_actual,raw,oracloud,0);

/*Tabla_2*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(earq_fecha_ejec,raw,oracloud,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(earq_fecha_ejec,&libreria..ead_fecha_ejec,raw,oracloud,0);

/*Tabla_3*/
/*#########################################################*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(earq_seguim_ejec_no_ejec,raw,oracloud,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(earq_seguim_ejec_no_ejec,&libreria..seguim_ejec_no_ejec,raw,oracloud,0);


/*==============================        EXPORT_TO_AWS - END          ===============================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

/*==================================================================================================*/
/*==================================    EQUIPO DATOS Y PROCESOS     ================================*/
/*  VARIABLE TIEMPO - FIN   */
data _null_;
    dur = datetime() - &tiempo_inicio;
    put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;
/*==================================    FECHA DEL PROCESO           ================================*/
data _null_;
    execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
    Call symput("fechaeDVN", execDVN);
RUN;
%put &fechaeDVN;
/*==================================    EMAIL CON CASILLA VARIABLE  ================================*/
proc sql noprint;
    SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
    SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
    SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
quit;
%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	

data _null_;
    FILENAME OUTBOX EMAIL
        FROM = ("&EDP_BI")
        TO = ("&DEST_1", "&DEST_2", "&DEST_3")
        SUBJECT = ("MAIL_AUTOM: Proceso EAD_SEGUIMIENTO_PROCESOS");
    FILE OUTBOX;
    PUT "Estimados:";
    put "   Proceso EAD_SEGUIMIENTO_PROCESOS, ejecutado con fecha: &fechaeDVN";
    PUT;
    PUT "   Disponible en SAS:  &libreria..ESTADO_PROCESO_ACTUAL";
    PUT;
    PUT;
    put 'Proceso Vers. 14';
    PUT;
    PUT;
    PUT 'Atte.';
    Put 'Equipo Arquitectura de Datos y Automatización BI';
    PUT;
RUN;
FILENAME OUTBOX CLEAR;
/*==================================    EQUIPO DATOS Y PROCESOS     ================================*/
/*==================================================================================================*/

FILENAME output EMAIL
SUBJECT= "PROCESOS NO EJECUTADOS"
FROM= ("&DEST_2")
TO = ("&DEST_2", "&DEST_3")
CT= "text/html" /* Required for HTML output */ ;
ODS LISTING CLOSE;
ODS HTML BODY=output STYLE=sasweb;
TITLE JUSTIFY=left
"EAD_SEGUIMIENTO_PROCESOS, detalle a continuación";
PROC PRINT DATA=WORK.SEGUIM_EJEC_NO_EJEC NOOBS;
RUN;
ODS HTML CLOSE;
ODS LISTING;

