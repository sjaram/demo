/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROPUESTA FUNNEL LPF		================================*/
/* CONTROL DE VERSIONES
/* 2022-02-08 -- V3 -- Rene F. --  
					-- Cambio de fuente de datos para segmento gestion, 
					   ahora se apunta a nlagos.SEGM_GEST_TODAS_PART_AAAAMM_NEW.
/* 2021-04-23 -- V2 -- Karina M. --  
/* 2021-02-26 -- V1 -- Karina M. --  
					-- Versión Original
/* INFORMACIÓN:
	Programa tipo con comentarios e instrucciones básicas para ser estandarizadas al equipo.

	(IN) Tablas requeridas o conexiones a BD:


	(OUT) Tablas de Salida o resultado:
	- PUBLICIN.Datos_funnel_LPF_IN
	- PUBLICIN.Datos_funnel_LPF_OUT
	- PUBLICIN.Datos_funnel_LPF
*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*######################################################################################*/
/*Proceso de creación variables Funnel LPF*/
/*######################################################################################*/

/*PARAMETROS::*/

/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
%let Base_Entregable1=%nrstr('PUBLICIN.Datos_funnel_LPF_IN'); 
%let Base_Entregable2=%nrstr('PUBLICIN.Datos_funnel_LPF_OUT');
%let Base_Entregable3=%nrstr('PUBLICIN.Datos_funnel_LPF');
/*::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/



%put==================================================================================================;
%put [00.00] Extrae SEGMENTO  ULTIMO DISPONIBLE  ;
%put==================================================================================================;


/*Obtener ultimo periodo de tabla disponible*/

PROC SQL noprint;
select max(anomes) as Max_anomes_SegG
into :Max_anomes_SegG
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-9,6),best.) as anomes
from (
select
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'NLAGOSG.SEGM_GEST_TODAS_PART_%'
and length(Nombre_Tabla)=length('NLAGOSG.SEGM_GEST_TODAS_PART_AAAAMM_NEW')
) as x
;QUIT;

%let Max_anomes_SegG=&Max_anomes_SegG;
%put &Max_anomes_SegG
;RUN;


proc sql;
create table SEGMENTO_GESTION as 
select 
a.rut,
a.SEGMENTO AS Segmento_Gestion
from NLAGOSG.SEGM_GEST_TODAS_PART_&Max_anomes_SegG._NEW as a
;quit; 


proc sql;
create table SEGMENTO_COMERCIAL as 
select 
a.rut,
a.SEGMENTO AS Segmento_Comercial
from PUBLICIN.SEGMENTO_COMERCIAL as a
;quit;

%put==================================================================================================;
%put [00.01]   # clientes confirmación solicitud ;
%put==================================================================================================;


PROC SQL;
CREATE TABLE  Clientes_confirmacion_solicitud as
SELECT (COUNT(DISTINCT(cli.rut))) AS Confirman_Solicitud /*, cli.dv, cli.nombre, cli.apellido_paterno, cli.apellido_materno, cli.celular, cli.email 
*/FROM LPF.CLIENTE cli
WHERE cli.ID NOT IN  (SELECT  CLIENTE_ID  from LPF.SOLICITUD)
;QUIT;



%put==================================================================================================;
%put [01.00] Extrae solicitudes generadas IN  ;
%put==================================================================================================;


/* solicitudes IN --> banco_nuevo_id 8 Banco ripley */
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
	sol.banco_nuevo_id,
	case when SUBSTR(sol.id_documento_firmado,1,1) = '2' then  1 else 0 end as Solicitud_Exitosa/*definicion revisada con consuelo y mauricio --que finaliza el flujo con digital-- */
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
(COUNT(sol_prod.producto_id)) AS n_producto_solicitados
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
	calculated  Solicitud_Exitosa
;quit;



%put==================================================================================================;
%put [02.00] Extrae Certificados de liquidación subidos  ;
%put==================================================================================================;

