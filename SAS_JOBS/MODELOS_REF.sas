* Inicio del código EG generado (no editar esta línea);
*
*  Procedimiento almacenado registrado por
*  Enterprise Guide Stored Process Manager V7.1
*
*  ====================================================================
*  Nombre del proceso almacenado: MODELOS_REF
*  ====================================================================
*;


*ProcessBody;

* Start before STPBEGIN code [99e73585668b464184429570ad470378];/* Insertar código personalizado ejecutado delante de la macro STPBEGIN */
%global _ODSDEST;
%let _ODSDEST=none;
* End before STPBEGIN code [99e73585668b464184429570ad470378];

%STPBEGIN;

* Fin del código EG generado (no editar esta línea);


/* CONTROL DE VERSIONES. */
/* 2023-06-20 -- V2 -- Esteban P.	-- Se sustituyen las credenciales correspondiente al usuario EPIELH.
*/

%macro principal();
 
%LET NOMBRE_PROCESO = 'MODELO_REF';


/*===================================================================================================================*/
/*=== I.- MODELO CUOTAS FUTURAS =====================================================================================*/
/*===================================================================================================================*/

/*=== A.- cuotas por pagar ====================================================================================================*/

proc sql NOPRINT;                              
SELECT USUARIO into :USER 
    FROM sasdyp.user_pass WHERE SCHEMA = 'BOPERS_ADM';
SELECT PASSWORD into :PASSWORD 
    FROM sasdyp.user_pass WHERE SCHEMA = 'BOPERS_ADM';
quit;

proc sql NOPRINT;                              
SELECT USUARIO into :USER2 
    FROM sasdyp.user_pass WHERE SCHEMA = 'GETRONICS';
SELECT PASSWORD into :PASSWORD2
    FROM sasdyp.user_pass WHERE SCHEMA = 'GETRONICS';
quit;


LIBNAME R_bopers ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=BOPERS_ADM  USER=&USER. PASSWORD=&PASSWORD.;
LIBNAME MPDT ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=GETRONICS  USER=&USER2. PASSWORD=&PASSWORD2.;


PROC SQL;
   CREATE TABLE BASE_MPDT007 AS 
   SELECT t1.CODENT, 
          t1.CENTALTA, 
          t1.CUENTA, 
          t1.FECALTA, 
          t1.FECULTCAR, 
          t1.IDENTCLI, 
          t1.FECBAJA, 
          t1.MOTBAJA, 
          input(t1.IDENTCLI,best.) as ID , 
          t1.PRODUCTO, 
          t1.SUBPRODU
      FROM MPDT.MPDT007 AS t1
;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
   CREATE TABLE BASE_RUT AS 
   SELECT A.*, 
          B.PEMID_GLS_NRO_DCT_IDE_K AS RUT, 
          B.PEMID_DVR_NRO_DCT_IDE AS DV,
              INPUT(B.PEMID_GLS_NRO_DCT_IDE_K,best.) as RUT1
      FROM WORK.BASE_MPDT007 AS A INNER JOIN R_BOPERS.BOPERS_MAE_IDE AS B ON (A.ID = B.PEMID_NRO_INN_IDE);
QUIT;

/*
------------------------------------------------------------
PAGO_CUOTAS
------------------------------------------------------------
*/
DATA _null_;

date = input(put(intnx('month',today(),1,'same'),yymmn6. ),7.);
Call symput("fecha", date);
RUN;
%put &fecha;


%if &syserr. > 0 %then %do;
 %goto exit;
	%end;



PROC SQL;
   CREATE TABLE work.CUOTAS_ITF AS 
   SELECT CODENT, 
          CENTALTA, 
          CUENTA,
          Fecfutvto as VCTO,
            ((SUM(IMPDEUDA5))+(SUM(IMPDEUDA6))+(SUM(Impdeuda7))) AS MORA, 
              ((SUM(Impdeuda1))+(SUM(Impdeuda2))+(SUM(Impdeuda3))+(SUM(Impdeuda4))+(SUM(Impdeuda8))+(SUM(Impdeuda9))+(SUM(Impdeuda10)))
             AS CUOTA
              FROM MPDT.MPDT460
        WHERE Fecfutvto >= &fecha /* LA CUOTA PROXIMA (EJ. SI ESTAMOS EN JULIO (7) DEBE SER AGOSTO (8))*/
      GROUP BY CODENT,CENTALTA,CUENTA,Fecfutvto
;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


/*AGRUPAR POR CODENT, CENTALTA, CUENTA Y CONTAR VENCIMIENTOS EXCLUYENDO*/
/*pegar el rut */
/*ELEGIR LAS CUOTAS MAX POR RUT*/

PROC SQL;
   create table result.CUOTAS_POR_PAGAR_OCT AS 
   SELECT t1.CODENT, 
          t1.CENTALTA, 
          t1.CUENTA, 
          t1.VCTO, 
          t1.MORA, 
          t1.CUOTA, 
          t2.RUT, 
          t2.DV
      FROM CUOTAS_ITF AS t1, WORK.BASE_RUT AS t2
      WHERE (t1.CODENT = t2.CODENT AND t1.CENTALTA = t2.CENTALTA AND t1.CUENTA = t2.CUENTA);
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
   create table result.CUOTAS_POR_PAGAR1_OCT AS 
   SELECT t1.RUT, 
          t1.CODENT, 
          t1.CENTALTA, 
          t1.CUENTA, 
          /* COUNT_of_VCTO */
            (COUNT(t1.VCTO)) AS COUNT_of_VCTO
      FROM result.CUOTAS_POR_PAGAR_OCT AS t1
      GROUP BY t1.RUT, t1.CODENT, t1.CENTALTA, t1.CUENTA;
QUIT;


%if &syserr. > 0 %then %do;
 %goto exit;
	%end;




/*===================================================================================================================*/
/*=== II.- MODELO PROPENSION SEREV ===================================================================================*/
/*===================================================================================================================*/


/*=== a.- saldos =======================================================================================================*/
DATA _null_;
datex = input(put(intnx('month',today(),-1,'end'),yymmn6.),$10.);      
exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);

Call symput("PERIODO", datex);
Call symput("fechae",exec);
RUN;

%put &PERIODO;
%put &fechae;


LIBNAME R_bopers ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=BOPERS_ADM  USER=&USER. PASSWORD=&PASSWORD.;
LIBNAME MPDT ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=GETRONICS  USER=&USER2. PASSWORD=&PASSWORD2.;



