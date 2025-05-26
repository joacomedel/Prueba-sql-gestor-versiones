CREATE OR REPLACE FUNCTION public.insertarccgrupoacompaniantereferencia(fila grupoacompaniantereferencia)
 RETURNS grupoacompaniantereferencia
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.grupoacompaniantereferenciacc:= current_timestamp;
    UPDATE sincro.grupoacompaniantereferencia SET garactivo= fila.garactivo, garapellido= fila.garapellido, garcorreo= fila.garcorreo, garfechacnac= fila.garfechacnac, garinvitado= fila.garinvitado, garnombres= fila.garnombres, gartelefonocontacto= fila.gartelefonocontacto, grupoacompaniantereferenciacc= fila.grupoacompaniantereferenciacc, idvinculo= fila.idvinculo, nrodoc= fila.nrodoc, nrodoctitular= fila.nrodoctitular, tipodoc= fila.tipodoc, tipodoctitular= fila.tipodoctitular WHERE nrodoctitular= fila.nrodoctitular AND tipodoctitular= fila.tipodoctitular AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.grupoacompaniantereferencia(garactivo, garapellido, garcorreo, garfechacnac, garinvitado, garnombres, gartelefonocontacto, grupoacompaniantereferenciacc, idvinculo, nrodoc, nrodoctitular, tipodoc, tipodoctitular) VALUES (fila.garactivo, fila.garapellido, fila.garcorreo, fila.garfechacnac, fila.garinvitado, fila.garnombres, fila.gartelefonocontacto, fila.grupoacompaniantereferenciacc, fila.idvinculo, fila.nrodoc, fila.nrodoctitular, fila.tipodoc, fila.tipodoctitular);
    END IF;
    RETURN fila;
    END;
    $function$
