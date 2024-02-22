call schm_artifacts.sp_earq_drop_tb_schm_workspace();

#email_sender = BigdataSesClient();
#email_sender.add_to('dvasquez@bancoripley.com');
#email_sender.add_subject('AWS MAIL AUTOMATICO: Esquema Workspace Vaciado');
#email_sender.add_text('Estimados,\n \n Se ha ejecutado sp que limpia schm_workspace con éxito \n \n \n Saludos Cordiales \n Equipo Arquitectura de Datos y Automatización \n Gerencia Data Analytics');
#email_sender.send_email();