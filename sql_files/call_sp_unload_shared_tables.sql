-- schm_data_analytics.notcall
UNLOAD('SELECT cast(rut as int), cast(fono as int), cast(tipo_inhibicion as varchar), cast(canal_reclamo as varchar), cast(area as int), cast(fecha_solicitud as date) FROM schm_data_analytics.notcall')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/notcall/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;


-- schm_data_analytics.lnegro_sms
UNLOAD('select cast(rut as int), cast(fono as int), cast(tipo_inhibicion as varchar), cast(canal_reclamo as varchar), cast(fecha_ingreso as date) from schm_data_analytics.ctbl_lnegro_sms')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/lnegro_sms/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;

-- schm_data_analytics.lnegro_email;
UNLOAD('select cast(rut as int), cast(email as varchar), cast(motivo as varchar), cast(fecha_inhibicion as date) from schm_data_analytics.ctbl_lnegro_email')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/lnegro_email/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;


-- schm_data_analytics.lnegro_car
UNLOAD('select cast(rut as bigint), cast(tipo_inhibicion as varchar), cast(canal_reclamo as varchar),cast(fecha_ingreso as date) from schm_data_analytics.ctbl_lnegro_car')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/lnegro_car/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;

-- schm_data_analytics.lnegro_call
UNLOAD('select cast(rut as int),cast(area as int),cast(fono as int),cast(tipo_inhibicion as varchar),cast(canal_reclamo as varchar) ,cast(fecha_ingreso as date) from schm_data_analytics.ctbl_lnegro_call')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/lnegro_call/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;


-- dgtl_logueos_internet
UNLOAD('SELECT cast(rut as integer), cast(fecha as date), cast(fecha_logueo as date) date, tipo_logueo as string, dispositivo as string, cast(periodo as integer) FROM schm_data_analytics.dgtl_logueos_internet')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/dgtl_logueos_internet/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;

-- schm_data_analytics.tnda_sucursal_preferente
UNLOAD('select * from schm_data_analytics.tnda_sucursal_preferente')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/tnda_sucursal_preferente/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;


-- schm_data_analytics.mdpg_contratos_itf_riesgo
UNLOAD('select * from schm_data_analytics.mdpg_contratos_itf_riesgo')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/mdpg_contratos_itf_riesgo/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;

--schm_data_analytics.mdpg_contratos_itf
UNLOAD('select * from schm_data_analytics.mdpg_contratos_itf')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/mdpg_contratos_itf/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;


-- schm_data_analytics.ctbl_fonos_movil_final
UNLOAD('select * from schm_data_analytics.ctbl_fonos_movil_final')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/ctbl_fonos_movil_final/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;


-- schm_data_analytics.ctbl_direcciones
UNLOAD('select * from schm_data_analytics.ctbl_direcciones')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/ctbl_direcciones/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;

-- schm_data_analytics.ctbl_demo_basket
UNLOAD('select * from schm_data_analytics.ctbl_demo_basket')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/ctbl_demo_basket/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;

-- schm_data_analytics.ctbl_base_trabajo_email
UNLOAD('select rut::int ,email ,aperturas ,nota ,ori_canal ,inicio_correo ,dominio ,fecha from schm_data_analytics.ctbl_base_trabajo_email')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/ctbl_base_trabajo_email/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;

-- schm_data_analytics.ctbl_base_nombres
UNLOAD('select * from schm_data_analytics.ctbl_base_nombres')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/ctbl_base_nombres/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;

-- schm_data_analytics.bitr_maestra_sucursales
UNLOAD('select * from schm_data_analytics.bitr_maestra_sucursales')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/bitr_maestra_sucursales/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;

-- schm_data_analytics.bitr_actividad_tr
UNLOAD('select * from schm_data_analytics.bitr_actividad_tr')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/bitr_actividad_tr/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;


-- schm_data_analytics.bitr_actividad_tr
UNLOAD('select * from schm_data_analytics.ctbl_fonos_movil_final')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/ctbl_fonos_movil_final/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;

-- schm_data_analytics.bitr_actividad_tr
UNLOAD('select * from schm_data_analytics.mdpg_uso_tr_marca')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/mdpg_uso_tr_marca/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;


UNLOAD('SELECT * FROM schm_data_analytics.ppff_trx_sav')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/ppff_trx_sav/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;

UNLOAD('SELECT * FROM schm_data_analytics.ppff_trx_av')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/ppff_trx_av/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;


UNLOAD('SELECT * FROM schm_data_analytics.ppff_trx_consumo')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/ppff_trx_consumo/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;

UNLOAD('SELECT cast(rut as integer), cast(fecha as date), cast(fecha_logueo as date) date, tipo_logueo as string, dispositivo as string, cast(periodo as integer) FROM schm_data_analytics.dgtl_logueos_internet')
to 's3://br-dm-prod-us-east-1-837538682169-analytics/data_analytics_rds/dgtl_logueos_internet/'
iam_role 'arn:aws:iam::837538682169:role/ROLE-BR-PROD-DATA-MANAGEMENT-DATACATALOG-REDSHIFT'
format parquet ALLOWOVERWRITE;

