/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	MCD_MAESTRO		================================*/
/* CONTROL DE VERSIONES
/* 2021-04-07 -- V1 -- Valentina M. --  
					-- Versión Original
*/

DATA _NULL_;
carga=put(intnx('day',today(),0,'same'), yymmddn8.);
fin=put(intnx('day',today(),-1,'same'), yymmddn8.);
periodo=put(intnx('month',today(),0,'same'), yymmn8.);
call symput("periodo",periodo);
call symput("carga",carga);
call symput("fin",fin);
run;

%put &carga;
%put &periodo;
%put &fin;

LIBNAME MPDT  ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME R_BOPERS ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME R_get ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017';

proc sql;
create table foto_panes_hoy  as 
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
panant,
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
from (
select 
B.PEMID_GLS_NRO_DCT_IDE_K  AS RUT,
A.CODENT,
A.CENTALTA,
A.CUENTA,
A.CALPART,
A.CODENT||A.CENTALTA||A.CUENTA as CTTO,
C.FECALTA as FECALTA_CTTO,
C.FECBAJA as FECBAJA_CTTO,
G.NUMPLASTICO,
G.PAN,
G.panant,
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
FROM mpdt.MPDT013 A /*CONTRATO de Tarjeta*/
INNER JOIN mpdt.MPDT007 C /*CONTRATO*/
ON (A.CODENT=C.CODENT) AND (A.CENTALTA=C.CENTALTA) AND (A.CUENTA=C.CUENTA) 
INNER JOIN R_BOPERS.BOPERS_MAE_IDE B ON 
INPUT(A.IDENTCLI,BEST.)=B.PEMID_NRO_INN_IDE
INNER JOIN mpdt.MPDT009 G /*Tarjeta*/ 
ON (A.CODENT=G.CODENT) AND (A.CENTALTA=G.CENTALTA) AND (A.CUENTA=G.CUENTA) AND (A.NUMBENCTA=G.NUMBENCTA)
INNER JOIN mpdt.MPDT063 H 
ON (G.CODENT=H.CODENT) AND (G.INDSITTAR=H.INDSITTAR)
LEFT JOIN mpdt.MPDT060 I 
ON (G.CODBLQ=I.CODBLQ)
where c.producto='08'
) 
;QUIT;
proc sql;
create table resumen as 
select 
input(compress(FECALTA_TR,'-'),best.) as fecha_alta,
floor (input(compress(FECALTA_TR,'-'),best.)/100 ) as periodo,
RUT,
CODENT,
CENTALTA,
CUENTA,
FECALTA_CTTO,
FECBAJA_CTTO,
PAN	,
PANANT,
INDULTTAR,
INDSITTAR,
DESSITTAR,
cod_bloq_tr
from foto_panes_hoy 
where ((PAN  is not null and 	PANANT is null) or 
substr(pan,1,6)='525384' and (substr(panant,1,6)='639229'))
and 	
substr(pan,1,6)='525384' 
and calculated fecha_alta =input("&fin",best.)
;QUIT;

proc sql;
create table entregable_&carga. as 
select distinct 
count(rut) as clientes,
fecha_alta
from resumen 
where substr(pan,1,6)='525384' and substr(panant,1,6)='639229' 
group by fecha_alta 
;quit; 

PROC EXPORT DATA=entregable_&carga.
   OUTFILE="/sasdata/users94/user_bi/migracion_mcd_&carga..csv" 
   DBMS=dlm; 
   delimiter=';'; 
   PUTNAMES=YES; 
RUN;

Filename myEmail EMAIL	
    Subject = "migracion mcd &carga."
    From    = "equipo_datos_procesos_bi@bancoripley.com"
    To      = ("cparedesp@bancoripley.com","carteagas@bancoripley.com")
    CC      = ("vmartinezf@bancoripley.com","sjaram@bancoripley.com","dvasquez@bancoripley.com")
	attach =("/sasdata/users94/user_bi/migracion_mcd_&carga..csv")
    Type    = 'Text/Plain';

Data _null_; File myEmail;
    PUT "Estimados,";
    PUT "Adjunto base de migracion MCD &carga..";
    PUT "Saludos.";
    PUT " ";
	PUT " ";
 	put 'Proceso Vers. 01'; 
 	PUT ;
	PUT ;
	PUT 'Atte.';
	Put 'Equipo Datos y Procesos BI';
	PUT ;
	PUT ;
	PUT ;
RUN;
