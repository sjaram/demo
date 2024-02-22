
/*###################################################################################*/
/*Saldo de Ripley puntos por tramo*/
/*###################################################################################*/


%macro principal();
 
%LET NOMBRE_PROCESO = 'TRAMIFICADOR_SALDO_RP';

/******************************** Comenzar Proceso ***********************************/

/*Definir Parametros*/
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
%let Base_Entregable=%nrstr("RESULT.Saldos_RP_Disp");
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/

%put==========================================================================================;
%put [01] Identificar Periodo Actual;
%put==========================================================================================;


proc sql outobs=1 noprint;

select input(SB_Ahora('AAAAMM'),best.) as anomes_ahora 
into :anomes_ahora 
from sbarrera.SB_Status_Tablas_IN

;quit;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

%put==========================================================================================;
%put [02] Sacar base madre de clientes enrolados;
%put==========================================================================================;

/*conexion a PSFC1*/

LIBNAME PSFC1 ORACLE PATH='PSFC1' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD= 'amarinaoc2017';



PROC SQL;

CREATE TABLE work.rutero_enrolados AS 
SELECT DISTINCT 
INPUT(LEFT(CODCUENT),BEST.) AS RUT,
FECHALTA,
FECHBAJA
FROM PSFC1.T7542600 
WHERE FECHBAJA='' 
and INPUT(SUBSTR(LEFT(FECHALTA),1,6),BEST.) <= &anomes_ahora 

;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

%put==========================================================================================;
%put [03] Pegar info de puntos disponibles y tramificar;
%put==========================================================================================;


/*Sacar Base*/ 


PROC SQL;

CREATE TABLE work.PuntosDisp AS 
SELECT	INPUT(CODCUENT,BEST.) AS RUT, 
	  	CANTPUNT AS PUNTOS
FROM PSFC1.T7542700 T1 
WHERE T1.TIPOPUNT = '01';
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

/*Pegar data*/

PROC SQL;

CREATE TABLE work.rutero_enrolados AS 
SELECT 
a.*,
coalesce(b.PUNTOS,0) as Puntos_Disponibles,
SB_Tramificar(coalesce(b.PUNTOS,0),500,0,200000,'') as Tramo_Puntos_Disponibles 
FROM work.rutero_enrolados as a 
left join work.PuntosDisp as b 
on (a.rut=b.rut)

;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

/*Borrar tabla de paso*/

PROC SQL noprint;

drop TABLE work.PuntosDisp 

;QUIT;


/*Corregir indice de tramo por cantidad de 0s*/

PROC SQL;

CREATE TABLE work.rutero_enrolados AS 
SELECT 
*,
case 
when index(Tramo_Puntos_Disponibles,'.')<4 then '0'||Tramo_Puntos_Disponibles
else Tramo_Puntos_Disponibles
end as Tramo2_Puntos_Disponibles 
FROM work.rutero_enrolados 

;QUIT;


%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SQL noprint;   

select compress(put(max(anomes), best6.)) as Max_anomes_SegReal
into :Max_anomes_SegReal
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'PUBLICIN.SEGMENTOS_RPTOS_%' 
and length(Nombre_Tabla)=length('PUBLICIN.SEGMENTOS_RPTOS_201807')
) as x

;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

/*Pegar Segmento*/


proc sql; 

CREATE TABLE work.rutero_enrolados AS 
SELECT 
a.*, 
coalesce(b.SEGMENTO,'SIN INFO') as SEGMENTO_COMERCIAL, 
coalesce(c.SEGMENTO,'SIN INFO') as SEGMENTO_REAL 
FROM work.rutero_enrolados AS a 
left join PUBLICIN.SEGMENTO_COMERCIAL as b 
on (a.rut=b.rut) 
left join PUBLICIN.SEGMENTOS_RPTOS_&Max_anomes_SegReal. as c 
on (a.rut=c.rut) 

;quit; 

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

/*determinar maximos periodos de Sucursal Preferente*/

PROC SQL noprint;   

select compress(put(max(anomes), best6.))  as Max_anomes_SucPref
into :Max_anomes_SucPref
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'PUBLICIN.SUC_PREF_%' 
and length(Nombre_Tabla)=length('PUBLICIN.SUC_PREF_201807')
) as x

;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

/*Pegar Info*/



proc sql; 

