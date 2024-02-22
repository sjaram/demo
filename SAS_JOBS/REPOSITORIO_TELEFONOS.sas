filename server ftp 'REPOSITORIO_TELEFONOS.txt' CD='/' 
       HOST='192.168.82.171' user='118732448' pass='118732448' PORT=21;

data _null_;   infile server;  
    file '/sasdata/users94/user_bi/TRASPASO_DOCS/REPOSITORIO_TELEFONOS.txt';
    input;   
	put _infile_;
	run;

proc import datafile='/sasdata/users94/user_bi/TRASPASO_DOCS/REPOSITORIO_TELEFONOS.txt'
	dbms=dlm 
	out=REPOSITORIO_TELEFONOS replace;
	delimiter=';';
	getnames=yes;
run;

PROC SQL;
   CREATE TABLE PUBLICIN.REPOSITORIO_TELEFONOS_2 AS 
   SELECT input(substr(t1.RUT,1,length(t1.RUT)-1),best.) as rut,
          t1.TELEFONO, 
          input(put(t1.FECHA , yymmdd10.), yymmdd10.) format= yymmdd10. as  FECHA, 
          t1.NOTA, 
          t1.FUENTE length=10
     FROM REPOSITORIO_TELEFONOS t1;
QUIT;

proc sql;
create table count_id as 
select count(rut) as rut,
count(telefono) as count_telefono
from PUBLICIN.REPOSITORIO_TELEFONOS;
quit;

DATA _null_;
fgenera = compress(input(put(today()-1,yymmdd10.),$10.),"-",c);
Call symput("fechaDIA",fgenera);
RUN;
%put &fechaDIA;

	FILENAME output EMAIL
	FROM= "sjaram@BANCORIPLEY.com"
	TO= ("sjaram@BANCORIPLEY.com","dvasquez@BANCORIPLEY.com")
	SUBJECT= "Ejecución de Proceso REPOSITORIO DE TELEFONOS"
	CT= "text/html" /* Required for HTML output */;
	
	FILENAME mail EMAIL TO=("sjaram@BANCORIPLEY.com")
 	SUBJECT="HTML OUTPUT" CONTENT_TYPE="text/html";
	ODS LISTING CLOSE;
	ODS HTML  path="/sasdata/users94/user_bi" file = "REPOSITORIO_UNICO.lst" (URL=none) BODY=output STYLE=sasweb;
	TITLE JUSTIFY=left;
	TITLE "Estimados, el proceso REPOSITORIO DE TELEFONOS EJECUTADO con fecha &fechaDIA";
ods html text = "Estimados el proceso fue ejecutado correctamente.
La Data se encuentra disponible en la PUBLICIN.REPOSITORIO_TELEFONOS";
%PUT "";
ods html text ="saludos";
ods html text =" Que tengas una buena semana";

	PROC PRINT DATA=count_id  NOOBS;
	RUN;

FILENAME OUTBOX CLEAR;
	ODS HTML CLOSE;
	ODS LISTING;

