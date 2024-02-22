/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	TRANSACCIONES_MCD.sas	================================*/
/* CONTROL DE VERSIONES
/* 2022-12-20 -- v05 -- David V.		-- Se actualiza variable fechax por periodo
/* 2022-12-16 -- v04 -- David V.		-- Ajustes menores en nombre tabla salida to AWS.
/* 2022-12-16 -- v03 -- Esteban P.		-- Se agrega nueva sentencia para exportar a 6 tablas, 3 spos y 3 tnda.
/* 2022-07-22 -- v02 -- Sergio J.  		-- Modificación de conexión a Segcom.
/* 2020-12-29 -- v01 -- Alejandra M. 	-- Nueva Versión Automática Equipo Datos y Procesos BI


Descripción:
En este proyecto se traen las transacciones realizadas con la MCD tanto en tienda como SPOS.	

`MODELAMIENTO`

	(IN) Tablas requeridas o conexiones a BD:
- MPDT.MPDT013 CONTRATO de Tarjeta
- BOPERS.BOPERS_MAE_IDE
- MPDT.MPDT007  CONTRATO
- MPDT.MPDT009 Tarjeta 
- MPDT.MPDT004 Transacciones

	(OUT) Tablas de Salida o resultado:
- PUBLICIN.SPOS_MCD_AAAAMM
- PUBLICIN.TDA_MCD_AAAAMM
- CORREO AUTOMATICO

*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/




%let LIB=PUBLICIN;



%macro spos_aut(periodo,libreria);

/****************************************************************************************************************/
/****************************************************************************************************************/
/****************************************************************************************************************/
/****************************************************************************************************************/
/****************************************************************************************************************/
/****************************************************************************************************************/



%put==================================================================================================;
%put [01] DETALLE MPDT004  TD;
%put==================================================================================================;

PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table cuentas  as 
select * 
from connection to ORACLE( 
SELECT 
cast(a2.PEMID_GLS_NRO_DCT_IDE_K as INT)  RUT,
a.CODENT, 
a.CENTALTA, 
a.CUENTA,
a1.producto, 
a.codpais, 
a.localidad, 
a.fectrn, 
a.hortrn, 
cast(REPLACE(a.fectrn, '-') as INT) cod_fecha, 
a.CODACT,  
a.CODCOM, 
a.CODCOM  Codigo_Comercio_ant, 
a.NOMCOM, 
sum(a.imptrn)  VENTA_TARJETA, 
a.Tipfran, 
a.totcuotas, 
a.porint, 
a.PAN, 
SUBSTR(a.PAN,13,4) PAN2,
a.tipofac, 
a.IMPCCA, 
a.CLAMONCCA, 
a.IMPDIV,
substr(a.MODENTDAT,1,2)  Ind_Online,
a.NUMAUT,
a3.DESACT  RUBRO
from GETRONICS.MPDT004  a 
INNER JOIN GETRONICS.MPDT007 a1 /*CONTRATO*/
ON (A.CODENT=a1.CODENT) AND (A.CENTALTA=a1.CENTALTA) AND (A.CUENTA=a1.CUENTA) 
INNER JOIN BOPERS_MAE_IDE a2 ON 
A1.IDENTCLI=a2.PEMID_NRO_INN_IDE
inner join GETRONICS.MPDT039 a3
on(a.CODACT = a3.CODACT)
where a.codrespu = '000' 
and a.tipfran <> 1004 
and cast(REPLACE(a.fectrn, '-') as INT)>=100*&periodo.+01 
and cast(REPLACE(a.fectrn, '-') as INT)<=100*&periodo.+31 
and  SUBSTR(a.PAN,1,6)='525384'  
group by 
a.CODENT, 
a.CENTALTA, 
a.cuenta,  
a.codpais, 
a.localidad, 
a.fectrn, 
a.hortrn,
a.CODACT,  
a.CODCOM, 
a.NOMCOM, 
a.Tipfran, 
a.totcuotas, 
a.porint, 
a.PAN,
a.tipofac,
a.IMPCCA,
a.CLAMONCCA,
a.IMPDIV,
substr(a.MODENTDAT,1,2),
a.NUMAUT,
cast(a2.PEMID_GLS_NRO_DCT_IDE_K as INT),
a3.DESACT,
SUBSTR(a.PAN,13,4),
a1.producto
) A
;QUIT;

%put==================================================================================================;
%put [02] DATA INCOMING;
%put==================================================================================================;

proc sql noprint;
	SELECT USUARIO into :USER 
		FROM sasdyp.user_pass WHERE SCHEMA = 'SEGCOM';
	SELECT PASSWORD into :PASSWORD 
		FROM sasdyp.user_pass WHERE SCHEMA = 'SEGCOM';
