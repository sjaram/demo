call schm_artifacts.sp_ppff_evolutivo_venta_ref(schm_artifacts.f_period_add_n_months(to_char(current_date,'yyyymm')::INTEGER, 0)::INTEGER
                                               ,schm_artifacts.f_period_add_n_months(to_char(current_date,'yyyymm')::INTEGER, -1)::INTEGER);
