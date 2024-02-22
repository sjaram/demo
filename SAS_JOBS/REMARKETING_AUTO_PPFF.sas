/* se modifico 16-10-2019 */

LIBNAME UNICA ORACLE SCHEMA='UNICACAR_ADM' USER='UNICACAR_ADM' PASSWORD='adm_unicacar'
PATH="(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=10.0.148.146)(PORT=1521))(CONNECT_DATA=(SERVER=dedicated)(SERVICE_NAME=unicacar)))";
LIBNAME QANEWHB ORACLE  PATH="QANEW.WORLD"  SCHEMA=HBPRI_ADM  USER=RIPLEYC  PASSWORD='ri99pley';


 
 
DATA _null_;
date000 = input(put(intnx('month',today(),0,'same'),yymmn6. ),$10.);
date0 = input(put(intnx('day',today(),-1,'same'),date9.),date9.)  ;
date1 = input(put(intnx('day',today(),-3,'same'),date9.),date9.)  ;
date2 = put(intnx('day',today(),-10,'same'),date9.) ;
date3 = put(intnx('day',today(),-60,'same'),date9.) ;
date00 = put(intnx('month',today(),0,'same'),yymmn6. );
date11 = put(intnx('month',today(),-1,'same'),yymmn6. );
Call symput("fecha000", date000);
Call symput("fecha0", date0);
Call symput("fecha1", date1);
Call symput("fecha2", date2);
Call symput("fecha3", date3);
Call symput("fecha00", date00);
Call symput("fecha11", date11);
RUN;
 
%put &fecha0;
%put &fecha1;
%put &fecha2;
%put &fecha00;
%put &fecha11;

PROC SQL;
   CREATE TABLE work.simulaciones_hoy AS 
   SELECT DISTINCT t1.RUT, FECHA
      FROM publicin.simulaciones_sav_av_&fecha00 t1
	  WHERE t1.RUT IS NOT NULL
	  and FECHA >= "&fecha2"d 
	  and t1.ENLOG_NOM_URL not like "%/superAvance/enLinea/destino%"
	  union
	SELECT DISTINCT t1.RUT, FECHA
      FROM publicin.simulaciones_sav_av_&fecha11 t1
	  WHERE t1.RUT IS NOT NULL
	    and FECHA >= "&fecha2"d
		and t1.ENLOG_NOM_URL not like "%/superAvance/enLinea/destino%"
;QUIT;


PROC SQL;
   CREATE TABLE WORK.SIMULACIONES_HOY_2 AS 
   SELECT t1.RUT, 
          t1.fecha, 
          weekday(t1.fecha) as dia_semana
      FROM WORK.SIMULACIONES_HOY t1
	  WHERE t1.fecha<=&fecha0
;
QUIT;
 
PROC SQL;
   CREATE TABLE work.relacion_dia_semana AS 
   SELECT t1.RUT, FECHA,
          case when t1.dia_semana =1 then &fecha0-2 when t1.dia_semana <>1 then &fecha0 end format=date9. as dia_relativo
 
      FROM WORK.SIMULACIONES_HOY_2 t1 
	  having dia_relativo<=FECHA

;
QUIT;
 

PROC SQL;
   CREATE TABLE work.SIMULACIONES_PASADAS AS 
   SELECT t1.RUT,FECHA,
   case when t1.dia_semana =1 then &fecha0-2 when t1.dia_semana <>1 then &fecha0 end format=date9. as dia_relativo
 
      FROM WORK.SIMULACIONES_HOY_2 t1
	   having dia_relativo>FECHA

;
QUIT;
 
PROC SQL;
   CREATE TABLE work.PF_INTERNET_TRX_pre AS 
   SELECT  iNPUT((SUBSTR(HDVOU_NOM_NOM_USR,1,(LENGTH(HDVOU_NOM_NOM_USR)-1))),BEST.) as rut
      FROM QANEWHB.HBPRI_HIS_DET_VOU t1
