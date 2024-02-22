call schm_digital.sp_dgtl_grupos_facturacion_tenencia_td_login(datepart(year,current_date),datepart(month,current_date),cast(date_part(year, current_date)*100+date_part(month, current_date) as int),current_date);
#email_sender = BigdataSesClient();
#email_sender.add_to('nverdejog@bancoripley.com,rarcosm@bancoripley.com,apinedar@bancoripley.com');
#email_sender.add_subject(f'{get_period()[:8]} Actualización Grupos de Facturación y Tenencia TD, con login');
#email_sender.add_text('Buenos dias,\nSe adjuntan archivos actualizados.\nSaludos, ');
#email_sender.add_file(f'dgtl/banco/dgtl_grupos_facturacion_tenencia_td_login/grupos_facturacion_tc_{get_period()}.csv');
#email_sender.add_file(f'dgtl/banco/dgtl_grupos_facturacion_tenencia_td_login/grupos_saldo_o_mov_td_{get_period()}.csv');
#email_sender.send_email();

