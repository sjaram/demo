/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================         TABLON_LPF		     	================================*/
/* CONTROL DE VERSIONES
/* 2021-03-11 -- V2 -- Sergio Jara y Karina Martinez --    
					-- Adaptaciones con Validvarname=any + cambios por karina

/* 2021-03-05 -- V1 -- Karina Martinez --    
					-- Versión Original +  EDP
/* INFORMACIÓN:


/*	VARIABLE LIBRERÍA			*/
%let libreria=PUBLICIN;

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

options validvarname=any;

%put==================================================================================================;
%put [01.00] Extrae solicitudes generadas IN - OUT  ;
%put==================================================================================================;

/*solicitudes IN --> banco_nuevo_id 8 Banco ripley*/
/*6616*/

proc sql;
create table sp_generadas_IN as
SELECT 'IN' AS Tipo_Solicitud,
	sol.id AS id_solicitud_interno,
		sol.id_documento_firmado as id_documento_firmado,
    sol.id_solicitud_portabilidad AS id_solicitud_proveedor_inicial,
    sol.id_operacion_portabilidad AS id_redbanc,
	cli.rut,
/*    concat(cli.rut, '-', cli.dv) AS rut,*/
/*    concat(cli.nombre, ' ', cli.apellido_paterno, ' ', cli.apellido_materno) AS nombre,*/
    sol.fecha_presentacion AS fecha_presentacion,
	datepart(sol.fecha_presentacion) format=DDMMYY10. as fecha,
	input(put(datepart(sol.fecha_presentacion),yymmddn8.),best.) as fec_num,
	est.nombre AS estado_solicitud,
	ban.nombre AS proveedor_inicial,
	sol.banco_actual_id,
	sol.banco_nuevo_id
FROM LPF.solicitud sol
LEFT JOIN LPF.banco ban ON sol.banco_actual_id = ban.id
LEFT JOIN LPF.cliente cli ON sol.cliente_id = cli.id
LEFT JOIN LPF.estado est ON sol.estado_id = est.id
WHERE 	sol.banco_nuevo_id = 8
;quit;



%put==================================================================================================;
%put [01.01] Extrae solicitudes generadas IN y Cantidad de productos solicitados ;
%put==================================================================================================;


proc sql;
create table sp_generadas_IN_prod as
SELECT 'IN' AS Tipo_Solicitud,
	sol.id AS id_solicitud_interno,
		sol.id_documento_firmado as id_documento_firmado,
    sol.id_solicitud_portabilidad AS id_solicitud_proveedor_inicial,
    sol.id_operacion_portabilidad AS id_redbanc,
	cli.rut,
/*    concat(cli.rut, '-', cli.dv) AS rut,*/
/*    concat(cli.nombre, ' ', cli.apellido_paterno, ' ', cli.apellido_materno) AS nombre,*/
    sol.fecha_presentacion AS fecha_presentacion,
	datepart(sol.fecha_presentacion) format=DDMMYY10. as fecha,
	input(put(datepart(sol.fecha_presentacion),yymmddn8.),best.) as fec_num,
	est.nombre AS estado_solicitud,
	ban.nombre AS proveedor_inicial,
	sol.banco_actual_id,
	sol.banco_nuevo_id,
	case when SUBSTR(sol.id_documento_firmado,1,1) = '2' then  1 else 0 end as Solicitud_Exitosa,/*definicion revisada con consuelo y mauricio --que finaliza el flujo con digital-- */
(COUNT(sol_prod.producto_id)) AS n_producto_solicitados,
sol_prod.producto_id,
	prod.nemo, 
          prod.nombre, 
          prod.familia_producto_id
FROM LPF.solicitud sol
LEFT JOIN LPF.banco ban ON sol.banco_actual_id = ban.id
LEFT JOIN LPF.cliente cli ON sol.cliente_id = cli.id
LEFT JOIN LPF.estado est ON sol.estado_id = est.id
LEFT JOIN LPF.solicitud_producto sol_prod ON sol_prod.solicitud_id=sol.id
LEFT JOIN LPF.producto prod ON sol_prod.producto_id=prod.id
WHERE 	sol.banco_nuevo_id = 8
group by 
	sol.id ,
		sol.id_documento_firmado ,
    sol.id_solicitud_portabilidad ,
    sol.id_operacion_portabilidad ,
	cli.rut,
    sol.fecha_presentacion,
	est.nombre ,
	ban.nombre,
	sol.banco_actual_id,
	sol.banco_nuevo_id,sol_prod.producto_id,
	prod.nemo, 
          prod.nombre, 
          prod.familia_producto_id,
	calculated  Solicitud_Exitosa
;quit;



PROC SQL;
   CREATE TABLE WORK.TABLA_PRODUCTO AS 
   SELECT t1.id_solicitud_interno, 
          t1.rut, 
          t1.n_producto_solicitados, 
          t1.nemo, 
          t1.nombre, 
          t1.familia_producto_id
      FROM WORK.SP_GENERADAS_IN_PROD t1;
QUIT;


/* -------------------------------------------------------------------
   Ordenar el conjunto de datos WORK.TABLA_PRODUCTO
   ------------------------------------------------------------------- */
PROC SORT
	DATA=WORK.TABLA_PRODUCTO(KEEP=nemo nombre id_solicitud_interno rut)
	OUT=WORK.SORTTempTableSorted;
	BY id_solicitud_interno rut;
RUN;
PROC TRANSPOSE DATA=WORK.SORTTempTableSorted
	OUT=WORK.TRNSTRANSPOSED_0000(LABEL="Transponer WORK.TABLA_PRODUCTO")
	PREFIX=Columna
	NAME=Fuente
	LABEL=Etiqueta
;
	BY id_solicitud_interno rut;
	ID nombre;
	VAR nemo;

