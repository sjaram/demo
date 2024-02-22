call schm_artifacts.sp_ppff_run_principalidad_uso_tctd();
call schm_digital.sp_data_chek_mensual_lsmc(to_char(DATEADD(MM,-1,current_date),'YYYYMM'));