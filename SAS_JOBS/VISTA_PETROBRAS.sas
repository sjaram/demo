/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	VISTA_PETROBRAS				 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-07-07 -- V02 -- David V.	-- Actualización mínima, librería, comentarios, versionamiento y correo.
/* 2022-07-07 -- V01 -- Ignacio P.	-- Versión Original

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_CODCOM_CAMPS_SPOS AS 
   SELECT distinct t1.Periodo_Campana, 
          t1.Marca_Campana,
		  t1.codigo_comercio
      FROM RESULT.CODCOM_CAMPS_SPOS t1
	  where UPCASE(Marca_Campana) like "%PETROBRAS%"
union 
   SELECT distinct 201908 as Periodo_Campana, 
          t1.Marca_Campana,
		  t1.codigo_comercio
      FROM RESULT.CODCOM_CAMPS_SPOS t1
	  where UPCASE(Marca_Campana) like "%PETROBRAS%" and Periodo_Campana=201909

	  union 
   SELECT distinct 201907 as Periodo_Campana, 
          t1.Marca_Campana,
		  t1.codigo_comercio
      FROM RESULT.CODCOM_CAMPS_SPOS t1
	  where UPCASE(Marca_Campana) like "%PETROBRAS%" and Periodo_Campana=201909 
	  	  union 
   SELECT distinct 201906 as Periodo_Campana, 
          t1.Marca_Campana,
		  t1.codigo_comercio
      FROM RESULT.CODCOM_CAMPS_SPOS t1
	  where UPCASE(Marca_Campana) like "%PETROBRAS%" and Periodo_Campana=201909 
	  	  union 
   SELECT distinct 201905 as Periodo_Campana, 
          t1.Marca_Campana,
		  t1.codigo_comercio
      FROM RESULT.CODCOM_CAMPS_SPOS t1
	  where UPCASE(Marca_Campana) like "%PETROBRAS%" and Periodo_Campana=201909 
	  	  union 
   SELECT distinct 201904 as Periodo_Campana, 
          t1.Marca_Campana,
		  t1.codigo_comercio
      FROM RESULT.CODCOM_CAMPS_SPOS t1
	  where UPCASE(Marca_Campana) like "%PETROBRAS%" and Periodo_Campana=201909 
	  	  union 
   SELECT distinct 201903 as Periodo_Campana, 
          t1.Marca_Campana,
		  t1.codigo_comercio
      FROM RESULT.CODCOM_CAMPS_SPOS t1
	  where UPCASE(Marca_Campana) like "%PETROBRAS%" and Periodo_Campana=201909 
	  	  union 
   SELECT distinct 201902 as Periodo_Campana, 
          t1.Marca_Campana,
		  t1.codigo_comercio
      FROM RESULT.CODCOM_CAMPS_SPOS t1
	  where UPCASE(Marca_Campana) like "%PETROBRAS%" and Periodo_Campana=201909 
	  	  union 
   SELECT distinct 201901 as Periodo_Campana, 
          t1.Marca_Campana,
		  t1.codigo_comercio
      FROM RESULT.CODCOM_CAMPS_SPOS t1
	  where UPCASE(Marca_Campana) like "%PETROBRAS%" and Periodo_Campana=201909

;QUIT;



%let libreria=PUBLICIN;
%macro VISTA_PETROBRAS(n,libreria);
DATA _null_;
PERIODO    = input(put(intnx('month',today(),-&n.,'end'),yymmn6. ),$10.);
Call symput("PERIODO", PERIODO);
RUN;

%put &PERIODO;

proc sql;
create table work.CodCom_Camps_SPOS_Periodo as 
select 
Codigo_Comercio,
MAX(Marca_Campana) AS Marca_Campana
from QUERY_FOR_CODCOM_CAMPS_SPOS /*Base de Comercios que manda SPOS en excel (asegurarse de que este buena: sin blancos, sin duplicados, otros)*/
where Periodo_Campana=&periodo.
and coalesce(Codigo_Comercio,0)>0 
group by /*se agrupa para asegurar de que quede a nivel de codigo UNICO*/
Codigo_Comercio,Marca_Campana
;quit;



%if (%sysfunc(exist(nlagosg.SEGMENTO_COMERCIAL_&periodo ))) %then %do;

proc sql;
create table SEGMENTO_COMERCIAL as 
select
rut,
SEGMENTO_FINAL as SEGMENTO
from nlagosg.SEGMENTO_COMERCIAL_&periodo
;QUIT;

%end;
%else %do;

proc sql;
create table SEGMENTO_COMERCIAL (
rut num,
SEGMENTO char(99)
)
;QUIT;
%end;

/*SPOS_AUT*/


