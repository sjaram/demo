/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	LEADS_SAV_CALL_CENTER			 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-12-05 -- V27 -- Andrea S.   -- Se agrega email en base simulaciones final
/* 2022-08-03 -- V26 -- David V.	-- Ajustes mínimos para ejecutar en servidor SAS.
/* 2022-08-01 -- V25 -- Jose Aburto	-- Se quita separación final, dejando solo una salida para call interno.
/* 2022-06-30 -- V24 -- David V. 	-- Se actualiza contraseña a nueva conexión a PWA
/* 2022-06-29 -- V23 -- David V. 	-- Agregar a Jefe y PM digital a correos de notificación
/* 2022-01-14 -- V22 -- David V. 	--
                     				-- Se agrega mail para enviar archivo con externo a EDP_BI
/* 2022-01-14 -- V21 -- Pedro Muñoz --
                     				-- Corrección de problema a días lunes + unifica ambas versiones en una sola
/* 2021-08-11 -- V20 -- Mauricio G. -- Version Original + agrega filtro de clientes consumon con oferta aprobada, origen FISA

/* INFORMACIÓN:
	Este proceso tiene como objetivo disponibilizar de los leads (remarketing financiero) a los calls center
	tanto externos como internos, en otras palabras cada vez que un cliente simula un producto financiero 
	y no cursa, lo mas pronto posible se le contacta para intentar persuadirlo de tomar ese producto u otro.

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

%let libreria_OUT	= RESULT;

options validvarname=any;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

/*##################################################################################################*/
/*Proceso de generacion simulaciones leads SAV para call center*/
/*##################################################################################################*/


/*********************************** Validar Proceso ***********************************************/


/************************************ Comenzar Proceso **********************************************/

/*PARAMETROS::*/
/*:::::::::::::::::::::::*/
%let hora_desde=18; /*hora dia desde corte simulaciones/leads desde dia anterior*/ 
%let recencia_simulaciones=15; /*dias hacia atras para excluir de simulaciones*/
/*%let Corte_Call=210; /*cantidad de casos maximo para call externo*/ 
%let Base_Entregable=%nrstr('RESULT.Leads_SAV'); /*nombre de base donde quedaran los resultados*/
/*:::::::::::::::::::::::*/

options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/

%put=======================================================================================;
%put [01] Definir fechas de corte dependiendo de dia (lunes vs resto de semana);
%put=======================================================================================;


DATA _null_;
         dated0 = input(put(intnx('DAY',today(),-1,'SAME'),date9. ),$10.) ;
		   sabado = input(put(intnx('DAY',today(),-2,'SAME'),date9. ),$10.) ;
         dated0P = input(put(intnx('DAY',today(),0,'SAME'),date9. ),$10.) ;
         dated1 = input(put(intnx('DAY',today(),-3,'SAME'),date9. ),$10.) ;
         dated14 = input(put(intnx('DAY',today(),-1*&recencia_simulaciones,'SAME'),date9. ),$10.) ; /*Fecha de hace 14 dias*/
         dateh = input(put(intnx('DAY',today(),0,'SAME'),weekday. ),best.) ;

dated14_PWA = input(put(intnx('DAY',today(),-1*&recencia_simulaciones,'SAME'),yymmdd10. ),$10.);
         dated0P_PWA = input(put(intnx('DAY',today(),0,'SAME'),yymmdd10. ),$10.) ;
            
          Call symput("fechad0", dated0);
		  Call symput("sabado", sabado);
          Call symput("fechad0P", dated0P);
          Call symput("fechad1", dated1);
          Call symput("fechad14", dated14);
          Call symput("fechah", dateh);
		  Call symput("dated14_PWA", dated14_PWA);
          Call symput("dated0P_PWA", dated0P_PWA);

          RUN;
 %put &sabado;
          %put &fechad0;
          %put &fechad0P;
          %put &fechad1;
          %put &fechad14;
          %put &fechah;
		  %put &dated14_PWA;
          %put &dated0P_PWA;