proc sql;
create table Cl_SUBIDOS as
SELECT
	clm.id AS id_cl_interno,
	clm.solicitud_id AS id_solicitud_interno,
    clSol.id_solicitud_portabilidad AS id_solicitud_proveedor_inicial,
    clSol.id_operacion_portabilidad AS id_redbanc,
	ban.nombre AS proveedor_inicial,
    clCli.cliente_rut AS rut,
    clCli.cliente_nombre_razon_social AS nombre,
    clCli.fecha_emision_certificado AS fecha_presentacion,
    solDoc.fecha_actualizacion AS fecha_generacion_documento,
    est.nombre AS estado_solicitud
FROM LPF.cl_main clm
LEFT JOIN LPF.cl_contacto_cliente clCli ON clm.id = clCli.main_id
LEFT JOIN LPF.cl_solicitud clSol ON clm.id = clSol.main_id
LEFT JOIN LPF.solicitud sol ON clm.solicitud_id = sol.id
LEFT JOIN LPF.banco ban ON sol.banco_actual_id = ban.id
LEFT JOIN LPF.estado est ON sol.estado_id = est.id
LEFT JOIN LPF.solicitud_documento solDoc ON sol.id = solDoc.solicitud_id AND solDoc.documento_id = 2
WHERE 	sol.banco_nuevo_id = 8
;QUIT;

/*
Certificados de liquidación para solicitudes de portabilidad por 1 producto debe ser entregado por banco de origen en un plazo de 3 días hábiles bancarios.
Certificados de liquidación para solicitudes de portabilidad por más de 1 producto debe ser entregado por banco de origen en un plazo de 5 días hábiles bancarios.
Estados:
Certificado de liquidación en proceso --> Operaciones solicitó a banco de origen el certificado de liquidación y el proveedor inicial está en plazo de entrega.
Certificado de liquidación en proceso fuera de plazo --> Operaciones solicitó a banco de origen el certificado de liquidación y el proveedor inicial todavía no lo entrega y está fuera de plazo
Certificado de liquidación en plazo --> Certificado de liquidación fue cargado a back office dentro del plazo
Certificado de liquidación fuera de plazo --> Certificado de liquidación fue cargado a back office fuera de plazo
*/

%put==================================================================================================;
%put [02.00] Extrae Ofertas generadas   ;
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
    ofem.estado_oferta = 1 AND 
	est.nombre NOT = 'OFERTA NO DISPONIBLE'
;quit;



%put==================================================================================================;
%put [03.00] Ofertas Aceptada   ;
%put==================================================================================================;

PROC SQL;
   CREATE TABLE WORK.Oferta_Aceptada AS 
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
%put [04.00] Ofertas Ratificadas   ;
%put==================================================================================================;

proc sql;
create table Ratificadas as
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
	sol.banco_actual_id,
	sol.banco_nuevo_id
FROM LPF.solicitud sol
LEFT JOIN LPF.cliente cli ON sol.cliente_id = cli.id
LEFT JOIN LPF.estado est ON sol.estado_id = est.id
WHERE 	sol.banco_nuevo_id = 8
and sol.estado_bo_id=10
;quit;

%put==================================================================================================;
%put [05.00] Ofertas Portadas  ;
%put==================================================================================================;


proc sql;
create table Portadas as
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
	sol.banco_actual_id,
	sol.banco_nuevo_id
FROM LPF.solicitud sol
LEFT JOIN LPF.cliente cli ON sol.cliente_id = cli.id
LEFT JOIN LPF.solicitud_documento sol_doc ON sol_doc.solicitud_id=sol.id
LEFT JOIN LPF.estado est ON sol.estado_id = est.id
WHERE 	sol.banco_nuevo_id = 8
and sol_doc.documento_id=9 AND 
sol_doc.estado_documento_id=5
;quit;

%put==================================================================================================;
%put [06.00] Se Generan marcas  ;
%put==================================================================================================;

