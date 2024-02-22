call schm_artifacts.sp_run_dgtl_logueos_internet();
call schm_digital.sp_dgtl_reporte_captacion();
#redshift_to_datalake('schm_data_analytics','dgtl_logueos_internet',query=f'select * from schm_data_analytics.dgtl_logueos_internet where periodo = {get_only_period()[:6]}',partition_col='periodo',team='seguros',overwrite='false',max_capacity=4)