PROC SQL;
   CREATE TABLE SALDOS AS 
   SELECT CODENT, 
          CENTALTA, 
          CUENTA, 
          LINEA, 
          SITIMP, 
          (IMPDEUDA1+IMPDEUDA2/*+IMPDEUDA3*/+IMPDEUDA4+IMPDEUDA5+
		   IMPDEUDA6+IMPDEUDA7+IMPDEUDA8+IMPDEUDA9+IMPDEUDA10)AS SALDO1, /*Detalle Cuotas Por Pagar*/
          (IMPAPL1+IMPAPL2/*+IMPAPL3*/+IMPAPL4+IMPAPL5+
           IMPAPL6+IMPAPL7+IMPAPL8+IMPAPL9+IMPAPL10) AS SALDO2 /*Detalle de Amortización de Cuotas*/
         /*bolsillos saldo con todos menos interes*/
      FROM MPDT.MPDT460 /*Saldos EPU*/
      WHERE (SITIMP = 'D' OR SITIMP = 'A') /* D: Dispuesto; A: Pendiente Autorización */;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
   CREATE TABLE SALDO_TOTAL AS 
   SELECT CODENT, 
          CENTALTA, 
          CUENTA, 
          (SUM(SALDO1)) - (SUM(SALDO2)) AS SALDO_FINAL
      FROM SALDOS
      GROUP BY CODENT, CENTALTA, CUENTA;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


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

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


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

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


/*CUPO*/

PROC SQL;
   CREATE TABLE LINEA_50 AS 
   SELECT CODENT, 
          CENTALTA, 
          CUENTA,
          LIMCRELNA AS LCA_50 
      FROM MPDT.MPDT450
        WHERE LINEA='0050';
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
   CREATE TABLE LINEA_51 AS 
   SELECT CODENT, 
          CENTALTA, 
          CUENTA,
          LIMCRELNA AS LCA_51
      FROM MPDT.MPDT450
      	WHERE LINEA='0051';
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
   CREATE TABLE DISP_FINAL_TEMP AS
   SELECT A.CODENT, 
	   	  A.CENTALTA, 
		  A.CUENTA,
		  B.SALDO_FINAL AS SALDO,
		  C.SALDO_FINAL AS SALDO_COMPRAS ,
	      D.SALDO_FINAL AS SALDO_AVANCE,
		  E.LCA_50 AS LCA_COMPRAS ,
		  F.LCA_51 AS LCA_AVANCE , 
		  input(G.PEMID_GLS_NRO_DCT_IDE_K, best.) AS RUT,
		  G.PEMID_NRO_INN_IDE
	  FROM MPDT.MPDT007 A
	  LEFT JOIN SALDO_TOTAL B ON A.CODENT=B.CODENT AND A.CENTALTA=B.CENTALTA AND A.CUENTA =B.CUENTA
	  LEFT JOIN SALDO_COMPRAS  C ON A.CODENT=C.CODENT AND A.CENTALTA=C.CENTALTA AND A.CUENTA =C.CUENTA
	  LEFT JOIN SALDO_AVANCE  D ON A.CODENT=D.CODENT AND A.CENTALTA=D.CENTALTA AND A.CUENTA =D.CUENTA
	  LEFT JOIN LINEA_50 E ON A.CODENT=E.CODENT AND A.CENTALTA=E.CENTALTA AND A.CUENTA =E.CUENTA
	  LEFT JOIN LINEA_51 F ON A.CODENT=F.CODENT AND A.CENTALTA=F.CENTALTA AND A.CUENTA =F.CUENTA
	  LEFT JOIN R_BOPERS.BOPERS_MAE_IDE G ON input(A.IDENTCLI, best.)=G.PEMID_NRO_INN_IDE;
QUIT;


%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


DATA _null_;

datexix1 = input(put(intnx('month',today(),-1,'end'),yymmn6.),$6.);
Call symput("fechaxix1", datexix1);

RUN;
%put &fechaxix1;

PROC SQL;
CREATE TABLE TMP_BASE AS
   SELECT A.*,
          B.RENTA
       FROM DISP_FINAL_TEMP AS A
LEFT JOIN publicin.DEMO_BASKET_&PERIODO AS B ON A.RUT=B.RUT;/* Última Acutalización */
QUIT; 

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


DATA _null_;

date1 = input(put(intnx('month',today(),1,'same'),yymmn6. ),$10.);
date2 = input(put(intnx('month',today(),0,'same'),yymmn6. ),$10.);
date3 = input(put(intnx('month',today(),-1,'same'),yymmn6. ),$10.);

Call symput("fecha1", date1);
Call symput("fecha2", date2);
Call symput("fecha3", date3);

RUN;
%put &fecha1;
%put &fecha2;
%put &fecha3;

DATA _null_;

datei = input(put(intnx('month',today(),-1,'begin'),yymmdd10. ),$10.);
Call symput("fechai", datei);
RUN;
%put &fechai;

PROC SQL;

CREATE TABLE PERIODOS AS /*se borran primero*/
SELECT DISTINCT RUT,
"&fecha1" AS PERIODO_OF, /*Mes Oferta Campaña Actual*/
"&fecha2" AS PERIODO, /*Mes de Ejecución Modelo*/
"&fecha3" AS PERIODO_MA
"&fechai" AS FECHA,   /*Mes donde están los datos*/
SALDO,
LCA_AVANCE,
CODENT,
CENTALTA,
CUENTA,
RENTA,
CASE WHEN LCA_COMPRAS <> 0 THEN SALDO_COMPRAS/ LCA_COMPRAS ELSE 0 END  AS USO_50,
CASE WHEN LCA_AVANCE <> 0 THEN SALDO_AVANCE/ LCA_AVANCE ELSE 0 END  AS USO_51,
CASE WHEN RENTA > 0 THEN SALDO/RENTA ELSE 0 END AS LEV_SDO_RTA
FROM  TMP_BASE               
WHERE SALDO > 0   /* Actualizar al PERIODO_MA - 2 meses atrás */              
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


/*
PROC SQL;
UPDATE JABURTOM.A
SET uso_51 =0
WHERE USO_51 IS MISSING;

PROC SQL;
UPDATE JABURTOM.A
SET uso_50 =0
WHERE uso_50 IS MISSING;
QUIT;*/
DATA _null_;


datev= input(put(intnx('month',today(),-1,'end'),yymmn6.),$10.);

Call symput("fechav", datev);

RUN;

%put &fechav;

/*2899765*/
PROC SQL;
create table result.REV_OF_TABLON_&PERIODO AS
SELECT A.*,
R_AVANCE, /*Recencia Avance*/
R_SUPER_AVANCE AS R_SAV /*Recencia Super Avance*/
FROM PERIODOS AS A
LEFT JOIN rsepulv.TABLONCITO_&PERIODO AS B ON (A.RUT=B.RUT )/*Usar el último*/;
QUIT;



