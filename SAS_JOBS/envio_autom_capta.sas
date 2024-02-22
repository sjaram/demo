%macro CAPTACIONES(N);
DATA _null_;
dated2 = input(put(intnx('month',today(),-2-&N.,'begin'),yymmn6. ),$10.) ;
dated1 = input(put(intnx('month',today(),-1-&N.,'begin'),date9. ),$10.) ;
dated0 = input(put(intnx('day',today(),&N.,'same'),date9. ),$10.) ;	
dated_act = input(put(intnx('month',today(),0-&N.,'same'),yymmn6. ),$10.) ;	
dated_ant = input(put(intnx('month',today(),-1-&N.,'same'),yymmn6. ),$10.) ;
ini_mes = input(put(intnx('month',today(),0-&N.,'begin'),date9. ),$10.) ;	
fin_mes = input(put(intnx('month',today(),0-&N.,'end'),date9. ),$10.) ;	

Call symput("fechad0", dated0);
Call symput("fechad1", dated1);
Call symput("fechad2", dated2);
Call symput("dated_act", dated_act);
Call symput("dated_ant", dated_ant);
Call symput("ini_mes", ini_mes);
Call symput("fin_mes", fin_mes);
RUN;
%put &fechad1;
%put &fechad0;
%put &fechad2;
%put &dated_act;
%put &dated_ant;
%put &ini_mes;
%put &fin_mes;

options cmplib=sbarrera.funcs;

proc sql;
create table capta as 
select RUT_CLIENTE,CATS(put(RUT_CLIENTE,commax10.),'-',SB_DV(RUT_CLIENTE)) as rut_dv,producto,fecha,via
from   RESULT.CAPTA_SALIDA
where fecha >= "&ini_mes"d and fecha <= "&fin_mes"d
;quit;

PROC EXPORT DATA =  work.capta
OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/capta.csv"
DBMS=dlm REPLACE;
delimiter=';';
PUTNAMES=YES;
RUN;

%mend CAPTACIONES;

%macro ENVIO_CORREO(N);
DATA _null_;
dated_act = input(put(intnx('month',today(),-&N.,'same'),yymmn6. ),$10.) ;	
Call symput("dated_act", dated_act);
RUN;
%put &dated_act;

data _null_;
FILENAME OUTBOX EMAIL
SUBJECT="MAIL_AUTOM: Captación &dated_act."
FROM = ("nverdejog@bancoripley.com")
TO = ("apinedar@bancoripley.com","sjaram@bancoripley.com")
CC = ("nverdejog@bancoripley.com")
attach =("/sasdata/users94/user_bi/TRASPASO_DOCS/capta.csv" content_type="excel")
Type = 'Text/Plain';
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
put "Datos actualizados periodo &dated_act.";
PUT ;
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
%CAPTACIONES(0);
%ENVIO_CORREO(0);

%CAPTACIONES(1);
%ENVIO_CORREO(1);
%end;

%else %DO;
%CAPTACIONES(0);

%ENVIO_CORREO(0);
%end;

%mend ejecutar;

%ejecutar(A);
