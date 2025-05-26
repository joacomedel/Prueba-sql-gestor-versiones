CREATE OR REPLACE FUNCTION public.eliminarcccmitem(fila cmitem)
 RETURNS cmitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cmitemcc:= current_timestamp;
    delete from sincro.cmitem WHERE idcmitem= fila.idcmitem AND TRUE;
    RETURN fila;
    END;
    $function$