/* -------------------------------------------------------------------
   Fin de código de la tarea
   ------------------------------------------------------------------- */
RUN; QUIT;

proc sql; 
CREATE TABLE work.TABLA_PRODUCTO2 AS 
select 
t1.*,
compress(substr(cats(
case when t1.'ColumnaTodos los Productos'n is not null then '+PROALL' else '' end,
case when t1.'ColumnaLinea de Crédito'n is not null then '+LINCRE' else '' end, 
case when t1.'ColumnaTarjeta de Crédito'n is not null then '+TARCRE' else '' end,
case when t1.'ColumnaTodas las Cuentas'n is not null then '+CTAALL' else '' end ,
case when t1.'ColumnaCrédito Comercial'n is not null then '+CRECOM' else '' end ,
case when t1.'ColumnaTodos los Créditos'n is not null then '+CREALL' else '' end ,
case when t1.'ColumnaCrédito de Consumo'n is not null then '+CRECON' else '' end ,
case when t1.'ColumnaCuenta Corriente'n is not null then '+CTACTE' else '' end ,
case when t1.'ColumnaTodas las Tarjetas de Cré'n is not null then '+ROTALL' else '' end ,
case when t1.'ColumnaCuenta Vista'n is not null then '+CTAVIS' else '' end ,
case when t1.'ColumnaCrédito Hipotecario'n is not null then '+CREHIP' else '' end ,
case when t1.'ColumnaCuenta Prepago'n is not null then '+CTAPRE' else '' end,
case when t1.'ColumnaCrédito Automotriz'n is not null then '+CREAUT' else '' end,
case when t1.'ColumnaOtro Crédito'n is not null then '+CREOTR' else '' end 
),2,99
)) as Tipo_Producto 
from work.TRNSTRANSPOSED_0000 t1
;quit; 



proc sql;
create table sp_generadas_IN_prod_unicos as
SELECT 'IN' AS Tipo_Solicitud,
	sol.id AS id_solicitud_interno,
		sol.id_documento_firmado as id_documento_firmado,
    sol.id_solicitud_portabilidad AS id_solicitud_proveedor_inicial,
    sol.id_operacion_portabilidad AS id_redbanc,
	cli.rut,
/*    concat(cli.rut, '-', cli.dv) AS rut,*/
/*    concat(cli.nombre, ' ', cli.apellido_paterno, ' ', cli.apellido_materno) AS nombre,*/
    sol.fecha_presentacion AS fecha_presentacion,
	datepart(sol.fecha_presentacion) format=DDMMYY10. as fecha,
	input(put(datepart(sol.fecha_presentacion),yymmddn8.),best.) as fec_num,
	est.nombre AS estado_solicitud,
	ban.nombre AS proveedor_inicial,
	sol.banco_actual_id,
	sol.banco_nuevo_id,
	case when SUBSTR(sol.id_documento_firmado,1,1) = '2' then  1 else 0 end as Solicitud_Exitosa,/*definicion revisada con consuelo y mauricio --que finaliza el flujo con digital-- */
(COUNT(sol_prod.producto_id)) AS n_producto_solicitados,
detprod.Tipo_Producto
/*sol_prod.producto_id,
	prod.nemo, 
          prod.nombre, 
          prod.familia_producto_id*/
FROM LPF.solicitud sol
LEFT JOIN LPF.banco ban ON sol.banco_actual_id = ban.id
LEFT JOIN LPF.cliente cli ON sol.cliente_id = cli.id
LEFT JOIN LPF.estado est ON sol.estado_id = est.id
LEFT JOIN LPF.solicitud_producto sol_prod ON sol_prod.solicitud_id=sol.id
LEFT JOIN LPF.producto prod ON sol_prod.producto_id=prod.id
LEFT JOIN TABLA_PRODUCTO2 detprod ON sol.id=detprod.id_solicitud_interno
WHERE 	sol.banco_nuevo_id = 8
group by 
	sol.id ,
		sol.id_documento_firmado ,
    sol.id_solicitud_portabilidad ,
    sol.id_operacion_portabilidad ,
	cli.rut,
    sol.fecha_presentacion,
	est.nombre ,
	ban.nombre,
	sol.banco_actual_id,
	sol.banco_nuevo_id,
detprod.Tipo_Producto,
	calculated  Solicitud_Exitosa
	
;quit;

proc sql;
create table sp_generadas_IN as 
select a.*,b.Tipo_Producto
from sp_generadas_IN a
left join sp_generadas_IN_prod_unicos b on a.id_solicitud_interno=b.id_solicitud_interno
;quit;

/* solicitudes OUT --> banco_actual_id 8 Banco ripley */
/*1631*/

proc sql;
create table sp_generadas_OUT as
SELECT 'OUT' AS Tipo_Solicitud,
	sol.id AS id_solicitud_interno,
	sol.id_documento_firmado as id_documento_firmado,
    sol.id_solicitud_portabilidad AS id_solicitud_proveedor_inicial,
    sol.id_operacion_portabilidad AS id_redbanc,
	cli.rut,
/*  cli.nombre||' '||cli.apellido_paterno||' '||cli.apellido_materno AS nombre,*/
    sol.fecha_presentacion AS fecha_presentacion,
	datepart(sol.fecha_presentacion) format=DDMMYY10. as fecha,
	input(put(datepart(sol.fecha_presentacion),yymmddn8.),best.) as fec_num,
    est.nombre AS estado_solicitud,
	ban.nombre AS proveedor_inicial,
	sol.banco_actual_id,
	sol.banco_nuevo_id
FROM LPF.solicitud sol
LEFT JOIN LPF.banco ban ON sol.banco_actual_id = ban.id
LEFT JOIN LPF.cliente cli ON sol.cliente_id = cli.id
LEFT JOIN LPF.estado est ON sol.estado_id = est.id
WHERE 	sol.banco_actual_id = 8
order by sol.id_operacion_portabilidad
;quit;


