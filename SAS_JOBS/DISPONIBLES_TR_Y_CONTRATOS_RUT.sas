/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	DISPONIBLES_TR_Y_CONTRATOS_RUT 	 ===============================*/
/* CONTROL DE VERSIONES
/* 2023-10-02 -- v04 -- Esteban P.	-- Se cambia el bucket de destino en AWS para la tabla CONTRATO_RUT de pre-raw a raw.
/* 2023-09-28 -- v03 -- David V.    -- Se cambiar export to AWS a raw y prefijo de tabla a sas_ctbl_contrato_rut (antes bitr).
/* 2023-06-07 -- v02 -- Esteban P.	-- Se añade export para disponibles tr.
/* 2022-11-14 -- v01 -- David V.	-- Versionamiento, correo y comentarios.	
									-- Se actualiza usuario para REPORITF.
									-- Se agrega código para export to AWS a Pre-Raw.
/* 0000-00-00 -- v00 -- 			-- Original
/*

/* VARIABLE TIEMPO - INICIO */
%let tiempo_inicio= %sysfunc(datetime());
options validvarname=any;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

%let libreria=PUBLICIN;

proc sql NOPRINT;                              
SELECT USUARIO	into :USUARIO_BOPERS 		FROM sasdyp.user_pass WHERE SCHEMA = 'BOPERS_ADM';
SELECT PASSWORD into :PASSWORD_BOPERS 		FROM sasdyp.user_pass WHERE SCHEMA = 'BOPERS_ADM';
SELECT USUARIO 	into :USUARIO_GETRONICS 	FROM sasdyp.user_pass WHERE SCHEMA = 'GETRONICS';
SELECT PASSWORD into :PASSWORD_GETRONICS 	FROM sasdyp.user_pass WHERE SCHEMA = 'GETRONICS';
quit;

LIBNAME MPDT  ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER=&USUARIO_BOPERS. PASSWORD=&PASSWORD_BOPERS.;
LIBNAME BOPERS ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER=&USUARIO_GETRONICS. PASSWORD=&PASSWORD_GETRONICS.;

/*LIBNAME MPDT  ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='PMANRIQUEZD' PASSWORD='PMAN#_1407'
LIBNAME R_bopers ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='PMANRIQUEZD' PASSWORD='PMAN#_1407'*/


/*CALCULANDO DISPONIBLE EGP*/


/*CUPO*/
PROC SQL;
   CREATE TABLE LINEA_EGP AS 
   SELECT t1.CODENT, 
          t1.CENTALTA, 
          t1.CUENTA, 
          t1.LIMCRECTA AS LCA_EGP
      FROM MPDT.MPDT163 AS t1;
QUIT;


/*SALDOS*/

/* NO SE CONSIDERA LA LINEA DEL PRODUCTO 52 Y ADEMAS SE EXCLUYE EL BOLSILLO 3 DE AMBOS 
LOS SALDOS CONSIDERAS TODOS LOS ITEM EXCEPTO LOS INTERES DEVENGADO Y POR DEVENGAR*/

PROC SQL;
   CREATE TABLE SALDOS AS 
   SELECT CODENT, 
          CENTALTA, 
          CUENTA, 
          LINEA, 
          SITIMP, 
          (IMPDEUDA1+IMPDEUDA2/*+IMPDEUDA3*/+IMPDEUDA4+IMPDEUDA5+IMPDEUDA6+IMPDEUDA7+IMPDEUDA8+IMPDEUDA9+IMPDEUDA10)AS SALDO1, /*DETALLE CUOTAS X PAGAR*/
          (IMPAPL1+IMPAPL2/*+IMPAPL3*/+IMPAPL4+IMPAPL5+IMPAPL6+IMPAPL7+IMPAPL8+IMPAPL9+IMPAPL10) AS SALDO2 /*AMORTIZACIÓN*/
         
      FROM MPDT.MPDT460 /*SALDOS EPU*/
      WHERE (SITIMP = 'D' /*DISPUESTO*/
       OR SITIMP = 'A') /*PENDIENTE AUTORIZACIÓN*/
     AND LINEA NOT ='0052'
;QUIT;

PROC SQL;
   CREATE TABLE SALDO_TOTAL AS 
   SELECT CODENT, 
          CENTALTA, 
          CUENTA, 
          (SUM(SALDO1)) - (SUM(SALDO2)) AS SALDO_FINAL
      FROM SALDOS
      GROUP BY CODENT, CENTALTA, CUENTA;
QUIT;

/*DISPONIBLE*/
PROC SQL;
CREATE TABLE DISP_EGP AS
SELECT A.*, IFN(SALDO_FINAL IS MISSING, 0,SALDO_FINAL) AS SALDO_TOTAL, LCA_EGP-IFN(SALDO_FINAL IS MISSING, 0,SALDO_FINAL) AS DISP_EGP
FROM LINEA_EGP A
LEFT JOIN SALDO_TOTAL B ON A.CODENT=B.CODENT AND A.CENTALTA=B.CENTALTA AND A.CUENTA =B.CUENTA;
QUIT; 


/*CALCULANDO DISPONIBLE COMPRAS*/

