#redshift_to_datalake('schm_data_analytics','ppff_trx_sav','select * from schm_data_analytics.ppff_trx_sav where periodo = 202301',partition_col='periodo')