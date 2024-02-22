/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	TRX_CONSUMO					 	 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-12-21 -- V02 -- David V.	-- Se agrega columna periodo en tabla para export to AWS.
/* 2022-11-07 -- V01 -- Sergio J.	-- Se agregan exportación a aws
/* 0000-00-00 -- V00 --    			-- Original
*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

options validvarname=any;


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



proc sql;
&mz_connect_BANCO;
create table TRX_BCO1 as
SELECT *
from  connection to BANCO(
select 
       a.pre_credito ,
       d.rut,
       sum (d.MONTO_LIQUIDO) VENTA_LIQUIDA,
       sum (d.MONTO_BRUTO) VENTA_BRUTA,
       a.pre_numper,
       a.pre_fecontab fecha_contble,
       a.pre_fecemi,
       a.pre_tasapac,
       decode(a.pre_sucursal, 0, 'HUERFANOS 1060', 1, 'HUERFANOS 1060', pkg_data_marketing.obtiene_nombre_sucursal(a.pre_sucursal)) sucursal,
       pkg_data_marketing.obtiene_nombre_zona_sucursal(a.pre_sucursal) zona,
       e.canal_agenda,
       F.PROPENSION * 10 propension,
       F.RANGO_PROPENSION,
       PKG_DATA_MARKETING.OBTIENE_RUT_EMPLEADO(a.pre_codeje) rut_Ejecutivo_curse,
       pkg_data_marketing.OBTIENE_NOMBRE_USUARIO(a.PRE_CODEJE) Nombre_Ejecutivo_curse,
       G.LEVERAGe,
       h.prd_nombre,
       e.nombre_promocion PROMO_BASE,
	   e.nombre_promocion as NOMBRE_PROMOCION,
       E.CUPO_PROMO MONTO_OFERTA_PROMO_BASE
  from tpre_prestamos a,
       tcli_persona b,
       br_dm_colocaciones_bco_sav d,
       br_Cam_minuta_final e,
       br_dm_propension_crm f,
       br_dm_leverage_campanas g,
       (select prd_pro,
        prd_nombre
        from tgen_productos
        where prd_mod = 6) h
 where a.pre_clientep = b.cli_codigo
   and substr(b.cli_identifica, 1, length(b.cli_identifica) - 1) = d.rut
   and d.fecini_promocion  = to_char(trunc(sysdate,'mm'), 'dd-mm-yyyy')
   and TRUNC (a.pre_fecONTAB) between trunc(sysdate, 'mm') and trunc(last_day(sysdate))
   and a.pre_pro not in(45,59,73,50,51,80,15,38,70,8,39,82,99,41) 
   and a.pre_status = 'E'
   and d.lugar_pago = 'BCO'
   and D.RUT = e.rut(+)
   and d.rut = f.rut(+)
   and d.rut = g.rut(+)
   and to_char(G.FECINI(+),'dd/mm/yyyy') = to_char(trunc(sysdate,'mm'), 'dd/mm/yyyy')
   and a.pre_pro = h.prd_pro
   and e.tipo_promo_plat(+) not in (66,69,70)
group by 
       a.pre_credito ,
       d.rut,
       a.pre_numper,
       a.pre_fecontab,
       a.pre_fecemi,
       a.pre_tasapac,
       a.pre_sucursal,
       e.canal_agenda,
       f.propension,
       f.rango_propension,
       a.pre_codeje,
       G.LEVERAGe,
       h.prd_nombre,
       E.NOMBRE_PROMOCION,
       e.cupo_promo
)A
;QUIT;


proc sql;
&mz_connect_BANCO;
create table MULTI1 as
SELECT *
from  connection to BANCO(
SELECT RUT, 
      NOMBRE_PROMOCION,
	  CUPO_PROMO
FROM BR_CAM_MINUTA_FINAL
WHERE TIPO_PROMO_PLAT = 66
)A
;QUIT;

proc sql;
&mz_connect_BANCO;
create table MULTI2 as
SELECT *
from  connection to BANCO(
SELECT RUT, 
      NOMBRE_PROMOCION,
	  CUPO_PROMO
FROM BR_CAM_MINUTA_FINAL
WHERE TIPO_PROMO_PLAT = 69
)A
;QUIT;


proc sql;
&mz_connect_BANCO;
create table MULTI3 as
SELECT *
from  connection to BANCO(
SELECT RUT, 
      NOMBRE_PROMOCION,
	  CUPO_PROMO
FROM BR_CAM_MINUTA_FINAL
WHERE TIPO_PROMO_PLAT = 70
)A
;QUIT;

proc sql;
CREATE TABLE BASE1
AS
SELECT 
   T1.*,
   T2.NOMBRE_PROMOCION AS MULTI1,
   T2.CUPO_PROMO AS OFERTA_MULTI1
  FROM 
     WORK.TRX_BCO1 AS T1
     LEFT JOIN WORK.MULTI1 AS T2 ON(T1.RUT = T2.RUT)
;quit;


proc sql;
CREATE TABLE BASE2
AS
SELECT 
   T1.*,
   T2.NOMBRE_PROMOCION AS MULTI2,
   T2.CUPO_PROMO AS OFERTA_MULTI2
  FROM 
     WORK.BASE1 AS T1
     LEFT JOIN WORK.MULTI2 AS T2 ON(T1.RUT = T2.RUT)
;quit;


proc sql;
CREATE TABLE BASE3
AS
SELECT 
   T1.*,
   T2.NOMBRE_PROMOCION AS MULTI3,
   T2.CUPO_PROMO AS OFERTA_MULTI3
  FROM 
     WORK.BASE2 AS T1
     LEFT JOIN WORK.MULTI3 AS T2 ON(T1.RUT = T2.RUT)
;quit;


PROC SQL;
CREATE TABLE PUBLICIN.TRX_CONSUMO_&fechax
AS
SELECT * FROM BASE3
;QUIT;

PROC SQL;
CREATE TABLE WORK.TRX_CONSUMO_&fechax AS
SELECT *, &fechax. as periodo  
FROM PUBLICIN.TRX_CONSUMO_&fechax
;QUIT;


%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_ppff_trx_consumo,raw,sasdata,0);

/*Exportación a AWS*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_ppff_trx_consumo,WORK.TRX_CONSUMO_&fechax.,raw,sasdata,0);


/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */

/*fecha proceso*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*preparacion envio correo*/
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_PPFF';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_1';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_2';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;	
%put &=DEST_6;


/*envio correo y adjunto archivo*/
data _null_;
FILENAME OUTBOX EMAIL
FROM	= ("&EDP_BI")
TO 		= ("&DEST_4","&DEST_5","&DEST_6")
CC 		= ("&DEST_1","&DEST_2","&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso TRX_CONSUMO");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "		Proceso TRX_CONSUMO, ejecutado automáticamente con fecha: &fechaeDVN";  
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 02'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
