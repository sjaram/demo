/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	DISPO_AV_COMPRA					 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-11-09 -- v03 -- David V.	-- Se actualizar export a AWS, cambiando earq por ppff
/* 2022-11-08 -- V02 -- Esteban P. 	-- Se añade nueva sentencia include para exportar a RAW sasdata. */

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/


*ProcessBody;

* Start before STPBEGIN code [5aaab21a1afb44ee856e33b1259e9a1e];/* Insertar código personalizado ejecutado delante de la macro STPBEGIN */
%global _ODSDEST;
%let _ODSDEST=none;
* End before STPBEGIN code [5aaab21a1afb44ee856e33b1259e9a1e];

%STPBEGIN;

* Fin del código EG generado (no editar esta línea);


/* 12 - 11 - 2018 */
/*========================================= FECHAS ==========================================*/
DATA _null_;
datex = input(put(intnx('month',today(),0,'end'),yymmn8.),$10.);
exec = put(datetime(),datetime20.);
Call symput("fechax",datex);
Call symput("fechae",exec);
RUN;
%put &fechax;
%put &fechae;

/*test */
/*proc sql outobs=1;*/
/*create table test_&fechae as */
/*select *, &fechae AS FEC_EX*/
/*from slillo.SPOS_201804*/
/*;QUIT;*/

/*======================================== CONEXIONES ========================================*/

/*LIBNAME REPLICAI 	ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' 	USER='NLAGOSG'  	PASSWORD='NLAG#_0211';*/
LIBNAME MPDT 		ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' 	USER='SAS_USR_BI' 	PASSWORD='SAS_23072020';
LIBNAME R_get 		ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' 	USER='SAS_USR_BI' 	PASSWORD='SAS_23072020';
LIBNAME R_bopers 	ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' 	USER='SAS_USR_BI' 	PASSWORD='SAS_23072020';
LIBNAME BOPERS 		ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' 	USER='SAS_USR_BI' 	PASSWORD='SAS_23072020';
/*======================================== =========== ========================================*/

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


/*/*SALDOS*/

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
SELECT A.*, IFN(SALDO_FINAL IS MISSING, 0,SALDO_FINAL) AS SALDO_TOTAL,
			LCA_EGP-IFN(SALDO_FINAL IS MISSING, 0,SALDO_FINAL) AS DISP_EGP
FROM LINEA_EGP A
LEFT JOIN SALDO_TOTAL B ON A.CODENT=B.CODENT AND A.CENTALTA=B.CENTALTA AND A.CUENTA =B.CUENTA;
QUIT; 

/*=========================================== CUPO AVANCE ======================================================================*/
PROC SQL;
 CREATE TABLE LINEA_51 AS 
   SELECT CODENT, 
          CENTALTA, 
          CUENTA,
          LIMCRELNA AS LCA_51 
	FROM MPDT.MPDT450
        WHERE LINEA='0051'
;QUIT;

/*====================================== SALDOS AVANCE ===========================================================================*/
PROC SQL;
   CREATE TABLE SALDO_AVANCE AS 
   SELECT CODENT, 
          CENTALTA, 
          CUENTA, 
          (SUM(SALDO1)) - (SUM(SALDO2)) AS SALDO_FINAL
      FROM SALDOS
        WHERE LINEA='0051'
      GROUP BY CODENT, CENTALTA, CUENTA;
QUIT;

/*======================================= DISPONIBLE AVANCE =====================================================================*/

PROC SQL;
CREATE TABLE DISP_51 AS
SELECT A.*, IFN(SALDO_FINAL IS MISSING, 0,SALDO_FINAL) AS SALDO_51,
       LCA_51-IFN(SALDO_FINAL IS MISSING, 0,SALDO_FINAL)  AS DISP_51
FROM LINEA_51 A
LEFT JOIN SALDO_AVANCE B ON A.CODENT=B.CODENT AND A.CENTALTA=B.CENTALTA AND A.CUENTA =B.CUENTA;
QUIT; 


