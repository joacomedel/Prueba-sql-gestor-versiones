CREATE OR REPLACE FUNCTION public.insertarccfar_medicamento(fila far_medicamento)
 RETURNS far_medicamento
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_medicamentocc:= current_timestamp;
    UPDATE sincro.far_medicamento SET far_medicamentocc= fila.far_medicamentocc, idarticulo= fila.idarticulo, idcentroarticulo= fila.idcentroarticulo, mnroregistro= fila.mnroregistro, nomenclado= fila.nomenclado WHERE mnroregistro= fila.mnroregistro AND nomenclado= fila.nomenclado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_medicamento(far_medicamentocc, idarticulo, idcentroarticulo, mnroregistro, nomenclado) VALUES (fila.far_medicamentocc, fila.idarticulo, fila.idcentroarticulo, fila.mnroregistro, fila.nomenclado);
    END IF;
    RETURN fila;
    END;
    $function$
