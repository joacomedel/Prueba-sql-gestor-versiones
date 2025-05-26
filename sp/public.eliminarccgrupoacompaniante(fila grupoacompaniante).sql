CREATE OR REPLACE FUNCTION public.eliminarccgrupoacompaniante(fila grupoacompaniante)
 RETURNS grupoacompaniante
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.grupoacompaniantecc:= current_timestamp;
    delete from sincro.grupoacompaniante WHERE idcentroconsumoturismo= fila.idcentroconsumoturismo AND idconsumoturismo= fila.idconsumoturismo AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
