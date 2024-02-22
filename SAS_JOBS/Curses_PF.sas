%macro principal();
 
%LET NOMBRE_PROCESO = 'CURSES_PF';


DATA _null_;
I_Actual  = input(put(intnx('month',today(),0,'begin' ),Date9.  ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
T_Actual = input(put(today()-1,Date9.),$10.);
datex	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*Mes Actual*/
datey	= input(put(intnx('month',today(),-1,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
exec	= compress(input(put(today(),yymmdd10.),$10.),"-",c);
exec1	= compress(input(put(intnx('month',today(),0,'begin' ),yymmdd10.  ),$10.),"-",c);
exec2	= compress(input(put(intnx('month',today(),0,'same' ),yymmdd10.  ),$10.),"-",c);

Call symput("inicio",I_Actual);
Call symput("termino",T_Actual);
Call symput("fechax", datex);
Call symput("fechay", datey);
Call symput("fechae",exec);
Call symput("fechae1",exec1);
Call symput("fechae2",exec2);
 
RUN;

%put &inicio; 
%put &termino;
%put &fechax;
%put &fechay; 
%put &fechae;
%put &fechae1;
%put &fechae2;

RUN;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

DATA _null_;
datehi   = compress(input(put(intnx('month',today(),-1,'begin' ),date9.   ),$20.),"-",c); /*cambiar 0 a -1 para ver cierre mes anterior*/
datehf  = compress(input(put(intnx('month',today(),-1,'end'        ),date9.                ),$20.),"-",c); /*cambiar 0 a -1 para ver cierre mes anterior*/
Call symput("fechahi",datehi);
Call symput("fechahf",datehf);
RUN;
%put &fechahi; 
%put &fechahf;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;



/************************ TRANSACCIONES CONSUMO MES EN CURSO *****************************/


%let mz_connect_BANCO=CONNECT TO ORACLE as BANCO(USER='RIPLEYC' PASSWORD='ri99pley'
PATH="  (DESCRIPTION = 
    (ADDRESS_LIST = 
      (ADDRESS = 
        (PROTOCOL = TCP)
        (Host = 192.168.10.31)
        (Port = 1521)
      )
    )
    (CONNECT_DATA = 
      (SID = ripleyc)
    )
  )
");


/* TRX CONSUMO MES */

/*PRE_FECEMI*/

proc sql;
&mz_connect_BANCO;
create table VTA_BANCO_ as
SELECT *
from  connection to BANCO(
select d.rut AS RUT_CLIENTE,
       sum (d.MONTO_LIQUIDO) VENTA_LIQUIDA,
       sum (d.MONTO_BRUTO) VENTA_BRUTA,
	   a.pre_fecemi,
	   a.pre_credito,
       a.pre_numper,
       a.pre_fecontab fecha_contble,
       a.pre_fecemi fecha_emision,
       a.pre_tasapac,
	   sum(a.pre_monto*a.pre_tasapac) monto_por_tasa,
       sum(a.pre_monto*a.pre_numper) monto_por_plazo
  from tpre_prestamos a,
       tcli_persona b,
       br_dm_colocaciones_bco_sav d
where a.pre_clientep = b.cli_codigo
   and substr(b.cli_identifica, 1, length(b.cli_identifica) - 1) = d.rut
   and d.fecini_promocion  = to_char(trunc(sysdate,'mm'), 'dd-mm-yyyy')
   and TRUNC (a.pre_fecONTAB) between trunc(sysdate, 'mm') and trunc(last_day(sysdate))
   and a.pre_pro not in(45,59,73,50,51,80,15,38,70,8,39,82,99,41) 
   and a.pre_status = 'E'
   and d.lugar_pago = 'BCO'
group by d.rut,
       a.pre_fecemi,
	   a.pre_credito,
       a.pre_numper,
       a.pre_fecontab,
       a.pre_fecemi,
       a.pre_tasapac
)A
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

/* TRX SAV MES */

PROC SQL;
   CREATE TABLE VTA_SAV AS 
   SELECT DISTINCT t1.RUT AS cliente_rut
      FROM PUBLICIN.TRX_SAV_&fechax t1
;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SQL;
   CREATE TABLE VTA_SAV_HB AS 
   SELECT DISTINCT t1.RUT AS cliente_rut
      FROM PUBLICIN.TRX_SAV_HB_&fechax t1
;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SQL;
   CREATE TABLE VTA_SAV_HB_1 AS 
   SELECT DISTINCT t1.RUT AS cliente_rut
      FROM PUBLICIN.TRX_SAV_HB_&fechay t1
;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SQL;
   CREATE TABLE VTA_SAV_1 AS 
   SELECT DISTINCT t1.RUT AS cliente_rut
      FROM PUBLICIN.TRX_SAV_&fechay t1
;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
   CREATE TABLE VTA_BANCO AS 
   SELECT DISTINCT t1.RUT
      FROM PUBLICIN.TRX_CONSUMO_&fechay t1;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

/* TRX SAV MES */

PROC SQL;
CREATE TABLE PUBLICIN.CURSES_PF AS 
SELECT DISTINCT RUT FROM(
SELECT RUT FROM PUBLICIN.TRX_REF_&fechax
UNION SELECT RUT FROM PUBLICIN.TRX_REF_&fechay 
UNION SELECT cliente_rut  AS RUT FROM VTA_SAV
UNION SELECT cliente_rut  AS RUT FROM VTA_SAV_1
UNION SELECT cliente_rut  AS RUT FROM VTA_SAV_HB
UNION SELECT cliente_rut  AS RUT FROM VTA_SAV_HB_1
/*UNION SELECT RUT AS RUT FROM VTA_BANCO_1*/
UNION SELECT RUT_CLIENTE AS RUT FROM VTA_BANCO_
UNION SELECT RUT AS RUT FROM VTA_BANCO )/* TRX PF UNIFCADAS */
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SQL;
DROP TABLE SAV_TRX
,VTA_BANCO_
,VTA_SAV
,VTA_SAV_HB
,VTA_SAV_HB_1
,VTA_SAV_1
,VTA_BANCO
;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

proc export data=PUBLICIN.CURSES_PF
	OUTFILE="/sasdata/users94/ougarte/temp/CURSES.CSV"
	dbms=dlm replace;
	delimiter=';';
	PUTNAMES=yes;
RUN;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


PROC SQL;
CREATE INDEX RUT ON PUBLICIN.DEMO_BASKET_&VdatePeriodoANT (RUT);
QUIT;

/*	=========================================================================	*/
/*			FIN : MEJORA PARA LA EDAD DE LOS DATOS - OBTENIDO DE BOPERS			*/
/*	=========================================================================	*/

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


%exit:

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
