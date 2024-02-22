/* FORMATOS QUE DEBEN TENER LAS VARIABLES */
/* VERSIONAMIENTO */
/* -- 02/06/2023 -- V02 -- Esteban P. -- Se añade codigo para leer columna de nombre en servidor. */



%let libreria=result;
OPTIONS VALIDVARNAME=ANY; 

DATA WORK.BASE_CODIGOS;
    LENGTH
        DEPTO            $ 17
        CODIGO           5
        SKU              8
        DESCRIPCION      $ 130
        PRECIO_MASTER      8
        PRECIO_VIGENTE     8
        PRECIO_TARJETA     8
        FECHA_INICIO     $ 11
        FECHA_TERMINO    $ 14
        'TDA/COM'n       $ 7 ;
    FORMAT
        DEPTO            $CHAR17.
        CODIGO           BEST13.
        SKU              BEST13.
        DESCRIPCION      $CHAR130.
        PRECIO_MASTER    BEST12.
        PRECIO_VIGENTE   BEST12.
        PRECIO_TARJETA   BEST12.
        FECHA_INICIO     $CHAR11.
        FECHA_TERMINO    $CHAR14.
        'TDA/COM'n       $CHAR7. ;
    INFORMAT
        DEPTO            $CHAR17.
        CODIGO           BEST13.
        SKU               BEST13.
        DESCRIPCION      $CHAR130.
        PRECIO_MASTER    BEST12.
        PRECIO_VIGENTE   BEST12.
        PRECIO_TARJETA   BEST12.
        FECHA_INICIO     $CHAR11.
        FECHA_TERMINO    $CHAR14.
        'TDA/COM'n       $CHAR7. ;
    INFILE "/sasdata/users94/user_bi/TRASPASO_DOCS/OPEX_TDA/BASE_CODIGOS.txt"
 MISSOVER DSD lrecl=32767 firstobs=2  delimiter='09'x ;
    INPUT
        DEPTO            : $CHAR17.
        CODIGO           : ?? BEST13.
        SKU              : ?? BEST13.
        DESCRIPCION      : $CHAR130.
        PRECIO_MASTER    : BEST7.
        PRECIO_VIGENTE   : BEST32.
        PRECIO_TARJETA   : BEST7.
        FECHA_INICIO     : $CHAR11.
        FECHA_TERMINO    : $CHAR14.
        'TDA/COM'n       : $CHAR7. ;
RUN;

DATA _null_;
periodo_act= input(put(intnx('month',today(),0,'begin'),yymmn6. ),$10.) ;
periodo_ant= input(put(intnx('month',today(),-1,'begin'),yymmn6. ),$10.) ;
Call symput("periodo_act", periodo_act);
Call symput("periodo_ant", periodo_ant);
RUN;
%put &periodo_act;
%put &periodo_ant;

%put------------------------------------------------------------------------------------------;
%put [1] CARGAMOS BASE ENVIADA POR RETAIL PARA CALCULO DE REBATE;
%put------------------------------------------------------------------------------------------;

PROC SQL;
CREATE TABLE BASE_DATA AS
SELECT distinct 
DEPTO,
CODIGO,
'TDA/COM'n  as TDA_COM,
SKU,
DESCRIPCION,
PRECIO_VIGENTE,
PRECIO_MASTER,
COALESCE(PRECIO_VIGENTE,PRECIO_MASTER) as PRECIO_VIGENTE2,
PRECIO_TARJETA,
input(cat(substr(FECHA_INICIO ,7,4),substr(FECHA_INICIO ,4,2),substr(FECHA_INICIO ,1,2)),best.) as  FECHA_INICIO,
input(cat(substr(FECHA_TERMINO ,7,4),substr(FECHA_TERMINO ,4,2),substr(FECHA_TERMINO ,1,2)),best.) as  FECHA_TERMINO

FROM BASE_CODIGOS
;QUIT;

%put------------------------------------------------------------------------------------------;
%put [2] TRABAJAMOS LA BASE PARA MODIFICAR INCONSISTENCIAS O FORMATOS;
%put------------------------------------------------------------------------------------------;

