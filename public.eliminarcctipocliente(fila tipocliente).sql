CREATE OR REPLACE FUNCTION public.eliminarcctipocliente(fila tipocliente)
 RETURNS tipocliente
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.tipoclientecc:= current_timestamp;
    delete from sincro.tipocliente WHERE idtipocliente= fila.idtipocliente AND TRUE;
    RETURN fila;
    END;
    $function$
