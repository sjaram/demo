/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	ARCH_CALIDAD_AURIS_FRAUDE	================================*/
/* CONTROL DE VERSIONES
/* 2022--03-22-- V1 -- David V. -- 
					-- importación desde FTP 171 a SAS (result) 

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio = %sysfunc(datetime()); /* inicio del proceso de conteo*/

OPTIONS VALIDVARNAME=ANY;

filename server ftp 'AURIS_Fraude_Montos_Desconocidos.txt' CD='/' 
       HOST='192.168.82.171' user='194227043' pass='194227043' PORT=21;

data _null_;   infile server;  
    file '/sasdata/users94/user_bi/TRASPASO_DOCS/AURIS_Fraude_Montos_Desconocidos.txt';
    input;   
	put _infile_;
	run;

proc import datafile="/sasdata/users94/user_bi/TRASPASO_DOCS/AURIS_Fraude_Montos_Desconocidos.txt"
out=AURIS_Fraude_Montos
dbms = dlm
replace;
delimiter =';';
getnames = yes; 
run;

PROC SQL;
   CREATE TABLE result.AURIS_FRAUDE_MONTOS_DESCON AS 
   SELECT t1.'CANAL DE INGRESO'n, 
          t1.Tipo_Canal, 
          t1.AURIS, 
          t1.'Fecha CreaciÃ³n/traslado'n as 'Fecha Creacion/traslado'n, 
          t1.Estado_Ticket, 
          t1.'RUTSINDV'n AS RUT, 
          t1.NUMINC, 
          t1.Agrupar, 
          t1.'GES - Avance 1'n, 
          t1.impfac
      FROM WORK.AURIS_FRAUDE_MONTOS t1;
QUIT;

/*==================================================================*/
 
filename server ftp 'AURIS_Fraude_Tickets.txt' CD='/' 
       HOST='192.168.82.171' user='194227043' pass='194227043' PORT=21;

data _null_;   infile server;  
    file '/sasdata/users94/user_bi/TRASPASO_DOCS/AURIS_Fraude_Tickets.txt';
    input;   
	put _infile_;
	run;

proc import datafile="/sasdata/users94/user_bi/TRASPASO_DOCS/AURIS_Fraude_Tickets.txt"
out=AURIS_Fraude_Tickets
dbms = dlm
replace;
delimiter =';';
getnames = yes; 
run;

PROC SQL;
   CREATE TABLE result.AURIS_FRAUDE_TICKETS AS 
   SELECT t1.'CANAL DE INGRESO'n, 
          t1.Tipo_Canal, 
          t1.AURIS, 
          t1.periodo, 
          t1.'Fecha CreaciÃ³n/traslado'n as 'Fecha Creacion/traslado'n, 
          t1.Estado_Ticket, 
          t1.RUTsinDV as rut, 
          t1.Agrupar, 
          t1.'GES - Avance 1'n
      FROM WORK.AURIS_FRAUDE_TICKETS t1;
QUIT;

/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'NICOLE_LAGOS';
quit;

%put &=EDP_BI;		%put &=DEST_1;		%put &=DEST_2;	%put &=DEST_3;

data _null_;
FILENAME OUTBOX EMAIL
FROM	= ("&EDP_BI")
TO 		= ("&DEST_3","iplazam@bancoripley.com")
CC 		= ("&DEST_1", "&DEST_2")
SUBJECT = ("MAIL_AUTOM: Proceso ARCH_CALIDAD_AURIS_FRAUDE");
FILE OUTBOX;
 PUT "Estimados:";
 put "        Proceso ARCH_CALIDAD_AURIS_FRAUDE, ejecutado automáticamente con fecha: &fechaeDVN";  
 PUT ;
 PUT '          Disponible información en SAS:';
 PUT '             RESULT.AURIS_FRAUDE_MONTOS_DESCON';
 PUT '             RESULT.AURIS_FRAUDE_TICKETS';
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 01'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
