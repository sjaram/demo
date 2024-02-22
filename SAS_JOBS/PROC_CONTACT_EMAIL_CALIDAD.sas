/*==========================================================================================*/
/*=============================	EQUIPO DATOS Y PROCESOS		================================*/
/*=============================	PROC_CONTACT_EMAIL_CALIDAD	================================*/
/* CONTROL DE VERSIONES
/* 2020-09-16 ---- Primera versión
*/
/*==========================================================================================*/
/*

/* EXPORTAR DE SAS A UN FTP O SFTP */ 
       filename server ftp 'BASE_TRABAJO_EMAIL.csv' CD='/' 
       HOST='192.168.82.171' user='17457765K' pass='17457765K' PORT=21;

data _null_;
       infile '/sasdata/users94/user_bi/ONBOARDING/BASE_TRABAJO_EMAIL.csv' ;
       file server;
       input;
       put _infile_;
run;


/*	Fecha ejecución del proceso	*/
data _null_;
exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechae", exec) ;
RUN;
%put &fechae;/*fecha ejecucion proceso */


/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'MARCELO_ANTONELLI';

SELECT EMAIL into :DEST_2 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_3 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'RODRIGO_PEREZ';

SELECT EMAIL into :DEST_4 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'MAXIMILIANO_RODRIGUEZ';

SELECT EMAIL into :DEST_5 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PAOLA_FUENZALIDA';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;
%put &=DEST_5;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_3","&DEST_4")
CC = ("&DEST_2","&DEST_5") 
SUBJECT = ("MAIL_AUTOM: Contactabilidad: Depositado archivo de BI_CORREOS");
FILE OUTBOX;
PUT "Estimados:";
PUT ; 
 put "Se encuentra disponible el archivo requerido, con fecha: &fechae";  
 put ; 
 put ; 
 PUT 'En FTP 192.168.82.171 - Nombre archivo: BASE_TRABAJO_EMAIL.csv';
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
