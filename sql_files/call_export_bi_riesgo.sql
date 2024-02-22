#sync_database_agent(external_db='riesgo', external_table='from_bi.gedcre_dcrm_cos_mov_trn_det_vta_art', redshift_table='br_dm_prod_bigdata_gedcre_db.gedcre_dcrm_cos_mov_trn_det_vta_art',write_redshift='False', overwrite='False');

#email_sender = BigdataSesClient();
#email_sender.add_to('dvasquez@bancoripley.com,cminchel@bancoripley.com,lmontalbab@bancoripley.com');
#email_sender.add_subject('AWS MAIL AUTOMATICO: Compartir tabla desde BI a Riesgo Analytics');
#email_sender.add_text('Estimados,\n \n Tabla(s) traspasada(s) desde BI a Riesgo');
#email_sender.add_text('\n tablas');
#email_sender.add_text('\n   select count(1) from CLOUD_AWS.from_bi.gedcre_dcrm_cos_mov_trn_det_vta_art');
#email_sender.add_text('\n \n');
#email_sender.add_text('Saludos Cordiales');
#email_sender.add_text('Equipo Arquitectura de Datos y Automatización');
#email_sender.add_text('Gerencia Data Analytics');
#email_sender.send_email();

call schm_artifacts.sp_earq_tablas_compartidas_bi_riesgo_analytics('gedcre_dcrm_cos_mov_trn_det_vta_art', 'br_dm_prod_bigdata_gedcre_db','Riesgo Analytics', '2024-01-15', 'dvasquez@bancoripley.com,cminchel@bancoripley.com,lmontalbab@bancoripley.com');