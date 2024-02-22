call schm_artifacts.sp_spos_analisis_petrobras_miercoles(schm_artifacts.f_period(current_date));

#email_sender = BigdataSesClient();
#email_sender.add_to('dvasquez@bancoripley.com,pmunozc@bancoripley.com');
#email_sender.add_subject('AWS MAIL AUTOMATICO: SP Análisis Petrobras');
#email_sender.add_text('Estimados,');
#email_sender.add_text('SP Análisis Petrobras ejecutado OK,');
#email_sender.add_text('\n \n');
#email_sender.add_text('Saludos Cordiales');
#email_sender.add_text('Equipo Arquitectura de Datos y Automatización');
#email_sender.add_text('Gerencia Data Analytics');
#email_sender.send_email();