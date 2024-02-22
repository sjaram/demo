/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS			================================*/
/*==================================    	 D10_AUT_BCO				================================*/
/* CONTROL DE VERSIONES
/* 2021-08-26 -- V3 -- Sergio J. --
					-- Cambio de formato int a best
/* 2021-08-10 -- V2 -- David V.. --  
					-- Ajustes mínimos para planificar en server SAS
/* 2021-08-04 -- V1 -- Sergio J. --  
					-- VERSIÓN INICIAL
/* INFORMACIÓN:
	Disponibiliza la información de los clientes D10 para BANCO en SAS

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

options validvarname=any;

/* Variable fecha último día del mes yymmdd */
DATA _null_;
datehf  = compress(input(put(intnx('month',today(),-1,'end' ),yymmdd10.     ),$20.),"-",c); /*cambiar 0 a -1 para ver cierre mes anterior*/
Call symput("fechahf",datehf);
run;
%put &fechahf; 

/* Variable fecha mes yymmn */
DATA null_;
dateMES	= input(put(intnx('month',today(),-1,'end'),yymmn6.),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
Call symput("fechaMES", dateMES);
RUN;
%put &fechaMES;

/* Nombre tabla de salida Final */
data _null_;
TABLA = COMPRESS('D10_'||&fechaMES.||'_BCO'," ",);
call symput("TABLA",TABLA);
run;


/* Variable ruta */
data _null_;
VAR = COMPRESS('/sasdata/users94/archivos_dat_proc/D10_'||&fechahf.||'_BCO.txt'," ",);
call symput("ruta",VAR);
run;

/* Importación del archivo */

DATA WORK.D10_BCO;
    LENGTH
        F1               $ 78 ;
    FORMAT
        F1               $CHAR78. ;
    INFORMAT
        F1               $CHAR78. ;
    INFILE "&ruta."
		firstobs=2
        LRECL=78
        ENCODING="LATIN1"
        TERMSTR=CRLF
        DLM='7F'x
        MISSOVER
        DSD ;
    INPUT
        F1               : $CHAR78. ;
RUN;

/* Tabla Final */
proc sql;
create table WORK.&tabla as
select 
input(substr(f1,1,9),best.) as RUT,
substr(f1,10,1) as DV,
substr(f1,11,50) as NOMBRE,
input(substr(f1,61,1),best.) as TIPO_DEUDOR,
input(substr(f1,62,2),best.) as TIPO_CREDITO,
INPUT(substr(f1,64,1),best.) AS MOROSIDAD,
input(substr(f1,Length(f1)-13,14), best14.) AS MONTO
from D10_BCO;
quit;


proc sql;
create table result.&tabla as 
select *
from WORK.&tabla
;quit;


/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;


data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1", "&DEST_2","jvidalc@bancoripley.com")
SUBJECT = ("MAIL_AUTOM: Proceso D10_AUT_BCO");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso D10_AUT_BCO, ejecutado con fecha: &fechaeDVN";  
 PUT " 	Archivo tomado desde: &ruta";
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 03'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
