call schm_artifacts.sp_dgtl_ppff_leads_ref(schm_artifacts.f_period(current_date),current_date);
#email_sender = BigdataSesClient();
#email_sender.add_to('mgonzaleza@bancoripley.com,dvasquez@bancoripley.com,eapinoh@bancoripley.com,sjaram@bancoripley.com,egalveze@bancoripley.com,mvargasc@bancoripley.com,hlunaa@bancoripley.com,cecheverriarr@bancoripley.com,rbuguenoe@bancoripley.com,rarcosm@bancoripley.com,jaburtom@ripley.com,nverdejog@bancoripley.com');
#email_sender.add_subject('AWS MAIL AUTOMATICO: LEADS REFINANCIAMIENTO');
#email_sender.add_text('Estimados,\n \n Adjuntamos Simulaciones de Refinanciamiento \n \n \n \n \n Saludos Cordiales \n Equipo Arquitectura de Datos y Automatización \n Gerencia Data Analytics');
#email_sender.add_file(f'dgtl/banco/dgtl_leads_ppff_ref/leads_ref_{get_period()}.csv');
#email_sender.send_email();