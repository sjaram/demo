CALL schm_artifacts.onb_3m_prueba(to_char(DATEADD(MM,-1,current_date),'YYYYMM')::INTEGER,
schm_artifacts.f_first_day(dateadd(MONTH,-1,current_date)::date),
schm_artifacts.f_last_day_given_period(to_char(DATEADD(MM,-1,current_date),'YYYYMM')::INTEGER));

CALL schm_artifacts.onb_3m_prueba(to_char(DATEADD(MM,-2,current_date),'YYYYMM')::INTEGER,
schm_artifacts.f_first_day(dateadd(MONTH,-2,current_date)::date),
schm_artifacts.f_last_day_given_period(to_char(DATEADD(MM,-2,current_date),'YYYYMM')::INTEGER));

CALL schm_artifacts.onb_3m_prueba(to_char(DATEADD(MM,-3,current_date),'YYYYMM')::INTEGER,
schm_artifacts.f_first_day(dateadd(MONTH,-2,current_date)::date),
schm_artifacts.f_last_day_given_period(to_char(DATEADD(MM,-3,current_date),'YYYYMM')::INTEGER));