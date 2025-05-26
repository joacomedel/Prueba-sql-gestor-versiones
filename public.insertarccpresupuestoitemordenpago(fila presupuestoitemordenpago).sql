CREATE OR REPLACE FUNCTION public.insertarccpresupuestoitemordenpago(fila presupuestoitemordenpago)
 RETURNS presupuestoitemordenpago
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.presupuestoitemordenpagocc:= current_timestamp;
    UPDATE sincro.presupuestoitemordenpago SET ctopimportepagado= fila.ctopimportepagado, idcentroordenpago= fila.idcentroordenpago, idcentropresupuestoitem= fila.idcentropresupuestoitem, idpresupuestoitem= fila.idpresupuestoitem, nroordenpago= fila.nroordenpago, presupuestoitemordenpagocc= fila.presupuestoitemordenpagocc WHERE ctopimportepagado= fila.ctopimportepagado AND idcentroordenpago= fila.idcentroordenpago AND idcentropresupuestoitem= fila.idcentropresupuestoitem AND idpresupuestoitem= fila.idpresupuestoitem AND nroordenpago= fila.nroordenpago AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.presupuestoitemordenpago(ctopimportepagado, idcentroordenpago, idcentropresupuestoitem, idpresupuestoitem, nroordenpago, presupuestoitemordenpagocc) VALUES (fila.ctopimportepagado, fila.idcentroordenpago, fila.idcentropresupuestoitem, fila.idpresupuestoitem, fila.nroordenpago, fila.presupuestoitemordenpagocc);
    END IF;
    RETURN fila;
    END;
    $function$
