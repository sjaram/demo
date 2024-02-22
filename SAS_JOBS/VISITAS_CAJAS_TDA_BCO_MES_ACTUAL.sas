/* VERSIONAMIENTO */
/* 2023-06-11 -- v02	-- Esteban P.	-- Se cambian credenciales de conexión GEDCRE.
*/

/*===============================================================================================================================================================*/
/*=== MACRO FECHAS ==============================================================================================================================================*/
/*===============================================================================================================================================================*/



%macro principal();
 
%LET NOMBRE_PROCESO = 'VISITAS_BCO_ACTUAL';

DATA _null_;
dated = input(put(intnx('month',today(),0,'begin'),date9. ),$10.);
date0 = input(put(intnx('month',today(),0,'same'),yymmn6. ),$10.);
datef = input(put(intnx('month',today(),1,'begin'),date9. ),$10.);
Call symput("periodo", date0);
Call symput("fechad", dated);
Call symput("fechaf", datef);
RUN;
%put &periodo; /*periodo actual*/
%put &fechad;/*fecha inicio actual ok trx-pagos tda*/
%put &fechaf;/*fecha fin actual ok trx-pagos tda*/


/*===============================================================================================================================================================*/
/*=== VISITAS TDA  TR ==============================================================================================================================================*/
/*===============================================================================================================================================================*/

/************** query entregado por jose aburto Funnel sav (visitas TV)*********************/
LIBNAME credito ODBC  DATASRC=creditoprd  SCHEMA=GEDCRE_CREDITO  USER=CONSULTA_CREDITO  PASSWORD='crdt#0806';

PROC SQL /*outobs=10*/ ;
   CREATE TABLE TIENDA AS 
   SELECT t2.COD_TIPO_TRANSACCION, 
          t2.COD_SUCURSAL, 
          t2.NUM_CAJA, 
          t1.RUT_TITULAR, 
          t2.NUM_DOCUMENTO, 
          t2.AGNO_MES_DIA_TRX, 
          t2.MONTO_TRANSACCION, 
          t1.NUM_MESES_DIFERIDO, 
          t1.MONTO_INTERESES, 
          t1.MONTO_CAPITAL, 
          t1.MONTO_GASTO, 
          t1.MES_PRIMER_VEN, 
          t3.COD_DPTO, 
          t1.PLAZO, 
          t3.COD_LINEA, 
          t3.COD_SUBLINEA, 
          t3.RUT_VENDEDOR, 
          t2.COD_TRANSACCION, 
          t1.TASA_CAR, 
          t1.TASA_FINAL, 
          t1.HORA_TRX_TARJETA, 
          t3.COD_ARTICULO, 
          t2.NUM_DOC_ASOCIADO, 
          t2.RUT_COMPR_PAG, 
          t2.COD_SUPERVISOR
      FROM CREDITO.VENTAS_TARJETAS_ACTUAL AS t1, CREDITO.VENTAS_HEADER_ACTUAL AS t2, CREDITO.VENTAS_DETALLE_ACTUAL AS t3
      WHERE (t1.COD_COMERCIO = t2.COD_COMERCIO AND t1.COD_SUCURSAL = t2.COD_SUCURSAL AND t1.FECHA = t2.FECHA AND
            t1.NUM_CAJA = t2.NUM_CAJA AND t1.NUM_DOCUMENTO = t2.NUM_DOCUMENTO AND t2.COD_COMERCIO = t3.COD_COMERCIO AND
            t2.COD_SUCURSAL = t3.COD_SUCURSAL AND t2.FECHA = t3.FECHA AND t2.NUM_CAJA = t3.NUM_CAJA AND t2.NUM_DOCUMENTO
            = t3.NUM_DOCUMENTO AND t1.COD_COMERCIO = t3.COD_COMERCIO AND t1.COD_SUCURSAL = t3.COD_SUCURSAL AND t1.FECHA
            = t3.FECHA AND t1.NUM_CAJA = t3.NUM_CAJA AND t1.NUM_DOCUMENTO = t3.NUM_DOCUMENTO AND t1.AGNO_MES_DIA_TRX =
            t2.AGNO_MES_DIA_TRX AND t1.AGNO_MES_DIA_TRX = t3.Agno_Mes_Dia_Trx AND t2.AGNO_MES_DIA_TRX =
            t3.Agno_Mes_Dia_Trx) AND (t3.COD_COMERCIO = 1 AND t2.COD_TIPO_TRANSACCION IN (1, 3) AND t2.COD_TRANSACCION
            IN (3, 20, 23, 30) AND t3.Agno_Mes_Dia_Trx  >= "&fechad"d AND t3.Agno_Mes_Dia_Trx <  "&fechaf"d AND t3.NUM_ITEM = 1)
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

