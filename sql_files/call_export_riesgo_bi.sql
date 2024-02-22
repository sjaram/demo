#sync_database_agent('riesgo','dbo.AJUSTECUPOPROC_202401','br_dm_prod_bigdata_riesgo_analytics_sql_db.ajustecupoproc',write_redshift='True', overwrite='True');

#email_sender = BigdataSesClient();
#email_sender.add_to('dvasquez@bancoripley.com,eapinoh@bancoripley.com,sjaram@bancoripley.com');
#email_sender.add_subject('AWS MAIL AUTOMATICO: Compartir tabla desde Riesgo Analytics a BI');
#email_sender.add_text('Estimados,\n \n Tabla(s) traspasada(s) OK desde Riesgo a BI \n \n \n Saludos Cordiales \n Equipo Arquitectura de Datos y Automatización \n Gerencia Data Analytics');
#email_sender.send_email();

call schm_artifacts.sp_earq_tablas_compartidas_bi_riesgo_analytics('AJUSTECUPOPROC_202401', 'Riesgo Analytics', 'br_dm_prod_bigdata_riesgo_analytics_sql_db', '2024-01-30', 'dvasquez@bancoripley.com,eapinoh@bancoripley.com,sjaram@bancoripley.com');