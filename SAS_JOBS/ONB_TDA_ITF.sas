/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	ONB_TDA_ITF			================================*/
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
	- /sasdata/users94/user_bi/unica/INPUT-TR_TRANSAC_TDA-&USUARIO..csv

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio	= %sysfunc(datetime());

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/

/* Usuario que genera la campaña*/
%let USUARIO	=	USER_BI;

DATA _NULL;
FEC_HASTA=put(intnx('day',today(),-1,'begin'), yymmddn8.);
FEC_DESDE=put(intnx('day',today(),-3,'begin'), yymmddn8.);


call symput("FEC_HASTA",FEC_HASTA);
call symput("FEC_DESDE",FEC_DESDE);
run;

%put &FEC_HASTA;
%put &FEC_DESDE;


LIBNAME MPDT  ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC'  PASSWORD='amarinaoc2017';
LIBNAME R_bopers ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='AMARINAOC'  PASSWORD='amarinaoc2017';

proc sql;
create table sin_cuotas as
select 
a.pan,
a.codent,
a.centalta,
a.cuenta,
input(PEMID_GLS_NRO_DCT_IDE_K,best.) AS RUT,
(input(cat(SIGNO,IMPFAC),best32.)) as capital,
0 as pie,
0 as cuotas,
input(compress(fecfac,"-"),best.) as fecha,
input(A.NUMBOLETA,best.) AS DCTO,
input(A.CODCOM,best.) AS COMERCIO,
input(SUBSTR(A.SUCURSAL,1,4),best.)	AS SUCURSAL,
input(SUBSTR(A.SUCURSAL,5,4),best.) AS CAJA,
0 	AS DIFERIDO,
0  	AS MGFIN,
0   AS TASA,
0   AS TASA_DIF,
floor(input(compress(fecfac,"-"),best.)/100) as periodo

from mpdt.mpdt012 as  a
inner join mpdt.mpdt044 d 
on (a.TIPOFAC = d.TIPOFAC) AND (a.INDNORCOR=d.INDNORCOR)
left join MPDT.MPDT007 b 
on (a.codent=b.codent and a.centalta=b.centalta and a.cuenta=b.cuenta)
left join R_bopers.BOPERS_MAE_IDE c 
on (input(b.IDENTCLI,best.) = c.PEMID_NRO_INN_IDE)
WHERE a.linea="0050"  AND CODCOM="000000000000001" AND INDMOVANU = 0
and a.numopecuo = 0
and input(substr(left(SUCURSAL),1,4),best.) not in (901,910,/*sir*/
990,991)/*prorroga*/
and a.TIPOFAC in (3010,1750,2750, 1450,2050, 1150,1250,3050,2850, 1850)
;quit;

proc sql;
create table con_cuotas as
select 
a.pan,
a.codent,
a.centalta,
a.cuenta,
input(PEMID_GLS_NRO_DCT_IDE_K,best.) AS RUT,
IMPFAC as capital,
A.ENTRADA  	AS PIE,
TOTCUOTAS   AS CUOTAS,
input(compress(fecfac,"-"),best.) as fecha,
input(A.NUMBOLETA,best.) AS DCTO,
input(A.CODCOM,best.)	AS COMERCIO,
input(SUBSTR(A.SUCURSAL,1,4),best.)	AS SUCURSAL,
input(SUBSTR(A.SUCURSAL,5,4),best.) AS CAJA,
D.NUMMESCAR   	AS DIFERIDO,
IMPINTTOTAL   	AS MGFIN,
PORINT     AS TASA,
PORINTCAR  	AS TASA_DIF,
floor(input(compress(fecfac,"-"),best.)/100) as periodo
from mpdt.mpdt205 as  a
inner join mpdt.mpdt206 D
on(a.codent=D.codent and a.centalta=D.centalta and a.cuenta=D.cuenta AND a.CODTIPC = d.CODTIPC AND a.NUMOPECUO =d.NUMOPECUO) 
left join MPDT.MPDT007 b 
on (a.codent=b.codent and a.centalta=b.centalta and a.cuenta=b.cuenta)
left join R_bopers.BOPERS_MAE_IDE c 
on (input(b.IDENTCLI,best.) = c.PEMID_NRO_INN_IDE)
WHERE linea="0050"    AND CODCOM="000000000000001" 
and input(substr(left(SUCURSAL),1,4),best.) not in (901,910,/*sir*/
990,991)/*prorroga*/ 
and a.TIPOFAC not in (2951,1950,1951,1952,1954,1957,1956,130,67)
;quit;