proc sql;
create table &libreria..KM_LPF_Solicitudes as
select *, case when SUBSTR(id_documento_firmado,1,1) = '2' then  1 else 0 end as Firma_digital_sol 
from (select *  
from sp_generadas_IN 
union select *
from sp_generadas_OUT)
order by fecha_presentacion
;quit;

%put==================================================================================================;
%put [01.01] Extrae solicitudes generadas y marcas ULTIMA SOLICITUD POR CLIENTE  ;
%put==================================================================================================;

/* trae ultima solicitud generada al cliente */

PROC SQL;
   CREATE TABLE WORK.MAX_APERTURA_IN AS 
   SELECT t1.rut,
   (COUNT(t1.id_solicitud_interno)) AS COUNT_of_id_solicitud_interno,
      
(MAX(t1.id_solicitud_proveedor_inicial)) AS id_solicitud_proveedor_inicial ,
sum(Firma_digital_sol ) AS sum_Firma_digital_sol,
/*          t1.id_solicitud_proveedor_inicial, */
          /* MAX_of_fecha */
            (MAX(t1.fecha)) FORMAT=DDMMYY10. AS MAX_of_fecha
      FROM &libreria..KM_LPF_Solicitudes t1
	  WHERE T1.Tipo_Solicitud ='IN'
 			    GROUP BY rut
;QUIT;


PROC SQL;
CREATE TABLE sp_generadas_IN_AGRUPADA AS 
   SELECT t1.Tipo_Solicitud, T1.RUT,
   t1.id_solicitud_interno,
   t1.id_documento_firmado,
   t1.Firma_digital_sol,
   t2.sum_Firma_digital_sol as n_Firma_digital_sol,
  t2.COUNT_of_id_solicitud_interno AS n_Solicitudes,
          t1.id_solicitud_proveedor_inicial, 
          t1.id_redbanc, 
          t1.fecha, 
          t1.fec_num, 
          t1.estado_solicitud, 
          t1.proveedor_inicial, 
          t1.banco_actual_id, 
          t1.banco_nuevo_id,
		  t1.Tipo_Producto
      FROM &libreria..KM_LPF_Solicitudes t1
INNER  JOIN WORK.MAX_APERTURA_IN t2
      ON  (t1.rut = t2.rut AND t1.fecha = t2.MAX_of_fecha AND t1.id_solicitud_proveedor_inicial = 
           t2.id_solicitud_proveedor_inicial) WHERE   T1.Tipo_Solicitud ='IN'
      GROUP BY t1.Tipo_Solicitud,
               t1.id_solicitud_proveedor_inicial,
               t1.id_redbanc,
               t1.fecha,
               t1.fec_num,
               t1.estado_solicitud,
               t1.proveedor_inicial,
               t1.banco_actual_id,
               t1.banco_nuevo_id,
		  t1.Tipo_Producto
;
QUIT;

/* trae ultima solicitud generada al cliente */

PROC SQL;
   CREATE TABLE WORK.MAX_APERTURA_OUT AS 
   SELECT t1.rut, 
          /* COUNT_of_id_solicitud_proveedor_ */
            (COUNT(t1.id_solicitud_proveedor_inicial)) AS COUNT_of_id_solicitud_proveedor_, 
          /* MAX_of_id_solicitud_interno */
            (MAX(t1.id_solicitud_interno)) FORMAT=BEST12. AS id_solicitud_interno, 
          /* MAX_of_fecha */
            (MAX(t1.fecha)) FORMAT=DDMMYY10. AS MAX_of_fecha
      FROM &libreria..KM_LPF_Solicitudes t1
	  WHERE T1.Tipo_Solicitud ='OUT'
      GROUP BY t1.rut;
QUIT;


PROC SQL;
CREATE TABLE sp_generadas_out_AGRUPADA AS 
   SELECT t1.Tipo_Solicitud, T1.RUT,
   t1.id_solicitud_interno,
   t1.id_documento_firmado,
   t1.Firma_digital_sol,
  t2.COUNT_of_id_solicitud_proveedor_ AS n_Solicitudes,
          t1.id_solicitud_proveedor_inicial, 
          t1.id_redbanc, 
          t1.fecha, 
          t1.fec_num, 
          t1.estado_solicitud, 
          t1.proveedor_inicial, 
          t1.banco_actual_id, 
          t1.banco_nuevo_id
      FROM &libreria..KM_LPF_Solicitudes t1
inner  JOIN WORK.MAX_APERTURA_OUT t2
      ON  (t1.rut = t2.rut AND t1.fecha = t2.MAX_of_fecha AND t1.id_solicitud_interno = 
           t2.id_solicitud_interno) WHERE   T1.Tipo_Solicitud ='OUT'
      GROUP BY t1.Tipo_Solicitud,
               t1.id_solicitud_proveedor_inicial,
               t1.id_redbanc,
               t1.fecha,
               t1.fec_num,
               t1.estado_solicitud,
               t1.proveedor_inicial,
               t1.banco_actual_id,
               t1.banco_nuevo_id
;QUIT;

%put==================================================================================================;
%put [01.02] Extrae solicitudes con oferta  ;
%put==================================================================================================;


PROC SQL;
CREATE TABLE ofertas_generadas AS 
SELECT
	ofem.id AS id_ofe_interno,
	sol.id AS id_solicitud_interno,
    sol.id_solicitud_portabilidad AS id_solicitud_proveedor_inicial,
    sol.id_operacion_portabilidad AS id_redbanc,
	ban.nombre AS proveedor_inicial,
    ofem.rut_cliente ,
	(INPUT(LEFT(SUBSTR(LEFT(COMPRESS(COMPRESS( ofem.rut_cliente,'.'),'-')),1,LENGTH(LEFT(COMPRESS(COMPRESS(ofem.rut_cliente,'.'),'-')))-1)),BEST.)) AS RUT,

    ofem.nombre_cliente AS nombre,
    ofem.fecha_emision AS fecha_presentacion,
		(ofem.fecha_emision) format=DDMMYY10. as fecha,
		input(put(ofem.fecha_emision,yymmddn8.),best.) as fec_num,
    ofem.estado_oferta,
    est.nombre AS estado_solicitud
