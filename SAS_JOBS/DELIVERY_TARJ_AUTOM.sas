

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

options validvarname=any;

%LET LIBRERIA=RESULT;


DATA _null_;
INI = input(put(intnx('month',Today(),-1,'begin'),date9. ),$10.);
FIN = input(put(intnx('day',intnx('month',Today(),-1,'same'),-1,'begin'),date9. ),$10.);
periodo = input(put(intnx('month',Today(),-1,'same'),yymmn6. ),$10.);
periodo_ant = input(put(intnx('month',Today(),-2,'same'),yymmn6. ),$10.);
periodo_ant2 = input(put(intnx('month',Today(),-3,'same'),yymmn6. ),$10.);
INI_FISA = put(intnx('day',Today(),-1,'begin'),ddmmyy10.);
FIN_FISA = put(intnx('day',intnx('day',Today(),0,'same'),0,'begin'),ddmmyy10.);
INI_NUM=put(intnx('day',today(),-1,'begin'), yymmddn8.);
fec_proceso=put(intnx('day',today(),0,'same'), yymmddn8.);

Call symput("INI", INI);
Call symput("FIN", FIN);
Call symput("periodo", periodo);
Call symput("periodo_ant", periodo_ant);
Call symput("periodo_ant2", periodo_ant2);
Call symput("INI_FISA", INI_FISA);
Call symput("FIN_FISA", FIN_FISA);
Call symput("INI_NUM", INI_NUM);
call symput("fec_proceso",fec_proceso);

RUN;
%PUT &INI_FISA;
%PUT &FIN_FISA;
%PUT &INI_NUM;
%put &fec_proceso;



%PUT ###CURSE CAPTA ONLINE CREDITO &periodo. ###;
/* CURSE TOTAL NUEVOS + DORMIDOS*/
PROC SQL ;
CONNECT TO ORACLE AS REPORTITF (PATH="REPORITF.WORLD" USER='KMARTINEZ' PASSWORD='kmar2102');
CREATE TABLE CURSE AS 
SELECT * FROM CONNECTION TO REPORTITF(
SELECT 
DISTINCT TAR.TAR_CAC_NRO_CTT_K NUMERO_CONTRATO, 
TAR.TAR_CAC_NRO_PAN_K NUMERO_TARJETA,
 SOL.SOL_COD_IDE_CLI RUT_CLIENTE, 
SOL.SOL_FCH_ALT_SOL FECHA_SOLICITUD, 
SOL.SOL_COD_NRO_SOL_K NUMERO_SOLICITUD,
sol.sol_cod_est_sol ESTADO, 
SEG.SEG_CAC_SEG_DES GLOSASEGURO,
FLJ.FLJ_COD_NRO_ETA_ACT||' - '||ETA.ETA_CAC_NOM_ETA AS ETAPA, 
DECODE(FLJ.FLJ_COD_NRO_ETA_ACT,50, '8', '103',8,'60',9,'104',9,3,'8','4',9,sol.sol_cod_est_sol ) ESTADO_FINAL,
CASE WHEN SOL_COD_IND_CU = 0 THEN 'SIN CLAVE UNICA' ELSE 'CLAVE UNICA EXITOSA' END AS CLAVE,
DECODE(SOL_COD_CLL_ACT,3,'ADMISION',14,'ONLINE',9,'MOVIL',SOL_COD_CLL_ACT) ULTIMO_CANAL,
TAR.TAR_COC_PRD,
TAR.TAR_COC_SUB_PRD
FROM SFADMI_BCO_SOL SOL 
INNER JOIN SFADMI_BCO_TAR TAR
ON TAR.TAR_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
LEFT OUTER  JOIN SFADMI_BCO_SEG_ASC SEG
ON  SOL.SOL_COD_NRO_SOL_K = SEG.SEG_COD_NRO_SOL_K
AND SEG_CAC_SEG_CHK = 1
LEFT OUTER  JOIN SFADMI_BCO_FIR_DCT_SOL FIR
ON  SOL.SOL_COD_NRO_SOL_K = FIR.FIR_COD_NRO_SOL_K
AND FIR.FIR_COD_FIR_IDE_K BETWEEN 500 AND 600
AND FIR.FIR_COD_SEG_IDE_SEG IS NOT NULL 
INNER JOIN SFADMI_BCO_WFW_FLJ_SOL FLJ
  ON SOL.SOL_COD_NRO_SOL_K = FLJ.FLJ_COD_NRO_SOL_K
INNER JOIN SFADMI_BCO_WFW_ETA ETA
ON ETA.ETA_COD_NRO_ETA_K = FLJ.FLJ_COD_NRO_ETA_ACT
AND ETA.ETA_COD_NRO_FLJ_K = FLJ.FLJ_COD_NRO_FLJ_ACT
WHERE 

SUBSTR(TAR.TAR_COD_TIP_PRD_K,1,2) = '01'
AND SOL_FCH_CRC_SOL BETWEEN to_date(%str(%')&ini_fisa.%str(%'),'dd/mm/yyyy') and 
to_date(%str(%')&fin_fisa.%str(%'),'dd/mm/yyyy')
AND (SOL.SOL_COD_CLL_ACT = 14 OR SOL.SOL_COD_CLL_ANT = 14)
AND SOL.SOL_COD_CLL_ADM = 2
AND EXISTS (SELECT BTC_COD_NRO_SOL_K
FROM SFADMI_BCO_BTC_SOL
WHERE BTC_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
AND BTC_COD_TIP_REG_K = 1
AND BTC_COD_ETA_K = 102
AND BTC_COD_EVT_K = 30)

ORDER BY  SOL.SOL_COD_NRO_SOL_K ASC
)A
;QUIT;

