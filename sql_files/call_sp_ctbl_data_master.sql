CALL schm_artifacts.sp_ctbl_data_master('CAMPAIGN_INPUT_DATAMASTER_USER_TC'
,'SJARAM'
,schm_artifacts.f_period(getdate()::DATE)
,'select * from schm_workspace.envio_data_master');
