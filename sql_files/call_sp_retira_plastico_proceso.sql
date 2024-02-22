call schm_artifacts.sp_ppff_retira_plastico_proceso(trunc(DATEADD(D,1,current_date)), schm_artifacts.f_last_day_given_period(schm_artifacts.f_period((trunc(current_date)))));

#sftp_redshift_sender('camp_motor_ftp',f'ppff/salida_retira_plastico/GCO_INI_IC00027_{get_dmy()}000.txt',f'/ftpcamp/GCO_INI_IC00027_{get_dmy()}.txt',600);


#email_sender = BigdataSesClient();
#email_sender.add_to('dvasquez@bancoripley.com,jmonteso@bancoripley.com');
#email_sender.add_subject('AWS MAIL AUTOMATICO: Proceso Retira Plástico');
#email_sender.add_text('Estimados,\n \n Proceso Retira Plástico ejecutado  OK \n');
#email_sender.add_text('\n \n');
#email_sender.add_text('Saludos Cordiales');
#email_sender.add_text('Equipo Arquitectura de Datos y Automatización');
#email_sender.add_text('Gerencia Data Analytics');
#email_sender.send_email();
