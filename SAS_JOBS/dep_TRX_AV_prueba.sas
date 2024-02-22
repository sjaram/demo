%macro principal();
 /*
options errors=max;
options noerrabend nosslcrlcheck;
*/
%LET NOMBRE_PROCESO = 'TRX_AV';
data _null_;
FECHA_PROCESO=cat((put(intnx('month',TODAY(),0,'same'),yymmdd10.)) ,"  " , (put(intnx('month',timepart(TIME()),0,'same'),hhmm8.2)) );
call symput("FECHA_DETALLE",FECHA_PROCESO);
run;

proc sql    ;
create table result.tmp as 
select * from publicin.trx_av_202008
where rut =3482780;
quit;

%if &syserr. > 0 %then %do;
  %goto exit;
	%end;

%put paso al segundo sql;

proc sql   ;
create table tabla2 as 
select xxxxx from  publicin.trx_av_202008
where rut =3482780;
quit;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


%exit:

%put &syserr;
%put &FECHA_DETALLE; 
%let error = &syserr;
%put &error;
proc sql outobs=1 noprint ; 
          select  
                case  
                     when &error=0 then "Ejecuci�n completada con �xito y sin mensajes de advertencia"
                     when &error=1 then "La ejecuci�n fue cancelada por un usuario con una declaraci�n RUN CANCEL."
                     when &error=2 then "La ejecuci�n fue cancelada por un usuario con un comando ATTN o BREAK."
                     when &error=3 then "Un error en un programa ejecutado en modo por lotes o no interactivo caus� que SAS ingresara al modo de verificaci�n de sintaxis."
                     when &error=4 then "Ejecuci�n completada con �xito pero con mensajes de advertencia."
                     when &error=5 then "La ejecuci�n fue cancelada por un usuario con una sentencia ABORT CANCEL."
                     when &error=6 then "La ejecuci�n fue cancelada por un usuario con una declaraci�n ABORTAR CANCELAR ARCHIVO."
                     when &error=108 then "Problema con uno o m�s grupos BY"
                     when &error=112 then "Error con uno o m�s grupos BY"
                     when &error=116 then "Problemas de memoria con uno o m�s grupos BY"
                     when &error=120 then "Problemas de E / S con uno o m�s grupos BY"
                     when &error=1008 then "Problema general de datos"
                     when &error=1012 then "Condici�n de error general"
                     when &error=1016 then "Condici�n de falta de memoria"
                     when &error=1020 then "Problema de E / S"
                     when &error=2000 then "Problema de acci�n sem�ntica"
                     when &error=2001 then "Problema de procesamiento de atributos"
                     when &error=3000 then "Error de sintaxis"
                     when &error=4000 then "No es un procedimiento v�lido."
                     when &error=9000 then "Error en el procedimiento"
                     when &error=20000 then "Se detuvo un paso o se emiti� una declaraci�n ABORT."
                     when &error=20001 then "Se emiti� una declaraci�n ABORT RETURN."
                     when &error=20002 then "Se emiti� una declaraci�n ABORT ABEND."
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
   %put inserta el valor syserr &syserr y error &error;


%mend;

%principal();

/*
data tbl_estado_proceso;
set result.tbl_estado_proceso;
run;
*/