%put=======================================================================================;
%put [02] Calculo de Fechas con un case when (depende del dia de la semana);
%put=======================================================================================;

 

proc sql;

   connect to ODBC as myconn (user="ripley-bi" password="biripley00"
     DATASRC="BR-BACKENDHB"
);
create table SIMULATIONAVSAVVIEW as 
   select * ,  "&fechad0"d  format=date9. as fecha_r
      from connection to myconn
         ( SELECT  *
            from SIMULATIONAVSAVVIEW
			 where CAST(FechaSimulación AS date) BETWEEN %str(%')&dated14_PWA.%str(%') AND %str(%')&dated0P_PWA.%str(%')

           );

   disconnect from myconn;
quit;


PROC SQL NOPRINT; 
 
select put(max(fecha_r),date9.) as fecha_r
into :fecha_r
from WORK.SIMULATIONAVSAVVIEW 

;QUIT;

%let fec=&fecha_r;


%put=======================================================================================;
%put [03] calcular Oferta sav aprobado cargado  en bbdd campañas para filtrar;
%put=======================================================================================;

/*815011*/
PROC SQL ;
CONNECT TO ORACLE AS CAMPANAS (PATH="BRTEFGESTIONP.WORLD" USER='CAMP_COMERCIAL' PASSWORD='ccomer2409');
CREATE TABLE OFERTA_SAV_APROBADO AS
SELECT * FROM CONNECTION TO CAMPANAS(
SELECT DISTINCT
A.CAMP_RUT_CLI AS RUT, 
A.CAMP_COD_CND_PROD, 
/*A.CAMP_MRC_PROD_ADM, */
A.CAMP_FLG_CAMP,
b.CAMP_EST_CAMP
FROM CBCAMP_MAE_OFERTAS A
inner join CBCAMP_MAE_CAMPANA b on (A.CAMP_COD_CAMP_FK=b.CAMP_COD_CAMP_K)
where  b.CAMP_EST_CAMP in (2) /* CAMPAÑA VIGENTE Y DISTRIBUIDA */ 
and a.CAMP_FLG_CAMP in (1) /* OFERTA  VIGENTE  */
and  a.CAMP_COD_TIP_PROD in ('6') /* PRODUCTO SAV */
and a.CAMP_COD_CND_PROD in('605')/* SUB PRODUCTO SAV APROBADO*/
)c
;QUIT;



%put=======================================================================================;
%put [04] Conexion a Fisa , rescate de clientes Of. Aprobada y cruce con cup_firmado;
%put=======================================================================================;

 
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
 

PROC SQL;
&mz_connect_BANCO;
create table RUTERO_CONS_APROBADO as
SELECT *
from  connection to BANCO(
SELECT 
 RUT
FROM 
  BR_CAM_MINUTA_FINAL
WHERE TIPO_PROMO_PLAT = 66
)A
;QUIT;


PROC SQL;
CREATE TABLE OF_APROBADA_CON_CUP
AS
SELECT 
   T1.RUT
FROM 
  RUTERO_CONS_APROBADO AS T1 
INNER JOIN (SELECT DISTINCT(RUT) AS RUT
                  FROM RESULT.CUP_VIGENTE) AS T2
ON (T1.RUT = T2.RUT)
;QUIT;



%put=======================================================================================;
%put [05] Extraccion de datos de simulaciones Solo Ultimos dias;
%put=======================================================================================;


proc sql;

connect to ODBC as myconn (user="ripley-bi" password="biripley00"
     DATASRC="BR-BACKENDHB"
);
create table SimulationPersonalLoanView as 
   select *    from connection to myconn
         ( SELECT  *
            from SimulationPersonalLoanView
where CAST(FechaSimulacion AS date) BETWEEN %str(%')&dated14_PWA.%str(%') AND %str(%')&dated0P_PWA.%str(%')

           );

   disconnect from myconn;
quit;


