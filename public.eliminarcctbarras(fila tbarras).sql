CREATE OR REPLACE FUNCTION public.eliminarcctbarras(fila tbarras)
 RETURNS tbarras
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.tbarrascc:= current_timestamp;
    delete from sincro.tbarras WHERE nrodoctitu= fila.nrodoctitu AND tipodoctitu= fila.tipodoctitu AND TRUE;
    RETURN fila;
    END;
    $function$
