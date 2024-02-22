CALL schm_digital.sp_dgtl_funnel_ppff(date_part('year', CURRENT_DATE):: int, date_part('month', CURRENT_DATE)::int, schm_artifacts.f_period(CURRENT_DATE), CURRENT_DATE);
call schm_digital.sp_dgtl_indicador_digitalizacion(schm_artifacts.f_period(CURRENT_DATE),current_date);
call schm_digital.sp_dgtl_nuevo_funnel_ppff(schm_artifacts.f_period(CURRENT_DATE),current_date);
#email_sender = BigdataSesClient();
#email_sender.add_to('nverdejog@bancoripley.com,tpiwonkas@bancoripley.com,rarcosm@bancoripley.com,tfarres@bancoripley.com');
#email_sender.add_subject(f'{get_period()[:8]} Funnel Digital PPFF');
#email_sender.add_text('Buenos dias,\nSe adjunta datos de funnel ppff \nSaludos, ');
#email_sender.add_file(f'dgtl/banco/dgtl_funnel_ppff/funnel_ppff_mes_actual_{get_period()}.csv');
#email_sender.add_file(f'dgtl/banco/dgtl_funnel_ppff/funnel_ppff_consolidado_{get_period()}.csv');
#email_sender.add_file(f'dgtl/banco/dgtl_funnel_ppff/nuevo_funnel_ppff_{get_period()}.csv');
#email_sender.send_email();
call schm_digital.sp_dgtl_funnel_ref(schm_artifacts.f_period(CURRENT_DATE),current_date);
#email_sender = BigdataSesClient();
#email_sender.add_to('nverdejog@bancoripley.com,rarcosm@bancoripley.com,cperezv@bancoripley.com');
#email_sender.add_subject(f'{get_period()[:8]} Funnel Digital REF');
#email_sender.add_text('Buenos dias,\nSe adjunta datos de funnel REF \nSaludos, ');
#email_sender.add_file(f'dgtl/banco/dgtl_funnel_ppff_ref/funnel_ppff_ref_{get_period()}.csv');
#email_sender.send_email();


