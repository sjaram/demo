/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	DETALLE_COMPRA				================================*/
/* CONTROL DE VERSIONES
/* 2022-08-25 -- V03 -- Sergio J. 
					 -- Se añade sentencia include para borrar y exportar a RAW

/* 2022-07-12 -- V02 -- Sergio J. 
					 -- Se agrega código de exportación para alimentar a Tableau

/* 2021-11-04 -- V01 -- Pedro M. -- 
			      	 -- Versión Original
/* INFORMACIÓN:
		Genera un dashboard de clientes unicos de los últimos 12 meses de campañas de SPOS, 
	aperturado por lógica comercial.
*/

/*seguimiento venta tam/TR*/

/*TABLAS DE USO*/
/*publicin.tda_itf_AAAAMM*/
/* result.capta_salida */
/*publicin.SPOS_AUT_AAAAMM*/
/*PUBLICIN.TOTAL_EVOLUTIVO_AAAAMM*/
/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());


%let libreria=RESULT;/*modificar donde se guardara*/

%macro venta(n,LIB);

DATA _NULL_;
per = put(intnx('month',today(),-&n.,'end'), yymmn6.);
call symput("periodo",per);
run;
%put &periodo;

%put==================================================================================================;
%put [01] Verificar si existe base madre , caso contrario crearla &periodo. ;
%put==================================================================================================;

%if (%sysfunc(exist(&LIB..RESUMEN_VENTA_TARJ))) %then %do;
%end;
%else %do;
proc sql;
create table &LIB..RESUMEN_VENTA_TARJ (
periodo date,
periodo_num num,
 VISTA char(99),
 ORIGEN char(99),
TIPO char(99),
 monto num,
CLIENTES num,
 boletas num,
 mgfin num,
 cuotas num
)
;QUIT;
%end;

%put==================================================================================================;
%put [02] Borrar &periodo. para evitar duplicados;
%put==================================================================================================;

proc sql;
delete *
from &LIB..RESUMEN_VENTA_TARJ
where 
periodo= mdy(mod(int((&periodo.*100+01)/100),100),mod((&periodo.*100+01),100),int((&periodo.*100+01)/10000))
;QUIT;

%put==================================================================================================;
%put [03] TDA ITF &periodo. ;
%put==================================================================================================;

proc sql;
create table conteo_TDA as 
select 
'ITF/SPOS_AUT' AS VISTA,
'TDA' as ORIGEN,
 CASE WHEN SUBSTR(PAN,1,6) IN('628156') THEN 'TR'
WHEN SUBSTR(PAN,1,6) IN ('549070') then 'TAM' else 'TR' end as TIPO,
sum(CAPITAl)+sum(pie) as monto,
count(distinct rut) as CLIENTES,
count(rut) as BOLETAS,
sum(MGFIN) as MGFIN,
avg(case when cuotas>0 then cuotas end ) as CUOTAS 
from publicin.tda_itf_&periodo.
group by calculated tipo
;QUIT;

%put==================================================================================================;
%put [04] SPOS AUT &periodo. ;
%put==================================================================================================;

proc sql;
create table conteo_SPOS as 
select 
'ITF/SPOS_AUT' AS VISTA,
'SPOS' as origen,
TIPO_TARJETA as  TIPO,
sum(venta_tarjeta) as monto,
count(distinct rut) as CLIENTES,
count(rut) as BOLETAS,
0 as mgfin,
avg(case when TOTCUOTAS>0 then TOTCUOTAS end ) as cuotas
from publicin.SPOS_AUT_&periodo.
group by tipo
;QUIT;

%put==================================================================================================;
%put [05] Captados &periodo. ;
%put==================================================================================================;

proc sql;
create table conteo_capta as 
select 
'ITF/SPOS_AUT' AS VISTA,
'CAPTACION' AS ORIGEN,
producto AS TIPO,
0 AS MONTO,
count(rut_cliente) as CLIENTES,
0 as BOLETAS,
0 as mgfin,
0 as cuotas
from result.capta_salida 
where 
year(fecha)*100+month(fecha)=&periodo.
and cod_prod<>4
group by 
producto
;QUIT;

%put==================================================================================================;
%put [06] total evolutivo &periodo. ;
%put==================================================================================================;

%if (%sysfunc(exist(PUBLICIN.TOTAL_EVOLUTIVO_&PERIODO.))) %then %do;

PROC SQL;
CREATE TABLE CONTEO_TOTAL_EVOL AS 
SELECT 
'TOTAL EVOLUTIVO' AS VISTA,
CASE WHEN BOL_TIENDA>0 AND BOL_SPOS>0 THEN 'TDA+SPOS(TDA)' end as ORIGEN,
'' AS TIPO,SUM(MONTO_TIENDA) AS MONTO,
count(case when BOL_TIENDA>0 then RUT end ) as CLIENTES,

SUM(BOL_TIENDA) AS BOL_TDA,
SUM(MGFIN_TIENDA) AS MGFIN
from PUBLICIN.TOTAL_EVOLUTIVO_&PERIODO.
group by 
CALCULATED ORIGEN
HAVING CALCULATED ORIGEN IS NOT NULL
union
SELECT 
'TOTAL EVOLUTIVO' AS VISTA,
CASE WHEN BOL_TIENDA>0 AND BOL_SPOS>0 THEN 'TDA+SPOS(SPOS)' end as ORIGEN,
'' AS TIPO,SUM(MONTO_spos) AS MONTO,
count(case when BOL_SPOS>0 then RUT end ) as CLIENTES,

