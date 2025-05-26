CREATE OR REPLACE FUNCTION public.insertarccmanextra(fila manextra)
 RETURNS manextra
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.manextracc:= current_timestamp;
    UPDATE sincro.manextra SET idacciofar= fila.idacciofar, idfarmtipounid= fila.idfarmtipounid, idformas= fila.idformas, idmonodroga= fila.idmonodroga, idtamanos= fila.idtamanos, idupotenci= fila.idupotenci, idvias= fila.idvias, manextracc= fila.manextracc, mepotencia= fila.mepotencia, mnroregistro= fila.mnroregistro, nomenclado= fila.nomenclado WHERE mnroregistro= fila.mnroregistro AND nomenclado= fila.nomenclado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.manextra(idacciofar, idfarmtipounid, idformas, idmonodroga, idtamanos, idupotenci, idvias, manextracc, mepotencia, mnroregistro, nomenclado) VALUES (fila.idacciofar, fila.idfarmtipounid, fila.idformas, fila.idmonodroga, fila.idtamanos, fila.idupotenci, fila.idvias, fila.manextracc, fila.mepotencia, fila.mnroregistro, fila.nomenclado);
    END IF;
    RETURN fila;
    END;
    $function$
