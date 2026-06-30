/*
  Ported from: BAJA_CUPO_AUTOM.sas

/*==================================================================================================*/
*/

CREATE OR REPLACE PROCEDURE schm_artifacts.sp_baja_cupo(
    v_period int4,
    v_nombre_campaing varchar,
    v_user varchar,
    v_fecha varchar,
    v_query varchar
)
LANGUAGE plpgsql
AS $$
BEGIN

    -- SAS macro variables (move to caller / hardcode):
    -- %let tiempo_inicio = %sysfunc(datetime())
    -- %let libreria = RESULT
    -- %let Base_Entregable = %nrstr('RESULT')
    -- %let USUARIO2 = BSOTO2
    -- %let MI_CORREO2 = bsotov@bancoripley.com
    -- %let CAMPANA2 = BAJA_CUPO_DORMIDOS_MORA
    -- %let CAMP_AREA2 = SEGMENTOS
    -- %let CAMP_PROD2 = BJC
    -- %let BASE_LIB2 = WORK.
    -- %let BASE_TAB2 = baja_cupo

	-- ================================================================
	-- CLEANUP: drop workspace tables from previous run
	-- ================================================================
	DROP TABLE IF EXISTS schm_workspace.final;
	DROP TABLE IF EXISTS schm_workspace.base_1;
	DROP TABLE IF EXISTS schm_workspace.baja_cupo_mora;
	DROP TABLE IF EXISTS schm_workspace.baja_cupo_Dormidos;
	DROP TABLE IF EXISTS schm_workspace.baja_cupo;
	DROP TABLE IF EXISTS schm_workspace.cuenta;
	DROP TABLE IF EXISTS schm_workspace.base_limpia;
	DROP TABLE IF EXISTS schm_workspace.baja_cupo_mora_carta;
	DROP TABLE IF EXISTS schm_workspace.baja_cupo_dormidos_carta;
	DROP TABLE IF EXISTS schm_workspace.UNICA_CARGA_CAMP_EMAIL;
	DROP TABLE IF EXISTS schm_workspace.COUNT_DE_TABLA_TMP2;

	-- ================================================================
	-- MAIN LOGIC (translated from BAJA_CUPO_AUTOM.sas)
	-- ================================================================
	select max(anomes) as Max_anomes_ACTR
-- INTO :macro_var (removed – move to caller)
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
trim(libname,.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'schm_data_analytics.ACT_TR_%' 
and length(Nombre_Tabla)=length('schm_data_analytics.ACT_TR_AAAAMM')
) as x

;

	select max(anomes) as Max_anomes_SegCOM
-- INTO :macro_var (removed – move to caller)
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
trim(libname,.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'br_dm_prod_analytics_ripley_puntos_db.SEGMENTO_COMERCIAL_%' 
and length(Nombre_Tabla)=length('br_dm_prod_analytics_ripley_puntos_db.SEGMENTO_COMERCIAL_AAAAMM')
) as x

;

	select max(anomes) as Max_anomes_SegR
-- INTO :macro_var (removed – move to caller)
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
trim(libname,.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'schm_data_analytics.BAJA_CUPO_%' 
and length(Nombre_Tabla)=length('schm_data_analytics.BAJA_CUPO_AAAAMM')
) as x

;

	CREATE TABLE final AS  
        SELECT DISTINCT T1.*,T1.RUT*2-1599 AS ID,
        A.SEGMENTO_FINAL,
        B.ACTIVIDAD_TR,
        C.PRIMER_NOMBRE, 
        C.PATERNO,  
        C.MATERNO,
        D.CALLE,  
        D.NUMERO, 
        D.RESTO,  
        D.COMUNA,  
        D.REGION, 
        CASE WHEN D.RUT IS NOT NULL THEN 1 ELSE 0 END AS T_DIRECCION, 
        case when F.EMAIL not in (select email from schm_data_analytics.lnegro_email) and t1.rut not in (select rut from schm_data_analytics.lnegro_email) then f.email end as Email,  
        CASE WHEN F.RUT IS NOT NULL THEN 1 ELSE 0 END AS T_EMAIL, 
		case when t1.rut in (select rut from schm_data_analytics.lnegro_car) then 1 else 0 end as Lnegro 
         FROM ',&Base_Entregable,'.BAJA_CUPO_',&Max_anomes_SegR,' T1
        LEFT JOIN br_dm_prod_analytics_ripley_puntos_db.SEGMENTO_COMERCIAL_',&Max_anomes_SegCOM,' A ON T1.RUT=A.RUT 
        LEFT JOIN schm_data_analytics.ACT_TR_',&Max_anomes_ACTR,' B ON T1.RUT=B.RUT 
        LEFT JOIN schm_data_analytics.BASE_NOMBRES C ON T1.RUT=C.RUT 
        LEFT JOIN schm_data_analytics.DIRECCIONES D ON T1.RUT=D.RUT 
        LEFT JOIN schm_data_analytics.BASE_TRABAJO_EMAIL F ON T1.RUT=F.RUT 
;

	create table base_1 as
