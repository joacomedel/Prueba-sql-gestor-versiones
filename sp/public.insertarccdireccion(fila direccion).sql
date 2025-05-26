CREATE OR REPLACE FUNCTION public.insertarccdireccion(fila direccion)
 RETURNS direccion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.direccioncc:= current_timestamp;
    UPDATE sincro.direccion SET barrio= fila.barrio, calle= fila.calle, direccioncc= fila.direccioncc, dpto= fila.dpto, idcentrodireccion= fila.idcentrodireccion, iddireccion= fila.iddireccion, idlocalidad= fila.idlocalidad, idprovincia= fila.idprovincia, nro= fila.nro, piso= fila.piso, tira= fila.tira WHERE idcentrodireccion= fila.idcentrodireccion AND iddireccion= fila.iddireccion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.direccion(barrio, calle, direccioncc, dpto, idcentrodireccion, iddireccion, idlocalidad, idprovincia, nro, piso, tira) VALUES (fila.barrio, fila.calle, fila.direccioncc, fila.dpto, fila.idcentrodireccion, fila.iddireccion, fila.idlocalidad, fila.idprovincia, fila.nro, fila.piso, fila.tira);
    END IF;
    RETURN fila;
    END;
    $function$
