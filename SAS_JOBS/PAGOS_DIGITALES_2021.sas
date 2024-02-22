%let libreria=RESULT;


%macro pagos_digitales(i,libreria);

DATA _null_;
dated1 = input(put(intnx('month',today(),-&i.,'begin'),yymmdd10. ),$10.) ;
dated2 = input(put(intnx('month',today(),-&i.,'end'),yymmdd10. ),$10.) ;
dated0 = input(put(intnx('day',today(),-&i.,'same'),date9. ),$10.) ;	
datemy0 = input(put(intnx('month',today(),-&i.,'BEGIN'),yymmn6. ),$10.);
Call symput("fechamy0", datemy0);	
Call symput("fechad0", dated0);
Call symput("fechad2", dated2);
Call symput("fechad1", dated1);
RUN;
%put &fechad1;
%put &fechad2;
%put &fechad0;
%put &fechad2;
%put &fechamy0;

PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table &libreria..pagos_digitales_&fechamy0.   as 
select 

TIPOFAC, 
CODCOM,
input(codcom,best.) as comercio,
RUT,
CODENT,
CENTALTA,
CUENTA,
fecha,
input(substr(suc,1,4),best.) as SUCURSAL ,
input(substr(suc,5,4),best.) as CAJA,
MONTO,
nomcomred,

case when CODCOM = '000000000009818' then 'KIPHU'
WHEN calculated sucursal =39 THEN 'HB_SERV'
WHEN CODCOM = '000000000007453' and calculated sucursal =51 THEN 'SERVIPAG_internet' 
WHEN CODCOM = '000000000009727' THEN 'SANTANDER' 
WHEN CODCOM = '000000000009774' THEN 'CHILEEXPRESS' 
WHEN CODCOM = '000000000007704' THEN 'HB_APP_OTRO'
WHEN CODCOM = '000000000009819' THEN 'CAJA_VECINA' 
WHEN CODCOM = '000000000009820' THEN 'UNIRED'  
when calculated sucursal <100 AND calculated caja<=200 AND calculated COMERCIO=0  AND calculated sucursal NOT IN (1,39,63,51) THEN 'TIENDA'
WHEN calculated sucursal =63 THEN 'BANCO'
WHEN  nomcomred= 'Servipag' THEN 'SERV_fisico'
WHEN calculated sucursal IN (42,401,403,450) THEN 'OTROS_PRESENCIALES'
WHEN calculated sucursal =51 AND calculated caja<=200 AND calculated COMERCIO=0 THEN 'TIENDA'
WHEN calculated COMERCIO IN (9,7) and calculated SUCURSAL not in (39,51,63)
THEN 'OTROS_PRESENCIALES'
WHEN calculated sucursal =51   AND calculated COMERCIO in (7,9) THEN 'OTROS_PRESENCIALES'
ELSE  'CCSS' END AS TIPO


from connection to ORACLE( 
select 
cast(b.RUT as INT) RUT,
a.CODENT,
a.CENTALTA,
a.CUENTA,
a.TIPOFAC, 
a.CODCOM, 
a.TIPOFAC,
a.SUCURSAL suc,
a.FECFAC FECHA,
a.IMPfac  MONTO,
a.nomcomred

from GETRONICS.MPDT012 a
inner join (select
a.CODENT,
a.CENTALTA,
a.CUENTA,
b.PEMID_GLS_NRO_DCT_IDE_K rut
from GETRONICS.MPDT007 a
INNER JOIN BOPERS_MAE_IDE B 
ON (A.IDENTCLI=B.PEMID_NRO_INN_IDE) ) b
on(a.codent=b.codent) and (a.centalta=b.centalta) and (a.cuenta=b.cuenta)

where FECFAC between %str(%')&fechad1.%str(%') and %str(%')&fechad2.%str(%')
and a.TIPOFAC in (1,41,42,43,52,53,54,68,91,97,99,208,411,415,1495,4000)
and a.linea='0000' ) A
;QUIT;


%mend pagos_digitales;


%macro ejecutar(A);


DATA _null_;
HOY = day(today());
Call symput("HOY", HOY);
RUN;
%put &HOY;

%if %eval(&HOY.<=6) %then %do;

%pagos_digitales(0,&libreria.);
%pagos_digitales(1,&libreria.);
%end;
%else %DO;

%pagos_digitales(0,&libreria.);

%end;

%mend ejecutar;

%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

%ejecutar(A);

DATA _null_;
datemy0 = input(put(intnx('month',today(),0,'BEGIN'),yymmn6. ),$10.);
Call symput("fechamy0", datemy0);	
RUN;

Data pagos_digitales_&fechamy0.;
set RESULT.PAGOS_DIGITALES_&fechamy0.;
keep rut fecha monto;
run;

/* Nombre tabla de salida Final */
data _null_;
TABLA = COMPRESS('pagos_digitales_'||&fechamy0.||'.csv'," ",);
call symput("TABLA",TABLA);
run;


/* Variable ruta */
data _null_;
VAR = COMPRESS('/sasdata/users94/user_bi/TRASPASO_DOCS/PAGOS/pagos_digitales_'||&fechamy0.||'.csv'," ",);
call symput("ruta",VAR);
run;



/*  EXPORTAR SALIDA A FTP DE SAS	*/
PROC EXPORT DATA= pagos_digitales_&fechamy0.
   OUTFILE="&ruta."
   DBMS=dlm REPLACE;
   delimiter=';';
   PUTNAMES=YES;
RUN;


data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */


/*	Fecha ejecución del proceso	*/
data _null;
execDVN = compress(compress(input(put(today(),yymmdd10.),$10.),"-",c)," ",);
Call symput("fechaeDVN", execDVN) ;
RUN;
%put &fechaeDVN;/*fecha ejecucion proceso */

proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

SELECT EMAIL into :DEST_5 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'MICHAEL_VARGAS';

SELECT EMAIL into :DEST_6
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'HECTOR_LUNA';

SELECT EMAIL into :DEST_7
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'CRISTIAN_ECHEVERRIA';

SELECT EMAIL into :DEST_8
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDUARDO_DIAZ';

SELECT EMAIL into :DEST_9
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JOSE_VALDEBENITO';

SELECT EMAIL into :DEST_10
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'RODRIGO_BUGUENO';

SELECT EMAIL into :DEST_11
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';

SELECT EMAIL into :DEST_12
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JOSE_ABURTO';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_5;
%put &=DEST_6;
%put &=DEST_7;
%put &=DEST_8;
%put &=DEST_9;
%put &=DEST_10;
%put &=DEST_11;
%put &=DEST_12;


data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_2")
SUBJECT="MAIL_AUTOM: PROCESO PAGOS DIGITALES %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso SPOS AUT, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put 'Tabla resultante en: RESULT.pagos_digitales_periodo'; 
 put ;
 put 'Vers.1'; 
 put ; 
 put ; 
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;


/*	SEGUNDO MAIL PARA CALL INTERNO	*/
data _null_;
FILENAME OUTBOX EMAIL
FROM 	= ("&EDP_BI")
TO 		= ("&DEST_5","&DEST_6","&DEST_7","&DEST_8","&DEST_9","&DEST_10","&DEST_11","&DEST_12")
CC 		= ("&DEST_1","&DEST_2")
ATTACH	= "&ruta."
SUBJECT = ("MAIL_AUTOM: Proceso PAGOS");
FILE OUTBOX;
 PUT "Estimados:";
 put "        Proceso PAGOS, ejecutado con fecha: &fechaeDVN";   
 PUT ;
 PUT '     Se adjunta el archivo';
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 1'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
