* Inicio del código EG generado (no editar esta línea);
*
*  Procedimiento almacenado registrado por
*  Enterprise Guide Stored Process Manager V7.1
*
*  ====================================================================
*  Nombre del proceso almacenado: DISPONIBLE_RP
*  ====================================================================
*;


*ProcessBody;

* Start before STPBEGIN code [78f145a3cf8542008d588524ed4d65b6];/* Insertar código personalizado ejecutado delante de la macro STPBEGIN */
%global _ODSDEST;
%let _ODSDEST=none;
* End before STPBEGIN code [78f145a3cf8542008d588524ed4d65b6];

%STPBEGIN;

* Fin del código EG generado (no editar esta línea);


/*===== FECHAS =======================================================================================================================*/

DATA _null_;
datex 	= input(put(intnx('month',today(),0,'end'),yymmn6.),$10.);      /*cambiar 0 a -1 para ver cierre mes anterior*/
exec = PUT(DATETIME(),DATETIME20.);

Call symput("fechax", datex);
Call symput("fechae",exec);
RUN;

%put &fechax;
%put &fechae;

/*===== CONSULTA =======================================================================================================================*/

LIBNAME PSFC1 ORACLE PATH='PSFC1' SCHEMA='GETRONICS' USER='PMANRIQUEZD' PASSWORD= 'PMAN#_8042';


/*===== DISPO_RP =======================================================================================================================*/

PROC SQL;
CREATE TABLE PUBLICIN.DISPONIBLE_RP_&fechax AS /*cambiar el mes*/
SELECT INPUT(CODCUENT,BEST.) AS RUT, CANTPUNT AS PUNTOS, "&fechae" as FEC_EX
FROM PSFC1.T7542700 T1
WHERE T1.TIPOPUNT = '01';
QUIT;

* Inicio del código EG generado (no editar esta línea);
;*';*";*/;quit;
%STPEND;

* Fin del código EG generado (no editar esta línea);

