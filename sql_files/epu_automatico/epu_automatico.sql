-------------- EPU_AUTOMATICO --------------
-- Autor : Patricio Quintero
-- email : pquinteroc@bancoripley.cl

-- select DATE_PART(month, current_date) as date_flt
-- select current_date, now();
-- SELECT
--   CURRENT_DATE,
--   (CURRENT_DATE - INTERVAL '3 months')::date
-- select current_date, DATE_PART(day, current_date) as date_flt;
-- select DATE_PART(year, current_date)||DATE_PART(month, current_date);

DROP TABLE IF EXISTS schm_workspace.mdpg_epu_cortes;
DROP TABLE IF EXISTS schm_workspace.mdpg_epu_cobro;
DROP TABLE IF EXISTS schm_workspace.mdpg_epu_cobro2;
DROP TABLE IF EXISTS schm_workspace.mdpg_base_epu;
DROP TABLE IF EXISTS schm_workspace.mdpg_unicos;
DROP TABLE IF EXISTS schm_workspace.mdpg_epu_mesactual;

CREATE TABLE schm_workspace.mdpg_epu_cortes AS
SELECT
    semuc_coc_eda_k	as entidad,
    semuc_coc_cen_ata_k	as  sucursal,
    semuc_coc_nro_cta_k as contrato,
    semuc_clv_enc_rut as rut,
    semuc_fch_fcn_k as corte,
    semuc_mnt_cuo_mes as monto_facturado,
    semuc_coc_prd as producto,
    semuc_mnt_pag_min_per as pago_minimo,
    CASE
        WHEN semuc_est_dir_epu in (0,1,2) THEN 1
        ELSE 0
    END AS si_epu_fisico,
    CASE
        WHEN semuc_est_dir_epu = 3 THEN 1
        ELSE 0
    END AS si_epu_mail
FROM br_dm_prod_bigdata_reporitf_db.sfepus_mae_nuc_cab
WHERE semuc_fch_fcn_k BETWEEN (CURRENT_DATE - INTERVAL '1 months')::date and CURRENT_DATE
  AND semuc_gls_emr ='S'
  AND semuc_dia_mor<80
;


CREATE TABLE schm_workspace.mdpg_epu_cobro AS
SELECT
    sednd_coc_cen_ata_k	as  sucursal,
    sednd_coc_nro_cta_k as contrato,
    sednd_cod_tip_fac,
    sednd_fch_fcn_k,
    sednd_mnt_fac,
    sednd_gls_trn
FROM br_dm_prod_bigdata_reporitf_db.sfepus_det_nuc_det
WHERE sednd_fch_fcn_k between (CURRENT_DATE - INTERVAL '1 months')::date and CURRENT_DATE
   AND sednd_cod_tip_fac in (201,237)
;

create table schm_workspace.mdpg_epu_cobro2 as
select
    a.*,
    b.sednd_cod_tip_fac as tip_fac_201,
    b.sednd_fch_fcn_k as fec_201,
    b.sednd_mnt_fac as monto_201,
    b.sednd_gls_trn as glosa_201,
    c.sednd_cod_tip_fac as tip_fac_237,
    c.sednd_fch_fcn_k as fec_237,
    c.sednd_mnt_fac as monto_237,
    c.sednd_gls_trn as glosa_237
from (
    select
        distinct sucursal,
        contrato
    from schm_workspace.mdpg_epu_cortes
    ) as a
    left join (
        select * from schm_workspace.mdpg_epu_cobro where sednd_cod_tip_fac in (201)
    ) as b on(a.contrato=b.contrato) and (a.sucursal=b.sucursal)
    left join (
        select * from schm_workspace.mdpg_epu_cobro where sednd_cod_tip_fac in (237)
    ) as c on(a.contrato=c.contrato) and (a.sucursal=c.sucursal)
;

create table schm_workspace.mdpg_base_epu as
select
    a.*,
    case
        when b.contrato is not null then coalesce(b.glosa_201,b.glosa_237)
    end as glosa,
    case
        when b.contrato is not null then 1
        else 0
    end  as si_mantencionepu,
    case
        when b.contrato is not null then coalesce(b.monto_201,0)+coalesce(b.monto_237,0)
    end as sednd_mnt_fac
from schm_workspace.mdpg_epu_cortes as a
left join schm_workspace.mdpg_epu_cobro2 as b
    on(a.contrato=b.contrato) and (a.sucursal=b.sucursal)
;

CREATE TABLE schm_workspace.mdpg_unicos AS
SELECT
    entidad,
    sucursal,
    contrato,
    RUT as rut,
    CORTE as facturacion,
    monto_facturado*1 as saldo,
    case
        when producto='01' then 'TR (con revolving)'
        when producto='03' then 'TR (sin revolving)'
        when producto='05' then 'TAM (con revolving)'
        when producto='06' then 'TAM (sin revolving)'
        when producto='07' then 'TAM chip'
    END as tipo_producto,
    pago_minimo*1 as pago_minimo,
    si_epu_fisico as si_epufisico,
    si_epu_mail as si_epumail,
    si_mantencionepu,
    glosa,
    sum(sednd_mnt_fac*1) as mto_mantencion