/*desde aqui modificar, toma la información solo dia anterior*/


%if %eval(&fechah.=2) %then %do;

PROC SQL;
CREATE TABLE WORK.SIMULACIONES_NOW AS 
SELECT  
INPUT((SUBSTR(t1.Rut,1,(LENGTH(t1.Rut)-1))),BEST.)as rut, 
t1.Producto AS PRODUCTO, 
t1.MontoSimulado AS MONTO, 
t1.CostoTotal AS COSTO_FINAL, 
t1.Cuotas AS CUOTAS, 
t1.PrecioSeguro AS MONTO_SEGURO, 
t1.'FechaSimulación'n AS FECHA,
datepart(t1.'FechaSimulación'n) format =weekday. AS dia,
timepart(t1.'FechaSimulación'n) format =hour. as hora,
case when &fechah=2 then "&fechad1"d else "&fechad0"d end format=date9. as fecha_r,
case when upcase(t1.Producto)='SAV' then 1 else 0 end as destino,
t1.Dispositivo
FROM WORK.SIMULATIONAVSAVVIEW as t1
where 'FechaSimulación'n>="&sabado 19:00:00"dt 
and INPUT((SUBSTR(t1.Rut,1,(LENGTH(t1.Rut)-1))),BEST.) IN (SELECT RUT FROM OFERTA_SAV_APROBADO)

union
SELECT  
INPUT((SUBSTR(t2.RUT,1,(LENGTH(t2.RUT)-1))),BEST.)as rut, 
'CONSUMO' AS PRODUCTO, 
t2.Montoliquido AS MONTO, 
t2.CostoTotal AS COSTO_FINAL, 
t2.Cuotas AS CUOTAS, 
t2.Segurovida AS MONTO_SEGURO, 
t2.FechaSimulacion AS FECHA,
datepart(t2.FechaSimulacion) format =weekday. AS dia,
timepart(t2.FechaSimulacion) format =hour. as hora,
case when &fechah=2 then "&fechad1"d else "&fechad0"d end format=date9. as fecha_r,
0 as destino,
t2.Dispositivo
FROM work.SimulationPersonalLoanView  as t2
where t2.FechaSimulacion>="&sabado 19:00:00"dt 
and INPUT((SUBSTR(t2.RUT,1,(LENGTH(t2.RUT)-1))),BEST.) IN (SELECT RUT FROM OF_APROBADA_CON_CUP)
;QUIT;

%end;
%else %do;
PROC SQL;
CREATE TABLE WORK.SIMULACIONES_NOW AS 
SELECT  
INPUT((SUBSTR(t1.Rut,1,(LENGTH(t1.Rut)-1))),BEST.)as rut, 
t1.Producto AS PRODUCTO, 
t1.MontoSimulado AS MONTO, 
t1.CostoTotal AS COSTO_FINAL, 
t1.Cuotas AS CUOTAS, 
t1.PrecioSeguro AS MONTO_SEGURO, 
t1.'FechaSimulación'n AS FECHA,
datepart(t1.'FechaSimulación'n) format =weekday. AS dia,
timepart(t1.'FechaSimulación'n) format =hour. as hora,
case when &fechah=2 then "&fechad1"d else "&fechad0"d end format=date9. as fecha_r,
case when upcase(t1.Producto)='SAV' then 1 else 0 end as destino,
t1.Dispositivo
FROM WORK.SIMULATIONAVSAVVIEW as t1
where 'FechaSimulación'n>="&fec &hora_desde:00:00"dt 
and INPUT((SUBSTR(t1.Rut,1,(LENGTH(t1.Rut)-1))),BEST.) IN (SELECT RUT FROM OFERTA_SAV_APROBADO)