%PUT ###agrupacion de curse por tipo ###;

LIBNAME MPDT ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='JABURTOM'  PASSWORD='JABU#_1107';


proc sql;
create table CURSE_SALIDA as 
select distinct
NUMERO_CONTRATO,
NUMERO_TARJETA,
input(RUT_CLIENTE,best.) as rut,
datepart(FECHA_SOLICITUD) format=date9. as fecha_solicitud,
NUMERO_SOLICITUD,
ESTADO,
/*count(case when glosaseguro='CESANTIA' then NUMERO_CONTRATO end) as cesantia,*/
/*count(case when glosaseguro='DESGRAVAMEN' then NUMERO_CONTRATO end) as DESGRAVAMEN,*/
ULTIMO_CANAL,
TAR_COC_PRD,
TAR_COC_SUB_PRD
from CURSE
where estado in (9,11) /*estado de entregados*/
group by 
NUMERO_CONTRATO,
NUMERO_TARJETA,
calculated rut,
calculated fecha_solicitud,
NUMERO_SOLICITUD,
ESTADO,
ULTIMO_CANAL
;QUIT;


PROC SQL;
   CREATE TABLE WORK.CURSE_SALIDA AS 
   SELECT DISTINCT t1.*,
          t2.DESPROD as TIPO_PRODUCTO 
      /*    t2.DESPRODRED */
      FROM WORK.CURSE_SALIDA t1, MPDT.MPDT043 t2
      WHERE (t1.TAR_COC_PRD = t2.PRODUCTO AND t1.TAR_COC_SUB_PRD = t2.SUBPRODU);
QUIT;


%let path_ora      = '(DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SID = ripleyc)))'; 
%let user_ora      = 'RIPLEYC'; 
%let pass_ora      = 'ri99pley';
%let conexion_ora  = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 


PROC SQL  NOERRORSTOP;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );

create table Stock_Cuenta_corriente  as
select * from connection to ORACLE
( 
SELECT 
CAST(SUBSTR(a.cli_identifica,1,length(a.cli_identifica)-1) AS INT)  rut,
SUBSTR(a.cli_identifica,length(a.cli_identifica),1)  dv,
/*b.vis_pro,*/
b.vis_numcue  cuenta, 
/*b.VIS_TIP  TIPO_PRODUCTO,*/
/*b.vis_fechape,*/ 
cast(TO_CHAR( b.vis_fechape,'YYYYMMDD') as INT) as FECHA_APERTURA,
/*b.VIS_FECHCIERR,*/ 
cast(TO_CHAR( b.VIS_FECHCIERR,'YYYYMMDD') as INT) as FECHA_CIERRE,
/*b.vis_status  estado,*/
CASE WHEN b.VIS_PRO=4 THEN 'CUENTA_VISTA'
     WHEN b.VIS_PRO=1 THEN 'CUENTA_CORRIENTE'
WHEN b.VIS_PRO=40 THEN 'LCA' END  DESCRIP_PRODUCTO,
CASE WHEN b.vis_status ='9' THEN 'cerrado' 
when b.vis_status ='2' then 'vigente' end as estado_cuenta,
/*c.DES_CODTAB,*/
b.VIS_SUC as SUCURSAL_APERTURA,
e.SUC_NOMBRE nombre_sucursal,
c.DES_CODIGO COD_CIERRE_CONTRATO,
c.DES_DESCRIPCION DESC_CIERRE_CONTRATO

 
from  tcap_vista  b 
inner join  tcli_persona   a
on(a.cli_codigo=b.vis_codcli) 
left join tgen_desctabla  c
on(b.VIS_CODTAB=c.DES_CODTAB) and     (b.VIS_CAUCIERR=c.DES_CODIGO)
left join TGEN_SUCURSAL e 
on(b.VIS_SUC=e.SUC_CODIGO)

where 
b.vis_mod=4
and (b.VIS_PRO=1)
and b.vis_tip=1  
AND (b.vis_status='2' or b.vis_status='9') 
and cast(TO_CHAR( b.vis_fechape,'YYYYMMDD') as INT)>=20210923 /*20220302*/
) ;
disconnect from ORACLE;
QUIT;


PROC SQL;
CREATE TABLE Stock_Cuenta_corriente AS
SELECT DISTINCT *
FROM Stock_Cuenta_corriente
WHERE ESTADO_CUENTA = 'vigente'
AND FECHA_APERTURA = &INI_NUM.
;QUIT;


PROC SQL;
CREATE TABLE TC AS
SELECT DISTINCT
A.rut,
year(A.fecha_solicitud)*10000+month(A.fecha_solicitud)*100+day(A.fecha_solicitud) AS FECHA_SOLICITUD,
/*A.ESTADO,
/*A.ULTIMO_CANAL,*/
A.TIPO_PRODUCTO

FROM CURSE_SALIDA AS A

;QUIT;


PROC SQL;
CREATE TABLE CTACTE AS
SELECT DISTINCT
A.RUT,
A.FECHA_APERTURA AS FECHA_SOLICITUD,
A.DESCRIP_PRODUCTO AS TIPO_PRODUCTO

FROM Stock_Cuenta_corriente AS A
;QUIT;


PROC SQL;
CREATE TABLE TC_CTACTE AS
SELECT A.* FROM TC AS A
UNION
SELECT B.* FROM CTACTE AS B
;QUIT;


PROC SQL;
CREATE TABLE TC_CTACTE AS
SELECT DISTINCT
A.*,
CASE WHEN B.RUT IS NOT NULL THEN 1 ELSE 0 END AS CAPTA_TC,
CASE WHEN C.RUT IS NOT NULL THEN 1 ELSE 0 END AS CAPTA_CC
FROM TC_CTACTE AS A
LEFT JOIN TC AS B
	ON A.RUT=B.RUT
LEFT JOIN CTACTE AS C
	ON A.RUT=C.RUT
;QUIT;



proc sql;
create table WORK.base_call_limpia as
select a.*
from work.TC_CTACTE a
left join PUBLICIN.LNEGRO_CAR b
on a.rut = b.rut
where b.TIPO_INHIBICION	<> "FALLECIDOS";
quit;



