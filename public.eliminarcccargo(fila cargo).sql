CREATE OR REPLACE FUNCTION public.eliminarcccargo(fila cargo)
 RETURNS cargo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cargocc:= current_timestamp;
    delete from sincro.cargo WHERE idcargo= fila.idcargo AND TRUE;
    RETURN fila;
    END;
    $function$
