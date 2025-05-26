CREATE OR REPLACE FUNCTION public.eliminarccmedicamentoacomprar(fila medicamentoacomprar)
 RETURNS medicamentoacomprar
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.medicamentoacomprarcc:= current_timestamp;
    delete from sincro.medicamentoacomprar WHERE idcentromedicamentoacomprar= fila.idcentromedicamentoacomprar AND idmedicamentoacomprar= fila.idmedicamentoacomprar AND TRUE;
    RETURN fila;
    END;
    $function$
