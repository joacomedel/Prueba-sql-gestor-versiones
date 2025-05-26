CREATE OR REPLACE FUNCTION public.insertarccrecetariotpitem(fila recetariotpitem)
 RETURNS recetariotpitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recetariotpitemcc:= current_timestamp;
    UPDATE sincro.recetariotpitem SET centro= fila.centro, idcentrorecetariotpitem= fila.idcentrorecetariotpitem, idcentrorecetariotpitempadre= fila.idcentrorecetariotpitempadre, idcentrovalidacionitem= fila.idcentrovalidacionitem, idrecetarioitempadre= fila.idrecetarioitempadre, idrecetariotpitem= fila.idrecetariotpitem, idvalidacionitem= fila.idvalidacionitem, mnroregistro= fila.mnroregistro, nomenclado= fila.nomenclado, nrorecetario= fila.nrorecetario, recetariotpitemcc= fila.recetariotpitemcc, rtpicantidadauditada= fila.rtpicantidadauditada, rtpipcobertura= fila.rtpipcobertura WHERE idcentrorecetariotpitem= fila.idcentrorecetariotpitem AND idrecetariotpitem= fila.idrecetariotpitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.recetariotpitem(centro, idcentrorecetariotpitem, idcentrorecetariotpitempadre, idcentrovalidacionitem, idrecetarioitempadre, idrecetariotpitem, idvalidacionitem, mnroregistro, nomenclado, nrorecetario, recetariotpitemcc, rtpicantidadauditada, rtpipcobertura) VALUES (fila.centro, fila.idcentrorecetariotpitem, fila.idcentrorecetariotpitempadre, fila.idcentrovalidacionitem, fila.idrecetarioitempadre, fila.idrecetariotpitem, fila.idvalidacionitem, fila.mnroregistro, fila.nomenclado, fila.nrorecetario, fila.recetariotpitemcc, fila.rtpicantidadauditada, fila.rtpipcobertura);
    END IF;
    RETURN fila;
    END;
    $function$