SUM(BOL_spos) AS BOL_TDA,
SUM(MGFIN_spos) AS MGFIN
from PUBLICIN.TOTAL_EVOLUTIVO_&PERIODO.
group by 
CALCULATED ORIGEN
HAVING CALCULATED ORIGEN IS NOT NULL
union
SELECT 
'TOTAL EVOLUTIVO' AS VISTA,
CASE WHEN BOL_TIENDA>0 AND (BOL_SPOS=0 OR BOL_SPOS=.) THEN 'TDA' end as ORIGEN,
'' AS TIPO,SUM(MONTO_tienda) AS MONTO,
count(case when BOL_tienda>0 then RUT end ) as CLIENTES,

SUM(BOL_tienda) AS BOL_TDA,
SUM(MGFIN_tienda) AS MGFIN
from PUBLICIN.TOTAL_EVOLUTIVO_&PERIODO.
group by 
CALCULATED ORIGEN
HAVING CALCULATED ORIGEN IS NOT NULL
union
SELECT 
'TOTAL EVOLUTIVO' AS VISTA,
CASE WHEN (BOL_TIENDA=0 OR BOL_TIENDA=.) AND BOL_SPOS>0 THEN 'SPOS' end as ORIGEN,
'' AS TIPO,SUM(MONTO_spos) AS MONTO,
count(case when BOL_SPOS>0 then RUT end ) as CLIENTES,
SUM(BOL_spos) AS BOL_TDA,
SUM(MGFIN_spos) AS MGFIN
from PUBLICIN.TOTAL_EVOLUTIVO_&PERIODO.
group by 
CALCULATED ORIGEN
HAVING CALCULATED ORIGEN IS NOT NULL
;QUIT;

%end;
%else %do;
proc sql inobs=1;
create table CONTEO_TOTAL_EVOL as 
SELECT 
'TOTAL EVOLUTIVO' AS VISTA,
'SPOS'  as ORIGEN,
'' AS TIPO,
0 AS MONTO,
0 as CLIENTES,
0 AS BOL_TDA,
0 AS MGFIN
from pmunoz.codigos_capta_cdp
;QUIT;

%end;

%put==================================================================================================;
%put [07] resumen &periodo. ;
%put==================================================================================================;

PROC SQl;
CREATE TABLE RESUMEN AS 
SELECT *
FROM conteo_TDA 
UNION 
SELECT * 
FROM CONTEO_SPOS
UNION
SELECT 
*
FROM conteo_capta
UNION SELECT *,0 as cuotas
FROM CONTEO_TOTAL_EVOL
;quit;

%put==================================================================================================;
%put [08] Insertar en tabla madre &periodo. ;
%put==================================================================================================;

proc sql;
insert into &LIB..RESUMEN_VENTA_TARJ
select 
mdy(mod(int((&periodo.*100+01)/100),100),mod((&periodo.*100+01),100),int((&periodo.*100+01)/10000)) format=date9. AS PERIODO,
&periodo. as periodo_num,
*
from RESUMEN
;QUIT;

%put==================================================================================================;
%put [09] Borrado tablas de paso &periodo. ;
%put==================================================================================================;

proc sql;
drop table resumen;
drop table conteo_TDA;
drop table CONTEO_SPOS;
drop table conteo_capta;
drop table CONTEO_TOTAL_EVOL;
;QUIT;

%mend venta;


%macro ejecucion(periodo,LIB);

%venta(&periodo.,&LIB.);

LIBNAME ORACLOUD ORACLE sql_functions=all  READBUFF=1000  INSERTBUFF=1000  PATH="REPORTSAS.WORLD"  SCHEMA=SAS_ADM authdomain=DBOracleCloud_Auth;


%if (%sysfunc(exist(oracloud.pmunoz_RESUMEN_VENTA_TARJ ))) %then %do;
 
%end;
%else %do;
proc sql;
connect using oracloud;
create table  oracloud.pmunoz_RESUMEN_VENTA_TARJ (
periodo date,
periodo_num num,
 VISTA char(99),
 ORIGEN char(99),
TIPO char(99),
 monto num,
CLIENTES num,
 boletas num,
 mgfin num,
 cuotas num
);
disconnect from oracloud;run;
%end;

proc sql;
connect using oracloud;
execute by oracloud (  delete from pmunoz_RESUMEN_VENTA_TARJ where periodo_num=&periodo.
);
disconnect from oracloud;
;quit;


proc sql; 
connect using oracloud;
insert into   oracloud.pmunoz_RESUMEN_VENTA_TARJ (
periodo ,
periodo_num,
 VISTA ,
 ORIGEN ,
TIPO ,
 monto ,
CLIENTES ,
 boletas ,
 mgfin ,
 cuotas )

select 
DHMS(periodo,0,0,0) as periodo format=datetime20.  ,
periodo_num,
 VISTA ,
 ORIGEN ,
TIPO ,
 monto ,
CLIENTES ,
 boletas ,
 mgfin ,
 cuotas 
from &LIB..RESUMEN_VENTA_TARJ
where periodo_num=&periodo.
; 
disconnect from oracloud;run;
%mend ejecucion;


%ejecucion(0,&libreria.);
%ejecucion(1,&libreria.);

%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_DELETE.sas";
%borrarOracleRaw(TNDA_RESUMEN_VENTA_TARJ);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_EXPORT.sas";
%ExportacionOracleRaw(TNDA_RESUMEN_VENTA_TARJ,RESULT.RESUMEN_VENTA_TARJ);


/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 


/*	Fecha ejecución del proceso	*/
data _null_;
execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechaeDVN", execDVN) ;
RUN;


%put &fechaeDVN;/*fecha ejecucion proceso */


/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

SELECT EMAIL into :DEST_3
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';
	SELECT EMAIL into :DEST_4
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'LIVIA_HERNANDEZ';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4")
CC = ("&DEST_1", "&DEST_2","&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso Evolutivo Tda/Spos");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso  Evolutivo Tda/Spos, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put ; 
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 03'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;                           