CREATE TABLE work.rutero_enrolados AS 
SELECT 
a.*, 
b.SUC as Codigo_Sucursal_Preferente, 
b.Nombre_Tienda as Nombre_Sucursal_Preferente, 
b.Zona_Retail as Zona_Sucursal, 
b.comuna as Comuna_Sucursal 
FROM work.rutero_enrolados AS a 
left join ( 
select 
x.rut, 
x.SUC, 
z.Nombre_Tienda, 
z.Zona_Retail, 
z.comuna 
from PUBLICIN.SUC_PREF_&Max_anomes_SucPref. as x 
left join AMARINAO.SUCURSALES as z 
on (x.SUC=z.Cod_Suc) 
) as b 
on (a.rut=b.rut) 

;quit; 

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

%put==========================================================================================;
%put [06] Pegar info de actividad TR;
%put==========================================================================================;


/*determinar Actualizacion de Tabla*/

PROC SQL noprint;   

select compress(put(max(anomes), best6.))  as Max_anomes_ActTR
into :Max_anomes_ActTR
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'PUBLICIN.ACT_TR_%' 
and length(Nombre_Tabla)=length('PUBLICIN.ACT_TR_201804')
) as x

;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

/*Pegar Info*/



proc sql ; 

CREATE TABLE work.rutero_enrolados AS 
SELECT 
a.*, 
b.VU_RIESGO,
b.VU_IC,
b.ACTIVIDAD_TR,
case when b.MARCA_BASE in ('TAM','TAM_CHIP') then 'TAM' else 'TR' end as Tipo_Tarjeta 
FROM work.rutero_enrolados AS a 
left join PUBLICIN.ACT_TR_&Max_anomes_ActTR. as b 
on (a.rut=b.rut) 

;quit; 

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

%put==========================================================================================;
%put [07] Pegar info de Demo Basquet;
%put==========================================================================================;


/*determinar Actualizacion de Tabla*/

PROC SQL noprint;   

select compress(put(max(anomes), best6.))  as Max_anomes_DemoB
into :Max_anomes_DemoB
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'PUBLICIN.DEMO_BASKET_%' 
and length(Nombre_Tabla)=length('PUBLICIN.DEMO_BASKET_201808')
) as x

;QUIT;


%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

/*Pegar Info*/


proc sql; 

CREATE TABLE work.rutero_enrolados AS 
SELECT 
a.*, 
b.TIPO_ACTIVIDAD,
b.SEXO,
b.RANGO_EDAD 
FROM work.rutero_enrolados AS a 
left join PUBLICIN.DEMO_BASKET_&Max_anomes_DemoB. as b 
on (a.rut=b.rut) 

;quit; 

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL outobs=1 noprint;   

select SB_Ahora('DD/MM/AAAA_HH:MM') as Fecha_Proceso
into :Fecha_Proceso
from sbarrera.SB_Status_Tablas_IN

;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

/*Vaciar a entregable*/

proc sql; 
create table RESULT.Saldos_RP_Disp as 
select "&Fecha_Proceso." as Fecha_Proceso, 
		Tramo2_Puntos_Disponibles, 
		SEGMENTO_COMERCIAL, 
		Codigo_Sucursal_Preferente, 
		Nombre_Sucursal_Preferente, 
		Comuna_Sucursal, 
		Zona_Sucursal, 
		VU_RIESGO,
		VU_IC,
		ACTIVIDAD_TR,
		Tipo_Tarjeta, 
		TIPO_ACTIVIDAD,
		SEXO,
		RANGO_EDAD, 
		count(*) as recuento, 
		sum(Puntos_Disponibles) as SUM_Puntos_Disponibles 
		from work.rutero_enrolados 
	group by 
		Tramo2_Puntos_Disponibles, 
		SEGMENTO_COMERCIAL, 
		SEGMENTO_REAL,  
		Codigo_Sucursal_Preferente, 
		Nombre_Sucursal_Preferente, 
		Comuna_Sucursal, 
		Zona_Sucursal, 
		VU_RIESGO, 
		VU_IC, 
		ACTIVIDAD_TR, 
		Tipo_Tarjeta, 
		TIPO_ACTIVIDAD, 
		SEXO, 
		RANGO_EDAD  

;quit; 

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

/*Borrar tabla de paso*/

proc sql noprint;

drop table work.rutero_enrolados

;quit;

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
