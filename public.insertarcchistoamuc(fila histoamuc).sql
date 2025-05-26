CREATE OR REPLACE FUNCTION public.insertarcchistoamuc(fila histoamuc)
 RETURNS histoamuc
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.histoamuccc:= current_timestamp;
    UPDATE sincro.histoamuc SET nrodoc= fila.nrodoc, mutu= fila.mutu, histoamuccc= fila.histoamuccc, tipodoc= fila.tipodoc, fechafin= fila.fechafin, idhistoamuc= fila.idhistoamuc, fechaini= fila.fechaini WHERE fechaini= fila.fechaini AND idhistoamuc= fila.idhistoamuc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.histoamuc(nrodoc, mutu, histoamuccc, tipodoc, fechafin, idhistoamuc, fechaini) VALUES (fila.nrodoc, fila.mutu, fila.histoamuccc, fila.tipodoc, fila.fechafin, fila.idhistoamuc, fila.fechaini);
    END IF;
    RETURN fila;
    END;
    $function$
