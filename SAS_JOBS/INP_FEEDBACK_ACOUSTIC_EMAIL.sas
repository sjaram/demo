/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS			================================*/
/*==================================    INP_FEEDBACK_ACOUSTIC_EMAIL		================================*/
/* CONTROL DE VERSIONES
/* 2022-10-26 -- V6 -- Sergio J. -- Exportación incremental a aws

/* 2021-06-14 -- V5 -- Sergio J. --  
					-- Separación del campcode en código, área y producto
/* 2021-05-12 -- V4 -- Sergio J. --  
					-- Eliminación tablas diarias. Estarán todas ingresadas en el cierre mensual
/* 2021-04-28 -- V3 -- Sergio J. --  
					-- Filtro de creación por fecha del día actual (para eliminar duplicados)
/* 2021-04-22 -- V2 -- Sergio J. --  
					-- Modificación en la importación, eliminación de duplicados y se agrega
					   campo fecha.
/* 2021-01-16 -- V1 -- David V. --  
					-- Versión Original
/* INFORMACIÓN:
	Disponibiliza el feedback de las campañas en sas.

	(IN) Tablas requeridas o conexiones a BD:
	- /sasdata/users94/user_bi/unica/output/OUTPUT_EMAIL_&fechaDIA;

	(OUT) Tablas de Salida o resultado:
	- work.OUTPUT_EMAIL_&fechaDIA
	- LIBCOMUN.OUTPUT_EMAIL_&fechaMES


*//*============================================================================================	*/
/*	IMPORTAR ARCHIVO DIARIO CON INFORMACIÓN EMAIL	*/
/*	============================================================================================	*/

/* VARIABLE TIEMPO - INICIO */
%let tiempo_inicio= %sysfunc(datetime());
options validvarname=any;

DATA _null_;
fgenera = compress(input(put(today()-1,yymmdd10.),$10.),"-",c);
dateMES	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/

Call symput("fechaMES", dateMES);
Call symput("fechaDIA",fgenera);
RUN;
%let libreria=libcomun;
%put &fechaDIA;
%put &libreria;
%put &fechaMES;


data _null_;
date1 = today()-1;
format date1 e8601da.;
Call symput("date1",date1);
run;
%put &date1;

%LET VAR=/sasdata/users94/user_bi/unica/output/OUTPUT_EMAIL_&fechaDIA;
%PUT &VAR;

/*	============================================================================================	*/
/*		*/
/*	============================================================================================	*/


DATA feedback_email;
    LENGTH
        recipient_id       8
        recipient_type   $ 6
        mailing_id         8
        report_id          8
        campaign_id        8
        email            $ 41
        event_type       $ 13
        event_timestamp    8
        body_type        $ 4
        content_id       $ 1
        click_name       $ 38
        url              $ 170
        conversion_action $ 1
        conversion_detail $ 1
        conversion_amount $ 1
        suppression_reason $ 30
        mailing_name     $ 69
        return_subject   $ 125
        return_from_name $ 21
        return_from_address $ 44
        id_usuario         8
        customer_id        8
        sto                8
        codigo           $ 15
        area             $ 3
        producto         $ 4 ;
    FORMAT
        recipient_id     BEST12.
        recipient_type   $CHAR6.
        mailing_id       BEST8.
        report_id        BEST10.
        campaign_id      BEST8.
        email            $CHAR41.
        event_type       $CHAR13.
        event_timestamp  mdyampm25.
        body_type        $CHAR4.
        content_id       $CHAR1.
        click_name       $CHAR38.
        url              $CHAR170.
        conversion_action $CHAR1.
        conversion_detail $CHAR1.
        conversion_amount $CHAR1.
        suppression_reason $CHAR30.
        mailing_name     $CHAR69.
        return_subject   $CHAR125.
        return_from_name $CHAR21.
        return_from_address $CHAR44.
        id_usuario       BEST8.
        customer_id      BEST8.
        sto              BEST3.
        codigo           $CHAR15.
        area             $CHAR3.
        producto         $CHAR4. ;
    INFORMAT
        recipient_id     BEST12.
        recipient_type   $CHAR6.
        mailing_id       BEST8.
        report_id        BEST10.
        campaign_id      BEST8.
        email            $CHAR41.
        event_type       $CHAR13.
        event_timestamp  mdyampm25.
        body_type        $CHAR4.
        content_id       $CHAR1.
        click_name       $CHAR38.
        url              $CHAR170.
        conversion_action $CHAR1.
        conversion_detail $CHAR1.
        conversion_amount $CHAR1.
        suppression_reason $CHAR30.
        mailing_name     $CHAR69.
        return_subject   $CHAR125.
        return_from_name $CHAR21.
        return_from_address $CHAR44.
        id_usuario       BEST8.
        customer_id      BEST8.
        sto              BEST3.
        codigo           $CHAR15.
        area             $CHAR3.
        producto         $CHAR4. ;
