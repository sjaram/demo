/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	PROC_TRX_SAV_DIARIO				 ===============================*/
/* CONTROL DE VERSIONES
/* 2023-04-20 -- v10 -- Alejandra M.-- Actualizacion con la descripcion del producto (mpdt043) y actualizacion de TIPO_TARJETA
/* 2022-11-15 -- v09 -- Sergio J.   -- Se agrega campo periodo
/* 2022-11-10 -- v08 -- Alejandra M.-- Se quita campo IMPUESTO2
/* 2022-11-07 -- v07 -- Alejandra M.-- Actualización en la lógica:
									-- (*)TRX=TRX Neteadas (TRX de compras-TRX de Notas de crédito)
									-- (**) Clientes= Se consideran clientes distintos
									-- (***) Monto=Venta Neta(Monto Compra-Monto Nota de crédito)
/* 2022-08-02 -- v06 -- Sergio J. 	-- Conexión SAS/AWS para envío de archivos.
/* 2022-05-04 -- v05 -- Jose A. 	-- Se agrega línea para ver la venta de chek.
/* 2022-04-04 -- v04 -- Esteban P. 	-- Se actualizan los correos: Se saca el DEST_3 del TO y se reemplazan por los de CC.
/* 2021-08-06 -- v03 -- David V. 	-- Se comenta todo lo relacionado a HOMEBANKING
/* 2020-12-03 -- v02 -- David V. 	-- Agrega el Pan a la query
/* INFORMACIÓN:
	Transacciones de SAV.

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
/*%let libreria=RESULT;*/

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

/*========================================================================================================================*/
/*==================================	 PROC_TRX_SAV_DIARIO - VERSION 20200701 		==================================*/
/*========================================================================================================================*/

/************************* ADMISION ES UN COMPLEMETO DE TRX_SAV ************************************/
/*************PARA IDENTIFICAR TIPO DE DESEMBOLSO  RECALCULO  CUPO DE OFERTA  ETC*******************/
/*********esta informacion no esta en getronics( intancia oficial de transaccionabilidad)***********/


