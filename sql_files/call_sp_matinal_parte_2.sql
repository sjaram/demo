call schm_planificacion_comercial.sp_run_spos_tam();
call schm_planificacion_comercial.sp_run_tasa_plazo();
call schm_planificacion_comercial.sp_run_blandos_duros();
call schm_planificacion_comercial.sp_run_ref_rene();
call schm_planificacion_comercial.sp_run_ppff_canal();
call schm_planificacion_comercial.sp_run_ppff_resumen();
call schm_planificacion_comercial.sp_run_clientes();
call schm_planificacion_comercial.sp_vis_blandos_duros();
call schm_planificacion_comercial.sp_vis_captaciones();

#email_sender = BigdataSesClient();
#email_sender.add_to('dvasquez@bancoripley.com,pmunozc@bancoripley.com');
#email_sender.add_subject('AWS MAIL AUTOMATICO: Calls del Matinal Terminados - Parte 2');
#email_sender.add_text('Hola, SP Matinal ejecutado con éxito - Parte 2');
#email_sender.add_text('\n \n');
#email_sender.add_text('v20240126');
#email_sender.add_text('\n \n');
#email_sender.add_text('Saludos Cordiales');
#email_sender.add_text('Equipo Arquitectura de Datos y Automatización');
#email_sender.add_text('Gerencia Data Analytics');
#email_sender.send_email();