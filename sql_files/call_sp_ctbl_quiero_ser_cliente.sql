call schm_artifacts.sp_ctbl_quiero_ser_cliente();
#email_sender = BigdataSesClient();
#email_sender.add_to('dvasquez@bancoripley.com,sjaram@bancoripley.com,eapinoh@bancoripley.com,fsotoga@bancoripley.com');
#email_sender.add_subject('AWS MAIL AUTOMATICO: Proceso Quiero Ser Cliente');
#email_sender.add_text('Estimados,\n \n Proceso Quiero Ser Cliente ejecutado OK \n \n');
#email_sender.add_text('\n Saludos Cordiales');
#email_sender.add_text('\n Equipo Arquitectura de Datos y Automatización');
#email_sender.add_text('\n Gerencia Data Analytics');
#email_sender.send_email();