union
SELECT  
INPUT((SUBSTR(t2.RUT,1,(LENGTH(t2.RUT)-1))),BEST.)as rut, 
'CONSUMO' AS PRODUCTO, 
t2.Montoliquido AS MONTO, 
t2.CostoTotal AS COSTO_FINAL, 
t2.Cuotas AS CUOTAS, 
t2.Segurovida AS MONTO_SEGURO, 
t2.FechaSimulacion AS FECHA,
datepart(t2.FechaSimulacion) format =weekday. AS dia,
timepart(t2.FechaSimulacion) format =hour. as hora,
case when &fechah=2 then "&fechad1"d else "&fechad0"d end format=date9. as fecha_r,
0 as destino,
t2.Dispositivo
FROM work.SimulationPersonalLoanView  as t2
where t2.FechaSimulacion>="&fec &hora_desde:00:00"dt 
and INPUT((SUBSTR(t2.RUT,1,(LENGTH(t2.RUT)-1))),BEST.) IN (SELECT RUT FROM OF_APROBADA_CON_CUP)
;QUIT;
%end;


%put=======================================================================================;
%put [06] calcular curses para luego descontar;
%put=======================================================================================;

proc sql;

   connect to ODBC as myconn (user="ripley-bi" password="biripley00"
     DATASRC="BR-BACKENDHB"
);
create table PWA_CURSES as 
   select *    from connection to myconn
         ( SELECT  *
            from AVSAVVOUCHERVIEW
			where CAST(FECHACURSE AS date) BETWEEN %str(%')&dated14_PWA.%str(%') AND %str(%')&dated0P_PWA.%str(%')
           );

   disconnect from myconn;
quit;



%put=======================================================================================;
%put [07] Llevar a nivel de rut unico quedandose con primera simulacion y descontando curses;
%put=======================================================================================;


PROC SQL;

CREATE TABLE WORK.minimo AS 
SELECT 
t1.rut, 
MIN(t1.FECHA) FORMAT=DATETIME20. AS MIN_of_FECHA
FROM WORK.SIMULACIONES_NOW t1
WHERE t1.rut NOT IN (SELECT INPUT((SUBSTR(t1.RUT,1,(LENGTH(t1.RUT)-1))),BEST.) FROM PWA_CURSES t1)
and  t1.rut NOT IN (SELECT RUT FROM publicin.LNEGRO_CAR)
and  t1.rut NOT IN (SELECT RUT FROM publicin.LNEGRO_CAll)
and rut  <>17603094
AND DESTINO=1

GROUP BY 
t1.rut

;QUIT;

PROC SQL;

CREATE TABLE WORK.minimo_0 AS 
SELECT 
t1.rut, 
MIN(t1.FECHA) FORMAT=DATETIME20. AS MIN_of_FECHA
FROM WORK.SIMULACIONES_NOW t1
WHERE t1.rut NOT IN (SELECT INPUT((SUBSTR(t1.RUT,1,(LENGTH(t1.RUT)-1))),BEST.) FROM PWA_CURSES t1)
and  t1.rut NOT IN (SELECT RUT FROM publicin.LNEGRO_CAR)
and  t1.rut NOT IN (SELECT RUT FROM publicin.LNEGRO_CAll)
and rut  <>17603094
AND DESTINO=0
GROUP BY 
t1.rut

;QUIT;

/* simulaciones SAV (destino = 1) */

PROC SQL;

CREATE TABLE WORK.simulaciones_final AS 
SELECT DISTINCT
t2.rut, 
t2.PRODUCTO, 
t2.MONTO, 
t2.COSTO_FINAL, 
t2.CUOTAS, 
t2.MONTO_SEGURO, 
t2.FECHA, 
t2.dia, 
t2.hora,
destino,
t2.Dispositivo
FROM WORK.MINIMO as t1
inner join WORK.SIMULACIONES_NOW as t2
on (t1.rut = t2.rut AND t1.MIN_of_FECHA = t2.FECHA) 
WHERE DESTINO=1
order by 
t2.FECHA asc /*Ordenar Por Fecha*/
;QUIT;

/* simulaciones consumo (destino = 0) */

PROC SQL;

