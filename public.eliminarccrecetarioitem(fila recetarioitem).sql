CREATE OR REPLACE FUNCTION public.eliminarccrecetarioitem(fila recetarioitem)
 RETURNS recetarioitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recetarioitemcc:= current_timestamp;
    delete from sincro.recetarioitem WHERE idrecetarioitem= fila.idrecetarioitem AND idcentrorecetarioitem= fila.idcentrorecetarioitem AND TRUE;
    RETURN fila;
    END;
    $function$