PROC SQL;
CONNECT TO ORACLE AS  bopers (PATH="REPORITF.WORLD" USER='SAS_USR_BI' PASSWORD='SAS_23072020');
CREATE TABLE DML_BOPERS AS 
SELECT * FROM CONNECTION TO bopers(
SELECT 
A.PEMID_GLS_NRO_DCT_IDE_K as rut, 
B.PEMNB_GLS_NOM_PEL AS NOMBRE,
B.PEMNB_GLS_APL_PAT AS PATERNO,
B.PEMNB_GLS_APL_MAT AS MATERNO,
C.PEMDM_GLS_CAL_DML as CALLE, 
C.PEMDM_NRO_DML as NUMERO, 
C.PEMDM_COD_UBC_3ER,
C.PEMDM_COD_UBC_1ER,
D.PEMFO_NRO_SEQ_FON_K,
D.PEMFO_NRO_FON AS TELEFONO
FROM 
BOPERS_MAE_IDE A, 
bopers_mae_nat_bsc B,
BOPERS_MAE_DML C,
BOPERS_MAE_FON D,
bopers_rel_ing_lcl E
WHERE
A.PEMID_NRO_INN_IDE = B.PEMID_NRO_INN_IDE_K AND
B.PEMID_NRO_INN_IDE_K = C.PEMID_NRO_INN_IDE_K AND 
C.PEMDM_COD_DML_PPA = 1 AND 
C.PEMDM_COD_NEG_DML = 1 AND 
C.PEMDM_COD_TIP_DML = 1 AND
C.PEMID_NRO_INN_IDE_K = D.PEMID_NRO_INN_IDE_K AND
D.pemfo_cod_tip_fon = 4 AND
D.pemfo_cod_est_lcl <> 6 AND
D.pemfo_nro_seq_fon_k = E.peril_nro_seq_lcl_dos_k AND
E.peril_cod_tip_lcl_dos_k = 5 AND
E.peril_nro_seq_lcl_uno_k = C.PEMDM_NRO_SEQ_DML_K
) A;
QUIT;


/*Cruce base call limpia con bopers*/
proc sql;
create table base_call_boopers1 as
select a.*,
b.NOMBRE,
b.PATERNO,
b.MATERNO,
b.CALLE, 
b.NUMERO, 
b.PEMDM_COD_UBC_3ER,
b.PEMDM_COD_UBC_1ER,
b.PEMFO_NRO_SEQ_FON_K,
CASE WHEN b.TELEFONO IS NOT NULL THEN CATS(9,B.TELEFONO) ELSE 'NULL' END AS FONO_BOPERS
from WORK.base_call_limpia as a

left join DML_BOPERS as b
	on a.rut=input(b.rut,best.)
;quit;

/*Rescata registro con nro secuencia mayor - Registro mas actualizado - Elimina duplicados*/
proc sql;
create table WORK.base_call_max_seq as
select a.rut,
max(a.PEMFO_NRO_SEQ_FON_K) as NRO_SEQ
from work.base_call_boopers1 a
group by a.rut
;QUIT;




/*Cruza tabla max nro secuencia con cruce bopers*/
proc sql;
create table WORK.DELIVERY as
select
a.*
from WORK.base_call_boopers1 a
left join  WORK.base_call_max_seq b
on a.rut = b.rut
where
a.PEMFO_NRO_SEQ_FON_K = b.NRO_SEQ
;quit;



/*CONEXION PARA BUSCAR COMUNA-REGION*/
LIBNAME GENERAL ORACLE READBUFF=1000 INSERTBUFF=1000 PATH="REPORITF.WORLD" SCHEMA='BOTGEN_ADM' USER='SAS_USR_BI' PASSWORD='SAS_23072020';

PROC SQL;
CREATE TABLE DML_BOPERS_COMUNA AS
SELECT  DISTINCT
a.*,
b.TGLUG_NOM_UBC_GEO as COMUNA
FROM DELIVERY a, GENERAL.BOTGEN_LOG_UBC_GEO b 
WHERE 
a.PEMDM_COD_UBC_3ER = b.TGLUG_COD_UBC_GEO_K 
AND B.TGLDP_COD_DVS_K = 4
;QUIT;

PROC SQL;
CREATE TABLE DML_BOPERS_REGION AS
SELECT DISTINCT
a.*, 
b.TGLUG_NOM_UBC_GEO as REGION
FROM DELIVERY a, GENERAL.BOTGEN_LOG_UBC_GEO b 
WHERE 
a.PEMDM_COD_UBC_1ER = b.TGLUG_COD_UBC_GEO_K 
AND B.TGLDP_COD_DVS_K = 1
;QUIT;


/*SACAR DV*/
PROC SQL;
CREATE TABLE DATA1 AS
SELECT *,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),1,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),1,1),BEST32.) END AS DIG1,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),2,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),2,1),BEST32.) END AS DIG2,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),3,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),3,1),BEST32.) END AS DIG3,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),4,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),4,1),BEST32.) END AS DIG4,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),5,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),5,1),BEST32.) END AS DIG5,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),6,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),6,1),BEST32.) END AS DIG6,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),7,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),7,1),BEST32.) END AS DIG7,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),8,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),8,1),BEST32.) END AS DIG8
FROM base_call_max_seq as a
;QUIT;


