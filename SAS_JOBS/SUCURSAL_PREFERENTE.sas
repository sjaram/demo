/*##########################################################################################*/
/* Proceso de Sucursal Preferente */
/*##########################################################################################*/

/****************************** Versiones del Proceso *************************************/

/* Version 2--> se cambio coneccion y se deribo de amarinao.suucrsales a result.Maestro de sucursal*/
*/

/********************************** Comenzar Proceso ***************************************/;


options cmplib=sbarrera.funcs; 

PROC SQL noprint outobs=1;   

select SB_Mover_anomes(input(SB_AHORA('AAAAMM'),best.),-1) as Periodo_Proceso    
into :Periodo_Proceso 
from sashelp.vmember

;QUIT;


/*+++++++++++++++++++++++++++++++++++++++++++*/
/*FINAL: Calculo de parametro*/
/*+++++++++++++++++++++++++++++++++++++++++++*/


/*PARAMETROS::*/
/*:::::::::::::::::::::::*/
%let anomes=&Periodo_Proceso;
%let Ventana_Tiempo=12;
%let Base_Entregable=%nrstr('publicin.Sucursal_Preferente');
/*:::::::::::::::::::::::*/


options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/

%put==============================================================================================;
%put [01] Extraer Venta desde Venta_BOL por Rut-Sucursal;
%put==============================================================================================;


%put----------------------------------------------------------------------------------------------;
%put [01.1] Calcular Periodos para ventana de Tiempo;
%put----------------------------------------------------------------------------------------------;



PROC SQL noprint outobs=1;   

select 
SB_mover_anomes(&anomes,-1*(&Ventana_Tiempo-1)) as anomes_i,
&anomes as anomes_f
into 
:anomes_i,
:anomes_f
from sbarrera.SB_Status_Tablas_IN

;QUIT;


%put----------------------------------------------------------------------------------------------;
%put [01.2] Extraer info desde venta tienda;
%put----------------------------------------------------------------------------------------------;


%let mz_connect_zeus=CONNECT TO ODBC as zeus(datasrc="creditoprd" user="CONSULTA_CREDITO" password="crdt#0806");

PROC SQL;

&MZ_CONNECT_ZEUS;
CREATE TABLE work.Venta_Tienda AS
SELECT 
rut,
Codigo_Sucursal,

sum(case when Nro_TRXs_TMP>0 then 1 else 0 end) as Frec_TMP,
SB_Meses_Entre(max(case when Nro_TRXs_TMP>0 then Periodo else 0 end),&anomes_f) as Rec_TMP,
sum(Nro_TRXs_TMP) as Nro_TRXs_TMP,
sum(Mto_TRXs_TMP) as Mto_TRXs_TMP, 

sum(case when Nro_TRXs_TAR>0 then 1 else 0 end) as Frec_TAR,
SB_Meses_Entre(max(case when Nro_TRXs_TAR>0 then Periodo else 0 end),&anomes_f) as Rec_TAR,
sum(Nro_TRXs_TAR) as Nro_TRXs_TAR,
sum(Mto_TRXs_TAR) as Mto_TRXs_TAR 

