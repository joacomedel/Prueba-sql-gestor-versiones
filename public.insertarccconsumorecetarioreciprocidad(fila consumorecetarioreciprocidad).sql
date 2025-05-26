CREATE OR REPLACE FUNCTION public.insertarccconsumorecetarioreciprocidad(fila consumorecetarioreciprocidad)
 RETURNS consumorecetarioreciprocidad
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.consumorecetarioreciprocidadcc:= current_timestamp;
    UPDATE sincro.consumorecetarioreciprocidad SET abreviatura= fila.abreviatura, centro= fila.centro, consumorecetarioreciprocidadcc= fila.consumorecetarioreciprocidadcc, debito= fila.debito, importe= fila.importe, importeapagar= fila.importeapagar, nrorecetario= fila.nrorecetario, tipocomprobante= fila.tipocomprobante, tipocuenta= fila.tipocuenta WHERE TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.consumorecetarioreciprocidad(abreviatura, centro, consumorecetarioreciprocidadcc, debito, importe, importeapagar, nrorecetario, tipocomprobante, tipocuenta) VALUES (fila.abreviatura, fila.centro, fila.consumorecetarioreciprocidadcc, fila.debito, fila.importe, fila.importeapagar, fila.nrorecetario, fila.tipocomprobante, fila.tipocuenta);
    END IF;
    RETURN fila;
    END;
    $function$
