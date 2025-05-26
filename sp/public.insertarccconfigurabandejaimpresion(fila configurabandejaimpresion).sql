CREATE OR REPLACE FUNCTION public.insertarccconfigurabandejaimpresion(fila configurabandejaimpresion)
 RETURNS configurabandejaimpresion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.configurabandejaimpresioncc:= current_timestamp;
    UPDATE sincro.configurabandejaimpresion SET bicantidadmaxima= fila.bicantidadmaxima, idbandejaimpresion= fila.idbandejaimpresion, bicantidad= fila.bicantidad, biip= fila.biip, binombre= fila.binombre, configurabandejaimpresioncc= fila.configurabandejaimpresioncc WHERE idbandejaimpresion= fila.idbandejaimpresion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.configurabandejaimpresion(bicantidadmaxima, idbandejaimpresion, bicantidad, biip, binombre, configurabandejaimpresioncc) VALUES (fila.bicantidadmaxima, fila.idbandejaimpresion, fila.bicantidad, fila.biip, fila.binombre, fila.configurabandejaimpresioncc);
    END IF;
    RETURN fila;
    END;
    $function$