FROM CONNECTION TO ZEUS(
select 
PERIODO,
rut,
Codigo_Sucursal,
count(*) as Nro_TRXs_TMP,
sum(Monto) as Mto_TRXs_TMP,
sum(case when Medio_Pago='TAR' then 1 else 0 end) as Nro_TRXs_TAR,
sum(case when Medio_Pago='TAR' then Monto else 0 end) as Mto_TRXs_TAR 
from (
SELECT 
floor(DDMTD_FCH_DIA/100) as Periodo, 
DDMCT_RUT_CLI AS RUT, 
cast(DDMSU_COD_SUC as int)-10000 as Codigo_Sucursal, /*10039 o 39 = internet*/
CASE WHEN DDMFP_COD_FOR_PAG=3 THEN 'TAR' ELSE 'OMP' END AS Medio_Pago,
DCMCT_MNT_TRN as Monto 
FROM GEDCRE_CREDITO.DCRM_COS_MOV_TRN_VTA_BOL 
WHERE DDMSU_COD_NEG=1 
AND DCMCT_COD_PRD=1
AND floor(DDMTD_FCH_DIA/100) BETWEEN &anomes_i AND &anomes_f
AND DCMCT_COD_TIP_TRN IN (1) /*1 compras, 3 notas de credito*/
AND DCMCT_COD_TRN NOT IN(39,401,402,89,90,93) 
AND DDMSU_COD_SUC NOT IN (10993,10990)
) as conexion
group by 
PERIODO,
rut,
Codigo_Sucursal
) as X 
group by 
rut,
Codigo_Sucursal

;QUIT;


%put----------------------------------------------------------------------------------------------;
%put [01.3] Calcular Indicador ponderando cada concepto normalizado;
%put----------------------------------------------------------------------------------------------;



PROC SQL;

