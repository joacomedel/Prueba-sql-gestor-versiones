CREATE OR REPLACE FUNCTION public.insertarccdatosauditoriafacturafarmacia(fila datosauditoriafacturafarmacia)
 RETURNS datosauditoriafacturafarmacia
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.datosauditoriafacturafarmaciacc:= current_timestamp;
    UPDATE sincro.datosauditoriafacturafarmacia SET anio= fila.anio, datosauditoriafacturafarmaciacc= fila.datosauditoriafacturafarmaciacc, fechaauditoria= fila.fechaauditoria, idauditoriafactura= fila.idauditoriafactura, nroregistro= fila.nroregistro WHERE idauditoriafactura= fila.idauditoriafactura AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.datosauditoriafacturafarmacia(anio, datosauditoriafacturafarmaciacc, fechaauditoria, idauditoriafactura, nroregistro) VALUES (fila.anio, fila.datosauditoriafacturafarmaciacc, fila.fechaauditoria, fila.idauditoriafactura, fila.nroregistro);
    END IF;
    RETURN fila;
    END;
    $function$
