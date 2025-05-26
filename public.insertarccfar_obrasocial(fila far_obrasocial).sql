CREATE OR REPLACE FUNCTION public.insertarccfar_obrasocial(fila far_obrasocial)
 RETURNS far_obrasocial
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_obrasocialcc:= current_timestamp;
    UPDATE sincro.far_obrasocial SET far_obrasocialcc= fila.far_obrasocialcc, idobrasocial= fila.idobrasocial, nrocuentac= fila.nrocuentac, osactivo= fila.osactivo, oscuit= fila.oscuit, osdescripcion= fila.osdescripcion, osdiasvigenciareceta= fila.osdiasvigenciareceta, osnombrecompleto= fila.osnombrecompleto, osrnos= fila.osrnos, ostipo= fila.ostipo WHERE idobrasocial= fila.idobrasocial AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_obrasocial(far_obrasocialcc, idobrasocial, nrocuentac, osactivo, oscuit, osdescripcion, osdiasvigenciareceta, osnombrecompleto, osrnos, ostipo) VALUES (fila.far_obrasocialcc, fila.idobrasocial, fila.nrocuentac, fila.osactivo, fila.oscuit, fila.osdescripcion, fila.osdiasvigenciareceta, fila.osnombrecompleto, fila.osrnos, fila.ostipo);
    END IF;
    RETURN fila;
    END;
    $function$
