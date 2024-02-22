CALL schm_artifacts.sp_ctbl_tr_planes('CAMPAIGN_INPUT_TR_PLANES' ,'SJARAM' ,schm_artifacts.f_period(getdate()::DATE),'select * from schm_data_analytics.tr_planes');