CREATE TABLE WORK.simulaciones_final_0 AS 
SELECT DISTINCT
t2.rut, 
t2.PRODUCTO, 
t2.MONTO, 
t2.COSTO_FINAL, 
t2.CUOTAS, 
t2.MONTO_SEGURO, 
t2.FECHA, 
t2.dia, 
t2.hora,
destino,
t2.Dispositivo
FROM WORK.MINIMO_0 as t1
inner join WORK.SIMULACIONES_NOW as t2
on (t1.rut = t2.rut AND t1.MIN_of_FECHA = t2.FECHA) 
WHERE DESTINO=0
order by 
t2.FECHA asc /*Ordenar Por Fecha*/
;QUIT;


%put=======================================================================================;
%put [08] se calcula desde un correlativo par impar para asignar a cada call;
%put=======================================================================================;


PROC SQL;
   CREATE TABLE WORK.agrega_correlativo AS 
   SELECT  t1.rut, 
          t1.PRODUCTO, 
          t1.MONTO, 
          t1.COSTO_FINAL, 
          t1.CUOTAS, 
          t1.MONTO_SEGURO, 
          t1.FECHA, 
          t1.dia, 
          t1.hora, 
          t1.destino,
		  t1.Dispositivo,
		  monotonic()  as correlativo
      FROM WORK.SIMULACIONES_FINAL t1; /* simulaciones SAV*/
QUIT;


PROC SQL;
   CREATE TABLE WORK.transforma_corr AS 
   SELECT t1.rut, 
          t1.PRODUCTO, 
          t1.MONTO, 
          t1.COSTO_FINAL, 
          t1.CUOTAS, 
          t1.MONTO_SEGURO, 
          t1.FECHA, 
          t1.dia, 
          t1.hora, 
          t1.destino, /* simulaciones SAV*/
          t1.Dispositivo, 
		  monotonic() as correlativo,
          compress(put(t1.correlativo,best.)) as correlativ0_2
      FROM WORK.AGREGA_CORRELATIVO t1;
QUIT;


PROC SQL;
   CREATE TABLE WORK.calcula_par AS 
   SELECT t1.rut, 
          t1.PRODUCTO, 
          t1.MONTO, 
          t1.COSTO_FINAL, 
          t1.CUOTAS, 
          t1.MONTO_SEGURO, 
          t1.FECHA, 
          t1.dia, 
          t1.hora, 
          t1.destino,
          t1.Dispositivo 
/*		 case when  correlativo/2 <=&Corte_Call then 1 else 0 end as cota_superior, /* revisar si aplica ,es to es la cuota del call */
/*          case when SUBSTR(t1.correlativ0_2,LENGTH(t1.correlativ0_2),1) 
/*            in ('0','2','4','6','8') then 1 else 0 end as par
	
as paridad*/
      FROM WORK.transforma_corr t1;
QUIT;


PROC SQL;
   CREATE TABLE WORK.simulaciones_final AS 
   SELECT t1.rut, 
          t1.PRODUCTO, 
          t1.MONTO, 
          t1.COSTO_FINAL, 
          t1.CUOTAS, 
          t1.MONTO_SEGURO, 
          t1.FECHA format=datetime20. as fecha, 
          t1.dia, 
          t1.hora,
          t1.destino, 
      /*    case when t1.cota_superior=1 and t1.paridad=1 then 1 else 0 end as destino,*/
		  t1.Dispositivo
      FROM WORK.CALCULA_PAR t1
union

   SELECT t1.rut, 
          t1.PRODUCTO, 
          t1.MONTO, 
          t1.COSTO_FINAL, 
          t1.CUOTAS, 
          t1.MONTO_SEGURO, 
          t1.FECHA format=datetime20. as fecha, 
          t1.dia, 
          t1.hora, 
          0 as destino,
		  t1.Dispositivo
      FROM WORK.SIMULACIONES_FINAL_0 t1 /* simulaciones CONSUMO */

/*	  where t1.rut not in (select rut from WORK.calcula_par) */

