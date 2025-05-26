CREATE OR REPLACE FUNCTION public.eliminarccctasctesmontosdescuento(fila ctasctesmontosdescuento)
 RETURNS ctasctesmontosdescuento
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ctasctesmontosdescuentocc:= current_timestamp;
    delete from sincro.ctasctesmontosdescuento WHERE idctasctesmontosdescuento= fila.idctasctesmontosdescuento AND idcentroctasctesmontosdescuento= fila.idcentroctasctesmontosdescuento AND TRUE;
    RETURN fila;
    END;
    $function$
