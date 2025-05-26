CREATE OR REPLACE FUNCTION public.insertarccitem(fila item)
 RETURNS item
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.itemcc:= current_timestamp;
    UPDATE sincro.item SET cantidad= fila.cantidad, centro= fila.centro, cobertura= fila.cobertura, idcapitulo= fila.idcapitulo, iditem= fila.iditem, idnomenclador= fila.idnomenclador, idpractica= fila.idpractica, idsubcapitulo= fila.idsubcapitulo, importe= fila.importe, itemcc= fila.itemcc WHERE centro= fila.centro AND iditem= fila.iditem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.item(cantidad, centro, cobertura, idcapitulo, iditem, idnomenclador, idpractica, idsubcapitulo, importe, itemcc) VALUES (fila.cantidad, fila.centro, fila.cobertura, fila.idcapitulo, fila.iditem, fila.idnomenclador, fila.idpractica, fila.idsubcapitulo, fila.importe, fila.itemcc);
    END IF;
    RETURN fila;
    END;
    $function$
