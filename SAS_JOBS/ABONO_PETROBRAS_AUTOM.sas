/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	ABONO_PETROBRAS_AUTOM		================================*/
/* CONTROL DE VERSIONES
/* 2022-07-07 -- V03 -- David V.	--  Mejora menor en correo de notificación
/* 2022-07-07 -- V02 -- Benja S.	--  Actualización
/* 2022-01-24 -- V01 -- Pedro M. 	--  Versión Original
/* INFORMACIÓN:
	Cálculo de abono de clientes que compran en pretrobras.
	Todos los jueves, después del SPOS_AUT

------------------------------
 DURACIÓN TOTAL:   
------------------------------
*/
OPTIONS VALIDVARNAME=ANY;

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria=RESULT;
%let Bonificacion_normal=0.042; /*Periodo de los indicadores*/
%let Bonificacion_Silver=0.0205; /*Periodo de los indicadores*/
%let Bonificacion_Gold=0.041; /*Periodo de los indicadores*/
%let Limite_bonificacion=12000; /*Periodo de los indicadores*/


proc sql outobs=1 noprint;
select 
year(today()-1)*100+month(today()-1)   
 as Periodo 
into :Periodo
from sashelp.vmember
;quit;

proc sql outobs=1 noprint;
select 
year(today()-1)*10000+month(today()-1) *100+day(today()-1)  

 as Periodo_dia 
into :Periodo_dia 
from sashelp.vmember
;quit;
%let periodo=&periodo;
%put &Periodo;

%let periodo_dia=&periodo_dia;
%put &Periodo_dia;


proc sql;
create table venta_petro as 
select * from publicin.spos_aut_&periodo. t1 
where codigo_comercio in (select codigo_comercio from result.codcom_camps_spos  
where  upper(marca_campana) like '%PETROBRAS%' having periodo_campana=max(periodo_campana)  )
and fecha<=&Periodo_dia
;QUIT;


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

%let Max_anomes_SegR=&Max_anomes_SegR;
%put &Max_anomes_SegR;


proc sql ; 
create table  salida as 
select t1.Rut, 
segmento_final as segmento, 
pan, 
venta_tarjeta,
round(venta_tarjeta*&Bonificacion_normal.) as Bonificacion_normal , 
case when segmento_final ='R_SILVER' THEN round(venta_tarjeta*&Bonificacion_Silver.) else 0 end as Bonificacion_Silver ,
case when segmento_final ='R_GOLD' THEN round(venta_tarjeta*&Bonificacion_Gold.) else 0 end as Bonificacion_Gold , 
fecha  
from venta_petro t1 
left join nlagosg.segmento_comercial_&Max_anomes_SegR. t2
on t1.rut=t2.rut 
where weekday(mdy(mod(int(fecha/100),100),mod(fecha,100),int(fecha/10000))) = 4  

and fecha=&Periodo_dia
order by fecha desc
;quit;


%if (%sysfunc(exist(&libreria..TABLA_LLENADO_PETROBRAS_RPTOS))) %then %do;

%end;
%else %do;
PROC SQL;
CREATE TABLE &libreria..TABLA_LLENADO_PETROBRAS_RPTOS 
(periodo num,
fecha num,
rut num,
pan  char(99),
segmento char(99), 
venta_tarjeta num,
Bonificacion_normal num, 
 Bonificacion_Silver num ,
Bonificacion_Gold num
)
;QUIT;
%end;


proc sql;
insert into &libreria..TABLA_LLENADO_PETROBRAS_RPTOS 
select 
&periodo. as periodo ,
fecha,
rut,
pan  ,
segmento , 
venta_tarjeta ,
Bonificacion_normal , 
 Bonificacion_Silver  ,
Bonificacion_Gold 
 from salida
;QUIT;


/*seleccion de carga*/


proc sql;
create table bonificacion as 
 select 
 PAN ,max(rut) as rut,