WHERE 'x'='x'
and t1.HDVOU_FCH_CPR >= "&fecha2:00:00:00"dt 
and   t1.HDVOU_COC_TOP_IDE NOT IN 
           ('BILL_PAYMENT','CASH_ADVANCE' ,
           'CREDITCARD_PAYMENT',
           'CREDITLINE_PAYMENT',
           'EXTERNAL_TRANSFER',
           'EXTERNAL_TRANSFER_TO_THIRD',
           'INTERNAL_TRANSFER',
           'INTERNAL_TRANSFER_BETWEEN_OWN_PRODUCTS',
           'INTERNAL_TRANSFER_TO_THIRD',
           'LOAN_INSTALLMENT_PAYMENT',
           'LOAN_SIMULATION_REQUEST',
           'TERM_DEPOSIT'
           );
QUIT;
 
 
PROC SQL;
   CREATE TABLE work.trx_all AS 
   SELECT t1.RUT,fecha format=date9. as fecha
      FROM PUBLICIN.TRX_SAV_&fecha00 t1
       having fecha >= "&fecha3"d
       union 
   SELECT t1.RUT,fecha format=date9. as fecha
      FROM PUBLICIN.TRX_SAV_&fecha11 t1
       having fecha >= "&fecha3"d
 
;QUIT;
 PROC SQL;
   CREATE TABLE work.aprobados AS 
   SELECT t1.RUT_REAL, 
          t1.MONTO_PARA_CANON as monto,
           ACTIVIDAD_TR,
		   RANGO_PROB,SAV_APROBADO_FINAL
      FROM JABURTOM.SAV_CAR_&fecha000 t1
      WHERE t1.SAV_APROBADO_FINAL = 1


	  union

	     SELECT t1.RUT_REAL, 
          t1.MONTO_PARA_CANON as monto,
           ACTIVIDAD_TR,
		   RANGO_PROB,SAV_APROBADO_FINAL
      FROM JABURTOM.SAV_CAR_INCREM_&fecha000 t1
      WHERE t1.SAV_APROBADO_FINAL = 1

;QUIT;

PROC SQL;
   CREATE TABLE work.SAV_TARGET_FINAL AS 
   SELECT distinct t1.RUT as customer_id, primer_nombre, email,fecha,dia_relativo
      FROM WORK.RELACION_DIA_SEMANA t1 left join publicin.BASE_TRABAJO_EMAIL t2 on (t1.RUT =t2.rut)
                                        left join publicin.BASE_NOMBRES t3 on (t1.RUT =t3.rut)
	  where  t1.RUT not in (select rut from publicin.LNEGRO_CAR)
	  and email is not null
	  and primer_nombre is not null
	  and t1.RUT not in (select rut from trx_all)
	  and t1.RUT not in (select rut from PF_INTERNET_TRX_pre)
	  and t1.RUT  in (select RUT_REAL from aprobados)
;QUIT;

 
PROC SQL;
   CREATE TABLE work.simulaciones_hoy AS 
   SELECT DISTINCT t1.RUT, FECHA
      FROM publicin.simulaciones_sav_av_&fecha00 t1
	  WHERE t1.RUT IS NOT NULL
	  and FECHA >= "&fecha2"d 
	  and t1.ENLOG_NOM_URL  like "%/avances/enLinea/destino%"
	  union
	SELECT DISTINCT t1.RUT, FECHA
      FROM publicin.simulaciones_sav_av_&fecha11 t1
	  WHERE t1.RUT IS NOT NULL
	    and FECHA >= "&fecha2"d
		and t1.ENLOG_NOM_URL  like "%/avances/enLinea/destino%"
;QUIT;
 

PROC SQL;
   CREATE TABLE work.relacion_dia_semana AS 
   SELECT t1.RUT, FECHA,
          case when t1.dia_semana =1 then &fecha0-2 when t1.dia_semana <>1 then &fecha0 end format=date9. as dia_relativo
 
      FROM WORK.SIMULACIONES_HOY_2 t1 
	  having dia_relativo<=FECHA

