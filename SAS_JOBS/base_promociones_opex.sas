/* VERSIONAMIENTO */
/* 2023-06-13 -- v02 -- Esteban P. -- Cambio credenciales link de conexión a gedcre.
*/

/*PARAMETROS::*/
/*:::::::::::::::::::::::*/
%let libreria=result; /* MODIFICAR PARA QUIEN EJECUTE */

DATA _null_;
per1 = input(put(intnx('month',today(),0,'end'),yymmn6. ),$10.);
per2 = input(put(intnx('month',today(),-1,'end'),yymmn6. ),$10.);

Call symput("per1", per1);
Call symput("per2", per2);
RUN;

%put &per1;
%put &per2;

%Let Periodo_desde=&Per2;
%Let Periodo_hasta=&Per1;

%let Dia=25;
/*Periodo hasta (ventas se veran desde y hasta)*/
%let Base_Entregable=%nrstr('result.Seguimiento_Vta_Art'); /* MODIFICAR PARA QUIEN EJECUTE */
/*:::::::::::::::::::::::*/




%let mz_connect_zeus=CONNECT TO ODBC as zeus(datasrc="creditoprd" user="CONSULTA_CREDITO" password="crdt#0806");

proc sql ;
&mz_connect_zeus;
create table VTA_UM3 AS 
SELECT B.*,(INPUT(B.CODIGO_ARTICULO,BEST13.)) FORMAT=13. AS SKU,
CAT(B.SUCURSAL+10000,' ',B.COD_FCH_CPV,' ',B.NRO_CAJA_NUMERICO,' ',B.NRO_DOCTO) AS BOLETA

FROM connection to zeus(
SELECT 
FLOOR(COD_FCH_CPV/100) as Periodo,
A.RUT_TITULAR,
A.COMPRADOR_PAGADOR AS RUT,

A.DESMAR AS TIPO_TR,
A.SUCURSAL,
A.COD_FCH_CPV,
A.NRO_CAJA_NUMERICO,


A.CODIGO_TRX,
/*
A.CODMAR,
A.PRODUCTO,
A.COD_FCH_CPV-100*floor(A.COD_FCH_CPV/100) as Dia_Nro,
A.FECHA,
*/
A.NRO_DOCTO,
A.UNIDADES,
A.NRO_ITEM,

A.NRO_MESES_DIFERIDO,
A.PLAZO,

A.DIRECCION_E_S,
(CASE WHEN A.DIRECCION_E_S = 1 THEN -(A.PRECIO_ARTICULO - A.DESCUENTO_BOLETA - A.DESCUENTO_ARTICULO)
ELSE (A.PRECIO_ARTICULO - A.DESCUENTO_BOLETA - A.DESCUENTO_ARTICULO)
END ) AS MONTO_TRX, 
A.MONTO_CAPITAL_1 AS MONTO_CAPITAL, 
A.MONTO_INTERESES_1 AS MONTO_INTERESES,
A.CODIGO_ARTICULO,
A.COD_DEPTO,
A.COD_LINEA,
A.TIPO_TRX,
a.CodMar
FROM GEDCRE_CREDITO.TRX_HEADER_DET_TAR_ADM  A 

WHERE (A.COD_FCH_CPV BETWEEN 100*&Periodo_desde+01 AND 100*&Periodo_hasta+31)
AND A.TIPO_TRX in (1,3) /*compras Y NOTAS DE CREDITO*/
/* AND A.CODMAR IN (1,2)  TARJETA RIPLEY 2	TARJETA MASTERCARD*/
AND A.CODIGO_TRX NOT IN (39,401,402,89,90,93)
and a.SUCURSAL NOT IN (10993,10990) 

) B
;QUIT;



%put==================================================================================================;
%put [02] Extraer Boletas con uso de OPEX o Canje de Oportunidad RPtos ;
%put==================================================================================================;

%let libreria=work;

%macro Boletas_Especiales(periodo,libreria);

PROC SQL; 
create table macro as
select &Periodo as periodo,
Tipo_Codigo, 
BOLETA,
Nro_Item,
Codigo,
DCTO 
from publicin.OPEX_CANJESOP_&Periodo.
;quit; 



%if (%sysfunc(exist(&libreria..Boletas_Especiales))) %then %do;
 
%end;
%else %do;
PROC  SQL;
CREATE TABLE &libreria..Boletas_Especiales 
(
periodo	 num,
Tipo_Codigo char(99),
BOLETA char(99),
Nro_Item num,
Codigo num,
DCTO num)
;quit;
%end;


proc sql;
delete *
from &libreria..Boletas_Especiales 
where periodo=&periodo.
;QUIT;


