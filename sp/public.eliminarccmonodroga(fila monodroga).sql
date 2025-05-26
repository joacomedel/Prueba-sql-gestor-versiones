CREATE OR REPLACE FUNCTION public.eliminarccmonodroga(fila monodroga)
 RETURNS monodroga
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.monodrogacc:= current_timestamp;
    delete from sincro.monodroga WHERE idmonodroga= fila.idmonodroga AND TRUE;
    RETURN fila;
    END;
    $function$
