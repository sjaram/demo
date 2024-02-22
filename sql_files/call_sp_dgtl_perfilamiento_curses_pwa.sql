call schm_digital.sp_dgtl_perfilamiento_curses_pwa(datepart(year,current_date),datepart(month,current_date),cast(date_part(year, current_date)*100+date_part(month, current_date) as int));
call schm_digital.sp_dgtl_chek_altas_tc();
#email_sender = BigdataSesClient();
#email_sender.add_to('BR_CustodiaCentral@bancoripley.com,schaparroe@bancoripley.com,dcollaor@bancoripley.com,rarcosm@bancoripley.com,rgonzalezs@bancoripley.com,vriverad@bancoripley.com,lmartinezc@bancoripley.com');
#email_sender.add_subject(f'{get_period()[:8]} Altas TC CHEK');
#email_sender.add_text('Buenos dias,\nSe adjunta datos de clientes que dieron alta de TC CHEK \nSaludos, ');
#email_sender.add_file(f'dgtl/chek/altas_tc_chek/altas_tc_chek_{get_period()}.csv');
#email_sender.send_email();
