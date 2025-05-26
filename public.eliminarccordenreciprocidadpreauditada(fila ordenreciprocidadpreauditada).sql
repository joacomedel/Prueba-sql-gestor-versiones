CREATE OR REPLACE FUNCTION public.eliminarccordenreciprocidadpreauditada(fila ordenreciprocidadpreauditada)
 RETURNS ordenreciprocidadpreauditada
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenreciprocidadpreauditadacc:= current_timestamp;
    delete from sincro.ordenreciprocidadpreauditada WHERE anio= fila.anio AND centro= fila.centro AND idcomprobantetipos= fila.idcomprobantetipos AND nroorden= fila.nroorden AND nroregistro= fila.nroregistro AND TRUE;
    RETURN fila;
    END;
    $function$
