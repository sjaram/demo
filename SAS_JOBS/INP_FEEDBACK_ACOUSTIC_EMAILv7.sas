/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS			================================*/
/*==================================    INP_FEEDBACK_ACOUSTIC_EMAIL		================================*/
/* CONTROL DE VERSIONES
/* 2023-04-12 -- V7 -- Sergio J. -- Refactorización de proceso creando tabla columnar particionada por periodo

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
	- work.OUTPUT_EMAIL
	- LIBCOMUN.OUTPUT_EMAIL


*//*============================================================================================	*/
/*	IMPORTAR ARCHIVO DIARIO CON INFORMACIÓN EMAIL	*/
/*	============================================================================================	*/

/* VARIABLE TIEMPO - INICIO */
%let tiempo_inicio= %sysfunc(datetime());

%macro ciclos(i);
options validvarname=any;

DATA null_;
fgenera = compress(input(put(today()-&i.,yymmdd10.),$10.),"-",c);
Call symput("fechaDIA",fgenera);
RUN;
%let libreria=libcomun;
%put &fechaDIA;
%put &libreria;

data _null;
date1 = today()-&i.;
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
INSERT INTO &libreria..OUTPUT_EMAIL 
(
recipient_id,
recipient_type,
mailing_id,
report_id,
campaign_id,
email,
event_type,
event_timestamp,
body_type,
content_id,
click_name,
conversion_action,
conversion_detail,
conversion_amount,
suppression_reason,
mailing_name,
return_from_name,
return_from_address,
id_usuario,
customer_id,
sto,
codigo,
area,
producto,
fecha,
periodo)

SELECT
recipient_id,
recipient_type,
mailing_id,
report_id,
campaign_id,
email,
event_type,
event_timestamp,
body_type,
content_id,
click_name,
conversion_action,
conversion_detail,
conversion_amount,
suppression_reason,
mailing_name,
return_from_name,
return_from_address,
id_usuario,
customer_id,
sto,
codigo,
area,
producto,
fecha,
periodo
FROM feedback_email_4
where fecha=&date1.;
quit;

proc datasets library=WORK kill noprint;
run;
quit;

%mend ciclos;
%ciclos(1);

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/* VARIABLE TIEMPO - FIN */
data _null_;
dur = datetime() - &tiempo_inicio;
put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;