/* cambio los valores missing por 0, para que no me los tome como negativos en los case when */
data BASE_DATA;
   set BASE_DATA;
   array change PRECIO_VIGENTE2;
        do over change;
            if change=. then change=0;
        end;
 run ;

 data BASE_DATA;
   set BASE_DATA;
   array change PRECIO_MASTER;
        do over change;
            if change=. then change=0;
        end;
 run ;

 data BASE_DATA;
   set BASE_DATA;
   array change PRECIO_TARJETA;
        do over change;
            if change=. then change=0;
        end;
 run ;

 data BASE_DATA;
   set BASE_DATA;
   array change codigo;
        do over change;
            if change=. then change=0;
        end;
 run ;

  data BASE_DATA;
   set BASE_DATA;
   array change sku;
        do over change;
            if change=. then change=0;
        end;
 run ;   



PROC SQL;
CREATE TABLE BASE_DATA AS
SELECT 
DEPTO,
CODIGO,
 TDA_COM,
compress(put(SKU,13.)) as sku,
DESCRIPCION,
PRECIO_VIGENTE,
PRECIO_MASTER,
PRECIO_VIGENTE2,
PRECIO_TARJETA,
FECHA_INICIO,
FECHA_TERMINO
FROM BASE_DATA
;QUIT;

%put------------------------------------------------------------------------------------------;
%put [3] GENERAMOS MARCAS DE ERRORES;
%put------------------------------------------------------------------------------------------;
/* ELIMINO FILAS DONDE NO EXISTA LA COLUMNA PRECIO_TARJETA */

PROC SQL;
create table BASE_DATA1 as
select *,
case when (PRECIO_TARJETA between 0.000001 and 0.999 AND PRECIO_VIGENTE2 between 0.000001 and 0.999) then 1 else 0 end as MARCA_PORCENTAJE,
case when PRECIO_TARJETA=0 OR PRECIO_TARJETA IS MISSING then 1 else 0 end as NO_PRECIO_TARJETA,
case when (PRECIO_MASTER=0 AND PRECIO_VIGENTE2=0) OR (PRECIO_MASTER IS MISSING AND PRECIO_VIGENTE2 IS MISSING) then 1 else 0
end as NO_OTRO_PRECIO,
case when PRECIO_TARJETA<0 or PRECIO_MASTER<0 or PRECIO_VIGENTE2<0 then 1 else 0 end as PRECIO_NEGATIVO,
case when codigo=0 and TDA_COM='TDA' then 1 else 0 end as MAL_TDA,
case when length(SKU)<13 and TDA_COM='COM' then 1 else 0 end as MAL_COM,
case when (codigo=0 or  length(SKU)<13) and TDA_COM='TDA/COM' then 1 else 0 end as MAL_TDA_COM,
case when (PRECIO_TARJETA between 0.000001 and 0.999 AND PRECIO_VIGENTE2>=1) then 1 else 0 end as MARCA_INCON_PORCENT,
case when TDA_COM not in ('TDA/COM', 'TDA', 'COM') then 1 else 0 end as MAL_NOMBRE_TDA_COM
FROM BASE_DATA
;QUIT;

proc sql;
create table BASE_DATA2 as
select
*,
case when (NO_PRECIO_TARJETA=1 OR NO_OTRO_PRECIO=1 OR PRECIO_NEGATIVO=1 OR MAL_TDA=1 OR MAL_COM=1 OR MAL_TDA_COM=1 OR MARCA_INCON_PORCENT=1 or MAL_NOMBRE_TDA_COM=1) then 0 else 1 end as SI_CALCULAR,
cats(
case when NO_PRECIO_TARJETA=1 then 'Columna PRECIO_TARJETA sin valor' else '' end, '+',
case when NO_OTRO_PRECIO=1 then 'Columnas PRECIO_VIGENTE y PRECIO_MASTER vacias' else '' end,'+',

case when MAL_TDA=1 then 'Falta codigo de Promocion para Rebate TDA' else '' end,'+',
case when MAL_COM=1 then 'Falta SKU para Rebate COM' else '' end,'+',
case when MAL_TDA_COM=1 then 'Falta codigo de Promocion o SKU para Rebate COM/TDA' else '' end,'+',
case when MARCA_INCON_PORCENT=1 then 'No todos los valores son %' else '' end,'+',
case when MAL_NOMBRE_TDA_COM=1 then 'Columna TDA/COM trae otro valor' else '' end,'+',
case when PRECIO_NEGATIVO=1 then 'Contiene un Precio negativo' else '' end ) AS MARCAJE
from BASE_DATA1
;quit;