;
QUIT;




%put=======================================================================================;
%put [09] Pegar informacion de Contacto (Telefono) y Marcar con Fecha_Proceso;
%put=======================================================================================;


/*Sacar fecha de Proceso*/
PROC SQL NOPRINT outobs=1;   

select 
SB_Ahora('DD/MM/AAAA_HH:MM') as Fecha_Proceso 
into :Fecha_Proceso 
from sashelp.vmember

;QUIT;
%let Fecha_Proceso="&Fecha_Proceso";


/*Pegar Fono + Fecha de Proceso*/

/* OJO ,aqui excluye los clientes que estan en base OUT carga dia para excluir ***/

PROC SQL;
CREATE TABLE WORK.simulaciones_final AS 
SELECT 
&Fecha_Proceso as Fecha_Proceso,
t1.rut,
t1.*,
t2.TELEFONO,
t3.DV, 
t3.NOMBRES, 
t3.PATERNO, 
t3.MATERNO,
t4.EMAIL
FROM WORK.simulaciones_final as t1
left join publicin.FONOS_MOVIL_FINAL as t2
on (t1.rut = t2.CLIRUT) 
left join publicin.BASE_NOMBRES  as t3
on (t1.rut = t3.RUT)
left join publicin.BASE_TRABAJO_EMAIL  as t4
on (t1.rut = t4.RUT)  
where t1.RUT NOT IN (SELECT RUT FROM &libreria_OUT..carga_dia /* excluye cleintes en bases actuales */ 
        WHERE FECHA_NUM >=YEAR("&fechad0P"D)*10000
                         +MONTH("&fechad0P"D)*100
                         +DAY("&fechad0P"D) )
;QUIT;


PROC SQL;
   CREATE TABLE WORK.BASE_EXTRACCION AS 
   SELECT t1.rut,DESTINO,
          YEAR("&fechad0P"D)*10000+MONTH("&fechad0P"D)*100+ DAY("&fechad0P"D) AS FECHA_NUM
      FROM WORK.SIMULACIONES_FINAL t1
;QUIT;


/* INSERT CAMPAÑA --> SMS */

proc sql NOPRINT; 
INSERT INTO &libreria_OUT..carga_dia
 ('rut'n, 'FECHA_NUM'n,'DESTINO'N) 
SELECT rut, FECHA_NUM,DESTINO
from WORK.BASE_EXTRACCION
;quit; 


/*Quedarse solamente con aquellos que si tienen Fono*/

PROC SQL;

CREATE TABLE WORK.simulaciones_final2 AS 
SELECT * 
from WORK.simulaciones_final 
where TELEFONO is not null 
order by FECHA asc /*Ordenar Por Fecha*/

;QUIT;

%put=======================================================================================;
%put [10] Separar Bases segun corte de cantidad a gestion por el call;
%put=======================================================================================;

/*** Este va solo data a call interno por solicitud de PPFF **/

/*Base para call interno (B2)*/

PROC SQL;

CREATE TABLE &libreria_OUT..simulaciones_final2_B2 AS 
SELECT * 
FROM WORK.simulaciones_final2 t1
/* where destino=0 */
;QUIT;


%put=======================================================================================;
%put [11] Guardar Tablas en duro;
%put=======================================================================================;

/*Base Total*/
PROC SQL NOPRINT outobs=1;   
select cats(&Base_Entregable) as Nombre_Total 
into :Nombre_Total  
from sashelp.vmember
;QUIT;


PROC SQL;

CREATE TABLE &Nombre_Total AS 
SELECT * 
FROM WORK.simulaciones_final  

;QUIT;

/*Base B0 --> Base de leads sin dato de Telefono*/

PROC SQL NOPRINT outobs=1;   
select cats(&Base_Entregable,"_Sin_Fono") as Nombre_B0  
into :Nombre_B0   
from sashelp.vmember
;QUIT;

PROC SQL;