FROM LPF.oferta_main ofem
LEFT JOIN LPF.solicitud sol ON ofem.solicitud_id = sol.id
LEFT JOIN LPF.banco ban ON sol.banco_actual_id = ban.id
LEFT JOIN LPF.estado est ON sol.estado_id = est.id
WHERE
	sol.banco_nuevo_id = 8 AND
    ofem.estado_oferta = 1
;quit;

	
/* considera todos los estados */
/* Estados CANCELADA
GENERACION OFERTA
OFERTA ACEPTADA
OFERTA CANCELADA
OFERTA DISPONIBLE
OFERTA EXPIRADA*/


PROC SQL;
   CREATE TABLE WORK.Clientes_Of AS 
   SELECT t1.RUT, 
          /* COUNT_of_id_ofe_interno */
            (COUNT(t1.id_ofe_interno)) AS N_Solicitudes_Oferta
      FROM WORK.OFERTAS_GENERADAS t1
      WHERE t1.estado_solicitud NOT = 'OFERTA NO DISPONIBLE'
      GROUP BY t1.RUT;
QUIT;

%put==================================================================================================;
%put [01.02] Extrae solicitudes con oferta generada detalle ;
%put==================================================================================================;


PROC SQL;
CREATE TABLE ofertas_detalle AS 
SELECT
	ofem.id AS id_ofe_interno,
	sol.id AS id_solicitud_interno,
    sol.id_solicitud_portabilidad AS id_solicitud_proveedor_inicial,
    sol.id_operacion_portabilidad AS id_redbanc,
	ban.nombre AS proveedor_inicial,
    ofem.rut_cliente ,
	(INPUT(LEFT(SUBSTR(LEFT(COMPRESS(COMPRESS( ofem.rut_cliente,'.'),'-')),1,LENGTH(LEFT(COMPRESS(COMPRESS(ofem.rut_cliente,'.'),'-')))-1)),BEST.)) AS RUT,

    ofem.nombre_cliente AS nombre,
    ofem.fecha_emision AS fecha_presentacion,
		(ofem.fecha_emision) format=DDMMYY10. as fecha,
		input(put(ofem.fecha_emision,yymmddn8.),best.) as fec_num,
    ofem.estado_oferta,
    est.nombre AS estado_solicitud,
	ofer.tipo_oferta,ofer.titulo_oferta,
	LENGTH (ofer.tipo_oferta) AS LARGO
FROM LPF.oferta_main ofem
LEFT JOIN LPF.solicitud sol ON ofem.solicitud_id = sol.id
LEFT JOIN LPF.banco ban ON sol.banco_actual_id = ban.id
LEFT JOIN LPF.estado est ON sol.estado_id = est.id
LEFT JOIN LPF.oferta ofer ON ofer.oferta_main_id=ofem.id
WHERE
	sol.banco_nuevo_id = 8 AND
    ofem.estado_oferta = 1 	and 
sol.id_documento_firmado IS NOT null
;quit;

/* se deja la oferta con mayor combinacion*/

PROC SQL;
   CREATE TABLE WORK.oferta_detalle_rut AS 
   select distinct  a.rut, 
         a.tipo_oferta, 
          a.LARGO
     
   from ofertas_detalle a
inner join (SELECT           t1.rut, 
          /* MAX_of_LARGO */
            (MAX(t1.LARGO)) AS MAX_of_LARGO
      FROM WORK.ofertas_detalle t1
	  where  estado_solicitud NOT = 'OFERTA NO DISPONIBLE'
      GROUP BY                t1.rut) b on (a.rut=b.rut and a.LARGO=MAX_of_LARGO)
;QUIT;

/* se deja unico, ya que se duplica por misma descricion <> orden*/
DATA oferta_detalle_rut;
SET  oferta_detalle_rut;
IF RUT=LAG(RUT) THEN FILTRO =1; 
ELSE FILTRO=0; 
RUN;

PROC SQL noprint;
DELETE * FROM oferta_detalle_rut WHERE FILTRO=1
;QUIT;


/* se deja la oferta con mayor combinacion*/
PROC SQL noprint;
/*   CREATE TABLE WORK.QUERY_FOR_OFERTAS_DETALLE_RUT AS */
   SELECT /* COUNT_of_rut */
            (COUNT(t1.rut)) AS COUNT_of_rut, 
          /* COUNT_DISTINCT_of_rut */
            (COUNT(DISTINCT(t1.rut))) AS COUNT_DISTINCT_of_rut
      FROM WORK.oferta_detalle_rut t1;
QUIT;



PROC SQL;
   CREATE TABLE WORK.Clientes_Of2 AS 
   SELECT t1.RUT, 
          t1.N_Solicitudes_Oferta,
		  t2.tipo_oferta
      FROM WORK.Clientes_Of t1
	  left join oferta_detalle_rut t2 on t1.rut=t2.rut
      
      GROUP BY t1.RUT;
QUIT;

%put==================================================================================================;
%put [01.03] Extrae MARCA SI CLIENTE ACEPTO OFERTA  ;
%put==================================================================================================;