%put------------------------------------------------------------------------------------------;
%put [4] SEPARAMOS BASES PARA TRABAJAR ENTRE TDA | COM | TDA_COM Y A SU VEZ EN % Y ENTEROS;
%put------------------------------------------------------------------------------------------;

proc sql;
create table base_data2 as 
select 
*,
case when PRECIO_VIGENTE2>1 then 'ENTERO'
when PRECIO_VIGENTE2>0 and PRECIO_VIGENTE2<=1 then 'FLOAT'
when PRECIO_VIGENTE2=0 then 'ERROR' end as tipologia
from base_data2
;QUIT;

%put------------------------------------------------------------------------------------------;
%put [5] EXTRAEMOS OPEX CON SUS MTOS | TRX | UNIDADES | CLIENTES DESDE LA BASE;
%put------------------------------------------------------------------------------------------;

proc sql;
create table parte1 as 
select 
*
from result.uso_tr_marca_&periodo_ant.
where MARCA_TIPO_TR='TR'
and Dia_Nro>24
;QUIT;

proc sql;
create table parte2 as 
select 
*
from result.uso_tr_marca_&periodo_act.
where MARCA_TIPO_TR='TR'
and Dia_Nro<=24
;QUIT;


proc sql;
create table parte1 as 
select 
monotonic() as ind,
*
from parte1
;QUIT;

proc sql;
create table parte2 as 
select 
monotonic() as ind,
*
from parte2
;QUIT;


/*relacion con canjes*/

proc sql;
create table parte1_1 as 
select distinct 
b.codigo,
a.*
from parte1 as a 
left join PUBLICIN.OPEX_CANJESOP_&periodo_ant. as b
on(a.boleta=b.boleta and a.Nro_Item=b.Nro_Item)
;QUIT;

proc sql;
create table parte2_1 as 
select distinct 
b.codigo,
a.*
from parte2 as a 
left join PUBLICIN.OPEX_CANJESOP_&periodo_act. as b
on(a.boleta=b.boleta and a.Nro_Item=b.Nro_Item)
;QUIT;

proc sql;
create table BASE_VENTA as 
select 
*
from parte1_1
outer union corr 
select 
*
from parte2_1
;QUIT;


proc sql;
create table marcaje_venta as 
select distinct 
a.*,
case when ( a.codigo=b.codigo)  and a.SUCURSAL<>39 and  b.TDA_COM='TDA' and b.codigo is not null then 1 else 0 end  as TDA_REBATE,
case when (compress(put(a.sku,13.))=b1.sku)   and a.SUCURSAL=39 and  b1.TDA_COM='COM'
and length(b1.sku)=13 and a.DDMTD_FCH_DIA between b1.FECHA_INICIO and   b1.FECHA_TERMINO then 1 else 0 end  as COM_REBATE,
case when (compress(put(a.sku,13.))=b2.sku) and (a.codigo=b2.codigo) and  b2.TDA_COM='TDA/COM' and  length(b2.sku)=13 
and b2.codigo is not null

then 1 else 0 end  as TDA_COM_REBATE,

case when compress(put(a.sku,13.))=b3.sku   and  b3.TDA_COM='TDA/COM' and a.SUCURSAL=39  
and  length(b3.sku)=13 
and a.DDMTD_FCH_DIA between b3.FECHA_INICIO and   b3.FECHA_TERMINO then  1 else 0 end  as TDA_COM_COM_REBATE

from base_venta as a 
left join base_data2 as b
on( a.codigo=b.codigo)  and a.SUCURSAL<>39 and  b.TDA_COM='TDA' and b.codigo is not null

left join base_data2 as b1
on compress(put(a.sku,13.))=b1.sku   and a.SUCURSAL=39 and  b1.TDA_COM='COM' and length(b1.sku)=13 
and a.DDMTD_FCH_DIA between b1.FECHA_INICIO and   b1.FECHA_TERMINO


left join base_data2 as b2
on compress(put(a.sku,13.))=b2.sku and (a.codigo=b2.codigo)   and  b2.TDA_COM='TDA/COM' and  length(b2.sku)=13 
and b2.codigo is not null

left join base_data2 as b3
on compress(put(a.sku,13.))=b3.sku   and  b3.TDA_COM='TDA/COM' and a.SUCURSAL=39   and  length(b3.sku)=13 
and a.DDMTD_FCH_DIA between b3.FECHA_INICIO and   b3.FECHA_TERMINO
;QUIT;

