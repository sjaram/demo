CALL schm_artifacts.sp_ctbl_contact_seguros('LNEGRO_EMAIL',TO_CHAR(GETDATE(), 'YYYYMMDD'),'select * from schm_data_analytics.ctbl_lnegro_email');
CALL schm_artifacts.sp_ctbl_contact_seguros('NOTCALL',TO_CHAR(GETDATE(), 'YYYYMMDD'),'select * from schm_data_analytics.notcall');
#sftp_redshift_sender('auris_ftp',f'ctbl/contact_seguros/LNEGRO_EMAIL000.csv',f'/AurisFtp/Archivos/BI_CCR_NOT_CALL/LNEGRO_EMAIL.csv',600);
#sftp_redshift_sender('auris_ftp',f'ctbl/contact_seguros/NOTCALL000.csv',f'/AurisFtp/Archivos/BI_CCR_NOT_CALL/NOTCALL.csv',600);