sum (VENTA_TARJETA) as venta_tarjeta ,
sum(Bonificacion_normal    ) as Bonificacion_normal,
sum(Bonificacion_Silver    ) as Bonificacion_Silver,
sum(Bonificacion_Gold) as Bonificacion_Gold,
sum(Bonificacion_normal)+ sum(Bonificacion_Silver     )+ sum(Bonificacion_Gold) as bonificacion_total
from &libreria..TABLA_LLENADO_PETROBRAS_RPTOS 
where periodo=&periodo. 
and fecha<=&Periodo_dia
group by pan
;QUIT;

proc sql;
create table bonificacion_real as 
select 
 PAN ,max(rut) as rut,
sum (VENTA_TARJETA) as venta_tarjeta ,
sum(Bonificacion_normal    ) as Bonificacion_normal,
sum(Bonificacion_Silver    ) as Bonificacion_Silver,
sum(Bonificacion_Gold) as Bonificacion_Gold,
sum(Bonificacion_normal)+ sum(Bonificacion_Silver     )+ sum(Bonificacion_Gold) as bonificacion_total
from &libreria..TABLA_LLENADO_PETROBRAS_RPTOS 
where periodo=&periodo.
and fecha<&Periodo_dia
group by pan
;QUIT;

proc sql;
create table tablon_bonificacion as 
select 
a.*,

coalesce(b.venta_tarjeta,0) as venta_acum,

coalesce(b.Bonificacion_normal,0) as bonificacion_normal_acum,

coalesce(b.Bonificacion_Silver,0) as Bonificacion_Silver_acum ,

coalesce(b.Bonificacion_Gold,0) as Bonificacion_Gold_acum,

coalesce(b.bonificacion_total,0) as bonificacion_total_Acum,

a.venta_tarjeta-coalesce(b.venta_tarjeta,0) as diff_venta,

a.Bonificacion_normal-coalesce(b.Bonificacion_normal,0) as diff_bonificacion_normal,

a.Bonificacion_Silver-coalesce(b.Bonificacion_Silver,0) as diff_Bonificacion_Silver ,

a.Bonificacion_Gold-coalesce(b.Bonificacion_Gold,0) as diff_Bonificacion_Gold,

a.bonificacion_total-coalesce(b.bonificacion_total,0) as diff_bonificacion_total
from bonificacion as a 
left join bonificacion_real as b
on(a.pan=b.pan)
;QUIT;


proc sql;
create table marcas as
select 
*,
case when bonificacion_total>=&Limite_bonificacion. and 
bonificacion_total_Acum<&Limite_bonificacion. then '01.BONIFICAR,SOLO DIFERENCIAL POR LIMITE'

when bonificacion_total>=&Limite_bonificacion. and 
bonificacion_total_Acum>=&Limite_bonificacion. then '02.NO BONIFICAR'


when bonificacion_total<&Limite_bonificacion. and 
bonificacion_total_Acum<&Limite_bonificacion. and bonificacion_total>bonificacion_total_Acum
then '03.BONIFICAR,SOLO DIFERENCIA NUEVO'

when bonificacion_total<&Limite_bonificacion. and 
bonificacion_total_Acum<&Limite_bonificacion. and bonificacion_total=bonificacion_total_Acum
then '04.NO BONIFICAR,BONIFICADO ANTERIOR' end as TIPO_BONIFICAR
from tablon_bonificacion
;QUIT;



/*base para bonificaciones*/ 

