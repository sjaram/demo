call schm_artifacts.sp_dgtl_funnel_dap(schm_artifacts.f_period(current_date),current_date);
#email_sender = BigdataSesClient();
#email_sender.add_to('nverdejog@bancoripley.com,apinedar@bancoripley.com,tpiwonkas@bancoripley.com,rarcosm@bancoripley.com,dbergoeingc@bancoripley.com,gmattheos@bancoripley.com,cchamorroc@bancoripley.com');
#email_sender.add_subject(f'{get_period()[:8]} Funnel DAP');
#email_sender.add_text('Buenos dias,\nSe adjunta funnel de DAP actualizado.\nSaludos, ');
#email_sender.add_file(f'dgtl/banco/dgtl_funnel_ppff_dap/funnel_ppff_dap_{get_period()}.csv');
#email_sender.add_file(f'dgtl/banco/dgtl_funnel_ppff_dap/detalle_curses_dap_{get_period()}.csv');
#email_sender.send_email();