proc sql;
create table VENTA_PETROBRAS as 
select
a.periodo,  
a.rut,
a.Tipo_Tarjeta,
c.SEGMENTO,
"TOTAL" as MARCA_PETROBRAS,
sum(a.venta_tarjeta) as venta,
count(a.rut) as trx
from publicin.spos_aut_&periodo as a
LEFT JOIN work.CodCom_Camps_SPOS_Periodo as b on (a.codigo_comercio=b.codigo_comercio)
LEFT JOIN SEGMENTO_COMERCIAL as c on (a.rut=c.rut)
where a.codigo_comercio in (SELECT CODIGO_COMERCIO FROM CodCom_Camps_SPOS_Periodo) 
group by
a.periodo, 
a.rut,
a.Tipo_Tarjeta,
c.SEGMENTO,
MARCA_PETROBRAS
;QUIT;

proc sql;
create table AGRUP_VENTA_PETROBRAS as 
SELECT t1.Periodo, 
t1.Tipo_Tarjeta, 
t1.SEGMENTO,  
t1.MARCA_PETROBRAS, 
(COUNT(DISTINCT(t1.RUT))) AS clientes_unicos, 
sum(venta) as venta,
(SUM(t1.trx)) AS trx
FROM WORK.VENTA_PETROBRAS t1
GROUP BY 
t1.Periodo,
t1.Tipo_Tarjeta,
t1.SEGMENTO,
t1.MARCA_PETROBRAS
;QUIT;


/* VENTA MIERCOLES */
options cmplib=sbarrera.funcs;

proc sql;
create table VENTA_PETROBRAS_MIERCOLES as 
select
a.periodo,  
a.rut,
a.Tipo_Tarjeta,
c.SEGMENTO,
"MIERCOLES" as MARCA_PETROBRAS,
SB_Dia_Sem(fecha,'Glosa') as Dia_Glosa,
sum(a.venta_tarjeta) as venta,
count(a.rut) as trx
from publicin.spos_aut_&periodo as a
LEFT JOIN work.CodCom_Camps_SPOS_Periodo as b on (a.codigo_comercio=b.codigo_comercio)
LEFT JOIN SEGMENTO_COMERCIAL as c on (a.rut=c.rut)
where a.codigo_comercio in (SELECT CODIGO_COMERCIO FROM CodCom_Camps_SPOS_Periodo) and calculated Dia_Glosa in ("3. Miercoles")
group by
a.periodo, 
a.rut,
a.Tipo_Tarjeta,
c.SEGMENTO,
calculated Dia_Glosa
;QUIT;

proc sql;
create table AGRUP_VENTA_PETROBRAS_MIERC as 
SELECT t1.Periodo, 
t1.Tipo_Tarjeta, 
t1.SEGMENTO, 
t1.MARCA_PETROBRAS, 
(COUNT(DISTINCT(t1.RUT))) AS clientes_unicos, 
sum(venta) as venta,
(SUM(t1.trx)) AS trx
FROM WORK.VENTA_PETROBRAS_MIERCOLES t1
GROUP BY 
t1.Periodo,
t1.Tipo_Tarjeta,
t1.SEGMENTO,
t1.MARCA_PETROBRAS
;QUIT;


proc sql;
create table AGRUPADO as
select * 
from AGRUP_VENTA_PETROBRAS
OUTER UNION CORR

select * 
from AGRUP_VENTA_PETROBRAS_MIERC
;quit;


%if (%sysfunc(exist(&libreria..ANALISIS_PETROBRAS))) %then %do;
 
%end;
%else %do;
PROC  SQL;
CREATE TABLE &libreria..ANALISIS_PETROBRAS 
(
Periodo	num	,
Tipo_Tarjeta	char(99)	,
SEGMENTO	char(99)	,
MARCA_PETROBRAS	char(99)	,
clientes_unicos	num	,
venta	num	,
trx	num	
)
;quit;
%end;


proc sql;
delete *
from &libreria..ANALISIS_PETROBRAS 
where periodo=&periodo.
;QUIT;

proc sql;
insert into &libreria..ANALISIS_PETROBRAS
select *
from agrupado
;QUIT;


proc sql;
create table &libreria..ANALISIS_PETROBRAS  as 
select 
*
from &libreria..ANALISIS_PETROBRAS 
;QUIT;

%mend VISTA_PETROBRAS;
%VISTA_PETROBRAS(	0, &Libreria.	);
%VISTA_PETROBRAS(	1, &Libreria.	);


/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==============================    FECHA DEL PROCESO	============================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==============================	EMAIL CON CASILLA VARIABLE		================================*/
proc sql noprint;                              
SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_SPOS_1';
SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SUBG_BI';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;
%put &=DEST_6;	

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO 	 = ("&DEST_4", "&DEST_5","&DEST_6")
CC 	 = ("&DEST_1", "&DEST_2","&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso VISTA_PETROBRAS");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "        Proceso VISTA_PETROBRAS, ejecutado con fecha: &fechaeDVN";  
 PUT "        Información disponible en SAS: &libreria..ANALISIS_PETROBRAS";  
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 02'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