FROM schm_workspace.mdpg_base_epu
GROUP BY
    entidad,
    sucursal,
    contrato,
    rut,
    corte,
    monto_facturado,
    tipo_producto,
    pago_minimo,
    si_epu_fisico,
    si_epu_mail,
    si_mantencionepu,
    glosa
;

DELETE
    FROM schm_workspace.mdpg_contratoepu
WHERE
    periodo = DATE_PART(year, current_date)||DATE_PART(month, current_date)
;

CREATE TABLE schm_workspace.mdpg_contratoepu as
SELECT
    rut,
    cast(contrato as BIGINT) as contrato,
    cast(sucursal as BIGINT) as sucursal,
    facturacion,
    saldo,
    pago_minimo,
    tipo_producto,
    si_epumail,
    si_epufisico,
    si_mantencionepu,
    CASE
        WHEN si_mantencionepu=1 THEN facturacion
    END as fechacorte,
    glosa,
    mto_mantencion,
    DATE_PART(year, current_date)||DATE_PART(month, current_date) as periodo
FROM schm_workspace.mdpg_unicos
;

CREATE TABLE schm_workspace.mdpg_mpdt012 AS
SELECT
    codent,
    centalta,
    cuenta,
    indnorcor,
    tipofac,
    fecfac,
    indmovanu,
    impfac,
    descuento,
    linea,
    pan
FROM br_dm_prod_bigdata_reporitf_db.mpdt012
WHERE
      fecfac between (CURRENT_DATE - INTERVAL '1 months')::date and CURRENT_DATE
  AND tipofac in (237,76)
;

CREATE TABLE schm_workspace.mdpg_cuentas AS
SELECT
    b.pemid_gls_nro_dct_ide_k as rut,
    a.codent,
    a.centalta,
    a.cuenta,
    a.fecalta as fecalta_ctto,
    a.fecbaja as fecbaja_ctto,
    a.producto,
    a.subprodu,
    a.conprod,
    a.grupoliq,
    a.indblqope,
    CASE
        WHEN a.grupoliq=1 THEN 5
        WHEN a.grupoliq=2 THEN 10
        WHEN a.grupoliq=3 THEN 15
        WHEN a.grupoliq=4 THEN 20
        WHEN a.grupoliq=5 THEN 25
        WHEN a.grupoliq=6 THEN 30
        WHEN a.grupoliq=7 THEN 18
    END as corte
FROM br_dm_prod_bigdata_reporitf_db.mpdt007 a
INNER JOIN br_dm_prod_bigdata_reporitf_db.bopers_mae_ide B
   ON a.identcli=b.pemid_nro_inn_ide
WHERE a.producto NOT IN ('08','12','13')
;

CREATE TABLE schm_workspace.mdpg_mpdt012_v2 AS
SELECT
    a.*,
    b.rut ,
    b.PRODUCTO,
    b.SUBPRODU,
    b.CONPROD,
    b.corte
FROM schm_workspace.mdpg_mpdt012 as a
LEFT JOIN schm_workspace.mdpg_cuentas as b
    ON (a.cuenta=b.cuenta) and (a.centalta=b.centalta)
;

CREATE TABLE schm_workspace.mdpg_mpdt012_v3 AS
SELECT
    a.*,
    b.facturacion,
    b.si_mantencionepu
from schm_workspace.mdpg_mpdt012_v2 as a
LEFT JOIN schm_workspace.mdpg_contratoepu as b
    ON a.cuenta  = b.contrato
;

CREATE TABLE schm_workspace.mdpg_epu_mesactual AS
SELECT
    rut,
    producto,
    subprodu,
    conprod,
    pan,
    fecfac as fecfac,
    CASE
        WHEN si_mantencionepu=1 THEN DATE_PART(day, current_date)
        ELSE corte
    END as corte,
    codent,
    centalta,
    cuenta,
    sum(IMPFAC) as monto,
    count(cuenta) as trx,
    sum(
        CASE
            WHEN si_mantencionepu=1 and fecfac <= facturacion then impfac
        ELSE 0
        END
    ) as monto_actual,
    count(
        case
            when si_mantencionepu=1 and FECFAC <= FACTURACION then cuenta
        end
    ) as trx_actual,
    sum(
        case when  FECFAC > FACTURACION then  IMPFAC
        else 0
        end
    ) as monto_des,
    count(
        case
            when FECFAC > FACTURACION then cuenta
        end
    ) as trx_DES,
    DATE_PART(year, current_date)||DATE_PART(month, current_date) as periodo
FROM schm_workspace.mdpg_mpdt012_v3
group by
    rut,
    producto,
    subprodu,
    conprod,
    CASE WHEN si_mantencionepu=1 THEN DATE_PART(day, current_date) ELSE corte END,
    codent,
    centalta,
    cuenta,
    fecfac,
    pan,
    DATE_PART(year, current_date)||DATE_PART(month, current_date)
;

DELETE
    FROM schm_business_intelligence.mdpg_epu_mesactual
WHERE
    periodo = DATE_PART(year, current_date)||DATE_PART(month, current_date)
;

--CREATE TABLE schm_business_intelligence.mdpg_epu_mesactual AS
INSERT INTO schm_business_intelligence.mdpg_epu_mesactual
SELECT
    *
FROM schm_workspace.mdpg_epu_mesactual;