/*=== b.- modelo ==================================================================================================================*/


PROC SORT DATA= result.REV_OF_TABLON_&PERIODO; BY RUT;RUN; /* Cambiar Por Mes de Campaña */
/*DISCRETIZARLAS*/

data result.SCORE_REF_TABLON_&PERIODO; /* Cambiar Por Mes de Campaña */
set result.REV_OF_TABLON_&PERIODO ; /* Cambiar Por Mes de Campaña */

*------------------------------------------------------------*;
* EM SCORE CODE;
* VERSION: 6.1;
* GENERATED BY: Susana Lillo Moya;
* CREATED: 03JUN2010:11:17:30;
*------------------------------------------------------------*;
*------------------------------------------------------------*;
* TOOL: Input Data Source;
* TYPE: SAMPLE;
* NODE: Ids2;
*------------------------------------------------------------*;
*------------------------------------------------------------*;
* TOOL: Partition Class;
* TYPE: SAMPLE;
* NODE: Part;
*------------------------------------------------------------*;
*------------------------------------------------------------*;
* TOOL: Extension Class;
* TYPE: MODIFY;
* NODE: BINNING;
*------------------------------------------------------------*;
length _UFormat $200;
drop _UFormat;
_UFormat='';

*------------------------------------------------------------*;
* Variable: LCA_AVANCE;
*------------------------------------------------------------*;
LABEL GRP_LCA_AVANCE = 'Grouped: LCA_AVANCE';

if MISSING(LCA_AVANCE) then
GRP_LCA_AVANCE = 1;
else if NOT MISSING(LCA_AVANCE) AND LCA_AVANCE < 1000 then
GRP_LCA_AVANCE = 2;
else if NOT MISSING(LCA_AVANCE) and 1000 <= LCA_AVANCE AND LCA_AVANCE < 116000 then
GRP_LCA_AVANCE = 3;
else if NOT MISSING(LCA_AVANCE) and 116000 <= LCA_AVANCE AND LCA_AVANCE < 400000 then
GRP_LCA_AVANCE = 4;
else if NOT MISSING(LCA_AVANCE) and 400000 <= LCA_AVANCE then
GRP_LCA_AVANCE = 5;

*------------------------------------------------------------*;
* Variable: LEV_SDO_RTA;
*------------------------------------------------------------*;
LABEL GRP_LEV_SDO_RTA = 'Grouped: LEV_SDO_RTA';

if MISSING(LEV_SDO_RTA) then
GRP_LEV_SDO_RTA = 1;
else if NOT MISSING(LEV_SDO_RTA) AND LEV_SDO_RTA < 0.77 then
GRP_LEV_SDO_RTA = 2;
else if NOT MISSING(LEV_SDO_RTA) and 0.77 <= LEV_SDO_RTA AND LEV_SDO_RTA < 1.62 then
GRP_LEV_SDO_RTA = 3;
else if NOT MISSING(LEV_SDO_RTA) and 1.62 <= LEV_SDO_RTA AND LEV_SDO_RTA < 3.5 then
GRP_LEV_SDO_RTA = 4;
else if NOT MISSING(LEV_SDO_RTA) and 3.5 <= LEV_SDO_RTA then
GRP_LEV_SDO_RTA = 5;

*------------------------------------------------------------*;
* Variable: R_AVANCE;
*------------------------------------------------------------*;
LABEL GRP_R_AVANCE = 'Grouped: R_AVANCE';

if MISSING(R_AVANCE) then
GRP_R_AVANCE = 1;
else if NOT MISSING(R_AVANCE) AND R_AVANCE < 4 then
GRP_R_AVANCE = 2;
else if NOT MISSING(R_AVANCE) and 4 <= R_AVANCE AND R_AVANCE < 10 then
GRP_R_AVANCE = 3;
else if NOT MISSING(R_AVANCE) and 10 <= R_AVANCE AND R_AVANCE < 25 then
GRP_R_AVANCE = 4;
else if NOT MISSING(R_AVANCE) and 25 <= R_AVANCE then
GRP_R_AVANCE = 5;

*------------------------------------------------------------*;
* Variable: R_SAV;
*------------------------------------------------------------*;
LABEL GRP_R_SAV = 'Grouped: R_SAV';

if MISSING(R_SAV) then
GRP_R_SAV = 1;
else if NOT MISSING(R_SAV) AND R_SAV < 10 then
GRP_R_SAV = 2;
else if NOT MISSING(R_SAV) and 10 <= R_SAV AND R_SAV < 17 then
GRP_R_SAV = 3;
else if NOT MISSING(R_SAV) and 17 <= R_SAV AND R_SAV < 26 then
GRP_R_SAV = 4;
else if NOT MISSING(R_SAV) and 26 <= R_SAV then
GRP_R_SAV = 5;

*------------------------------------------------------------*;
* Variable: SALDO;
*------------------------------------------------------------*;
LABEL GRP_SALDO = 'Grouped: SALDO';

if MISSING(SALDO) then
GRP_SALDO = 1;
else if NOT MISSING(SALDO) AND SALDO < 262841 then
GRP_SALDO = 2;
else if NOT MISSING(SALDO) and 262841 <= SALDO AND SALDO < 488801.5 then
GRP_SALDO = 3;
else if NOT MISSING(SALDO) and 488801.5 <= SALDO AND SALDO < 1000048.5 then
GRP_SALDO = 4;
else if NOT MISSING(SALDO) and 1000048.5 <= SALDO then
GRP_SALDO = 5;

*------------------------------------------------------------*;
* Variable: USO_50;
*------------------------------------------------------------*;
LABEL GRP_USO_50 = 'Grouped: USO_50';

if MISSING(USO_50) then
GRP_USO_50 = 1;
else if NOT MISSING(USO_50) AND USO_50 < 0.04 then
GRP_USO_50 = 2;
else if NOT MISSING(USO_50) and 0.04 <= USO_50 AND USO_50 < 0.21 then
GRP_USO_50 = 3;
else if NOT MISSING(USO_50) and 0.21 <= USO_50 AND USO_50 < 0.58 then
GRP_USO_50 = 4;
else if NOT MISSING(USO_50) and 0.58 <= USO_50 then
GRP_USO_50 = 5;

*------------------------------------------------------------*;
* Variable: USO_51;
*------------------------------------------------------------*;
LABEL GRP_USO_51 = 'Grouped: USO_51';

