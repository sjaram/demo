/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	BASE_CLIENTES_TC_PRESENCIAL		 ===============================*/

/* CONTROL DE VERSIONES
/* 2022-10-05 -- v02 -- David V. 	-- Agregando un noprint para el server SAS
/* 2022-09-29 -- v01 -- David V. 	-- Automatización en server SAS
/* 2022-09-29 -- v00 -- José Aburto	-- Versión Original

/* INFORMACIÓN:
Clientes tarjeta de crédito que son captados en presencial (TC y CDP), base debe salir una vez concluido 
la base de capta salida y enviar a destinatarios sugeridos.
Sin FTP ya que es puntual por Cyber

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
OPTIONS VALIDVARNAME=ANY;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/


DATA _null_;
dia  = input(put(intnx('day',today(),-1,'begin' ),Date9.  ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
exec	= compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechax", dia);
RUN;
%put &fechax;
RUN;

PROC SQL;
   CREATE TABLE WORK.CAPTA_SALIDA AS 
   SELECT t1.RUT_CLIENTE AS RUT,
          'R96RNi3mqwLa4o1WYgcR' as ID
      FROM RESULT.CAPTA_SALIDA t1
      WHERE t1.PRODUCTO IN 
           (
           'CAMBIO DE PRODUCTO',
           'CAMBIO_DE_PRODUCTO',
           'MASTERCARD_BLACK',
           'TAM',
           'TAM_CERRADA',
           'TAM_CUOTAS',
           'TR'
           ) AND t1.FECHA = "&fechax"d
		     AND t1.VIA NOT = 'HOMEBAN'
		     AND COD_SUCURSAL NOT = 39
;
QUIT;

;options cmplib=sbarrera.funcs;

proc sql;
create table CAPTA_SALIDA  as 
select t1.*, CATS(put(RUT,best.),LOWCASE(SB_DV(RUT))) AS RUT_DV
from CAPTA_SALIDA as t1
;
quit;


;options cmplib=sbarrera.funcs;


proc sql;
create table CAPTA_SALIDA  as 
select CATS(ID,',',RUT_DV)AS RUT
from CAPTA_SALIDA as t1
;quit;

/* muestra de salida de formato */

PROC SURVEYSELECT noprint DATA=CAPTA_SALIDA
      OUT=MUESTRA
      METHOD=SRS
      N= 20
      SEED=1
      ;
RUN;

/* fecha -1 */

PROC EXPORT DATA = CAPTA_SALIDA
   OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/Temp/base_TC_Cyber_&fechax..csv"
   DBMS=dlm REPLACE;
   delimiter=';';
   PUTNAMES=NO;
RUN;

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==============================			FECHA DEL PROCESO  		 ===============================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==============================		EMAIL CON CASILLA VARIABLE	 ===============================*/
proc sql noprint;                              
SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_PPFF';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_1';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_2';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;
%put &=DEST_6;


data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
/*TO = ("&DEST_4","mgalazh@bancoripley.com")*/
/*CC = ("&DEST_1")*/
TO = ("apinedar@bancoripley.com","mgalazh@bancoripley.com","mamunozo@bancoripley.com")
CC = ("&DEST_1","&DEST_2","&DEST_3","&DEST_4","&DEST_5","&DEST_6")
ATTACH	= "/sasdata/users94/user_bi/TRASPASO_DOCS/Temp/base_TC_Cyber_&fechax..csv"
SUBJECT = ("MAIL_AUTOM: Proceso especial CYBER - BASE_CLIENTES_TC_PRESENCIAL");
FILE OUTBOX;
	PUT "Estimados:";
	PUT "		Proceso especial CYBER - BASE_CLIENTES_TC_PRESENCIAL, ejecutado con fecha: &fechaeDVN";  
	PUT ;
	PUT "	Se adjunta archivo base_TC_Cyber_&fechax..csv";
	PUT ;
	PUT ;
	PUT;
	PUT;
	PUT 'Proceso Vers. 02';
	PUT;
	PUT;
	PUT 'Atte.';
	PUT 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