proc sql ;
create table TDA_TR_ITF AS 
select * from sin_cuotas 
union 
select * from con_cuotas 
;quit; 


PROC SQL;
CREATE TABLE TDA_ITF AS
select *,
		  CASE WHEN SUBSTR(PAN,1,6) IN('628156') THEN 'CERRADA'
WHEN SUBSTR(PAN,1,4) IN('6392') THEN 'CUENTA VISTA'
WHEN SUBSTR(PAN,1,6) IN('549070')AND INPUT(LEFT(SUBSTR(PAN,1,7)),BEST.) >=5490702 THEN 'TAM CHIP' 
WHEN SUBSTR(PAN,1,6) IN('549070')AND INPUT(LEFT(SUBSTR(PAN,1,7)),BEST.) <5490702 THEN 'TAM' 
ELSE 'CERRADA' END AS TIPO_TR
from SIN_CUOTAS
union
select *,
		  CASE WHEN SUBSTR(PAN,1,6) IN('628156') THEN 'CERRADA'
WHEN SUBSTR(PAN,1,4) IN('6392') THEN 'CUENTA VISTA'
WHEN SUBSTR(PAN,1,6) IN('549070')AND INPUT(LEFT(SUBSTR(PAN,1,7)),BEST.) >=5490702 THEN 'TAM CHIP' 
WHEN SUBSTR(PAN,1,6) IN('549070')AND INPUT(LEFT(SUBSTR(PAN,1,7)),BEST.) <5490702 THEN 'TAM' 
ELSE 'CERRADA' END AS TIPO_TR
from con_cuotas
;QUIT;

proc sql;
create table BASE_TDA AS
SELECT    
RUT as ID_USUARIO, 
'TIENDA' AS TIPO_TRANSACCION,
capital AS MONTO_TRANSACCION, 
mdy(mod(int(fecha /100),100),mod(fecha ,100),int(fecha /10000))  format=mmddyy10. AS FECHA_TRANSACCION, 
CASE WHEN TIPO_TR IN ('TAM' ,'TAM CHIP') THEN 'TC_Mastercard' 
WHEN TIPO_TR IN ('CERRADA') THEN 'TC_Ripley' ELSE 'REVISAR' END AS TIPO_TC_TRANSACCION
FROM TDA_ITF
WHERE TIPO_TR <>'CUENTA VISTA'
AND fecha between input("&fec_desde",best.) and input("&fec_hasta",best.) 
order by rut,fecha
;QUIT;

/*Aplicar "ROW_NUMBER" de SAS*/

data BASE_TDA; /*Nombre de nueva tabla*/

  set BASE_TDA; /*Nombre de actual tabla*/

  by ID_Usuario Fecha_Transaccion notsorted; /*variables por las que se quiere aplicar el correlativo*/

  NUM_TRANSACCION_TDA + 1; /*regla del correlativo*/

  if first.ID_USUARIO then NUM_TRANSACCION_TDA=1; /*regla del correlativo*/

run;
proc sql;
create table prueba_base_tda_bi as 
select * from BASE_TDA
;quit; 

/*DELETE AND EXPORT TO AWS*/

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(INPUT_TR_TRANSAC_TDA,raw,oracloud/campaign,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(INPUT_TR_TRANSAC_TDA,work.prueba_base_tda_bi,raw,oracloud/campaign,0);


/*
 PROC EXPORT DATA = prueba_base_tda_bi
OUTFILE="/sasdata/users94/user_bi/unica/input/INPUT-TR_TRANSAC_TDA-&USUARIO..csv"
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
