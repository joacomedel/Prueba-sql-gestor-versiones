CREATE OR REPLACE FUNCTION public.insertarccfar_configura_reporte(fila far_configura_reporte)
 RETURNS far_configura_reporte
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_configura_reportecc:= current_timestamp;
    UPDATE sincro.far_configura_reporte SET crseparavalidacion= fila.crseparavalidacion, far_configura_reportecc= fila.far_configura_reportecc, idobrasocial= fila.idobrasocial, idtiporeporte= fila.idtiporeporte, idvalorcajacoseguro= fila.idvalorcajacoseguro, idvalorcajactacte= fila.idvalorcajactacte WHERE crseparavalidacion= fila.crseparavalidacion AND idobrasocial= fila.idobrasocial AND idtiporeporte= fila.idtiporeporte AND idvalorcajacoseguro= fila.idvalorcajacoseguro AND idvalorcajactacte= fila.idvalorcajactacte AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_configura_reporte(crseparavalidacion, far_configura_reportecc, idobrasocial, idtiporeporte, idvalorcajacoseguro, idvalorcajactacte) VALUES (fila.crseparavalidacion, fila.far_configura_reportecc, fila.idobrasocial, fila.idtiporeporte, fila.idvalorcajacoseguro, fila.idvalorcajactacte);
    END IF;
    RETURN fila;
    END;
    $function$
