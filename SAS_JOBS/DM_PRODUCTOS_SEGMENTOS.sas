/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================    DM_PRODUCTOS_SEGMENTOS				 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-12-06 -- V01 -- Sergio J.	--  Versión original
/* 2023-02-14 -- v02 -- Benjamin S. --  Se agrego para reemplazar la tabla segmento_comercial de publicin
/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*============================== SEGMENTO COMERCIAL AWS ===============================*/

/*Importar data de segmento comercial AWS */
proc import datafile="/sasdata/users94/user_bi/IN_SEGMENTO_PLANES_AWS/SEGMENTO_COMERCIAL.csv"
out=result.segmento_comercial_planes
dbms = dlm
replace;
delimiter =';';
getnames = yes; 
run;

proc sql;
create index rut on result.segmento_comercial_planes(rut);
quit;

DATA _null_;
periodo = input(put(intnx('month',intnx('day',today(),-1,'end'),0,'end'),yymmn6. ),$10.);



Call symput("periodo", periodo);
RUN;


%put &periodo;


proc sql;
create table publicin.segmento_comercial as
select rut,segmento_final as segmento,case when segmento_final in ('R_GOLD','R_SILVER','R_PLUS') THEN 1 else 0 
end as COMUNICADO,&Periodo. as Periodo
from result.segmento_comercial_planes


;Quit;

/*============================== PRODUCTOS POR CLIENTE ===============================*/

/*Obtención de ruts unicos en base a productos vigentes*/
proc sql;
create table productos as 
select distinct rut
from RESULT.UNIV_TI_VIG_ANT
order by rut desc
;quit;

/*Clasificación de productos por cliente*/
proc sql;
create table result.productos_por_cliente as
select distinct 
	a.RUT,
case  
	when a.RUT in (select distinct RUT from RESULT.UNIV_TI_VIG_ANT where tipo_tarjeta="TAM") 
	then 1 else 0 end as SI_TAM,
case 
	when a.RUT in (select distinct RUT from RESULT.UNIV_TI_VIG_ANT where tipo_tarjeta="CC") 
	then 1 else 0 end as SI_CC,
case 
	when a.RUT in (select distinct RUT from RESULT.UNIV_TI_VIG_ANT where tipo_tarjeta="MASTERCARD CHEK") 
	then 1 else 0 end as SI_MC_CHEK,
case 
	when a.RUT in (select distinct RUT from RESULT.UNIV_TI_VIG_ANT where tipo_tarjeta="TD") 
	then 1 else 0 end as SI_TD,
case 
	when a.RUT in (select distinct RUT from RESULT.UNIV_TI_VIG_ANT where tipo_tarjeta="TR") 
	then 1 else 0 end as SI_TR
FROM productos a
;QUIT;

proc sql;
create index rut on result.productos_por_cliente(rut);
quit;

proc sql;
create table result.dm_productos_segmentos as 
select 
	a.*,
	b.*
from result.segmento_comercial_planes a
left join  result.productos_por_cliente b
on a.rut=b.rut;
quit;


/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;


data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1", "&DEST_2", "&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso DM_PRODUCTOS_SEGMENTOS");
FILE OUTBOX;
 	PUT "Estimados:";
 	put "		Proceso DM_PRODUCTOS_SEGMENTOS, ejecutado con fecha: &fechaeDVN";  
    PUT;
    PUT;
    PUT 'Proceso Vers. 01';
    PUT;
    PUT;
    PUT 'Atte.';
    PUT 'Equipo Arquitectura de Datos y Automatización BI';
    PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
