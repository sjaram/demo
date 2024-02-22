
%LET NOMBRE_PROCESO = "Clientes con Saldo";

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

DATA _null_;
datex = input(put(intnx('month',today(),-1,'end'),yymmn6.),$10.);    
datex12 = input(put(intnx('month',today(),-13,'end'),yymmn6.),$10.);    

Call symput("datex", datex);
Call symput("datex12", datex12);
RUN;

%put &datex;
%put &datex12;


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
proc sql ;
	  INSERT INTO result.tbl_estado_proceso
	  VALUES ( &error, &DESC, &FEC_DET , &NOMBRE_PROCESO );
quit;



PROC SQL;
CREATE TABLE EMAIL_CLIENTES_CON_SALDO AS 
SELECT * FROM RESULT.CLIENTES_CON_SALDO
WHERE PERIODO IN (&datex, &datex12);
QUIT;



/*Fecha Inicial de la etapa*/
PROC SQL outobs=1 noprint;   
select 
infoerr as temp_error
into :temp_error
from result.tbl_estado_proceso
where nombre_proceso = 'Clientes con Saldo'
order by fecha desc
;QUIT;

FILENAME output EMAIL
SUBJECT= "Ejecución de Proceso CLIENTES CON SALDO (GTN)"
FROM = "OUGARTED@BANCORIPLEY.com"
TO = ("OUGARTED@BANCORIPLEY.com", "dvasquez@bancoripley.com", "pfuenzalida@ripley.com")
CT = "text/html" ;
ODS LISTING CLOSE;
ODS HTML  path="/sasdata/users94/user_bi" file = "CLIENTES_CONSALDO.lst" (URL=none) BODY=output STYLE=sasweb;
TITLE JUSTIFY=left
&temp_error;
PROC PRINT DATA=EMAIL_CLIENTES_CON_SALDO  NOOBS;
RUN;
ODS HTML CLOSE;
ODS LISTING;