PROC SQL;
   CREATE TABLE WORK.Aceptacion_Cliente AS 
   SELECT 
	ofem.id AS id_ofe_interno,
	sol.id AS id_solicitud_interno,
    sol.id_solicitud_portabilidad AS id_solicitud_proveedor_inicial,
    sol.id_operacion_portabilidad AS id_redbanc,
	ban.nombre AS proveedor_inicial,
    ofem.rut_cliente,
	(INPUT(LEFT(SUBSTR(LEFT(COMPRESS(COMPRESS( ofem.rut_cliente,'.'),'-')),1,LENGTH(LEFT(COMPRESS(COMPRESS(ofem.rut_cliente,'.'),'-')))-1)),BEST.)) AS RUT,
    ofem.nombre_cliente AS nombre,
    ofem.fecha_emision AS fecha_presentacion,
    ofem.estado_oferta,
			(ofem.fecha_emision) format=DDMMYY10. as fecha,
		input(put(ofem.fecha_emision,yymmddn8.),best.) as fec_num,
    est.nombre AS Estado_acepta_Oferta
FROM LPF.oferta_main ofem
LEFT JOIN LPF.solicitud sol ON ofem.solicitud_id = sol.id
LEFT JOIN LPF.banco ban ON sol.banco_actual_id = ban.id
LEFT JOIN LPF.estado est ON sol.estado_id = est.id
WHERE
	sol.banco_nuevo_id = 8 AND
    ofem.estado_oferta = 2
;QUIT;


%put==================================================================================================;
%put [01.04] Extrae MARCA previred  ;
%put==================================================================================================;


PROC SQL;
   CREATE TABLE WORK.Cliente_con_Previred AS 
   SELECT t1.id, 
          t1.fecha_solicitud, 
          t1.cliente_id,
		  	datepart(t1.fecha_solicitud) format=DDMMYY10. as fecha,
	input(put(datepart(t1.fecha_solicitud),yymmddn8.),best.) as fec_num,
	t2.rut
      FROM LPF.CLIENTE_PREVIRED t1
	  inner JOIN LPF.cliente t2 ON t1.cliente_id = t2.id
;QUIT;


%put==================================================================================================;
%put [01.05] Agrega marcas a solicitud  ;
%put==================================================================================================;

PROC SQL;
   CREATE TABLE SP_GENERADAS_IN_AGRUPADA_OF AS 
   SELECT distinct
          t1.rut, 
          t1.id_solicitud_interno, 
          t1.id_documento_firmado, 
          t1.Firma_digital_sol, 
          t1.n_Solicitudes,
t1.n_Firma_digital_sol, 
          t1.id_solicitud_proveedor_inicial, 
          t1.id_redbanc, 
          t1.fecha, 
          t1.fec_num, 
          t1.estado_solicitud, 
		  t1.Tipo_Producto,
          t1.proveedor_inicial, 
          t1.banco_actual_id, 
          t1.banco_nuevo_id,
	      case when t5.RUT > 1 then 1  else  0 end as Marca_Previred, 
          case when t2.RUT > 1 then 1  else  0 end as Oferta_Generada, 
          t2.estado_solicitud AS Estado_Oferta,
		  t3.N_Solicitudes_Oferta as N_Ofertas_Generadas,
		  t3.tipo_oferta,
		  case when t4.RUT > 1 then 1  else  0 end as Oferta_Aceptada
      FROM WORK.SP_GENERADAS_IN_AGRUPADA t1
LEFT JOIN WORK.OFERTAS_GENERADAS t2 ON (t1.id_solicitud_interno = t2.id_solicitud_interno) AND (t1.rut = 
          t2.RUT)
LEFT JOIN WORK.Clientes_Of2 t3 ON (t1.RUT = t3.RUT) 
LEFT JOIN WORK.Aceptacion_Cliente t4 ON (t1.id_solicitud_interno = t4.id_solicitud_interno) AND (t1.rut = 
          t4.RUT)
LEFT JOIN WORK.Cliente_con_Previred t5 ON (t1.fec_num = t5.fec_num) AND (t1.rut = 
          t5.RUT)

;
QUIT;





/*

PROC SQL;
   CREATE TABLE WORK.Oferta_Disponible AS 
   SELECT * 
FROM LPF.oferta_main AS a 
INNER JOIN LPF.oferta AS b 
ON (a.id = b.oferta_main_id)
;quit;*/


%put==================================================================================================;
%put [01.00] Extrae TABLON CON OFERTA Y VARIABLES. ULTIMO DISPONIBLE  ;
%put==================================================================================================;



PROC SQL noprint;    
select max(anomes) as Max_anomes5 
into :Max_anomes5
from ( 
select *, 
input(substr(Nombre_Tabla,12,6),best.) as anomes 
from ( 
select  
*, 
cat(trim(libname),.,trim(memname)) as Nombre_Tabla 
from sashelp.vmember 
) as a 
where libname ='SBARRERA' 
AND upper(Nombre_Tabla)   CONTAINS 'RUTERO1_LPF'   
) as x 
;QUIT;

%let periodo=&Max_anomes5;

/*
PROC SQL;
CREATE TABLE KMARTINE.Clientes_Solicitud_LPF AS
SELECT *
FROM  sbarrera.SB&periodo._RUTERO1_LPF 
union select * from (SELECT DISTINCT t1.rut
      FROM KMARTINE.KM_LPF_SOLICITUDES t1)
;QUIT;*/




PROC SQL;
   CREATE TABLE &libreria..Clientes_Solicitud_LPF AS 
   SELECT t1.rut, 
          t1.VU_C_PRIMA, 
          t1.Cuadrante, 
          t1.Cuadrante_Grupo, 
          t1.OFERTA_CONSOLIDACION, 
          t1.OFERTA_LIBRE_DISPOSICION, 
          t1.OFERTA_RETENCION, 
          t1.SEMAFORO_RETENCION, 
          t1.SEMAFORO_ATACAR, 
          t1.CUPO_ORIGINAL, 
          t1.CUPO_AUMENTADO, 
