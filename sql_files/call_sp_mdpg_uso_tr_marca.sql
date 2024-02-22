CALL schm_artifacts.sp_run_mdpg_uso_tr_marca();
CALL schm_digital.sp_dgtl_chek_reporte_diario_lsmc(CURRENT_DATE-1);
CALL schm_digital.sp_dgtl_chek_funnel_mensual_lsmc();