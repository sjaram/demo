/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================    DATA_MKP						 ===============================*/
/* CONTROL DE VERSIONES
/* 2023-04-21 -- v05 -- David V.	-- Se agrega export to aws
/* 2022-08-24 -- v04 -- David V.	-- Se comentan nuevas columnas que no vienen en el archivo de origen.
/* 2022-08-11 -- v03 -- David V.	-- Se comentan nuevas columnas que no vienen en el archivo de origen.
/* 2022-07-28 -- v02 -- David V.	-- Se comenta el campo promo ya que dejó de venir en el archivo de origen.
/* 2022-06-30 -- v01 -- David V.	-- Versión Inicial.

Descripcion:
Proceso que toma información de MKP provista por Eduardo Gallardo y su equipo en una URL, lo llevamos a archivo
en el sFTP SAS, luego a tabla SAS para quitar una columna y lo pasamos al FTP de Control Comercial, con el 
objetivo de que esta información sea incluida en el matinal que ve todo el negocio.
*/

%let libreria=RESULT;
%let tiempo_inicio= %sysfunc(datetime());
options validvarname=any;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

/* 01 - Toma la información propocionada y la deja en la ruta del sFTP SAS */
filename out "/sasdata/users94/user_bi/TRASPASO_DOCS/AWS/DATA_MKP.xlsx";

proc http
url='https://blobaac.blob.core.windows.net/feedsrtl/barilliance/recomendacion/ReporteMKP.xlsx?sv=2020-10-02&st=2022-06-07T19%3A56%3A25Z&se=2050-01-03T18%3A56%3A00Z&sr=b&sp=r&sig=whCqiqt72HIURtC6rKgKLrfRVl9%2BxY9EdUwqiVPDPCs%3D'
method="get" out=out;

/* 02 - Lleva el archivo a tabla sas */
proc import datafile='/sasdata/users94/user_bi/TRASPASO_DOCS/AWS/DATA_MKP.xlsx'
	dbms=xlsx out=&libreria..DATA_MKP replace;
/*	delimiter=';';*/
	getnames=yes;
run;

/* 03 - Quitamos la columna con problemas para Control Comercial */
PROC SQL;
   CREATE TABLE tabla_salida_final_CC AS 
   SELECT t1.cod, 
          t1.order_id, 
          t1.SKU, 
          t1.Fecha_Creacion, 
          t1.Estado, 
          t1.Tipo_de_Pago, 
          t1.Seller, 
/*          t1.Detalle, */
          t1.Categoria, 
          t1.Marca, 
          t1.devoluciones, 
          t1.Rut_Cliente, 
          t1.Venta, 
          t1.Items, 
          t1.Precio, 
          t1.Precio_Envio, 
          t1.Margen, 
          t1.shop_id, 
          t1.Region, 
          t1.sku_2, 
          t1.DEPTO, 
          t1.'Nombre departamento'n, 
          t1.Division, 
          t1.Division3, 
          t1.Mes, 
          t1.'Año'n, 
          t1.Dia2, 
/*          t1.Costo_FleteReal, */
/*          t1.Costo_Flete, */
/*          t1.Q, */
/*          t1.'Sem Cmc'n, */
          t1.TAR, 
          t1.Venta_TAR 
/*          t1.promo, */
/*          t1.NC, */
/*          t1.NCcomision, */
/*          t1.cat2*/
      FROM &libreria..DATA_MKP t1;
QUIT;

/* 04 - Exportamos la tabla SAS a archivo nuevamente en sFTP SAS */
PROC EXPORT DATA=tabla_salida_final_CC
	OUTFILE='/sasdata/users94/user_bi/TRASPASO_DOCS/AWS/DATA_MKP_CC.csv'
	DBMS=dlm REPLACE;
	delimiter=';';
	PUTNAMES=YES;
RUN;

/* 05 - Exportamos el archivo desde sFTP SAS a FTP Control Comercial */
filename server ftp 'DATA_MKP.csv' CD='/' 
	HOST='192.168.82.171' user='AWS_DATALAKE_BANCO_1' pass='AWS_DATALAKE_BANCO' PORT=21;

data _null_;
	infile '/sasdata/users94/user_bi/TRASPASO_DOCS/AWS/DATA_MKP_CC.csv';
	file server;
	input;
	put _infile_;
run;

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*  VARIABLE TIEMPO - FIN   */
data _null_;
    dur = datetime() - &tiempo_inicio;
    put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;
/*==================================    FECHA DEL PROCESO           ================================*/
data _null_;
    execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
    Call symput("fechaeDVN", execDVN);
RUN;
%put &fechaeDVN;
/*==================================    EMAIL CON CASILLA VARIABLE  ================================*/
proc sql noprint;
    SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
quit;
%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
data _null_;
    FILENAME OUTBOX EMAIL
        FROM = ("&EDP_BI")
        TO = ("&DEST_1", "&DEST_2", "&DEST_3")
        SUBJECT = ("MAIL_AUTOM: Proceso DATA_MKP");
    FILE OUTBOX;
    PUT "Estimados:";
    put "   Proceso DATA_MKP, ejecutado con fecha: &fechaeDVN";
    PUT;
    PUT "   Disponible en SAS:  &libreria..DATA_MKP";
	PUT "   Disponible en FTP:  Publico de Control Comercial";
    PUT;
    PUT;
    put 'Proceso Vers. 05';
    PUT;
    PUT;
    PUT 'Atte.';
    Put 'Equipo Arquitectura de Datos y Automatización BI';
    PUT;
RUN;
FILENAME OUTBOX CLEAR;
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(sas_tnda_data_mkp,raw,sasdata,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(sas_tnda_data_mkp,tabla_salida_final_CC,raw,sasdata,0);