quit;

%put &USER;
%put &PASSWORD;
%let path_ora       = '(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.84.167)(PORT = 1521))(CONNECT_DATA=(SERVER = DEDICATED)(SERVICE_NAME = segcom)))';
%let conexion_ora   = ORACLE PATH=&path_ora. USER=&USER. PASSWORD=&PASSWORD.;
%put &conexion_ora.;


LIBNAME DBLIBORA     &conexion_ora. insertbuff=10000 readbuff=10000;  

PROC SQL  NOERRORSTOP;

CONNECT TO ORACLE (USER=&USER. PASSWORD=&PASSWORD. path =&path_ora. );

create table data_IMP_DATA as

select * from connection to ORACLE

(

select  
fecha,
END_POINT,
DE42_CARD_ACCEPTOR_ID_CODE,
DE38_CODIGO_DE_APROBACION ,
de12_FECHA_HORA_TRANSACCION,
DE2_NUMERO_DE_TARJETA

from IPM_DATA
where 20*1000000 +floor(de12_FECHA_HORA_TRANSACCION/1000000) between 100*&periodo.+01
and 100*&periodo.+31
             
);
disconnect from ORACLE;

QUIT;

proc sql;
create table data_IMP_DATA2 as 
select 
*,
substr(DE2_NUMERO_DE_TARJETA,length(DE2_NUMERO_DE_TARJETA)-3,4) as auto,
input('20'||substr(compress(put(de12_FECHA_HORA_TRANSACCION,32.)),1,6),best.) as fec_num,
substr(compress(put(de12_FECHA_HORA_TRANSACCION,32.)),7,2)||':'||substr(compress(put(de12_FECHA_HORA_TRANSACCION,32.)),9,2)||':'||substr(compress(put(de12_FECHA_HORA_TRANSACCION,32.)),11,2) as hora
from data_IMP_DATA
;QUIT;

proc sql;
create table cuentas as 
select monotonic() as ind,
* from cuentas
;QUIT;

proc sql; 
create table cruce as 
select 
a.*,
input(b.DE42_CARD_ACCEPTOR_ID_CODE,best32.) as codigo_comercio 

from   cuentas as a 
left join data_IMP_DATA2 as b
on(a.cod_fecha=b.fec_num) 
and (a.NUMAUT=b.DE38_CODIGO_DE_APROBACION) and (a.PAN2=b.auto)
;QUIT;



%put==================================================================================================;
%put [03] TIPO DE Actividad;
%put==================================================================================================;

proc sql;
create table BASE_TOTAL_FIN as 
select 
*,CASE WHEN UPPER(NOMCOM) LIKE 'RIPLEY %' THEN 'TIENDA' ELSE 'SPOS' END AS LUGAR,
CASE when producto='13' then 'CTACTE'
WHEN producto='08' THEN 'MCD'
WHEN producto='12' THEN 'MC CHECK'
END AS Tipo_Tarjeta

from cruce

;QUIT;


%put==================================================================================================;
%put [04] TABLA SPOS resumida;
%put==================================================================================================;

proc sql;
create table &libreria..spos_MCD_&periodo.  as 
select 
X.COD_FECHA as Fecha, 
X.hortrn AS Hora,
floor(X.COD_FECHA/100) as Periodo, 
input(X.codigo_comercio_ant,best32.) as codigo_comercio_ant,
x.codigo_comercio, 
X.NOMCOM as Nombre_Comercio, 
X.RUBRO as Actividad_Comercio, 
X.RUT, 
X.VENTA_TARJETA, 
x.codpais, 
X.TOTCUOTAS,
X.PAN,
X.CODACT,
X.PORINT,
X.CODENT,
X.CENTALTA,
X.CUENTA,
X.Tipo_Tarjeta,
(LEFT(SUBSTR(X.PAN,13,4))) as PAN2, 
CAT(X.CODENT,X.CENTALTA,X.CUENTA,calculated PAN2) as CONTRATO_PAN,
case when x.Ind_Online in ('81','10') then 1 else 0 end as si_digital,
Ind_Online as Ind_PAN,
X.Producto,
X.tipofac,x.NUMAUT
from BASE_TOTAL_FIN as x
where LUGAR='SPOS' and  TIPO_TARJETA='MCD'
;QUIT;

