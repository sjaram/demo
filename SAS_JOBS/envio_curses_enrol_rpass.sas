%macro CURSES_ENROLAM(N);
LIBNAME libbehb ODBC  DATASRC="BR-BACKENDHB"  SCHEMA=dbo  USER="ripley-bi"  
PASSWORD="biripley00"; 
/*matriz de variables macro*/

DATA _null_;
dated2 = input(put(intnx('month',today(),-2-&N.,'begin'),yymmn6. ),$10.) ;
dated1 = input(put(intnx('month',today(),-1-&N.,'begin'),date9. ),$10.) ;
dated0 = input(put(intnx('day',today(),&N.,'same'),date9. ),$10.) ;	
dated_act = input(put(intnx('month',today(),0-&N.,'same'),yymmn6. ),$10.) ;	
dated_ant = input(put(intnx('month',today(),-1-&N.,'same'),yymmn6. ),$10.) ;
ini_mes = input(put(intnx('month',today(),0-&N.,'begin'),date9. ),$10.) ;	
Call symput("fechad0", dated0);
Call symput("fechad1", dated1);
Call symput("fechad2", dated2);
Call symput("dated_act", dated_act);
Call symput("dated_ant", dated_ant);
Call symput("ini_mes", ini_mes);
RUN;

%put &fechad1;
%put &fechad0;
%put &fechad2;
%put &dated_act;
%put &dated_ant;
%put &ini_mes;

PROC SQL;
CREATE TABLE avance AS 
select  *
FROM libbehb.AVSAVVOUCHERVIEW t1
WHERE datepart(FECHACURSE)>="&ini_mes"D and producto = 'AV'
;QUIT;

PROC SQL;
CREATE TABLE super_avance AS 
select  *
FROM libbehb.AVSAVVOUCHERVIEW t1
WHERE datepart(FECHACURSE)>="&ini_mes"D and producto = 'SAV'
;QUIT;

PROC SQL;
CREATE TABLE consumo AS 
select  *
FROM libbehb.PersonalLoanView t1
WHERE datepart(FechaCurse)>="&ini_mes"D
;QUIT;

proc sql;
create table rpass as 
select distinct 'Identificador Usuario'n  as rut,
'Fin Enrolamiento'n as fecha_enrolamiento
from publicin.IDNOW_REPORTEENROLAMIENTOS
where 'Descripcion Estado'n = 'OK' AND
      'Sistema Operativo'n IN ('ANDROID','IOS') AND
      'Nombre Paso'n = 'FINALIZAR ENROLAMIENTO' and
	  input(put(input(put('Fin Enrolamiento'n,ddmmyy10.),ddmmyy10.),date9.),date9.) >="&ini_mes"D  
;Quit;

PROC EXPORT DATA =  work.avance
OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/avance.csv"
DBMS=dlm REPLACE;
delimiter=';';
PUTNAMES=YES;
RUN;

PROC EXPORT DATA =  work.super_avance
OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/super_avance.csv"
DBMS=dlm REPLACE;
delimiter=';';
PUTNAMES=YES;
RUN;

PROC EXPORT DATA =  work.consumo
/*OUTFILE="/sasdata/users94/user_bi/unica/INPUT-TR_CAMPANAS-&USUARIO..csv"*/
OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/consumo.csv"
DBMS=dlm REPLACE;
delimiter=';';
PUTNAMES=YES;
RUN;

PROC EXPORT DATA =  work.rpass
/*OUTFILE="/sasdata/users94/user_bi/unica/INPUT-TR_CAMPANAS-&USUARIO..csv"*/
OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/rpass.csv"
DBMS=dlm REPLACE;
delimiter=';';
PUTNAMES=YES;
RUN;

%mend CURSES_ENROLAM;

%macro ENVIO_CORREO(N);
DATA _null_;
dated0 = input(put(intnx('day',today(),-&N.,'same'),date9. ),$10.) ;	
Call symput("fechad0", dated0);
RUN;
%put &fechad0;

data _null_;
FILENAME OUTBOX EMAIL
SUBJECT="MAIL_AUTOM: Actualización Curses PPFF y enrolados RPASS  &fechad0."
FROM = ("nverdejog@bancoripley.com")
TO = ("tpiwonkas@bancoripley.com","vmorah@bancoripley.com")
 CC      = ("nverdejog@bancoripley.com","tpiwonkas@bancoripley.com","vmorah@bancoripley.com","sjaram@bancoripley.com")
attach =("/sasdata/users94/user_bi/TRASPASO_DOCS/avance.csv" content_type="excel")
attach    =( "/sasdata/users94/user_bi/TRASPASO_DOCS/super_avance.csv" content_type="excel") 
attach    =( "/sasdata/users94/user_bi/TRASPASO_DOCS/consumo.csv" content_type="excel") 
attach    =( "/sasdata/users94/user_bi/TRASPASO_DOCS/rpass.csv" content_type="excel") 
	  Type    = 'Text/Plain';
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Datos actualizados al &fechad0.";  
 put ; 
 put ; 
 PUT ;
PUT 'Atte.';
Put 'Nicolás Verdejo';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
%mend ENVIO_CORREO;

%macro ejecutar(A);

DATA _null_;
HOY = day(today());
Call symput("HOY", HOY);
RUN;
%put &HOY;

%if %eval(&HOY.<=2) %then %do;
%CURSES_ENROLAM(0);
%ENVIO_CORREO(0);

%CURSES_ENROLAM(1);

DATA _null_;
dated_act = input(put(intnx('month',today(),-1,'same'),yymmn6. ),$10.) ;	
Call symput("dated_act", dated_act);
RUN;
%put &dated_act;

data _null_;
FILENAME OUTBOX EMAIL
SUBJECT="MAIL_AUTOM: Actualización Curses PPFF y enrolados RPASS  Cierre &dated_act."
FROM = ("nverdejog@bancoripley.com")
TO = ("tpiwonkas@bancoripley.com","vmorah@bancoripley.com")
 CC      = ("nverdejog@bancoripley.com","tpiwonkas@bancoripley.com","vmorah@bancoripley.com")
attach =("/sasdata/users94/user_bi/TRASPASO_DOCS/avance.csv" content_type="excel")
attach =( "/sasdata/users94/user_bi/TRASPASO_DOCS/super_avance.csv" content_type="excel") 
attach =( "/sasdata/users94/user_bi/TRASPASO_DOCS/consumo.csv" content_type="excel") 
attach =( "/sasdata/users94/user_bi/TRASPASO_DOCS/rpass.csv" content_type="excel") 
Type = 'Text/Plain';
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Datos actualizados cierre mensual";  
 put ; 
 put ; 
 PUT ;
PUT 'Atte.';
Put 'Nicolás Verdejo';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
%end;

%else %DO;
%CURSES_ENROLAM(0);
%ENVIO_CORREO(0);
%end;

%mend ejecutar;

%ejecutar(A);
