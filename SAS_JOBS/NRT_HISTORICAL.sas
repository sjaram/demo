/* --- NRT_HISTORICAL --- */
/* --- El siguiente proceso tiene como objetivo
		crear una tabla histórica a partir de los registros
		que se actualizan diariamente en la tabla "ESTADO_PROCESO_ACTUAL en RESULT. ---  */

/* --- CONTROL DE VERSIONES. --- */
/* --- 28-06-2022 -- V2 -- Esteban P. -- Se actualiza la ruta de referencia de la tabla histórica.*/
/* --- 08-06-2022 -- V1 -- Esteban P. -- */


/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

options validvarname=any;

/* --- Definimos la librería RESULT para almacenar en SAS. --- */
%let libreria=RESULT;

/* --- Se crea una tabla en WORK para trabajar con la data nueva y en limpio. --- */
proc sql;
	CREATE TABLE NRT_HIST AS
		SELECT * 
		FROM &LIBRERIA..ESTADO_PROCESO_ACTUAL;
quit;

/* --- Asignamos una ruta a la variable "myfilerf" que será utilizada por la macro "". --- */
%let myfilerf=/sasdata/users_BI/RESULTADOS/nrt_hist_incremental.sas7bdat;

/* --- Macro que cumple con la función de verificar si la tabla NRT_HIST_INCREMENTAL ha sido creada antes. --- */
/* --- Si existe: Inserta datos del día de hoy y los acumula. ---- */
/* --- Si no existe: Crea la tabla e inserta los datos que existen en la tabla original. --- */
%macro diferenciador_tabla_existe;
%put &myfilerf.;
	%if %sysfunc(fileexist(&myfilerf)) %then
		%DO;
			%PUT EXISTE;
			proc sql;
				INSERT INTO &LIBRERIA..NRT_HIST_INCREMENTAL 
					SELECT *
						FROM NRT_HIST;			quit;

		%END;
	%else
		%DO;
			%put NO EXISTE;
			proc sql;
				CREATE TABLE &LIBRERIA..NRT_HIST_INCREMENTAL as
					SELECT *
						FROM NRT_HIST;			quit;
	%END;
%mend diferenciador_tabla_existe;

/* --- Instanciamos la macro. --- */
%diferenciador_tabla_existe;


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
%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
data _null_;
    FILENAME output EMAIL
        FROM = ("&EDP_BI")
        TO = ("&DEST_1", "&DEST_2", "&DEST_3")
        SUBJECT = ("MAIL_AUTOM: Proceso NRT_HISTORICAL")
CT= "text/html" /* Required for HTML output */ ;
	FILENAME mail EMAIL 
 	SUBJECT="HTML OUTPUT" CONTENT_TYPE="text/html";
	ODS LISTING CLOSE;
	ODS HTML  path="/sasdata/users94/user_bi" file = "NRT_HISTORICAL.lst" (URL=none) BODY=output STYLE=sasweb;
	TITLE JUSTIFY=left;
PROC PRINT DATA=WORK.QUERY_FOR_USER_INFO NOOBS;
RUN;
ODS HTML CLOSE;
ODS LISTING;
