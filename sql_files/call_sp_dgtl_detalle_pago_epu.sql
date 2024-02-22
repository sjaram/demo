call schm_digital.sp_dgtl_detalle_pago_epu(schm_artifacts.f_period(current_date),current_date);
#email_sender = BigdataSesClient();
#email_sender.add_to('nverdejog@bancoripley.com,apinedar@bancoripley.com');
#email_sender.add_subject(f'{get_period()[:8]} Detalle Pagos EPU');
#email_sender.add_text('Buenos dias,\nSe adjunta leads de ppff de semana anterior\nSaludos, ');
#email_sender.add_file(f'dgtl/banco/dgtl_detalle_pagos_epu/detalle_pagos_{get_period()}.csv');
#email_sender.add_file(f'dgtl/banco/dgtl_detalle_pagos_epu/detalle_pagos_por_edad_{get_period()}.csv');
#email_sender.send_email();