PROC SQL;
CREATE TABLE publicin.DISPO_AVANCE_&fechax AS /* disponible avance al dia solicitado*/
SELECT A.CODENT, A.CENTALTA, A.CUENTA,A.SALDO_TOTAL,A.DISP_EGP,B.SALDO_51,B.DISP_51,
CASE WHEN DISP_EGP<DISP_51 THEN DISP_EGP ELSE DISP_51 END AS DISP_51_FINAL, B1.LCA_51 AS CUPO,
input(PEMID_GLS_NRO_DCT_IDE_K, best.) as rut , "&fechae" as FEC_EX
FROM DISP_EGP A
LEFT JOIN DISP_51 B ON A.CODENT=B.CODENT AND A.CENTALTA=B.CENTALTA AND A.CUENTA =B.CUENTA
LEFT JOIN LINEA_51 B1 ON A.CODENT=B1.CODENT AND A.CENTALTA=B1.CENTALTA AND A.CUENTA =B1.CUENTA
LEFT JOIN MPDT.MPDT007 C ON A.CODENT=C.CODENT AND A.CENTALTA=C.CENTALTA AND A.CUENTA =C.CUENTA
LEFT JOIN BOPERS.BOPERS_MAE_IDE D ON input(C.IDENTCLI, best.)=D.PEMID_NRO_INN_IDE
;QUIT;


PROC SQL;
UPDATE publicin.DISPO_AVANCE_&fechax
SET DISP_51_FINAL=0
WHERE DISP_51_FINAL < 0
;QUIT;


/*RAW SASDATA*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_ppff_dispo_avance,raw,sasdata,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_ppff_dispo_avance,publicin.dispo_avance_&fechax,raw,sasdata,0);


/*================= DISPO COMPRAS =================================================================================================================*/


/*CALCULANDO DISPONIBLE COMPRAS*/

/*CUPO*/
PROC SQL;
   CREATE TABLE LINEA_50 AS 
   SELECT CODENT, 
          CENTALTA, 
          CUENTA,
		  LIMCRELNA AS LCA_50 
      FROM R_GET.MPDT450
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
SELECT A.*, 
IFN(SALDO_FINAL IS MISSING, 0,SALDO_FINAL) AS SALDO_50,
(LCA_50 - IFN(SALDO_FINAL IS MISSING, 0,SALDO_FINAL))  AS DISP_50

FROM LINEA_50 A
LEFT JOIN SALDO_COMPRAS B ON A.CODENT=B.CODENT AND A.CENTALTA=B.CENTALTA AND A.CUENTA =B.CUENTA;
QUIT; 


/* CÁLCULO DEL DISPONIBLE TOTAL */



PROC SQL;
CREATE TABLE DISP_FINAL AS
SELECT A.CODENT, A.CENTALTA, A.CUENTA, SALDO_TOTAL, DISP_EGP, SALDO_50, DISP_50,
CASE WHEN DISP_EGP < DISP_50 THEN DISP_EGP ELSE DISP_50 END AS DISP_50_FINAL, B1.LCA_50 as CUPO,
			input(PEMID_GLS_NRO_DCT_IDE_K, best.) as rut
FROM DISP_EGP A
LEFT JOIN DISP_50 B 				ON A.CODENT=B.CODENT AND A.CENTALTA=B.CENTALTA AND A.CUENTA =B.CUENTA
LEFT JOIN LINEA_50 B1				ON A.CODENT=B1.CODENT AND A.CENTALTA=B1.CENTALTA AND A.CUENTA =B1.CUENTA
LEFT JOIN R_GET.MPDT007 C 			ON A.CODENT=C.CODENT AND A.CENTALTA=C.CENTALTA AND A.CUENTA =C.CUENTA
LEFT JOIN R_bopers.BOPERS_MAE_IDE D ON input(C.IDENTCLI, best.) = D.PEMID_NRO_INN_IDE
;QUIT;


/*DISPO AL DÍA*/
PROC SQL;
   CREATE TABLE publicin.DISPO_COMPRA_&fechax AS 
   SELECT t1.rut AS RUT, 
          /* MAX_of_DISP_50_FINAL */
            (MAX(t1.DISP_50_FINAL)) AS DISP_50_FINAL, CUPO, "&fechae" as FEC_EX
      FROM WORK.DISP_FINAL AS t1
	  WHERE rut >2
      GROUP BY t1.rut;
QUIT;

* Inicio del código EG generado (no editar esta línea);
;*';*";*/;quit;
%STPEND;

* Fin del código EG generado (no editar esta línea);

/*	VARIABLE TIEMPO	- FIN	*/;
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 
