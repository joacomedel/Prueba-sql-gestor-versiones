CREATE OR REPLACE FUNCTION public.insertarccconsumo(fila consumo)
 RETURNS consumo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.consumocc:= current_timestamp;
    UPDATE sincro.consumo SET anulado= fila.anulado, centro= fila.centro, consumocc= fila.consumocc, idconsumo= fila.idconsumo, nrodoc= fila.nrodoc, nroorden= fila.nroorden, tipodoc= fila.tipodoc WHERE centro= fila.centro AND idconsumo= fila.idconsumo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.consumo(anulado, centro, consumocc, idconsumo, nrodoc, nroorden, tipodoc) VALUES (fila.anulado, fila.centro, fila.consumocc, fila.idconsumo, fila.nrodoc, fila.nroorden, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