infile "&VAR"

    DELIMITER=';'
    FIRSTOBS=2
    MISSOVER
    DSD
    LRECL=32767;
    INPUT
        recipient_id     : ?? BEST12.
        recipient_type   : $CHAR6.
        mailing_id       : ?? BEST8.
        report_id        : ?? BEST10.
        campaign_id      : ?? BEST8.
        email            : $CHAR41.
        event_type       : $CHAR13.
        event_timestamp  : ?? mdyampm25.
        body_type        : $CHAR4.
        content_id       : $CHAR1.
        click_name       : $CHAR38.
        url              : $CHAR170.
        conversion_action : $CHAR1.
        conversion_detail : $CHAR1.
        conversion_amount : $CHAR1.
        suppression_reason : $CHAR30.
        mailing_name     : $CHAR69.
        return_subject   : $CHAR125.
        return_from_name : $CHAR21.
        return_from_address : $CHAR44.
        id_usuario       : ?? BEST8.
        customer_id      : ?? BEST8.
        sto              : ?? BEST3.
        codigo           : $CHAR15.
        area             : $CHAR3.
        producto         : $CHAR4. ;

RUN;

proc sort data=work.feedback_email out=work.feedback_email_2
noduprecs dupout=malos; by _all_;
run;

proc sql;
create table feedback_email_3 as 
select *
,datepart(event_timestamp) format=e8601da. as fecha
from work.feedback_email_2;
quit;

proc sql;
create table feedback_email_4 as 
select *
,input(put(fecha,yymmn6.),best.) as periodo
from work.feedback_email_3;
quit;


PROC SQL;
CREATE TABLE OUTPUT_EMAIL_&fechaDIA AS 
SELECT * 
FROM feedback_email_4
where fecha=&date1.;
quit;

/*== Export a AWS para tableau ==== EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_INCREMENTAL_DIARIO.sas";
%INCREMENTAL(sas_camp_output_email,work.OUTPUT_EMAIL_&fechaDIA,raw,sasdata,-1);


/*	============================================================================================	*/
/*	CREAR TABLA PERIODICA DE - EMAIL	*/
/*	============================================================================================	*/

%MACRO PRUEBA (libreria, fechaMES, fechaDIA);

%IF %sysfunc(exist(&libreria..OUTPUT_EMAIL_&fechaMES.)) %then %do;

PROC SQL;
INSERT INTO &libreria..OUTPUT_EMAIL_&fechaMES 
SELECT *
FROM  OUTPUT_EMAIL_&fechaDIA;

;RUN; 

%end;
%else %do;

proc sql;
   create table &libreria..output_email_&fechames. as 
   select *
      from  OUTPUT_EMAIL_&fechaDIA t1;
run;


%end;

%mend ;
%PRUEBA (&libreria., &fechaMES., &fechaDIA.);


proc datasets library=WORK kill noprint;
run;
quit;

/* VARIABLE TIEMPO - FIN */
data _null_;
dur = datetime() - &tiempo_inicio;
put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;

/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;


data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1", "&DEST_2")
SUBJECT = ("MAIL_AUTOM: TEST - Proceso INP_FEEDBACK_ACOUSTIC_EMAIL");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso INP_FEEDBACK_ACOUSTIC_EMAIL_&fechaDIA, ejecutado con fecha: &fechaeDVN";  
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 06'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
