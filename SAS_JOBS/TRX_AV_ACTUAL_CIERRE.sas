/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	TRX_AV_ACTUAL_CIERRE		 	 ===============================*/
/* CONTROL DE VERSIONES
/* 2023-04-20 -- v06 -- Alejandra M. -- Se agrego la mastercard Black a la marca de tipo de tarjeta y la descripcion del producto tipo_pdto se dejo directo de la tabla 43
/* 2022-11-29 -- v05 -- David V.	-- Actualización variable periodo en tabla export to aws.
/* 2022-11-07 -- v04 -- Alejandra M.-- Actualización en la lógica:
									-- (*)TRX=TRX Neteadas (TRX de compras-TRX de Notas de crédito)
									-- (**) Clientes= Se consideran clientes distintos
									-- (***) Monto=Venta Neta(Monto Compra-Monto Nota de crédito)
/* 2022-10-28 -- v03 -- Sergio J.	-- New delete and export code to aws
/* 2022-10-07 -- V02 -- Sergio J.	-- Se agregan exportación a raw
/* 2022-08-01 -- V01 -- David V.	-- Se agregan comentarios, versionamiento y correo
/* 0000-00-00 -- V00 --    			-- Original

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

options validvarname=any;
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

/*  se agrega canal de venta CHEK y MasterCard Cerrada 15-07-2022 */

%let libreria=PUBLICIN;

DATA _NULL_;
per = put(intnx('mONth',today(),-1,'end'), yymmn6.);
datei 	= input(put(intnx('month',today(),-1,'begin' ),yymmdd10.),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datef	= input(put(intnx('month',today(),-1,'end'	),yymmdd10.),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
FECHA_PROCESO	= compress(input(put(today(),yymmdd10.),$10.),"-",c);
call symput("Periodo",per);
Call symput("fechai", datei);
Call symput("fechaf", datef);
call symput("FECHA_PROCESO",FECHA_PROCESO);

run;

%put &Periodo; 
%put &fechai;  
%put &fechaf;  
%put &FECHA_PROCESO;


PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table CUOTA_&Periodo. as
select RUT,
DV,
CODENT,
CENTALTA,
CUENTA,
fecfac,
PAN	,
NUMAUT,
NUMBOLETA,
SIAIDCD,
CODPAIS AS PAIS,
CASE WHEN CODPAIS=152 THEN 'NACIONAL' ELSE 'INTERNACIONAL' END AS NACIONAL, 
sucursal,
caja,
CODCOM,
NOMCOMRED,
CODACT,
DESACT,
CASE WHEN (SIGNO='-')  THEN 'NOTA CREDITO' ELSE 'COMPRA' END AS TRANSACCION, 
CODMAR,
INDTIPT,
DESTIPT,
TIPO_TARJETA,
LINEA,
TIPFRAN AS FRANQUICIA,
DESFRA,
TIPOFAC,
DESTIPFAC,
SIGNO,
TOTCUOTAS,
CASE     
WHEN TOTCUOTAS = 0 THEN 'REVOLVING'
WHEN TOTCUOTAS > 0 AND TOTCUOTAS < 2   THEN '1 CUOTA'
ELSE '2 O MAS CUOTAS' END AS FINANCIAMIENTO,

CASE WHEN SIGNO='-' THEN CAPITAL*(-1) ELSE CAPITAL END AS CAPITAL,
CASE WHEN SIGNO='-' THEN ENTRADA*(-1) ELSE ENTRADA END AS PIE,
PORINT,
VALOR_CUOTA,
CASE WHEN SIGNO='-' THEN MGFIN*(-1) ELSE MGFIN END AS MGFIN,
IMPTOTAL,
PORINTCAR,
NUMMESCAR,
CASE WHEN NUMMESCAR>0 THEN 1 ELSE 0 END AS I_DIFERIDO,
CASE WHEN SIGNO='-' THEN COMISION*(-1) ELSE COMISION END AS COMISION,
MODENTDAT,
IDTERM,
PRODUCTO


from connection to ORACLE( 
select 
cast(G.PEMID_GLS_NRO_DCT_IDE_K as INT) AS RUT,
G.PEMID_DVR_NRO_DCT_IDE as DV,
A.codent,
A.centalta,
A.cuenta,
A.fecfac,
A.PAN,
A.NUMAUT,
A.NUMBOLETA,
A.SIAIDCD,
A.CODPAIS,
substr(A.sucursal,1,4) as sucursal,
substr(A.sucursal,5,4) as caja,
A.CODCOM,
A.NOMCOMRED,
A.codact,
E.desact,
F.CODMAR,
F.INDTIPT,
J.DESTIPT,
CASE 
WHEN F.CODMAR=1 AND F.INDTIPT 	in (1,3,9,11) then 'TR'
WHEN F.CODMAR=2	 AND F.INDTIPT	in (1,6,7,10,14) then 'TAM'
WHEN F.CODMAR=2	 AND F.INDTIPT	in (8) then 'MASTERCARD DEBITO'
WHEN F.CODMAR=2	 AND F.INDTIPT	in (13) then 'DEBITO CTACTE'
WHEN F.CODMAR=2	 AND F.INDTIPT	in (12) then 'MASTERCARD CHEK'
WHEN F.CODMAR=4	 AND F.INDTIPT	in (1) then 'MAESTRO DEBITO' 
end 
as TIPO_TARJETA,
A.LINEA ,
A.TIPFRAN,
I.DESFRA,
A.TIPOFAC,
H.DESTIPFAC,
H.INDNORCOR,
H.SIGNO,
A.IMPFAC as CAPITAL, 
A.ENTRADA,
C.TOTCUOTAS,
C.IMPCUOTA AS VALOR_CUOTA,
C.Impinttotal as MGFIN,
C.IMPTOTAL,
C.PORINT,
C.PORINTCAR,
C.NUMMESCAR,
X.MODENTDAT,
X.IDTERM,
B.PRODUCTO,

sum(coalesce((D.impbrueco - D.impboneco),0)) as COMISION

/*Operaciones en Cuotas*/
from GETRONICS.mpdt205 A 
/*Autorizacines*/
left join GETRONICS.MPDT004 X on A.SIAIDCD=X.SIAIDCD
/*relacion para obtener los datos del contrato a partir del movimiento*/
left join GETRONICS.MPDT007 B ON (A.CODENT=B.CODENT AND A.CENTALTA=B.CENTALTA AND A.CUENTA=B.CUENTA)
/*relacion para obtener los datos de financiamiento de la operacion en cuotas*/
LEFT JOIN GETRONICS.MPDT206 C  ON (A.codent=C.codent AND A.centalta=C.centalta AND A.cuenta=C.cuenta  AND A.clamon=C.clamon AND A.numopecuo=C.numopecuo AND A.numfinan=C.numfinan )
/*relacion para obtener los conceptos de comisiones asociadas al negocio en cuotas*/
left join GETRONICS.MPDT208 D ON (A.codent=D.codent AND A.centalta=D.centalta AND A.cuenta = D.cuenta AND A.clamon = D.clamon AND A.numopecuo = D.numopecuo AND A.numfinan = D.numfinan)
/*relacion para obtener la descripción del codigo de actividad ISO*/
left join GETRONICS.MPDT039 E ON (A.codent=E.codent and A.codact=E.codact)
/*relacion para obtener la marca y el tipo de tarjeta*/
LEFT JOIN GETRONICS.MPDT009 F ON (A.codent=F.codent AND A.centalta = F.centalta AND A.cuenta = F.cuenta AND A.pan = F.pan)
/*relacion para determinar el rut asociado al titular del contrato*/
left join BOPERS_MAE_IDE G ON G.PEMID_NRO_INN_IDE = B.identcli
/*relacion para poder filtrar las facturas de compras*/
LEFT JOIN GETRONICS.MPDT044 H ON (A.codent = H.codent  AND A.tipofac = H.tipofac AND A.indnorcor = H.indnorcor AND H.indfacinf = 'N' )/*Indicador de factura informativa (S/N)*/
/*Franquicias*/
LEFT JOIN GETRONICS.MPDT131 I ON (A.TIPFRAN = I.TIPFRAN AND I.CODIDIOMA='1')  
/*Tipos de Tarjeta*/
LEFT JOIN GETRONICS.MPDT026 J ON (J.codent = F.codent AND J.CODMAR=F.CODMAR AND J.INDTIPT=F.INDTIPT )  

WHERE A.tipofac not in (210,115,117) /*210 RepactaciONes, 115 y 117 RegularizaciONes sir*/
AND A.LINEA in ('0051') /* av */
and A.tipfran <> 9999 and A.tipfran <> 8006  and A.tipfran <> 0 /*se excluyen franquicias de ajustes*/
AND A.fecfac BETWEEN  %str(%')&fechai.%str(%') AND %str(%')&fechaf.%str(%')  /*aqui se debe indicar el rango de busqueda de transacciones revolving*/

group by 
G.PEMID_GLS_NRO_DCT_IDE_K,
G.PEMID_DVR_NRO_DCT_IDE,
A.codent,
A.centalta,
A.cuenta,
A.fecfac,
A.PAN,
A.NUMAUT,
A.NUMBOLETA,
A.SIAIDCD,
A.CODPAIS,
substr(A.sucursal,1,4),
substr(A.sucursal,5,4),
A.CODCOM,
A.NOMCOMRED,
A.codact,
E.desact,
F.CODMAR,
F.INDTIPT,
J.DESTIPT,
CASE 
WHEN F.CODMAR=1 AND F.INDTIPT 	in (1,3,9,11) then 'TR'
WHEN F.CODMAR=2	 AND F.INDTIPT	in (1,6,7,10,14) then 'TAM'
WHEN F.CODMAR=2	 AND F.INDTIPT	in (8) then 'MASTERCARD DEBITO'
WHEN F.CODMAR=2	 AND F.INDTIPT	in (13) then 'DEBITO CTACTE'
WHEN F.CODMAR=2	 AND F.INDTIPT	in (12) then 'MASTERCARD CHEK'
WHEN F.CODMAR=4	 AND F.INDTIPT	in (1) then 'MAESTRO DEBITO' 
end,
A.LINEA ,
A.TIPFRAN,
I.DESFRA,
A.TIPOFAC,
H.DESTIPFAC,
H.INDNORCOR,
H.SIGNO,
A.IMPFAC, 
A.ENTRADA,
C.TOTCUOTAS,
C.IMPCUOTA,
C.Impinttotal,
C.IMPTOTAL,
C.PORINT,
C.PORINTCAR,
C.NUMMESCAR,
X.MODENTDAT,
X.IDTERM,
B.PRODUCTO
) 
;quit;

PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table SINCUOTA_&Periodo. as
select RUT,
DV,
CODENT,
CENTALTA,
CUENTA,
fecfac,
PAN,
NUMAUT,
NUMBOLETA,
SIAIDCD,
CODPAIS AS PAIS,
CASE WHEN CODPAIS=152 THEN 'NACIONAL' ELSE 'INTERNACIONAL' END AS NACIONAL, 
sucursal,
caja,
CODCOM,
NOMCOMRED,
codact,
desact,
CASE WHEN (SIGNO='-')  THEN 'NOTA CREDITO' ELSE 'COMPRA' END AS TRANSACCION, 
CODMAR,
INDTIPT,
DESTIPT,
TIPO_TARJETA,
LINEA,
TIPFRAN AS FRANQUICIA,
DESFRA,
TIPOFAC,
DESTIPFAC,
SIGNO,
TOTCUOTAS,
'REVOLVING' AS FINANCIAMIENTO,
CASE WHEN SIGNO='-' THEN CAPITAL*(-1) ELSE CAPITAL END AS CAPITAL,
CASE WHEN SIGNO='-' THEN ENTRADA*(-1) ELSE ENTRADA END AS PIE,
0 as VALOR_CUOTA,
0 as MGFIN,
0 as IMPTOTAL,
0 as PORINT,
0 as PORINTCAR,
0 as NUMMESCAR,
0 AS I_DIFERIDO,
CASE WHEN SIGNO='-' THEN COMISION*(-1) ELSE COMISION END AS COMISION,
MODENTDAT,
IDTERM,
PRODUCTO
      
from connection to ORACLE( 
select 
cast(G.PEMID_GLS_NRO_DCT_IDE_K as INT) AS RUT,
G.PEMID_DVR_NRO_DCT_IDE as DV,
A.codent,
A.centalta,
A.cuenta,
A.codpais,
A.fecfac,
A.PAN,
A.NUMAUT,/*Número de autorización*/
A.NUMBOLETA,/*Número que asigna el Terminal en el momento de la operación.*/
A.SIAIDCD,
substr(A.sucursal,1,4) as sucursal,
substr(A.sucursal,5,4) as caja,
A.codcom,
A.nomcomred,
A.codact,
A.TOTCUOTAS,
D.desact,
F.CODMAR,
F.INDTIPT,
J.DESTIPT,
CASE 
WHEN F.CODMAR=1 AND F.INDTIPT 	in (1,3,9,11) then 'TR'
WHEN F.CODMAR=2	 AND F.INDTIPT	in (1,6,7,10,14) then 'TAM'
WHEN F.CODMAR=2	 AND F.INDTIPT	in (8) then 'MASTERCARD DEBITO'
WHEN F.CODMAR=2	 AND F.INDTIPT	in (13) then 'DEBITO CTACTE'
WHEN F.CODMAR=2	 AND F.INDTIPT	in (12) then 'MASTERCARD CHEK'
WHEN F.CODMAR=4	 AND F.INDTIPT	in (1) then 'MAESTRO DEBITO' 
end 
as TIPO_TARJETA,
A.linea,
A.tipfran,/*Tipo de franquicia*/
I.DESFRA,
A.tipofac,/*Tipo de factura*/
E.DESTIPFAC,
E.INDNORCOR,/*Indicador de normal o correctora: 0 - Normal  1 – Correctora*/
E.signo,/*Signo del importe (+/-)*/
A.IMPFAC as CAPITAL, /*Importe de la factura*/
A.ENTRADA,/*Entrada: (pie). Importe que corresponde a la parte de la compra que el cliente abona en efectivo en cajA. Tiene carácter informativo*/
X.MODENTDAT,
X.IDTERM,
B.PRODUCTO,
coalesce ((C.impbrueco - C.impboneco),0) as COMISION /*(Importe bruto calculado por el concepto económico)-(IMPBONECO:Importe bonificado sobre el cálculo del concepto económico)*/

/*Movimientos del Extracto de Crédito*/
from GETRONICS.mpdt012 A
/*Autorizacines*/
left join GETRONICS.MPDT004 X ON A.SIAIDCD = X.SIAIDCD
/* relacion para obtener los datos del contrato a partir del movimiento */
left join GETRONICS.MPDT007 B ON (A.codent = B.codent and A.centalta = B.centalta and A.cuenta = B.cuenta)
/* relacion para obtener la descripción del codigo de actividad ISO */
left join GETRONICS.MPDT039 D ON (A.codent = D.codent and A.codact  = D.codact)
/*relacion para obtener la marca y el tipo de tarjeta*/
left join GETRONICS.MPDT009 F ON (A.codent = F.CODENT AND A.centalta = F.centalta AND A.cuenta = F.cuenta AND A.pan = F.pan)
/*relacion para determinar el rut asociado al titular del contrato*/
left join BOPERS_MAE_IDE G ON G.PEMID_NRO_INN_IDE = B.identcli
/*relacion para poder filtrar las facturas de compras*/
left join GETRONICS.MPDT044 E ON (A.tipofac = E.tipofac and A.indnorcor = E.indnorcor and E.indfacinf = 'N') /*Indicador de factura informativa (S/N)*/
/* relacion para obtener los conceptos de comisiones asociadas al movimiento*/
left join GETRONICS.MPDT151 C ON (A.codent = C.codent and A.centalta = C.centalta and A.cuenta = C.cuenta and A.clamon = C.clamon and A.numextcta = C.numextcta and A.nummovext = C.nummovext and C.tipimp = 2 and C.codconeco= 200) 
/*Franquicias*/
LEFT JOIN GETRONICS.MPDT131 I ON (A.TIPFRAN=I.TIPFRAN AND I.CODIDIOMA='1')  
/*Tipos de Tarjeta*/
LEFT JOIN GETRONICS.MPDT026 J ON (J.codent=F.codent AND J.CODMAR=F.CODMAR AND J.INDTIPT=F.INDTIPT )  

/*filtros adicionales*/
where A.tipofac not in (210,115,117) /*210 RepactaciONes, 115 y 117 CARGO REGULARIZACION SIR */
AND A.LINEA in ('0051') /* av */
AND A.indnorcor = 0 /*Indicador de normal o correctora: 0 - Normal  1 – Correctora*/
/*AND A.indmovanu = 0
 Indicador de movimiento anulado:
0 – Normal
1 – Anulado
2 – Pago por contrato
El pago tiene desglose cuando INDMOVANU = 2 o INDMOVANU = 0 y ORIGENOPE = ‘PAGE’*/
AND A.tipfran <> 9999 and A.tipfran <> 8006  and A.tipfran <> 0  /* se excluyen franquicias de ajustes */
AND A.numcuota = 0 /*Sin Cuota*/
and E.tipofacsist = 2   /* solo compras*/
AND A.fecfac BETWEEN  %str(%')&fechai.%str(%') AND %str(%')&fechaf.%str(%') /*aqui se debe indicar el rango de busqueda de transacciones revolving */
) 
;quit;

PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table NC_&Periodo. as
select RUT,
DV,
CODENT,
CENTALTA,
CUENTA,
fecfac,
PAN,
NUMAUT,
NUMBOLETA,
SIAIDCD,
CODPAIS AS PAIS,
CASE WHEN CODPAIS=152 THEN 'NACIONAL' ELSE 'INTERNACIONAL' END AS NACIONAL, 
sucursal,
caja,
CODCOM,
NOMCOMRED,
codact,
desact,
CASE WHEN (SIGNO='-')  THEN 'NOTA CREDITO' ELSE 'COMPRA' END AS TRANSACCION, 
CODMAR,
INDTIPT,
DESTIPT,
TIPO_TARJETA,
LINEA,
TIPFRAN AS FRANQUICIA,
DESFRA,
TIPOFAC,
DESTIPFAC,
SIGNO,
0 as TOTCUOTAS,
'NC' AS FINANCIAMIENTO,
CASE WHEN SIGNO='-' THEN CAPITAL*(-1) ELSE CAPITAL END AS CAPITAL,
CASE WHEN SIGNO='-' THEN ENTRADA*(-1) ELSE ENTRADA END AS PIE,
0 as VALOR_CUOTA,
0 as MGFIN,
0 as IMPTOTAL,
0 as PORINT,
0 as PORINTCAR,
0 as NUMMESCAR,
0 AS I_DIFERIDO,
CASE WHEN SIGNO='-' THEN COMISION*(-1) ELSE COMISION END AS COMISION,
MODENTDAT,
IDTERM,
PRODUCTO
       
from connection to ORACLE( 
select 
cast(G.PEMID_GLS_NRO_DCT_IDE_K as INT) AS RUT,
G.PEMID_DVR_NRO_DCT_IDE as DV,
A.codent,
A.centalta,
A.cuenta,
A.codpais,
A.fecfac,
A.PAN,
A.NUMAUT,/*Número de autorización*/
A.NUMBOLETA,/*Número que asigna el Terminal en el momento de la operación.*/
A.SIAIDCD,
substr(A.sucursal,1,4) as sucursal,
substr(A.sucursal,5,4) as caja,
A.codcom,
A.nomcomred,
A.codact,
D.desact,
F.CODMAR,
F.INDTIPT,
J.DESTIPT,
CASE 
WHEN F.CODMAR=1 AND F.INDTIPT 	in (1,3,9,11) then 'TR'
WHEN F.CODMAR=2	 AND F.INDTIPT	in (1,6,7,10,14) then 'TAM'
WHEN F.CODMAR=2	 AND F.INDTIPT	in (8) then 'MASTERCARD DEBITO'
WHEN F.CODMAR=2	 AND F.INDTIPT	in (13) then 'DEBITO CTACTE'
WHEN F.CODMAR=2	 AND F.INDTIPT	in (12) then 'MASTERCARD CHEK'
WHEN F.CODMAR=4	 AND F.INDTIPT	in (1) then 'MAESTRO DEBITO' 
end 
as TIPO_TARJETA,
A.linea,
A.tipfran,/*Tipo de franquicia*/
I.DESFRA,
A.tipofac,/*Tipo de factura*/
E.DESTIPFAC,
E.INDNORCOR,/*Indicador de normal o correctora: 0 - Normal  1 – Correctora*/
E.signo,/*Signo del importe (+/-)*/
A.IMPFAC as CAPITAL, /*Importe de la factura*/
A.ENTRADA,/*Entrada: (pie). Importe que corresponde a la parte de la compra que el cliente abona en efectivo en cajA. Tiene carácter informativo*/
X.MODENTDAT,
X.IDTERM,
B.PRODUCTO,
coalesce ((C.impbrueco - C.impboneco),0) as COMISION /*(Importe bruto calculado por el concepto económico)-(IMPBONECO:Importe bonificado sobre el cálculo del concepto económico)*/

/*Movimientos del Extracto de Crédito*/
from GETRONICS.mpdt012 A
/*Autorizacines*/
left join GETRONICS.MPDT004 X ON A.SIAIDCD=X.SIAIDCD
/* relacion para obtener los datos del contrato a partir del movimiento */
left join GETRONICS.MPDT007 B ON (A.codent = B.codent and A.centalta=B.centalta and A.cuenta = B.cuenta)
/* relacion para obtener la descripción del codigo de actividad ISO */
left join GETRONICS.MPDT039 D ON (A.codent = D.codent and A.codact=D.codact)
/*relacion para obtener la marca y el tipo de tarjeta*/
left join GETRONICS.MPDT009 F ON (A.codent=F.CODENT AND A.centalta=F.centalta AND A.cuenta=F.cuenta AND A.pan=F.pan)
/*relacion para determinar el rut asociado al titular del contrato*/
left join BOPERS_MAE_IDE G ON G.PEMID_NRO_INN_IDE= B.identcli
/*relacion para poder filtrar las facturas de compras*/
left join GETRONICS.MPDT044 E ON (A.tipofac=E.tipofac and A.indnorcor=E.indnorcor ) /*Indicador de factura informativa (S/N)*/
/*Franquicias*/
LEFT JOIN GETRONICS.MPDT131 I ON (A.TIPFRAN = I.TIPFRAN AND I.CODIDIOMA='1')  
/* relacion para obtener los conceptos de comisiones asociadas al movimiento*/
left join GETRONICS.MPDT151 C ON (A.codent=C.codent and A.centalta= C.centalta and A.cuenta=C.cuenta and A.clamon=C.clamon and A.numextcta = C.numextcta and A.nummovext = C.nummovext and C.tipimp = 2 and C.codconeco= 200) 
/*Franquicias*/
LEFT JOIN GETRONICS.MPDT131 I ON (A.TIPFRAN=I.TIPFRAN AND I.CODIDIOMA='1')  
/*Tipos de Tarjeta*/
LEFT JOIN GETRONICS.MPDT026 J ON (J.codent=F.codent AND J.CODMAR=F.CODMAR AND J.INDTIPT=F.INDTIPT )  

/*filtros adicionales*/
where A.tipofac not in (210,115,117) /*210 RepactaciONes, 115 y 117 CARGO REGULARIZACION SIR */
/*AND A.CODCOM <> '000000000000001' para spos */
AND A.LINEA in ('0051') /* av */
AND A.indnorcor = 0
/*AND A.tipfran <> 9999 and A.tipfran <> 8006  and A.tipfran <> 0   se excluyen franquicias de ajustes */
and (E.tipofacsist = 1500 and A.indmovanu = 0)
AND A.fecfac BETWEEN  %str(%')&fechai.%str(%') AND %str(%')&fechaf.%str(%') /*aqui se debe indicar el rango de busqueda de transacciones revolving */

) 
;quit;

LIBNAME R_get ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017';

proc sql;
create table &libreria..TRX_AV_&Periodo. as
select 
D.RUT	,
D.DV,
D.CODENT	,
D.CENTALTA	,
D.CUENTA	,
D.PRODUCTO,
E.DESPROD,
D.LINEA	,
D.FECFAC,
D.TOTCUOTAS	,
D.CAPITAL ,
D.SUCURSAL as SUC,
input(D.SUCURSAL,best.) as SUCURSAL,
input(D.CAJA,best.) as N_CAJA,
D.NUMBOLETA	AS DOCUMENTO,
D.PORINT AS TASA_CAR,
D.PORINTCAR	AS TASA_DIFERIDO,
D.VALOR_CUOTA as CUOTA,
D.MGFIN AS INTERES,
D.BASE,
D.NUMMESCAR	AS DIFERIDO,
D.I_DIFERIDO,
D.PAN	,
D.NUMAUT	,
D.SIAIDCD	,
D.PAIS	,
D.NACIONAL	,
/*CODCOM,
NOMCOMRED,
CODACT,
DESACT,*/
D.TRANSACCION	,
D.CODMAR	,
D.INDTIPT	,
D.DESTIPT	,
D.TIPO_TARJETA	,
D.FRANQUICIA	,
D.DESFRA	,
D.TIPOFAC	,
D.DESTIPFAC	,
D.SIGNO	,
D.FINANCIAMIENTO	,
D.IMPTOTAL ,
D.COMISION,
CASE WHEN Linea='0051' THEN 'AV' ELSE 'OTRO' END AS LUGAR
 
from(
select A.*, 'CON CUOTA' AS BASE
from CUOTA_&Periodo. A
outer union corr
select B.*,'SIN CUOTA' AS BASE
from SINCUOTA_&Periodo. B 
outer union corr
select C.*,'NC' AS BASE
from NC_&Periodo. C
) d left join R_get.MPDT043 e
on d.producto=e.producto
;quit;



proc sql;
create table &libreria..TRX_AV_&Periodo. as
select 
RUT,
DV,
CODENT,
CENTALTA,
CUENTA,
PRODUCTO,
DESPROD AS TIPO_PDTO,
LINEA,
FECFAC,
TOTCUOTAS,
CAPITAL FORMAT= BEST.,
SUC,
SUCURSAL,
N_CAJA,
DOCUMENTO,
CASE WHEN N_CAJA is MISSING AND SUCURSAL NOT IN (1,63) THEN 'ATM'							
WHEN SUCURSAL = 1 AND N_CAJA=1 THEN 'HB' 							
WHEN SUCURSAL = 300 AND N_CAJA=1 THEN 'HB' 				
WHEN SUCURSAL = 400 AND N_CAJA=1 THEN 'APP'				
WHEN SUCURSAL = 1 AND N_CAJA=2000 THEN 'PF'				
WHEN SUCURSAL = 200 THEN 'MOVIL'				
WHEN SUCURSAL = 63 THEN 'BCO'							
WHEN N_CAJA =201 AND SUCURSAL = 6 THEN 'TLMK'/*NUEVO CANAL 25_06_2019 */				
WHEN N_CAJA >=200 AND SUCURSAL NOT IN (6,1,63,300,400) THEN 'TF'							
WHEN N_CAJA < 200 AND SUCURSAL NOT IN (6,1,63,300,400)THEN 'TV' 							
END AS VIA,
TASA_CAR FORMAT=COMMAX4.3,
TASA_DIFERIDO FORMAT=COMMAX4.3,
CUOTA FORMAT= BEST.,
INTERES FORMAT= BEST.,
BASE,
DIFERIDO,
&FECHA_PROCESO. as FEC_EX,
/*****************/
/**CAMPOS NUEVOS**/
/*****************/
I_DIFERIDO,
PAN,
NUMAUT,
SIAIDCD,
PAIS,
NACIONAL,
/*CODCOM,
NOMCOMRED,
CODACT,
DESACT,*/
TRANSACCION,
CODMAR,
INDTIPT,
DESTIPT,
TIPO_TARJETA,
FRANQUICIA,
DESFRA,
TIPOFAC,
DESTIPFAC,
SIGNO,
FINANCIAMIENTO,
IMPTOTAL,
COMISION,
LUGAR
FROM &libreria..TRX_AV_&Periodo.  
WHERE SUCURSAL <> 901
ORDER BY FECFAC DESCENDING
;quit;

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================        EXPORT_TO_AWS - INI          ===============================*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_ppff_trx_av,raw,sasdata,-1);

/*Exportación a AWS*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_ppff_trx_av,&libreria..trx_av_&Periodo.,raw,sasdata,-1);

/*==============================        EXPORT_TO_AWS - END          ===============================*/
/*==================================================================================================*/

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */

/*fecha proceso*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*preparacion envio correo*/
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_PPFF';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_1';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_2';
	SELECT EMAIL into :DEST_7 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PPFF_PM_AVANCE';

quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;	
%put &=DEST_6; %put &=DEST_7;


/*envio correo y adjunto archivo*/
data _null_;
FILENAME OUTBOX EMAIL
FROM	= ("&EDP_BI")
TO 		= ("&DEST_4","&DEST_5","&DEST_6","&DEST_7")
CC 		= ("&DEST_1","&DEST_2","&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso TRX_AV_ACTUAL_CIERRE");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "		Proceso TRX_AV_ACTUAL_CIERRE, ejecutado automáticamente con fecha: &fechaeDVN";  
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 05'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
