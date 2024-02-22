/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	INHIBIR_NOTCALL_AREA_SEGUROS================================*/

/* CONTROL DE VERSIONES
/* 2021-12-02 -- V1 -- David V. --  
				-- Versión Original
/* INFORMACIÓN:
Se comparte información NOTCALL a equipo Seguros

(IN) Tablas requeridas o conexiones a BD:
- PUBLICIN.NOTCALL

(OUT) Tablas de Salida o resultado:
- SFTP:192.168.80.15 
- RUTA:/ServFiden/Fiden/base_contacto_cliente

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria=PUBLICIN;

proc export data=&libreria..NOTCALL
	OUTFILE="/sasdata/users94/user_bi/CONTACTABILIDAD_PARA_SEGUROS/NOTCALL.csv"
	dbms=dlm REPLACE;
	delimiter=',';
	PUTNAMES=yes;
RUN;

/* EXPORTAR DE SAS A UN FTP O SFTP */
filename server ftp 'NOTCALL.csv' CD='/base_contacto_cliente/' 
	HOST='192.168.80.15' user='FidenFtp' pass='Ftp01Fiden' PORT=21;

data _null_;
	infile "/sasdata/users94/user_bi/CONTACTABILIDAD_PARA_SEGUROS/NOTCALL.csv";
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
	Call symput("fechaeDVN", execDVN);
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
		/*CC   = ("&DEST_1", "&DEST_2")*/
	SUBJECT="MAIL_AUTOM: Inhibir: Archivos depositados de BI_NOTCALL para área SEGUROS";
	FILE OUTBOX;
	PUT 'Estimados:';
	PUT;
	put "        Base NOTCALL desde BI depositada en FTP, con fecha: &fechaeDVN";
	put;
	PUT "        Ruta: /base_contacto_cliente";
	put;
	put;
	PUT;
	put;
	PUT 'Saludos Cordiales.';
	PUT 'Atte.';
	Put 'Equipo Datos y Procesos BI';
	PUT;
	PUT;
	PUT;
RUN;

FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
