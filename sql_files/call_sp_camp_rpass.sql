call schm_artifacts.sp_camp_rpass( 'CAMPAIGN_INPUT_TR_CAMPANA',
										 cast(to_char(current_date,'YYYYMMDD') as integer),
										 'nvargas', 
										 'select * from schm_campanas.camp_rpass',
										 schm_artifacts.f_period(current_date));
call schm_digital.sp_dgtl_chek_email_callcenter();
#email_sender = BigdataSesClient();
#email_sender.add_to('nvargasc@bancoripley.com','acolmenaresp@bancoripley.com', 'rgonzalezs@bancoripley.com', 'tpiwonkas@bancoripley.com', 'rarcosm@bancoripley.com');
#email_sender.add_subject(f'{get_period()[:8]} Base camp_rpass_chek generada'); 
#email_sender.add_text('Buenos dias,\nLa base de la camp_rpass_chek fue generada y enviada acoustic.\nSaludos, ');
#email_sender.send_email();