/* PARA UNIR CON P_CUOTAS_FINAL*/
PROC SQL;
   CREATE TABLE TIENDA_FINAL AS 
   SELECT t1.COD_SUCURSAL AS SUCURSAL, 
          t1.HORA_TRX_TARJETA AS FECHA, 
          (inPUT((t1.NUM_CAJA),BEST32.))As NUM_CAJA /*t1.NUM_CAJA AS NRO_CAJA*/, 
          t1.RUT_TITULAR AS RUT_CLIENTE, 
          t1.RUT_VENDEDOR AS CAJERO, 
          t1.AGNO_MES_DIA_TRX AS FECHA_TRUNC FORMAT = DDMMYY20. ,
              t1.COD_DPTO,
              'VENTAS' AS DETALLE,
              'TV' AS VIA 
      FROM WORK.TIENDA AS t1
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

/*PAGO_CUOTAS*/

PROC SQL;
   CREATE TABLE PAGO_CUOTAS AS 
   SELECT t1.SUCURSAL, 
          t1.FECHA, 
          t1.NRO_CJA_NUM AS NRO_CAJA, 
          t1.NRO_DOCTO, 
          t1.RUT_CLIENTE, 
          t1.CAJERO, 
          t1.FECHA_TRUNC, 
          t1.MONTO_RECAUDACION, 
          t1.INTERES_MORA_ADIC, 
          t1.GASTOS_MORA_ADIC, 
          t1.CODIGO_TRX, 
          t1.COMERCIO, 
          t1.MONTO_TARJETA, 
          t1.TIPO_TRX
      FROM CREDITO.TRX_HEADER_ABONOS AS t1
WHERE t1.FECHA_TRUNC >= "&fechad"d AND t1.FECHA_TRUNC <  "&fechaf"d 
AND TIPO_TRX = 2 AND COMERCIO = 1 ;
QUIT; 
      
%if &syserr. > 0 %then %do;
 %goto exit;
	%end;
            
PROC SQL;
   CREATE TABLE FECHA_MAX_P_CUOTAS AS 
   SELECT t1.SUCURSAL, 
          /* MAX_of_FECHA */
            (MAX(t1.FECHA)) FORMAT=DATETIME20. AS MAX_of_FECHA, 
          t1.RUT_CLIENTE, 
          t1.CAJERO
      FROM WORK.PAGO_CUOTAS AS t1
      GROUP BY t1.SUCURSAL, t1.RUT_CLIENTE, t1.CAJERO;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SQL;
   CREATE TABLE PAGO_CUOTAS_VISITAS AS 
   SELECT t2.SUCURSAL, 
          t2.FECHA, 
          t2.NRO_CAJA, 
          t2.RUT_CLIENTE, 
          t2.CAJERO, 
          t2.FECHA_TRUNC, 
          t2.COMERCIO
      FROM WORK.FECHA_MAX_P_CUOTAS AS t1, WORK.PAGO_CUOTAS AS t2
      WHERE (t1.SUCURSAL = t2.SUCURSAL AND t1.MAX_of_FECHA = t2.FECHA AND t1.RUT_CLIENTE = t2.RUT_CLIENTE AND t1.CAJERO =
            t2.CAJERO) AND t2.COMERCIO = 1;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

