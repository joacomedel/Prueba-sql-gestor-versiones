CREATE OR REPLACE FUNCTION public.insertarccmonodroga(fila monodroga)
 RETURNS monodroga
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.monodrogacc:= current_timestamp;
    UPDATE sincro.monodroga SET idmonodroga= fila.idmonodroga, monnombre= fila.monnombre, monodrogacc= fila.monodrogacc WHERE idmonodroga= fila.idmonodroga AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.monodroga(idmonodroga, monnombre, monodrogacc) VALUES (fila.idmonodroga, fila.monnombre, fila.monodrogacc);
    END IF;
    RETURN fila;
    END;
    $function$