PROC SQL;
CREATE TABLE DATA2 AS
SELECT *,
11-(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)-
            (INT(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)/11)*11)) AS DIG,
CASE 
WHEN 11-(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)-
            (INT(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)/11)*11))=11 THEN '0'
WHEN 11-(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)-
            (INT(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)/11)*11))=10 THEN 'K'
ELSE PUT(11-(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)-
            (INT(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)/11)*11)),BEST1.) END AS DV_2
FROM DATA1
;QUIT;


PROC SQL;
CREATE TABLE COMUNICAR_DELIVERY AS
SELECT DISTINCT
A.RUT,
B.DV_2 AS DV,
A.FECHA_SOLICITUD,
CASE 
	WHEN A.CAPTA_TC=1 AND A.CAPTA_CC=0 THEN '01.TAM'
	WHEN A.CAPTA_TC=0 AND A.CAPTA_CC=1 THEN '02.CC'
	WHEN A.CAPTA_TC=1 AND A.CAPTA_CC=1 THEN '03.TAM+CC'
END AS TIPO_PRODUCTO,
A.NOMBRE AS NOMBRE_COMPLETO,
A.PATERNO,
A.MATERNO,
A.CALLE,
A.NUMERO,
C.COMUNA,
D.REGION,
E.EMAIL,
A.FONO_BOPERS AS TELEFONO

FROM WORK.DELIVERY AS A
LEFT JOIN DATA2 AS B
	ON A.RUT=B.RUT
INNER JOIN DML_BOPERS_COMUNA AS C
	ON (A.RUT = C.RUT)
INNER JOIN DML_BOPERS_REGION AS D
	ON (A.RUT = D.RUT)
LEFT JOIN publicin.base_trabajo_email as E
	ON (A.RUT = E.RUT)
LEFT JOIN RSEPULV.GSE_CORP AS F 
	ON (A.RUT = F.RUT)

WHERE F.CATEGORIA_GSE IN ('AB','C1a','C1b','C2')

ORDER BY A.FECHA_SOLICITUD
;QUIT;


PROC SQL;
CREATE TABLE &LIBRERIA..DELIVERY_TARJ_&fec_proceso. AS
SELECT DISTINCT *
FROM COMUNICAR_DELIVERY
;QUIT;



/*para exportar archivo en correo*/
PROC EXPORT DATA=&libreria..DELIVERY_TARJ_&fec_proceso.
   OUTFILE="/sasdata/users94/user_bi/CAPTA_DELIVERY/DELIVERY_TARJ_&fec_proceso..csv" 
   DBMS=dlm replace; 
   delimiter=';'; 
   PUTNAMES=YES; 
RUN;


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
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;	
%put &=DEST_6;


/*envio correo y adjunto archivo*/
data _null_;
FILENAME OUTBOX EMAIL
FROM	= ("&EDP_BI")
TO 		= ("carteagas@bancoripley.com","jackeline.rondon@deliverypro.cl","jose.vergara@deliverypro.cl","rohemy.munoz@deliverypro.cl","cmaturana@bancoripley.com","fcerdag@bancoripley.com","jaravena@bancoripley.com","priveros@bancoripley.com","bodega3@deliverypro.cl")
CC 		= ("&DEST_1","&DEST_2","&DEST_3","&DEST_4","&DEST_5","&DEST_6","gherrerab@bancoripley.com","cparedesp@bancoripley.com","jdonoson@bancoripley.com","rfonsecaa@bancoripley.com","jaburtom@ripley.com")
ATTACH	= "/sasdata/users94/user_bi/CAPTA_DELIVERY/DELIVERY_TARJ_&fec_proceso..csv"  
SUBJECT = ("MAIL_AUTOM: Proceso DELIVERY TARJETAS");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "		Proceso DELIVERY TARJETAS, ejecutado automáticamente con fecha: &fechaeDVN";  
 PUT ;
 PUT "	  	Se adjunta archivo: DELIVERY_TARJ_&fec_proceso..csv";
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
