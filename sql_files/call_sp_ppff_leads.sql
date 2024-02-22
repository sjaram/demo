CALL schm_artifacts.sp_ppff_leads('LEADS_SAV_CALL_ARCHIVO_UNICO','select * from schm_data_analytics.ppff_leads_call_center');
#email_sender = BigdataSesClient();
#email_sender.add_to('dvasquez@bancoripley.com,eapinoh@bancoripley.com,sjaram@bancoripley.com,egalveze@bancoripley.com,mvargasc@bancoripley.com,hlunaa@bancoripley.com,cecheverriarr@bancoripley.com,jvaldebenitot@bancoripley.com,rbuguenoe@bancoripley.com,rarcosm@bancoripley.com,jaburtom@ripley.com,nverdejog@bancoripley.com');
#email_sender.add_subject('AWS MAIL AUTOMATICO: LEADS ARCHIVO ÚNICO');
#email_sender.add_text('Estimados,\n \n Adjuntamos Simulaciones de SAV, AV y CONSUMO \n \n \n \n \n Saludos Cordiales \n Equipo Arquitectura de Datos y Automatización \n Gerencia Data Analytics');
#email_sender.add_file(f'ppff/leads/LEADS_SAV_CALL_ARCHIVO_UNICO000.csv');
#email_sender.send_email();