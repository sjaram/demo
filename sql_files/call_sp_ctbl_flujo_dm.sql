CALL schm_artifacts.sp_clts_universo_panes();

CALL schm_artifacts.sp_ctbl_tr_planes('CAMPAIGN_INPUT_TR_PLANES','SJARAM',schm_artifacts.f_period(getdate()::DATE),'select * from schm_data_analytics.tr_planes');

CALL schm_artifacts.sp_clts_productos_segmentos();

CALL schm_artifacts.sp_camp_score(schm_artifacts.f_period_add_n_months(schm_artifacts.f_period(current_date),-6));

CALL schm_artifacts.sp_ctbl_data_master('CAMPAIGN_INPUT_DATAMASTER_USER_TC','SJARAM',schm_artifacts.f_period(current_date)::VARCHAR,'select * from schm_workspace.envio_data_master');

CALL schm_artifacts.sp_camp_reporte_journeys(to_char(trunc(DATEADD(MM,-6,current_date)),'YYYYMM')::INTEGER);
