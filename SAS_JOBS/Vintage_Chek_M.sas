/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	PROC_ACTIVIDAD_TR	 			 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-12-07 -- V17 -- David.V	-- Se agrega columna periodo a tabla de Salida
/* 2022-11-15 -- V16 -- David.V	-- Se incluye export to AWS (Pre-Raw)
/* 2022-10-25 -- V14 -- Alejandra M.
					 -- Se realiza cambios en SPOS,se tomara a partir del mes Octubre 2022la version de SPOS_AUT como fuente oficial y no el cierre de CC.
					 -- Se incorpora las transacciones de Seguros de Open Market
					 -- Solo se considera desde el punto de vista transaccional los clientes con uso en el mes >0 en cada producto.
/* 2022-10-11 -- V13 -- David.V -- Se actualiza variable correo de subgerBI y EARQ
/* 2022-02-25 -- V12 -- David.V -- Se comparte archivo de salida al FTP de Ctrl Com. como PUBLICIN.ACT_TR_YYYYMM 
/* 2020-08-12 -- V11 -- David.V -- Se quita correo de Xime y Seba, dejando el de Jonathan Gonzalez
/* 2020-05-07 -- V10 -- David.V -- Se actualiza credenciales ya que eliminan cuenta MALVARADOU para REPORITF

/* INFORMACIÓN:
/* Tablas necesarias:
	- PUBLICIN.VU
	- RESULT.MARCA_RIESGO_&Periodo
	- publicin.SPOS_AUT_&Periodo_Iteracion
	- publicin.SPOS_&Periodo_Iteracion 
	- publicin.TDA_ITF_&Periodo_Iteracion 
	- publicin.TRX_AV_&Periodo_Iteracion 
	- publicin.TRX_SAV_&Periodo_Iteracion 
	- R_GET.MPDT007 					(REPORITF - GETRONICS)
	- R_GET.MPDT008 					(REPORITF - GETRONICS)
	- R_BOPERS.BOPERS_MAE_IDE 			(REPORITF - BOPERS)
	- result.EDP_BI_DESTINATARIOS

	Tiempo ejecución aprox.: 40 minutos
------------------------------
 DURACIÓN TOTAL:   1:27:09.10
------------------------------
*/
/*==================================================================================================*/


/*##################################################################################################*/
/*Proceso de Actividad TR (Desde TC: tarjeta de credito)*/
/*##################################################################################################*/

/************************************ Validar Proceso ***********************************************/

/*
Observaciones:
1. Para ejecutarse requiere VU del periodo + Marca riesgo del periodo 
2. Si esta los VU se ejecuta la Actividad
*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/************************************ Comenzar Proceso **********************************************/

/*PARAMETROS:*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
%let Periodo_Proceso=0; /*periodo de la actividad (si tiene valor 0, toma periodo anterior*/
%let ventana_tiempo=36; /*ventana de tiempo hacia atras para ver movimientos*/
%let ventana_tiempo_SPOS_AUT=1; /*meses hacia atras que tomara SPOS_AUT (0=ningun mes|1=ultimo mes)*/
%let Base_Entregable=%nrstr('PUBLICIN.ACT_TR'); /*Nombre de Base Entregable ...._AAAAMM*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/


options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/


%put==================================================================================================;
%put [00] Calcular Parametros previos;
%put==================================================================================================;

%put--------------------------------------------------------------------------------------------------;
%put [00.1] Determinar Parametros a Utilizar;
%put--------------------------------------------------------------------------------------------------;


/*Periodo que se usara*/
PROC SQL outobs=1 noprint;   

select 
case 
when &Periodo_Proceso>0 then &Periodo_Proceso 
else SB_mover_anomes(input(SB_AHORA('AAAAMM'),best.),-1) 
end as Periodo,
SB_mover_anomes(input(SB_AHORA('AAAAMM'),best.),-1) as Periodo_Tmenos1  
into 
:Periodo,
:Periodo_Tmenos1
from sashelp.vmember

;QUIT;



/*Periodo Final y Periodo Inicial para movimientos de TC*/
PROC SQL outobs=1 noprint;   

