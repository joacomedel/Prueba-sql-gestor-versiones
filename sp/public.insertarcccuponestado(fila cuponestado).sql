CREATE OR REPLACE FUNCTION public.insertarcccuponestado(fila cuponestado)
 RETURNS cuponestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuponestadocc:= current_timestamp;
    UPDATE sincro.cuponestado SET cefechafin= fila.cefechafin, cefechaini= fila.cefechaini, cuponestadocc= fila.cuponestadocc, idcentrocupon= fila.idcentrocupon, idcentrocuponestado= fila.idcentrocuponestado, idcetcambioestado= fila.idcetcambioestado, idcupon= fila.idcupon, idestadotipo= fila.idestadotipo WHERE idcentrocupon= fila.idcentrocupon AND idcentrocuponestado= fila.idcentrocuponestado AND idcetcambioestado= fila.idcetcambioestado AND idcupon= fila.idcupon AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.cuponestado(cefechafin, cefechaini, cuponestadocc, idcentrocupon, idcentrocuponestado, idcetcambioestado, idcupon, idestadotipo) VALUES (fila.cefechafin, fila.cefechaini, fila.cuponestadocc, fila.idcentrocupon, fila.idcentrocuponestado, fila.idcetcambioestado, fila.idcupon, fila.idestadotipo);
    END IF;
    RETURN fila;
    END;
    $function$
