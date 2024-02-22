call schm_digital.sp_dgtl_leads_ppff(cast(dateadd(day,-7,current_date) as date),current_date);
#email_sender = BigdataSesClient();
#email_sender.add_to('nverdejog@bancoripley.com,tpiwonkas@bancoripley.com');
#email_sender.add_subject(f'{get_period()[:8]} Leads PPFF');
#email_sender.add_text('Buenos dias,\nSe adjunta leads de ppff de semana anterior\nSaludos, ');
#email_sender.add_file(f'dgtl/banco/dgtl_leads_ppff/leads_ppff_{get_period()}.csv');
#email_sender.send_email();