/*BASE SALIDA P_CUOTAS, ESTA SE UNE CON BASE DE TIENDA*/

PROC SQL;
   CREATE TABLE PAGO_CUOTAS_FINAL AS 
   SELECT t1.SUCURSAL, 
          t1.FECHA, 
          t1.NRO_CAJA AS NUM_CAJA, 
          t1.RUT_CLIENTE, 
          t1.CAJERO, 
          DATEPART(t1.FECHA_TRUNC) FORMAT = DDMMYY20. AS FECHA_TRUNC,
              '' FORMAT=$15. LENGTH=15  AS COD_DPTO,
              'PAGOS' AS DETALLE,
              CASE WHEN NRO_CAJA>=200 THEN 'TF' ELSE 'TV' END AS VIA 
      FROM WORK.PAGO_CUOTAS_VISITAS AS t1;
QUIT;


%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SQL;
CREATE TABLE VISITAS_TOTALES AS
SELECT*
FROM TIENDA_FINAL
OUTER UNION CORR
SELECT*
FROM PAGO_CUOTAS_FINAL;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
   CREATE TABLE VISITAS_TOTALES1 AS 
   SELECT A.*,
          B.Descripcion
      FROM WORK.VISITAS_TOTALES AS A
INNER JOIN JABURTOM.SUCURSALES AS B ON (A.SUCURSAL = B.Codigo)
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
CREATE TABLE PUBLICIN.VISITAS_TOTALES_TDA_&periodo AS
SELECT*
FROM VISITAS_TOTALES1
WHERE  SUCURSAL NOT IN (
           39,
           59,
           67,
           40) /*se excluye trx de sucursales sin curse av presencial*/
		   order by FECHA
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;




/*===============================================================================================================================================================*/
/*=== VISITAS TDA TRX OMP ==============================================================================================================================================*/
/*===============================================================================================================================================================*/


%LET MZ_CONNECT_ZEUS=CONNECT TO ODBC AS ZEUS(DATASRC="CREDITOPRD" USER="CONSULTA_CREDITO" PASSWORD="CONSULTA_CREDITO");
PROC SQL /*outobs=10*/;
CREATE TABLE TRX_OMP AS
   SELECT t1.COD_TIPO_TRANSACCION, 
          t1.COD_SUCURSAL, 
          t1.NUM_CAJA,
          t1.NUM_DOCUMENTO, 
          t2.TASA_CAR,
          t2.NUM_ITEM AS AUXILIAR_TIPO_TRX, 
          t1.AGNO_MES_DIA_TRX, 
          t1.MONTO_TRANSACCION AS MTO_NETO, 
          t2.COD_DPTO, 
          t2.COD_LINEA, 
          t2.COD_SUBLINEA, 
          t2.RUT_VENDEDOR, 
          t1.COD_TRANSACCION, 
          t1.RUT_COMPR_PAG, 
          t1.NUM_DOC_ASOCIADO, 
          t2.FECHA, 
          t2.COD_ARTICULO, 
          t1.RUT_CAJERO, 
          t1.COD_SUC_ASOCIADA/*,
		  input(compress(put(t2.Agno_Mes_Dia_Trx,yymmddn8.),'-'),best.) as fc*/
      FROM CREDITO.VENTAS_HEADER_ACTUAL AS t1, CREDITO.VENTAS_DETALLE_ACTUAL AS t2