;
QUIT;
 

PROC SQL;
   CREATE TABLE work.SIMULACIONES_PASADAS AS 
   SELECT t1.RUT,FECHA,
   case when t1.dia_semana =1 then &fecha0-2 when t1.dia_semana <>1 then &fecha0 end format=date9. as dia_relativo
 
      FROM WORK.SIMULACIONES_HOY_2 t1
	   having dia_relativo>FECHA

;
QUIT;
 
 
PROC SQL;
   CREATE TABLE PF_INTERNET_TRX_pre AS 
   SELECT  iNPUT((SUBSTR(HDVOU_NOM_NOM_USR,1,(LENGTH(HDVOU_NOM_NOM_USR)-1))),BEST.) as rut
      FROM QANEWHB.HBPRI_HIS_DET_VOU t1
WHERE 'x'='x'
and t1.HDVOU_FCH_CPR >= "&fecha2:00:00:00"dt 
and   t1.HDVOU_COC_TOP_IDE NOT IN 
           ('BILL_PAYMENT','SUPER_CASH_ADVANCE',
           'CREDITCARD_PAYMENT',
           'CREDITLINE_PAYMENT',
           'EXTERNAL_TRANSFER',
           'EXTERNAL_TRANSFER_TO_THIRD',
           'INTERNAL_TRANSFER',
           'INTERNAL_TRANSFER_BETWEEN_OWN_PRODUCTS',
           'INTERNAL_TRANSFER_TO_THIRD',
           'LOAN_INSTALLMENT_PAYMENT',
           'LOAN_SIMULATION_REQUEST',
           'TERM_DEPOSIT'
           );
QUIT;
 
 PROC SQL;
   CREATE TABLE AVANCE_SELECCION AS 
   SELECT t1.RUT_REGISTRO_CIVIL
      FROM PUBLICRI.AVANCE_SELECCION_&fecha000  t1;
QUIT;


 
PROC SQL;
   CREATE TABLE AV_TARGET_FINAL AS 
   SELECT distinct t1.RUT as customer_id, primer_nombre, email,fecha,dia_relativo
      FROM WORK.RELACION_DIA_SEMANA t1 left join publicin.BASE_TRABAJO_EMAIL t2 on (t1.RUT =t2.rut)
                                        left join publicin.BASE_NOMBRES t3 on (t1.RUT =t3.rut)
	  where t1.RUT not in (select rut from publicin.LNEGRO_CAR)
	  and email is not null
	  and primer_nombre is not null
	  and t1.RUT not in (select rut from PF_INTERNET_TRX_pre)
	  and t1.RUT  in (select RUT_REGISTRO_CIVIL from AVANCE_SELECCION)
;QUIT;



PROC SQL;
   CREATE TABLE result.PPFF_SIMULACIONES_FINAL AS 
   SELECT distinct customer_id, primer_nombre, email, 'AV' AS PRODUCTO
     FROM AV_TARGET_FINAL
	 WHERE customer_id NOT IN (SELECT CUSTOMER_ID FROM SAV_TARGET_FINAL)

	 UNION

	SELECT distinct customer_id, primer_nombre, email, 'SAV' AS PRODUCTO
     FROM SAV_TARGET_FINAL
	 
	 UNION
	SELECT distinct customer_id, primer_nombre, email, 'SAV' AS PRODUCTO
     FROM EPIELH.SIEMBRA_RMKT

	  
	 
;QUIT;

proc export data=RESULT.PPFF_SIMULACIONES_FINAL
 OUTFILE="/sasdata/users94/ougarte/temp/PPFF_SIMULACIONES_FINAL.CSV"
 dbms=dlm replace;
 delimiter=',';
 PUTNAMES=yes;
RUN;