if MISSING(USO_51) then
GRP_USO_51 = 1;
else if NOT MISSING(USO_51) AND USO_51 < 0 then
GRP_USO_51 = 2;
else if NOT MISSING(USO_51) and 0 <= USO_51 AND USO_51 < 0.72 then
GRP_USO_51 = 3;
else if NOT MISSING(USO_51) and 0.72 <= USO_51 then
GRP_USO_51 = 4;
*------------------------------------------------------------*;
* TOOL: Regression;
* TYPE: MODEL;
* NODE: Reg2;
*------------------------------------------------------------*;
*************************************;
*** begin scoring code for regression;
*************************************;

length _WARN_ $4;
label _WARN_ = 'Warnings' ;

length I_RESPUESTA $ 1;
label I_RESPUESTA = 'Into: RESPUESTA' ;
*** Target Values;
array REG2DRF [2] $1 _temporary_ ('1' '0' );
label U_RESPUESTA = 'Unnormalized Into: RESPUESTA' ;
format U_RESPUESTA BEST1.;
*** Unnormalized target values;
ARRAY REG2DRU[2]  _TEMPORARY_ (1 0);

drop _DM_BAD;
_DM_BAD=0;

*** Generate dummy variables for GRP_LCA_AVANCE ;
drop _1_0 _1_1 _1_2 _1_3 ;
*** encoding is sparse, initialize to zero;
_1_0 = 0;
_1_1 = 0;
_1_2 = 0;
_1_3 = 0;
if missing( GRP_LCA_AVANCE ) then do;
   _1_0 = .;
   _1_1 = .;
   _1_2 = .;
   _1_3 = .;
   substr(_warn_,1,1) = 'M';
   _DM_BAD = 1;
end;
else do;
   length _dm12 $ 12; drop _dm12 ;
   _dm12 = put( GRP_LCA_AVANCE , BEST12. );
   %DMNORMIP( _dm12 )
   _dm_find = 0; drop _dm_find;
   if _dm12 <= '3'  then do;
      if _dm12 <= '2'  then do;
         if _dm12 = '1'  then do;
            _1_0 = 1;
            _dm_find = 1;
         end;
         else do;
            if _dm12 = '2'  then do;
               _1_1 = 1;
               _dm_find = 1;
            end;
         end;
      end;
      else do;
         if _dm12 = '3'  then do;
            _1_2 = 1;
            _dm_find = 1;
         end;
      end;
   end;
   else do;
      if _dm12 = '4'  then do;
         _1_3 = 1;
         _dm_find = 1;
      end;
      else do;
         if _dm12 = '5'  then do;
            _1_0 = -1;
            _1_1 = -1;
            _1_2 = -1;
            _1_3 = -1;
            _dm_find = 1;
         end;
      end;
   end;
   if not _dm_find then do;
      _1_0 = .;
      _1_1 = .;
      _1_2 = .;
      _1_3 = .;
      substr(_warn_,2,1) = 'U';
      _DM_BAD = 1;
   end;
end;

*** Generate dummy variables for GRP_LEV_SDO_RTA ;
drop _2_0 _2_1 _2_2 _2_3 ;
*** encoding is sparse, initialize to zero;
_2_0 = 0;
_2_1 = 0;
_2_2 = 0;
_2_3 = 0;
if missing( GRP_LEV_SDO_RTA ) then do;
   _2_0 = .;
   _2_1 = .;
   _2_2 = .;
   _2_3 = .;
   substr(_warn_,1,1) = 'M';
   _DM_BAD = 1;
end;
else do;
   length _dm12 $ 12; drop _dm12 ;
   _dm12 = put( GRP_LEV_SDO_RTA , BEST12. );
   %DMNORMIP( _dm12 )
   _dm_find = 0; drop _dm_find;
   if _dm12 <= '3'  then do;
      if _dm12 <= '2'  then do;
         if _dm12 = '1'  then do;
            _2_0 = 1;
            _dm_find = 1;
         end;
         else do;
            if _dm12 = '2'  then do;
               _2_1 = 1;
               _dm_find = 1;
            end;
         end;
      end;
      else do;
         if _dm12 = '3'  then do;
            _2_2 = 1;
            _dm_find = 1;
         end;
      end;
   end;
   else do;
      if _dm12 = '4'  then do;
         _2_3 = 1;
         _dm_find = 1;
      end;
      else do;
         if _dm12 = '5'  then do;
            _2_0 = -1;
            _2_1 = -1;
            _2_2 = -1;
            _2_3 = -1;
            _dm_find = 1;
         end;
      end;
   end;
   if not _dm_find then do;
      _2_0 = .;
      _2_1 = .;
      _2_2 = .;
      _2_3 = .;
      substr(_warn_,2,1) = 'U';
      _DM_BAD = 1;
   end;
end;

*** Generate dummy variables for GRP_R_AVANCE ;
drop _3_0 _3_1 _3_2 _3_3 ;
*** encoding is sparse, initialize to zero;
_3_0 = 0;
_3_1 = 0;
_3_2 = 0;
_3_3 = 0;
if missing( GRP_R_AVANCE ) then do;
   _3_0 = .;
   _3_1 = .;
   _3_2 = .;
   _3_3 = .;
   substr(_warn_,1,1) = 'M';
   _DM_BAD = 1;
end;
else do;
   length _dm12 $ 12; drop _dm12 ;
   _dm12 = put( GRP_R_AVANCE , BEST12. );
   %DMNORMIP( _dm12 )
   _dm_find = 0; drop _dm_find;
   if _dm12 <= '3'  then do;
      if _dm12 <= '2'  then do;
         if _dm12 = '1'  then do;
            _3_0 = 1;
            _dm_find = 1;
         end;
         else do;
            if _dm12 = '2'  then do;
               _3_1 = 1;
               _dm_find = 1;
            end;
         end;
      end;
      else do;
         if _dm12 = '3'  then do;
            _3_2 = 1;
            _dm_find = 1;
         end;
      end;
   end;
   else do;
      if _dm12 = '4'  then do;
         _3_3 = 1;
         _dm_find = 1;
      end;
      else do;
         if _dm12 = '5'  then do;
            _3_0 = -1;
            _3_1 = -1;
            _3_2 = -1;
            _3_3 = -1;
            _dm_find = 1;
         end;
      end;
   end;
   if not _dm_find then do;
      _3_0 = .;
      _3_1 = .;
      _3_2 = .;
      _3_3 = .;
      substr(_warn_,2,1) = 'U';
      _DM_BAD = 1;
   end;
end;

