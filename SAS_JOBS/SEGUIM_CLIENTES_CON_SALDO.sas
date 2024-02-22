/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	SEGUIM_CLIENTES_CON_SALDO	================================*/
/* CONTROL DE VERSIONES
/* 2022-11-07 -- V06 -- Esteban P.
					 -- Se añade nueva sentencia include para exportar a RAW.
/* 2022-08-25 -- V05-- Sergio J.
					 -- Se añade sentencia include para borrar y exportar a RAW
/* 2022-07-11 -- V04 -- Sergio J. --  
					 -- Se agrega código de exportación para alimentar a Tableau
/* 2022-02-18 -- V03 -- David V. --  
					 -- Según indicación de Benja, se agrega _new en línea 212
/* 2022-01-02 -- V02 -- David V. --  
					 -- Versión para server SAS
/* 2022-01-04 -- V01 -- Benjamín Soto --  
					 -- Versión Original
/* INFORMACIÓN:
	Seguimiento de clientes con saldo, de forma diaria.

------------------------------
 DURACIÓN TOTAL:   0:33:50.50
------------------------------
*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

%let libreria=PUBLICIN;

DATA _null_;
periodo = input(put(intnx('month',intnx('day',today(),-2,'end'),0,'end'),yymmn6. ),$10.);
periodo2 = input(put(intnx('month',intnx('day',today(),-2,'end'),-1,'end'),yymmn6. ),$10.);
DIA = put(intnx('day',today(),-2,'begin'),yymmdd10.);
DIA2 = put(intnx('day',today(),-2,'begin'),ddmmyy10.);




Call symput("periodo", periodo);
Call symput("periodo2", periodo2);
Call symput("DIA", DIA);
Call symput("DIA2", DIA2);
RUN;



%put &periodo;
%put &periodo2;
%put &DIA;
%put &DIA2;


PROC SQL noprint;   

select max(anomes) as Max_anomes_SegR
into :Max_anomes_SegR
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'NLAGOSG.SEGMENTO_COMERCIAL_%' 
and length(Nombre_Tabla)=length('NLAGOSG.SEGMENTO_COMERCIAL_AAAAMM')
) as x

;QUIT;

PROC SQL noprint;   

select max(anomes) as Max_anomes_SegG
into :Max_anomes_SegG
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-9,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'NLAGOSG.SEGM_GEST_TODAS_PART_%' 
and length(Nombre_Tabla)=length('NLAGOSG.SEGM_GEST_TODAS_PART_AAAAMM_NEW')
) as x

;QUIT;
%let Max_anomes_SegG=&Max_anomes_SegG;
%let Max_anomes_SegR=&Max_anomes_SegR;
%put &Max_anomes_SegG;
%put &Max_anomes_SegR;


PROC SQL NOERRORSTOP ;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table cuentas as
select *
from connection to ORACLE(
select
a.codent,
a.centalta,
a.cuenta,
a.CODESTCTA,
a.FECPROCES,
a.TIPIMP1+
a.TIPIMP2+
a.TIPIMP3+
a.TIPIMP4+
a.TIPIMP5+
a.TIPIMP6+
a.TIPIMP7+
a.TIPIMP8+
a.TIPIMP9+
a.TIPIMP10 as TIPIMP
from GETRONICS.MPDT166 a
where a.TIPIMP1+
a.TIPIMP2+
a.TIPIMP3+
a.TIPIMP4+
a.TIPIMP5+
a.TIPIMP6+
a.TIPIMP7+
a.TIPIMP8+
a.TIPIMP9+
a.TIPIMP10 >0
and a.FECPROCES = %str(%')&DIA.%str(%')
) A
;QUIT;






PROC SQL NOERRORSTOP ;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table mora as
select *
from connection to ORACLE(
select
b.evaam_nro_ctt,
EVAAM_DIA_MOR
from SFRIES_ALT_MOR b
where b.EVAAM_FCH_PRO =
to_date(%str(%')&DIA2.%str(%'),'dd/mm/yyyy')
) A
;QUIT;





proc sql;
create table final as
select a.*,b.* from cuentas a
left join mora b on (a.codent||a.centalta||a.cuenta=b.evaam_nro_ctt)
;quit;






PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table cuentas as
select *
from connection to ORACLE(
select A.IDENTCLI,
cast(B.PEMID_GLS_NRO_DCT_IDE_K as INT) RUT,
A.CODENT,
A.CENTALTA,
A.CUENTA,
a.FECALTA FECALTA_CTTO,
a.FECBAJA FECBAJA_CTTO,
a.PRODUCTO,
a.SUBPRODU,
a.CONPROD,
a.GRUPOLIQ,
a.INDBLQOPE,
case when a.GRUPOLIQ=1 then 5
when a.GRUPOLIQ=2 then 10
when a.GRUPOLIQ=3 then 15
when a.GRUPOLIQ=4 then 20
when a.GRUPOLIQ=5 then 25
when a.GRUPOLIQ=6 then 30
when a.GRUPOLIQ=7 then 18 end as corte



from MPDT007 a
INNER JOIN BOPERS_MAE_IDE B
ON A.IDENTCLI=B.PEMID_NRO_INN_IDE
where a.PRODUCTO not in ('08','13')
) A
;QUIT;





proc sql;
create table final_agg as
select b.*,a.rut from final b
left join cuentas a on (a.codent||a.centalta||a.cuenta=b.evaam_nro_ctt)
;quit;





proc sql;
create table final_agg2 as
select a.*,segmento_final as segmento_Comercial,c.segmento as segmento_Gestion from final_agg a
left join nlagosg.Segmento_comercial_&Max_anomes_SegR. b on a.rut=b.rut
left join nlagosg.SEGM_GEST_TODAS_PART_&Max_anomes_SegR._new c on a.rut=c.rut
;quit;





proc sql;
create table final_agg2 as
select a.*,
case when EVAAM_DIA_MOR=0 then '1.- MORA 0'
when EVAAM_DIA_MOR between 1 and 30 then '2.- MORA 1-30'
when EVAAM_DIA_MOR between 31 and 60 then '3.- MORA 31-60'
when EVAAM_DIA_MOR between 61 and 90 then '4.- MORA 61-90'
when EVAAM_DIA_MOR between 91 and 120 then '5.- MORA 91-120'
when EVAAM_DIA_MOR between 121 and 150 then '6.- MORA 121-150'
when EVAAM_DIA_MOR between 151 and 180 then '7.- MORA 151-180'
when EVAAM_DIA_MOR>180 then '8.- MORA>181d' end as MORA_TRAMO
from final_agg2 a
;quit;

proc sql outobs=1 noprint;
select 
day(today()-2)  
 as Periodo_dia 
into :Periodo_dia 
from sashelp.vmember
;quit;

%let periodo_dia=&periodo_dia;
%put &Periodo_dia;



PROC SQL NOPRINT;
insert into &libreria..seguimiento_clientes_saldo 
SELECT
&periodo. as periodo,
&periodo_dia. as dia,
t1.segmento_gestion ,
t1.segmento_comercial,
t1.MORA_TRAMO,
/* SUM_of_TIPIMP */
(SUM(t1.TIPIMP)) AS SUM_of_TIPIMP,
/* COUNT_DISTINCT_of_RUT */
(COUNT(DISTINCT(t1.RUT))) AS COUNT_DISTINCT_of_RUT,
/* COUNT_DISTINCT_of_EVAAM_NRO_CTT */
(COUNT(DISTINCT(t1.EVAAM_NRO_CTT))) AS COUNT_DISTINCT_of_EVAAM_NRO_CTT
FROM WORK.FINAL_AGG2 t1
GROUP BY t1.segmento_gestion,
segmento_comercial,
t1.MORA_TRAMO;
QUIT;

%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(clts_seguimiento_saldo,raw,oracloud,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(clts_seguimiento_saldo,publicin.seguimiento_clientes_saldo,raw,oracloud,0);

/*proc sql;*/
/*	drop table cuentas;*/
/*	drop table final;*/
/*	drop table final_agg;*/
/*	drop table final_agg2;*/
/*	drop table mora;*/
/*quit;*/

/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;