proc sql;
insert into &libreria..Boletas_Especiales
select *
from macro
;QUIT;

proc sql;
create table &libreria..Boletas_Especiales  as 
select 
*
from &libreria..Boletas_Especiales 
;QUIT;

%mend Boletas_Especiales;

%Boletas_Especiales(	&Periodo_desde, &Libreria.	);
%Boletas_Especiales(	&Periodo_hasta, &Libreria.	);


%put==================================================================================================;
%put [03] Hacer Cruce entre bases ;
%put==================================================================================================;

/*indexar ambas tablas antes de cruzar*/

PROC SQL;
CREATE INDEX Boleta ON work.Boletas_Especiales (Boleta)
;QUIT;

PROC SQL;
CREATE INDEX Nro_Item ON work.Boletas_Especiales (Nro_Item)
;QUIT;


PROC SQL;
CREATE INDEX Boleta ON VTA_UM3 (Boleta)
;QUIT;

PROC SQL;
CREATE INDEX Nro_Item ON VTA_UM3 (Nro_Item)
;QUIT;


/*hacer cruce*/

proc sql;
create table Detalle_Vtas_TDA as 
select 
a.*,
b.Codigo as Codigo_Promocional,
b.DCTO as DCTO_Promocional,
b.Tipo_Codigo as Tipo_Codigo_Promocional 
from VTA_UM3 as a 
left join work.Boletas_Especiales as b 
on (a.Boleta=b.Boleta and a.Nro_Item=b.Nro_Item) 

;quit;

proc sql;
create table Detalle_Vtas_TDA as 
select a.*,
case when a.CodMar in (1,2) then 'TAR' else 'OMP' end as Medio_Pago,
b.Nombre_Depto,
b.Division
from Detalle_Vtas_TDA a left join amarinao.DEPTO_DIV_RETAIL b
on a.COD_DEPTO=b.Cod_Depto
;quit;

PROC SQL;
UPDATE Detalle_Vtas_TDA
SET Codigo_Promocional=.
WHERE SUCURSAL=39 AND CodMar not in (1,2) AND Tipo_Codigo_Promocional in ('OPEX','CANJE+OPEX')
;QUIT;

PROC SQL;
UPDATE Detalle_Vtas_TDA
SET DCTO_Promocional=.
WHERE Codigo_Promocional=.;
QUIT;

PROC SQL;
UPDATE Detalle_Vtas_TDA
SET Tipo_Codigo_Promocional=''
WHERE Codigo_Promocional=.;
QUIT;


%put==================================================================================================;
%put [04] Agrupar por Variables Relevantes ;
%put==================================================================================================;

proc sql;
create table &libreria.Detalle_Vtas_TDA as 
select *, cats(RUT,'-',boleta,'-',NRO_ITEM) as llave
from Detalle_Vtas_TDA t1
order by t1.COD_FCH_CPV asc,t1.RUT asc, t1.BOLETA asc, t1.NRO_ITEM asc
;quit;


DATA &libreria.Detalle_Vtas_TDA;
SET  &libreria.Detalle_Vtas_TDA;
IF llave=LAG(llave) THEN FILTRO =1; 
ELSE FILTRO=0; 
RUN;


PROC SQL;
CREATE TABLE WORK.aer AS 
SELECT t1.FILTRO, 
(COUNT(t1.llave)) AS llave
FROM &libreria.DETALLE_VTAS_TDA t1
GROUP BY t1.FILTRO;
QUIT;

proc sql;
create table work.Detalle_Vtas_TDA_AGG as 
select 
Periodo,
COD_FCH_CPV-100*floor(COD_FCH_CPV/100) as dia,
SUCURSAL,
COD_DEPTO as Codigo_Dpto,
Nombre_Depto as Nombre_Dpto,
Division,
Medio_Pago,
Codigo_Promocional,
Tipo_Codigo_Promocional,
SKU,
filtro,
sum(UNIDADES) as Nro_Articulos,
sum(MONTO_TRX) as Mto_Articulos,
sum(DCTO_Promocional) as Mto_DCTO_Promocional  
from &libreria.Detalle_Vtas_TDA
group by 
Periodo,
calculated dia,
SUCURSAL,
COD_DEPTO,
Nombre_Depto,
Division,
Medio_Pago,
Codigo_Promocional,
Tipo_Codigo_Promocional,
SKU,
filtro
;quit;


%put==================================================================================================;
%put [05] Pegar data de Division y Clasificacion DPTO Blando-Duro y Nombre Sucursal;
%put==================================================================================================;