WHERE t1.COD_COMERCIO = t2.COD_COMERCIO
AND t1.COD_SUCURSAL = t2.COD_SUCURSAL
AND t1.FECHA = t2.FECHA
AND t1.NUM_CAJA = t2.NUM_CAJA
AND t1.NUM_DOCUMENTO = t2.NUM_DOCUMENTO
AND t1.AGNO_MES_DIA_TRX = t2.Agno_Mes_Dia_Trx
AND t2.COD_COMERCIO = 1 
AND t1.COD_TIPO_TRANSACCION IN (1, 3) 
AND t1.COD_TRANSACCION NOT IN (3, 20, 23, 30, 300, 304, 308, 401, 402) 
AND t2.Agno_Mes_Dia_Trx >= "&fechad"d AND t2.Agno_Mes_Dia_Trx <  "&fechaf"d 
AND t2.NUM_ITEM = 1 
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

/*362.343*/
PROC SQL;
   CREATE TABLE TRX_OMP_2 AS 
   SELECT t1.COD_SUCURSAL AS SUCURSAL,
          t1.NUM_CAJA,
CASE WHEN INPUT(t1.NUM_CAJA,BEST12.) >=200 THEN 'TF' ELSE 'TV' END AS VIA, 
          t1.RUT_COMPR_PAG AS RUT_CLIENTE, 
          t1.RUT_CAJERO AS CAJERO, 
          t1.MTO_NETO, 
          t1.AUXILIAR_TIPO_TRX,
            t1.AGNO_MES_DIA_TRX  FORMAT=DDMMYY20. AS FECHA_TRUNC
      FROM WORK.TRX_OMP AS t1
      WHERE t1.COD_SUCURSAL NOT = 39
AND t1.RUT_COMPR_PAG > 0 
AND t1.MTO_NETO >= 2000 
AND t1.AUXILIAR_TIPO_TRX = 1
;QUIT;

PROC SQL;
   CREATE TABLE publicin.VISITAS_TOTALES_OMP_&periodo AS 
   SELECT t1.SUCURSAL, 
          t1.FECHA_TRUNC AS FECHA, 
          t1.NUM_CAJA, 
          t1.RUT_CLIENTE, 
          t1.CAJERO, 
          t1.FECHA_TRUNC, 
          t1.VIA,
            'OMP' AS DETALLE
      FROM WORK.TRX_OMP_2 t1
	  WHERE SUCURSAL NOT IN (
           39,
           59,
           67,
           40 /* se excluyen sucursales ripley.com y sucursales que no realizan venta*/
           )order by FECHA
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


/*===============================================================================================================================================================*/
/*=== VISITAS CAJAS SUCURSAL BCO ==============================================================================================================================================*/
/*===============================================================================================================================================================*/


/** VISITAS BANCO **/


/*%let STR_BD_DCRM=CONNECT TO ODBC as creditoprd(datasrc="creditoprd" user="gredcre_credito" password="credito");*/


/***SACA TODOS LOS ABONOS QUE EXISTEN***/
/*34204*/

/** VISITAS BANCO **/


/*%let STR_BD_DCRM=CONNECT TO ODBC as creditoprd(datasrc="creditoprd" user="gredcre_credito" password="credito");*/


/***SACA TODOS LOS ABONOS QUE EXISTEN***/
/*34204*/



%let mz_connect_credito=CONNECT TO ODBC as CREDITO(datasrc="creditoprd" user="CONSULTA_CREDITO" password="CONSULTA_CREDITO");
PROC SQL /*OUTOBS=10*/;
CREATE TABLE PAGO_EPU_BANCO_&periodo AS 
SELECT distinct RUT_CLIENTE as RUT,FECHA,input(put(datepart(FECHA),yymmddn8.),best.) as fec_num
FROM  CREDITO.TRX_ABONOS 
WHERE floor(input(put(datepart(FECHA),yymmddn8.),best.)/100) =&periodo
AND SUCURSAL = 63 /*63 SUCUSALES BANCO*/
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


/* pago credito consumo en cajas  banco*/