/* prueba */ 
proc sqL;
create table &libreria..TABLA_RABATE_RETAIL as 
select 
a.*,
sum(case when a.TDA_COM='TDA' then b.mto  end) as MTO_TDA,
sum(case when a.TDA_COM='COM' then b1.mto end) as MTO_COM,
sum(case when a.TDA_COM='TDA/COM' then b2.mto end) as MTO_TDA_COM,
sum(case when a.TDA_COM='TDA/COM' then b3.mto end) as MTO_TDA_COM_COM,

sum(case when a.TDA_COM='TDA' then b.trx  end) as trx_TDA,
sum(case when a.TDA_COM='COM' then b1.trx end) as trx_COM,
sum(case when a.TDA_COM='TDA/COM' then b2.trx end) as trx_TDA_COM,
sum(case when a.TDA_COM='TDA/COM' then b3.trx end) as trx_TDA_COM_COM,

case when a.tipologia='ENTERO' then ((PRECIO_VIGENTE2-	PRECIO_TARJETA)/(1.19))*(calculated trx_TDA)

when a.tipologia='FLOAT' then ((PRECIO_TARJETA-PRECIO_VIGENTE2))*(calculated MTO_TDA)
else 0 end as REBATE_TDA,

case when a.tipologia='ENTERO' then ((PRECIO_VIGENTE2-	PRECIO_TARJETA)/(1.19))*(calculated trx_COM)

when a.tipologia='FLOAT' then ((PRECIO_TARJETA-PRECIO_VIGENTE2))*(calculated MTO_COM)
else 0 end as REBATE_COM,

case when a.tipologia='ENTERO' then ((PRECIO_VIGENTE2-	PRECIO_TARJETA)/(1.19))*(calculated trx_TDA_COM)

when a.tipologia='FLOAT' then ((PRECIO_TARJETA-PRECIO_VIGENTE2))*(calculated MTO_TDA_COM)
else 0 end as REBATE_TDA_COM,

case when a.tipologia='ENTERO' then ((PRECIO_VIGENTE2-	PRECIO_TARJETA)/(1.19))*(calculated trx_TDA_COM_COM)

when a.tipologia='FLOAT' then ((PRECIO_TARJETA-PRECIO_VIGENTE2))*(calculated MTO_TDA_COM_COM)
else 0 end as REBATE_TDA_COM_COM

from base_data2 as a 
left join (select  codigo,sum(mto) as mto, count(codigo)  as trx
from marcaje_venta where TDA_REBATE=1
group by codigo) as b
ON(a.codigo=b.codigo)   and a.TDA_COM='TDA'

left join (select DDMTD_FCH_DIA, SKU,sum(mto) as mto, count(NRO_UNI)  as trx
from marcaje_venta where COM_REBATE=1
group by DDMTD_FCH_DIA, SKU) as b1
ON compress(put(b1.sku,13.))=a.sku    and a.TDA_COM='COM' and b1.DDMTD_FCH_DIA between a.FECHA_INICIO and   a.FECHA_TERMINO

left join (select SKU,codigo,sum(mto) as mto, count(*)  as trx
from marcaje_venta where TDA_COM_REBATE=1
group by SKU,codigo) as b2
ON compress(put(b2.sku,13.))=a.sku and  (a.codigo=b2.codigo)  and a.TDA_COM='TDA/COM'

left join (select DDMTD_FCH_DIA, SKU,sum(mto) as mto, count(NRO_UNI)  as trx
from marcaje_venta where TDA_COM_COM_REBATE=1
group by DDMTD_FCH_DIA, SKU) as b3
ON compress(put(b3.sku,13.))=a.sku  and a.TDA_COM='TDA/COM' and b3.DDMTD_FCH_DIA between a.FECHA_INICIO and   a.FECHA_TERMINO

group by
a.DEPTO,
a.CODIGO,
a.TDA_COM,
a.sku,
a.DESCRIPCION,
a.PRECIO_VIGENTE,
a.PRECIO_MASTER,
a.PRECIO_VIGENTE2,
a.PRECIO_TARJETA,
a.FECHA_INICIO,
a.FECHA_TERMINO,
a.MARCA_PORCENTAJE,
a.NO_PRECIO_TARJETA,
a.NO_OTRO_PRECIO,
a.PRECIO_NEGATIVO,
a.MAL_TDA,
a.MAL_COM,
a.MAL_TDA_COM,
a.MARCA_INCON_PORCENT,
a.MAL_NOMBRE_TDA_COM,
a.SI_CALCULAR,
a.MARCAJE,
a.tipologia	

