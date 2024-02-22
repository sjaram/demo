CALL schm_artifacts.sp_clts_baja_cupo(schm_artifacts.f_period(current_date)-1,'BAJA_CUPO','SJARAM',schm_artifacts.f_period(current_date)::VARCHAR,'select * from schm_workspace.camp_baja_cupo');
#email_sender = BigdataSesClient();
#email_sender.add_to('dvasquez@bancoripley.com,eapinoh@bancoripley.com,sjaram@bancoripley.com,aillanesa@bancoripley.com,cjarav@bancoripley.com,fjnorambuena@bancoripley.com,rfuentealbaf@bancoripley.com,bsotov@bancoripley.com,nlagosg@bancoripley.com,rarcosm@bancoripley.com,kmartinezb@bancoripley.com');
#email_sender.add_subject('AWS MAIL AUTOMATICO: BAJA CUPO');
#email_sender.add_text('Estimados,\n \n Adjuntamos bases para baja de cupo carta \n \n \n \n \n Saludos Cordiales \n Equipo Arquitectura de Datos y Automatización \n Gerencia Data Analytics');
#email_sender.add_file(f'clts/baja_cupo/carta_dormidos000.csv');
#email_sender.add_file(f'clts/baja_cupo/carta_mora000.csv');
#email_sender.send_email();