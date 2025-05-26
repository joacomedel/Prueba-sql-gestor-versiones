CREATE OR REPLACE FUNCTION public.insertarccmutualpadronestado(fila mutualpadronestado)
 RETURNS mutualpadronestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.mutualpadronestadocc:= current_timestamp;
    UPDATE sincro.mutualpadronestado SET idmutualpadron= fila.idmutualpadron, mpefechaini= fila.mpefechaini, mpefechafin= fila.mpefechafin, mutualpadronestadocc= fila.mutualpadronestadocc, idmutualpadronestadotipo= fila.idmutualpadronestadotipo, idcentromutualpadron= fila.idcentromutualpadron, idmutualpadronestado= fila.idmutualpadronestado, idcentromutualpadronestado= fila.idcentromutualpadronestado WHERE idcentromutualpadronestado= fila.idcentromutualpadronestado AND idmutualpadronestado= fila.idmutualpadronestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.mutualpadronestado(idmutualpadron, mpefechaini, mpefechafin, mutualpadronestadocc, idmutualpadronestadotipo, idcentromutualpadron, idmutualpadronestado, idcentromutualpadronestado) VALUES (fila.idmutualpadron, fila.mpefechaini, fila.mpefechafin, fila.mutualpadronestadocc, fila.idmutualpadronestadotipo, fila.idcentromutualpadron, fila.idmutualpadronestado, fila.idcentromutualpadronestado);
    END IF;
    RETURN fila;
    END;
    $function$
