CREATE OR REPLACE FUNCTION public.eliminarccprorroga(fila prorroga)
 RETURNS prorroga
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.prorrogacc:= current_timestamp;
    delete from sincro.prorroga WHERE idcentroregional= fila.idcentroregional AND idprorr= fila.idprorr AND TRUE;
    RETURN fila;
    END;
    $function$