;QUIT;


PROC SQL;
CREATE TABLE &libreria..TABLA_RABATE_RETAIL_ERROR AS
SELECT 
		  0 as PARAMETREO_CALCULO,
		  0 as SI_CALCULO, 
          MARCAJE,
          t1.TDA_COM, 
          '' AS COD_DEPTO, 
          '' AS DEPARTAMENTO_FIN, 
          t1.DESCRIPCION, 
          t1.PRECIO_MASTER, 
          t1.PRECIO_VIGENTE2, 
          t1.PRECIO_TARJETA, 
          t1.FECHA_INICIO, 
          t1.FECHA_TERMINO, 
		  0 as MARCA_BASE, 
		  0 as Mto_TR_COM_OPEX, 
		  0 as Mto_TR_TDA_OPEX, 
		  0 as TRX_TR_COM_OPEX, 
		  0 as TRX_TR_TDA_OPEX, 
		  0 as TOT_NROUNI_TR_COM_OPEX, 
		  0 as TOT_NROUNI_TR_TDA_OPEX, 
		  0 as CLIENTES_TR_COM_OPEX, 
		  0 as CLIENTES_TR_TDA_OPEX, 
		  0 as APORTE_OPEX_TDA, 
		  0 as REBATE_TDA, 
		  0 as APORTE_OPEX_COM, 
		  0 as REBATE_COM, 
          t1.SKU,
		  0 as REBATE_TDACOM

FROM BASE_DATA2 AS T1
where SI_CALCULAR=0
;QUIT;


data _null_;
execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechaeDVN", execDVN) ;
RUN;
%put &fechaeDVN;/*fecha ejecucion proceso */


/*EXPORTAR EN CSV*/
proc sql;
create table TABLA_RABATE_RETAIL AS 
SELECT 
&fechaeDVN. as fecha_proceso,
*
FROM &libreria..TABLA_RABATE_RETAIL
;QUIT;

/*EXPORTAR EN CSV*/
proc sql;
create table TABLA_RABATE_RETAIL_ERROR AS 
SELECT 
&fechaeDVN. as fecha_proceso,
*
FROM &libreria..TABLA_RABATE_RETAIL_ERROR
;QUIT;

filename myfile "/sasdata/users94/user_bi/TRASPASO_DOCS/OPEX_TDA/TABLA_RABATE_RETAIL.xlsx" ;
data _null_;
rc=fdelete("myfile");
;run;
filename myfile clear;


filename myfile2 "/sasdata/users94/user_bi/TRASPASO_DOCS/OPEX_TDA/TABLA_RABATE_RETAIL_ERROR.xlsx" ;
data _null_;
rc=fdelete("myfile2");
;run;
filename myfile2 clear;


PROC EXPORT DATA=TABLA_RABATE_RETAIL
DBMS=xlsx 
OUTFILE= "/sasdata/users94/user_bi/TRASPASO_DOCS/OPEX_TDA/TABLA_RABATE_RETAIL.xlsx"
replace;
;RUN;

PROC EXPORT DATA=TABLA_RABATE_RETAIL_ERROR
DBMS=xlsx 
OUTFILE= "/sasdata/users94/user_bi/TRASPASO_DOCS/OPEX_TDA/TABLA_RABATE_RETAIL_ERROR.xlsx"
replace;
;RUN;
 

proc sql noprint;                              
SELECT EMAIL into :DEST_1 
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'IGNACIO_PLAZA';
quit;

%put &=DEST_1;

Filename myEmail EMAIL    
    Subject = "BASES REBATE ACTUALIZADAS"
    From    = ("IPLAZAM@bancoripley.com") 
    To      = ("pmunozc@bancoripley.com","IPLAZAM@bancoripley.com", "jsantamaria@bancoripley.com",
			   "adiazse@bancoripley.com", "fmunozh@bancoripley.com")
    Type    = 'Text/Plain';


Data _null_; File myEmail; 
PUT "Estimadas,";
PUT "Se informa que las bases de Rebate se encuentra actualizadas en la SFTP: &fechaeDVN.";
PUT "Recuerden subir archivo BASE_CODIGOS.txt antes de las 16:00!!";
PUT "Saludos.";
PUT " ";
PUT " ";
PUT 'Atte.';
Put 'Equipo de Facturacion';
PUT ;
PUT ;
PUT ;
;RUN;
