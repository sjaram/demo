/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	Clientes_uso_corte				 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-10-28 -- v10 -- Karina M.	-- Actualización en parte de la lógica.
/* 2022-10-28 -- v09 -- David V.	-- Se actualizar export a AWS, según nuevas definiciones a RAW.
/* 2022-09-07 -- V08 -- David V. 	-- Se agrega variable librería, eliminada por accidente en actualización anterior.
/* 2022-08-25 -- V07 -- Sergio J. 	-- Se añade sentencia include para borrar y exportar a RAW
/* 2022-07-12 -- V06 -- Sergio J.   -- Se agrega código de exportación para alimentar a Tableau
/* 2022-07-07 -- V05 -- David V.	-- Actualización mínima, comentarios y destinatarios de correo.
/* 2022-07-07 -- V04 -- Karina M.	-- Actualización.
/* 2022-06-30 -- V03 -- David V. 	-- Versión de Karina + comentarios para versionado y correo de notificación.

/* INFORMACIÓN:
	Programa que...

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
%let n=0;
%let libreria=result;

%macro cortes(n,libreria);


DATA _null_;
periodo = input(put(intnx('month',today(),-&n.,'end'),yymmn6. ),$10.);
Call symput("periodo", periodo);
RUN;


/*ciclos */
/*5,10,15,18,20,25,30,cierre mes */


proc sql;
create table vista
(ind num,
corte num)
;QUIT;


proc sql;
insert into vista
values(1,5)
values(2,10)
values(3,15)
values(4,18)
values(5,20)
values(6,25)
values(7,30)
values(8,31)
;QUIT;


proc sql;
create table llenado
(periodo num,
corte char(10),
COMBINATORIA char(20),
TOTAL num
)
;QUIT;


%if (%sysfunc(exist(&libreria..cliente_unico_USO_CORTE))) %then %do;

%end;
%else %do;


PROC SQL;
CREATE TABLE &libreria..cliente_unico_USO_CORTE (
periodo num,
corte char(10),
COMBINATORIA char(20),
TOTAL num)
;RUN;
%end;



%do i=1 %to 8;


proc sql noprint;
select corte
into:corte
from vista
where ind=&i.
;QUIT;


%let corte=&corte;
%put &corte;


proc sql;
create table clientes as
select
rut,
tipo
from (
select rut,

sum(capital)+sum(pie) as monto,
'TDA' as tipo
from publicin.tda_itf_&periodo.
where
day(fecha)<=&corte.
group by rut
having calculated monto>0

outer union corr
select
rut,
monto,
tipo
from (
select 
rut,
sum(venta_tarjeta) as monto,
'SPOS' as tipo
from publicin.spos_AUT_&periodo.
where
fecha-floor(fecha/100)*100<=&corte.
group by rut
having calculated monto>0)

outer union corr
select
rut,
sum(capital) as monto,
'PPFF' as tipo
from publicin.TRX_AV_&periodo.
where
input(compress(fecfac,'-'),best.)-floor(input(compress(fecfac,'-'),best.)/100)*100<=&corte.

outer union corr
select
rut,
sum(capital) as monto,
'PPFF' as tipo
from publicin.TRX_SAV_&periodo.
where
input(compress(fecfac,'-'),best.)-floor(input(compress(fecfac,'-'),best.)/100)*100<=&corte.

outer union corr
select
rut,
sum(MONTO_RECAUDADO) as monto,
'SEGUROS' as tipo
from publicin.TRX_SEGUROS_&periodo.
where
input(compress(FECPROCES,'-'),best.)-floor(input(compress(FECPROCES,'-'),best.)/100)*100<=&corte.
and TIPO_SEGURO='SEGUROS OPEN MARKET' and CODCONREC not in ('S201','S083','S170')

)
group by rut

;QUIT;


proc sql;
create table clientes1 as
select
rut,
max(case when tipo='TDA' then 1 else 0 end ) as TDA,
max(case when tipo='SPOS' then 1 else 0 end ) as SPOS,
max(case when tipo='PPFF' then 1 else 0 end) as PPFF,
max(case when tipo='SEGUROS' then 1 else 0 end) as SEGUROS
from clientes
group by rut
;QUIT;


proc sql;
create table clientes2 as
select *,
cat(
case when max(case when TDA=1 then 1 else 0 end )=1 then 'TDA' else '' end,' ',
case when max(case when SPOS=1 then 1 else 0 end )=1 then 'SPOS' else '' end,' ',
case when max(case when PPFF=1 then 1 else 0 end )=1 then 'PPFF' else '' end,' ',
case when max(case when SEGUROS=1 then 1 else 0 end )=1 then 'SEG' else '' end

) as COMBINATORIA

from clientes1
group by rut

;quit;



proc sql;
create table colapso as
select
&periodo. as periodo,
case when &corte.=5 then 'A.05'
when &corte.=10 then 'B.10'
when &corte.=15 then 'C.15'
when &corte.=18 then 'D.18'
when &corte.=20 then 'E.20'
when &corte.=25 then 'F.25'
when &corte.=30 then 'G.30'
when &corte.=31 then 'H.CIERRE' end as corte,
COMBINATORIA,
count(rut) as TOTAL
from clientes2
group by
combinatoria
;QUIT;


proc sql;
insert into llenado
select *
from colapso
;QUIT;


%end;


proc sql;
delete *
from &libreria..cliente_unico_USO_CORTE
where periodo=&periodo.
and combinatoria not is missing 
;QUIT;


proc sql;
insert into &libreria..cliente_unico_USO_CORTE
select *
from llenado
;QUIT;




%mend cortes;




%cortes(0,&libreria.);
%cortes(1,&libreria.);

proc sql;
create table  cliente_unico_USO_CORTE as 
select case when periodo-floor(periodo/100)*100 between 1 and 9 then 
cat(floor(periodo/100),'-',
cat('0',periodo-floor(periodo/100)*100),'-',
'01')
else 
cat(floor(periodo/100),'-',
periodo-floor(periodo/100)*100,'-',
'01') end  as periodo2, * from result.cliente_unico_USO_CORTE;
quit;


%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(clts_cliente_unico_uso_corte,raw,oracloud,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(clts_cliente_unico_uso_corte,work.cliente_unico_uso_corte,raw,oracloud,0);

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*  VARIABLE TIEMPO - FIN   */
data _null_;
    dur = datetime() - &tiempo_inicio;
    put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;
/*==================================    FECHA DEL PROCESO           ================================*/
data _null_;
    execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
    Call symput("fechaeDVN", execDVN);
RUN;
%put &fechaeDVN;
/*==================================    EMAIL CON CASILLA VARIABLE  ================================*/
proc sql noprint;
    SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_CLIENTES';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CLIENTES_2';
quit;
%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;

data _null_;
    FILENAME OUTBOX EMAIL
        FROM = ("&EDP_BI")
        TO = ("&DEST_4", "&DEST_5")
		CC = ("&DEST_1", "&DEST_2", "&DEST_3")
        SUBJECT = ("MAIL_AUTOM: Proceso Clientes_uso_corte");
    FILE OUTBOX;
    PUT "Estimados:";
    put "   Proceso Clientes_uso_corte, ejecutado con fecha: &fechaeDVN";
    PUT;
    PUT "   Disponible en SAS y Oracloud:  &libreria..cliente_unico_USO_CORTE";
    PUT;
    PUT;
    put 'Proceso Vers. 10';
    PUT;
    PUT;
    PUT 'Atte.';
    Put 'Equipo Arquitectura de Datos y Automatización BI';
    PUT;
RUN;
FILENAME OUTBOX CLEAR;
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
