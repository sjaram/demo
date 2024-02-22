/*INSTANCIA MISCAR */


%macro principal();
%LET NOMBRE_PROCESO = 'Caega_VU';

DATA _null_;
ayer	= compress(tranwrd(put(INTNX('month',today() , -2),yymmn6.),"-",""));
Call symput("ayer", ayer);
RUN;
%put &ayer;


data _null_;
	datex = input(put(intnx('month',today(),-1,'same'),yymmn6.),$10.);
    datex1 = input(put(intnx('month',today(),-2,'same'),yymmn6.),$10.);
	datex25 = input(put(intnx('month',today(),-25,'same'),yymmn6.),$10.);
	Call symput("fechax", datex);
	Call symput("fechax1", datex1);
	Call symput("fechax25", datex25);
run;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;
%put &fechax;
%put &fechax1;
%put &fechax25;


PROC SQL noprint;
	INSERT INTO PUBLICIN.VU_historico
	(PERIODO,
	 RUT, 
	 SALDO_INSOLUTO, 
	 Saldos,
	 VU_C, 
	 MARCA_BASE
	 ) 
	   SELECT &ayer as PERIODO,
			  t1.RUT, 
	   		  t1.SALDO_INSOLUTO, 
	          t1.Saldos,
	          t1.VU_C, 
	          t1.MARCA_BASE          
	      FROM publicin.VU t1 
		;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

/* SE CARGA EL AÑO ACTUAL A PUBLICIN.VU */
proc sql;
   connect to ODBC as MISGTN (DATASRC="BR-MISGTN" user="nlagosg" password="{SAS002}7183730115E4691046F2820058130A68");
CREATE TABLE publicin.VU AS
SELECT * FROM connection to MISGTN(  
   SELECT * 
FROM VU_&fechax);
quit;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;
%exit:
%put &FECHA_DETALLE; 
%let error = &syserr;
%mend;
%principal();


%LET NOMBRE_PROCESO = "Carga VU";

data _null_;
FECHA_PROCESO=cat((put(intnx('month',TODAY(),0,'same'),yymmdd10.)) ,"  " , (put(intnx('month',timepart(TIME()),0,'same'),hhmm8.2)) );
call symput("FECHA_DETALLE",FECHA_PROCESO);

run;



%put &FECHA_DETALLE; 
%let error = &syserr;



data _null_;
	call symputx('anomes',sum(year(today())*100,month( intnx('month',today(),-1,'begin')  )*1));
	call symputx('anomes1',sum(year(today())*100,month( intnx('month',today(),-2,'begin')  )*1));
run;

%put &anomes;

proc sql inobs=1 noprint;
 
          select  
                case  
                     when &error=0 then "Ejecución completada con éxito y sin mensajes de advertencia"
                     when &error=1 then "La ejecución fue cancelada por un usuario con una declaración RUN CANCEL."
                     when &error=2 then "La ejecución fue cancelada por un usuario con un comando ATTN o BREAK."
                     when &error=3 then "Un error en un programa ejecutado en modo por lotes o no interactivo causó que SAS ingresara al modo de verificación de sintaxis."
                     when &error=4 then "Ejecución completada con éxito pero con mensajes de advertencia."
                     when &error=5 then "La ejecución fue cancelada por un usuario con una sentencia ABORT CANCEL."
                     when &error=6 then "La ejecución fue cancelada por un usuario con una declaración ABORTAR CANCELAR ARCHIVO."
                     when &error=108 then "Problema con uno o más grupos BY"
                     when &error=112 then "Error con uno o más grupos BY"
                     when &error=116 then "Problemas de memoria con uno o más grupos BY"
                     when &error=120 then "Problemas de E / S con uno o más grupos BY"
                     when &error=1008 then "Problema general de datos"
                     when &error=1012 then "Condición de error general"
                     when &error=1016 then "Condición de falta de memoria"
                     when &error=1020 then "Problema de E / S"
                     when &error=2000 then "Problema de acción semántica"
                     when &error=2001 then "Problema de procesamiento de atributos"
                     when &error=3000 then "Error de sintaxis"
                     when &error=4000 then "No es un procedimiento válido."
                     when &error=9000 then "Error en el procedimiento"
                     when &error=20000 then "Se detuvo un paso o se emitió una declaración ABORT."
                     when &error=20001 then "Se emitió una declaración ABORT RETURN."
                     when &error=20002 then "Se emitió una declaración ABORT ABEND."
                     when &error=25000 then "Error grave del sistema. El sistema no puede inicializarse o continuar."
                end 
          as infoerror   into: infoerr
                from sashelp.air;
quit;

%let FEC_DET = "&FECHA_DETALLE";
%LET DESC = "&infoerr";  
proc sql noprint;
	  INSERT INTO result.tbl_estado_proceso_localSJ
	  VALUES ( &error, &DESC, &FEC_DET , &NOMBRE_PROCESO );
quit;


/*Fecha Inicial de la etapa*/
PROC SQL outobs=1 noprint;   
select 
infoerr as temp_error
into :temp_error
from result.tbl_estado_proceso_localSJ
where nombre_proceso = 'Carga VU'
order by fecha desc
;QUIT;


PROC SQL;
create table valida1 as 
SELECT COUNT(RUT) AS CANTIDAD, 'CLIENTES CON SALDO' as OBS 
  FROM PUBLICIN.VU
WHERe SALDO_INSOLUTO > 0

;
QUIT;


procedure sql;
create table valida2 as 
select COUNT(rut) AS CANTIDAD, 'CLIENTES VU'  as OBS
from publicin.vu
where vu_c = 'VU' 
;
quit;


proc sql;
create table valida_vu as 
select * from valida1 
outer union corr
select * from valida2;
quit;

DATA null_;
dateMES	= input(put(intnx('month',today(),-1,'end'),yymmn6.),$6.); /*cambiar 0 a -1 para ver cierre mes anterior*/
Call symput("ayer", dateMES);
RUN;
%put &ayer;


data VURUC;
SET publicin.vu;
PERIODO=&ayer;
keep rut periodo VU_C;
RUN;

proc sql;
create table vuperiodo as
select PERIODO, RUT
from VURUC
where vu_c = 'VU';
quit;

proc export data=vuperiodo
 OUTFILE="/sasdata/users94/user_bi/vu_&ayer..csv"
 dbms=csv REPLACE;
 PUTNAMES=yes;
RUN;

/* EXPORTAR DE SAS A UN FTP O SFTP */ 
       filename server ftp "VU_&AYER..CSV" CD='/VU/' 
       HOST='192.168.10.155' user='ruc' pass='Bripley.2018' PORT=5560;

data _null_;
       infile"/sasdata/users94/user_bi/vu_&ayer..csv";
       file server;
       input;
       put _infile_;
run;



FILENAME output EMAIL
SUBJECT= "Ejecucion de Proceso Carga VU"
FROM= "SJARAM@BANCORIPLEY.com"
TO= ("dvasquez@bancoripley.com","SJARAM@BANCORIPLEY.com")
/*cc=("icomercial@ripley.com")*/
CT= "text/html" /* Required for HTML output */ ;
ODS LISTING CLOSE;
ODS HTML BODY=output STYLE=sasweb;
TITLE JUSTIFY=left
&temp_error;
PROC print DATA=WORK.valida_vu noobs;
RUN;
ODS HTML CLOSE;
ODS LISTING;

