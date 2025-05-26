CREATE OR REPLACE FUNCTION public.eliminarccpresupuestoitemordenpago(fila presupuestoitemordenpago)
 RETURNS presupuestoitemordenpago
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.presupuestoitemordenpagocc:= current_timestamp;
    delete from sincro.presupuestoitemordenpago WHERE ctopimportepagado= fila.ctopimportepagado AND idcentroordenpago= fila.idcentroordenpago AND idcentropresupuestoitem= fila.idcentropresupuestoitem AND idpresupuestoitem= fila.idpresupuestoitem AND nroordenpago= fila.nroordenpago AND TRUE;
    RETURN fila;
    END;
    $function$
