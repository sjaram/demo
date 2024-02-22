/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	CONTACT_PARA_AREA_SEGUROS	================================*/
/* CONTROL DE VERSIONES

/* 2021-02-15 -- V2 -- David V. --  
					-- Se elimina la exportación de fonos fijos

/* 2021-01-27 -- V1 -- David V. --  
					-- Versión Original
/* INFORMACIÓN:
	Proceso que comparte contactabilidad para área de SEGUROS

	(IN) Tablas requeridas o conexiones a BD:
	- PUBLICIN.BASE_TRABAJO_EMAIL
	- PUBLICIN.FONOS_MOVIL_FINAL

	(OUT) Tablas de Salida o resultado:
	- SFTP:192.168.80.15 
	- RUTA:/ServFiden/Fiden/base_contacto_cliente

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/

/*   1 - EXPORTAR SALIDA A FTP DE SAS - EMAIL  */
PROC EXPORT DATA	=	publicin.BASE_TRABAJO_EMAIL
   OUTFILE="/sasdata/users94/user_bi/CONTACTABILIDAD_PARA_SEGUROS/BASE_TRABAJO_EMAIL.csv"
   DBMS=dlm REPLACE;
   delimiter=';';
   PUTNAMES=YES;
RUN;

/*   1 - EXPORTAR SALIDA A FTP DE SAS - FONOS MOVIL  */
PROC EXPORT DATA	=	publicin.FONOS_MOVIL_FINAL
   OUTFILE="/sasdata/users94/user_bi/CONTACTABILIDAD_PARA_SEGUROS/FONOS_MOVIL_FINAL.csv"
   DBMS=dlm REPLACE;
   delimiter=';';
   PUTNAMES=YES;
RUN;

/*	2 - EXPORTAR DE SAS A UN FTP O SFTP - EMAIL	*/ 
       filename server ftp 'BASE_TRABAJO_EMAIL.csv' CD='/base_contacto_cliente' 
       HOST='192.168.80.15' user='FidenFtp' pass='Ftp01Fiden' PORT=21;

data _null_;
       infile '/sasdata/users94/user_bi/CONTACTABILIDAD_PARA_SEGUROS/BASE_TRABAJO_EMAIL.csv';
       file server;
       input;
       put _infile_;
run;

/*	2 - EXPORTAR DE SAS A UN FTP O SFTP - FONOS MOVIL	*/ 
       filename server ftp 'FONOS_MOVIL_FINAL.csv' CD='/base_contacto_cliente' 
       HOST='192.168.80.15' user='FidenFtp' pass='Ftp01Fiden' PORT=21;

data _null_;
       infile '/sasdata/users94/user_bi/CONTACTABILIDAD_PARA_SEGUROS/FONOS_MOVIL_FINAL.csv';
       file server;
       input;
       put _infile_;
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
TO 	 = ("&DEST_1","amontoyab@ripley.com","&DEST_2")
SUBJECT="MAIL_AUTOM: Contactabilidad: Depositado archivos de BI_CONTACTABILIDAD para área SEGUROS" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "        Depositado archivos de BI_CONTACTABILIDAD depositada en FTP, con fecha: &fechaeDVN";  
 put ; 
 PUT "        Ruta: /base_contacto_cliente"; 
 put ; 
 put ; 
 PUT ;
 put ; 
PUT 'Saludos Cordiales.';
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