/*CUPO*/
PROC SQL;
   CREATE TABLE LINEA_50 AS 
   SELECT CODENT, 
          CENTALTA, 
          CUENTA,
          LIMCRELNA AS LCA_50 
      FROM MPDT.MPDT450
        WHERE LINEA='0050'
    
;QUIT;

/*SALDOS*/
PROC SQL;
   CREATE TABLE SALDO_COMPRAS AS 
   SELECT CODENT, 
          CENTALTA, 
          CUENTA, 
          (SUM(SALDO1)) - (SUM(SALDO2)) AS SALDO_FINAL
      FROM SALDOS
        WHERE LINEA='0050'
      GROUP BY CODENT, CENTALTA, CUENTA;
QUIT;

/*DISPONIBLE*/
PROC SQL;
CREATE TABLE DISP_50 AS
SELECT A.*, IFN(SALDO_FINAL IS MISSING, 0,SALDO_FINAL) AS SALDO_50, LCA_50-IFN(SALDO_FINAL IS MISSING, 0,SALDO_FINAL)  AS DISP_50
FROM LINEA_50 A
LEFT JOIN SALDO_COMPRAS B ON A.CODENT=B.CODENT AND A.CENTALTA=B.CENTALTA AND A.CUENTA =B.CUENTA;
QUIT; 


/* CÁLCULO DEL DISPONIBLE TOTAL */
PROC SQL;
CREATE TABLE DISP_FINAL AS
SELECT A.CODENT, A.CENTALTA, A.CUENTA,LCA_EGP,SALDO_TOTAL,DISP_EGP,LCA_50,SALDO_50,DISP_50,
CASE WHEN DISP_EGP<DISP_50 THEN DISP_EGP ELSE DISP_50 END AS DISP_50_FINAL,
input(PEMID_GLS_NRO_DCT_IDE_K, best.) as rut
FROM DISP_EGP A
LEFT JOIN DISP_50 B ON A.CODENT=B.CODENT AND A.CENTALTA=B.CENTALTA AND A.CUENTA =B.CUENTA
LEFT JOIN MPDT.MPDT007 C ON A.CODENT=C.CODENT AND A.CENTALTA=C.CENTALTA AND A.CUENTA =C.CUENTA
LEFT JOIN BOPERS.BOPERS_MAE_IDE D ON input(C.IDENTCLI, best.)=D.PEMID_NRO_INN_IDE
;QUIT;


/*PERIODO ANTERIOR*/
DATA _null_;
datex = input(put(intnx('month',today(),-1,'end'),yymmn6.),$10.);
Call symput("fechax", datex);
RUN;
%put &fechax;


PROC SQL;
CREATE TABLE PUBLICIN.DISPONIBLES_TR_&fechax AS  /* PERIODO ANTERIOR DINAMICO, NO CAMBIAR*/
SELECT * FROM DISP_FINAL;
QUIT;


