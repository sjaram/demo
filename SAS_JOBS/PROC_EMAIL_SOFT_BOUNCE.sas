/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROC_EMAIL_SOFT_BOUNCE		================================*/
/* CONTROL DE VERSIONES
/* 2020-09-22 ---- Original 
/* 2022-01-25 ----  SE CAMBIA ORIGEN DE LOS REBOTES SUAVES (TABLA DE COMUNICACIONES)
*/
/*==================================================================================================*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/


DATA _null_;
datex0 = put(intnx('month',today(),0,'same'),yymmn6. );
Call symput("fechax0", datex0);
RUN;

PROC SQL;
   CREATE TABLE SP_REBOTE_SUAVE AS 					
   SELECT t1.customer_id as RUT, 
          t1.EMAIL length=50
      FROM LIBCOMUN.output_email_&fechax0 t1
	  where event_type='Soft Bounce'
	  GROUP BY t1.EMAIL
	order by 1
    ;
QUIT;

PROC SQL;
CREATE TABLE result.SP_REBOTE_SUAVE_&fechax0 AS 
SELECT 
distinct RUT,
EMAIL
FROM SP_REBOTE_SUAVE

;QUIT;


proc sort data=result.SP_REBOTE_SUAVE_&fechax0 out=result.SP_REBOTE_SUAVE_&fechax0 nodupkeys dupout=WORK.duplicados_RUT_rebote;
by EMAIL;
run;


PROC SQL;
CREATE INDEX EMAIL ON result.SP_REBOTE_SUAVE_&fechax0  (EMAIL);
QUIT;



/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */
