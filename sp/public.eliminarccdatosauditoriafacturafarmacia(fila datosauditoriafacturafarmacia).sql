CREATE OR REPLACE FUNCTION public.eliminarccdatosauditoriafacturafarmacia(fila datosauditoriafacturafarmacia)
 RETURNS datosauditoriafacturafarmacia
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.datosauditoriafacturafarmaciacc:= current_timestamp;
    delete from sincro.datosauditoriafacturafarmacia WHERE idauditoriafactura= fila.idauditoriafactura AND TRUE;
    RETURN fila;
    END;
    $function$
