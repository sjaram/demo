/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	Proyecto_SALDO_SAV			================================*/
/* CONTROL DE VERSIONES
/* 2020-11-18 -- V4 -- Sebastián B. --  
					-- Se agregan 3 columnas adicionales a la salida 
					   t1.Valor_Cuota, t1.N_Cuotas y t1.Saldo
/* 2020-10-15 -- V3 -- Sebastián B. -- Versión Original 
					-- Cambio en día 6 como máximo para ejecución
/* 2020-10-14 -- V2 -- David V. -- Versión Original 
					-- + Comentarios al inicio y al final
					-- + Variables tiempo de ejecución
					-- + Envío de email al final
/* INFORMACIÓN:
- Input
	- REPORITF (JABURTOM)
		- SFADMI_ADM
		- BOPERS_ADM
		- GETRONICS
	- PUBLICIN.CONTRATO_RUT_&PeriodoMax

- Output
	- PUBLICIN.SALDO_SAV_&Periodo_Anterior
*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/

/*###################################################################################*/
/*Proceso de Cierre de Stock SAV indicando Saldos pendiente*/
/*###################################################################################*/

/*
IMPDEUDA1 = CAPITAL FINANCIADO
IMPDEUDA2 = COMISION
IMPDEUDA3 = INTERES
IMPDEUDA4 = IMPUESTO
IMPDEUDA5 = COMISION MORA
IMPDEUDA6 = INTERES MORA
IMPDEUDA7 = IMPUESTO MORA
         Seguro Desgravamen (Perú) 
IMPDEUDA8 = CAPITAL NO FINANCIADO
IMPDEUDA9 = GASTO GESIC
IMPDEUDA10 = COMISION EXTRACTO 
*/
/* IDEM PARA IMPAPL */


/***************************** Validar Proceso ***************************************/



/*******************************Comenzar Proceso *************************************/


/*Definir Parametros*/
/*:::::::::::::::::::::::::::*/
%let Base_Entregable=%nrstr('PUBLICIN.SALDO_SAV'); /*Base entregable _AAAAMM*/
/*:::::::::::::::::::::::::::*/

options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/

%put===========================================================================================;
%put[00] Pasos Preliminares ;
%put===========================================================================================;

%put-------------------------------------------------------------------------------------------;
%put[00.1] Conexiones;
%put-------------------------------------------------------------------------------------------;

LIBNAME SFA  	ORACLE PATH='REPORITF.WORLD' SCHEMA='SFADMI_ADM' USER='JABURTOM'  PASSWORD='JABU#_1107' /*dbmax_text=7025*/;
LIBNAME R_bopers ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='JABURTOM' PASSWORD='JABU#_1107';
LIBNAME MPDT  	ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='JABURTOM'  PASSWORD='JABU#_1107';


%put-------------------------------------------------------------------------------------------;
%put[00.2] Calcular Periodo de nombre con que se guardara Tabla;
%put-------------------------------------------------------------------------------------------;


PROC SQL outobs=1 noprint;   

select 
case 
when input(SB_AHORA('DD'),best.)<=6 then SB_mover_anomes(input(SB_AHORA('AAAAMM'),best.),-1) /*Periodo anterior*/
else input(SB_AHORA('AAAAMM'),best.) 
end as Periodo
into 
:Periodo 
from sashelp.vmember

;QUIT;
%let Periodo=&Periodo;


%put-------------------------------------------------------------------------------------------;
%put[00.3] Construir Nombre de base Entregable;
%put-------------------------------------------------------------------------------------------;


PROC SQL outobs=1 noprint;   

select cats(&Base_Entregable,"_",put(&Periodo,best.)) as Base_Entregable2
into :Base_Entregable2 
from sashelp.vmember

;QUIT;


%put===========================================================================================;
%put[01] Extraccion de Data ;
%put===========================================================================================;



PROC SQL;

