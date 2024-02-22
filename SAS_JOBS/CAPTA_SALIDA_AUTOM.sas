/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	CAPTA_SALIDA_AUTOM				 ===============================*/
/* CONTROL DE VERSIONES
/* 2022--12-26-- V06 -- Sergio J. -- drop view and create view para eliminar bloqueo de tabla
/* 2022--10-11-- V04 -- Sergio J. -- Cambio de librería a sasdyp
/* 2022--09-27-- V03 -- Sergio J. -- Se cambia fuente a capta_salida_original puesto que es la tabla de origen asociada
a la vista capta_salida, se agrega lock para bloquar la tabla mientras se ejecuta el proceso
/* 2022--07-06-- V02 -- David V. -- Ajustes al correo y orden tabla salida
/* 2022--03-15-- V01 -- Sergio.J -- Nueva Versión Automática Equipo Datos y Procesos BI
					 			 -- Se automatiza importación y se agrega condición de ejecución si 
el archivo está actualizado.

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio = %sysfunc(datetime()); /* inicio del proceso de conteo*/

/* para listar los archivos contenidos dentro del sftp*/
filename dir ftp '' list user='118732448' HOST='192.168.82.171' user='118732448' pass='118732448' PORT=21
prompt ;
data TMP;
   infile dir TRUNCOVER;
   input VAR1 $86.;
   put _INFILE_;
run;

/*Tomamos el archivo y buscamos el que necesitamos, en este caso capta salida.*/
PROC SQL;
CREATE TABLE TMP2 AS 
select input(scan(var1,7," ") || upcase(scan(var1,6," ")) || put(year(today()),best4.), date9.) format=date9. as fecha_capta,
var1,
today() format=date9. as fecha_hoy /* para procesar el día anterior, solo agregar el -1*/
from tmp 
where var1 like "%CAPTA_SALIDA.txt";
quit;


proc sql noprint;
select fecha_capta,fecha_hoy
into: fecha_capta1, : fecha_hoy1
from tmp2
;quit;

%put &fecha_capta1;
%put &fecha_hoy1;


%macro enviacorreo();
%if &fecha_capta1. ~= &fecha_hoy1. %then %do;
%put el archivo no está actualizado, &fecha_capta1 <> &fecha_hoy1;

/*=========================================================================================*/
/*========     FECHA PROCESO Y AVISO DE DESCACTUALIZACION POR EMAIL     ===================*/

data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
    SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
    SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_SPOS_1';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_SPOS_2';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
	SELECT EMAIL into :DEST_7 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_1';
	SELECT EMAIL into :DEST_8 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_2';
	SELECT EMAIL into :DEST_9 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_PPFF';
	SELECT EMAIL into :DEST_10 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFATURA_CAMP';
	SELECT EMAIL into :DEST_11 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'GRUPO_BI';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;
%put &=DEST_6;	%put &=DEST_7;	%put &=DEST_8;	%put &=DEST_9;	%put &=DEST_10;	%put &=DEST_11;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_2","&DEST_3")
SUBJECT = ("WARNING, ARCHIVO CAPTA SALIDA DESACTUALIZADO");
FILE OUTBOX;
 PUT "Estimados:";
 PUT " El ARCHIVO CAPTA SALIDA ESTÁ DESACTUALIZADO, &fecha_capta1 ~= &fecha_hoy1";
 put ; 
 put '    La Causa:'; 
 put '    Control Comercial no ha enviado el archivo de hoy'; 
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 06'; 
 PUT ;
 PUT ;
PUT 'Atte.';
PUT 'Equipo Arquitectura de Datos y Automatización BI';
RUN;
FILENAME OUTBOX CLEAR;
 
%end;
%else %do;

/*Creo nuevamente la vista en base a la tabla actualizada*/
proc sql;
drop view result.capta_salida;
quit;

/*Bloqueo la Tabla Original en la que quiero trabajar*/
lock RESULT.cpsld;

filename server ftp 'CAPTA_SALIDA.txt' CD='/'
       HOST='192.168.82.171' user='118732448' pass='118732448' PORT=21;
data _null_;   infile server;
    file '/sasdata/users94/user_bi/TRASPASO_DOCS/CAPTA_SALIDA.txt';
    input;
    put _infile_;
    run;

