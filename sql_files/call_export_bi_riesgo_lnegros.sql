#sync_database_agent(external_db='riesgo', external_table='from_bi.ctbl_lnegro_call', redshift_table='schm_data_analytics.ctbl_lnegro_call',write_redshift='False', overwrite='False');
#sync_database_agent(external_db='riesgo', external_table='from_bi.ctbl_lnegro_car', redshift_table='schm_data_analytics.ctbl_lnegro_car',write_redshift='False', overwrite='False');

#email_sender = BigdataSesClient();
#email_sender.add_to('dvasquez@bancoripley.com,cminchel@bancoripley.com,lmontalbab@bancoripley.com');
#email_sender.add_subject('AWS MAIL AUTOMATICO: Compartir tabla desde BI a Riesgo Analytics');
#email_sender.add_text('Estimados,\n \n Tabla(s) traspasada(s) desde BI a Riesgo OK \n');
#email_sender.add_text('\n tablas');
#email_sender.add_text('\n   select count(1) from CLOUD_AWS.from_bi.ctbl_lnegro_call');
#email_sender.add_text('\n   select count(1) from CLOUD_AWS.from_bi.ctbl_lnegro_car');
#email_sender.add_text('\n \n');
#email_sender.add_text('Saludos Cordiales');
#email_sender.add_text('Equipo Arquitectura de Datos y Automatización');
#email_sender.add_text('Gerencia Data Analytics');
#email_sender.send_email();

call schm_artifacts.sp_earq_tablas_compartidas_bi_riesgo_analytics('ctbl_lnegro_call', 'schm_data_analytics','Riesgo Analytics', '2024', 'dvasquez@bancoripley.com,cminchel@bancoripley.com,sjaram@bancoripley.com,lmontalbab@bancoripley.com');
call schm_artifacts.sp_earq_tablas_compartidas_bi_riesgo_analytics('ctbl_lnegro_car', 'schm_data_analytics','Riesgo Analytics', '2024', 'dvasquez@bancoripley.com,cminchel@bancoripley.com,sjaram@bancoripley.com,lmontalbab@bancoripley.com');
