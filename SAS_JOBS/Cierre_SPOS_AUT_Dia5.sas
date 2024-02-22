/*#################################################################################################*/
/*Generar tabla de SPOS del Periodo desde autorizaciones*/
/*#################################################################################################*/

%macro principal();
 
%LET NOMBRE_PROCESO = 'Cierre_SPOS_AUT_DIA5';

/* Se Borra y se crea el LOG de ejecucion */

/* Se borra el Archivo despues que se Cargo */

%put==========================================================================================;
%put [01] Sacar Periodo Actual;
%put==========================================================================================;


options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/



PROC SQL outobs=1 noprint;   

select 
case 
when DAY(today())>1 THEN input(SB_AHORA('AAAAMM'),best.)
ELSE SB_MOVER_ANOMES(input(SB_AHORA('AAAAMM'),best.),-1) 
END as Periodo_Ahora 
into 
:Periodo_Ahora 
from sashelp.vmember

;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

/*DATA _null_;*/
/*Periodo_Ahora=compress(put(&Periodo_Ahora, best.));*/
/*Call symput("Periodo_Ahora1",Periodo_Ahora);*/
/**/
/*run;*/

DATA _null_;
Periodo_Anterior=compress(put(&Periodo_Ahora-1, best.));
Call symput("Periodo_Anterior",Periodo_Anterior);

run;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

%put &Periodo_Anterior;

%put==========================================================================================;
%put [02] Crear Base;
%put==========================================================================================;
/*%put &Periodo_Ahora1;*/

/*LIBNAME MPDT  ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='PMANRIQUEZD' PASSWORD='PMAN#_1407';
LIBNAME BOPERS ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='PMANRIQUEZD' PASSWORD='PMAN#_1407';
*/
LIBNAME MPDT ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME BOPERS ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='AMARINAOC' PASSWORD='amarinaoc2017';

PROC SQL; 

create table PUBLICIN.SPOS_AUT_&Periodo_Anterior. as 
select 
X.COD_FECHA as Fecha, 
X.hortrn AS Hora,
floor(X.COD_FECHA/100) as Periodo, 
X.Codigo_Comercio, 
X.NOMCOM as Nombre_Comercio, 
X.RUBRO as Actividad_Comercio, 
X.RUT_CLIENTE as rut, 
X.VENTA_TARJETA, 
x.codpais, 
X.TOTCUOTAS,
X.PAN,
X.CODACT,
X.PORINT,
X.CODENT,
X.CENTALTA,
X.CUENTA,
CASE 
WHEN X.producto in('07','05','06','TARJETA M') THEN 'TAM' 
WHEN X.producto in('Credi2000','01','03','TARJETA R') THEN 'TR' 
WHEN X.producto = '08' THEN 'DEBITO' 
END AS Tipo_Tarjeta,  
(LEFT(SUBSTR(X.PAN,13,4))) as PAN2, 
CAT(X.CODENT,X.CENTALTA,X.CUENTA,calculated PAN2) as CONTRATO_PAN 

from ( 
SELECT 
C.CODENT, 
C.CENTALTA, 
C.CUENTA, 
b.PEMID_GLS_NRO_DCT_IDE_K, 
input(b.PEMID_GLS_NRO_DCT_IDE_K,best.) as RUT_CLIENTE, 
c.codpais, 
c.localidad, 
c.fectrn, 
c.hortrn, 
input(compress(c.fectrn,'-'),best.)  as cod_fecha, 
c.CODACT, 
d.DESACT as RUBRO, 
C.CODCOM, 
input(c.CODCOM,best32.) as Codigo_Comercio, 
c.NOMCOM, 
sum(c.imptrn) as VENTA_TARJETA, 
c.Tipfran, 
c.totcuotas, 
c.porint, 
c.PAN,
a.producto, 
c.tipofac, 
c.IMPCCA, 
c.CLAMONCCA, 
c.IMPDIV 
FROM MPDT.MPDT004 as c, 
MPDT.MPDT007 as a, 
BOPERS.bopers_mae_ide as b, 
MPDT.MPDT039 as d 
where input(a.IDENTCLI,best.) = b.PEMID_NRO_INN_IDE 
and (c.CODACT = d.CODACT) 
and (a.cuenta = c.cuenta) 
and c.CODACT <> 6011 
AND c.tipofac IN (1053,1350,1353,5250,1050,1650,5050,5150,5350,2750,2350,2050,6050,3010,2777,3050) 
and c.codrespu = '000' 
and tipfran <> 4 
and input(compress(fectrn,'-'),best.)>=100*&Periodo_Anterior+01 
and input(compress(fectrn,'-'),best.)<=100*&Periodo_Anterior+31 
AND PRODUCTO IN ('07','05','06','TARJETA M','Credi2000','01','03','TARJETA R') 
group by 
C.CODENT, 
C.CENTALTA, 
c.cuenta,  
b.PEMID_GLS_NRO_DCT_IDE_K, 
c.codpais, 
c.localidad, 
c.fectrn, 
c.CODACT, 
d.DESACT, 
C.CODCOM, 
C.NOMCOM, 
c.Tipfran, 
c.totcuotas, 
c.porint, 
c.hortrn, 
a.producto,
c.PAN,
c.tipofac,
c.IMPCCA,
c.CLAMONCCA,
c.IMPDIV 
) as X 

;QUIT; 

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


%exit:
%put &syserr;
%put &FECHA_DETALLE; 
%let error = &syserr;
%put &error;

data _null_;
FECHA_PROCESO=cat((put(intnx('month',TODAY(),0,'same'),yymmdd10.)) ,"  " , (put(intnx('month',timepart(TIME()),0,'same'),hhmm8.2)) );
call symput("FECHA_DETALLE",FECHA_PROCESO);
run;


proc sql ;
select infoerr 
into : infoerr 
from result.TBL_DESC_ERRORES
where error=&error;
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
