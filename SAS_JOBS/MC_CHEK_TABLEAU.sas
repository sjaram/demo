/*==================================================================================================*/
/*==================================	EQUIPO ARQ.DATOS Y AUTOM.		============================*/
/*==================================	MC_CHEK_TABLEAU					============================*/
/* CONTROL DE VERSIONES
/* 2023-11-09 -- V09    -- David V. 	-- Se actualiza conexión para ahora apuntar a SEGCOM_NEW.
/* 2023-09-26 -- V08    -- David V. 	-- Se agrega a Nico Verdejo al correo de salida.
/* 2023-06-23 -- V07    -- David V. 	-- Se comenta parte para quitar error mínimo en log.
/* 2023-01-25 -- V06    -- David V. 	-- Se comenta parte oracloud para quitar error en logs.
/* 2022-09-30 -- V05    -- Sergio J. 	-- Se modifica conexión a reportitf por data switch
/* 2022-08-29 -- V04    -- Sergio J. 	-- Se añade sentencia include para borrar y exportar a RAW
/* 2022-07-11 -- V03	-- David V. 	-- Ajustes mínimos para nuevo flujo "Oracloud AWS Athena".
/* 2022-05-17 -- V02 	-- Jonathan G. 	-- Actualización quita PAN de la query
*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*==================================================================================================*/

%put===========================================================================================;
%put [00] USUARIOS CHEK CON TRANSACCIONES  ;
%put===========================================================================================;

proc sql noprint;
	SELECT USUARIO into :USER 
		FROM sasdyp.user_pass WHERE SCHEMA = 'SEGCOM';
	SELECT PASSWORD into :PASSWORD 
		FROM sasdyp.user_pass WHERE SCHEMA = 'SEGCOM';
quit;

%let mz_connect_BANCO=CONNECT TO ORACLE as BANCO(USER=&USER. PASSWORD=&PASSWORD.
PATH="(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.84.167)(PORT = 1521))(CONNECT_DATA=(SERVER = DEDICATED)(SERVICE_NAME = segcom)))"); 

PROC SQL NOERRORSTOP;
&mz_connect_BANCO; 
create table cuentas_trxs as
select *
from connection to BANCO(
SELECT
cast(a2.PEMID_GLS_NRO_DCT_IDE_K as INT) RUT,
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
a.CODCOM Codigo_Comercio_ant,
a.NOMCOM,
sum(a.imptrn) VENTA_TARJETA,
a.Tipfran,
a.totcuotas,
a.porint,
a.tipofac,
a.IMPCCA,
a.CLAMONCCA,
a.IMPDIV,
a.INDCRUCE,
substr(a.MODENTDAT,1,2) Ind_Online,
a.NUMAUT,
a3.DESACT RUBRO,
a.codrespu
from REPLICA_ADM.MPDT004 a
INNER JOIN REPLICA_ADM.MPDT007 a1 /*CONTRATO*/
ON (A.CODENT=a1.CODENT) AND (A.CENTALTA=a1.CENTALTA) AND (A.CUENTA=a1.CUENTA)
INNER JOIN BOPERS_ADM.BOPERS_MAE_IDE a2 ON
A1.IDENTCLI=a2.PEMID_NRO_INN_IDE
inner join REPLICA_ADM.MPDT039 a3
on(a.CODACT = a3.CODACT)
where /*a.codrespu = '000'*/
 a1.producto = 12
and a.tipfran <> 1004
/*and cast(REPLACE(a.fectrn, '-') as INT)>=20220101
and cast(REPLACE(a.fectrn, '-') as INT)<=202120110*/
and SUBSTR(a.PAN,1,6)='525384'
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
a.tipofac,
a.IMPCCA,
a.CLAMONCCA,
a.IMPDIV,
substr(a.MODENTDAT,1,2),
a.NUMAUT,
cast(a2.PEMID_GLS_NRO_DCT_IDE_K as INT),
a3.DESACT,
a1.producto,
a.INDCRUCE,
a.codrespu
) A
;QUIT;

proc sql;

create table cuentas_trxs as
select a.*, b.Rubros_SPOS from work.cuentas_trxs as a 
left join sbarrera.arbol_rubros_spos as b
on a.CODACT = b.COD_ACT

;quit;


%put===========================================================================================;
%put [00] USUARIOS CHEK CON ACTIVACIÓN DE MC ;
%put===========================================================================================;

PROC SQL NOERRORSTOP;
&mz_connect_BANCO; 
create table cuentas  as 
select * 
from connection to BANCO( 
select 
cast(B.PEMID_GLS_NRO_DCT_IDE_K as INT)  RUT,
A.CODENT,
A.CENTALTA,
A.CUENTA,
a.FECALTA  FECALTA_CTTO,
a.FECBAJA  FECBAJA_CTTO,
cast(REPLACE(a.FECALTA, '-') as int) Fecha_alta,
a.PRODUCTO,
a.SUBPRODU,
a.CONPROD
from REPLICA_ADM.MPDT007 a
INNER JOIN BOPERS_ADM.BOPERS_MAE_IDE B 
ON A.IDENTCLI=B.PEMID_NRO_INN_IDE
WHERE a.PRODUCTO = '12'
) A
;QUIT;

%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_DELETE.sas";
%borrarOracleRaw(CHEK_MASTERCARD);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_EXPORT.sas";
%ExportacionOracleRaw(CHEK_MASTERCARD,WORK.cuentas_trxs);

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_DELETE.sas";
%borrarOracleRaw(CHEK_MASTERCARD_CUENTAS);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_EXPORT.sas";
%ExportacionOracleRaw(CHEK_MASTERCARD_CUENTAS,WORK.cuentas);

/*==================================================================================================*/

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
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_DIGITAL';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_CHEK_1';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_CHEK_2';
	SELECT EMAIL into :DEST_7 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_DIGITAL_1';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;
%put &=DEST_6;	%put &=DEST_7;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4","&DEST_5","&DEST_6","&DEST_7")
CC = ("&DEST_1","&DEST_2","&DEST_3")
SUBJECT="MAIL_AUTOM: PROCESO MC_CHEK_TABLEAU" ;
FILE OUTBOX;
PUT 'Estimados:';
 PUT "Proceso MC_CHEK_TABLEAU, ejecutado con fecha: &fechaeDVN";  
 PUT ; 
 PUT 'Tabla resultante en Athena: CHEK_MASTERCARD';
 PUT 'Tabla resultante en Athena: CHEK_MASTERCARD_CUENTAS';
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 09'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