proc sql;
create table base_bonificacion_nuevo as 
select 
diff_Bonificacion_Gold as 'Bonificación Final'n,
pan as Pan,
'Abono Gold Petrobras' as Glosa,
131 as 'Numero Factura'n
from marcas
where  TIPO_BONIFICAR='03.BONIFICAR,SOLO DIFERENCIA NUEVO'
and Bonificacion_Gold-Bonificacion_Gold_acum>0
union 
select 
diff_Bonificacion_silver as 'Bonificación Final'n,
pan as Pan,
'Abono Silver Petrobras' as Glosa,
132 as 'Numero Factura'n
from marcas
where  TIPO_BONIFICAR='03.BONIFICAR,SOLO DIFERENCIA NUEVO'
and Bonificacion_silver-Bonificacion_silver_acum>0
union 
select 
diff_Bonificacion_normal as 'Bonificación Final'n,
pan as Pan,
'Abono Petrobras' as Glosa,
133 as 'Numero Factura'n
from marcas
where  TIPO_BONIFICAR='03.BONIFICAR,SOLO DIFERENCIA NUEVO'
and Bonificacion_normal-Bonificacion_normal_acum>0
;QUIT;


/*caso del diff*/

proc sql;
create table diff2 as 
select 
*,
case when bonificacion_total_Acum<&Limite_bonificacion. 
and &Limite_bonificacion.-bonificacion_total_Acum <=diff_bonificacion_normal 
and diff_Bonificacion_Silver=0 and   diff_Bonificacion_Gold=0
then 'TODO NORMAL SIN SEGMENTO'

when bonificacion_total_Acum<&Limite_bonificacion. 
and &Limite_bonificacion.-bonificacion_total_Acum <=diff_bonificacion_normal 
and (diff_Bonificacion_Silver>0 or   diff_Bonificacion_Gold>0)
then 'TODO NORMAL CON SEGMENTO'

when 
bonificacion_total_Acum<&Limite_bonificacion. 
and &Limite_bonificacion.-bonificacion_total_Acum >=diff_bonificacion_normal and diff_Bonificacion_Gold>0
then 'NORMAL+GOLD'

when 
bonificacion_total_Acum<&Limite_bonificacion. 
and &Limite_bonificacion.-bonificacion_total_Acum >=diff_bonificacion_normal and diff_Bonificacion_Silver>0
then 'NORMAL+SILVER' end as TIPO_BONIFICACION2,

case when calculated TIPO_BONIFICACION2 ='TODO NORMAL SIN SEGMENTO' then &Limite_bonificacion.-bonificacion_total_Acum 
when calculated TIPO_BONIFICACION2 ='TODO NORMAL CON SEGMENTO' then &Limite_bonificacion.-bonificacion_total_Acum
when calculated TIPO_BONIFICACION2 ='NORMAL+GOLD' then diff_bonificacion_normal
  when calculated TIPO_BONIFICACION2 ='NORMAL+SILVER' then diff_bonificacion_normal end as diff_normal_fin,

   case when calculated TIPO_BONIFICACION2 ='TODO NORMAL SIN SEGMENTO' then 0 
when calculated TIPO_BONIFICACION2 ='TODO NORMAL CON SEGMENTO' then 0
when calculated TIPO_BONIFICACION2 ='NORMAL+GOLD' then &Limite_bonificacion.-bonificacion_total_Acum-diff_bonificacion_normal
  when calculated TIPO_BONIFICACION2 ='NORMAL+SILVER' then 0 end as diff_GOLD_fin,

   case when calculated TIPO_BONIFICACION2 ='TODO NORMAL SIN SEGMENTO' then 0 
when calculated TIPO_BONIFICACION2 ='TODO NORMAL CON SEGMENTO' then 0
when calculated TIPO_BONIFICACION2 ='NORMAL+GOLD' then 0
  when calculated TIPO_BONIFICACION2 ='NORMAL+SILVER' then &Limite_bonificacion.-bonificacion_total_Acum-diff_bonificacion_normal end 
as diff_SILVER_fin
from marcas
where TIPO_BONIFICAR='01.BONIFICAR,SOLO DIFERENCIAL POR LIMITE'
;QUIT;



