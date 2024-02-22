
	
DATA _null_;
datei = input(put(intnx('month',today(),-1,'begin'),yymmddn8.),$10.);
datef = input(put(intnx('month',today(),-1,'end'),yymmddn8.),$10.);
date9i = put(intnx('month',today(),-1,'begin'),date9.);
date9f = put(intnx('month',today(),-1,'end'),date9.);
datex = input(put(intnx('month',today(),0,'end'),yymmn6.),$10.);    
datex1 = input(put(intnx('month',today(),-2,'end'),yymmn6.),$10.);      
datex12 = input(put(intnx('month',today(),-12,'end'),yymmn6.),$10.);
exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Archivo = compress(cat('''', '/sasdata/users94/user_bi/Temp/Saldo_Purga/SALDO_RP_', datex,'.txt',''''));
Call symput("fechai",datei);
Call symput("fechaf",datef);
Call symput("fec9i",date9i);
Call symput("fec9f",date9f);
Call symput("PERIODO", datex);
Call symput("fechax1", datex1);
Call symput("fechax12", datex12);
Call symput("fechae",exec);
call symput("Archivo",Archivo);
RUN;

%put &fechai;
%put &fechaf;
%put &fec9i;
%put &fec9f;
%put &PERIODO;
%put &fechax1;
%put &fechax12;
%put &fechae;
%put &Archivo;


LIBNAME PSFC1 ORACLE PATH='PSFC1' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017';

 
PROC SQL;
CREATE TABLE WORK.PuntosDisp AS 
SELECT INPUT(T1.CODCUENT,BEST.) AS RUT,
t1.TIPOPUNT, 
t1.CANTPUNT, 
t1.SALULTEX, 
t1.FECULTAC, 
t1.FECHPROC, 
t1.CHEQDATA
FROM PSFC1.T7542700 t1
WHERE t1.TIPOPUNT = '01';
QUIT;
 
PROC SQL;
CREATE TABLE ENROLADOS AS 
SELECT DISTINCT INPUT(LEFT(CODCUENT),BEST.) AS RUT,FECHALTA,FECHBAJA
FROM PSFC1.T7542600 AS T1
WHERE INPUT(SUBSTR(LEFT(FECHALTA),1,6),BEST.) <= &Periodo AND FECHBAJA='' 
;QUIT;
 
/*EXPORTAR EN .TXT*/
 
PROC SQL;
CREATE TABLE PUBLICIN.SALDO_RP_&Periodo AS 
SELECT t1.RUT,t2.CANTPUNT,t2.FECULTAC
FROM ENROLADOS AS T1 left join PuntosDisp t2
on t1.rut=t2.rut
;QUIT;



proc export data=PUBLICIN.SALDO_RP_&Periodo. 
 outfile="&Archivo."
 dbms=dlm; 
 delimiter=';'; 
 putnames=yes;
 run;


