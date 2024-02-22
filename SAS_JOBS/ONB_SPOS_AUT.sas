/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	ONB_SPOS_AUT_new	================================*/
/* CONTROL DE VERSIONES
/* 2022-11-08 -- v5 -- Sergio J .	--  Cambio de directorio a campaign
/* 2022-10-28 -- v4 -- Sergio J.	-- New delete and export code to aws
/* 2022-10-03 -- v3 -- Sergio J.	--  Actualización Delete AWS
/* 2022-09-13 -- V2 -- Sergio J.    -- Se añade exportación a aws
/* 2021-05-05 -- V1 -- Valentina M. -- 
					-- Versión Original +  EDP.
/* INFORMACIÓN:
	Proceso parte del proyecto ONBOARDING.

	(IN) Tablas requeridas o conexiones a BD:
	- 

	(OUT) Tablas de Salida o resultado:
	- /sasdata/users94/user_bi/unica/INPUT-TR_PAGOS_TC-&USUARIO..csv

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio	= %sysfunc(datetime());

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/

/* Usuario que genera el archivo */
%let USUARIO	=	USER_BI_SPOS_AUT;
%put &USUARIO;

DATA _NULL;
FEC_HASTA=put(intnx('day',today(),-1,'begin'), yymmddn8.);
FEC_DESDE=put(intnx('day',today(),-3,'begin'), yymmddn8.);


call symput("FEC_HASTA",FEC_HASTA);
call symput("FEC_DESDE",FEC_DESDE);
run;

%put &FEC_HASTA;
%put &FEC_DESDE;


LIBNAME MPDT  ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017'; /*REVISAR CONEXION*/
LIBNAME BOPERS ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='AMARINAOC' PASSWORD='amarinaoc2017';

PROC SQL; 

create table SPOS_AUT_SIN_CORR as 
select 
X.COD_FECHA as Fecha, 
floor(X.COD_FECHA/100) as Periodo, 
X.NOMCOM as Nombre_Comercio, 
X.RUBRO as Actividad_Comercio, 
X.RUT_CLIENTE as rut, 
X.VENTA_TARJETA, 
x.codpais, 
CASE 
WHEN X.producto in('07','05','06','TARJETA M') THEN 'TC_Mastercard' 
WHEN X.producto in('Credi2000','01','03','TARJETA R') THEN 'TC_Ripley' 
WHEN X.producto = '08' THEN 'DEBITO' 
END AS Tipo_Tarjeta
from ( 
SELECT 
b.PEMID_GLS_NRO_DCT_IDE_K, 
input(b.PEMID_GLS_NRO_DCT_IDE_K,best.) as RUT_CLIENTE, 
c.codpais, 
c.localidad, 
c.fectrn, 
input(compress(c.fectrn,'-'),best.)  as cod_fecha, 
d.DESACT as RUBRO, 
C.CODCOM, 
input(c.CODCOM,best32.) as Codigo_Comercio, 
c.NOMCOM, 
sum(c.imptrn) as VENTA_TARJETA, 
c.Tipfran, 
a.producto, 
c.tipofac
FROM MPDT.MPDT004 as c, 
MPDT.MPDT007 as a, 
BOPERS.bopers_mae_ide as b, 
MPDT.MPDT039 as d 
where input(a.IDENTCLI,best.) = b.PEMID_NRO_INN_IDE 
and (c.CODACT = d.CODACT) 
and (a.cuenta = c.cuenta) 
and c.CODACT <> 6011 
AND c.tipofac IN (1053,1350,1353,5250,1050,1650,5050,5150,5350,2750,2350,2050,6050,3010,2777,3050) 
and c.codrespu = '000' 
and tipfran <> 4 
and input(compress(fectrn,'-'),best.) between input("&fec_desde",best.) and input("&fec_hasta",best.) 

AND PRODUCTO IN ('07','05','06','TARJETA M','Credi2000','01','03','TARJETA R') 
group by 
b.PEMID_GLS_NRO_DCT_IDE_K, 
c.codpais, 
c.localidad, 
c.fectrn, 
d.DESACT, 
C.CODCOM, 
C.NOMCOM, 
c.Tipfran, 
a.producto,
c.tipofac
) as X 

;QUIT; 

proc sql;
create table SPOS_AUT as 
select
mdy(mod(int(fecha /100),100),mod(fecha ,100),int(fecha /10000))  format=mmddyy10. AS FECHA_TRANSACCION, 
PERIODO AS PERIODO,
NOMBRE_COMERCIO AS NOMBRE_COMERCIO ,
ACTIVIDAD_COMERCIO AS ACTIVIDAD_COMERCIO,
RUT AS ID_USUARIO,
VENTA_TARJETA AS  MONTO_TRANSACCION,
CODPAIS AS CODPAIS,
TIPO_TARJETA AS TIPO_TC_TRANSACCION
from SPOS_AUT_SIN_CORR
 order by rut, FECHA;
 
data SPOS_AUT; /*Nombre de nueva tabla*/

  set SPOS_AUT; /*Nombre de actual tabla*/

  by ID_USUARIO FECHA_TRANSACCION notsorted; /*variables por las que se quiere aplicar el correlativo*/

  NUM_TRANSACCION_SPOS + 1; /*regla del correlativo*/

  if first.ID_USUARIO then NUM_TRANSACCION_SPOS=1; /*regla del correlativo*/

run;

 proc sql ;
 create table prueba_bi_spos_aut as 
 select * from SPOS_AUT
 ;quit; 

/*DELETE AND EXPORT TO AWS*/

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(INPUT_TR_TRANSAC_SPOS,raw,oracloud/campaign,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(INPUT_TR_TRANSAC_SPOS,work.prueba_bi_spos_aut,raw,oracloud/campaign,0);


 /* EXPORT --> Generación archivo CSV - SMS */
/*
PROC EXPORT DATA = prueba_bi_spos_aut
OUTFILE="/sasdata/users94/user_bi/unica/input/INPUT-TR_TRANSAC_SPOS-&USUARIO..csv"
DBMS=dlm REPLACE;
delimiter=',';
PUTNAMES=YES;
RUN;
*/
/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/

/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
