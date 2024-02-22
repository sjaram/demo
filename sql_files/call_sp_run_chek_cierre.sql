-- DROP PROCEDURE schm_planificacion_comercial.sp_run_chek();

CREATE OR REPLACE PROCEDURE schm_planificacion_comercial.sp_run_chek()
	LANGUAGE plpgsql
AS $$
		
	
BEGIN

    IF EXTRACT(DAY FROM GETDATE()) <= 5
    THEN
        call schm_planificacion_comercial.sp_chek(trunc(schm_artifacts.f_period(current_date)-1));
        call schm_planificacion_comercial.sp_chek(trunc(schm_artifacts.f_period(current_date)));
    ELSE
        call schm_planificacion_comercial.sp_chek(trunc(schm_artifacts.f_period(current_date)));
    END IF;
END


$$
;