*** Generate dummy variables for GRP_R_SAV ;
drop _4_0 _4_1 _4_2 _4_3 ;
*** encoding is sparse, initialize to zero;
_4_0 = 0;
_4_1 = 0;
_4_2 = 0;
_4_3 = 0;
if missing( GRP_R_SAV ) then do;
   _4_0 = .;
   _4_1 = .;
   _4_2 = .;
   _4_3 = .;
   substr(_warn_,1,1) = 'M';
   _DM_BAD = 1;
end;
else do;
   length _dm12 $ 12; drop _dm12 ;
   _dm12 = put( GRP_R_SAV , BEST12. );
   %DMNORMIP( _dm12 )
   if _dm12 = '1'  then do;
      _4_0 = 1;
   end;
   else if _dm12 = '5'  then do;
      _4_0 = -1;
      _4_1 = -1;
      _4_2 = -1;
      _4_3 = -1;
   end;
   else if _dm12 = '4'  then do;
      _4_3 = 1;
   end;
   else if _dm12 = '2'  then do;
      _4_1 = 1;
   end;
   else if _dm12 = '3'  then do;
      _4_2 = 1;
   end;
   else do;
      _4_0 = .;
      _4_1 = .;
      _4_2 = .;
      _4_3 = .;
      substr(_warn_,2,1) = 'U';
      _DM_BAD = 1;
   end;
end;

*** Generate dummy variables for GRP_SALDO ;
drop _5_0 _5_1 _5_2 _5_3 ;
*** encoding is sparse, initialize to zero;
_5_0 = 0;
_5_1 = 0;
_5_2 = 0;
_5_3 = 0;
if missing( GRP_SALDO ) then do;
   _5_0 = .;
   _5_1 = .;
   _5_2 = .;
   _5_3 = .;
   substr(_warn_,1,1) = 'M';
   _DM_BAD = 1;
end;
else do;
   length _dm12 $ 12; drop _dm12 ;
   _dm12 = put( GRP_SALDO , BEST12. );
   %DMNORMIP( _dm12 )
   _dm_find = 0; drop _dm_find;
   if _dm12 <= '3'  then do;
      if _dm12 <= '2'  then do;
         if _dm12 = '1'  then do;
            _5_0 = 1;
            _dm_find = 1;
         end;
         else do;
            if _dm12 = '2'  then do;
               _5_1 = 1;
               _dm_find = 1;
            end;
         end;
      end;
      else do;
         if _dm12 = '3'  then do;
            _5_2 = 1;
            _dm_find = 1;
         end;
      end;
   end;
   else do;
      if _dm12 = '4'  then do;
         _5_3 = 1;
         _dm_find = 1;
      end;
      else do;
         if _dm12 = '5'  then do;
            _5_0 = -1;
            _5_1 = -1;
            _5_2 = -1;
            _5_3 = -1;
            _dm_find = 1;
         end;
      end;
   end;
   if not _dm_find then do;
      _5_0 = .;
      _5_1 = .;
      _5_2 = .;
      _5_3 = .;
      substr(_warn_,2,1) = 'U';
      _DM_BAD = 1;
   end;
end;

*** Generate dummy variables for GRP_USO_50 ;
drop _6_0 _6_1 _6_2 _6_3 ;
*** encoding is sparse, initialize to zero;
_6_0 = 0;
_6_1 = 0;
_6_2 = 0;
_6_3 = 0;
if missing( GRP_USO_50 ) then do;
   _6_0 = .;
   _6_1 = .;
   _6_2 = .;
   _6_3 = .;
   substr(_warn_,1,1) = 'M';
   _DM_BAD = 1;
end;
else do;
   length _dm12 $ 12; drop _dm12 ;
   _dm12 = put( GRP_USO_50 , BEST12. );
   %DMNORMIP( _dm12 )
   _dm_find = 0; drop _dm_find;
   if _dm12 <= '3'  then do;
      if _dm12 <= '2'  then do;
         if _dm12 = '1'  then do;
            _6_0 = 1;
            _dm_find = 1;
         end;
         else do;
            if _dm12 = '2'  then do;
               _6_1 = 1;
               _dm_find = 1;
            end;
         end;
      end;
      else do;
         if _dm12 = '3'  then do;
            _6_2 = 1;
            _dm_find = 1;
         end;
      end;
   end;
   else do;
      if _dm12 = '4'  then do;
         _6_3 = 1;
         _dm_find = 1;
      end;
      else do;
         if _dm12 = '5'  then do;
            _6_0 = -1;
            _6_1 = -1;
            _6_2 = -1;
            _6_3 = -1;
            _dm_find = 1;
         end;
      end;
   end;
   if not _dm_find then do;
      _6_0 = .;
      _6_1 = .;
      _6_2 = .;
      _6_3 = .;
      substr(_warn_,2,1) = 'U';
      _DM_BAD = 1;
   end;
end;

*** Generate dummy variables for GRP_USO_51 ;
drop _7_0 _7_1 ;
if missing( GRP_USO_51 ) then do;
   _7_0 = .;
   _7_1 = .;
   substr(_warn_,1,1) = 'M';
   _DM_BAD = 1;
end;
else do;
   length _dm12 $ 12; drop _dm12 ;
   _dm12 = put( GRP_USO_51 , BEST12. );
   %DMNORMIP( _dm12 )
   if _dm12 = '3'  then do;
      _7_0 = 0;
      _7_1 = 1;
   end;
   else if _dm12 = '1'  then do;
      _7_0 = 1;
      _7_1 = 0;
   end;
   else if _dm12 = '4'  then do;
      _7_0 = -1;
      _7_1 = -1;
   end;
   else do;
      _7_0 = .;
      _7_1 = .;
      substr(_warn_,2,1) = 'U';
      _DM_BAD = 1;
   end;
end;

*** If missing inputs, use averages;
if _DM_BAD > 0 then do;
   _P0 = 0.5000040196;
   _P1 = 0.4999959804;
   goto REG2DR1;
end;

*** Compute Linear Predictor;
drop _TEMP;
drop _LP0;
_LP0 = 0;

***  Effect: GRP_LCA_AVANCE ;
_TEMP = 1;
_LP0 = _LP0 + (    0.13847926121033) * _TEMP * _1_0;
_LP0 = _LP0 + (    0.30562532248503) * _TEMP * _1_1;
_LP0 = _LP0 + (    0.13202817076427) * _TEMP * _1_2;
_LP0 = _LP0 + (   -0.16099139066226) * _TEMP * _1_3;

