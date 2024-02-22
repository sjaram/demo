CALL schm_artifacts.sp_ppff_tablon_visitas(schm_artifacts.f_first_day(current_date), last_day(current_date), schm_artifacts.f_period(current_date), current_date);

#email_sender = BigdataSesClient();
#email_sender.add_to('dvasquez@bancoripley.com,eapinoh@bancoripley.com,sjaram@bancoripley.com,nreyesc@bancoripley.com,jaburtom@ripley.com');
#email_sender.add_subject('AWS MAIL AUTOMATICO: Proceso PPFF Tablon Visitas');
#email_sender.add_text('Estimados,\n \n Proceso ejecutado OK \n');
#email_sender.add_text('\n \n Saludos Cordiales');
#email_sender.add_text('Equipo Arquitectura de Datos y Automatización');
#email_sender.add_text('Gerencia Data Analytics');
#email_sender.send_email();