/*==========================================================================================*/
/*=============================	EQUIPO DATOS Y PROCESOS		 ===============================*/
/*=============================	PROC_ONBOARDING_BASE_NOMBRES ===============================*/
/* CONTROL DE VERSIONES
/* 2020-07-17 ---- Primera versi�n
*/
/*==========================================================================================*/
/*

/*   EXPORTAR SALIDA A FTP DE SAS   */
PROC EXPORT DATA=publicin.BASE_NOMBRES
   OUTFILE='/sasdata/users94/user_bi/ONBOARDING/BASE_NOMBRES.csv'
   DBMS=dlm REPLACE;
   delimiter=';';
   PUTNAMES=YES;
RUN;

/*	Fecha ejecuci�n del proceso	*/
data _null_;
exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechae", exec) ;
RUN;
%put &fechae;/*fecha ejecucion proceso */


/*   ENV�O DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDUARDO_MORALES';

SELECT EMAIL into :DEST_2 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_3 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SEBASTIAN_BARRERA';

SELECT EMAIL into :DEST_4 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'NICOLE_LAGOS';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_2","&DEST_3","&DEST_4")
SUBJECT = ("MAIL_AUTOM: Onboarding: Depositado archivo de BI_BASE_NOMBRES");
FILE OUTBOX;
PUT "Estimados:";
PUT ; 
 put "Se encuentra disponible el archivo requerido, con fecha: &fechae";  
 put ; 
 put ; 
 PUT 'Ruta: /sasdata/users94/user_bi/ONBOARDING/BASE_NOMBRES.csv';
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
