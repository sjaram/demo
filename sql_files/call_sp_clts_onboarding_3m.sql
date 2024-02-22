CALL schm_artifacts.sp_clts_onboarding_3m(to_char(DATEADD(MM,-6,current_date),'YYYYMM')::INTEGER,to_char(DATEADD(MM,-6,current_date),'YYYYMM')::INTEGER);
 
CALL schm_artifacts.sp_clts_onboarding_3m(to_char(DATEADD(MM,-5,current_date),'YYYYMM')::INTEGER,to_char(DATEADD(MM,-5,current_date),'YYYYMM')::INTEGER);
 
CALL schm_artifacts.sp_clts_onboarding_3m(to_char(DATEADD(MM,-4,current_date),'YYYYMM')::INTEGER,to_char(DATEADD(MM,-4,current_date),'YYYYMM')::INTEGER);
 
CALL schm_artifacts.sp_clts_onboarding_3m(to_char(DATEADD(MM,-3,current_date),'YYYYMM')::INTEGER,to_char(DATEADD(MM,-3,current_date),'YYYYMM')::INTEGER);
 
CALL schm_artifacts.sp_clts_onboarding_3m(to_char(DATEADD(MM,-2,current_date),'YYYYMM')::INTEGER,to_char(DATEADD(MM,-2,current_date),'YYYYMM')::INTEGER);
 
CALL schm_artifacts.sp_clts_onboarding_3m(to_char(DATEADD(MM,-1,current_date),'YYYYMM')::INTEGER,to_char(DATEADD(MM,-1,current_date),'YYYYMM')::INTEGER);

CALL schm_artifacts.sp_clts_onboarding_3m(to_char(DATEADD(MM,0,current_date),'YYYYMM')::INTEGER,to_char(DATEADD(MM,0,current_date),'YYYYMM')::INTEGER);