/*          t1.GSE, */
          t1.'GC: Categoria Gold x 3 meses'n, 
          t1.'GC: Categoria Silver x 3 meses'n, 
          t1.'GC: Despacho gratis 1 cupon'n, 
          t1.'GC: Tasa (superar competencia)'n, 
          t1.'GC: Tasa (igualar competencia)'n, 
          t1.'GC: Costo $0 CV'n, 
          t1.'GC: Costo $0 TAM 3 meses'n, 
          t1.'GC: Cupón Dcto tiendas y .com'n, 
          t1.Oferta_Capta, 
          t1.Tenencia_Tarjetas_VU, 
		  t1.TC_Tenencia,
          t1.TD_Tenencia, 
          t1.TD_Tenencia_ABR, 
          t1.DAP_Tenencia, 
          t1.AV_Tenencia, 
          t1.SAV_Tenencia, 
          t1.CONS_Tenencia, 
          t1.PAT_Tenencia, 
          t1.SEG_Tenencia, 
          t1.SEG_Auto_Tenencia, 
          t1.SEG_Hogar_Tenencia, 
          t1.SEG_Vida_Tenencia, 
          t1.SEG_Salud_Tenencia, 
          t1.SEG_Fraude_Tenencia, 
          t1.SEG_Desgravamen_Tenencia, 
          t1.SEG_Cesantia_Tenencia,
          t1.CHEK_Tenencia,
		  t1.Nro_Productos,
		  t1.SBF_Dda_Dir_Vig,
		  t1.SBF_Dda_Com,
	      t1.SBF_Dda_Cred_Cons,
t1.SBF_Dda_Cred_Hip,
t1.SBF_Nro_Inst,
t1.SBF_Mto_Linea_Disp,
t1.SBF_Dda_MVC
      FROM sbarrera.SB&periodo._RUTERO1_LPF  t1;
QUIT;


%put==================================================================================================;
%put [01.02] UNIVERSO ;
%put==================================================================================================;

PROC SQL;
CREATE TABLE &libreria..Tablon_LPF as
select rut from &libreria..KM_LPF_Solicitudes /* solicitudes in out */
union select rut from &libreria..Clientes_Solicitud_LPF
;quit;


%put==================================================================================================;
%put [01.03] Extrae ULTIMA ACTIVIDAD DISPONIBLE  ;
%put==================================================================================================;



PROC SQL noprint;    
select max(anomes) as Max_anomesACT 
into :Max_anomesACT
from ( 
select *, 
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes 
from ( 
select  
*, 
cat(trim(libname),.,trim(memname)) as Nombre_Tabla 
from sashelp.vmember 
) as a 
where upper(Nombre_Tabla) like "PUBLICIN.ACT_TR_%"
and length(Nombre_Tabla)=length("PUBLICIN.ACT_TR_202010")
) as x 
;QUIT;

%let periodo_ACT=&Max_anomesACT;




%put==================================================================================================;
%put [01.04] Extrae OFERTAS SAV-AV-CONSUMO ULTIMO DISPONIBLE  ;
%put==================================================================================================;



PROC SQL noprint;    
select max(anomes) as Max_anomesACT 
into :Max_anomesACT
from ( 
select *, 
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes 
from ( 
select  
*, 
cat(trim(libname),.,trim(memname)) as Nombre_Tabla 
from sashelp.vmember 
) as a 
where upper(Nombre_Tabla) like "KMARTINE.AVANCE_FIN_%"
and length(Nombre_Tabla)=length("KMARTINE.AVANCE_FIN_202010")
) as x 
;QUIT;

%let periodo_AV=&Max_anomesACT;

PROC SQL noprint;    
select max(anomes) as Max_anomesACT 
into :Max_anomesACT
from ( 
select *, 
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes 
from ( 
select  
*, 
cat(trim(libname),.,trim(memname)) as Nombre_Tabla 
from sashelp.vmember 
) as a 
where upper(Nombre_Tabla) like "JABURTOM.SAV_FIN_%"
and length(Nombre_Tabla)=length("JABURTOM.SAV_FIN_202101")
) as x 
;QUIT;

%let periodo_SAV=&Max_anomesACT;

proc sql;
create table SAV_FIN_&periodo_SAV as 
select *
from jaburtom.SAV_FIN_&periodo_SAV t3 
where MONTO_oferta_SAV>0
;quit;



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
create table rutero_consumo as
  SELECT	DISTINCT RUT
  from  connection to BANCO(
     select rut
     from 
     br_cam_minuta_final
     where tipo_promo_plat not in (66,69,70)
)A
;QUIT;


%put==================================================================================================;
%put [01.05] se agregan variables   ;
%put==================================================================================================;



proc sql;
create table Clientes_Solicitud_LPF as
select a.rut,
t1.VU_C_PRIMA, 
          t1.Cuadrante, 
          t1.Cuadrante_Grupo, 
          t1.OFERTA_CONSOLIDACION, 
          t1.OFERTA_LIBRE_DISPOSICION, 
          t1.OFERTA_RETENCION, 
          t1.SEMAFORO_RETENCION, 
          t1.SEMAFORO_ATACAR, 
          t1.CUPO_ORIGINAL, 
          t1.CUPO_AUMENTADO, 
/*          t6.GSE, */
          t1.'GC: Categoria Gold x 3 meses'n, 
          t1.'GC: Categoria Silver x 3 meses'n, 
          t1.'GC: Despacho gratis 1 cupon'n, 
          t1.'GC: Tasa (superar competencia)'n, 
          t1.'GC: Tasa (igualar competencia)'n, 
          t1.'GC: Costo $0 CV'n, 
          t1.'GC: Costo $0 TAM 3 meses'n, 
          t1.'GC: Cupón Dcto tiendas y .com'n, 
          t1.Oferta_Capta, 
          t1.Tenencia_Tarjetas_VU,