CREATE TABLE &Nombre_B0 AS 
SELECT * 
FROM &libreria_OUT..simulaciones_final_B0 

;QUIT;

PROC SQL NOPRINT outobs=1;   
select cats(&Base_Entregable,"_Call_Interno") as Nombre_B2 
into :Nombre_B2  
from sashelp.vmember
;QUIT;

PROC SQL;

CREATE TABLE &Nombre_B2 AS 
SELECT * 
FROM &libreria_OUT..simulaciones_final2_B2  

;QUIT;


%put=======================================================================================;
%put [12] Generar enviable por mail;
%put=======================================================================================;

/*	LEADS_SAV_CALL_INTERNO*/
/*  EXPORTAR SALIDA A FTP DE SAS	*/

/*** Este va solo data a call interno por solicitud de PPFF **/

PROC EXPORT DATA	= &libreria_OUT..simulaciones_final2_B2
   OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/LEADS_SAV_CALL/LEADS_SAV_CALL_ARCHIVO_UNICO.csv"
/*   OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/LEADS_SAV_CALL/LEADS_SAV_CALL_INTERNO.csv"*/
   DBMS=dlm REPLACE;
   delimiter=';';
   PUTNAMES=YES;
RUN;

/*	EXPORTAR DE SAS A UN SFTP	*/
 
       filename server sftp 'LEADS_SAV_CALL_ARCHIVO_UNICO.csv' CD='/Call_Interno/' 
		HOST='192.168.80.15' user='usr_bi_g';
data _null_;
       infile "/sasdata/users94/user_bi/TRASPASO_DOCS/LEADS_SAV_CALL/LEADS_SAV_CALL_ARCHIVO_UNICO.csv";
       file server;
       input;
       put _infile_;
run;

/*	VARIABLE TIEMPO	- FIN	*/

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
	SELECT EMAIL into :EDP_BI 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_DIGITAL';
	SELECT EMAIL into :DEST_5 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_DIGITAL_1';
	SELECT EMAIL into :DEST_6 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'MICHAEL_VARGAS';
	SELECT EMAIL into :DEST_7 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'HECTOR_LUNA';
	SELECT EMAIL into :DEST_8 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'CRISTIAN_ECHEVERRIA';
	SELECT EMAIL into :DEST_9 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDUARDO_DIAZ';
	SELECT EMAIL into :DEST_10 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JOSE_VALDEBENITO';
	SELECT EMAIL into :DEST_11	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'RODRIGO_BUGUENO';
	SELECT EMAIL into :DEST_12 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_PPFF';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;	%put &=DEST_6;
%put &=DEST_7;	%put &=DEST_8;	%put &=DEST_9;	%put &=DEST_10;	%put &=DEST_11;	%put &=DEST_12;

/*	MAIL PARA CALL INTERNO	*/
data _null_;
FILENAME OUTBOX EMAIL
FROM 	= ("&EDP_BI")
/*to 		= ("&DEST_1","&DEST_2")*/
TO 		= ("&DEST_6","&DEST_7","&DEST_8","&DEST_9","&DEST_10","&DEST_11")
CC 		= ("&DEST_1","&DEST_2","&DEST_3","&DEST_4","&DEST_5","&DEST_12")
ATTACH	= "/sasdata/users94/user_bi/TRASPASO_DOCS/LEADS_SAV_CALL/LEADS_SAV_CALL_ARCHIVO_UNICO.csv"
SUBJECT = ("MAIL_AUTOM: Proceso LEADS_SAV_CALL_CENTER - ARCHIVO_UNICO");
FILE OUTBOX;
 PUT "Estimados:";
 put "        Proceso LEADS_SAV_CALL_CENTER, ejecutado con fecha: &fechaeDVN";   
 PUT ;
 PUT '     Se adjunta archivo: LEADS_SAV_CALL_ARCHIVO_UNICO.csv';
	PUT;
	PUT;
	put 'Proceso Vers. 27';
	PUT;
	PUT;
	PUT 'Atte.';
	Put 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
