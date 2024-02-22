/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	UNIVERSO_PANES_DIARIO			================================*/
/* CONTROL DE VERSIONES
/* 
2022-11-21 -- V2 -- Alejandra M. -- Se agrega DESTIPT as Tipo_Tarjeta_RSAT, TIPO_TARJETA agrupacion en base al producto y se agrega el PANANT que es el PAN anterior
2021-01-21 -- V1 -- XIMENA Z. 	 -- Se crea proceso universo panes diario

INPUT:
REPORITF:
	BOPERS_ADM
	GETRONICS

OUTPUT:
RESULT.UNIVERSO_PANES

*/
/*==================================================================================================*/

/*	DECLARACIÓN VARIABLE TIEMPO Y LIBRER		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/
%let libreria=RESULT;

/*==================================================================================================*/
/*	INICIO CÓDIGO DEL PROGRAMA	PM	*/
LIBNAME R_BOPERS ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME R_get ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017';


DATA _null_;
periodo = input(put(intnx('month',today(),-1,'end'),yymmn6. ),$10.);
corte = put(intnx('month',today(),0,'begin'),yymmdd10.);

Call symput("periodo", periodo);
Call symput("corte", corte);

RUN;

%put &periodo;
%put &corte;

proc sql inobs=100;
create table ajaja as
select 
(LEFT(SUBSTR(PAN,13,4))) as PAN2,
PAN
from R_GET.MPDT009;
quit;
/*Tarjeta*/

PROC SQL;
	CREATE TABLE &libreria..UNIVERSO_PANES AS 
		SELECT INPUT(B.PEMID_GLS_NRO_DCT_IDE_K,BEST.) AS RUT,
			A.CODENT,A.CENTALTA,A.CUENTA,A.CALPART,
			CAT(A.CODENT,' ',A.CENTALTA,' ',A.CUENTA) as CTTO,
		CASE 
			WHEN C.FECBAJA = '0001-01-01' THEN 1 
			ELSE 0 
		END 
	AS T_CTTO_VIGENTE,
		C.FECALTA as FECALTA_CTTO,C.FECBAJA as FECBAJA_CTTO,
		G.CODMAR,
		G.INDTIPT,
		D.DESTIPT as Tipo_Tarjeta_RSAT, 
	CASE 
		WHEN G.CODMAR=1  AND G.INDTIPT in (1,3,9,11) then 'TR'
		WHEN G.CODMAR=2  AND G.INDTIPT in (1,6,7,10,14) then 'TAM' 
		WHEN G.CODMAR=2  AND G.INDTIPT in (8) then 'MASTERCARD DEBITO'
		WHEN G.CODMAR=2	 AND G.INDTIPT	in (13) then 'DEBITO CTACTE'
		WHEN G.CODMAR=2	 AND G.INDTIPT	in (12) then 'MASTERCARD CHEK'
		WHEN G.CODMAR=4  AND G.INDTIPT in (1) then 'MAESTRO DEBITO' 
	end 
as TIPO_TARJETA,
	G.NUMPLASTICO,G.PAN,G.PANANT,G.FECCADTAR,G.INDULTTAR,G.NUMBENCTA,
	G.FECALTA AS FECALTA_TR, G.FECBAJA AS FECBAJA_TR,
	G.INDSITTAR,H.DESSITTAR, G.FECULTBLQ, G.CODBLQ,
CASE 
	WHEN G.CODBLQ = 1 AND TEXBLQ = 'BLOQUEO TARJETA NO ISO'  THEN 'BLOQUEO TARJETA NO ISO' 
	WHEN G.CODBLQ = 1 AND TEXBLQ NOT IN ('BLOQUEO TARJETA NO ISO') THEN 'ROBO/CODIGO_BLOQUEO' 
	WHEN G.CODBLQ IN (79,98)  THEN 'CAMBIO DE PRODUCTO'
	WHEN G.CODBLQ IN (16,43)  THEN 'FRAUDE' 
	WHEN G.CODBLQ > 1 AND G.CODBLQ NOT IN (16,43,79,98) THEN DESBLQ 
END 
AS MOTIVO_BLOQUEO,
CASE 
	WHEN G.INDSITTAR=5 AND G.FECALTA<>'0001-01-01' AND G.FECBAJA='0001-01-01' AND G.CODBLQ=0 /*G.FECULTBLQ='0001-01-01'*/
	THEN 1 ELSE 0 END AS T_TR_VIG,
		(LEFT(SUBSTR(G.PAN,13,4))) as PAN2, 
			CAT(A.CODENT,A.CENTALTA,A.CUENTA,calculated PAN2) as CONTRATO_PAN
		FROM R_GET.MPDT013 A /*CONTRATO de Tarjeta*/
	INNER JOIN R_GET.MPDT007 C /*CONTRATO*/
	ON A.CODENT=C.CODENT AND A.CENTALTA=C.CENTALTA AND A.CUENTA=C.CUENTA 
	INNER JOIN R_BOPERS.BOPERS_MAE_IDE B ON INPUT(A.IDENTCLI,BEST.)=B.PEMID_NRO_INN_IDE
	INNER JOIN R_GET.MPDT009 G /*Tarjeta*/
	ON A.CODENT=G.CODENT AND A.CENTALTA=G.CENTALTA AND A.CUENTA=G.CUENTA AND A.NUMBENCTA=G.NUMBENCTA 
	INNER JOIN R_GET.MPDT063 H ON G.CODENT=H.CODENT AND G.INDSITTAR=H.INDSITTAR
		LEFT JOIN R_GET.MPDT060 I ON G.CODBLQ=I.CODBLQ
		LEFT JOIN R_GET.MPDT026 D ON G.codent = D.codent AND G.codmar = D.codmar AND G.INDTIPT = D.INDTIPT 
			ORDER BY calculated CTTO ASC,NUMPLASTICO DESC
	;
QUIT;


(A.CODENT,' ',A.CENTALTA,' ',A.CUENTA)
data sjaksj;
set result.universo_panes(obs=10);
run;



/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
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
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';

SELECT EMAIL into :DEST_2 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_CLIENTES';

SELECT EMAIL into :DEST_3 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';

SELECT EMAIL into :DEST_4
  FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_GOBIERNO_DAT_1';
quit;




%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_2","&DEST_3","&DEST_4")
SUBJECT="MAIL_AUTOM: UNIVESO_PANES_DIARIO - %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso UNIVESO_PANES_DIARIO, ejecutado con fecha: &fechaeDVN";  
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
