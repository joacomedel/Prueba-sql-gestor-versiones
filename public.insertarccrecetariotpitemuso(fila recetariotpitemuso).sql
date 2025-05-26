CREATE OR REPLACE FUNCTION public.insertarccrecetariotpitemuso(fila recetariotpitemuso)
 RETURNS recetariotpitemuso
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recetariotpitemusocc:= current_timestamp;
    UPDATE sincro.recetariotpitemuso SET idcentroordenventa= fila.idcentroordenventa, idcentrorecetariotpitem= fila.idcentrorecetariotpitem, idcentrorecetariotpitemuso= fila.idcentrorecetariotpitemuso, idordenventa= fila.idordenventa, idrecetariotpitem= fila.idrecetariotpitem, idrecetariotpitemuso= fila.idrecetariotpitemuso, recetariotpitemusocc= fila.recetariotpitemusocc, rtpiufechauso= fila.rtpiufechauso WHERE idcentrorecetariotpitemuso= fila.idcentrorecetariotpitemuso AND idrecetariotpitemuso= fila.idrecetariotpitemuso AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.recetariotpitemuso(idcentroordenventa, idcentrorecetariotpitem, idcentrorecetariotpitemuso, idordenventa, idrecetariotpitem, idrecetariotpitemuso, recetariotpitemusocc, rtpiufechauso) VALUES (fila.idcentroordenventa, fila.idcentrorecetariotpitem, fila.idcentrorecetariotpitemuso, fila.idordenventa, fila.idrecetariotpitem, fila.idrecetariotpitemuso, fila.recetariotpitemusocc, fila.rtpiufechauso);
    END IF;
    RETURN fila;
    END;
    $function$
