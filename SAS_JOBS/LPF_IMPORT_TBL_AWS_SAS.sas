/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	LPF_IMPORT_TBL_AWS_SAS		================================*/
/* CONTROL DE VERSIONES
/* 2021-01-26 -- V2 -- David V. --  
					-- Comentarios + correo de notificación + validación a user_bi
/* 2021-01-11 -- V1 -- Ana M. --  
					-- Versión Original
/* INFORMACIÓN:
	Proceso que toma desde un ruta archivos exportados desde AWS, y los deja disponible en SAS.

	(IN) Tablas requeridas o conexiones a BD:
	- /sasdata/users94/user_bi/TABLAS_LPF_AWS

	(OUT) Tablas de Salida o resultado:
	- LPF.* (Todas las tablas que están en la ruta)

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/

/*DECLARACION DE VARIABLES Y LIBRERIAS */
%LET LIBRERIA =LPF;
%LET PATH_IN =/sasdata/users94/user_bi/TABLAS_LPF_AWS/;
%LET EXT =txt;
%LET EXT2 =.txt;

/*declaracion de macro funciones */
%macro cargaArchivo(file, tablaOut);
     proc import datafile="&file"
     out=&tablaOut
     dbms=dlm    replace;
     delimiter=';';
     getnames=yes;
     %PUT PASO &tablaOut;
     run; 
%mend;


%macro list_files(dir,ext,libreria);

/*esta macro carga el contenido de una carpeta conla funcion dopen y solo */

  %local filrf rc did memcnt name i;
  %let rc=%sysfunc(filename(filrf,&dir));
  %let did=%sysfunc(dopen(&filrf));      
   %if &did eq 0 %then %do; 
    %put Directory &dir cannot be open or does not exist;
    %return;
  %end;
   %do i = 1 %to %sysfunc(dnum(&did));   
   %let name=%qsysfunc(dread(&did,&i));
      %if %qupcase(%qscan(&name,-1,.)) = %upcase(&ext) %then %do;
        %put &dir/&name;
          %put %sysfunc(tranwrd(%quote(&name),%str(.txt),%str()));
         
           %cargaArchivo(file=&dir/&name, tablaOut= &libreria..%sysfunc(tranwrd(%quote(&name),%str(.txt),%str())));
        
      %end;
      %else %if %qscan(&name,2,.) = %then %do;        
        %list_files(&dir/&name,&ext)
      %end;
   %end;
   %let rc=%sysfunc(dclose(&did));
   %let rc=%sysfunc(filename(filrf));     
%mend list_files;


/*importa todos los archivos cvs que estan en la ruta PATH_IN*/
%list_files(&PATH_IN,&EXT,&LIBRERIA);

/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

SELECT EMAIL into :DEST_3
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'MAURICIO_GUZMAN';

SELECT EMAIL into :DEST_4
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'KARINA_MARTINEZ';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1")
CC = ("&DEST_2", "&DEST_3","&DEST_4")
SUBJECT = ("MAIL_AUTOM: Proceso LPF_IMPORT_TBL_AWS_SAS");
FILE OUTBOX;
 PUT "Estimados:";
 put "		Tablas de LPF recibidas desde FTP y depositadas en librería LPF en SAS, con fecha: &fechaeDVN";  
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 02'; 
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
