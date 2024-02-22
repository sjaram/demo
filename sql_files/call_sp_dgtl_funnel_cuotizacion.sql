call schm_artifacts.sp_dgtl_funnel_cuotizacion(schm_artifacts.f_period(current_date),current_date);
#email_sender = BigdataSesClient();
#email_sender.add_to('nverdejog@bancoripley.com,bsarquisa@bancoripley.com,rarcosm@bancoripley.com');
#email_sender.add_subject(f'{get_period()[:8]} Funnel Cuotización');
#email_sender.add_text('Buenos dias,\nSe adjunta funnel de cuotización\nSaludos, ');
#email_sender.add_file(f'dgtl/banco/dgtl_funnel_cuotizacion/funnel_ppff_cuotizacion_{get_period()}.csv');
#email_sender.add_file(f'dgtl/banco/dgtl_funnel_cuotizacion/detalle_auotizacion_trx_{get_period()}.csv');
#email_sender.add_file(f'dgtl/banco/dgtl_funnel_cuotizacion/curses_cuotizacion_{get_period()}.csv');
#email_sender.send_email();
