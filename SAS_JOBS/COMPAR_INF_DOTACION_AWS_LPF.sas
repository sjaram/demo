/*==================================================================================================*/
/*==================================	EQUIPO ARQ.DATOS Y AUTOM.		============================*/
/*==================================	COMPAR_INF_DOTACION_AWS_LPF		============================*/
/* CONTROL DE VERSIONES
/* 2022-10-17 ---- V02 -- Sergio J. -- Se cambia fechax a -2
/* 2022-05-17 ---- V01 -- David V. -- Original
 */

/*==================================================================================================*/
/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*	VARIABLE LIBRERÍA			*/
%let libreria_1  = NLAGOSG;

DATA _null_;
	datex	= input(put(intnx('month',today(),-2,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
	Call symput("fechax", datex);
run;
%put &fechax;


proc sql;
	create table DOTACION as
		select rut from &libreria_1..DOTACION_&fechax
	;
quit;

/*   EXPORTAR SALIDA A SFTP DE SAS   */
PROC EXPORT DATA = DOTACION
	OUTFILE="/sasdata/users94/user_bi/IN_ARCHIVO_DOTACION/input/DOTACION.txt"
	DBMS=dlm REPLACE;
	delimiter=';';
	PUTNAMES=YES;
RUN;


/* VARIABLE TIEMPO - FIN */
data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;

/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN);
RUN;

%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;

data _null_;
	FILENAME OUTBOX EMAIL
		FROM = ("&EDP_BI")
		TO = ("&DEST_1", "&DEST_2")
		SUBJECT = ("MAIL_AUTOM: Proceso COMPAR_INF_DOTACION_AWS_LPF");
	FILE OUTBOX;
	PUT "Estimados:";
	put "		Proceso COMPAR_INF_DOTACION_AWS_LPF, ejecutado con fecha: &fechaeDVN";
	put "		Archivo depositado en: /sasdata/users94/user_bi/IN_ARCHIVO_DOTACION/input/DOTACION.txt";
	PUT;
	PUT;
	put 'Proceso Vers. 02';
	PUT;
	PUT;
	PUT 'Atte.';
	Put 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;

FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO ARQ.DATOS Y AUTOM.	================================*/