select 
&Periodo as Periodo_hasta,
SB_mover_anomes(&Periodo,-1*(&ventana_tiempo-1)) as Periodo_desde
into 
:Periodo_hasta,
:Periodo_desde
from sashelp.vmember

;QUIT;


%put==================================================================================================;
%put [01] Extraer rutero principal desde base de VU del periodo;
%put==================================================================================================;



%macro Macro_IF;

options cmplib=sbarrera.funcs; /*Script para uso de funciones propias*/

%if &Periodo_Proceso=0 or &Periodo_Proceso=&Periodo_Tmenos1 %then /*Ultimo Periodo*/
%do; /*inicio if*/

proc sql;

create table work.Actividad_TR as 
select 
RUT,
case when VU_C='VU' then 1 else 0 end as VU_RIESGO,
VU_C as MARCA_RIESGO,
VU_C_PRIMA as VU_C_PRIMA,
SALDO_INSOLUTO as SALDO_CONTABLE,
0 as SALDO_FF_CONTABLE, /*Por que??!!!*/
coalesce(Saldos,0) AS SALDO_TOTAL,
MARCA_BASE 
from PUBLICIN.VU /*VU cargado en publicin debidamente actualizado*/

;quit;

%end; /*final if*/
%else /*Para replicar periodos pasados usar misma actividad como rutero*/
%do; /*inicio else*/


