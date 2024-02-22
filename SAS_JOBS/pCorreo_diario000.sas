data _null_; 
 FILENAME OUTBOX EMAIL  
 FROM  = ("equipo_datos_procesos_bi@bancoripley.com")
 TO    = ("epielh@ripley.com", "dvasquez@bancoripley.com", "pmunozc@bancoripley.com")      
 CC    = ("sjaram@bancoripley.com")   
 
        
 SUBJECT = ("Info: Ejecución Logueos internet diarios - Simulaciones");
 FILE OUTBOX;
 PUT ;
 PUT ;
 PUT 'Se Ejecutaron correctamente los Siguientes Procesos';
 PUT ;
 PUT 'Logueos Diarios';
 PUT 'Simulaciones'; 
 PUT ;
 PUT 'Que tengas una linda semana, Saludos cordiales';
 PUT ;
 PUT ;
 PUT 'Atte.';
 PUT 'Equipo BI';
 PUT 'Gerencia de Marketing y Productos';
 PUT ;
 PUT ;
 RUN;
