CALL schm_artifacts.sp_ctbl_lnegro_car();

#email_sender = BigdataSesClient();
#email_sender.add_to('dvasquez@bancoripley.com,eapinoh@bancoripley.com,sjaram@bancoripley.com,fsotoga@bancoripley.com,pfuenzalidam@bancoripley.com');
#email_sender.add_subject('AWS MAIL AUTOMATICO: Lnegro CAR');
#email_sender.add_text('Estimados,\n \n Proceso Lnegro CAR ejecutado OK \n \n');
#email_sender.add_text('\n \n');
#email_sender.add_text('Saludos Cordiales');
#email_sender.add_text('Equipo Arquitectura de Datos y Automatización');
#email_sender.add_text('Gerencia Data Analytics');
#email_sender.send_email();