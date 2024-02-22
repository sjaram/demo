/*	==========================	Nuevo Flujo	========================== */
%let USUARIO = EPIELH;
%put &USUARIO;

DATA _null_;
hoy= compress(tranwrd(put(INTNX('DAY',today() , 0),mmddyy10.),"-",""));
Call symput("fecha", hoy);
RUN;
%put &fecha;

/*	VARIABLE LIBRERÍA			*/
%let libreria=PUBLICIN;
%let libreria2=result;

DATA _null_;
		datemy0 = input(put(intnx('month',today(),0,'BEGIN'),yymmn6. ),$10.);
		datemy1 = input(put(intnx('month',today(),-1,'BEGIN'),yymmn6. ),$10.);
		datemy2 = input(put(intnx('month',today(),-2,'BEGIN'),yymmn6. ),$10.);
		datemy3 = input(put(intnx('month',today(),-3,'BEGIN'),yymmn6. ),$10.);
		datemy4 = input(put(intnx('month',today(),-4,'BEGIN'),yymmn6. ),$10.);
		datemy5 = input(put(intnx('month',today(),-5,'BEGIN'),yymmn6. ),$10.);
		datemy6 = input(put(intnx('month',today(),-6,'BEGIN'),yymmn6. ),$10.);
	    dated0 = input(put(intnx('day',today(),-3,'SAME'),date9. ),$10.) ;
	    datedx = input(put(intnx('day',today(),0,'SAME'),date9. ),$10.) ;
	    datedN = YEAR(today())*10000+MONTH(today())*100+DAY(today());

		Call symput("fechamy0", datemy0);
		Call symput("fechamy1", datemy1);
		Call symput("fechamy2", datemy2);
		Call symput("fechamy3", datemy3);
		Call symput("fechamy4", datemy4);
		Call symput("fechamy5", datemy5);
		Call symput("fechamy6", datemy6);
	    Call symput("fechad0", dated0);
	    Call symput("fechadx", datedx);
	    Call symput("fechadN", datedN);
		RUN;

		%put &fechamy0;
		%put &fechad0;
		%put &fechadx;
		%put &fechadN;

OPTIONS VALIDVARNAME=ANY;

/* INSERT CAMPAÑA --> PUSH */
proc sql NOPRINT;
INSERT INTO &libreria2..UNICA_CARGA_CAMP_PUSH_CE
('CAMPANA-CAMPCODE'n, 'CAMPANA-AREA'n, 'CAMPANA-PRODUCTO'n, 'CAMPANA-CAMPANA'n, 'CAMPANA-FECHA'n, 'CAMPANA-CUSTOMERID'n, 'CAMPANA-CANAL'n, 'CAMPANA-RUT_PUSH'n, 'CAMPANA-ID_USUARIO'n, 'CLIENTE-ID_USUARIO'n)
SELECT DISTINCT compress(cats("&fechadN",'EPU',PUT(VENCIMIENTO,BEST.))), 'INT', 'EPU', 'PAGO INTERNET',  "&FECHA.", RUT, 'PUSH', RUT_DV, RUT, RUT
from &libreria..tmp_push_internet_2 
;quit;

/*	EXPORT --> Generación archivo CSV */
PROC EXPORT DATA = &libreria2..UNICA_CARGA_CAMP_PUSH_CE
OUTFILE="/sasdata/users94/user_bi/unica/INPUT-FIREBASE-PAGO_INTERNET_CE-&USUARIO..csv"
DBMS=dlm REPLACE;
delimiter=',';
PUTNAMES=YES;
RUN; 
