/* CONTROL DE VERSIONES */
/* 2023-06-30 -- V2 -- Esteban P.   -- Se añade export para tabla CANJES_RP_APP
*/


/*creando la variable de AAAA_MM*/
data _null_;
hoy = compress(substr((put(today(),yymmn6.)),1,4)||"_"||substr(put(intnx('month',today(),0,'end' ),yymmn6.),5,2));
	Call symput("hoy", hoy);
run;
%put &hoy; /*modificar a -1 el primer día del mes*/

/*Generar la variable de la ruta del archivo con fecha automática*/
DATA _null_;
 archivo= COMPRESS(CAT("/sasdata/users94/user_bi/unica/output/out_transacciones_&hoy..csv"));
 	Call symput("archivo", archivo);
RUN;
%put &archivo;

options validvarname=any;

/*subir el archivo a SAS*/
data WORK.TRANSACCIONES;
infile "&archivo."
delimiter = ';' MISSOVER DSD lrecl=32767 firstobs=2 encoding='utf-8';
informat RUT $9. ;
informat FECHA anydtdtm40. ;
informat PUNTOS best32. ;
informat SKU best32. ;
informat CATEGORIA $14. ;
informat PRODUCTO best32. ;
informat "CODIGO PROMO"N best32. ;
informat "FOLIO SERVICIO CANJE"N best32. ;
informat "FOLIO PRODUCTO"N $9. ;
informat "NOMBRE PRODUCTO"N $250. ;
informat ORIGEN $25.;
informat "SELECTED TITLE"N $99. ;
informat "FECHA EXPIRACION"n anydtdtm40. ;
format RUT $9. ;
format FECHA datetime. ;
format PUNTOS best12. ;
format SKU best12. ;
format CATEGORIA $14. ;
format PRODUCTO best12. ;
format "CODIGO PROMO"N best12. ;
format "FOLIO SERVICIO CANJE"N best12. ;
format "FOLIO PRODUCTO"N $9. ;
format "NOMBRE PRODUCTO"N $250. ;
format ORIGEN $25.;
format "SELECTED TITLE"N $99. ;
format "FECHA EXPIRACION"N datetime. ;
input
RUT $
FECHA
PUNTOS
SKU
CATEGORIA $
PRODUCTO
"CODIGO PROMO"N
"FOLIO SERVICIO CANJE"N
"FOLIO PRODUCTO"N $
"NOMBRE PRODUCTO"N $
ORIGEN $
"SELECTED TITLE"N
"FECHA EXPIRACION"N
;run;


proc sql noprint outobs=1;
select
min(year(datepart(FECHA))*10000+month(datepart(FECHA))*100+day(datepart(FECHA))) as min_fecha
into
:min_fecha
from transacciones
;QUIT;


%let min_fecha=&min_fecha;

/*borrar info de tabla madre*/

proc sql noprint;
delete *
from result.CANJES_RP_APP
where year(datepart(fecha))*10000+month(datepart(fecha))*100+day(datepart(fecha))>=&min_fecha
;QUIT;

/*insertar en la tabla madre*/

PROC SQL noprint NOERRORSTOP ;
INSERT INTO result.CANJES_RP_APP
SELECT
RUT ,
FECHA format=datetime. as FECHA,
year(datepart(fecha))*10000+month(datepart(fecha))*100+day(datepart(fecha)) as FEC_NUM,
PUNTOS,
SKU,
CATEGORIA,
PRODUCTO,
'CODIGO PROMO'n,
'FOLIO SERVICIO CANJE'n,
'FOLIO PRODUCTO'n,
'NOMBRE PRODUCTO'n,
ORIGEN,
"SELECTED TITLE"N,
"FECHA EXPIRACION"n 
from transacciones
;RUN;

/* EXPORT TO AWS */

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(sas_ppff_canjes_rp_app,raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(sas_ppff_canjes_rp_app,RESULT.CANJES_RP_APP,raw,sasdata,0);

/*borrado de tablas de paso*/

proc sql noprint;
drop table transacciones
;QUIT;

/*Conteo de Canjes*/
PROC SQL;
   CREATE TABLE result.QUERY_FOR_CANJES_RP_APP AS 
   SELECT /* COUNT_of_RUT */
            (COUNT(t1.RUT)) AS COUNT_of_RUT, 
          /* MAX_of_FECHA */
            (MAX(t1.FECHA)) FORMAT=DATETIME. AS MAX_of_FECHA
      FROM RESULT.CANJES_RP_APP t1;
QUIT;

/*Envío de correo automático*/
FILENAME output EMAIL
SUBJECT= "Ejecucion de Proceso Canjes RP APP"
FROM= "equipo_datos_procesos_bi@bancoripley.com"
TO= ("epinoh@bancoripley.com","sjaram@bancoripley.com","bsotov@bancoripley.com","dvasquez@bancoripley.com", "iplazam@bancoripley.com")
CT= "text/html" /* Required for HTML output */ ;
	FILENAME mail EMAIL 
 	SUBJECT="HTML OUTPUT" CONTENT_TYPE="text/html";
	ODS LISTING CLOSE;
	ODS HTML  path="/sasdata/users94/user_bi" file = "CANJES_RP_APP_AUTOM.lst" (URL=none) BODY=output STYLE=sasweb;
	TITLE JUSTIFY=left;
PROC PRINT DATA=result.QUERY_FOR_CANJES_RP_APP NOOBS;
RUN;
ODS HTML CLOSE;
ODS LISTING;
