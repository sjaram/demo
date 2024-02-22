
call schm_digital.sp_dgtl_perfil_digital_login(datepart(year,current_date),datepart(month,current_date),cast(date_part(year, current_date)*100+date_part(month, current_date) as int));
