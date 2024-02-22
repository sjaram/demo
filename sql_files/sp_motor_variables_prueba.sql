CALL schm_artifacts.sp_ppff_variables_motor_precios_final(202312,202402);

CALL schm_artifacts.f_unload_s3_txt('select customeridentification,activityreference,producttypereference,productpropensitychannel,inactivityperiod,customerrelationhiprating,customerbehaviormodeltype,customerrelationshipstatus,customerbehaviormodelother,productreference,elasticity,rentability,propensityadvance,propensityconsumption,punto_y_coma from schm_data_analytics.ppff_variables_motor_precio where periodo = schm_artifacts.f_period(trunc(DATEADD(MM,0,current_date)))', 'ppff/variables_motor/VISTA_MOTOR_PRICING_DATA_TABLE');

#sftp_redshift_sender(arg_sftp='camp_motor_ftp', aws_file_key='ppff/variables_motor/VISTA_MOTOR_PRICING_DATA_TABLE000.txt', sftp_file_key='/bas_04/sat/ripley/ripprod/dat/VISTA_MOTOR_PRICING_DATA_TABLE_2024.txt');

#email_sender = BigdataSesClient();
#email_sender.add_to('dvasquez@bancoripley.com');
#email_sender.add_subject('AWS MAIL AUTOMATICO: Proceso Variables Motor de Precios');
#email_sender.add_text('Estimados,\n \n Proceso Variables Motor de Precios ejecutado  OK \n');
#email_sender.add_text('\n \n');
#email_sender.add_text('Saludos Cordiales');
#email_sender.add_text('Equipo Arquitectura de Datos y Automatización');
#email_sender.add_text('Gerencia Data Analytics');
#email_sender.send_email();