select *,case when Tipo_Disminucion in('Mora Externa',
'Salida Inmediata') then 'Mora Externa'
when 'Contingente' then 'Dormidos'
end as Base,
case when lower(marca_comunicado) like '%carta%' and calle IS NOT NULL then 'Carta'
when lower(marca_comunicado) like '%carta%' and calle IS NULL and email IS NOT NULL then 'Email'
when lower(marca_comunicado) like '%carta%' and calle IS NULL and email IS NULL then 'No Comunicar'
when lower(marca_comunicado) like '%email%' and email IS NOT NULL then 'Email'
when lower(marca_comunicado) like '%email%' and email IS NULL and calle IS NOT NULL then 'Carta'
when lower(marca_comunicado) like '%email%' and email IS NULL and calle IS NULL then 'No Comunicar'
else 'revisar' end as Base2
from final
;

	create table baja_cupo_mora  as
select * from base_1
where base='Mora Externa' and lnegro=0 and (segmento_final IS NULL or segmento_final='RIPLEY_BAJA')
and actividad_tr in ('DORMIDO DURO','DORMIDO BLANDO') and base2 not in ('No Comunicar')
;

	create table baja_cupo_Dormidos as
select * from base_1
where base='Dormidos' and lnegro=0 and (segmento_final IS NULL or segmento_final='RIPLEY_BAJA')
and actividad_tr in ('DORMIDO DURO','DORMIDO BLANDO') and base2 not in ('No Comunicar')
;

	create table baja_cupo as
select *, 'MORA' as VAR_CAMP_TXT_1
from baja_cupo_mora
UNION ALL
select *, 'DORMIDO' as VAR_CAMP_TXT_1
from baja_cupo_Dormidos
;

	create table cuenta as
select 
base,
sum(case when lnegro=1 then 1 else 0 end) as Lnegro,
sum(case when lnegro=0 and (segmento_final IS NULL or segmento_final='RIPLEY_BAJA')
and actividad_tr in ('DORMIDO DURO','DORMIDO BLANDO') and base2 = 'Carta' then 1 else 0 end) as  Carta,
sum(case when lnegro=0 and (segmento_final IS NULL or segmento_final='RIPLEY_BAJA')
and actividad_tr in ('DORMIDO DURO','DORMIDO BLANDO') and base2 = 'Email' then 1 else 0 end) as Email,
sum(case when lnegro=0 and (segmento_final IS NULL or segmento_final='RIPLEY_BAJA')
and actividad_tr in ('DORMIDO DURO','DORMIDO BLANDO') and base2 = 'No Comunicar' then 1 else 0 end) as No_comunicable,
sum(case when lnegro=0 and ((segmento_final IS NOT NULL and segmento_final not ='RIPLEY_BAJA')
or actividad_tr not in ('DORMIDO DURO','DORMIDO BLANDO'))  then 1 else 0 end) as no_aplica
from base_1 
group by base
;

	create table base_limpia as
select * from base_1
where lnegro=0 and (segmento_final IS NULL or segmento_final='RIPLEY_BAJA')
and actividad_tr in ('DORMIDO DURO','DORMIDO BLANDO') and base2 not in ('No Comunicar') 
;

	create table ',&Base_Entregable,'.baja_cupo_',&Max_anomes_SegR,'_final as 
select * from base_limpia 
;

	create table baja_cupo_mora_carta as 
select rut,id,primer_nombre || ' ' || paterno || ' ' || materno as DESTINATARIO,
calle || ' ' || numero || ' ' || resto as DIRECCION,COMUNA,REGIoN
from baja_cupo_mora
where base2='Carta'  
;

	create table baja_cupo_dormidos_carta as 
select rut,id,primer_nombre || ' ' || paterno || ' ' || materno as DESTINATARIO,
calle || ' ' || numero || ' ' || resto as DIRECCION,COMUNA,REGIoN
from baja_cupo_Dormidos
where base2='Carta'  
;

	SELECT EMAIL -- INTO :macro_var (removed – move to caller) 	FROM schm_data_analytics.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
