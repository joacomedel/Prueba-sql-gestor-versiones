CREATE OR REPLACE FUNCTION public.insertarcctipocliente(fila tipocliente)
 RETURNS tipocliente
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.tipoclientecc:= current_timestamp;
    UPDATE sincro.tipocliente SET descripcioncliente= fila.descripcioncliente, idtipocliente= fila.idtipocliente, tipoclientecc= fila.tipoclientecc WHERE idtipocliente= fila.idtipocliente AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.tipocliente(descripcioncliente, idtipocliente, tipoclientecc) VALUES (fila.descripcioncliente, fila.idtipocliente, fila.tipoclientecc);
    END IF;
    RETURN fila;
    END;
    $function$
