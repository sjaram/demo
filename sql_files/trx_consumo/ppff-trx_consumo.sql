-------------- TRX_CONSUMO --------------
-- Autor        : Patricio Quintero
-- email        : pquinteroc@bancoripley.cl
-- Periodicidad :

-- select DATE_PART(month, current_date) as date_flt
-- select current_date, now();
-- SELECT
--   CURRENT_DATE,
--   (CURRENT_DATE - INTERVAL '3 months')::date
-- select current_date, DATE_PART(day, current_date) as date_flt;
-- select DATE_PART(year, current_date)||DATE_PART(month, current_date);

DROP TABLE IF EXISTS schm_workspace.trx_bco1;
DROP TABLE IF EXISTS schm_workspace.multi1;
DROP TABLE IF EXISTS schm_workspace.multi2;
DROP TABLE IF EXISTS schm_workspace.multi3;

DROP TABLE IF EXISTS schm_workspace.base1;
DROP TABLE IF EXISTS schm_workspace.base2;
DROP TABLE IF EXISTS schm_workspace.base3;



CREATE TABLE schm_workspace.trx_bco1 AS
SELECT
    a.pre_credito
   ,d.rut
   ,sum (d.monto_liquido) as venta_liquida
   ,sum (d.monto_bruto) as venta_bruta
   ,a.pre_numper
   ,a.pre_fecontab as fecha_contble
   ,a.pre_fecemi
   ,a.pre_tasapac
   ,decode(a.pre_sucursal, 0, 'huerfanos 1060', 1, 'HUERFANOS 1060', pkg_data_marketing.obtiene_nombre_sucursal(a.pre_sucursal)) as sucursal
   ,pkg_data_marketing.obtiene_nombre_zona_sucursal(a.pre_sucursal) as zona
   ,e.canal_agenda
   ,(f.propension * 10) as propension
   ,f.rango_propension
   ,pkg_data_marketing.obtiene_rut_empleadO(a.pre_codeje) as rut_ejecutivo_curse
   ,pkg_data_marketing.obtiene_nombre_usuaRIO(a.PRE_CODEJE) as nombre_ejecutivo_curse
   ,g.leverage
   ,h.prd_nombre
   ,e.nombre_promocion as promo_base
   ,e.nombre_promocion as nombre_promocion
   ,e.cupo_promo as monto_oferta_promo_base
FROM br_dm_prod_bigdata_fisa_db.tpre_prestamos a,
     br_dm_prod_bigdata_fisa_db.tcli_persona b,
     br_dm_prod_bigdata_fisa_db.br_dm_colocaciones_bco_sav d, -- no
     br_dm_prod_bigdata_fisa_db.br_cam_minuta_final e,
     br_dm_prod_bigdata_fisa_db.br_dm_propension_crm f,
     br_dm_prod_bigdata_fisa_db.br_dm_leverage_campanas g, --no
    (SELECT prd_pro, prd_nombre FROM tgen_productos WHERE prd_mod = 6) h
WHERE a.pre_clientep = b.cli_codigo
   AND substr(b.cli_identifica, 1, length(b.cli_identifica) - 1) = d.rut
   AND d.fecini_promocion  = to_char(trunc(sysdate,'mm'), 'dd-mm-yyyy')
   AND TRUNC (a.pre_fecONTAB) between trunc(sysdate, 'mm') and trunc(last_day(sysdate))
   AND a.pre_pro not in(45,59,73,50,51,80,15,38,70,8,39,82,99,41)
   AND a.pre_status = 'E'
   AND d.lugar_pago = 'BCO'
   AND d.RUT = e.rut(+)
   AND d.rut = f.rut(+)
   AND d.rut = g.rut(+)
   AND to_char(G.FECINI(+),'dd/mm/yyyy') = to_char(trunc(sysdate,'mm'), 'dd/mm/yyyy')
   AND a.pre_pro = h.prd_pro
   AND e.tipo_promo_plat(+) not in (66,69,70)
GROUP BY
    a.pre_credito
   ,d.rut
   ,a.pre_numper
   ,a.pre_fecontab
   ,a.pre_fecemi
   ,a.pre_tasapac
   ,a.pre_sucursal
   ,e.canal_agenda
   ,f.propension
   ,f.rango_propension
   ,a.pre_codeje
   ,g.LEVERAGe
   ,h.prd_nombre
   ,e.NOMBRE_PROMOCION
   ,e.cupo_promo
;


CREATE TABLE schm_workspace.multi1 AS
SELECT
    rut
    ,nombre_promocion
    ,cupo_promo
FROM br_dm_prod_bigdata_fisa_db.br_cam_minuta_final
WHERE tipo_promo_plat = 66
;


CREATE TABLE schm_workspace.multi2 as
SELECT
    rut
    ,nombre_promocion
    ,cupo_promo
FROM br_dm_prod_bigdata_fisa_db.br_cam_minuta_final
WHERE tipo_promo_plat = 69
;


CREATE TABLE schm_workspace.multi3 as
SELECT *
SELECT
    rut
    ,nombre_promocion
    ,cupo_promo
FROM br_dm_prod_bigdata_fisa_db.br_cam_minuta_final
WHERE tipo_promo_plat = 70
;


CREATE TABLE schm_workspace.base1
SELECT
   a.*,
   b.nombre_promocion as multi1,
   b.cupo_promo as oferta_multi1
FROM schm_workspace.trx_bco1 as a
LEFT JOIN schm_workspace.multi1 as b ON(a.rut = b.rut)
;

CREATE TABLE schm_workspace.base2 as
SELECT
   t1.*,
   t2.nombre_promocion as multi2,
   t2.cupo_promo as oferta_multi2
FROM schm_workspace.base1 as a
LEFT JOIN WORK.MULTI2 as b ON(a.RUT = b.RUT)
;

CREATE TABLE schm_workspace.base3 as
SELECT
   a.*,
   b.nombre_promocion as multi3,
   b.cupo_promo as oferta_multi3
FROM schm_workspace.base2 as a
LEFT JOIN schm_workspace.multi3 AS b ON(a.rut = b.rut)
;


CREATE TABLE schm_workspace.trx_consumo as
SELECT * FROM schm_workspace.base3