proc sql;
create table work.Detalle_Vtas_TDA_AGG as 
select 
a.*,
cats(compress(put(a.Sucursal,best.)),'|',b.TGMSU_NOM_SUC) as Nombre_Sucursal, 
case 
when a.Codigo_Dpto='D115' then '01. Ropa Interior Mujer'
when a.Codigo_Dpto='D134' then '01. Ropa Interior Mujer'
when a.Codigo_Dpto='D342' then '01. Ropa Interior Mujer'
when a.Codigo_Dpto='D327' then '02. Perfumería'
when a.Codigo_Dpto='D328' then '02. Perfumería'
when a.Codigo_Dpto='D374' then '03. Accesorios'
when a.Codigo_Dpto='D373' then '03. Accesorios'
when a.Codigo_Dpto='D160' then '03. Accesorios'
when a.Codigo_Dpto='D201' then '03. Accesorios'
when a.Codigo_Dpto='D308' then '04. Calzado Mujer/Infantil'
when a.Codigo_Dpto='D309' then '04. Calzado Mujer/Infantil'
when a.Codigo_Dpto='D312' then '04. Calzado Mujer/Infantil'
when a.Codigo_Dpto='D313' then '04. Calzado Mujer/Infantil'
when a.Codigo_Dpto='D310' then '05. Calzado Hombre'
when a.Codigo_Dpto='D311' then '05. Calzado Hombre'
when a.Codigo_Dpto='D102' then '06. DECO Duro'
when a.Codigo_Dpto='D360' then '06. DECO Duro'
when a.Codigo_Dpto='D359' then '06. DECO Duro'
when a.Codigo_Dpto='D363' then '07. Cama y Baño'
when a.Codigo_Dpto='D364' then '07. Cama y Baño'
when a.Codigo_Dpto='D361' then '08. Menaje'
when a.Codigo_Dpto='D362' then '08. Menaje'
when a.Codigo_Dpto='D365' then '09. Decoración y Regalos'
when a.Codigo_Dpto='D127' then '09. Decoración y Regalos'
when a.Codigo_Dpto='D151' then '09. Decoración y Regalos'
when a.Codigo_Dpto='D366' then '09. Decoración y Regalos'
when a.Codigo_Dpto='D367' then '09. Decoración y Regalos'
when a.Codigo_Dpto='D369' then '10. Otros DECO'
when a.Codigo_Dpto='D386' then '10. Otros DECO'
when a.Codigo_Dpto='D169' then '11. Vestuario Deportivo'
when a.Codigo_Dpto='D314' then '11. Vestuario Deportivo'
when a.Codigo_Dpto='D315' then '11. Vestuario Deportivo'
when a.Codigo_Dpto='D170' then '12. Out Door'
when a.Codigo_Dpto='D192' then '12. Out Door'
when a.Codigo_Dpto='D317' then '13. Zapatillas Deportivas'
when a.Codigo_Dpto='D103' then '14. Audio _Tv Video'
when a.Codigo_Dpto='D130' then '14. Audio _Tv Video'
when a.Codigo_Dpto='D171' then '14. Audio _Tv Video'
when a.Codigo_Dpto='D122' then '15. Linea Blanca'
when a.Codigo_Dpto='D136' then '15. Linea Blanca'
when a.Codigo_Dpto='D200' then '15. Linea Blanca'
when a.Codigo_Dpto='D112' then '16. Vestuario Formal Hombre'
when a.Codigo_Dpto='D164' then '16. Vestuario Formal Hombre'
when a.Codigo_Dpto='D163' then '16. Vestuario Formal Hombre'
when a.Codigo_Dpto='D143' then '17. Vestuario Juvenil Hombre'
when a.Codigo_Dpto='D303' then '17. Vestuario Juvenil Hombre'
when a.Codigo_Dpto='D307' then '17. Vestuario Juvenil Hombre'
when a.Codigo_Dpto='D337' then '17. Vestuario Juvenil Hombre'
when a.Codigo_Dpto='D338' then '17. Vestuario Juvenil Hombre'
when a.Codigo_Dpto='D339' then '17. Vestuario Juvenil Hombre'
when a.Codigo_Dpto='D348' then '17. Vestuario Juvenil Hombre'
when a.Codigo_Dpto='D351' then '17. Vestuario Juvenil Hombre'
when a.Codigo_Dpto='D393' then '17. Vestuario Juvenil Hombre'
when a.Codigo_Dpto='D394' then '17. Vestuario Juvenil Hombre'
when a.Codigo_Dpto='D395' then '17. Vestuario Juvenil Hombre'
when a.Codigo_Dpto='D396' then '17. Vestuario Juvenil Hombre'
when a.Codigo_Dpto='D152' then '18. Vestuario Infantil'
when a.Codigo_Dpto='D153' then '18. Vestuario Infantil'
when a.Codigo_Dpto='D162' then '18. Vestuario Infantil'
when a.Codigo_Dpto='D403' then '18. Vestuario Infantil'
when a.Codigo_Dpto='D176' then '18. Vestuario Infantil'
when a.Codigo_Dpto='D300' then '18. Vestuario Infantil'
when a.Codigo_Dpto='D301' then '18. Vestuario Infantil'
when a.Codigo_Dpto='D397' then '18. Vestuario Infantil'
when a.Codigo_Dpto='D398' then '18. Vestuario Infantil'
when a.Codigo_Dpto='D399' then '18. Vestuario Infantil'
when a.Codigo_Dpto='D400' then '18. Vestuario Infantil'
when a.Codigo_Dpto='D401' then '18. Vestuario Infantil'
when a.Codigo_Dpto='D402' then '18. Vestuario Infantil'
when a.Codigo_Dpto='D107' then '19. Escolar'
when a.Codigo_Dpto='D124' then '19. Escolar'
when a.Codigo_Dpto='D331' then '19. Escolar'
when a.Codigo_Dpto='D340' then '19. Escolar'
when a.Codigo_Dpto='D161' then '20. Rodados'
when a.Codigo_Dpto='D198' then '21. Juguetería'
when a.Codigo_Dpto='D175' then '21. Juguetería'
when a.Codigo_Dpto='D125' then '22. Vestuario Mujer'
when a.Codigo_Dpto='D129' then '22. Vestuario Mujer'
when a.Codigo_Dpto='D141' then '22. Vestuario Mujer'
when a.Codigo_Dpto='D159' then '22. Vestuario Mujer'
when a.Codigo_Dpto='D166' then '22. Vestuario Mujer'
when a.Codigo_Dpto='D320' then '22. Vestuario Mujer'
when a.Codigo_Dpto='D321' then '22. Vestuario Mujer'
when a.Codigo_Dpto='D330' then '22. Vestuario Mujer'
when a.Codigo_Dpto='D387' then '22. Vestuario Mujer'
when a.Codigo_Dpto='D388' then '22. Vestuario Mujer'
when a.Codigo_Dpto='D389' then '22. Vestuario Mujer'
when a.Codigo_Dpto='D391' then '22. Vestuario Mujer'
when a.Codigo_Dpto='D392' then '22. Vestuario Mujer'
when a.Codigo_Dpto='D113' then '23. Tecnología'
when a.Codigo_Dpto='D172' then '23. Tecnología'
when a.Codigo_Dpto='D199' then '23. Tecnología'
when a.Codigo_Dpto='D126' then '24. Telefonía y Fotografía'
when a.Codigo_Dpto='D191' then '24. Telefonía y Fotografía'
when a.Codigo_Dpto='D345' then '25. Accesorios Tecnología'
when a.Codigo_Dpto='D347' then '25. Accesorios Tecnología'
else '00. Sin Clasificacion' 
end as Nombre_Division,
case
when a.Codigo_Dpto IN ('D102','D103','D111','D113','D119','D122','D123',
'D126','D128','D130','D133','D136','D148','D149','D150','D171','D172','D185','D191',
'D194','D195','D199','D200','D345','D346','D347','D359','D360','D367','D377','D381',
'D384','D386') 
then 'Duro'
else 'Blando'
end as Categoria_Dpto 
from work.Detalle_Vtas_TDA_AGG as a 
left join jaburtom.BOTGEN_MAE_SUC as b 
on (a.Sucursal=b.TGMSU_COD_SUC_K)

;quit;


%put==================================================================================================;
%put [06] Guardar resultados en tabla entregable ;
%put==================================================================================================;



/*Vaciar en tabla guardable*/
DATA _NULL_;
Call execute(
cat('
proc sql;

create table ',&Base_Entregable,' as 
SELECT * 
from work.Detalle_Vtas_TDA_AGG   

;quit;
')
);
run;

/*Eliminar tablas de paso*/
proc sql; drop table work.VTA_UM3 ;quit;

proc sql; drop table work.Boletas_Especiales ;quit;

proc sql; drop table work.Detalle_Vtas_TDA ;quit;

/* copiar pedro/jonathan/livia/ fabi/ignacio */


/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

SELECT EMAIL into :DEST_3
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("fmunozh@bancoripley.com","iplazam@bancoripley.com","lhernandezh@bancoripley.com","lhernandezh@bancoripley.com")
CC = ("&DEST_1", "&DEST_2", "jgonzalezma@bancoripley.com","fmunozh@bancoripley.com","&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso BASE_PROMOCIONES_OPEX");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso BASE_PROMOCIONES_OPEX, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put ; 
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 02'; 
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
