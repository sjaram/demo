/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	TRX_SEG        	================================*/
/* CONTROL DE VERSIONES
/* 2022-11-02 -- V03 -- Esteban P. -- Se agrega nueva sentencia exportación a RAW.
/* 2022-10-12 -- V02 -- Sergio J. -- Se agrega exportación a raw
/* 2021-03-09 -- V01 -- Ximena Z. -- Nueva Versión Automática Equipo Datos y Procesos BI

/* Descripcion del proceso: 

Extrae las transaccciones de Seguros.


/* INPUT: 
GETRONICS.MPDT512
- GETRONICS.MPDT510

/* OUTPUT: 
- PUBLICIN.TRX_SEGUROS_&PERIODO

/*UNIVERSO DE CONTRATOS*/

%let libreria=Publicin;


/*:::::::::::::::::::::::*/



%macro TRX_SEGUROS(Periodo,libreria);


PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table &libreria..TRX_SEGUROS_&Periodo.  as 
select * 
from connection to ORACLE( 
select 
A.CODCONPER  CONTRATO,
SUBSTR(A.CODCONPER,1,4)  CODENT,
SUBSTR(A.CODCONPER,5,4)  CENTALTA,
SUBSTR(A.CODCONPER,9,12) CUENTA,
A.TIPOFAC,
floor(cast(REPLACE(A.FECPROCES, '-') as INT)/100) PERIODO,
a.FECMOV,
A.FECPROCES,
A.IMPREC*1 MONTO_RECAUDADO,
A.PAN,
A.IDREFEXT GLOSA_PROPUESTA_CUOTA,
CASE WHEN A.TIPOFAC=5056 THEN 'SEGUROS TARJETA'
     WHEN A.TIPOFAC=5054 THEN 'SEGUROS OPEN MARKET' END TIPO_SEGURO,
A.CODCONREC,
c.DESCONREC,
cast(e.PEMID_GLS_NRO_DCT_IDE_K as INT)  RUT
FROM GETRONICS.MPDT512  A
LEFT JOIN GETRONICS.MPDT510  C 
ON (A.CODCONREC=C.CODCONREC)
left join getronics.mpdt007 d 
on(SUBSTR(A.CODCONPER,9,12)=d.cuenta) 
and (SUBSTR(A.CODCONPER,5,4)=d.centalta)
and (SUBSTR(A.CODCONPER,1,4)=d.codent)
left join  BOPERS_MAE_IDE e
ON (d.IDENTCLI=e.PEMID_NRO_INN_IDE)
WHERE A.TIPOFAC IN (5056,5054) 
AND cast(REPLACE(A.FECPROCES, '-') as INT) Between 100*&periodo.+ 01 and 
100*&periodo.+ 31

) A
;QUIT;

%mend TRX_SEGUROS;


%macro ejecutar(A);


DATA _null_;
HOY = day(today());
Call symput("HOY", HOY);
RUN;
%put &HOY;

%if %eval(&HOY.<=5) %then %do;

DATA _null_;
periodo_ant = input(put(intnx('month',today(),-1,'end'),yymmn6. ),$10.);
periodo_act = input(put(intnx('month',today(),0,'end'),yymmn6. ),$10.);
Call symput("periodo_ant", periodo_ant);
Call symput("periodo_act", periodo_act);

RUN;

%put &periodo_ant;
%put &periodo_act;

%TRX_SEGUROS(&periodo_ant.,&libreria.);
%TRX_SEGUROS(&periodo_act.,&libreria.);

/*Exportación a AWS*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_ppff_trx_seguros,raw,sasdata,-1);
%DELETE_INCREM_PER_DIARIO(sas_ppff_trx_seguros,raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_ppff_trx_seguros,&libreria..trx_seguros_&periodo_ant.,raw,sasdata,-1);
%INCREM_PER_DIARIO(sas_ppff_trx_seguros,&libreria..trx_seguros_&periodo_act.,raw,sasdata,0);

%end;
%else %DO;

DATA _null_;
periodo_act = input(put(intnx('month',today(),0,'end'),yymmn6. ),$10.);
Call symput("periodo_act", periodo_act);
RUN;

%put &periodo_act;
%TRX_SEGUROS(&periodo_act.,&libreria.);

/*Exportación a AWS*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_ppff_trx_seguros,raw,sasdata,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_ppff_trx_seguros,publicin.trx_seguros_&periodo_act.,raw,sasdata,0);


%end;

%mend ejecutar;

%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

%ejecutar(A);

data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */


/*	Fecha ejecución del proceso	*/
data _null_;
execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechaeDVN", execDVN) ;
RUN;
%put &fechaeDVN;/*fecha ejecucion proceso */

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';

	SELECT EMAIL into :DEST_3 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'NICOLE_LAGOS';

		SELECT EMAIL into :DEST_4
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'XIMENA_ZAMORA';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_2","&DEST_3","&DEST_4")
SUBJECT="MAIL_AUTOM: PROCESO TRX SEGUROS %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso  TRX SEGUROS, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put 'Tabla resultante en: PUBLICIN.TRX_SEGUROS'; 
 put ;
 put 'Vers.03'; 
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