proc sql;
create table Solicitudes_in_marcas as
select distinct floor(a.fec_num/100) AS PERIODO,a.*, 1 as Solicitudes_Generadas,
case when b.id_solicitud_interno>=1 then 1 else 0 end as Con_CL,
case when c.id_solicitud_interno>=1 then 1 else 0 end as Con_Oferta_Generada,
B.fecha_presentacion format=date9. as fecha_presentacion_cl2,
datepart (B.fecha_generacion_documento)format=date9. as fecha_generacion_documento2,
g.n_producto_solicitados,
/*intck('weekday',  calculated fecha_presentacion_cl2,calculated fecha_generacion_documento2 ) as dif,*/
/*despues agregar en plazo o fuera de plazo dif de fechas intck('weekday',  '21jan2021'd,'25jan2021'd) as dif*/
case when a.Solicitud_Exitosa=1 and c.id_solicitud_interno is missing    then 1 else 0 end as Sin_Oferta_Generada,
case when d.id_solicitud_interno>=1 then 1 else 0 end as Solicitud_Aceptada,
case when e.id_solicitud_interno>=1 then 1 else 0 end as Solicitud_Ratificada,
case when f.id_solicitud_interno>=1 then 1 else 0 end as Portada
from SP_GENERADAS_IN a
left join Cl_SUBIDOS b on a.id_solicitud_interno=b.id_solicitud_interno
left join ofertas_generadas c on a.id_solicitud_interno=c.id_solicitud_interno
left join Oferta_Aceptada d on a.id_solicitud_interno=d.id_solicitud_interno
left join Ratificadas e on a.id_solicitud_interno=e.id_solicitud_interno
left join Portadas f on a.id_solicitud_interno=f.id_solicitud_interno
left join  sp_generadas_IN_prod g on a.id_solicitud_interno=g.id_solicitud_interno
;quit;

proc sql;
create table Solicitudes_in_marcas1 as
select *,intck('weekday',   fecha_presentacion_cl2, fecha_generacion_documento2 ) as dif_dias,
case when Con_CL =1 and n_producto_solicitados =1 and calculated dif_dias <= 3 then 1 
when Con_CL =1 and n_producto_solicitados >1 and calculated dif_dias <= 5 then 1
else 0 end as Marca_En_Plazo,
case when Con_CL =1 AND calculated  Marca_En_Plazo NOT = 1 then 1 else 0   end as Marca_Fuera_Plazo,
case when estado_solicitud ='OFERTA EXPIRADA' and Solicitud_Exitosa=1 then 1 else 0 end as  Solicitudes_Expiradas,
case when Tipo_Solicitud = 'IN'	and Solicitud_Exitosa=1 then 1 else 0 END AS  Solicitud_IN,
case when Con_Oferta_Generada =1 and Solicitud_Aceptada not =1 and estado_solicitud not ='OFERTA EXPIRADA' then 1 else 0 end as Con_Oferta_Noacepta_en_Plazo,
case when Con_Oferta_Generada =1 and Solicitud_Aceptada not =1 and estado_solicitud  ='OFERTA EXPIRADA' then 1 else 0 end as Con_Oferta_Noacepta_Fuera_Plazo
from Solicitudes_in_marcas
;quit;



%put=========================================================================================;
%put [7] Guardar entregable ;
%put=========================================================================================;

%put-----------------------------------------------------------------------------------------;
%put [7.1] Guardar entregable del detalle;
%put-----------------------------------------------------------------------------------------;