/*carga del archivo, se realiza de esta manera para tener control en el formato de las variables*/
data WORK.CAPTA_SALIDA;
	infile '/sasdata/users94/user_bi/TRASPASO_DOCS/CAPTA_SALIDA.txt' delimiter=';' MISSOVER DSD lrecl=32767 firstobs=2 ;     /*modificar ftp de origen*/
	informat PERIODO best32.;
	informat RUT_CLIENTE best32.;
	informat COD_PROD best32.;
	informat PRODUCTO $18.;
	informat RUT_VENDEDOR best32.;
	informat RUT_CAPTADOR best32.;
	informat RUT_ASISTENTE best32.;
	informat COD_SUCURSAL best32.;
	informat COD_CANAL best32.;
	informat CANAL $20.;
	informat FECHA yymmdd10.;
	informat ORIGEN $9.;
	informat INTERNET best32.;
	informat LINEA_CREDITO best32.;
	informat ADICIONALES best32.;
	informat CODENT $10.;
	informat CENTALTA $10.;
	informat CUENTA $12.;
	informat CONCRECION best32.;
	informat NRO_TERMINAL best32.;
	informat HORA_OFERTA time20.3;
	informat HORA_INICIO_VENTA time20.3;
	informat HORA_ENTREGA_PRODUCTO time20.3;
	informat VIA $7.;
	informat NRO_SOLICITUD best32.;
	informat ID_OFERTA best32.;
	format PERIODO best12.;
	format RUT_CLIENTE best12.;
	format COD_PROD best12.;
	format PRODUCTO $18.;
	format RUT_VENDEDOR best12.;
	format RUT_CAPTADOR best12.;
	format RUT_ASISTENTE best12.;
	format COD_SUCURSAL best12.;
	format COD_CANAL best12.;
	format CANAL $20.;
	format FECHA yymmdd10.;
	format ORIGEN $9.;
	format INTERNET best12.;
	format LINEA_CREDITO best12.;
	format ADICIONALES best12.;
	format CODENT $10.;
	format CENTALTA $10.;
	format CUENTA $12.;
	format CONCRECION best12.;
	format NRO_TERMINAL best12.;
	format HORA_OFERTA time20.3;
	format HORA_INICIO_VENTA time20.3;
	format HORA_ENTREGA_PRODUCTO time20.3;
	format VIA $7.;
	format NRO_SOLICITUD best12.;
	format ID_OFERTA best12.;
	input                                                                  
		PERIODO                                                    
		RUT_CLIENTE                                                
		COD_PROD                                                   
		PRODUCTO  $                                                
		RUT_VENDEDOR                                               
		RUT_CAPTADOR                                               
		RUT_ASISTENTE                                              
		COD_SUCURSAL                                               
		COD_CANAL                                                  
		CANAL  $                                                   
		FECHA                                                                                                                                                        
		ORIGEN  $                                                  
		INTERNET                                                   
		LINEA_CREDITO                                              
		ADICIONALES                                                
		CODENT                                                     
		CENTALTA                                                   
		CUENTA                                                     
		CONCRECION                                                 
		NRO_TERMINAL                                               
		HORA_OFERTA                                                
		HORA_INICIO_VENTA                                          
		HORA_ENTREGA_PRODUCTO                                      
		VIA  $                                                     
		NRO_SOLICITUD                                              
		ID_OFERTA                                                  
	;
run;

/*eleccion de la minima fecha que posee la tabla del archivo de carga*/ 
PROC SQL noprint outobs=1;   
select 
min(fecha) format=date9. as min_fecha
into 
:min_fecha
from CAPTA_SALIDA
;QUIT;

%let min_fecha=&min_fecha;

/*eliminacion de la info desde la tabla de origen*/
proc sql noprint;
delete *
from result.cpsld
where fecha>="&min_fecha"d
;QUIT;