t1.TC_Tenencia ,
          t1.TD_Tenencia, 
          t1.TD_Tenencia_ABR, 
          t1.DAP_Tenencia, 
          t1.AV_Tenencia, 
          t1.SAV_Tenencia, 
          t1.CONS_Tenencia, 
          t1.PAT_Tenencia, 
          t1.SEG_Tenencia, 
          t1.SEG_Auto_Tenencia, 
          t1.SEG_Hogar_Tenencia, 
          t1.SEG_Vida_Tenencia, 
          t1.SEG_Salud_Tenencia, 
          t1.SEG_Fraude_Tenencia, 
          t1.SEG_Desgravamen_Tenencia, 
          t1.SEG_Cesantia_Tenencia, 
          t1.CHEK_Tenencia,
		  t1.Nro_Productos,
		  t1.SBF_Dda_Dir_Vig,
		  t1.SBF_Dda_Com,
	      t1.SBF_Dda_Cred_Cons,
t1.SBF_Dda_Cred_Hip,
t1.SBF_Nro_Inst,
t1.SBF_Mto_Linea_Disp,
t1.SBF_Dda_MVC,
t5.ACTIVIDAD_TR,
case when T2.rut>1 then 1 else 0 end as Oferta_Av,
case when t3.rut_Real>1 then 1 else 0 end as Oferta_Sav,
case when t4.rut>1 then 1 else 0 end as Oferta_Consumo
from &libreria..Tablon_LPF a
left join &libreria..Clientes_Solicitud_LPF t1 on a.rut=t1.rut
left join KMARTINE.AVANCE_FIN_&periodo_AV t2 on a.rut=t2.rut
left join SAV_FIN_&periodo_SAV t3 on a.rut=t3.rut_real
left join rutero_consumo t4 on a.rut=t4.rut
left join PUBLICIN.ACT_TR_&periodo_ACT t5 on a.rut=t5.rut
/*left join publicin.GSE_2018 t6 on t1.rut =t6.rut*/
;QUIT;


/*2690187*/
proc sql;
create table &libreria..Tablon_LPF as
select t1.*, 
case when t2.rut>1 then 1 else 0 end as Sol_IN,
t2.fec_num AS fec_num_IN,
floor(t2.fec_num/100) AS PERIODO, 
          t2.Firma_digital_sol, 
          t2.n_Solicitudes AS n_Solicitudes_IN, 
		  t2.n_Firma_digital_sol as n_Firma_digital_IN,
          t2.estado_solicitud, 
		  t2.Tipo_Producto,
          t2.banco_actual_id, 
          t2.Marca_Previred, 
          t2.Oferta_Generada, 
          t2.Estado_Oferta, 
          t2.N_Ofertas_Generadas,
t2.tipo_oferta as tipo_oferta_LPF, 
          t2.Oferta_Aceptada,
		  case when t3.rut>1 then 1 else 0 end as Sol_OUT,
t3.fec_num AS  fec_num_OUT, 
          t3.n_Solicitudes AS n_Solicitudes_OUT, 
          t3.banco_actual_id,
		           t6.GSE
from Clientes_Solicitud_LPF t1
left join SP_GENERADAS_IN_AGRUPADA_OF t2 on t1.rut =t2.rut
left join SP_GENERADAS_OUT_AGRUPADA t3 on t1.rut =t3.rut
left join publicin.GSE_2018 t6 on t1.rut =t6.rut
;quit;


%put------------------------------------------------------------------------------------------;
%put [02.00] Resumen salida;
%put------------------------------------------------------------------------------------------;

options cmplib=sbarrera.funcs;
 
PROC SQL;
   CREATE TABLE &libreria..Resumen_Tablon_LPF AS 
   SELECT VU_C_PRIMA, 
   ACTIVIDAD_TR,
          Cuadrante, 
          Cuadrante_Grupo, 
          SEMAFORO_RETENCION, 
          SEMAFORO_ATACAR, 
          GSE, 
          'GC: Categoria Gold x 3 meses'n, 
          'GC: Categoria Silver x 3 meses'n, 
          'GC: Despacho gratis 1 cupon'n, 
          'GC: Tasa (superar competencia)'n, 
          'GC: Tasa (igualar competencia)'n, 
          'GC: Costo $0 CV'n, 
          'GC: Costo $0 TAM 3 meses'n, 
          'GC: Cupón Dcto tiendas y .com'n, 
          Tenencia_Tarjetas_VU, 
          estado_solicitud, 
          Estado_Oferta,
		  SB_Tramificar(OFERTA_CONSOLIDACION,500000,0,15000000,'') as Tramo_OFERTA_CONSO,