proc sql;
create table &libreria..spos_MCCHEK_&periodo.  as 
select 
X.COD_FECHA as Fecha, 
X.hortrn AS Hora,
floor(X.COD_FECHA/100) as Periodo, 
input(X.codigo_comercio_ant,best32.) as codigo_comercio_ant,
x.codigo_comercio, 
X.NOMCOM as Nombre_Comercio, 
X.RUBRO as Actividad_Comercio, 
X.RUT, 
X.VENTA_TARJETA, 
x.codpais, 
X.TOTCUOTAS,
X.PAN,
X.CODACT,
X.PORINT,
X.CODENT,
X.CENTALTA,
X.CUENTA,
X.Tipo_Tarjeta,
(LEFT(SUBSTR(X.PAN,13,4))) as PAN2, 
CAT(X.CODENT,X.CENTALTA,X.CUENTA,calculated PAN2) as CONTRATO_PAN,
case when x.Ind_Online in ('81','10') then 1 else 0 end as si_digital,
Ind_Online as Ind_PAN,
X.Producto,
X.tipofac,x.NUMAUT
from BASE_TOTAL_FIN as x
where LUGAR='SPOS' and  TIPO_TARJETA='MC CHECK'
;QUIT;

proc sql;
create table &libreria..spos_CTACTE_&periodo.  as 
select 
X.COD_FECHA as Fecha, 
X.hortrn AS Hora,
floor(X.COD_FECHA/100) as Periodo, 
input(X.codigo_comercio_ant,best32.) as codigo_comercio_ant,
x.codigo_comercio, 
X.NOMCOM as Nombre_Comercio, 
X.RUBRO as Actividad_Comercio, 
X.RUT, 
X.VENTA_TARJETA, 
x.codpais, 
X.TOTCUOTAS,
X.PAN,
X.CODACT,
X.PORINT,
X.CODENT,
X.CENTALTA,
X.CUENTA,
X.Tipo_Tarjeta,
(LEFT(SUBSTR(X.PAN,13,4))) as PAN2, 
CAT(X.CODENT,X.CENTALTA,X.CUENTA,calculated PAN2) as CONTRATO_PAN,
case when x.Ind_Online in ('81','10') then 1 else 0 end as si_digital,
Ind_Online as Ind_PAN,
X.Producto,
X.tipofac,x.NUMAUT
from BASE_TOTAL_FIN as x
where LUGAR='SPOS' and  TIPO_TARJETA='CTACTE'
;QUIT;
%put==================================================================================================;
%put [04] TABLA SPOS resumida;
%put==================================================================================================;

proc sql;
create table &libreria..TDA_MCD_&periodo.  as 
select 
X.COD_FECHA as Fecha, 
X.hortrn AS Hora,
floor(X.COD_FECHA/100) as Periodo, 
input(X.codigo_comercio_ant,best32.) as codigo_comercio_ant,
x.codigo_comercio, 
X.NOMCOM as Nombre_Comercio, 
X.RUBRO as Actividad_Comercio, 
X.RUT, 
X.VENTA_TARJETA, 
x.codpais, 
X.TOTCUOTAS,
X.PAN,
X.CODACT,
X.PORINT,
X.CODENT,
X.CENTALTA,
X.CUENTA,
X.Tipo_Tarjeta,
(LEFT(SUBSTR(X.PAN,13,4))) as PAN2, 
CAT(X.CODENT,X.CENTALTA,X.CUENTA,calculated PAN2) as CONTRATO_PAN,
case when x.Ind_Online in ('81','10') then 1 else 0 end as si_digital,
Ind_Online as Ind_PAN,
X.Producto,
X.tipofac,x.NUMAUT
from BASE_TOTAL_FIN as x
where LUGAR='TIENDA' and TIPO_TARJETA='MCD'
;QUIT;


proc sql;
create table &libreria..TDA_MCCHEK_&periodo.  as 
select 
X.COD_FECHA as Fecha, 
X.hortrn AS Hora,
floor(X.COD_FECHA/100) as Periodo, 
input(X.codigo_comercio_ant,best32.) as codigo_comercio_ant,
x.codigo_comercio, 
X.NOMCOM as Nombre_Comercio, 
X.RUBRO as Actividad_Comercio, 
X.RUT, 
X.VENTA_TARJETA, 
x.codpais, 
X.TOTCUOTAS,
X.PAN,
X.CODACT,
X.PORINT,
X.CODENT,
X.CENTALTA,
X.CUENTA,
X.Tipo_Tarjeta,
(LEFT(SUBSTR(X.PAN,13,4))) as PAN2, 
CAT(X.CODENT,X.CENTALTA,X.CUENTA,calculated PAN2) as CONTRATO_PAN,
case when x.Ind_Online in ('81','10') then 1 else 0 end as si_digital,
Ind_Online as Ind_PAN,
X.Producto,
X.tipofac,x.NUMAUT
from BASE_TOTAL_FIN as x
where LUGAR='TIENDA' and TIPO_TARJETA='MC CHEK'
;QUIT;

