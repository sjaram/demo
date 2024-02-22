call schm_artifacts.sp_run_clts_opex_canjesop();

#email_sender = BigdataSesClient();
#email_sender.add_to('dvasquez@bancoripley.com,sjaram@bancoripley.com');
#email_sender.add_subject('AWS MAIL AUTOMATICO: Proceso Opex Canjesop');
#email_sender.add_text('Estimados,\n \n Proceso Opex Canjesop ejecutado  OK \n');
#email_sender.add_text('\n \n');
#email_sender.add_text('Saludos Cordiales');
#email_sender.add_text('Equipo Arquitectura de Datos y Automatización');
#email_sender.add_text('Gerencia Data Analytics');
#email_sender.send_email();