CREATE TABLE work.Venta_Tienda AS
SELECT 
*, 
round(
0.5*SB_Valor_Interpolado(Nro_TRXs_TMP,1,0,2*&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(Frec_TMP,1,0,&Ventana_Tiempo,0,1)+
0.1*SB_Valor_Interpolado(Mto_TRXs_TMP,1,0,20000*&Ventana_Tiempo,0,1)+
0.1*SB_Valor_Interpolado(Rec_TMP,1,&Ventana_Tiempo,0,0,1) 
,.001) as Indicador_TMP,
round(
0.5*SB_Valor_Interpolado(Nro_TRXs_TAR,1,0,2*&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(Frec_TAR,1,0,&Ventana_Tiempo,0,1)+
0.1*SB_Valor_Interpolado(Mto_TRXs_TAR,1,0,20000*&Ventana_Tiempo,0,1)+
0.1*SB_Valor_Interpolado(Rec_TAR,1,&Ventana_Tiempo,0,0,1) 
,.001) as Indicador_TAR 
from work.Venta_Tienda

;quit;


%put==============================================================================================;
%put [02] Calcular Codigo de Sucursal Preferente segun distintos criterios;
%put==============================================================================================;


%put----------------------------------------------------------------------------------------------;
%put [02.1] Sucursal Preferente Total TMP (todo medio de pago);
%put----------------------------------------------------------------------------------------------;


/*Marcar Tabla*/

PROC SQL;

CREATE TABLE work.Venta_Tienda_TotalTMP AS
SELECT 
a.*, 
case when b.rut is not null then 1 else 0 end as Suc_Pref 
from work.Venta_Tienda as a 
left join (
select 
rut,
max(Indicador_TMP*10000+Codigo_Sucursal) as Ind 
from work.Venta_Tienda 
group by 
rut 
) as b 
on (a.rut=b.rut and a.Indicador_TMP*10000+a.Codigo_Sucursal=b.Ind)
order by 
rut,
Codigo_Sucursal 

;quit;


/*Guardar Rutero con Sucursal Preferente*/

PROC SQL;
CREATE TABLE work.Venta_Tienda_TotalTMP2 AS
SELECT 
rut,
max(Codigo_Sucursal) as Codigo_Sucursal 
from work.Venta_Tienda_TotalTMP 
where Suc_Pref=1
group by 
rut 
;quit;


/*Eliminar Tabla de Paso*/


PROC SQL;

drop TABLE work.Venta_Tienda_TotalTMP

;quit;



%put----------------------------------------------------------------------------------------------;
%put [02.2] Sucursal Preferente Presencial TMP (todo medio de pago);
%put----------------------------------------------------------------------------------------------;



/*Marcar Tabla*/

PROC SQL;

CREATE TABLE work.Venta_Tienda_PresencialTMP AS
SELECT 
a.*, 
case when b.rut is not null then 1 else 0 end as Suc_Pref 
from work.Venta_Tienda as a 
left join (
select 
rut,
max(Indicador_TMP*10000+Codigo_Sucursal) as Ind 
from work.Venta_Tienda 
where Codigo_Sucursal<>39
group by 
rut 
) as b 
on (a.rut=b.rut and a.Indicador_TMP*10000+a.Codigo_Sucursal=b.Ind)
where a.Codigo_Sucursal<>39
order by 
rut,
Codigo_Sucursal 

;quit;


/*Guardar Rutero con Sucursal Preferente*/

PROC SQL;

CREATE TABLE work.Venta_Tienda_PresencialTMP2 AS
SELECT 
rut,
max(Codigo_Sucursal) as Codigo_Sucursal 
from work.Venta_Tienda_PresencialTMP 
where Suc_Pref=1
group by 
rut 

;quit;


/*Eliminar Tabla de Paso*/


PROC SQL;

drop TABLE work.Venta_Tienda_PresencialTMP

;quit;



%put----------------------------------------------------------------------------------------------;
%put [02.3] Sucursal Preferente Total TAR (Tarjeta);
%put----------------------------------------------------------------------------------------------;



PROC SQL;

CREATE TABLE work.Venta_Tienda_TotalTAR AS
SELECT 
a.*, 
case when b.rut is not null then 1 else 0 end as Suc_Pref 
from work.Venta_Tienda as a 
left join (
select 
rut,
max(Indicador_TAR*10000+Codigo_Sucursal) as Ind 
from work.Venta_Tienda 
group by 
rut 
) as b 
on (a.rut=b.rut and a.Indicador_TAR*10000+a.Codigo_Sucursal=b.Ind)
order by 
rut,
Codigo_Sucursal 

;quit;


/*Guardar Rutero con Sucursal Preferente*/

PROC SQL;

CREATE TABLE work.Venta_Tienda_TotalTAR2 AS
SELECT 
rut,
max(Codigo_Sucursal) as Codigo_Sucursal 
from work.Venta_Tienda_TotalTAR 
where Suc_Pref=1
group by 
rut 

;quit;


/*Eliminar Tabla de Paso*/


PROC SQL;

drop TABLE work.Venta_Tienda_TotalTAR

;quit;


%put----------------------------------------------------------------------------------------------;
%put [02.4] Sucursal Preferente Presencial TAR (Tarjeta);
%put----------------------------------------------------------------------------------------------;


/*Marcar Tabla*/

PROC SQL;

CREATE TABLE work.Venta_Tienda_PresencialTAR AS
SELECT 
a.*, 
case when b.rut is not null then 1 else 0 end as Suc_Pref 
from work.Venta_Tienda as a 
left join (
select 
rut,
max(Indicador_TAR*10000+Codigo_Sucursal) as Ind 
from work.Venta_Tienda 
where Codigo_Sucursal<>39
group by 
rut 
) as b 
on (a.rut=b.rut and a.Indicador_TAR*10000+a.Codigo_Sucursal=b.Ind)
where a.Codigo_Sucursal<>39
order by 
rut,
Codigo_Sucursal 

;quit;


/*Guardar Rutero con Sucursal Preferente*/

PROC SQL;

CREATE TABLE work.Venta_Tienda_PresencialTAR2 AS
SELECT 
rut,
max(Codigo_Sucursal) as Codigo_Sucursal 
from work.Venta_Tienda_PresencialTAR 
where Suc_Pref=1
group by 
rut 

;quit;


/*Eliminar Tabla de Paso*/


PROC SQL;

drop TABLE work.Venta_Tienda_PresencialTAR

;quit;



%put==============================================================================================;
%put [03] Unificar resultados en una sola base;
%put==============================================================================================;

/*Crear Tabla*/

proc sql;

Create table work.Sucursal_Pref as 
select 
a.rut,
b.Codigo_Sucursal as CodSuc_TotalTMP,
c.Codigo_Sucursal as CodSuc_PresencialTMP,
d.Codigo_Sucursal as CodSuc_TotalTAR,
e.Codigo_Sucursal as CodSuc_PresencialTAR 
from (
select distinct rut 
from work.Venta_Tienda
) as a 
left join work.Venta_Tienda_TotalTMP2 as b 
on (a.rut=b.rut) 
left join work.Venta_Tienda_PresencialTMP2 as c 
on (a.rut=c.rut) 
left join work.Venta_Tienda_TotalTAR2 as d 
on (a.rut=d.rut) 
left join work.Venta_Tienda_PresencialTAR2 as e 
on (a.rut=e.rut) 

;quit;


/*Borrar Tablas de paso*/

PROC SQL;

drop TABLE work.Venta_Tienda

;quit;

PROC SQL;

drop TABLE work.Venta_Tienda_TotalTMP2

;quit;

PROC SQL;

drop TABLE work.Venta_Tienda_PresencialTMP2

;quit;

PROC SQL;

drop TABLE work.Venta_Tienda_TotalTAR2

;quit;

PROC SQL;

drop TABLE work.Venta_Tienda_PresencialTAR2

;quit;


%put==============================================================================================;
%put [04] Pegar Nombre de Sucursal de cada Tipo (Comuna y Zona);
%put==============================================================================================;

proc sql;

Create table work.Sucursal_Preferente as 
select 
a.*,

b.Nombre_Tienda as NomSuc_TotalTMP,
b.COMUNA as ComunaSuc_TotalTMP,
b.Zona_Retail as ZonaSuc_TotalTMP,

c.Nombre_Tienda as NomSuc_PresencialTMP,
c.COMUNA as ComunaSuc_PresencialTMP,
c.Zona_Retail as ZonaSuc_PresencialTMP,

d.Nombre_Tienda as NomSuc_TotalTAR,
d.COMUNA as ComunaSuc_TotalTAR,
d.Zona_Retail as ZonaSuc_TotalTAR,

e.Nombre_Tienda as NomSuc_PresencialTAR,
e.COMUNA as ComunaSuc_PresencialTAR,
e.Zona_Retail as ZonaSuc_PresencialTAR 

from work.Sucursal_Pref as a 
left join RESULT.MAESTRA_SUCURSALES as b /*tabla de Ale de sucursales (facilitada por fabiola)*/
on (a.CodSuc_TotalTMP=b.Cod_Suc)
left join RESULT.MAESTRA_SUCURSALES as c 
on (a.CodSuc_PresencialTMP=c.Cod_Suc)
left join RESULT.MAESTRA_SUCURSALES as d 
on (a.CodSuc_TotalTAR=d.Cod_Suc)
left join RESULT.MAESTRA_SUCURSALES as e 
on (a.CodSuc_PresencialTAR=e.Cod_Suc)

;quit;


%put==============================================================================================;
%put [05] Vaciar Resultados en tabla entregable;
%put==============================================================================================;

/*Obtener Fecha del proceso*/

PROC SQL noprint outobs=1;   

select 
SB_Ahora('DD/MM/AAAA_HH:MM') as Fecha_Proceso,
input(SB_Ahora('AAAAMMDD'),best.) as Fecha2_Proceso
into :Fecha_Proceso,:Fecha2_Proceso
from sbarrera.SB_Status_Tablas_IN

;QUIT;
%let Fecha_Proceso="&Fecha_Proceso";


/*Guardar Entregable*/


DATA _NULL_;
Call execute(
cat('
proc sql; 

create table ',&Base_Entregable,'_',&anomes,' as 
SELECT 
''',&Fecha_Proceso,''' as Fecha_Proceso, 
* 
from work.Sucursal_Preferente 

;quit;
')
);
run;


/*Borrar Tablas de paso*/

PROC SQL;

drop TABLE work.Sucursal_Preferente

;quit;

