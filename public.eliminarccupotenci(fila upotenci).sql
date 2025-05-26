CREATE OR REPLACE FUNCTION public.eliminarccupotenci(fila upotenci)
 RETURNS upotenci
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.upotencicc:= current_timestamp;
    delete from sincro.upotenci WHERE idupotenci= fila.idupotenci AND TRUE;
    RETURN fila;
    END;
    $function$
