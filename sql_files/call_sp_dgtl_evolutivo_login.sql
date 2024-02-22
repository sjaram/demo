call schm_digital.sp_dgtl_evolutivo_login(schm_artifacts.f_period(current_date),current_date);
#email_sender = BigdataSesClient();
#email_sender.add_to('nverdejog@bancoripley.com,apinedar@bancoripley.com,rarcosm@bancoripley.com');
#email_sender.add_subject(f'{get_period()[:8]} Evolutivo Login');
#email_sender.add_text('Buenos dias,\nSe adjunta datos de evolutivo login\nSaludos, ');
#email_sender.add_file(f'dgtl/banco/dgtl_evolutivo_login/seg_evolutivo_login_{get_period()}.csv');
#email_sender.send_email();
