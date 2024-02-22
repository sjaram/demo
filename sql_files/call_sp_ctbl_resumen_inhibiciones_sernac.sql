CALL schm_artifacts.ctbl_resumen_inhibiciones_sernac('CTBL_RESUMEN_INHIBICIONES_SERNAC','select * from schm_data_analytics.resumen_final');
#email_sender = BigdataSesClient();
#email_sender.add_to('sjaram@bancoripley.com,pfuenzalidam@bancoripley.com,fsotoga@bancoripley.com,dvasquez@bancoripley.com,lmontalbab@bancoripley.com');
#email_sender.add_subject('Proceso Resumen Inhibiciones Sernac');
#email_sender.add_text('Resumen Inhibiciones Sernac');
#email_sender.add_text('saludos');
#email_sender.add_file('ctbl/resumen_inhibiciones_sernac/CTBL_RESUMEN_INHIBICIONES_SERNAC000.csv');
#email_sender.send_email();
