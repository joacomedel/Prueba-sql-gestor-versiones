CREATE OR REPLACE FUNCTION public.insertarccinformefacturacioncobranza(fila informefacturacioncobranza)
 RETURNS informefacturacioncobranza
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.informefacturacioncobranzacc:= current_timestamp;
    UPDATE sincro.informefacturacioncobranza SET fechadesde= fila.fechadesde, fechahasta= fila.fechahasta, idcentroinformefacturacion= fila.idcentroinformefacturacion, idcentropago= fila.idcentropago, idcomprobantecobranzamultivac= fila.idcomprobantecobranzamultivac, idformapagocobranza= fila.idformapagocobranza, idpago= fila.idpago, ifcorigenpago= fila.ifcorigenpago, informefacturacioncobranzacc= fila.informefacturacioncobranzacc, nroinforme= fila.nroinforme WHERE idcentroinformefacturacion= fila.idcentroinformefacturacion AND idformapagocobranza= fila.idformapagocobranza AND idpago= fila.idpago AND nroinforme= fila.nroinforme AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.informefacturacioncobranza(fechadesde, fechahasta, idcentroinformefacturacion, idcentropago, idcomprobantecobranzamultivac, idformapagocobranza, idpago, ifcorigenpago, informefacturacioncobranzacc, nroinforme) VALUES (fila.fechadesde, fila.fechahasta, fila.idcentroinformefacturacion, fila.idcentropago, fila.idcomprobantecobranzamultivac, fila.idformapagocobranza, fila.idpago, fila.ifcorigenpago, fila.informefacturacioncobranzacc, fila.nroinforme);
    END IF;
    RETURN fila;
    END;
    $function$
