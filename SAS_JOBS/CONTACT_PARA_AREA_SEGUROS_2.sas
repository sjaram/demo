/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	CONTACT_PARA_AREA_SEGUROS_2	================================*/
/* CONTROL DE VERSIONES
/* 2021-02-15 -- V1 -- Sergio J. --  
					-- Versión Original
/* INFORMACIÓN:
 Se comparte una base con información de los clientes tomada desde demobasket y base nombres

	(IN) Tablas requeridas o conexiones a BD:
	- PUBLICIN.BASE_TRABAJO_EMAIL
	- PUBLICIN.FONOS_MOVIL_FINAL

	(OUT) Tablas de Salida o resultado:
	- SFTP:192.168.80.15 
	- RUTA:/ServFiden/Fiden/base_contacto_cliente

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());
/*	VARIABLE LIBRERÍA			*/
%let libreria=PUBLICIN;
DATA null_;
ayer	= compress(tranwrd(put(INTNX('month',today() , -1),yymmn6.),"-",""));
Call symput("ayer", ayer);
RUN;
%put &ayer;


/*EXPORTAR BASE DATOS DEMOGRAFICOS*/

proc sql;
create table &libreria..DATOS_DEMOGRAFICOS as 
select
t1.rut,
t1.fecha_nacimiento,
t1.edad,
t1.sexo,
t2.nombres,
t2.paterno,
t2.materno
from &libreria..demo_basket_&ayer as t1 
inner join &libreria..base_nombres as t2 on (t1.rut = t2.Rut);
quit;


proc export data=PUBLICIN.DATOS_DEMOGRAFICOS
  OUTFILE="/sasdata/users94/user_bi/CONTACTABILIDAD_PARA_SEGUROS/DATOS_DEMOGRAFICOS.csv"
 dbms=dlm REPLACE;
 delimiter=',';
 PUTNAMES=yes;
RUN;

/* EXPORTAR DE SAS A UN FTP O SFTP */ 
       filename server ftp 'DATOS_DEMOGRAFICOS.csv' CD='/base_contacto_cliente/' 
       HOST='192.168.80.15' user='FidenFtp' pass='Ftp01Fiden' PORT=21;

data _null_;
     infile "/sasdata/users94/user_bi/CONTACTABILIDAD_PARA_SEGUROS/DATOS_DEMOGRAFICOS.csv";
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
/*CC   = ("&DEST_1", "&DEST_2")*/
SUBJECT="MAIL_AUTOM: Contactabilidad: Archivos depositados de BI_CONTACTABILIDAD para área SEGUROS" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "        Base DATOS_DEMOGRAFICOS de BI_CONTACTABILIDAD depositada en FTP, con fecha: &fechaeDVN";  
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