DATA _null_;
datehi	= compress(input(put(intnx('month',today(),0,'begin' ),yymmdd10.	),$20.),"-",c); /*cambiar 0 a -1 para ver cierre mes anterior*/
datehf	= compress(input(put(intnx('month',today(),0,'end'	),yymmdd10. 	),$20.),"-",c); /*cambiar 0 a -1 para ver cierre mes anterior*/
datei 	= input(put(intnx('month',today(),0,'begin' ),yymmdd10.	),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datef	= input(put(intnx('month',today(),0,'end'	),yymmdd10. ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
datex	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);
per = put(intnx('mONth',today(),0,'end'), yymmn6.);

Call symput("fechahi",datehi);
Call symput("fechahf",datehf);
Call symput("fechai", datei);
Call symput("fechaf", datef);
Call symput("fechae",exec);
Call symput("Periodo",per);
Call symput("fechax", datex);

RUN;

%put &fechahi; 
%put &fechahf; 
%put &fechai;  
%put &fechaf;  
%put &fechae;
%put &Periodo; 
%put &fechax; 
%let libreria=PUBLICIN;


/*======================================= CONEXIONES =====================================================================*/
LIBNAME SFA     ORACLE PATH='REPORITF.WORLD' SCHEMA='SFADMI_ADM' USER='JABURTOM'  PASSWORD='JABU#_1107' /*dbmax_text=7025*/;
LIBNAME R_bopers ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='JABURTOM' PASSWORD='JABU#_1107';
LIBNAME R_get  ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='JABURTOM'  PASSWORD='JABU#_1107';
LIBNAME BOTGEN ORACLE PATH='REPORITF.WORLD' SCHEMA='BOTGEN_ADM' USER='JABURTOM' PASSWORD='JABU#_1107';
/*========================================================================================================================*/

PROC SQL; 
   CREATE TABLE OFERTAS AS  
   SELECT t1.OFE_COD_NRO_SOL_K, 
          t1.OFE_COD_PRD_OFE_K,  
          t1.OFE_VLR_RTA_OFE, 
          t1.OFE_VLR_CUP_OFE,  
          t1.OFE_VLR_CUP_RCA, 
          t1.OFE_CAC_NRO_CTT, 
          t1.OFE_COD_IND_OFE,
          t1.OFE_COD_IND_SOL, 
          t1.OFE_VLR_CUP_SOL, 
          t1.OFE_FCH_INI_VIG, 
          t1.OFE_FCH_FIN_VIG, 
          t1.OFE_CAC_COD_CPS, 
          t1.OFE_GLS_DES_CPS, 
          t1.OFE_GLS_DES_OFE 
      FROM SFA.SFADMI_BCO_OFE t1 
       WHERE t1.OFE_COD_PRD_OFE_K = '050001' AND OFE_COD_IND_SOL = 1 
;QUIT; 

PROC SQL; 
   CREATE TABLE OFERTADOS_CURSE AS  
   SELECT t1.*,  
          t2.SOL_COD_EST_SOL, 
            t2.SOL_FCH_CRC_SOL, 
          t2.SOL_FCH_ALT_SOL, 
            t2.SOL_NRO_SUC_ORE AS NRO_SUCURSAL_ORIGEN, 
            t2.SOL_CAC_SUC_ADM AS SUCURSAL_ADMISION, 
            t2.SOL_COD_CLL_ADM, 
            t2.SOL_COD_CLL_SOL 
      FROM WORK.OFERTAS t1 
      INNER JOIN SFA.SFADMI_BCO_SOL t2 ON (t1.OFE_COD_NRO_SOL_K = t2.SOL_COD_NRO_SOL_K) 
;QUIT;

/*=========================================== PRE-APROBADOS ==========================================*/
PROC SQL; 
   CREATE TABLE CURSE_SAV_PA AS  
   SELECT t1.* 
   FROM WORK.OFERTADOS_CURSE t1 
   WHERE t1.SOL_COD_EST_SOL = 11 
;QUIT; 

PROC SQL; 
   CREATE TABLE CURSE_SAV_PA_1 AS  
   SELECT t1.*,  
          t2.PER_COD_IDE_CLI_K AS RUT 
   FROM WORK.CURSE_SAV_PA t1 
   INNER JOIN SFA.SFADMI_BCO_DAT_PER t2 ON (t1.OFE_COD_NRO_SOL_K = t2.PER_COD_NRO_SOL_K) 
;QUIT; 

PROC SQL; 
   CREATE TABLE CURSE_SAV_PA_2 AS  
   SELECT t1.*,  
          t2.PRD_VLR_CUP_SOL , input(compress(put(DATEPART(SOL_FCH_ALT_SOL),yymmdd10.),"-"),best.) AS FECHA_NUM
   FROM WORK.CURSE_SAV_PA_1 t1, SFA.SFADMI_BCO_PRD_SOL t2 
   WHERE (t1.OFE_COD_NRO_SOL_K = t2.PRD_COD_NRO_SOL_K AND t1.OFE_COD_PRD_OFE_K = t2.PRD_COD_TIP_PRD_K) 
;QUIT; 

PROC SQL;
CREATE TABLE CURSE_SAV_&PERIODO AS 
SELECT *
FROM WORK.CURSE_SAV_PA_2 t1
WHERE FECHA_NUM BETWEEN &fechahi AND &fechahf
;QUIT;

/*===================================================================================================*/
PROC SQL;
   CREATE TABLE TRX_ADM_0 AS 
   SELECT t1.RUT,
          INPUT( t1.RUT,BEST.) AS RUT_REAL,
          t1.OFE_COD_NRO_SOL_K, 
          t1.OFE_VLR_CUP_OFE FORMAT=BEST32., 
          t1.OFE_VLR_CUP_RCA FORMAT=BEST32.,  
          t1.PRD_VLR_CUP_SOL FORMAT=BEST32.,
            t1.SOL_FCH_ALT_SOL,
            t1.NRO_SUCURSAL_ORIGEN, 
          t1.SUCURSAL_ADMISION 
      FROM WORK.CURSE_SAV_&PERIODO t1;
QUIT;

PROC SQL;
   CREATE TABLE TRX_ADM_1 AS 
   SELECT t1.RUT, 
          t1.RUT_REAL, 
          t1.OFE_COD_NRO_SOL_K, 
          t1.OFE_VLR_CUP_OFE, 
          t1.OFE_VLR_CUP_RCA, 
          t1.PRD_VLR_CUP_SOL,
            t1.SOL_FCH_ALT_SOL,
          t1.NRO_SUCURSAL_ORIGEN, 
          t1.SUCURSAL_ADMISION,  
          t2.PRD_COD_TIP_PRD_K, 
          t2.PRD_CAC_DET_PRD, 
          t2.PRD_GLS_DES_PLN, 
          t2.PRD_GLS_DES_AFI
      FROM WORK.TRX_ADM_0 t1
           LEFT JOIN SFA.SFADMI_BCO_PRD_SOL t2 ON (t1.OFE_COD_NRO_SOL_K = t2.PRD_COD_NRO_SOL_K) AND (t1.PRD_VLR_CUP_SOL 
          = t2.PRD_VLR_CUP_SOL);
QUIT;

PROC SQL;
CREATE TABLE TRX_ADM_2 AS
SELECT t1.*, 
CASE  WHEN t1.PRD_CAC_DET_PRD CONTAINS 'EFECTIVO' THEN 'EFECTIVO'
      WHEN t1.PRD_CAC_DET_PRD CONTAINS 'TRANSFERENCIA EXTERNA MISMO RUT' THEN 'TRANSFERENCIA'
      ELSE 'TRANSFERENCIA' END AS TIPO_DESEMBOLSO

       FROM TRX_ADM_1 as t1
;
QUIT;

PROC SQL;
CREATE TABLE TRX_ADM_3 AS
SELECT t1.*,
(DATEPART(SOL_FCH_ALT_SOL))FORMAT=DDMMYY10. AS FECHA

FROM TRX_ADM_2 as t1
;
QUIT;


PROC SQL;
   CREATE TABLE BOTGEN_MAE_SUC AS 
   SELECT t1.*
      FROM BOTGEN.BOTGEN_MAE_SUC t1;
QUIT;

PROC SQL;
CREATE TABLE &Libreria..TRX_ADMISION_&PERIODO AS /*DURO*/ 
SELECT t1.*,
t2.TGMSU_NOM_SUC,
CASE  WHEN t1.SUCURSAL_ADMISION > 100 THEN 'BANCO_R' ELSE 'T_RIPLEY' END AS TIPO_SUC,
CASE  WHEN t1.TIPO_DESEMBOLSO = 'EFECTIVO' THEN 'CIS' ELSE 'TEF' END AS VIA
FROM WORK.TRX_ADM_3 t1
INNER JOIN BOTGEN_MAE_SUC t2 ON (t1.SUCURSAL_ADMISION = t2.TGMSU_COD_SUC_K)
;
QUIT;



/****************************************** GETRONIC SAV *********************************************/


PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table CUOTA_&Periodo. as
select RUT,
DV,
ID,
CODENT,
CENTALTA,
CUENTA,
FECFAC,
PAN	,
NUMAUT,
NUMBOLETA,
SIAIDCD,
CODPAIS AS PAIS,
CODTIPC,
CASE WHEN CODPAIS=152 THEN 'NACIONAL' ELSE 'INTERNACIONAL' END AS NACIONAL, 
SUCURSAL,
CAJA,
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
IMPUESTO,
ESTCOMPRA,
/*MOTBAJA,
FECBAJA,*/
PRODUCTO,
SUBPRODU,
NUMBENCTA
from connection to ORACLE( 
select 
cast(G.PEMID_GLS_NRO_DCT_IDE_K as INT) AS RUT,
G.PEMID_DVR_NRO_DCT_IDE as DV,
G.PEMID_NRO_INN_IDE as ID,
A.codent,
A.centalta,
A.cuenta,
A.fecfac,
A.PAN,
A.NUMAUT,
A.NUMBOLETA,
A.SIAIDCD,
A.CODPAIS,
A.CODTIPC,
substr(A.sucursal,1,4) as sucursal,
substr(A.sucursal,5,4) as caja,
A.CODCOM,
A.NOMCOMRED,
A.CODACT,
E.DESACT,
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
A.LINEA,
A.TIPFRAN,
I.DESFRA,
A.TIPOFAC,
H.DESTIPFAC,
H.INDNORCOR,
H.SIGNO,
A.IMPFAC as CAPITAL, 
C.IMPIMPTOTOT AS IMPUESTO, 
A.ESTCOMPRA,
A.ENTRADA,
C.TOTCUOTAS,
C.IMPCUOTA AS VALOR_CUOTA,
C.Impinttotal as MGFIN,
C.IMPTOTAL,
C.PORINT,
C.PORINTCAR,
C.NUMMESCAR,
C.MOTBAJA,
C.FECBAJA,
X.MODENTDAT,
X.IDTERM,
B.PRODUCTO,
B.SUBPRODU,
F.NUMBENCTA,
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
AND A.LINEA in ('0052') /* sav */
and A.tipfran <> 9999 and A.tipfran <> 8006  and A.tipfran <> 0 /*Estado 6 son trx que se van al modulo de incidencia y estan asociadas a estas franquicias, por eso se excluyen las franquicias de ajustes*/
AND A.fecfac BETWEEN  %str(%')&fechai.%str(%') AND %str(%')&fechaf.%str(%')  /*aqui se debe indicar el rango de busqueda de transacciones revolving*/
group by 
G.PEMID_GLS_NRO_DCT_IDE_K,
G.PEMID_DVR_NRO_DCT_IDE,
G.PEMID_NRO_INN_IDE,
A.codent,
A.centalta,
A.cuenta,
A.fecfac,
A.PAN,
A.NUMAUT,
A.NUMBOLETA,
A.SIAIDCD,
A.CODPAIS,
A.CODTIPC,
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
C.IMPIMPTOTOT,
A.ESTCOMPRA,
A.ENTRADA,
C.TOTCUOTAS,
C.IMPCUOTA,
C.Impinttotal,
C.IMPTOTAL,
C.PORINT,
C.PORINTCAR,
C.NUMMESCAR,
C.MOTBAJA,
C.FECBAJA,
X.MODENTDAT,
X.IDTERM,
B.PRODUCTO,
B.SUBPRODU,
F.NUMBENCTA

) 
;quit;



PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table NC_&Periodo. as
select RUT,
DV,
ID,
CODENT,
CENTALTA,
CUENTA,
fecfac,
PAN,
NUMAUT,
NUMBOLETA,
SIAIDCD,
CODPAIS AS PAIS,
'0000' as CODTIPC,
CASE WHEN CODPAIS=152 THEN 'NACIONAL' ELSE 'INTERNACIONAL' END AS NACIONAL, 
sucursal,
CAJA,
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
IMPIMPTO AS IMPUESTO,
0 as ESTCOMPRA,
PRODUCTO,
SUBPRODU,
NUMBENCTA

        
from connection to ORACLE( 
select 
cast(G.PEMID_GLS_NRO_DCT_IDE_K as INT) AS RUT,
G.PEMID_DVR_NRO_DCT_IDE as DV,
G.PEMID_NRO_INN_IDE as ID,
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
E.SIGNO,/*Signo del importe (+/-)*/
A.IMPFAC as CAPITAL, /*Importe de la factura*/
A.ENTRADA,/*Entrada: (pie). Importe que corresponde a la parte de la compra que el cliente abona en efectivo en cajA. Tiene carácter informativo*/
X.MODENTDAT,
X.IDTERM,
A.IMPIMPTO,
B.PRODUCTO,
B.SUBPRODU,
F.NUMBENCTA,
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
AND A.LINEA in ('0052') /* sav*/
AND A.indnorcor = 0
/*AND A.tipfran <> 9999 and A.tipfran <> 8006  and A.tipfran <> 0   se excluyen franquicias de ajustes */
and (E.tipofacsist = 1500 and A.indmovanu = 0)
AND A.fecfac BETWEEN  %str(%')&fechai.%str(%') AND %str(%')&fechaf.%str(%') /*aqui se debe indicar el rango de busqueda de transacciones revolving */

) 
;quit;

LIBNAME R_get ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017';

proc sql;
create table &libreria..APROB_SAV_&Periodo. as
select  INPUT (CAT((SUBSTR(D.FECFAC,1,4)),(SUBSTR(D.FECFAC,6,2)),(SUBSTR(D.FECFAC,9,2))),BEST.) AS PERIODO,
D.RUT	,
D.DV,
D.ID,
D.CODENT	,
D.CENTALTA	,
D.CUENTA	,
D.LINEA	,
D.FECFAC,
input(cat((SUBSTR(D.FECFAC,1,4)),(SUBSTR(D.FECFAC,6,2)),(SUBSTR(D.FECFAC,9,2))) ,BEST10.) AS FECHA1,
(MDY(INPUT(SUBSTR(PUT(CALCULATED FECHA1,BEST8.),5,2),BEST4.),
INPUT(SUBSTR(PUT(CALCULATED FECHA1,BEST8.),7,2),BEST4.),
INPUT(SUBSTR(PUT(CALCULATED FECHA1,BEST8.),1,4),BEST4.)) ) FORMAT=DDMMYY10. AS FECHA,
D.TOTCUOTAS	,
D.CAPITAL ,
INPUT(D.SUCURSAL,BEST.) as SUCURSAL,
INPUT(D.CAJA,BEST.) as CAJA,
D.NUMBOLETA	,
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
D.CODTIPC,
D.NACIONAL	,
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
D.IMPUESTO,
D.ESTCOMPRA,
CASE WHEN ESTCOMPRA=1 THEN 'Vigente'
WHEN ESTCOMPRA=2 THEN 'Cancelada'
WHEN ESTCOMPRA=3 THEN 'Amortizada o finalizada'
WHEN ESTCOMPRA=4 THEN 'Fusión compras'
WHEN ESTCOMPRA=5 THEN 'Cancelada cartera-vencida'
WHEN ESTCOMPRA=6 THEN 'Generada Incidencia'
WHEN ESTCOMPRA=7 THEN 'Refinanciada'
WHEN ESTCOMPRA=8 THEN 'Acelerada'
END AS DESESTCOMPRA,

D.PRODUCTO,
E.DESPROD,
D.SUBPRODU,
D.NUMBENCTA,

'SAV' AS LUGAR
 
from(
select A.*, 'CON CUOTA' AS BASE
from CUOTA_&Periodo. A
outer union corr
select C.*,'NC' AS BASE
from NC_&Periodo. C
) d left join R_get.MPDT043 e
on d.producto=e.producto
;quit;



proc sql;
create table APROB_SAV_&Periodo. as
select 
RUT,
DV,
CODENT,
CENTALTA,
CUENTA,
LINEA,
FECFAC,
input(cat((SUBSTR(FECFAC,1,4)),(SUBSTR(FECFAC,6,2)),(SUBSTR(FECFAC,9,2))) ,BEST10.) AS FECHA1,
     (MDY(INPUT(SUBSTR(PUT(CALCULATED FECHA1,BEST8.),5,2),BEST4.),
     INPUT(SUBSTR(PUT(CALCULATED FECHA1,BEST8.),7,2),BEST4.),
     INPUT(SUBSTR(PUT(CALCULATED FECHA1,BEST8.),1,4),BEST4.)) ) FORMAT=DDMMYY10. AS FECHA,

TOTCUOTAS,
ROUND(CAPITAL) FORMAT=BEST32.0 AS CAPITAL,
SUCURSAL,
CAJA,
CASE 
WHEN CODTIPC = '0030' AND CAJA >=200 AND SUCURSAL NOT IN (1,63,900,6) THEN 'TF'
WHEN CODTIPC = '0030' AND CAJA < 200 AND SUCURSAL NOT IN (1,63,900,6)THEN 'TV'
WHEN CODTIPC = '0035' AND SUCURSAL = 0 AND CAJA = 1 THEN 'TEF' /*CLIENTE VA A LA TIENDA Y LE TRASFIERE*/
WHEN CODTIPC = '0035' AND SUCURSAL = 1 AND CAJA = 1 THEN 'HOME_B' /*HOME BANKING*/
WHEN CODTIPC = '0035' AND SUCURSAL = 300 AND CAJA = 1 THEN 'HOME_B' /*HOME BANKING*/
WHEN CODTIPC = '0035' AND SUCURSAL = 400 AND CAJA = 1 THEN 'APP' /*HOME BANKING*/
WHEN CODTIPC = '0036' AND SUCURSAL = 100 AND CAJA = 1 THEN 'SAV_CENTER' /*SAV_CENTER*/
WHEN CODTIPC = '0035' AND SUCURSAL = 200 AND CAJA = 1 AND TIPOFAC = 1652 THEN 'MOVIL' /*MOVIL TDA*/
WHEN SUCURSAL IN (6,900) THEN 'TLMK' /*CCR TRANFERENCIA*/
WHEN SUCURSAL = 63 THEN 'BCO'
WHEN CODTIPC = '0035' AND SUCURSAL = 500 AND CAJA = 1 AND TIPOFAC = 1652 THEN 'CHEK'
WHEN SIGNO='-' THEN 'NC'
END AS VIA,
TASA_CAR FORMAT=COMMAX4.3,
TASA_DIFERIDO FORMAT=COMMAX4.3,
ROUND(CUOTA) FORMAT=BEST32.0 AS CUOTA, 
/*
(INTERES) FORMAT=BEST32.0 AS INTERES1, 
ROUND(T1.IMPUESTO) FORMAT=BEST32.0 AS IMPUESTO1, 
*/

INTERES,
BASE,
DIFERIDO,
I_DIFERIDO,
PAN,
NUMAUT,
SIAIDCD,
PAIS,
NACIONAL,
CODTIPC,
PRODUCTO,
DESPROD AS TIPO_PDTO,
IMPUESTO,
ESTCOMPRA,
NUMBOLETA,
ID,
DESESTCOMPRA,
SUBPRODU,
NUMBENCTA,
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
FROM &libreria..APROB_SAV_&Periodo.
/*AMARINAO.APROB_SAV_202209*/
WHERE SUCURSAL <> 901
ORDER BY FECFAC ASC
;quit;


PROC SQL;
CREATE TABLE CRUCE_SAV AS
SELECT DISTINCT t1.*,
t2.PRD_VLR_CUP_SOL,
t2.OFE_VLR_CUP_OFE,
t2.OFE_VLR_CUP_RCA, 
t2.SOL_FCH_ALT_SOL, 
t2.SUCURSAL_ADMISION, 
t2.TIPO_DESEMBOLSO, 
t2.TIPO_SUC, 
t2.VIA AS VIA1 
FROM APROB_SAV_&Periodo. t1
LEFT JOIN &libreria..TRX_ADMISION_&PERIODO T2
ON (t1.FECHA = t2.FECHA) AND (t1.RUT = t2.RUT_REAL)
;QUIT;

PROC SQL;
        CREATE TABLE CRUCE_SAV1 AS 
        SELECT t1.*,
               t1.VIA AS VIA_FINAL
           FROM WORK.CRUCE_SAV t1;
     QUIT;


	 
PROC SQL;
     UPDATE CRUCE_SAV1
     SET VIA_FINAL = 'CIS'
     WHERE VIA1 = 'CIS'
     AND VIA_FINAL = 'TF'
     ;
     UPDATE CRUCE_SAV1
     SET VIA_FINAL = 'CIS'
     WHERE VIA1 = 'CIS'
     AND VIA_FINAL = 'BCO'
     ;
     UPDATE CRUCE_SAV1
     SET VIA_FINAL = 'CIS'
     WHERE VIA1 = 'CIS'
     AND VIA_FINAL = 'TLMK'
     ;
     QUIT;

     PROC SQL;
     UPDATE CRUCE_SAV1
     SET VIA_FINAL = 'TEF'
     WHERE VIA1 = 'TEF'
     AND VIA_FINAL = 'TF'
     ;
     UPDATE CRUCE_SAV1
     SET VIA_FINAL = 'TEF'
     WHERE VIA1 = 'TEF'
     AND VIA_FINAL = 'TF'
     ;
     QUIT;

     PROC SQL;
     UPDATE CRUCE_SAV1
     SET VIA_FINAL = 'TEF'
     WHERE VIA1 = 'TEF'
     AND VIA_FINAL = 'HOME_B'
     AND VIA = 'HOME_B'
     ;
     QUIT;

PROC SQL;
        CREATE TABLE TRX_SAV AS 
        SELECT t1.*
           FROM WORK.CRUCE_SAV1 t1;
     QUIT;

PROC SQL;
     UPDATE TRX_SAV
     SET VIA_FINAL = 'BCO'
     WHERE SUCURSAL IN (0,63) 
     AND SUCURSAL_ADMISION > 100
     AND VIA_FINAL IN ('CIS','TEF')
     ;
     QUIT;

PROC SQL;
     UPDATE TRX_SAV
     SET VIA_FINAL = 'BCO'
     WHERE SUCURSAL = 63 
     AND VIA_FINAL = 'CIS'
     ;
     QUIT;
          
PROC SQL;
   CREATE TABLE SAV_APROBADO_&Periodo AS 
   SELECT t1.RUT_REAL, 
          t1.SAV_APROBADO_FINAL, 
          t1.MONTO_PARA_CANON AS OFERTA_SAV_APROBADO,
          'FUSION' AS MARCA_OFERTA,
          t1.CUENTA,
          t1.CENTALTA 
      FROM JABURTOM.SAV_CAR_&Periodo t1
      WHERE t1.SAV_APROBADO_FINAL = 1
;
QUIT;

/*PROC SQL;
   CREATE TABLE SAV_APROBADO_INCREM_&fechax AS 
   SELECT t1.RUT_REAL, 
          t1.SAV_APROBADO_FINAL, 
          t1.MONTO_PARA_CANON AS OFERTA_SAV_APROBADO,
          'INCREMENTALES' AS MARCA_OFERTA,
          t1.CUENTA,
          t1.CENTALTA 
      FROM JABURTOM.SAV_CAR_INCREM_&fechax t1
      WHERE t1.SAV_APROBADO_FINAL = 1
;
QUIT;*/

PROC SQL;
CREATE TABLE SAV_APROBADO_FINAL_&Periodo AS
SELECT * 
FROM SAV_APROBADO_&Periodo
/*OUTER UNION CORR
SELECT * FROM SAV_APROBADO_INCREM_&fechax*/
;
QUIT;


PROC SQL;
CREATE TABLE TRX_SAV_&Periodo AS 
SELECT t1.*,
        t2.OFERTA_SAV_APROBADO 
        FROM  TRX_SAV t1
        LEFT JOIN SAV_APROBADO_FINAL_&Periodo t2 ON (t1.CUENTA = t2.CUENTA) AND (t1.RUT = t2.RUT_REAL) AND (t1.CENTALTA = t2.CENTALTA)
     ;
QUIT;


     PROC SQL;
     UPDATE TRX_SAV_&Periodo
     SET VIA_FINAL = 'CIS'
     WHERE VIA_FINAL = 'TF'
     AND CAPITAL > 1120000
     ;
     QUIT;

 
     PROC SQL;
     UPDATE TRX_SAV_&Periodo
     SET VIA_FINAL = 'BCO'
     WHERE VIA_FINAL is missing
     AND SUCURSAL = 1 
     AND CAJA = 1
     ;
     QUIT;
     
	PROC SQL;
	UPDATE TRX_SAV_&Periodo
	SET VIA_FINAL = 'CHEK'
	WHERE VIA = 'CHEK'
	AND SUCURSAL = 500
	AND CAJA = 1
	;
	QUIT;

	
   
/*** Incorpora PD y tramo PD ***/


PROC SQL;
   CREATE TABLE TRX_SAV_&Periodo AS 
   SELECT t1.*, 
		  t2.PD_SAV_FINAL
      FROM WORK.TRX_SAV_&Periodo t1
		   LEFT JOIN PUBLICRI.PD_SAV_UNIF_&Periodo t2 ON (t1.RUT = t2.RUT_REGISTRO_CIVIL)
;
QUIT;


options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/

PROC SQL;
CREATE TABLE TRX_SAV_&fechax AS
SELECT*,
SB_Tramificar(PD_SAV_FINAL,0.01,0,0.50,'%') as Tramo_pd_Final
FROM TRX_SAV_&Periodo
;
QUIT;
     
PROC SQL;
   CREATE TABLE &LIBRERIA..TRX_SAV_&Periodo AS 
   SELECT t1.CENTALTA, 
t1.CUENTA, 
t1.CODTIPC, 
t1.TIPOFAC, 
t1.PRODUCTO,
t1.TIPO_PDTO,
t1.LINEA, 
t1.FECFAC, 
t1.TOTCUOTAS, 
t1.DIFERIDO, 
t1.TASA_DIFERIDO, 
t1.TASA_CAR, 
t1.CAPITAL, 
t1.CUOTA, 
t1.INTERES, 
t1.IMPUESTO, 
t1.SUCURSAL, 
t1.CAJA, 
t1.ESTCOMPRA, 
t1.NUMBOLETA,
t1.PAN, 
t1.ID, 
t1.RUT, 
input(compress(t1.FECFAC,'-',),best8.) as PERIODO,
t1.VIA, 
t1.FECHA, 
t1.PRD_VLR_CUP_SOL, 
t1.OFE_VLR_CUP_OFE, 
t1.OFE_VLR_CUP_RCA, 
t1.SOL_FCH_ALT_SOL, 
t1.SUCURSAL_ADMISION, 
t1.TIPO_DESEMBOLSO, 
t1.TIPO_SUC,
t1.VIA1, 
t1.VIA_FINAL, 
t1.OFERTA_SAV_APROBADO,
t1.PD_SAV_FINAL,
t1.Tramo_pd_Final,
/*campos nuevos*/
T1.BASE,
T1.CODENT,
T1.SIGNO,
T1.I_DIFERIDO,
T1.NUMAUT,
T1.SIAIDCD,
T1.PAIS,
T1.CODTIPC,
T1.NACIONAL,
T1.TRANSACCION,
T1.CODMAR,
T1.INDTIPT,
T1.DESTIPT as Tipo_Tarjeta_RSAT,
T1.TIPO_TARJETA,
T1.FRANQUICIA,
T1.DESFRA,
T1.DESTIPFAC,
T1.SIGNO,
T1.FINANCIAMIENTO,
T1.IMPTOTAL,
T1.COMISION,
T1.DESESTCOMPRA,
T1.SUBPRODU,
T1.NUMBENCTA,
T1.LUGAR

FROM WORK.TRX_SAV_&Periodo t1;
QUIT;

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================        EXPORT_TO_AWS - INI          ===============================*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_ppff_trx_sav,raw,sasdata,0);

/*Exportación a AWS*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_ppff_trx_sav,&libreria..trx_sav_&periodo,raw,sasdata,0);

/*==============================        EXPORT_TO_AWS - END          ===============================*/
/*==================================================================================================*/


/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*	VARIABLE TIEMPO	- FIN	*/;
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
%put &=DEST_6; &=DEST_7;


/*envio correo y adjunto archivo*/
data _null_;
FILENAME OUTBOX EMAIL
FROM	= ("&EDP_BI")
TO 		= ("&DEST_4","&DEST_5","&DEST_6","&DEST_7")
CC 		= ("&DEST_1","&DEST_2","&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso PROC_TRX_SAV_DIARIO");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso PROC_TRX_SAV_DIARIO, ejecutado con fecha: &fechaeDVN";  
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 10'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
