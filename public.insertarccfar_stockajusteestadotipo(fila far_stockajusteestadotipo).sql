CREATE OR REPLACE FUNCTION public.insertarccfar_stockajusteestadotipo(fila far_stockajusteestadotipo)
 RETURNS far_stockajusteestadotipo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_stockajusteestadotipocc:= current_timestamp;
    UPDATE sincro.far_stockajusteestadotipo SET far_stockajusteestadotipocc= fila.far_stockajusteestadotipocc, idstockajusteestadotipo= fila.idstockajusteestadotipo, saetdescripcion= fila.saetdescripcion WHERE idstockajusteestadotipo= fila.idstockajusteestadotipo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_stockajusteestadotipo(far_stockajusteestadotipocc, idstockajusteestadotipo, saetdescripcion) VALUES (fila.far_stockajusteestadotipocc, fila.idstockajusteestadotipo, fila.saetdescripcion);
    END IF;
    RETURN fila;
    END;
    $function$
