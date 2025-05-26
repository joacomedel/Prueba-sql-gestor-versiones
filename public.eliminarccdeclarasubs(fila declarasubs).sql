CREATE OR REPLACE FUNCTION public.eliminarccdeclarasubs(fila declarasubs)
 RETURNS declarasubs
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.declarasubscc:= current_timestamp;
    delete from sincro.declarasubs WHERE nro= fila.nro AND nrodoctitu= fila.nrodoctitu AND tipodoctitu= fila.tipodoctitu AND TRUE;
    RETURN fila;
    END;
    $function$
