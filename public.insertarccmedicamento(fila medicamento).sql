CREATE OR REPLACE FUNCTION public.insertarccmedicamento(fila medicamento)
 RETURNS medicamento
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.medicamentocc:= current_timestamp;
    UPDATE sincro.medicamento SET idfarmtipoventa= fila.idfarmtipoventa, idlaboratorio= fila.idlaboratorio, mcodbarra= fila.mcodbarra, medicamentocc= fila.medicamentocc, mnombre= fila.mnombre, mnroregistro= fila.mnroregistro, mpresentacion= fila.mpresentacion, mtroquel= fila.mtroquel, nomenclado= fila.nomenclado WHERE mnroregistro= fila.mnroregistro AND nomenclado= fila.nomenclado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.medicamento(idfarmtipoventa, idlaboratorio, mcodbarra, medicamentocc, mnombre, mnroregistro, mpresentacion, mtroquel, nomenclado) VALUES (fila.idfarmtipoventa, fila.idlaboratorio, fila.mcodbarra, fila.medicamentocc, fila.mnombre, fila.mnroregistro, fila.mpresentacion, fila.mtroquel, fila.nomenclado);
    END IF;
    RETURN fila;
    END;
    $function$
