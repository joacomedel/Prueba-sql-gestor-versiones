CREATE OR REPLACE FUNCTION public.insertarccmultidro(fila multidro)
 RETURNS multidro
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.multidrocc:= current_timestamp;
    UPDATE sincro.multidro SET idnuevadro= fila.idnuevadro, mnroregistro= fila.mnroregistro, multidrocc= fila.multidrocc, nomenclado= fila.nomenclado WHERE idnuevadro= fila.idnuevadro AND mnroregistro= fila.mnroregistro AND nomenclado= fila.nomenclado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.multidro(idnuevadro, mnroregistro, multidrocc, nomenclado) VALUES (fila.idnuevadro, fila.mnroregistro, fila.multidrocc, fila.nomenclado);
    END IF;
    RETURN fila;
    END;
    $function$
