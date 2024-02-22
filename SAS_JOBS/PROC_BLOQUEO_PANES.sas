/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROC_BLOQUEO_PANES 			================================*/
/* CONTROL DE VERSIONES
/* 2020-09-28 ---- Original Generado por Pedro Muñoz
*/
/*==================================================================================================*/

/*macro que extrae la información de los bloqueos diarios*/

%let libreria = RESULT;

%macro bloqueos_diarios(lib);

%put==================================================================================================;
%put [01] MACRO FECHAS;
%put==================================================================================================;

DATA _null_;
periodo = input(put(intnx('month',today(),0,'end'),yymmn6. ),$10.);
periodo_ant = input(put(intnx('month',today(),-1,'end'),yymmn6. ),$10.);
corte = put(intnx('day',today(),-1,'same'),yymmddn8.);
hoy=put(intnx('month',today(),0,'same'),date9.);

Call symput("periodo", periodo);
Call symput("periodo_ant",periodo_ant );
Call symput("corte", corte);
Call symput("hoy", hoy);

RUN;

%put &periodo_ant;
%put &periodo;
%put &corte;
%put &hoy;

%put==================================================================================================;
%put [02] EXISTENCIA DE TABLAS;
%put==================================================================================================;

%if (%sysfunc(exist(&lib..bloqueo_pan_&periodo.))) %then %do;

%end;
%else %do;

PROC SQL;
CREATE TABLE &lib..bloqueo_pan_&periodo. (
RUT num, 
CODENT char(99), 
CENTALTA char(99), 
CUENTA char(99), 
CALPART char(99), 
CTTO char(99), 
T_CTTO_VIGENTE num, 
FECALTA_CTTO char(99), 
FECBAJA_CTTO char(99), 
TIPO_TR char(99), 
NUMPLASTICO num, 
PAN  char(99), 
FECCADTAR num , 
INDULTTAR  char(99), 
NUMBENCTA num , 
FECALTA_TR  char(99), 
FECBAJA_TR  char(99), 
INDSITTAR num , 
DESSITTAR  char(99), 
FECULTBLQ  char(99), 
cod_bloq_tr num , 
MOTIVO_BLOQUEO  char(99), 
T_TR_VIG num , 
PAN2 char(99) , 
CONTRATO_PAN  char(99))
;QUIT;

%end;

%put==================================================================================================;
%put [03] Extraer bloqueos del dia &corte.;
%put==================================================================================================;

PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table Panes_bloqueados  as 
select 
RUT,
CODENT,
CENTALTA,
CUENTA,
CALPART,
CTTO,
CASE WHEN FECBAJA_CTTO = '0001-01-01' THEN 1 ELSE 0 END AS T_CTTO_VIGENTE,
FECALTA_CTTO,
FECBAJA_CTTO,
CASE WHEN SUBSTR(PAN,1,6) IN('628156') THEN 'CERRADA'
WHEN SUBSTR(PAN,1,4) IN('6392') THEN 'CUENTA VISTA'
when substr(pan,1,6) in ('525384') then 'CUENTA VISTA'
WHEN SUBSTR(PAN,1,6) IN('549070')AND INPUT(LEFT(SUBSTR(PAN,1,7)),BEST.) >=5490702 THEN 'TAM CHIP' 
WHEN SUBSTR(PAN,1,6) IN('549070')AND INPUT(LEFT(SUBSTR(PAN,1,7)),BEST.) <5490702 THEN 'TAM' 
ELSE 'CERRADA' END AS TIPO_TR, 
NUMPLASTICO,
PAN,
FECCADTAR,
INDULTTAR,
NUMBENCTA,
 FECALTA_TR,