proc sql;
create table base_bonificacion_DIFF as 
select 
diff_gold_fin as 'Bonificación Final'n,
pan as Pan,
'Abono Gold Petrobras' as Glosa,
131 as 'Numero Factura'n
from diff2
where  diff_gold_fin>0
union 
select 
diff_silver_fin as 'Bonificación Final'n,
pan as Pan,
'Abono Silver Petrobras' as Glosa,
132 as 'Numero Factura'n
from diff2
where  diff_silver_fin>0
union 
select 
diff_normal_fin as 'Bonificación Final'n,
pan as Pan,
'Abono Petrobras' as Glosa,
133 as 'Numero Factura'n
from diff2
where  diff_normal_fin>0
;QUIT;


%if (%sysfunc(exist(&libreria..ENVIADOS_PETROBRAS_RPTOS))) %then %do;

%end;
%else %do;
PROC SQL;
CREATE TABLE &libreria..ENVIADOS_PETROBRAS_RPTOS 
(
periodo num,
dia num,
'Bonificación Final'n num,
Pan char(99),
Glosa char(99),
'Numero Factura'n num
)
;QUIT;
%end;

proc sql;
insert into &libreria..ENVIADOS_PETROBRAS_RPTOS 
select 
&periodo. as periodo,
&periodo_dia. as dia,
*
from base_bonificacion_nuevo
outer union corr 
select 
&periodo. as periodo,
&periodo_dia. as dia,
*
from base_bonificacion_DIFF
;QUIT;

/*base a depositar*/

proc sql;
create table bonificacion_petrobras_&periodo_dia. as 
select sum('Bonificación Final'n) as 'Bonificación Final'n,
pan,
coalesce(max(case 
when 'Numero Factura'n=131 then 'Abono Gold Petrobras' 
when 'Numero Factura'n=132 then 'Abono Silver Petrobras'
end),'Abono Petrobras') as Glosa,
min('Numero Factura'n) as 'Numero Factura'n   from (
select 
*
from base_bonificacion_nuevo
outer union corr 
select 
*
from base_bonificacion_DIFF)
group by pan
;QUIT;

PROC EXPORT DATA	=	bonificacion_petrobras_&periodo_dia.
   OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/PETROBRAS_ABONO/bonificacion_petrobras_&periodo_dia..txt"
   DBMS=dlm REPLACE;
   delimiter=';';
   PUTNAMES=YES;
RUN;

/*	EXPORTAR DE SAS A UN SFTP	*/ 
       filename server sftp "bonificacion_petrobras_&periodo_dia..txt" CD='/Bonificacion_petrobras/' 
		HOST='192.168.80.15' user='usr_bi_g';
data _null_;
       infile "/sasdata/users94/user_bi/TRASPASO_DOCS/PETROBRAS_ABONO/bonificacion_petrobras_&periodo_dia..txt";
       file server;
       input;
       put _infile_;
run;

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
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'BENJAMIN_SOTO';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;

data _null_;
FILENAME OUTBOX EMAIL
FROM 	= ("&EDP_BI")
/*TO 		= ("&DEST_1")*/
TO 		= ("aborquezj@bancoripley.com","ccortesl@bancoripley.com","cnavarrov@bancoripley.com")
CC 		= ("&DEST_1","&DEST_2","&DEST_3","&DEST_4","&DEST_5")
ATTACH	= "/sasdata/users94/user_bi/TRASPASO_DOCS/PETROBRAS_ABONO/bonificacion_petrobras_&periodo_dia..txt"
SUBJECT = ("MAIL_AUTOM: Proceso ABONO_PETROBRAS_AUTOM");
FILE OUTBOX;
 PUT "Estimados:";
 put "        Proceso ABONO_PETROBRAS_AUTOM, ejecutado con fecha: &fechaeDVN";   
 PUT ;
 PUT '        Se comparte archivo abonos petrobras asociado al día de ayer';
 PUT '        En servidor sFTP 192.168.80.15, directorio: /Bonificacion_petrobras';
 PUT ;
 PUT '        Adicionalmente, se adjunta en este mail automático';
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 03'; 
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


/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;
