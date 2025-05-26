CREATE OR REPLACE FUNCTION public.eliminarccrecetariotpitem(fila recetariotpitem)
 RETURNS recetariotpitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recetariotpitemcc:= current_timestamp;
    delete from sincro.recetariotpitem WHERE idcentrorecetariotpitem= fila.idcentrorecetariotpitem AND idrecetariotpitem= fila.idrecetariotpitem AND TRUE;
    RETURN fila;
    END;
    $function$