SELECT EMAIL -- INTO :macro_var (removed – move to caller) 	FROM schm_data_analytics.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ_CAMP';
SELECT EMAIL -- INTO :macro_var (removed – move to caller) 	FROM schm_data_analytics.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA_CAMP';
SELECT EMAIL -- INTO :macro_var (removed – move to caller) 	FROM schm_data_analytics.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFATURA_CAMP';
SELECT EMAIL -- INTO :macro_var (removed – move to caller) 	FROM schm_data_analytics.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CAMP_1';
SELECT EMAIL -- INTO :macro_var (removed – move to caller) 	FROM schm_data_analytics.EDP_BI_DESTINATARIOS WHERE CODIGO = 'BENJAMIN_SOTO';
SELECT EMAIL -- INTO :macro_var (removed – move to caller) 	FROM schm_data_analytics.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CAMP_2';
SELECT EMAIL -- INTO :macro_var (removed – move to caller) 	FROM schm_data_analytics.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CAMP_3';
SELECT EMAIL -- INTO :macro_var (removed – move to caller) 	FROM schm_data_analytics.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_SEGMENTOS_1';
SELECT EMAIL -- INTO :macro_var (removed – move to caller) 	FROM schm_data_analytics.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_SEGMENTOS_2';
SELECT EMAIL -- INTO :macro_var (removed – move to caller) 	FROM schm_data_analytics.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_SEGMENTOS';

	Create table UNICA_CARGA_CAMP_EMAIL (
	'CAMPANA-CAMPCODE'n 	CHAR(200), 		/* OBLIGATORIO SMS / PUSH / EMAIL */
	'CAMPANA-AREA'n 		CHAR(200), 		/* SMS / PUSH / EMAIL */
	'CAMPANA-PRODUCTO'n 	CHAR(200), 		/* SMS / PUSH / EMAIL */
	'CAMPANA-CAMPANA'n 		CHAR(200), 		/* OBLIGATORIO SMS / PUSH / EMAIL */
	'CAMPANA-FECHA'n 		CHAR(38), 		/* SMS / PUSH / EMAIL */
	'CAMPANA-CUSTOMERID'n 	NUMERIC(38),	/* SMS / PUSH / EMAIL */
	'CLIENTE-EMAIL'n 		CHAR(50), 		/* SMS / PUSH / EMAIL */
	'CLIENTE-NOMBRE'n  		CHAR(50),
	'CAMPANA-ID_USUARIO'n 	NUMERIC(38),	/* OBLIGATORIO SMS / PUSH / EMAIL */
	'CLIENTE-ID_USUARIO'n 	NUMERIC(38),	/* OBLIGATORIO SMS / PUSH / EMAIL */
	'CAMPANA-IND_RUT_DUP_CAMP'n NUMERIC(38),
	'CAMPANA-VAR_CAMP_TXT_1'n   CHAR(20)
)
;

	INSERT INTO UNICA_CARGA_CAMP_EMAIL
('CAMPANA-CAMPCODE'n, 'CAMPANA-AREA'n, 'CAMPANA-PRODUCTO'n, 'CAMPANA-CAMPANA'n, 'CAMPANA-FECHA'n, 'CAMPANA-CUSTOMERID'n, 'CLIENTE-EMAIL'n, 'CLIENTE-NOMBRE'n,
'CAMPANA-ID_USUARIO'n, 'CLIENTE-ID_USUARIO'n, 'CAMPANA-IND_RUT_DUP_CAMP'n, 'CAMPANA-VAR_CAMP_TXT_1'n )
SELECT DISTINCT "&CAMPCODE_B.", "&CAMP_AREA2.", "&CAMP_PROD2.", "&CAMPANA2.",  "&FECHA2.", RUT, EMAIL,PRIMER_NOMBRE, RUT, RUT, 0 , VAR_CAMP_TXT_1
from &var_BASE2 WHERE BASE2='Email';
;

	CREATE TABLE COUNT_DE_TABLA_TMP2 AS
SELECT COUNT('CAMPANA-ID_USUARIO') AS CANTIDAD_DE_REGISTROS_CARGADOS
from UNICA_CARGA_CAMP_EMAIL
;

	-- UNLOAD example (replace v_query with your SELECT):
	-- EXECUTE
	-- 'UNLOAD(' || quote_literal(v_query) ||
	-- ') to ''s3://br-dm-prod-us-east-1-837538682169-raw/bigdata/campaign/'
	-- || v_nombre_campaing || '/' || v_nombre_campaing || '_' || v_fecha
	-- || '_0-' || v_user
	-- || ''' iam_role ''arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT''
	-- format csv parallel off HEADER ALLOWOVERWRITE extension ''csv'' DELIMITER '','';';

	RETURN;

	-- Post-return cleanup
	DROP TABLE IF EXISTS schm_workspace.final;
	DROP TABLE IF EXISTS schm_workspace.base_1;
	DROP TABLE IF EXISTS schm_workspace.baja_cupo_mora;
	DROP TABLE IF EXISTS schm_workspace.baja_cupo_Dormidos;
	DROP TABLE IF EXISTS schm_workspace.baja_cupo;
	DROP TABLE IF EXISTS schm_workspace.cuenta;
	DROP TABLE IF EXISTS schm_workspace.base_limpia;
	DROP TABLE IF EXISTS schm_workspace.baja_cupo_mora_carta;
	DROP TABLE IF EXISTS schm_workspace.baja_cupo_dormidos_carta;
	DROP TABLE IF EXISTS schm_workspace.UNICA_CARGA_CAMP_EMAIL;
	DROP TABLE IF EXISTS schm_workspace.COUNT_DE_TABLA_TMP2;

END;
$$;

-- ================================================================
-- CALL TEMPLATE
-- ================================================================
-- CALL schm_artifacts.sp_baja_cupo(
--     schm_artifacts.f_period(trunc(DATEADD(MM,-1,current_date))),
--     'SP_BAJA_CUPO',
--     'SJARAM',
--     schm_artifacts.f_period(current_date)::VARCHAR,
--     'select * from schm_workspace.baja_cupo_output'
-- );