DATA _NULL_;
Call execute(
cat('
proc sql; 

CREATE TABLE Solicitudes_in_marcas2 AS 
select a.*,b.Segmento_Gestion,c.Segmento_Comercial,d.gse  
from work.Solicitudes_in_marcas1 a 
left join segmento_gestion b on a.rut=b.rut  
left join segmento_comercial c on a.rut=c.rut 
left join publicin.GSE_2018 d on a.rut=d.rut 
;quit; 
')
);
run;





%put==================================================================================================;
%put [08.00] Extrae solicitudes generadas OUT  ;
%put==================================================================================================;


/* solicitudes IN --> banco_nuevo_id 8 Banco ripley */
/*6616*/

proc sql;
create table sp_generadas_OUT as
SELECT 'OUT' AS Tipo_Solicitud,
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
	case when SUBSTR(sol.id_documento_firmado,1,1) = '2' then  1 else 0 end as Solicitud_Exitosa/*definicion revisada con consuelo y mauricio --que finaliza el flujo con digital-- */
FROM LPF.solicitud sol
LEFT JOIN LPF.banco ban ON sol.banco_nuevo_id = ban.id
LEFT JOIN LPF.cliente cli ON sol.cliente_id = cli.id
LEFT JOIN LPF.estado est ON sol.estado_id = est.id
WHERE 	sol.banco_actual_id = 8
;quit;


%put==================================================================================================;
%put [08.01] Extrae solicitudes generadas IN y Cantidad de productos solicitados ;
%put==================================================================================================;


proc sql;
create table sp_generadas_OUT_prod as
SELECT 'OUT' AS Tipo_Solicitud,
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
(COUNT(sol_prod.producto_id)) AS n_producto_solicitados
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
WHERE 		sol.banco_actual_id = 8
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
	calculated  Solicitud_Exitosa
;quit;


%put==================================================================================================;
%put [09.00] Extrae Certificados de liquidación subidos  ;
%put==================================================================================================;

proc sql;
create table Cl_GENERADOS as
SELECT
	clm.id AS id_cl_interno,
	clm.solicitud_id AS id_solicitud_interno,
    clSol.id_solicitud_portabilidad AS id_solicitud_proveedor_inicial,
    clSol.id_operacion_portabilidad AS id_redbanc,
	ban.nombre AS proveedor_inicial,
    clCli.cliente_rut AS rut,
    clCli.cliente_nombre_razon_social AS nombre,
    clCli.fecha_emision_certificado AS fecha_presentacion,
    solDoc.fecha_actualizacion AS fecha_generacion_documento,
    est.nombre AS estado_solicitud
FROM LPF.cl_main clm
LEFT JOIN LPF.cl_contacto_cliente clCli ON clm.id = clCli.main_id
LEFT JOIN LPF.cl_solicitud clSol ON clm.id = clSol.main_id
LEFT JOIN LPF.solicitud sol ON clm.solicitud_id = sol.id
LEFT JOIN LPF.banco ban ON sol.banco_nuevo_id = ban.id
LEFT JOIN LPF.estado est ON sol.estado_id = est.id
LEFT JOIN LPF.solicitud_documento solDoc ON sol.id = solDoc.solicitud_id 
AND solDoc.documento_id = 2
WHERE 	sol.banco_actual_id = 8
;QUIT;


/*
Certificados de liquidación para solicitudes de portabilidad por 1 producto debe ser entregado por banco de origen en un plazo de 3 días hábiles bancarios.
Certificados de liquidación para solicitudes de portabilidad por más de 1 producto debe ser entregado por banco de origen en un plazo de 5 días hábiles bancarios.
Estados:
Certificado de liquidación en proceso --> Operaciones solicitó a banco de origen el certificado de liquidación y el proveedor inicial está en plazo de entrega.
Certificado de liquidación en proceso fuera de plazo --> Operaciones solicitó a banco de origen el certificado de liquidación y el proveedor inicial todavía no lo entrega y está fuera de plazo
Certificado de liquidación en plazo --> Certificado de liquidación fue cargado a back office dentro del plazo
Certificado de liquidación fuera de plazo --> Certificado de liquidación fue cargado a back office fuera de plazo
*/



%put==================================================================================================;
%put [10.00] Ofertas Portadas  ;
%put==================================================================================================;


proc sql;
create table Portadas_OUT as
SELECT 'OUT' AS Tipo_Solicitud,
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
	sol.banco_actual_id,
	sol.banco_nuevo_id
FROM LPF.solicitud sol
LEFT JOIN LPF.cliente cli ON sol.cliente_id = cli.id
LEFT JOIN LPF.solicitud_documento sol_doc ON sol_doc.solicitud_id=sol.id
LEFT JOIN LPF.estado est ON sol.estado_id = est.id
WHERE 	sol.banco_actual_id = 8
and sol_doc.documento_id=9 
AND sol_doc.estado_documento_id=4
;quit;

%put==================================================================================================;
%put [06.00] Se Generan marcas  ;
%put==================================================================================================;

proc sql;
create table Solicitudes_out_marcas as
select distinct floor(a.fec_num/100) AS PERIODO,a.*, 1 as Solicitudes_Generadas,
case when b.id_solicitud_interno>=1 then 1 else 0 end as Con_CL,
 0  as Con_Oferta_Generada,
B.fecha_presentacion format=date9. as fecha_presentacion_cl2,
datepart (B.fecha_generacion_documento)format=date9. as fecha_generacion_documento2,
g.n_producto_solicitados,
/*intck('weekday',  calculated fecha_presentacion_cl2,calculated fecha_generacion_documento2 ) as dif,*/
/*despues agregar en plazo o fuera de plazo dif de fechas intck('weekday',  '21jan2021'd,'25jan2021'd) as dif*/
 0  as Sin_Oferta_Generada,
0  as Solicitud_Aceptada,
0  as Solicitud_Ratificada,
case when f.id_solicitud_interno>=1 then 1 else 0 end as Portada
from SP_GENERADAS_OUT a
left join Cl_GENERADOS b on a.id_solicitud_interno=b.id_solicitud_interno
/*left join ofertas_generadas c on a.id_solicitud_interno=c.id_solicitud_interno*/
/*left join Oferta_Aceptada d on a.id_solicitud_interno=d.id_solicitud_interno*/
/*left join Ratificadas e on a.id_solicitud_interno=e.id_solicitud_interno*/
left join Portadas_OUT f on a.id_solicitud_interno=f.id_solicitud_interno
left join  sp_generadas_OUT_prod g on a.id_solicitud_interno=g.id_solicitud_interno
;quit;

proc sql;
create table Solicitudes_out_marcas1 as
select *,intck('weekday',   fecha_presentacion_cl2, fecha_generacion_documento2 ) as dif_dias,
case when Con_CL =1 and n_producto_solicitados =1 and calculated dif_dias <= 3 then 1 
when Con_CL =1 and n_producto_solicitados >1 and calculated dif_dias <= 5 then 1
else 0 end as Marca_En_Plazo,
case when Con_CL =1 AND calculated  Marca_En_Plazo NOT = 1 then 1 else 0   end as Marca_Fuera_Plazo,
case when estado_solicitud ='OFERTA EXPIRADA' and Solicitud_Exitosa=1 then 1 else 0 end as  Solicitudes_Expiradas,
case when Tipo_Solicitud = 'OUT'  then 1 else 0 END AS Solicitud_OUT	
from Solicitudes_out_marcas
;quit;



%put=========================================================================================;
%put [7] Guardar entregable ;
%put=========================================================================================;

%put-----------------------------------------------------------------------------------------;
%put [7.1] Guardar entregable del detalle;
%put-----------------------------------------------------------------------------------------;


DATA _NULL_;
Call execute(
cat('
proc sql; 

CREATE TABLE Solicitudes_out_marcas2 AS 
select a.*,b.Segmento_Gestion,c.Segmento_Comercial,d.gse   
from work.Solicitudes_out_marcas1   a  
left join segmento_gestion b on a.rut=b.rut   
left join segmento_comercial c on a.rut=c.rut 
left join publicin.GSE_2018 d on a.rut=d.rut 
;quit; 
')
);
run;


%put-----------------------------------------------------------------------------------------;
%put [7.2] Guardar entregable del resumen;
%put-----------------------------------------------------------------------------------------;

DATA _NULL_;
Call execute(
cat('
proc sql; 

CREATE TABLE ',&Base_Entregable1,'_RESUMEN AS 
SELECT t1.PERIODO,t1.fecha, 
          t1.fec_num,
	      t1.Segmento_Gestion,
	      t1.Segmento_Comercial,
	      t1.gse, 
          t1.Tipo_Solicitud, 
          t1.estado_solicitud, 
          t1.proveedor_inicial, 
          t1.Solicitudes_Generadas,
          t1.Solicitud_IN, 
          t1.Solicitud_Exitosa,
	      t1.Solicitudes_Expiradas ,
          t1.Con_CL,
		  t1.Marca_En_Plazo, 
		  t1.Marca_Fuera_Plazo,
          t1.Con_Oferta_Generada,
t1.Con_Oferta_Noacepta_en_Plazo,
t1.Con_Oferta_Noacepta_Fuera_Plazo, 
          t1.Sin_Oferta_Generada, 
          t1.Solicitud_Aceptada, 
          t1.Solicitud_Ratificada, 
          t1.Portada, 
          (COUNT(DISTINCT(t1.rut))) AS n_Clientes, 
          (SUM(t1.Solicitudes_Generadas)) FORMAT=BEST12. AS sum_Solicitudes_Generadas, 
		  (SUM(t1.Solicitud_IN)) AS sum_Solicitud_IN,
          (SUM(t1.Solicitud_Exitosa)) AS sum_Solicitud_Exitosa,
		  (SUM(t1.Solicitudes_Expiradas)) AS sum_Solicitud_Expirada,
          (SUM(t1.Con_CL)) AS sum_Con_CL, 
		  (SUM(t1.Marca_En_Plazo)) AS sum_Marca_En_Plazo,
		  (SUM(t1.Marca_Fuera_Plazo)) AS sum_Marca_Fuera_Plazo,
          (SUM(t1.Con_Oferta_Generada)) AS sum_Con_Oferta_Generada, 
		  (SUM(t1.Con_Oferta_Noacepta_en_Plazo)) AS sum_Oferta_Noacepta_en_Plazo, 
		  (SUM(t1.Con_Oferta_Noacepta_Fuera_Plazo)) AS sum_Oferta_Noacepta_Fuera_Plazo, 
          (SUM(t1.Sin_Oferta_Generada)) AS sum_Sin_Oferta_Generada, 
          (SUM(t1.Solicitud_Aceptada)) AS sum_Solicitud_Aceptada, 
          (SUM(t1.Solicitud_Ratificada)) AS sum_Solicitud_Ratificada, 
          (SUM(t1.Portada)) AS sum_Portada
      FROM WORK.SOLICITUDES_IN_MARCAS2 t1
      GROUP BY t1.PERIODO,t1.fecha,
               t1.fec_num,
			   t1.Segmento_Gestion,
	           t1.Segmento_Comercial,
	           t1.gse,
               t1.Tipo_Solicitud,
               t1.estado_solicitud,
               t1.proveedor_inicial,
               t1.Solicitudes_Generadas,
			   t1.Solicitud_IN,
               t1.Solicitud_Exitosa,
			   t1.Solicitudes_Expiradas,
               t1.Con_CL,
			   t1.Marca_En_Plazo, 
		       t1.Marca_Fuera_Plazo,
               t1.Con_Oferta_Generada,
			   t1.Con_Oferta_Noacepta_en_Plazo,
t1.Con_Oferta_Noacepta_Fuera_Plazo,
               t1.Sin_Oferta_Generada,
               t1.Solicitud_Aceptada,
               t1.Solicitud_Ratificada,
               t1.Portada 

;quit; 
')
);
run;


DATA _NULL_;
Call execute(
cat('
proc sql; 

CREATE TABLE ',&Base_Entregable2,'_RESUMEN AS 
SELECT t1.PERIODO,t1.fecha, 
          t1.fec_num,
	      t1.Segmento_Gestion,
	      t1.Segmento_Comercial,
	      t1.gse ,
          t1.Tipo_Solicitud, 
          t1.estado_solicitud, 
          t1.proveedor_inicial, 
          t1.Solicitudes_Generadas, 
		  t1.Solicitud_OUT,
          t1.Solicitud_Exitosa,
	      t1.Solicitudes_Expiradas , 
          t1.Con_CL,
		  t1.Marca_En_Plazo, 
		  t1.Marca_Fuera_Plazo,
          t1.Con_Oferta_Generada, 
          t1.Sin_Oferta_Generada, 
          t1.Solicitud_Aceptada, 
          t1.Solicitud_Ratificada, 
          t1.Portada, 
          (COUNT(DISTINCT(t1.rut))) AS n_Clientes, 
          (SUM(t1.Solicitudes_Generadas)) FORMAT=BEST12. AS sum_Solicitudes_Generadas, 
		  (SUM(t1.Solicitud_OUT)) AS sum_Solicitud_OUT,
          (SUM(t1.Solicitud_Exitosa)) AS sum_Solicitud_Exitosa, 
		  (SUM(t1.Solicitudes_Expiradas)) AS sum_Solicitud_Expirada,
          (SUM(t1.Con_CL)) AS sum_Con_CL, 
		  (SUM(t1.Marca_En_Plazo)) AS sum_Marca_En_Plazo,
		  (SUM(t1.Marca_Fuera_Plazo)) AS sum_Marca_Fuera_Plazo,
          (SUM(t1.Con_Oferta_Generada)) AS sum_Con_Oferta_Generada, 
          (SUM(t1.Sin_Oferta_Generada)) AS sum_Sin_Oferta_Generada, 
          (SUM(t1.Solicitud_Aceptada)) AS sum_Solicitud_Aceptada, 
          (SUM(t1.Solicitud_Ratificada)) AS sum_Solicitud_Ratificada, 
          (SUM(t1.Portada)) AS sum_Portada
      FROM WORK.SOLICITUDES_OUT_MARCAS2 t1
      GROUP BY t1.PERIODO,t1.fecha,
               t1.fec_num,
			   t1.Segmento_Gestion,
	           t1.Segmento_Comercial,
	           t1.gse,
               t1.Tipo_Solicitud,
               t1.estado_solicitud,
               t1.proveedor_inicial,
               t1.Solicitudes_Generadas,
			   t1.Solicitud_OUT,
               t1.Solicitud_Exitosa,
			   t1.Solicitudes_Expiradas ,
               t1.Con_CL,
			   t1.Marca_En_Plazo, 
		       t1.Marca_Fuera_Plazo,
               t1.Con_Oferta_Generada,
               t1.Sin_Oferta_Generada,
               t1.Solicitud_Aceptada,
               t1.Solicitud_Ratificada,
               t1.Portada 

;quit; 
')
);
run;




DATA _NULL_;
Call execute(
cat('
proc sql; 

CREATE TABLE ',&Base_Entregable3,'_RESUMEN AS 
SELECT * FROM ',&Base_Entregable1,'_RESUMEN 
OUTER UNION CORR SELECT * FROM ',&Base_Entregable2,'_RESUMEN 
OUTER UNION CORR SELECT * FROM Clientes_confirmacion_solicitud

;quit; 
')
);
run;

/*Eliminar tabla de paso*/
proc sql; drop table work.SP_GENERADAS_IN ;quit; 
proc sql; drop table work.Cl_SUBIDOS ;quit; 
proc sql; drop table work.ofertas_generadas ;quit; 
proc sql; drop table work.Oferta_Aceptada ;quit; 
proc sql; drop table work.Ratificadas ;quit; 
proc sql; drop table work.Portadas ;quit; 
proc sql; drop table work.SP_GENERADAS_OUT ;quit; 
proc sql; drop table work.Cl_GENERADOS ;quit; 
proc sql; drop table work.Portadas_OUT ;quit; 


/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
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

/*******************************************************************************************/
/*** envio email aviso actualización *******************************************************/
/*******************************************************************************************/

Filename myEmail EMAIL
    Subject = "Actualización FUNNEL LPF " 
    From    = "equipo_datos_procesos_bi@bancoripley.com"
    To      = ("carteagas@bancoripley.com","fcasanovav@bancoripley.com")
    CC      = ("kmartinez@ripley.com","sjaram@bancoripley.com","pfuenzalida@ripley.com","jvaldebenito@ripley.com","sbarrerav@bancoripley.com","rfonsecaa@bancoripley.com")
    Type    = 'Text/Plain';


Data _null_; File myEmail;
    PUT "Finalizó actualización FUNNEL LPF, ejecutado con fecha: &fechaeDVN";
	PUT " ";
    PUT " ";
    PUT " ";
    PUT "Disponible en SAS add-in  PUBLICIN.Datos_funnel_LPF_RESUMEN ";
     PUT " ";
	put 'Proceso Vers. 02'; 
	PUT ;
	PUT ;
	PUT 'Atte.';
	Put 'Equipo Datos y Procesos BI';
     PUT " ";
     PUT " "
;RUN;