/*					TABLA CONTRATOS RUT                 */
PROC SQL;
CREATE TABLE &libreria..CONTRATO_RUT_&fechax AS
SELECT DISTINCT INPUT(B.PEMID_GLS_NRO_DCT_IDE_K,BEST.) AS RUT,INPUT(A.IDENTCLI,BEST.) AS ID,
A.CODENT,A.CUENTA, A.CENTALTA,CATS(A.CODENT,A.CENTALTA,A.CUENTA) AS CONTRATO,
A.FECALTA,A.FECBAJA,A.GRUPOLIQ,A.PRODUCTO,
C.CONPROD,C.DESCON,C.DESCONRED,
D.DESCRED AS DIA_DE_PAGO,D.DESCRIPCION,
INPUT(E.VERSION,BEST12.) AS COD_GARANTIA,E.CLAMON,
F.DESVERSION AS TIPO_GARANTIA,
CASE WHEN SUBSTR(G.PAN,1,6) IN('628156') THEN 'CERRADA'
WHEN SUBSTR(G.PAN,1,6) IN('549070')AND INPUT(LEFT(SUBSTR(G.PAN,1,7)),BEST.) >=5490702 THEN 'TAM CHIP' 
WHEN SUBSTR(G.PAN,1,6) IN('549070')AND INPUT(LEFT(SUBSTR(G.PAN,1,7)),BEST.) <5490702 THEN 'TAM' 
ELSE 'CERRADA' END AS TIPO_TR,
G.NUMPLASTICO,G.FECALTA AS FECALTA_TR, G.FECBAJA AS FECBAJA_TR,G.PAN,G.FECCADTAR,
G.INDSITTAR,H.DESSITTAR, G.FECULTBLQ,
CASE WHEN G.CODBLQ = 1 AND TEXBLQ = 'BLOQUEO TARJETA NO ISO'  THEN 'BLOQUEO TARJETA NO ISO' 
WHEN G.CODBLQ = 1 AND TEXBLQ NOT IN ('BLOQUEO TARJETA NO ISO') THEN 'ROBO/CODIGO_BLOQUEO' 
WHEN G.CODBLQ IN (79,98)  THEN 'CAMBIO DE PRODUCTO'
WHEN G.CODBLQ IN (16,43)  THEN 'FRAUDE' 
WHEN G.CODBLQ > 1 AND G.CODBLQ NOT IN (16,43,79,98) THEN DESBLQ END AS MOTIVO_BLOQUEO,
/*N_ADICIONALES,*/
CASE WHEN A.FECALTA<>'0001-01-01' AND A.FECBAJA='0001-01-01' THEN 1 ELSE 0 END AS T_CTTO_VIG,
CASE WHEN G.INDSITTAR=5 AND G.FECALTA<>'0001-01-01' AND G.FECBAJA='0001-01-01' AND G.FECULTBLQ='0001-01-01' THEN 1 ELSE 0 END AS T_TR_VIG
FROM MPDT.MPDT007 A 
INNER JOIN BOPERS.BOPERS_MAE_IDE B ON B.PEMID_NRO_INN_IDE=INPUT(A.IDENTCLI,BEST.)
INNER JOIN MPDT.MPDT167 C ON A.CODENT=C.CODENT AND A.PRODUCTO=C.PRODUCTO AND A.SUBPRODU=C.SUBPRODU AND A.CONPROD=C.CONPROD
INNER JOIN MPDT.MPDT086 D ON A.GRUPOLIQ=D.CODGRUPO AND D.CODPROCESO = 1
INNER JOIN MPDT.MPDT494 E ON A.CODENT=E.CODENT AND A.CENTALTA=E.CENTALTA AND A.CUENTA=E.CUENTA
INNER JOIN MPDT.MPDT496 F ON A.CODENT=F.CODENT AND A.PRODUCTO=F.PRODUCTO AND A.SUBPRODU=F.SUBPRODU AND E.CLAMON=F.CLAMON AND E.VERSION=F.VERSION
INNER JOIN MPDT.MPDT009 G ON A.CODENT=G.CODENT AND A.CENTALTA=G.CENTALTA AND A.CUENTA=G.CUENTA AND G.NUMBENCTA=1 AND INDULTTAR='S'
INNER JOIN MPDT.MPDT063 H ON G.CODENT=H.CODENT AND G.INDSITTAR=H.INDSITTAR
LEFT JOIN MPDT.MPDT060 I ON G.CODBLQ=I.CODBLQ
/*LEFT JOIN (SELECT CODENT,CENTALTA,CUENTA,COUNT(CUENTA) AS N_ADICIONALES */
/*			FROM MPDT.MPDT013*/
/*			WHERE CALPART = 'BE' AND FECBAJA = '0001-01-01'*/
/*			GROUP BY CODENT,CENTALTA,CUENTA) J ON A.CODENT=J.CODENT AND A.CENTALTA=J.CENTALTA AND A.CUENTA=J.CUENTA*/
;QUIT;


/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================        EXPORT_TO_AWS - INI          ===============================*/
/*
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_ctbl_contrato_rut,raw,sasdata,-1);
*/
/*Exportación a AWS*/
/*
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_ctbl_contrato_rut,&libreria..CONTRATO_RUT_&fechax,raw,sasdata,-1);
*/


%Let Periodo_Proceso=1; 		/* para correr un nuevo periodo CAMBIAR AQUÍ */

proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='PUBLICIN'
and memname='CONTRATO_RUT_&fechax.'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='PUBLICIN'
and memname='CONTRATO_RUT_&fechax.'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='PUBLICIN'
and memname='CONTRATO_RUT_&fechax.'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(SAS_CTBL_CONTRATO_RUT,raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select * from PUBLICIN.CONTRATO_RUT_&fechax.	/* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(SAS_CTBL_CONTRATO_RUT,corte_&i.,raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_INCREMENTAL_DIARIO.sas";
%INCREMENTAL(sas_ppff_disponibles_tr,PUBLICIN.DISPONIBLES_TR_&fechax,raw,sasdata,-1);


/*==============================        EXPORT_TO_AWS - END          ===============================*/
/*==================================================================================================*/

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*	FECHA DEL PROCESO	*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN);
RUN;

%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
/*	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';*/
/*	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_GOBIERNO_DAT_1';*/
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	
/*%put &=DEST_4;	%put &=DEST_5;*/

/* VARIABLE TIEMPO - FIN */
data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;

data _null_;
	FILENAME OUTBOX EMAIL
	FROM = ("&EDP_BI")
	/*TO = ("&DEST_1")*/
	TO = ("&DEST_4","&DEST_5")
	CC = ("&DEST_1", "&DEST_2", "&DEST_3")
	SUBJECT = ("MAIL_AUTOM: Proceso DISPONIBLES_TR_T_CONTRATOS_RUT");
	FILE OUTBOX;
	PUT "Estimados:";
	PUT "		Proceso DISPONIBLES_TR_T_CONTRATOS_RUT, ejecutado con fecha: &fechaeDVN";
	PUT "  		Información disponible en SAS: &libreria..CONTRATO_RUT_&fechax";
	PUT "  		Información disponible en AWS: sas_ctbl_contrato_rut (En proceso)";
	PUT;
	PUT;
	PUT;
	PUT 'Proceso Vers. 04';
	PUT;
	PUT;
	PUT 'Atte.';
	PUT 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;

FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
