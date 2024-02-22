/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	CUP_PRESENCIAL				================================*/
/* CONTROL DE VERSIONES
/* 2022-04-05 -- V2 -- Esteban P. -- Se actualizan los correos: Se elimina a SEBASTIAN_BARRERA y OSVALDO_UGARTE.
/* 2020-10-15 -- V1 -- Pedro M. -- Versión Original 

/* INFORMACIÓN:
/* 		Saber cuantos clientes captados de manera presencial, tenemos con CUP firmado, 
		ya sea firmado de forma digital o presencial.
- Input
	- REPORITF (KMARTINEZ)
		- SFADMI_ADM
	- SEGCOM (PMUNOZC)
		- mpdt666

- Output
	- RESULT.CUP_VIGENTE
*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
%put==================================================================================================;
%put [0.1] BASE FIRMA CUP;
%put==================================================================================================;

pROC SQL ;
CONNECT TO ORACLE AS REPORTITF (PATH="REPORITF.WORLD" USER='KMARTINEZ' PASSWORD='kmar2102');
CREATE TABLE CUP_PRESENCIAL AS 
SELECT * FROM CONNECTION TO REPORTITF(
select 
DECODE(SUBSTR(C.OFE_COD_PRD_OFE_K,1,2),'01','TARJETA CREDITO',
'02','CAMBIO PRODUCTO','04', 'CUENTA VISTA', ' ') as PRODUCTO, 
DECODE(SUBSTR(C.OFE_COD_PRD_OFE_K,1,2),'04',SUBSTR(C.OFE_CAC_NRO_CTT,9,10), C.OFE_CAC_NRO_CTT) as CONTRATO,
cast(A.SOL_COD_IDE_CLI as INT) as RUT,
A.SOL_FCH_CRC_SOL as FECHA_CREACION,
A.SOL_COD_NRO_SOL_K as NRO_SOLICITUD, 
A.SOL_COD_EST_SOL, 
B.FIR_COD_IND_MAU_FIN as INDICADOR_FIRMA_MANUAL,
B.FIR_COD_IND_DIG_FIN as INDICADOR_FIRMA_DIGITAL
FROM SFADMI_BCO_SOL A, 
SFADMI_BCO_FIR_DCT_SOL B,
SFADMI_BCO_OFE C
WHERE 
A.SOL_COD_CLL_ADM <>  2 and 
A.SOL_COD_EST_SOL = 11 AND 
B.FIR_COD_FIR_IDE_K = 3     and 
(B.FIR_COD_IND_DIG_FIN = 1 or 
B.FIR_COD_IND_MAU_FIN = 1) AND 
B.FIR_COD_NRO_SOL_K = A.SOL_COD_NRO_SOL_K 
AND B.FIR_COD_NRO_SOL_K = C.OFE_COD_NRO_SOL_K
AND C.OFE_COD_IND_NGC = 1
AND SUBSTR(C.OFE_COD_PRD_OFE_K,1,2) IN ('01','02','04')
AND NOT EXISTS ( SELECT BTC_COD_NRO_SOL_K
                  FROM SFADMI_BCO_BTC_SOL E
                 WHERE E.BTC_COD_NRO_SOL_K = A.SOL_COD_NRO_SOL_K
                    AND E.BTC_COD_TIP_REG_K = 1
                    AND E.BTC_COD_ETA_K = 102
                    AND E.BTC_COD_EVT_K = 30))
;QUIT;

%put==================================================================================================;
%put [0.2] Base de paso segcom mpdt666(fisa-rsat relacion);
%put==================================================================================================;


%let path_ora        = '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=192.168.84.76)(PORT=1521))(CONNECT_DATA=(SERVER=dedicated)(SID=SEGCOM)))'; 
%let user_ora        = 'PMUNOZC'; 
%let pass_ora        = 'pmun3012';
 
%let conexion_ora    = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 
  
PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );
 
create table mpdt666 as
select 

CODENT1,
CENTALTA1,
CUENTA1,
input(cuenta2,best.) as cv

from connection to ORACLE
(
select * from MPDT666
 
);
disconnect from ORACLE;
QUIT;


proc sql;
create table CUP_PRESENCIAL2 as 
select 
a.*,
case when a.producto in ('TARJETA CREDITO','CAMBIO PRODUCTO') then a.contrato
when a.producto not in ('TARJETA CREDITO','CAMBIO PRODUCTO') and b.cv is not null then 
b.CODENT1||b.CENTALTA1||b.CUENTA1 end as CONTRATO_RSAT
from CUP_PRESENCIAL as a
left join mpdt666 as b
on(input(a.contrato,best.)=b.cv)
;QUIT;



%put==================================================================================================;
%put [0.3] TIPO DE CONTRATO;
%put==================================================================================================;



pROC SQL ;
CONNECT TO ORACLE AS REPORTITF (PATH="REPORITF.WORLD" USER='KMARTINEZ' PASSWORD='kmar2102');
CREATE TABLE TIPO_CONTRATO AS 
SELECT * FROM CONNECTION TO REPORTITF(
select 
a.CODENT,
a.CENTALTA,
a.CUENTA,
a.CODENT||a.CENTALTA||a.CUENTA as contrato,
a.FECALTA,
a.FECBAJA,
b.VERSION,
b.DESVERSION

from mpdt007  a
left join ( select a.CODENT,
a.CENTALTA,
a.CUENTA,
a.CODENT||a.CENTALTA||a.CUENTA as contrato,
a.VERSION,
b.DESVERSION

from mpdt494 a
left join mpdt496 b
on(a.version=b.version)) b
on(a.CODENT||a.CENTALTA||a.CUENTA=b.contrato)
)
;QUIT;

proc sql;
create table CUP_PRESENCIAL3 as 
select distinct 
a.*,
b.FECBAJA,
b.version,
b.desversion
from CUP_PRESENCIAL2 as a
left join TIPO_CONTRATO as b
on(a.contrato_rsat=b.contrato)
;QUIT;

%put==================================================================================================;
%put [0.4] ENTREGABLE;
%put==================================================================================================;

proc sql;
create table RESULT.CUP_VIGENTE as 
select distinct 
PRODUCTO,
CONTRATO,
CONTRATO_RSAT,
RUT,
datepart(FECHA_CREACION) format=date9. as FECHA_FIRMA,
INDICADOR_FIRMA_MANUAL,
INDICADOR_FIRMA_DIGITAL,
VERSION as VERSION_CONTRATO,
DESVERSION as DESC_CONTRATO
from CUP_PRESENCIAL3 
where FECBAJA='0001-01-01'
;QUIT;

proc sql;
drop table CUP_PRESENCIAL;
drop table mpdt666;
drop table CUP_PRESENCIAL2;
drop table TIPO_CONTRATO;
drop table CUP_PRESENCIAL3;
;QUIT;


/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	FECHA PROCESO Y ENVÍO DE EMAIL =============================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

SELECT EMAIL into :DEST_5
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JOSE_ABURTO';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_5;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
/*CC = ("&DEST_4", "&DEST_5")*/
TO = ("&DEST_1", "&DEST_2")
SUBJECT = ("MAIL_AUTOM: Proceso CUP PRESENCIAL");
FILE OUTBOX;
 PUT "Estimados:";
 put "     Proceso CUP PRESENCIAL, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put ; 
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 01'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