proc sql;
create table &libreria..TDA_CTACTE_&periodo.  as 
select 
X.COD_FECHA as Fecha, 
X.hortrn AS Hora,
floor(X.COD_FECHA/100) as Periodo, 
input(X.codigo_comercio_ant,best32.) as codigo_comercio_ant,
x.codigo_comercio, 
X.NOMCOM as Nombre_Comercio, 
X.RUBRO as Actividad_Comercio, 
X.RUT, 
X.VENTA_TARJETA, 
x.codpais, 
X.TOTCUOTAS,
X.PAN,
X.CODACT,
X.PORINT,
X.CODENT,
X.CENTALTA,
X.CUENTA,
X.Tipo_Tarjeta,
(LEFT(SUBSTR(X.PAN,13,4))) as PAN2, 
CAT(X.CODENT,X.CENTALTA,X.CUENTA,calculated PAN2) as CONTRATO_PAN,
case when x.Ind_Online in ('81','10') then 1 else 0 end as si_digital,
Ind_Online as Ind_PAN,
X.Producto,
X.tipofac,x.NUMAUT
from BASE_TOTAL_FIN as x
where LUGAR='TIENDA' and TIPO_TARJETA='CTACTE'
;QUIT;


/* EXPORT SAS A AWS */

/* export spos_mcd */
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_spos_mcd,raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_spos_mcd,publicin.spos_mcd_&periodo.,raw,sasdata,0);

/* export tda_mcd */
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_tnda_mcd,raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_tnda_mcd,publicin.tda_mcd_&periodo.,raw,sasdata,0);

/* export spos_mcchek */
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_spos_mcchek,raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_spos_mcchek,publicin.spos_mcchek_&periodo.,raw,sasdata,0);

/* export tda_mcchek */
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_tnda_mcchek,raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_tnda_mcchek,publicin.tda_mcchek_&periodo.,raw,sasdata,0);

/* export spos_ctacte */
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_spos_cta_cte,raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_spos_cta_cte,publicin.spos_ctacte_&periodo.,raw,sasdata,0);

/* export tda_ctacte */
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_tnda_cta_cte,raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_tnda_cta_cte,publicin.tda_ctacte_&periodo.,raw,sasdata,0);


%put==================================================================================================;
%put [05] BORRADO DE TABLAS;
%put==================================================================================================;

/*borrar todas las tablas del work, tener cuidado con tablas internas si no borrara toda la libreria*/
proc datasets library=WORK kill noprint;
run;
quit;

%mend spos_aut;


%macro ejecutar(A);


DATA _null_;
HOY = day(today());
Call symput("HOY", HOY);
RUN;
%put &HOY;

%if %eval(&HOY.<=5) %then %do;

DATA _null_;
periodo_ant = input(put(intnx('month',today(),-1,'end'),yymmn6. ),$10.);
periodo_act = input(put(intnx('month',today(),0,'end'),yymmn6. ),$10.);
Call symput("periodo_ant", periodo_ant);
Call symput("periodo_act", periodo_act);

RUN;

%put &periodo_ant;
%put &periodo_act;

%spos_aut(&periodo_ant.,&lib.);
%spos_aut(&periodo_act.,&lib.);
%end;
%else %DO;

DATA _null_;
periodo_act = input(put(intnx('month',today(),0,'end'),yymmn6. ),$10.);
Call symput("periodo_act", periodo_act);
RUN;

%put &periodo_act;
%spos_aut(&periodo_act.,&lib.);

%end;

%mend ejecutar;

%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

%ejecutar(A);

data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */


/*	Fecha ejecución del proceso	*/
data _null_;
execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechaeDVN", execDVN) ;
RUN;
%put &fechaeDVN;/*fecha ejecucion proceso */

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';

	SELECT EMAIL into :DEST_3 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'ALEJANDRA_MARINAO';

		SELECT EMAIL into :DEST_4
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_2","&DEST_3","&DEST_4")
SUBJECT="MAIL_AUTOM: PROCESO MCD %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
 PUT 'Estimados:';
 PUT "Proceso MCD, ejecutado con fecha: &fechaeDVN";  
 PUT ; 
 PUT 'Tabla resultante en: PUBLICIN.SPOS_MCD_PERIODO'; 
 PUT 'Tabla resultante en: PUBLICIN.TDA_MCD_PERIODO'; 
 PUT 'Tabla resultante en: PUBLICIN.SPOS_MCCHEK_PERIODO'; 
 PUT 'Tabla resultante en: PUBLICIN.TDA_MCCHEK_PERIODO'; 
 PUT 'Tabla resultante en: PUBLICIN.SPOS_CTACTE_PERIODO'; 
 PUT 'Tabla resultante en: PUBLICIN.TDA_CTACTE_PERIODO'; 
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 05'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;


