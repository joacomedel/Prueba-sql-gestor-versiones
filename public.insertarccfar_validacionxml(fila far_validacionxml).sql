CREATE OR REPLACE FUNCTION public.insertarccfar_validacionxml(fila far_validacionxml)
 RETURNS far_validacionxml
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_validacionxmlcc:= current_timestamp;
    UPDATE sincro.far_validacionxml SET far_validacionxmlcc= fila.far_validacionxmlcc, idadesfaprocesotipo= fila.idadesfaprocesotipo, idcentrovalidacionxml= fila.idcentrovalidacionxml, idvalidacionxml= fila.idvalidacionxml, vcadenaxml= fila.vcadenaxml, vfecha= fila.vfecha WHERE idcentrovalidacionxml= fila.idcentrovalidacionxml AND idvalidacionxml= fila.idvalidacionxml AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_validacionxml(far_validacionxmlcc, idadesfaprocesotipo, idcentrovalidacionxml, idvalidacionxml, vcadenaxml, vfecha) VALUES (fila.far_validacionxmlcc, fila.idadesfaprocesotipo, fila.idcentrovalidacionxml, fila.idvalidacionxml, fila.vcadenaxml, fila.vfecha);
    END IF;
    RETURN fila;
    END;
    $function$