FECBAJA_TR,
INDSITTAR,
DESSITTAR,
FECULTBLQ,
CODBLQ as cod_bloq_tr,
CASE WHEN CODBLQ = 1 AND TEXBLQ = 'BLOQUEO TARJETA NO ISO'  THEN 'BLOQUEO TARJETA NO ISO' 
WHEN CODBLQ = 1 AND TEXBLQ NOT IN ('BLOQUEO TARJETA NO ISO') THEN 'ROBO/CODIGO_BLOQUEO' 
WHEN CODBLQ IN (79,98)  THEN 'CAMBIO DE PRODUCTO'
WHEN CODBLQ IN (16,43)  THEN 'FRAUDE' 
WHEN CODBLQ > 1 AND CODBLQ NOT IN (16,43,79,98) THEN DESBLQ END AS MOTIVO_BLOQUEO,
CASE WHEN INDSITTAR=5 AND FECALTA_TR<>'0001-01-01' AND FECBAJA_TR='0001-01-01' AND CODBLQ=0 
THEN 1 ELSE 0 END AS T_TR_VIG,
PAN2, 
CONTRATO_PAN

from connection to ORACLE(
select 
cast(B.PEMID_GLS_NRO_DCT_IDE_K as INT) AS RUT,
A.CODENT,
A.CENTALTA,
A.CUENTA,
A.CALPART,
A.CODENT||A.CENTALTA||A.CUENTA as CTTO,
C.FECALTA as FECALTA_CTTO,
C.FECBAJA as FECBAJA_CTTO,

G.NUMPLASTICO,
G.PAN,
G.FECCADTAR,
G.INDULTTAR,
G.NUMBENCTA,
G.FECALTA AS FECALTA_TR,
G.FECBAJA AS FECBAJA_TR,
G.INDSITTAR,
H.DESSITTAR,
G.FECULTBLQ,
g.CODBLQ,
g.TEXBLQ,
I.DESBLQ,
SUBSTR(G.PAN,13,4) as PAN2, 
A.CODENT||A.CENTALTA||A.CUENTA|| SUBSTR(G.PAN,13,4)  as CONTRATO_PAN
FROM MPDT013 A /*CONTRATO de Tarjeta*/
INNER JOIN MPDT007 C /*CONTRATO*/
ON (A.CODENT=C.CODENT) AND (A.CENTALTA=C.CENTALTA) AND (A.CUENTA=C.CUENTA) 
INNER JOIN BOPERS_MAE_IDE B ON 
A.IDENTCLI=B.PEMID_NRO_INN_IDE
INNER JOIN MPDT009 G /*Tarjeta*/ 
ON (A.CODENT=G.CODENT) AND (A.CENTALTA=G.CENTALTA) AND (A.CUENTA=G.CUENTA) AND (A.NUMBENCTA=G.NUMBENCTA)
INNER JOIN MPDT063 H 
ON (G.CODENT=H.CODENT) AND (G.INDSITTAR=H.INDSITTAR)
LEFT JOIN MPDT060 I 
ON (G.CODBLQ=I.CODBLQ)
where
cast(REPLACE(G.FECULTBLQ, '-') as INT)=&corte.  and 
g.CODBLQ<>0
) 
;QUIT;


%put==================================================================================================;
%put [04] Insertar del día &corte.;
%put==================================================================================================;

proc sqL noprint inobs=1 ;
select 
day("&hoy."d) as hoy_num
into:hoy_num
from pmunoz.codigos_capta_cdp
;QUIT;

%let hoy_num=&hoy_num;
%put &hoy_num;


%if %eval(&hoy_num.=1) %then %do;

proc sql;
delete *
from &lib..bloqueo_pan_&periodo_ant.
where input(compress(FECULTBLQ,'-','p'),best.)=&corte.
;QUIT;

proc sql;
insert into &lib..bloqueo_pan_&periodo_ant.
select 
*
from Panes_bloqueados 
;QUIT;

%end;
%else %do;

proc sql;
delete *
from &lib..bloqueo_pan_&periodo.
where input(compress(FECULTBLQ,'-','p'),best.)=&corte.
;QUIT;

proc sql;
insert into &lib..bloqueo_pan_&periodo.
select 
*
from Panes_bloqueados 
;QUIT;

%end;

%put==================================================================================================;
%put [05] BOrrar de table de paso ;
%put==================================================================================================;

proc sql;
drop table Panes_bloqueados;
;QUIT;

%mend bloqueos_diarios;


%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

%bloqueos_diarios(&libreria.);

data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */


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
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';

	SELECT EMAIL into :DEST_3 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_2","&DEST_3")
SUBJECT="MAIL_AUTOM: Bloqueo Panes %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso Bloqueo de Panes, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put ; 
 put ; 
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