%let mz_connect_BANCO=CONNECT TO ORACLE as BANCO(USER='RIPLEYC' PASSWORD='ri99pley'
PATH="  (DESCRIPTION = 
    (ADDRESS_LIST = 
      (ADDRESS = 
        (PROTOCOL = TCP)
        (Host = 192.168.10.31)
        (Port = 1521)
      )
    )
    (CONNECT_DATA = 
      (SID = ripleyc)
    )
  )
");





/*57277*/
proc sql;
&mz_connect_BANCO;
create table PAGOS_BANCO as
SELECT *
from  connection to BANCO(
 select substr(cli_identifica, 1, length(cli_identifica) - 1) rut,
       pre_credito nro_operacion,
       fpa_codeje codigo_usuario,
       pkg_data_marketing.obtiene_nombre_usuario(fpa_codeje) nombre_usuario,
       substr(cli_identifica, 1, length(cli_identifica) - 1) rut_cliente,
       cli_nomcorresp nombre_cliente,
       fpa_valor cuota_pagada,
       fpa_fecha fecha_pago,
       pre_fecontab fecha_contable,
       pkg_data_marketing.obtiene_rut_empleado(fpa_codeje) rut_cajero,
       fpa_sucorg codigo_suc_origen,
       pkg_data_marketing.obtiene_nombre_sucursal(fpa_sucorg) sucursal_origen,
       fpa_sucdes codigo_suc_destino,
       pkg_data_marketing.obtiene_nombre_sucursal(fpa_sucdes) sucursal_destino,
       trunc(sysdate) fecha_extraccion 
  from tcaj_forpago,
       tpre_prestamos,
       tcli_persona
  where fpa_cuentades = pre_credito
  and fpa_clides = cli_codigo
   /*filtro para periodo.
   */and TO_NUMBER(TO_CHAR(trunc(fpa_fecha),'YYYYMM')) =&periodo
   /*Filtro para mes en curso */
   /*and fpa_fecha >= trunc(sysdate, 'mm') */
)A /*WHERE t1.VIS_FECHAPE = '20Jun2016:15:20:33'dt*/
;QUIT;


%if &syserr. > 0 %then %do;
 %goto exit;
	%end;



PROC SQL;
   CREATE TABLE WORK.PAGOS_CREDITOS_BANCO_&periodo AS 
   SELECT DISTINCT input(t1.rut_cliente,best.) as rut,
          /*t1.FECHA_PAGO,input(put(FECHA_PAGO,yymmddn8.),best.) as fec_num,*/
		  input(SUBSTR(put(datepart(fecha_pago),yymmddn8.),1,8),best8.) as fec_num
      FROM WORK.PAGOS_BANCO t1
WHERE t1.rut_cajero NOT IN (11111120,/*	USUARIO BTN.SERVIPAG NO PRESENCIAL*/
							11111118,/*	USUARIO BTN.SANTANDER NO PRESENCIAL*/
				            1111112,/*	USUARIO HOMEBANKING NO PRESENCIAL*/)
;QUIT;


%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


/*204961*/
PROC SQL;
CREATE TABLE publicin.VISITAS_CAJAS_BCO_&periodo AS
SELECT RUT,fec_num/*, 'TDA' AS ORIGEN*/ FROM PAGO_EPU_BANCO_&periodo 
UNION SELECT RUT,fec_num/*, 'BCO' AS ORIGEN*/ FROM PAGOS_CREDITOS_BANCO_&periodo
ORDER BY RUT
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


%exit:

%put &syserr;
%put &FECHA_DETALLE; 
%let error = &syserr;
%put &error;

data _null_;
FECHA_PROCESO=cat((put(intnx('month',TODAY(),0,'same'),yymmdd10.)) ,"  " , (put(intnx('month',timepart(TIME()),0,'same'),hhmm8.2)) );
call symput("FECHA_DETALLE",FECHA_PROCESO);
run;


proc sql ;
select infoerr 
into : infoerr 
from result.TBL_DESC_ERRORES
where error=&error;
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


