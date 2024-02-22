DROP PROCEDURE schm_artifacts.blueprint(v_fecha_inicio date, v_fecha_fin date, v_periodo int);





CREATE OR REPLACE PROCEDURE schm_artifacts.blueprint(v_fecha_inicio date, v_fecha_fin date, v_periodo int)
AS $$
BEGIN

    DROP TABLE IF EXISTS schm_workspace.category_stage;
    DROP TABLE IF EXISTS schm_workspace.category_stage;

    create table schm_workspace.category_stage(
        catid smallint default 0,
        catgroup varchar(10) default 'General',
        catname varchar(10) default 'General',
        catdesc varchar(50) default 'General'
    );

    insert into schm_workspace.category_stage values
    (default, default, default, default),
    (20, default, 'Country', default),
    (21, 'Concerts', 'Rock', default);

-- ---------------------------
-- Tabla Final
-- ---------------------------
    create table schm_arquitectura.category_stage as select * from schm_workspace.category_stage;

    DROP TABLE IF EXISTS schm_workspace.category_stage;
    DROP TABLE IF EXISTS schm_workspace.category_stage;

END;
$$ LANGUAGE plpgsql;
