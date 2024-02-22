call schm_digital.sp_dgtl_chek_email_callcenter();
#email_sender = BigdataSesClient();
#email_sender.add_to('lmontalbab@bancoripley.com,callendeo@bancoripley.com,lmartinezc@bancoripley.com,lsolarif@bancoripley.com,rgonzalezs@bancoripley.com,lfigueroau@bancoripley.com,jlazcanof@bancoripley.com,mvargasc@bancoripley.com,hlunaa@bancoripley.com,rarcosm@bancoripley.com');
#email_sender.add_subject(f'{get_period()[:8]} Leads Diarios');
#email_sender.add_text('Buenos dias,\nSe adjunta bases leads diarios para su gestión.\nSaludos, ');
#email_sender.add_file(f'dgtl/chek/CONSUMO_{get_period()}.csv');
#email_sender.add_file(f'dgtl/chek/SAV_{get_period()}.csv');
#email_sender.send_email();