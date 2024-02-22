/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	      CARGOS_PAT			====================================*/
/* CONTROL DE VERSIONES
/* 		2021-04-09 -- V4 -- Alejandra M. -- Nueva Versión */
/* 		2021-03-26 -- V3 -- Alejandra M. -- Nueva Versión */

%let libreria=PUBLICIN; /*libreria donde se guardara la info*/


%macro cargos_pat_cierre(libreria,i);

%put ######## fecha de ejecucion ######;

DATA _null_;
datex = input(put(intnx('month',today(),-&i.,'end'),yymmn6. ),$10.);
Call symput("periodo", datex);
RUN;
%put &periodo;


%put############### NOMBRES COMERCIOS ###################;

PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table COMERCIOS  as 
select * 
from connection to ORACLE( 
select 
t1.TGDTG_GLS_CCN_K,
cast(t1.TGDTG_GLS_CCN_K as INT) COD_TG300,
t1.TGDTG_GLS_COO_UNO,
t1.TGDTG_GLS_LAR_UNO,
t1.TGDTG_FCH_ACL_REG,
t1.tgetg_cor_tbl_k,
t2.TGMDO_GLS_DOM 
from botgen_det_tbl_gra t1
LEFT JOIN BOTGEN_MOV_DOM t2
on t1.TGDTG_COD_COO_CIN=t2.TGMDO_COD_DOM_K
WHERE t1.tgetg_cor_tbl_k in (300,320) 
and t2.TGMMD_COD_MAC_DOM_K = 1925
) A
;QUIT;


%put ######## cargos pat &periodo. ######;

PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table cargos_pat  as 
select * 
from connection to ORACLE( 
SELECT 
cast(a2.PEMID_GLS_NRO_DCT_IDE_K as INT) RUT,
floor(cast(REPLACE(a.fectrn, '-') as INT)/100)  PERIODO,
a.FECTRN,
a.PAN,
CASE
WHEN SUBSTR(a.PAN,1,6) IN('628156') THEN 'CERRADA'
WHEN SUBSTR(a.PAN,1,6) IN('549070') AND cast(SUBSTR(a.PAN,1,7) as INT) >=5490702 THEN 'TAM CHIP'
WHEN SUBSTR(a.PAN,1,6) IN('549070') AND cast(SUBSTR(a.PAN,1,7) as INT) <5490702 THEN 'TAM'
WHEN SUBSTR(a.PAN,1,6) IN('525384') THEN 'MCD'
WHEN SUBSTR(a.PAN,1,4) IN('6392') THEN 'DEBITO'
ELSE 'OTRA' END  TIPO_TR,
a.Imptrn,
cast(a.codcom as INT)  Codigo,
a.CODACT,
a.CODENT,
a.CUENTA,
a.CENTALTA,
a.TIPFRAN
from GETRONICS.MPDT004  a 
INNER JOIN GETRONICS.MPDT007 a1 /*CONTRATO*/
ON (A.CODENT=a1.CODENT) AND (A.CENTALTA=a1.CENTALTA) AND (A.CUENTA=a1.CUENTA) 
INNER JOIN BOPERS_MAE_IDE a2 ON 
A1.IDENTCLI=a2.PEMID_NRO_INN_IDE


where UPPER(a.NOMCOM) LIKE '%TRANSBANK%'
AND a.INDCRUCE IN ('1','2')
AND a.CODRESPU IN ('000','900')
AND a.TIPFRAN in (7,1007)
AND a.indanul = 0
AND a.indnorcor = 0
AND a.TIPOFAC <> 15
and cast(REPLACE(a.fectrn, '-') as INT)>=100*&periodo.+01 
and cast(REPLACE(a.fectrn, '-') as INT)<=100*&periodo.+31 
  

) A
;QUIT;


%put ######## modificación codigos de comercio######;

PROC SQL;
create table CARGOS_PAT2 as
SELECT A.*,

case when substr(compress(put(Codigo,20.)),1,4)='5970' then input(substr(compress(put(Codigo,20.)),5,length(compress(put(Codigo,20.)))),best.)
else Codigo end as COD_COM

FROM CARGOS_PAT A
ORDER BY FECTRN;
QUIT;


%put ######## cruce final ######;

PROC SQL;
create table CARGOS_PAT_TAM as
SELECT a.*,
B.TGDTG_GLS_COO_UNO,
B.TGDTG_GLS_LAR_UNO,
B.TGMDO_GLS_DOM,b.TGDTG_FCH_ACL_REG

FROM CARGOS_PAT2 A 
LEFT JOIN COMERCIOS B
ON A.COD_COM=B.COD_TG300
ORDER BY FECTRN;
QUIT;


%put ######## guardado en duro ######;

proc sql;
create table &libreria..CARGOS_PAT_&periodo. as 
select 
RUT,
periodo,
FECTRN,
PAN,
TIPO_TR,
IMPTRN,
cod_com,
CODACT,
CODENT,
CUENTA,
CENTALTA,
TGDTG_GLS_COO_UNO,
TGDTG_GLS_LAR_UNO,
TGDTG_FCH_ACL_REG,
TGMDO_GLS_DOM
from CARGOS_PAT_TAM
WHERE IMPTRN>50
;QUIT;


%put ######## borrado de tablas de paso ######;

proc sql;
drop table COMERCIOS;
drop table cargos_pat;
drop table cargos_pat2;
drop table cargos_pat_tam;
;QUIT;



%mend  cargos_pat_cierre;

proc sql inobs=1 noprint;
select 
day(today()) as dia
into: dia
from publicin.lnegro_car
;QUIT;


%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

%if %eval(&dia.<=10) %then %do;

%cargos_pat_cierre(&libreria.,1);
%cargos_pat_cierre(&libreria.,0);

%end;
%else %do;
%cargos_pat_cierre(&libreria.,0);
%end;


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
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'ALEJANDRA_MARINAO';

SELECT EMAIL into :DEST_3 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';

SELECT EMAIL into :DEST_4 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';
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
SUBJECT="MAIL_AUTOM TEST: CIERRE CARGOS PAT %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso CIERRE CARGOS PAT, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put 'Tabla resultante en: publicin.cargos_pat_&periodo'; 
 put ;
 put 'Vers.4'; 
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
