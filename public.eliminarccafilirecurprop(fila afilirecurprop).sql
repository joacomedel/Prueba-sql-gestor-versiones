CREATE OR REPLACE FUNCTION public.eliminarccafilirecurprop(fila afilirecurprop)
 RETURNS afilirecurprop
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afilirecurpropcc:= current_timestamp;
    delete from sincro.afilirecurprop WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
