#redshift_to_datalake('schm_data_analytics','dgtl_logueos_internet',query='select * from schm_data_analytics.dgtl_logueos_internet where periodo = 202401',partition_col='periodo',team='seguros',overwrite='false',max_capacity=6,max_execution=7200)