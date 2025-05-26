CREATE OR REPLACE FUNCTION public.eliminarccrecetariotpitemuso(fila recetariotpitemuso)
 RETURNS recetariotpitemuso
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recetariotpitemusocc:= current_timestamp;
    delete from sincro.recetariotpitemuso WHERE idcentrorecetariotpitemuso= fila.idcentrorecetariotpitemuso AND idrecetariotpitemuso= fila.idrecetariotpitemuso AND TRUE;
    RETURN fila;
    END;
    $function$
