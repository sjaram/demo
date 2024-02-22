CALL schm_productos_financieros.sp_ppff_base_planes_nps('base_planes_nps',TO_CHAR(GETDATE(), 'YYYYMMDD'),'select * from schm_productos_financieros.ppff_base_planes_nps');
#sftp_redshift_sender('ctrl_comercial_ftp',f'ppff/base_planes_nps/base_planes_nps_{get_period()}.csv',f'/base_planes_nps_{get_period()}.csv',600);
