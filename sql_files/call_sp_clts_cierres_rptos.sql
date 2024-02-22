call schm_artifacts.sp_clts_cierres_rptos();

#email_sender = BigdataSesClient();
#email_sender.add_to('dvasquez@bancoripley.com,eapinoh@bancoripley.com,sjaram@bancoripley.com,nlagosg@bancoripley.com');
#email_sender.add_subject('AWS MAIL AUTOMATICO: Cierre Rptos');
#email_sender.add_text('Estimados,\n \n Cierre Rptos ejecutado \n \n \n Saludos Cordiales \n Equipo Arquitectura de Datos y Automatización \n Gerencia Data Analytics');
#email_sender.send_email();