CREATE OR REPLACE FUNCTION public.eliminarccafiliactipodoc(fila afiliactipodoc)
 RETURNS afiliactipodoc
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afiliactipodoccc:= current_timestamp;
    delete from sincro.afiliactipodoc WHERE iddocafil= fila.iddocafil AND idrecepcion= fila.idrecepcion AND TRUE;
    RETURN fila;
    END;
    $function$
