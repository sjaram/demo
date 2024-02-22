/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	BICLICLETEO_AUTOM			================================*/
/* CONTROL DE VERSIONES
/* 2021-06-17 -- V1 -- David V. --  
					-- Automatización inicial

/* INFORMACIÓN:


	(IN) Tablas requeridas o conexiones a BD:
	- /sasdata/users94/user_bi/TRASPASO_DOCS/BAJA_CUPO/AJUSTECUPOPROC &fechaMES;

	(OUT) Tablas de Salida o resultado:
 	- 

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

options validvarname=any;

DATA _null_;
dateMES	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
Call symput("fechaMES", dateMES);
%let libreria=RESULT;

RUN;
%put &libreria;
%put &fechaMES;

%LET ARCH="/sasdata/users94/user_bi/TRASPASO_DOCS/BICICLETEO/Resumen % Bonificación  &fechaMES";
%put==================================================================================================;
%put 01.MACRO DE CARGA DEL ARCHIVO;
%put==================================================================================================;

%macro PROCESO_CARGA_ARCHIVO(ARCH);
%if %sysfunc(fileexist(&ARCH.)) %then %do;

%put==================================================================================================;
%put A.SE CARGARA EL ARCHIVO SOLICITADO;
%put==================================================================================================;

/*Si existe tabla se elimina*/
	proc import datafile="/sasdata/users94/user_bi/TRASPASO_DOCS/BICICLETEO/Resumen % Bonificación  &fechaMES"
		   DBMS = xlsx replace
		   out = &libreria..BICICLETEO_INPUT_2_&fechaMES;  
           getnames = yes; 
		   sheet='Cod Comercios Bloqueados'  
	;quit; 
%end;
%else %do;

%put==================================================================================================;
%put B.NO EXISTE ARCHIVO EN LA RUTA;
%put==================================================================================================;

%end;
%mend PROCESO_CARGA_ARCHIVO;
%PROCESO_CARGA_ARCHIVO(&ARCH);


/*	QUITA REGISTROS NULOSO VACÍOS DE LA TABLA DE SALIDA */
proc sql;
delete * from &libreria..BICICLETEO_INPUT_2_&fechaMES t1
where t1.B="Código";
quit;

/*	QUITA LA COLUMNA J QUE NO TENÍA DATOS	*/
PROC SQL;
   CREATE TABLE &libreria..BICICLETEO_INPUT_&fechaMES AS 
   SELECT t1.B	as CODIGO, 
          t1.C	as GLOSA, 
          t1.D	as 'FECHA BLOQUEO'n, 
          t1.E	as 'Monto Bloqueo: >='n, 
          t1.F as observaciones
      FROM &libreria..BICICLETEO_INPUT_2_&fechaMES t1
;QUIT;

PROC SQL;
DROP TABLE &libreria..BICICLETEO_INPUT_2_&fechaMES
;QUIT;

data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;

%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'XIMENA_ZAMORA';

quit;

%put &=EDP_BI;		%put &=DEST_1;		%put &=DEST_2;		%put &=DEST_3;

data _null_;
FILENAME OUTBOX EMAIL
FROM	= ("&EDP_BI")
TO 		= ("&DEST_3")
CC 		= ("&DEST_1", "&DEST_2")
SUBJECT = ("MAIL_AUTOM: Proceso BICLICLETEO_AUTOM");
FILE OUTBOX;
 PUT "Estimada:";
 put "        Proceso BICLICLETEO_AUTOM, ejecutado automáticamente con fecha: &fechaeDVN";  
 PUT ;
 PUT '          Disponible información en SAS:';
 PUT "             &libreria..BICICLETEO_INPUT_&fechaMES";
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 01'; 
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

/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 
