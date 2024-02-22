CALL schm_productos_financieros.sp_ppff_tablon_campanas(
schm_artifacts.f_first_day(DATEADD(month, 0, getdate())::DATE) 
, trunc(getdate()) 
, cast(schm_artifacts.f_period(DATEADD(month, 0, getdate())::DATE) as integer)
,'CAMPAIGN_INPUT_PPFF_CAMPAIGN_MODEL'
,'USRAUTO'
,TO_CHAR(GETDATE(), 'YYYYMMDD')
,'select * from schm_workspace.ppff_tablon_camp_comerciales_export'
);
call schm_productos_financieros.sp_run_ppff_radiografia_CtaCte();