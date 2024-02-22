/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	COMPRAS_EN_CUOTAS	 		 	 ===============================*/

/* CONTROL DE VERSIONES
/* 2023-08-10 -- v04 -- Esteban P.	-- Se cambia export a AWS por script de división + export a S3.
/* 2023-06-09 -- v03 -- Esteban P	-- Se añade export a AWS para la tabla cuotas.
/* 2023-03-29 -- v02 -- Ale Marinao	-- Se agrega una variable por parte de Tecnocom que sería, 
									   el cálculo del Saldo Insoluto al momento del refinanciamiento.
/* 2023-03-29 -- v01 -- Ale Marinao	-- Original
/*

/* VARIABLE TIEMPO - INICIO */
%let tiempo_inicio= %sysfunc(datetime());
options validvarname=any;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

/*V1  :Query Cuotas version agrupada por Estado de la Cuota al momento de realizar la consulta
  V1.1:query Cuotas version agrupada por Estado de la Cuota y Motivo de baja del número de financiación
*/

%let LIBRERIA=RESULT;

DATA _null_;
	datef	= input(put(intnx('month',today(),-1,'end'	),yymmdd10.),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
	datex	= input(put(intnx('month',today(),-1,'end'	),yymmn6.),$6.); /*cambiar 0 a -1 para ver cierre mes anterior*/
	exec	= compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaf", datef);
	Call symput("Periodo", datex);
	Call symput("fechae",exec);
RUN;

%put &fechaf;
%put &Periodo;
%put &fechae;

PROC SQL;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table CUOTAS_&Periodo. as
select &fechae. as Fecha_eje,T.*
from connection to ORACLE( 
SELECT    
F.PEMID_GLS_NRO_DCT_IDE_K AS RUT,
F.PEMID_DVR_NRO_DCT_IDE AS DV,
C.CODENT, 
C.CENTALTA,
C.CUENTA, 
C.CLAMON, 
C.NUMFINAN, 
C.NUMOPECUO, 
A.SIAIDCD, 
A.LINEA, 
G.DESLINEA, 
B.PORINT, 
B.PORINTCAR, 
A.FECALTCOMP AS FECHA_COMPRA, 
A.TIPFRAN, 
A.CODCOM,
CASE WHEN A.TIPFRAN = 1 and A.LINEA IN ( '0050', '0053') THEN 'FUERA DE TIENDA'
WHEN A.TIPFRAN = 2 and A.LINEA IN ( '0050', '0053') THEN 'FUERA DE TIENDA'
WHEN A.TIPFRAN = 2 and A.LINEA IN ( '0051' )        THEN 'BANCO - AVANCE EN EFECTIVO '
WHEN A.TIPFRAN = 2 and A.LINEA IN ( '0052' )        THEN 'BANCO - SUPERAVANCE'
WHEN A.TIPFRAN = 4 and A.LINEA IN ( '0050', '0053') THEN 'TIENDA'
WHEN A.TIPFRAN = 4 and A.LINEA IN ( '0051')         THEN 'AVANCE EN TIENDA'
WHEN A.TIPFRAN = 4 and A.LINEA IN ( '0052')         THEN 'SUPER AVANCE EN TIENDA'
WHEN A.TIPFRAN = 6                                  THEN 'ERROR 1'
WHEN A.TIPFRAN = 7 and A.LINEA IN ( '0050', '0053') THEN 'FUERA DE TIENDA'
WHEN A.TIPFRAN = 8                                  THEN 'ERROR 2'
WHEN A.TIPFRAN = 9                                  THEN 'ERROR 2'
WHEN A.TIPFRAN = 1001                               THEN 'ERROR 3'
WHEN A.TIPFRAN = 1004 and A.LINEA = ( '0051' ) THEN 'AV'
WHEN A.TIPFRAN = 1004 and A.LINEA = ( '0052' ) THEN 'SAV'
WHEN A.TIPFRAN = 1007 and A.LINEA IN ( '0050', '0053') THEN 'FUERA DE TIENDA'
WHEN A.LINEA = '0057'                               THEN 'REPACTACION'
WHEN A.TIPFRAN = 8006                               THEN 'AJUSTES'
WHEN A.TIPFRAN = 9999                               THEN 'SOL. INCIDENCIAS'
END AS FRANQUICIA,
A.FECFAC AS FEC_FACTURACION, 
A.TIPOFAC,
B.TOTCUOTAS AS TOTAL_CUOTAS,
A.IMPFAC AS MONTO_PACTADO,
B.IMPINTTOTAL as INTERES_TOTAL,
SUM( C.IMPCAPITAL - C.IMPCAPAMORT ) AS INSOLUTO,
C.ESTCUO,
CASE
WHEN C.ESTCUO = 1 THEN 'PENDIENTE'
WHEN C.ESTCUO = 2 THEN 'LIQUIDADA'
WHEN C.ESTCUO = 3 THEN 'CANCELADA'
WHEN C.ESTCUO = 4 THEN 'VENCIDA'
WHEN C.ESTCUO = 98 THEN 'PRONTO PAGO'
WHEN C.ESTCUO = 99 THEN 'PAGO ANTICIPADO'
END  AS Def_ESTCUO,
A.ESTCOMPRA,
case when A.ESTCOMPRA='01' THEN 'Vigente'
when A.ESTCOMPRA='02' THEN 'Cancelada'
when A.ESTCOMPRA='03' THEN 'Amortizada o finalizada'
when A.ESTCOMPRA='04' THEN 'Fusión n compras'
when A.ESTCOMPRA='05' THEN 'Cancelada cartera-vencida'
when A.ESTCOMPRA='06' THEN 'Incidencia'
when A.ESTCOMPRA='07' THEN 'Refinanciada'
when A.ESTCOMPRA='08' THEN 'Acelerada'
ELSE '' end as Def_ESTCOMPRA,
B.FECALTA,
B.FECBAJA,
B.MOTBAJA,
case when B.MOTBAJA='01' THEN 'Amortización anticipada'
when B.MOTBAJA='02' THEN 'Modificación del número de cuotas'
when B.MOTBAJA='03' THEN 'Cancelación de compra'
when B.MOTBAJA='04' THEN 'Fusión de n compras en cuotas'
when B.MOTBAJA='05' THEN 'Cancelada por cartera-vencida'
when B.MOTBAJA='06' THEN 'Incidencia'
when B.MOTBAJA='07' THEN 'Refinanciada'
when B.MOTBAJA='08' THEN 'Acelerada'
ELSE '' end as Def_MOTBAJA,
SUM(1) AS DIF_CUOTAS, 
SUM(C.IMPCAPITAL) AS MONTO_PARCIAL,
SUM(C.IMPINTERESES) INTERES_PARCIAL, 
SUM(C.IMPIMPTO) AS IMPUESTO , 
SUM(D.IMPBRUECO - D.IMPBONECO) AS COMISION_PARCIAL
FROM MPDT205 A,MPDT206 B, MPDT207 C, MPDT208 D   ,MPDT007 E , BOPERS_ADM.BOPERS_MAE_IDE F, MPDT042 G
WHERE F.PEMID_NRO_INN_IDE = E.IDENTCLI 
    AND E.CODENT = A.CODENT 
    AND E.CENTALTA = A.CENTALTA
    AND E.CUENTA   = A.CUENTA 
/*AND A.CUENTA='100002063616'*/
/* CRUCE MPDT205 CON MPDT206*/
    AND A.CODENT = B.CODENT
    AND A.CENTALTA = B.CENTALTA
    AND A.CUENTA = B.CUENTA
    AND A.CLAMON = B.CLAMON
    AND A.NUMFINAN = B.NUMFINAN
    AND A.NUMOPECUO = B.NUMOPECUO
/*CRUCE MPDT205 CON MPDT207*/
    AND A.CODENT = C.CODENT
    AND A.CENTALTA = C.CENTALTA
    AND A.CUENTA = C.CUENTA
    AND A.CLAMON = C.CLAMON
    AND A.NUMFINAN = C.NUMFINAN
    AND A.NUMOPECUO = C.NUMOPECUO
   

/* CRUCE MPDT207 CON MPDT208*/
    AND C.CODENT = D.CODENT(+)
    AND C.CENTALTA = D.CENTALTA(+)
    AND C.CUENTA = D.CUENTA(+)
    AND C.CLAMON = D.CLAMON(+)
    AND C.NUMFINAN = D.NUMFINAN(+)
    AND C.NUMOPECUO = D.NUMOPECUO(+)
    AND C.NUMCUOTA = D.NUMCUOTA(+)
    AND G.LINEA = A.LINEA
	AND A.FECALTCOMP <= %str(%')&fechaf.%str(%') /*'2023-02-28'*/ 



GROUP BY F.PEMID_GLS_NRO_DCT_IDE_K,
F.PEMID_DVR_NRO_DCT_IDE,
C.CODENT,
C.CENTALTA,
C.CUENTA,
C.CLAMON,
C.NUMFINAN,
C.NUMOPECUO,
A.SIAIDCD,
A.LINEA,
G.DESLINEA,
B.PORINT,
B.PORINTCAR,
A.FECALTCOMP,
A.TIPFRAN,
A.CODCOM,
A.FECFAC,
A.TIPOFAC,
B.TOTCUOTAS,
A.IMPFAC,
B.IMPINTTOTAL,
C.ESTCUO,
A.ESTCOMPRA,
B.FECALTA,
B.FECBAJA,
B.MOTBAJA 

ORDER BY CUENTA, NUMOPECUO, NUMFINAN, ESTCUO
)T
;quit;


proc sql;
create table &libreria..CUOTAS_&Periodo. as 
select a.*,
cats(CODENT,'-',CENTALTA,'-',CUENTA) as CONTRATO
from CUOTAS_&Periodo. a
order by calculated CONTRATO, NUMOPECUO, NUMFINAN, ESTCUO desc
;quit;

/* EXPORT RAW AWS DIVIDIDO*/
%Let Periodo_Proceso=1; 		/* para correr un nuevo periodo CAMBIAR AQUÍ */

proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='CUOTAS_&Periodo.'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='CUOTAS_&Periodo.'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='CUOTAS_&Periodo.'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_ppff_cuotas,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select * from RESULT.CUOTAS_&Periodo.	/* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_ppff_cuotas,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);
