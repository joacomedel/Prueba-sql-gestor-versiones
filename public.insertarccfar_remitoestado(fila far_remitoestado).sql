CREATE OR REPLACE FUNCTION public.insertarccfar_remitoestado(fila far_remitoestado)
 RETURNS far_remitoestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_remitoestadocc:= current_timestamp;
    UPDATE sincro.far_remitoestado SET centro= fila.centro, centrocambioestado= fila.centrocambioestado, far_remitoestadocc= fila.far_remitoestadocc, idremito= fila.idremito, idremitoestado= fila.idremitoestado, idremitoestadotipo= fila.idremitoestadotipo, remitofechafin= fila.remitofechafin, remitofechaini= fila.remitofechaini WHERE centrocambioestado= fila.centrocambioestado AND idremitoestado= fila.idremitoestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_remitoestado(centro, centrocambioestado, far_remitoestadocc, idremito, idremitoestado, idremitoestadotipo, remitofechafin, remitofechaini) VALUES (fila.centro, fila.centrocambioestado, fila.far_remitoestadocc, fila.idremito, fila.idremitoestado, fila.idremitoestadotipo, fila.remitofechafin, fila.remitofechaini);
    END IF;
    RETURN fila;
    END;
    $function$
