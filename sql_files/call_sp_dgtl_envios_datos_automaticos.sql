call schm_digital.sp_dgtl_envios_datos_automaticos(datepart(year,current_date),datepart(month,current_date),cast(date_part(year, current_date)*100+date_part(month, current_date) as int),current_date);
#email_sender = BigdataSesClient();
#email_sender.add_to('nverdejog@bancoripley.com,tpiwonkas@bancoripley.com,rarcosm@bancoripley.com,msanhuezaa@bancoripley.com,vmorah@bancoripley.com,apinedar@bancoripley.com');
#email_sender.add_subject(f' Datos Canal Digital - {get_period()[:8]}');
#email_sender.add_text('Buenos dias,\nSe adjunta las siguientes bases del mes en curso:\n-Curses PPFF\n-Captación\n-Enrolados Rpass\nSaludos, ');
#email_sender.add_file(f'dgtl/banco/dgtl_envio_datos_automaticos/curses_ppff/curses_ppff_av_{get_period()}.csv');
#email_sender.add_file(f'dgtl/banco/dgtl_envio_datos_automaticos/curses_ppff/curses_ppff_sav_{get_period()}.csv');
#email_sender.add_file(f'dgtl/banco/dgtl_envio_datos_automaticos/curses_ppff/curses_ppff_consumo_{get_period()}.csv');
#email_sender.add_file(f'dgtl/banco/dgtl_envio_datos_automaticos/captacion/captacion_{get_period()}.csv');
#email_sender.add_file(f'dgtl/banco/dgtl_envio_datos_automaticos/enrolados_rpass/enrolados_rpass_{get_period()}.csv');
#email_sender.send_email();

#email_sender = BigdataSesClient();
#email_sender.add_to('nverdejog@bancoripley.com,tpiwonkas@bancoripley.com,rarcosm@bancoripley.com,msanhuezaa@bancoripley.com,vmorah@bancoripley.com,apinedar@bancoripley.com');
#email_sender.add_subject(f'Datos Canal Digital - Login - {get_period()[:8]}');
#email_sender.add_text('Buenos dias,\nSe adjunta login actualizado al día anterior\nSaludos, ');
#email_sender.add_file(f'dgtl/banco/dgtl_envio_datos_automaticos/login/login_{get_period()}.csv');
#email_sender.send_email();


#email_sender = BigdataSesClient();
#email_sender.add_to('nverdejog@bancoripley.com,tpiwonkas@bancoripley.com,rarcosm@bancoripley.com,msanhuezaa@bancoripley.com,vmorah@bancoripley.com,apinedar@bancoripley.com');
#email_sender.add_subject(f'Datos Canal Digital - Simulacion PPFF - {get_period()[:8]}');
#email_sender.add_text('Buenos dias,\nSe adjunta datos de simulacion actualizados al día anterior\nSaludos, ');
#email_sender.add_file(f'dgtl/banco/dgtl_envio_datos_automaticos/simulaciones_ppff/simulaciones_ppff_av_{get_period()}.csv');
#email_sender.add_file(f'dgtl/banco/dgtl_envio_datos_automaticos/simulaciones_ppff/simulaciones_ppff_sav_{get_period()}.csv');
#email_sender.add_file(f'dgtl/banco/dgtl_envio_datos_automaticos/simulaciones_ppff/simulaciones_ppff_consumo_{get_period()}.csv');
#email_sender.send_email();

#email_sender = BigdataSesClient();
#email_sender.add_to('nverdejog@bancoripley.com,tpiwonkas@bancoripley.com,rarcosm@bancoripley.com,msanhuezaa@bancoripley.com,vmorah@bancoripley.com,apinedar@bancoripley.com');
#email_sender.add_subject(f'Datos Canal Digital - DAP - {get_period()[:8]}');
#email_sender.add_text('Buenos dias,\nSe adjunta datos de DAP actualizados al día anterior\nSaludos, ');
#email_sender.add_file(f'dgtl/banco/dgtl_envio_datos_automaticos/curses_ppff/curses_ppff_dap_{get_period()}.csv');
#email_sender.add_file(f'dgtl/banco/dgtl_envio_datos_automaticos/simulaciones_ppff/simulaciones_ppff_dap_{get_period()}.csv');
#email_sender.send_email();

#email_sender = BigdataSesClient();
#email_sender.add_to('nverdejog@bancoripley.com,rarcosm@bancoripley.com,fcerdag@bancoripley.com,cchamorroc@bancoripley.com,cdiazc@ext.bancoripley.com,priveros@bancoripley.com,jaravena@bancoripley.com,cmaturana@bancoripley.com');
#email_sender.add_subject(f'Datos PWA - Curses Consumo - {get_period()[:8]}');
#email_sender.add_file(f'dgtl/banco/dgtl_envio_datos_automaticos/curses_ppff/curses_ppff_consumo_operaciones_{get_period()}.csv');
#email_sender.send_email();
