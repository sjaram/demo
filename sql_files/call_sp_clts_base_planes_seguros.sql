CALL schm_clientes.sp_base_planes_seguros('Base_Planes_seguros', 'select * from schm_clientes.Base_Planes_seguros');
#email_sender = BigdataSesClient();
#email_sender.add_to('dvasquez@bancoripley.com,eapinoh@bancoripley.com,sjaram@bancoripley.com,nlagosg@bancoripley.com,kmartinezb@bancoripley.com,nbittnert@bancoripley.com,mbustamanten@bancoripley.com,acanalesm@bancoripley.com,furrutiar@bancoripley.com,mdelsolarr@bancoripley.com');
#email_sender.add_subject('AWS MAIL AUTOMATICO: Rutero marca Plan Seguros');
#email_sender.add_text('Estimados,\n \n Adjuntamos Rutero de clientes Plan dados de baja y su estado de la tarjeta \n \n \n \n \n Saludos Cordiales \n Equipo Arquitectura de Datos y Automatización \n Gerencia Data Analytics');
#email_sender.add_file(f'clts/base_planes_seguros/Base_Planes_seguros000.csv');
#email_sender.send_email(); 