CREATE OR REPLACE FUNCTION public.insertarccmedicamentoacomprar(fila medicamentoacomprar)
 RETURNS medicamentoacomprar
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.medicamentoacomprarcc:= current_timestamp;
    UPDATE sincro.medicamentoacomprar SET idcentromedicamentoacomprar= fila.idcentromedicamentoacomprar, idmedicamentoacomprar= fila.idmedicamentoacomprar, maccantidad= fila.maccantidad, macfechaingreso= fila.macfechaingreso, medicamentoacomprarcc= fila.medicamentoacomprarcc, mnroregistro= fila.mnroregistro WHERE idcentromedicamentoacomprar= fila.idcentromedicamentoacomprar AND idmedicamentoacomprar= fila.idmedicamentoacomprar AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.medicamentoacomprar(idcentromedicamentoacomprar, idmedicamentoacomprar, maccantidad, macfechaingreso, medicamentoacomprarcc, mnroregistro) VALUES (fila.idcentromedicamentoacomprar, fila.idmedicamentoacomprar, fila.maccantidad, fila.macfechaingreso, fila.medicamentoacomprarcc, fila.mnroregistro);
    END IF;
    RETURN fila;
    END;
    $function$
