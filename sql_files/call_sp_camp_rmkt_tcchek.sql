call schm_artifacts.sp_camp_rmkt_tcchek( 'CAMPAIGN_INPUT_TR_CAMPANA',
										 cast(to_char(current_date,'YYYYMMDD') as integer),
										 'nvargas', 
										 'select * from schm_campanas.rmkt_tcchek',
										 schm_artifacts.f_period(current_date));