CREATE TABLE work.SALDOS_SAV AS 
SELECT 
CODENT, 
CENTALTA, 
CUENTA, 
LINEA, 
SITIMP, 
IMPDEUDA1 as Cuota_Fija, /*componente fija de la cuota*/
Fecfutvto as VCTO,
Impdeuda1+
Impdeuda2+
Impdeuda3+
Impdeuda4+
Impdeuda8+
Impdeuda9+
Impdeuda10 
AS CUOTA,
IMPDEUDA1+
IMPDEUDA2+
IMPDEUDA3+
IMPDEUDA4+
IMPDEUDA5+
IMPDEUDA6+
IMPDEUDA7+
IMPDEUDA8+
IMPDEUDA9+
IMPDEUDA10
AS SALDO1, /*DETALLE CUOTAS X PAGAR*/
IMPAPL1+
IMPAPL2+
IMPAPL3+
IMPAPL4+
IMPAPL5+
IMPAPL6+
IMPAPL7+
IMPAPL8+
IMPAPL9+
IMPAPL10
AS SALDO2 /*AMORTIZACIÓN*/
FROM MPDT.MPDT460 /*SALDOS EPU*/
WHERE LINEA  = '0052' 
and (SITIMP = 'D' /*DISPUESTO*/ OR SITIMP = 'A' /*PENDIENTE AUTORIZACIÓN*/) 

;QUIT;



%put===========================================================================================;
%put[02] Llevar a nivel de contrato Unico ;
%put===========================================================================================;



PROC SQL;

CREATE TABLE work.SALDO_FINAL_SAV AS 
SELECT 
CODENT, 
CENTALTA, 
CUENTA,
avg(Cuota_Fija) as Valor_Cuota,
count(VCTO) as N_Cuotas,
sum(CUOTA) as Saldo, /*deberia dar lo mismo que el saldo total*/
SUM(SALDO1) AS DEUDA_TOTAL, /*CUOTAS X PAGAR*/
SUM(SALDO2) AS PAGOS_TOTAL, /*AMORTIZACIÓN*/ 
SUM(SALDO1) - SUM(SALDO2) AS SALDO_TOTAL /*SALDO_SAV*/
FROM work.SALDOS_SAV
GROUP BY 
CODENT, 
CENTALTA, 
CUENTA

;QUIT;


/*Eliminar tabla de paso*/

proc sql;

drop table work.SALDOS_SAV

;quit;



%put===========================================================================================;
%put[03] Pegar info de rut a partir de tabla contratos ;
%put===========================================================================================;

%put-------------------------------------------------------------------------------------------;
%put[03.1] Obtener Ultimo Periodo disponible de tabla de contratos;
%put-------------------------------------------------------------------------------------------;


PROC SQL outobs=1 noprint;   

select 
max(anomes) as Periodo_Contrato  
into :Periodo_Contrato   
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'PUBLICIN.CONTRATO_RUT_%' 
and length(Nombre_Tabla)=length('PUBLICIN.CONTRATO_RUT_AAAAMM')
) as x

;QUIT;
%let Periodo_Contrato=&Periodo_Contrato;


%put-------------------------------------------------------------------------------------------;
%put[03.2] Pegar rut a partir del contrato;
%put-------------------------------------------------------------------------------------------;



PROC SQL;

CREATE TABLE WORK.SALDO_FINAL_SAV AS 
SELECT 
t2.CONTRATO, 
t2.RUT, 
t1.Valor_Cuota,
t1.N_Cuotas,
t1.Saldo, 
t1.DEUDA_TOTAL, 
t1.PAGOS_TOTAL, 
t1.SALDO_TOTAL
FROM WORK.SALDO_FINAL_SAV as t1
LEFT JOIN PUBLICIN.CONTRATO_RUT_&Periodo_Contrato as t2 
ON (
t1.CODENT = t2.CODENT AND 
t1.CENTALTA = t2.CENTALTA AND  
t1.CUENTA = t2.CUENTA
)

;QUIT;



%put===========================================================================================;
%put[04] Guardar en Tabla Entregable ;
%put===========================================================================================;



proc sql;

create table &Base_Entregable2 as 
select * 
from WORK.SALDO_FINAL_SAV 
where SALDO_TOTAL>0 /*Solo aquellos que tienen Saldo*/ 
order by SALDO_TOTAL 

;quit;


/*Eliminar tabla de paso*/

proc sql;

drop table WORK.SALDO_FINAL_SAV  

;quit;


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

SELECT EMAIL into :DEST_3
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'OSVALDO_UGARTE';

SELECT EMAIL into :DEST_4
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SEBASTIAN_BARRERA';

SELECT EMAIL into :DEST_5
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JOSE_ABURTO';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;
%put &=DEST_5;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4", "&DEST_5")
CC = ("&DEST_1", "&DEST_2", "&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso MENSUAL SALDO SAV");
FILE OUTBOX;
 PUT "Estimados:";
 put "     Proceso MENSUAL SALDO SAV, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put ; 
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 04'; 
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