SB_Tramificar(OFERTA_LIBRE_DISPOSICION,500000,0,15000000,'') as Tramo_OFERTA_LD,
SB_Tramificar(coalesce(OFERTA_CONSOLIDACION,0)+coalesce(OFERTA_LIBRE_DISPOSICION,0),500000,0,15000000,'') as Tramo_OFERTA_CONSOLD,
Oferta_Capta,
estado_solicitud,
Tipo_Producto, 
Estado_Oferta, 
fec_num_IN, 
PERIODO as PERIODO_IN,
fec_num_OUT,
Sol_IN,
Sol_OUT,
tipo_oferta_LPF,
count(*) as Nro_Clientes,
sum(TC_Tenencia) as sum_TC_Tenencia,
sum(CONS_Tenencia) as sum_CONS_Tenencia,
sum(TD_Tenencia) as sum_TD_Tenencia,
sum(TD_Tenencia_ABR) as sum_TD_Tenencia_ABR,
sum(DAP_Tenencia) as sum_DAP_Tenencia,
sum(AV_Tenencia) as sum_AV_Tenencia,
sum(SAV_Tenencia) as sum_SAV_Tenencia,
sum(PAT_Tenencia) as sum_PAT_Tenencia,
sum(SEG_Tenencia) as sum_SEG_Tenencia,
sum(SEG_Auto_Tenencia) as sum_SEG_Auto_Tenencia,
sum(SEG_Hogar_Tenencia) as sum_SEG_Hogar_Tenencia,
sum(SEG_Vida_Tenencia) as sum_SEG_Vida_Tenencia,
sum(SEG_Salud_Tenencia) as sum_SEG_Salud_Tenencia,
sum(SEG_Fraude_Tenencia) as sum_SEG_Fraude_Tenencia,
sum(SEG_Desgravamen_Tenencia) as sum_SEG_Desgravamen_Tenencia,
sum(SEG_Cesantia_Tenencia) as sum_SEG_Cesantia_Tenencia,
sum(CHEK_Tenencia) as sum_CHEK_Tenencia,
sum(Nro_Productos) as sum_Nro_Productos,
sum(Oferta_Av) as sum_Oferta_Av,
sum(Oferta_Sav) as sum_Oferta_Sav,
sum(Oferta_Consumo) as sum_Oferta_Consumo,
sum(SBF_Dda_Dir_Vig) as sum_SBF_Dda_Dir_Vig,
sum(SBF_Dda_Com) as sum_SBF_Dda_Com,
sum(case when SBF_Dda_Cred_Cons>0 then 1 else 0 end) as sum_SBF_CLI_Dda_Cred_Cons,
sum(SBF_Dda_Cred_Cons) as sum_SBF_Dda_Cred_Cons,
sum(SBF_Dda_Cred_Hip) as sum_SBF_Dda_Cred_Hip,
sum(SBF_Nro_Inst) as sum_SBF_Nro_Inst,
sum(SBF_Mto_Linea_Disp) as sum_SBF_Mto_Linea_Disp,
sum(SBF_Dda_MVC) as sum_SBF_Dda_MVC,
sum(OFERTA_RETENCION) as sum_OFERTA_RETENCION,
sum(case when OFERTA_RETENCION>0 then 1 else 0 end) as sum_CLI_OFERTA_RETENCION,
sum(CUPO_AUMENTADO) as sum_CUPO_AUMENTADO,
sum(case when CUPO_AUMENTADO>0 then 1 else 0 end) as sum_CLI_CUPO_AUMENTADO,
sum(CUPO_ORIGINAL) as sum_CUPO_ORIGINAL,
sum(case when CUPO_ORIGINAL>0 then 1 else 0 end) as sum_CLI_CUPO_ORIGINAL,
(SUM(Sol_IN)) AS SUM_Sol_IN, 
            (SUM(n_Solicitudes_IN)) AS SUM_n_Solicitudes_IN, 
            (SUM(Firma_digital_sol)) AS SUM_Firma_digital_sol,
(SUM(n_Firma_digital_IN)) AS SUM_n_Firma_digital_IN,
            (SUM(Marca_Previred)) AS SUM_Marca_Previred, 
            (SUM(Oferta_Generada)) AS SUM_Oferta_Generada, 
            (SUM(N_Ofertas_Generadas)) AS SUM_N_Ofertas_Generadas, 
            (SUM(Oferta_Aceptada)) AS SUM_Oferta_Aceptada, 
            (SUM(Sol_OUT)) AS SUM_Sol_OUT, 
            (SUM(n_Solicitudes_OUT)) AS SUM_n_Solicitudes_OUT
      FROM &libreria..TABLON_LPF 
	  group by
VU_C_PRIMA, 
ACTIVIDAD_TR,
          Cuadrante, 
          Cuadrante_Grupo, 
          SEMAFORO_RETENCION, 
          SEMAFORO_ATACAR, 
          GSE, 
          'GC: Categoria Gold x 3 meses'n, 
          'GC: Categoria Silver x 3 meses'n, 
          'GC: Despacho gratis 1 cupon'n, 
          'GC: Tasa (superar competencia)'n, 
          'GC: Tasa (igualar competencia)'n, 
          'GC: Costo $0 CV'n, 
          'GC: Costo $0 TAM 3 meses'n, 
          'GC: Cupón Dcto tiendas y .com'n, 
                    Tenencia_Tarjetas_VU, 
          estado_solicitud, 
          Estado_Oferta, 
		  calculated Tramo_OFERTA_CONSO,
calculated Tramo_OFERTA_LD,
calculated Tramo_OFERTA_CONSOLD,
Oferta_Capta,
estado_solicitud,
Tipo_Producto,  
Estado_Oferta, 
fec_num_IN,
PERIODO , 
fec_num_OUT,
Sol_IN,
Sol_OUT,
tipo_oferta_LPF
;QUIT;

/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*******************************************************************************************/
/*** envio email aviso actualización *******************************************************/
/*******************************************************************************************/

Filename myEmail EMAIL
    Subject = "Actualización Tablón LPF " 
    From    = "equipo_datos_procesos_bi@bancoripley.com"
    To      = ("carteagas@bancoripley.com","vtroncoso@bancoripley.com")
    CC      = ("kmartinez@ripley.cl","sjaram@bancoripley.com","pfuenzalida@ripley.com","jvaldebenito@ripley.com","sbarrerav@bancoripley.com")
    Type    = 'Text/Plain';


Data _null_; File myEmail;
    PUT "Finalizó actualización Tablón LPF";
	PUT " ";
    PUT " ";
    PUT " ";
    PUT "Disponible en SAS add-in  PUBLICIN.Resumen_Tablon_LPF ";
     PUT " ";
     PUT "Karina Martínez";
     PUT "Product Manager Inteligencia de Negocios";
     PUT " ";
     PUT " "
;RUN;