***  Effect: GRP_LEV_SDO_RTA ;
_TEMP = 1;
_LP0 = _LP0 + (     0.1302767398436) * _TEMP * _2_0;
_LP0 = _LP0 + (   -0.12031885215557) * _TEMP * _2_1;
_LP0 = _LP0 + (     0.0420880024759) * _TEMP * _2_2;
_LP0 = _LP0 + (   -0.01157461291229) * _TEMP * _2_3;

***  Effect: GRP_R_AVANCE ;
_TEMP = 1;
_LP0 = _LP0 + (   -0.36764748104308) * _TEMP * _3_0;
_LP0 = _LP0 + (    0.23958717314045) * _TEMP * _3_1;
_LP0 = _LP0 + (    0.19616246973919) * _TEMP * _3_2;
_LP0 = _LP0 + (    0.09472195280375) * _TEMP * _3_3;

***  Effect: GRP_R_SAV ;
_TEMP = 1;
_LP0 = _LP0 + (    -0.3327201544533) * _TEMP * _4_0;
_LP0 = _LP0 + (   -0.14473615516725) * _TEMP * _4_1;
_LP0 = _LP0 + (    0.29862717382215) * _TEMP * _4_2;
_LP0 = _LP0 + (    0.18422632823252) * _TEMP * _4_3;

***  Effect: GRP_SALDO ;
_TEMP = 1;
_LP0 = _LP0 + (      0.814375178675) * _TEMP * _5_0;
_LP0 = _LP0 + (   -0.82785500414431) * _TEMP * _5_1;
_LP0 = _LP0 + (   -0.21906123325769) * _TEMP * _5_2;
_LP0 = _LP0 + (                   0) * _TEMP * _5_3;

***  Effect: GRP_USO_50 ;
_TEMP = 1;
_LP0 = _LP0 + (   -1.11632802349032) * _TEMP * _6_0;
_LP0 = _LP0 + (   -0.09657285383893) * _TEMP * _6_1;
_LP0 = _LP0 + (    0.29594196260017) * _TEMP * _6_2;
_LP0 = _LP0 + (    0.44583813980926) * _TEMP * _6_3;

***  Effect: GRP_USO_51 ;
_TEMP = 1;
_LP0 = _LP0 + (   -0.32281078916952) * _TEMP * _7_0;
_LP0 = _LP0 + (                   0) * _TEMP * _7_1;

*** Naive Posterior Probabilities;
drop _MAXP _IY _P0 _P1;
_TEMP =     0.33249928095927 + _LP0;
if (_TEMP < 0) then do;
   _TEMP = exp(_TEMP);
   _P0 = _TEMP / (1 + _TEMP);
end;
else _P0 = 1 / (1 + exp(-_TEMP));
_P1 = 1.0 - _P0;

REG2DR1:


*** Posterior Probabilities and Predicted Level;
label P_RESPUESTA1 = 'Predicted: RESPUESTA=1' ;
label P_RESPUESTA0 = 'Predicted: RESPUESTA=0' ;
P_RESPUESTA1 = _P0;
_MAXP = _P0;
_IY = 1;
P_RESPUESTA0 = _P1;
if (_P1 - _MAXP > 1e-8) then do;
   _MAXP = _P1;
   _IY = 2;
end;
I_RESPUESTA = REG2DRF[_IY];
U_RESPUESTA = REG2DRU[_IY];

*************************************;
***** end scoring code for regression;
*************************************;
*------------------------------------------------------------*;
* TOOL: Score Node;
* TYPE: ASSESS;
* NODE: Score;
*------------------------------------------------------------*;
*------------------------------------------------------------*;
* Score: creando nombres fijos;
*------------------------------------------------------------*;
LABEL EM_EVENTPROBABILITY = 'Probability for level 1 of RESPUESTA';
EM_EVENTPROBABILITY = P_RESPUESTA1;
LABEL EM_PROBABILITY = 'Probability of Classification';
EM_PROBABILITY = max(
P_RESPUESTA1
,
P_RESPUESTA0
);
LENGTH EM_CLASSIFICATION $%dmnorlen;
LABEL EM_CLASSIFICATION = "Prediction for RESPUESTA";
EM_CLASSIFICATION = I_RESPUESTA;

PROC SORT DATA= result.SCORE_REF_TABLON_&PERIODO ; BY RUT;RUN; /* Cambiar Por Mes de Campaña */

DATA result.SCORE_REF_TABLON_&PERIODO;
SET   result.SCORE_REF_TABLON_&PERIODO;
IF P_RESPUESTA1 <= 0.1 THEN RANGO_PROB = '0.0 - 0.1'; 
ELSE IF P_RESPUESTA1 <= 0.20 THEN RANGO_PROB = '0.1 - 0.2'; 
ELSE IF P_RESPUESTA1 <= 0.30 THEN RANGO_PROB = '0.2 - 0.3'; 
ELSE IF P_RESPUESTA1 <= 0.40 THEN RANGO_PROB = '0.3 - 0.4'; 
ELSE IF P_RESPUESTA1 <= 0.50 THEN RANGO_PROB = '0.4 - 0.5' ; 
ELSE IF P_RESPUESTA1 <= 0.60 THEN RANGO_PROB = '0.5 - 0.6' ; 
ELSE IF P_RESPUESTA1 <= 0.70 THEN RANGO_PROB = '0.6 - 0.7' ; 
ELSE IF P_RESPUESTA1 <= 0.80 THEN RANGO_PROB = '0.7 - 0.8' ; 
ELSE IF P_RESPUESTA1 <= 0.90 THEN RANGO_PROB = '0.8 - 0.9' ; 
ELSE RANGO_PROB = '0.9 - 1.0' ; RUN;

data result.RGO_SCORE_REF_TABLON_&PERIODO (KEEP= RUT P_RESPUESTA1 RANGO_PROB); /* Cambiar Por Mes de Campaña */
set result.SCORE_REF_TABLON_&PERIODO; /* Cambiar Por Mes de Campaña */
RUN;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


/*PROC SORT DATA=SLILLO.RGO_SCORE2_REF_jun10; BY RUT;RUN;*/

PROC SQL;
   create table result.RGO_SCORE_REF_TABLON_1_&PERIODO AS 
   SELECT t1.RUT, 
          t1.CODENT, 
          t1.CENTALTA, 
          t1.CUENTA, 
          t1.P_RESPUESTA1, 
          t1.RANGO_PROB
      FROM result.SCORE_REF_TABLON_&PERIODO AS t1;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


/*2904293*/
PROC SQL;
create table result.RGO_SCORE_REF_TABLON_&PERIODO AS
SELECT t1.RUT,
       t1.P_RESPUESTA1,
       t1.RANGO_PROB
