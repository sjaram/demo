/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	CHEK_TABLAS_DESDE_AWS			 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-12-05 -- v01 -- David V. 	-- Versión Original

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria=PUBLICIN;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/

/**********************************************************************************************/
/******* 			TOMA DATOS DE CONTACTO DESDE BASES DE CHEK EN SAS 					*******/
/**********************************************************************************************/
proc import datafile='/sasdata/users94/user_bi/TRASPASO_DOCS/Contact_AWS_Chek_Users/CHEK_ACCOUNTS.csv'
	dbms=dlm out=&libreria..CHEK_ACCOUNTS replace;
	delimiter=',';
	getnames=yes;
run;

proc import datafile='/sasdata/users94/user_bi/TRASPASO_DOCS/Contact_AWS_Chek_Users/CHEK_BANK_ACCOUNTS.csv'
	dbms=dlm out=&libreria..CHEK_BANK_ACCOUNTS replace;
	delimiter=',';
	getnames=yes;
run;

proc import datafile='/sasdata/users94/user_bi/TRASPASO_DOCS/Contact_AWS_Chek_Users/CHEK_DEPOSITS.csv'
	dbms=dlm out=&libreria..CHEK_DEPOSITS replace;
	delimiter=',';
	getnames=yes;
run;

proc import datafile='/sasdata/users94/user_bi/TRASPASO_DOCS/Contact_AWS_Chek_Users/CHEK_MOVEMENTS.csv'
	dbms=dlm out=&libreria..CHEK_MOVEMENTS replace;
	delimiter=',';
	getnames=yes;
run;

proc import datafile='/sasdata/users94/user_bi/TRASPASO_DOCS/Contact_AWS_Chek_Users/CHEK_PAYMENTS.csv'
	dbms=dlm out=&libreria..CHEK_PAYMENTS replace;
	delimiter=',';
	getnames=yes;
run;

proc import datafile='/sasdata/users94/user_bi/TRASPASO_DOCS/Contact_AWS_Chek_Users/CHEK_USER_DETAILS.csv'
	dbms=dlm out=&libreria..CHEK_USER_DETAILS replace;
	delimiter=',';
	getnames=yes;
run;

proc import datafile='/sasdata/users94/user_bi/TRASPASO_DOCS/Contact_AWS_Chek_Users/CHEK_WITHDRAWS.csv'
	dbms=dlm out=&libreria..CHEK_WITHDRAWS replace;
	delimiter=',';
	getnames=yes;
run;


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
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4")
CC = ("&DEST_1", "&DEST_2", "&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso CHEK_TABLAS_DESDE_AWS");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "		Proceso CHEK_TABLAS_DESDE_AWS, ejecutado con fecha: &fechaeDVN";  
 PUT "		Tablas Disponibles en SAS, librería &libreria.";  
 PUT "			- CHEK_ACCOUNTS";
 PUT "			- CHEK_BANK_ACCOUNTS";
 PUT "			- CHEK_DEPOSITS";
 PUT "			- CHEK_MOVEMENTS";
 PUT "			- CHEK_PAYMENTS";
 PUT "			- CHEK_USER_DETAILS";
 PUT "			- CHEK_WITHDRAWS";
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 01'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/