DATA _NULL_;
Call execute(
cat('
proc sql;

create table work.Actividad_TR as 
select 
RUT,
VU_RIESGO,
VU_C_PRIMA,
MARCA_RIESGO,
SALDO_CONTABLE,
SALDO_FF_CONTABLE, 
SALDO_TOTAL,
MARCA_BASE 
from PUBLICIN.ACT_TR_',&Periodo,'  

;quit;
')
);
run;


%end; /*final else*/

%mend Macro_IF;

%Macro_IF;



%put==================================================================================================;
%put [02] Calcular rutero de ultimo uso, recencia y frecuencia de movimientos;
%put==================================================================================================;


%put--------------------------------------------------------------------------------------------------;
%put [02.1] Apilar Rutero con Movs por cada Periodo;
%put--------------------------------------------------------------------------------------------------;


%macro Macro_Iteracion;

options cmplib=sbarrera.funcs; /*Script para uso de funciones propias*/


%let Periodo_Iteracion=&Periodo_hasta;

%do %while(&Periodo_Iteracion>=&Periodo_desde); /*inicio del while*/

%put#####################################################################;
%put##### &Periodo_hasta --> &Periodo_Iteracion --> &Periodo_desde ######;
%put#####################################################################;


/*Rutero de SPOS*/

%if &Periodo_Iteracion>=202210 %then
%do; /*inicio if*/

PROC SQL;
CREATE TABLE WORK.uso_spos AS 
SELECT t1.RUT, 
/* SUM_of_VENTA_TARJETA */
(SUM(t1.VENTA_TARJETA)) AS sum_monto
FROM PUBLICIN.SPOS_AUT_&Periodo_Iteracion  t1
GROUP BY t1.RUT;
QUIT;

proc sql;
create table work.TRXs_SPOS as 
select 
rut,
Fecha,
VENTA_TARJETA as Monto 
from PUBLICIN.SPOS_AUT_&Periodo_Iteracion 
where rut in (select rut
from uso_spos
where sum_monto>0)
;quit;

proc sql;
create table work.USO_TDA as 
select 
rut,
(SUM(CAPITAL+PIE)) AS sum_monto
from PUBLICIN.TDA_ITF_&Periodo_Iteracion 
group by rut
;quit;

proc sql;
create table work.TRXs_TDA as 
select 
rut,
10000*year(Fecha)+100*month(Fecha)+day(Fecha) as Fecha,
capital as Monto 
from publicin.TDA_ITF_&Periodo_Iteracion 
where rut in (select rut
from USO_TDA
where sum_monto>0)

;quit;

%end; /*final if*/
%else 
%do; /*inicio else*/

PROC SQL;
CREATE TABLE WORK.uso_spos AS 
SELECT t1.RUT_CLIENTE, 
/* SUM_of_VENTA_TARJETA */
(SUM(t1.VENTA_TARJETA)) AS sum_monto
FROM publicin.SPOS_&Periodo_Iteracion  t1
GROUP BY t1.RUT_CLIENTE;
QUIT;

proc sql;

create table work.TRXs_SPOS as 
select 
rut_cliente as rut,
COD_FECHA as Fecha,
VENTA_TARJETA as Monto 
from publicin.SPOS_&Periodo_Iteracion 
where rut_cliente in (select rut_cliente
from uso_spos
where sum_monto>0)

;quit;

proc sql;
create table work.USO_TDA as 
select 
rut,
(SUM(CAPITAL+PIE)) AS sum_monto
from publicin.TDA_ITF_&Periodo_Iteracion 
group by rut
;quit;


proc sql;
create table work.TRXs_TDA as 
select 
rut,
10000*year(Fecha)+100*month(Fecha)+day(Fecha) as Fecha,
capital as Monto 
from publicin.TDA_ITF_&Periodo_Iteracion
where rut in (select rut
from USO_TDA
where sum_monto>0)
;quit;

%end; /*final else*/



/*Rutero de SEGURO OPEN MARKET*/

proc sql;
create table work.USO_SOM as 
select 
rut,
(SUM(MONTO_RECAUDADO)) AS sum_monto
from publicin.TRX_SEGUROS_&Periodo_Iteracion 
group by rut
;quit;

proc sql;
create table work.TRXs_SEGUROS as 
select 
rut,
input(compress(FECPROCES,"-"),best.) as Fecha,
MONTO_RECAUDADO as Monto 
from publicin.TRX_SEGUROS_&Periodo_Iteracion 
where TIPO_SEGURO='SEGUROS OPEN MARKET' and CODCONREC not in ('S201','S083','170')
AND rut in (select rut
from USO_SOM
where sum_monto>0)
;quit;

/*Rutero de AV*/

proc sql;
create table work.USO_AV as 
select 
rut,
(SUM(capital)) AS sum_monto
from publicin.TRX_AV_&Periodo_Iteracion 
group by rut
;quit;

proc sql;

create table work.TRXs_AV as 
select 
rut,
input(compress(FECFAC,"-"),best.) as Fecha,
capital as Monto 
from publicin.TRX_AV_&Periodo_Iteracion 
where rut in (select rut
from USO_AV
where sum_monto>0)
;quit;


/*Rutero de SAV*/

proc sql;
create table work.USO_SAV as 
select 
rut,
(SUM(capital)) AS sum_monto
from publicin.TRX_SAV_&Periodo_Iteracion 
group by rut
;quit;

proc sql;

create table work.TRXs_SAV as 
select 
rut,
input(compress(FECFAC,"-"),best.) as Fecha,
capital as Monto 
from publicin.TRX_SAV_&Periodo_Iteracion 
where rut in (select rut
from USO_SAV
where sum_monto>0)

;quit;

/*Unificar todos los ruteros en un unico rutero de la iteracion (_I)*/


DATA _NULL_;
Call execute(
cat('
proc sql; 

create table work.Rutero_Movs_TC_I as 
select 
rut,
1 as F_meses,
/*sum(Monto) as Monto_Total,*/ 
/*count(distinct Fecha) as F_Dias,*/
max(Fecha) as Max_Fecha 

from ( 

select * from work.TRXs_SPOS outer union corr 
select * from work.TRXs_TDA  outer union corr 
select * from work.TRXs_SEGUROS  outer union corr 
select * from work.TRXs_AV   outer union corr 
select * from work.TRXs_SAV   

) as x 
group by 
rut 

;quit; 
')
);
run;





/*Si es primera iteracion, crear consolidado (_C)*/
%if &Periodo_Iteracion=&Periodo_hasta %then
%do; /*inicio if*/

proc sql;

create table work.Rutero_Movs_TC_C as 
select * 
from work.Rutero_Movs_TC_I 

;quit;

%end; /*final if*/
%else 
%do; /*inicio else*/


/*Crear tabla de paso intermedia, unificando consolidado con Iteracion*/
proc sql;

create table work.Rutero_Movs_TC_C2 as 
select 
rut,
sum(F_meses) as F_meses,
/*sum(Monto_Total) as Monto_Total,*/ 
/*sum(F_Dias) as F_Dias,*/ 
max(Max_Fecha) as Max_Fecha 

from (

select * 
from work.Rutero_Movs_TC_I 

outer union corr 

select * 
from work.Rutero_Movs_TC_C  

) as x 
group by 
rut 

;quit;


/*Pisar consolidado con nueva info*/
proc sql;

create table work.Rutero_Movs_TC_C as 
select * 
from work.Rutero_Movs_TC_C2

;quit;


%end; /*final else*/

/*actualizar variable de iteracion del while*/
%let Periodo_Iteracion=%sysfunc(SB_Mover_anomes(&Periodo_Iteracion,-1));

%end; /*final del while*/

%mend Macro_Iteracion;

%Macro_Iteracion;


/*Eliminar tablas de paso*/

proc sql; drop table work.TRXs_SPOS ;quit;
proc sql; drop table work.TRXs_TDA  ;quit;
proc sql; drop table work.TRXs_AV   ;quit;
proc sql; drop table work.TRXs_SAV  ;quit;

proc sql; drop table work.Rutero_Movs_TC_I  ;quit;
proc sql; drop table work.Rutero_Movs_TC_C2  ;quit;


%put--------------------------------------------------------------------------------------------------;
%put [02.2] Calcular otros indicadores (Fechas y Recencias);
%put--------------------------------------------------------------------------------------------------;


proc sql;

create table work.Rutero_Movs_TC_C as 
select 
rut,
F_meses,
/*Monto_Total,*/ 
/*F_Dias,*/
Max_Fecha, 
MDY(
input(substr(compress(put(Max_Fecha,best.)),5,2),best.),
input(substr(compress(put(Max_Fecha,best.)),7,2),best.),
input(substr(compress(put(Max_Fecha,best.)),1,4),best.)
) format=date9. as Max_Fecha2,
floor(Max_Fecha/100) as Max_Periodo,
SB_meses_entre(floor(Max_Fecha/100),&Periodo) as R_meses,
SB_dias_entre(Max_Fecha,100*&Periodo+SB_dias_mes(&Periodo)) as R_dias 
from work.Rutero_Movs_TC_C   

;quit;



%put--------------------------------------------------------------------------------------------------;
%put [02.3] Pegar indicadores;
%put--------------------------------------------------------------------------------------------------;



proc sql;

create table work.Actividad_TR as 
select 
a.*,
b.Max_Fecha as FECHA_AAAAMMDD_ULT_COMPRA,
b.Max_Periodo as PERIODO_ULT_COMPRA,
b.Max_Fecha2 as FECHA_ULT_COMPRA,
b.R_meses as RECENCIA_TR,
b.F_meses as FRECUENCIA 
from work.Actividad_TR as a 
left join work.Rutero_Movs_TC_C as b 
on (a.rut=b.rut) 

;quit;



/*Eliminar tabla de paso*/
proc sql; drop table work.Rutero_Movs_TC_C ;quit;



%put==================================================================================================;
%put [03] Agregar/Calcular otras variables/indicadores/marcas;
%put==================================================================================================;


%put--------------------------------------------------------------------------------------------------;
%put [03.1] Agregar P_Aprobacion y P_Activacion;
%put--------------------------------------------------------------------------------------------------;

/*Conexiones a Librerias*/
LIBNAME R_bopers ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='SAS_USR_BI' PASSWORD='SAS_23072020';
LIBNAME R_get 	 ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS'  USER='SAS_USR_BI' PASSWORD='SAS_23072020';

/*Bajar muestras de tablas con campos relevantes*/

proc sql;

create table work.MPDT007 as
select 
IDENTCLI, 
CODENT, 
CUENTA, 
CENTALTA, 
FECALTA 
from R_GET.MPDT007 

;quit;


proc sql;

create table work.MPDT008 as
select 
CODENT,
CUENTA,
CENTALTA,
FECACUSER 
from R_GET.MPDT008 

;quit;


proc sql;

create table work.BOPERS_MAE_IDE as
select 
PEMID_GLS_NRO_DCT_IDE_K, 
PEMID_NRO_INN_IDE  
from R_BOPERS.BOPERS_MAE_IDE 

;quit;

/*Cruzar tablas creando Tabla unificada*/
PROC SQL;

CREATE TABLE work.CONTRATO_RUT AS
SELECT 
A.CODENT,
A.CUENTA, 
A.CENTALTA,
INPUT(C.PEMID_GLS_NRO_DCT_IDE_K,BEST.) AS RUT,
case when A.FECALTA<>'0001-01-01' then input(compress(A.FECALTA,'-'),best.) end as FECALTA,
case when b.FECACUSER<>'0001-01-01' then input(compress(B.FECACUSER,'-'),best.) end as FECACUSER 
FROM work.MPDT007 as A 
LEFT JOIN work.MPDT008 as B 
ON (A.CODENT=B.CODENT AND A.CENTALTA=B.CENTALTA AND A.CUENTA=B.CUENTA)
LEFT JOIN work.BOPERS_MAE_IDE as C 
ON (INPUT(A.IDENTCLI,BEST.) = C.PEMID_NRO_INN_IDE)

;QUIT;


/*Agrupar a Nivel de rut Unico calculando Variables*/
PROC SQL;

CREATE TABLE work.CONTRATO_RUT2 AS
SELECT 
rut,
min(case when floor(FECALTA/100)<=&Periodo then floor(FECALTA/100) end) as P_APROBACION,
min(case when floor(FECACUSER/100)<=&Periodo then floor(FECACUSER/100) end) as P_ACTIVACION 
from work.CONTRATO_RUT 
group by 
rut 

;QUIT;

/*Pegar en tabla*/
proc sql;

create table work.Actividad_TR as 
select 
a.*,
b.P_APROBACION,
b.P_ACTIVACION 
from work.Actividad_TR as a 
left join work.CONTRATO_RUT2 as b 
on (a.rut=b.rut) 

;quit;


/*Eliminar tabla de paso*/
/*
proc sql; drop table work.CONTRATO_RUT ;quit;
proc sql; drop table work.CONTRATO_RUT2 ;quit;
proc sql; drop table work.MPDT007 ;quit;
proc sql; drop table work.MPDT008 ;quit;
proc sql; drop table work.BOPERS_MAE_IDE ;quit;
*/

%put--------------------------------------------------------------------------------------------------;
%put [03.2] Calcular Marca de Actividad;
%put--------------------------------------------------------------------------------------------------;


proc sql;

create table work.Actividad_TR as 
select 
*,
case 
when coalesce(RECENCIA_TR,999)<=2 then 'ACTIVO' /*ultimos 3 meses*/
when coalesce(RECENCIA_TR,999)<=11 then 'SEMIACTIVO' /*ultimos 12 meses*/
when coalesce(RECENCIA_TR,999)<=23 then 'DORMIDO BLANDO' /*ultimos 24 meses*/
when coalesce(SALDO_CONTABLE,0)>0 then 'OTROS CON SALDO' /*con saldo >0*/
when (coalesce(PERIODO_ULT_COMPRA,0)=0 or PERIODO_ULT_COMPRA<P_APROBACION)
and  P_APROBACION>=200804 /*Por que???!!*/
and  P_ACTIVACION BETWEEN SB_mover_anomes(&Periodo,-11) and &Periodo /*en ultimos 12 meses*/
THEN 'NUEVO SIN USO' 
WHEN coalesce(PERIODO_ULT_COMPRA,0)=0 
and  P_ACTIVACION BETWEEN SB_mover_anomes(&Periodo,-11) and &Periodo /*en ultimos 12 meses*/ 
THEN 'NUEVO SIN USO'
WHEN coalesce(PERIODO_ULT_COMPRA,0)=0 
and  P_ACTIVACION is null 
and  P_APROBACION BETWEEN SB_mover_anomes(&Periodo,-11) and &Periodo /*en ultimos 12 meses*/
THEN 'NUEVO SIN USO'
WHEN PERIODO_ULT_COMPRA IS NOT null THEN 'DORMIDO DURO' /*No hay ventana de tiempo para dormido duro*/
/*else 'ANTIGUO SIN USO'*/ /*valor por default de proceso antiguo*/
else 'DORMIDO DURO' /*valor por default*/
END AS ACTIVIDAD_TR 
from work.Actividad_TR  

;quit;


/*
El "case when" anterior es exacto al del proceso original (no ha sido optimizado) 
Notar que la diferencia entre el "dormido duro" y el "antiguo sin uso" es practicamente nula
no hay un corte de recencia claramente definido para diferenciar ambas marcas
El dormido duro, por definicion, es aquel sin movimientos en los ultimos 2 años 
Para efectos practicos se dejara una sola marca (dormido duro)
*/


%put--------------------------------------------------------------------------------------------------;
%put [03.3] Calcular Marca de VU_IC;
%put--------------------------------------------------------------------------------------------------;


proc sql;

create table work.Actividad_TR as 
select 
*,
case 
when ACTIVIDAD_TR in ('ACTIVO','SEMIACTIVO','OTROS CON SALDO','DORMIDO BLANDO')
and VU_RIESGO=1 
then 1 
else 0 
END AS VU_IC /*es un VU con movimientos en los ultimos 2 años*/
from work.Actividad_TR  

;quit;


%put--------------------------------------------------------------------------------------------------;
%put [03.4] Pegar Observacion desde Marca Riesgo del Periodo Correspondiente;
%put--------------------------------------------------------------------------------------------------;




%macro Macro_IF2;

options cmplib=sbarrera.funcs; /*Script para uso de funciones propias*/

%if &Periodo>=201907 %then /*desde donde hay tablas de marca riesgo*/
%do; /*inicio if*/

DATA _NULL_;
Call execute(
cat('
proc sql;

create table work.Actividad_TR as 
select 
a.*,
b.OBSERVACION 
from work.Actividad_TR as a 
left join result.MARCA_RIESGO_',&Periodo,' as b /*de donde viene esta tabla??!!*/
on (a.rut=b.rut) 

;quit;
')
);
run;


%end; /*final if*/
%else /*hacia mas atras no hay marca de riesgo --> usar actividad*/
%do; /*inicio else*/

DATA _NULL_;
Call execute(
cat('
proc sql;

create table work.Actividad_TR as 
select 
a.*,
b.OBSERVACION 
from work.Actividad_TR as a 
left join publicin.ACT_TR_',&Periodo,' as b 
on (a.rut=b.rut) 

;quit;
')
);
run;


%end; /*final else*/

%mend Macro_IF2;

%Macro_IF2;



%put==================================================================================================;
%put [04] Guardar Tabla entregable en formato correspondiente;
%put==================================================================================================;

%put--------------------------------------------------------------------------------------------------;
%put [04.1] Guardar Actividad en Tabla entregable con campos en orden;
%put--------------------------------------------------------------------------------------------------;


DATA _NULL_;
Call execute(
cat('
proc sql; 

create table ',&Base_Entregable,'_',&Periodo,' as 
select 
',&Periodo,' as Periodo,
''1'' AS ACT_TR, 
RUT,
VU_RIESGO,
VU_IC,
VU_C_PRIMA,
ACTIVIDAD_TR,
0 as MARCA_CARTERA,
MARCA_RIESGO,
FECHA_AAAAMMDD_ULT_COMPRA,
PERIODO_ULT_COMPRA,
FECHA_ULT_COMPRA,
P_APROBACION,
P_ACTIVACION,
SALDO_CONTABLE,
SALDO_FF_CONTABLE,
SALDO_TOTAL,
0 as IMPRIME_TR,
MARCA_BASE,
RECENCIA_TR,
FRECUENCIA,
OBSERVACION 
from work.Actividad_TR 

;quit; 
')
);
run;


%put--------------------------------------------------------------------------------------------------;
%put [04.2] Guardar Tabla de Validacion/revision resultados Actividad;
%put--------------------------------------------------------------------------------------------------;



DATA _NULL_;
Call execute(
cat('
proc sql; 

create table ',&Base_Entregable,'_revision as 
select 
',&Periodo,' as Periodo,
VU_RIESGO,	
VU_IC,	
VU_C_PRIMA,	
ACTIVIDAD_TR,	
MARCA_RIESGO,	
case when RECENCIA_TR=0 then 1 else 0 end as CON_USO_MES,
case when SALDO_CONTABLE>0 then 1 else 0 end as CON_SALDO,
case when MARCA_BASE like ''%TAM%'' then ''TAM'' else ''TR'' end as Tipo_TC,
count(*) as Nro_Clientes,
sum(SALDO_CONTABLE) as sum_SALDO_CONTABLE 
from work.Actividad_TR 
group by 
VU_RIESGO,	
VU_IC,	
VU_C_PRIMA, 
ACTIVIDAD_TR,	
MARCA_RIESGO,	
calculated CON_USO_MES,
calculated CON_SALDO,
calculated Tipo_TC 

;quit; 
')
);
run;

DATA _null_;
datex1 = put(intnx('month',today(),-1,'same'),yymmn6. );
Call symput("fechax1", datex1);
RUN;

/*Eliminar tabla de paso*/
/*proc sql; drop table work.Actividad_TR ;quit;*/

/*	OBTENER EL PRIMER REGISTRO DE LA TABLA GENERADA PARA INCORPORAR AL EMIAL*/
PROC SQL;
CREATE TABLE COUNT_DE_TABLA_TMP AS
	SELECT COUNT(rut) AS CANTIDAD_DE_REGISTROS
		from PUBLICIN.ACT_TR_&fechax1
;QUIT;

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
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
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SUBG_BI';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'GRUPO_BI';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;

FILENAME output EMAIL
SUBJECT="MAIL_AUTOM: PROCESO ACTIVIDAD TR %sysfunc(date(),yymmdd10.)" 
FROM = ("&EDP_BI")
/*TO = ("&DEST_3")*/
TO = ("&DEST_1")
/*CC = ("&DEST_1","&DEST_2","&DEST_4")*/
CT= "text/html"  ;
ODS HTML 
BODY=output 
style=sasweb; 
ods escapechar='~'; 

title1  "Estimados:";
title2 font='helvetica/italic' height=10pt 
		" Proceso ACTIVIDAD TR, ejecutado con fecha: &fechaeDVN 
		  Favor vuestra validacion
		~n 
		~n
		  Proceso Vers. 17
		~n 
		~n
		~n 
		~n
		Atte.
		~n
		Equipo Arquitectura de Datos y Automatización BI
		~n
";
PROC REPORT DATA=COUNT_DE_TABLA_TMP NOWD
STYLE(REPORT)=[PREHTML="<hr>"] /*Inserts a rule between title & body*/;
RUN;
ODS HTML CLOSE;

/* Se comparte archivo de salida al FTP de Control Comercial como PUBLICIN.TABLON_PRODUCTOS_YYYYMM */
PROC EXPORT DATA=PUBLICIN.ACT_TR_&fechax1
OUTFILE="/sasdata/TEST/PUBLICIN.ACT_TR_&fechax1..txt"
DBMS=dlm;
delimiter=';';
PUTNAMES=YES;
RUN;

/* EXPORTAR DE SAS A UN FTP O SFTP */
filename server ftp "PUBLICIN.ACT_TR_&fechax1..txt" CD='/'
HOST='192.168.82.171' user='17457765K' pass='17457765K' PORT=21;

data _null_;
infile "/sasdata/TEST/PUBLICIN.ACT_TR_&fechax1..txt";
file server;
input;
put _infile_;
run;

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================        EXPORT_TO_AWS - INI          ===============================*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_bitr_act_tr,raw,sasdata,-1);

/*Exportación a AWS*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_bitr_act_tr,PUBLICIN.ACT_TR_&fechax1.,raw,sasdata,-1);

/*==============================        EXPORT_TO_AWS - END          ===============================*/
/*==================================================================================================*/