FROM result.RGO_SCORE_REF_TABLON_1_&PERIODO AS t1;
QUIT; 

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;



/*===================================================================================================================*/
/*=== III.- MODELO PROPENSION SEREV ===================================================================================*/
/*===================================================================================================================*/


/*=== a.- trx sin cuotas ===============================================================================================*/


LIBNAME MPDT ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=GETRONICS  USER=&USER2. PASSWORD=&PASSWORD2.;

/*TRX Sin Cuotas*/ 

/*Se utiliza último mes cerrado de transacciones*/
DATA _null_;

datei = input(put(intnx('month',today(),-1,'begin'),yymmdd10. ),$10.);
datef = input(put(intnx('month',today(),-1,'end'),yymmdd10. ),$10.);

Call symput("fechai", datei);
Call symput("fechaf", datef);

RUN;
%put &fechai;
%put &fechaf;

DATA _null_;

datex = input(put(intnx('month',today(),-1,'same'),yymmn6. ),$10.);
Call symput("fechax1", datex);
RUN;
%put &fechax1;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
   create table result.MPDT12_&fechax1 AS 
   SELECT t1.CODENT, 
	      t1.CENTALTA, 
	      t1.CUENTA, 
	      t1.LINEA, 
	      t1.FECFAC, 
	      t1.IMPFAC, 
	      t1.CODCOM, 
	      t1.ORIGENOPE 
	      FROM MPDT.MPDT012 AS t1
	WHERE t1.FECFAC BETWEEN "&fechai" AND "&fechaf"/*Ojo,fijarsse cuantos días tiene el mes*/
	AND   t1.TIPOFAC IN (2053, 2050,2051,2150, 2250, 2350,2351,2651,2850,
1850, 2353, 6050,6051,3010,6551,2777,2750,1653) /*CODIGOS COMPRAS REVOLVING y AVANCES*/
;
QUIT;

/* TRX Vigentes Con Cuotas */

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
   CREATE TABLE MPDT205_206 AS 
   SELECT t1.CODENT, 
          t1.CENTALTA, 
          t1.CUENTA, 
          t1.LINEA, 
          t1.FECFAC, 
          t1.IMPFAC, 
          t1.ORIGENOPE, 
          t1.CODCOM,
          t2.PORINT
      FROM MPDT.MPDT205 AS t1, MPDT.MPDT206 AS t2
      WHERE t1.CODENT = t2.CODENT AND t1.CENTALTA = t2.CENTALTA AND t1.CUENTA = t2.CUENTA AND t1.CLAMON = t2.CLAMON AND
            t1.CODTIPC = t2.CODTIPC AND t1.NUMOPECUO = t2.NUMOPECUO AND t1.ESTCOMPRA = 1 /*1 = TRANSACCIONES VIGENTES*/;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;



/*=== b.- calculo de tasas ===============================================================================================*/


LIBNAME R_bopers ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=BOPERS_ADM  USER=&USER. PASSWORD=&PASSWORD.;
LIBNAME MPDT ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=GETRONICS  USER=&USER2. PASSWORD=&PASSWORD2.;

DATA _null_;

date1 = input(put(intnx('month',today(),-1,'same'),yymmn6. ),$10.);
date2 = input(put(intnx('month',today(),-2,'same'),yymmn6. ),$10.);
date3 = input(put(intnx('month',today(),-3,'same'),yymmn6. ),$10.);
date4 = input(put(intnx('month',today(),-4,'same'),yymmn6. ),$10.);
date5 = input(put(intnx('month',today(),-5,'same'),yymmn6. ),$10.);
date6 = input(put(intnx('month',today(),-6,'same'),yymmn6. ),$10.);

Call symput("fecha1", date1);
Call symput("fecha2", date2);
Call symput("fecha3", date3);
Call symput("fecha4", date4);
Call symput("fecha5", date5);
Call symput("fecha6", date6);

RUN;
%put &fecha1;
%put &fecha2;
%put &fecha3;
%put &fecha4;
%put &fecha5;
%put &fecha6;


PROC SQL;
CREATE TABLE MPDT12_UNIFICADA AS /*Cambiar a últimos 6 meses*/
SELECT * FROM result.MPDT12_&fecha6
OUTER UNION CORR 
SELECT * FROM result.MPDT12_&fecha5
OUTER UNION CORR 
SELECT * FROM result.MPDT12_&fecha4
OUTER UNION CORR
SELECT * FROM result.MPDT12_&fecha3
OUTER UNION CORR
SELECT * FROM result.MPDT12_&fecha2
OUTER UNION CORR
SELECT * FROM result.MPDT12_&fecha1;
QUIT;


%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
   CREATE TABLE BASE_UNIDA AS 
  SELECT A.CODENT, 
          A.CENTALTA, 
         A.CUENTA, 
         A.LINEA, 
         A.FECFAC, 
         A.IMPFAC, 
         A.ORIGENOPE, 
          A.CODCOM, 
         A.PORINT
     FROM MPDT205_206 AS A
        OUTER UNION CORR 
   SELECT B.CODENT, 
          B.CENTALTA, 
          B.CUENTA, 
          B.LINEA, 
          B.FECFAC, 
          B.IMPFAC, 
          B.ORIGENOPE, 
          B.CODCOM
FROM WORK.MPDT12_UNIFICADA AS B
;
QUIT;

PROC SQL;
UPDATE BASE_UNIDA
SET PORINT =0.0
WHERE PORINT =.
;
QUIT; 

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
CREATE TABLE PASO1 AS
SELECT A.*,
(A.IMPFAC*A.PORINT) AS FINAN
FROM BASE_UNIDA AS A
;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
   CREATE TABLE BASE_MPDT007 AS /* Contiene todos los contratos, se agregaron clientes castigados */
   SELECT t1.CODENT, 
          t1.CENTALTA, 
          t1.CUENTA, 
          t1.FECALTA, 
          t1.FECULTCAR, 
          t1.IDENTCLI, 
          t1.FECBAJA, 
          t1.MOTBAJA, 
          input(t1.IDENTCLI,best.) as ID , 
          t1.PRODUCTO, 
          t1.SUBPRODU
      FROM MPDT.MPDT007 AS t1