/*tabla que se agregara*/
PROC SQL;
   CREATE TABLE paso_capta_salida AS 
   SELECT t1.RUT_CLIENTE, 
          t1.COD_PROD,
		   case when UPCASE(t1.PRODUCTO)='TAM_DORMIDO' then 'TAM' 
		 WHEN UPCASE(t1.PRODUCTO)='TR_DORMIDO' then 'TR' 
		 else PRODUCTO end AS PRODUCTO,
		  t1.PRODUCTO AS PRODUCTO_2,
          t1.RUT_VENDEDOR, 
          t1.RUT_CAPTADOR, 
          t1.RUT_ASISTENTE, 
          t1.COD_SUCURSAL, 
          t1.COD_CANAL, 
          t1.CANAL, 
          t1.FECHA format=date9. as FECHA, 
          t1.ORIGEN, 
          t1.INTERNET ,
          t1.LINEA_CREDITO, 
          t1.ADICIONALES, 
          t1.CODENT ,
          t1.CENTALTA ,
          t1.CUENTA, 
          t1.CONCRECION, 
          t1.NRO_TERMINAL, 
          t1.VIA, 
          t1.NRO_SOLICITUD, 
          t1.ID_OFERTA
      FROM WORK.CAPTA_SALIDA t1
order by t1.FECHA desc;
QUIT;

/*insertar en la tabla madre*/
proc sql noprint;
insert into result.cpsld
select 
		  t1.RUT_CLIENTE, 
          t1.COD_PROD, 
          t1.PRODUCTO,
	      t1.RUT_VENDEDOR, 
          t1.RUT_CAPTADOR, 
          t1.RUT_ASISTENTE, 
          t1.COD_SUCURSAL, 
          t1.COD_CANAL, 
          t1.CANAL, 
          t1.FECHA format=date9. as FECHA, 
          t1.ORIGEN, 
          t1.INTERNET, 
          t1.LINEA_CREDITO, 
          t1.ADICIONALES, 
          t1.CODENT, 
          t1.CENTALTA, 
          t1.CUENTA, 
          t1.CONCRECION, 
          t1.NRO_TERMINAL, 
          t1.VIA, 
          t1.NRO_SOLICITUD, 
          t1.ID_OFERTA
from paso_capta_salida t1 
;QUIT;

proc sql;
create view result.capta_salida as
select *
from result.cpsld;
quit;

/*desbloquear tabla*/
lock result.cpsld clear;

/*borrar tablas de paso*/
proc sql noprint;
drop table work.capta_salida
;QUIT;

proc sql noprint;
drop table paso_capta_salida
;QUIT;

DATA _NULL_;
ini = put(intnx('month',today(),0,'Begin'),date9.);
ant = put(intnx('day',today(),-1,'same'),date9.);
Call symput("INI",ini);
Call symput("ant",ant);
run;

%put &INI;
%put &ant;


proc sql;
create table resumen_capta_salida as 
select distinct 
producto,
max(fecha) format=date9. as max_fecha,
count(rut_cliente) as cantidad
from result.cpsld 
where   fecha between "&INI."d and "&ant."d 
group by 
producto
;QUIT;

proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
    SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
    SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_SPOS_1';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_SPOS_2';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
	SELECT EMAIL into :DEST_7 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_1';
	SELECT EMAIL into :DEST_8 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_2';
	SELECT EMAIL into :DEST_9 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_PPFF';
	SELECT EMAIL into :DEST_10 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFATURA_CAMP';
	SELECT EMAIL into :DEST_11 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'GRUPO_BI';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;
%put &=DEST_6;	%put &=DEST_7;	%put &=DEST_8;	%put &=DEST_9;	%put &=DEST_10;	%put &=DEST_11;


FILENAME output EMAIL
SUBJECT= "Proceso CAPTA_SALIDA_AUTOM"
FROM= ("&EDP_BI")
TO = ("&DEST_4","&DEST_5","&DEST_6","&DEST_7","&DEST_8","&DEST_9","&DEST_10")
CC = ("&DEST_1","&DEST_2","&DEST_3","&DEST_11")
CT= "text/html" /* Required for HTML output */ ;
ODS LISTING CLOSE;
ODS HTML BODY=output STYLE=sasweb;
TITLE JUSTIFY=left
"Proceso CAPTA_SALIDA_AUTOM ejecutado, detalle a continuación";
PROC PRINT DATA=WORK.resumen_capta_salida NOOBS;
RUN;
ODS HTML CLOSE;
ODS LISTING;

proc sql noprint;
drop table resumen_capta_salida
;QUIT;

%end;
%mend; 
%enviacorreo();


/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
