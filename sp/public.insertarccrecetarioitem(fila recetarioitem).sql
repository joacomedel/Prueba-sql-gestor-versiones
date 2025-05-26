CREATE OR REPLACE FUNCTION public.insertarccrecetarioitem(fila recetarioitem)
 RETURNS recetarioitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recetarioitemcc:= current_timestamp;
    UPDATE sincro.recetarioitem SET idmotivodebito= fila.idmotivodebito, coberturaporplan= fila.coberturaporplan, nomenclado= fila.nomenclado, nrorecetario= fila.nrorecetario, ridebito= fila.ridebito, importe= fila.importe, idrecetarioitem= fila.idrecetarioitem, importeapagar= fila.importeapagar, coberturaefectiva= fila.coberturaefectiva, centro= fila.centro, importevigente= fila.importevigente, idcentrorecetarioitem= fila.idcentrorecetarioitem, recetarioitemcc= fila.recetarioitemcc, mnroregistro= fila.mnroregistro WHERE idrecetarioitem= fila.idrecetarioitem AND idcentrorecetarioitem= fila.idcentrorecetarioitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.recetarioitem(idmotivodebito, coberturaporplan, nomenclado, nrorecetario, ridebito, importe, idrecetarioitem, importeapagar, coberturaefectiva, centro, importevigente, idcentrorecetarioitem, recetarioitemcc, mnroregistro) VALUES (fila.idmotivodebito, fila.coberturaporplan, fila.nomenclado, fila.nrorecetario, fila.ridebito, fila.importe, fila.idrecetarioitem, fila.importeapagar, fila.coberturaefectiva, fila.centro, fila.importevigente, fila.idcentrorecetarioitem, fila.recetarioitemcc, fila.mnroregistro);
    END IF;
    RETURN fila;
    END;
    $function$