;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
   CREATE TABLE BASE_RUT AS 
   SELECT A.*, 
          B.PEMID_GLS_NRO_DCT_IDE_K AS RUT, 
          B.PEMID_DVR_NRO_DCT_IDE AS DV,
              INPUT(B.PEMID_GLS_NRO_DCT_IDE_K,best.) as RUT1
      FROM WORK.BASE_MPDT007 AS A INNER JOIN R_BOPERS.BOPERS_MAE_IDE AS B ON (A.ID = B.PEMID_NRO_INN_IDE);
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
   CREATE TABLE PASO2 AS 
   SELECT t1.CODENT, 
          t1.CENTALTA, 
          t1.CUENTA, 
          t1.LINEA, 
          t1.FECFAC, 
          t1.IMPFAC, 
          t1.ORIGENOPE, 
          t1.CODCOM, 
          t1.PORINT, 
          t1.FINAN, 
          t2.RUT, 
          t2.DV
      FROM WORK.PASO1 AS t1, WORK.BASE_RUT AS t2
      WHERE (t1.CODENT = t2.CODENT AND t1.CENTALTA = t2.CENTALTA AND t1.CUENTA = t2.CUENTA);
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
   CREATE TABLE PASO3 AS 
   SELECT t1.RUT, 
          t1.CUENTA, 
          /* SUM_of_IMPFAC */
            (SUM(t1.IMPFAC)) FORMAT=19.2 AS SUM_of_IMPFAC, 
          /* SUM_of_FINAN */
            (SUM(t1.FINAN)) AS SUM_of_FINAN
      FROM WORK.PASO2 AS t1
      GROUP BY t1.RUT, t1.CUENTA;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
   CREATE TABLE PASO4 AS 
   SELECT t1.RUT, 
          t1.CUENTA, 
          /* TASA_PONDERADA */
            (t1.SUM_of_FINAN/t1.SUM_of_IMPFAC) FORMAT=COMMA8.2 AS TASA_PONDERADA
      FROM WORK.PASO3 AS t1;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
CREATE TABLE PASO5 AS
SELECT *,
CASE WHEN TASA_PONDERADA  BETWEEN 0.00 AND 0.999999999 THEN '0 - 0.9'
WHEN TASA_PONDERADA BETWEEN 1.00 AND 1.5999999999 THEN '1.0 - 1.5'
WHEN TASA_PONDERADA BETWEEN 1.60 AND 2.0999999999 THEN '1.6 - 2.0'
WHEN TASA_PONDERADA BETWEEN 2.10 AND 2.5999999999 THEN '2.1 - 2.5'
WHEN TASA_PONDERADA BETWEEN 2.60 AND 3.0999999999 THEN '2.6 - 3.0'
WHEN TASA_PONDERADA BETWEEN 3.10 AND 3.5999999999 THEN '3.1 - 3.5'
WHEN TASA_PONDERADA BETWEEN 3.60 AND 4.0999999999 THEN '3.6 - 4.0'
WHEN TASA_PONDERADA > 4.10 THEN '4.1' END  AS TRAMO_TSA
FROM WORK.PASO4;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


DATA _null_;

datex = input(put(intnx('month',today(),-1,'same'),yymmn6. ),$10.);
Call symput("fechax", datex);
RUN;
%put &fechax;
PROC SQL;
create table result.TASA_POND_&fechax AS
SELECT *
FROM PASO5 ;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SURVEYSELECT DATA=BASE_UNIDA 
      OUT=BASE_PRUEBA
      METHOD=SRS
      N= 10
      SEED=1
      ;RUN;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
   CREATE TABLE PRUEBA AS 
   SELECT t1.CODENT, 
          t1.CENTALTA, 
          t1.CUENTA, 
          t1.LINEA, 
          t1.FECFAC, 
          t1.IMPFAC, 
          t1.ORIGENOPE, 
          t1.CODCOM, 
          t1.PORINT
      FROM WORK.BASE_UNIDA AS t1
      WHERE t1.CUENTA = '100000056811';
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


%exit:

/* REGISTRO DE ERRORES */

data _null_;
FECHA_PROCESO=cat((put(intnx('month',TODAY(),0,'same'),yymmdd10.)) ,"  " , (put(intnx('month',timepart(TIME()),0,'same'),hhmm8.2)) );
call symput("FECHA_DETALLE",FECHA_PROCESO);
run;


%put &syserr;
%put &FECHA_DETALLE; 
%let error = &syserr;
%put &error;
proc sql outobs=1 noprint ; 
          select  
                case  
                     when &error=0 then "Ejecución completada con éxito y sin mensajes de advertencia"
                     when &error=1 then "La ejecución fue cancelada por un usuario con una declaración RUN CANCEL."
                     when &error=2 then "La ejecución fue cancelada por un usuario con un comando ATTN o BREAK."
                     when &error=3 then "Un error en un programa ejecutado en modo por lotes o no interactivo causó que SAS ingresara al modo de verificación de sintaxis."
                     when &error=4 then "Ejecución completada con éxito pero con mensajes de advertencia."
                     when &error=5 then "La ejecución fue cancelada por un usuario con una sentencia ABORT CANCEL."
                     when &error=6 then "La ejecución fue cancelada por un usuario con una declaración ABORTAR CANCELAR ARCHIVO."
                     when &error=108 then "Problema con uno o más grupos BY"
                     when &error=112 then "Error con uno o más grupos BY"
                     when &error=116 then "Problemas de memoria con uno o más grupos BY"
                     when &error=120 then "Problemas de E / S con uno o más grupos BY"
                     when &error=1008 then "Problema general de datos"
                     when &error=1012 then "Condición de error general"
                     when &error=1016 then "Condición de falta de memoria"
                     when &error=1020 then "Problema de E / S"
                     when &error=2000 then "Problema de acción semántica"
                     when &error=2001 then "Problema de procesamiento de atributos"
                     when &error=3000 then "Error de sintaxis"
                     when &error=4000 then "No es un procedimiento válido."
                     when &error=9000 then "Error en el procedimiento"
                     when &error=20000 then "Se detuvo un paso o se emitió una declaración ABORT."
                     when &error=20001 then "Se emitió una declaración ABORT RETURN."
                     when &error=20002 then "Se emitió una declaración ABORT ABEND."
                     when &error=25000 then "Error grave del sistema. El sistema no puede inicializarse o continuar."
                end 
          as infoerror   into: infoerr
                from sashelp.air;
quit;

%let FEC_DET = "&FECHA_DETALLE";
%LET DESC = "&infoerr";  





	  proc sql ;
	  INSERT INTO result.tbl_estado_proceso
	  VALUES ( &error, &DESC, &FEC_DET , &NOMBRE_PROCESO );
	  quit;
   %put inserta el valor syserr &syserr y error &error;


%mend;

%principal();


* Inicio del código EG generado (no editar esta línea);
;*';*";*/;quit;
%STPEND;

* Fin del código EG generado (no editar esta línea);

