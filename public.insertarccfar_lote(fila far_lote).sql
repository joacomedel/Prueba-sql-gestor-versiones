CREATE OR REPLACE FUNCTION public.insertarccfar_lote(fila far_lote)
 RETURNS far_lote
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_lotecc:= current_timestamp;
    UPDATE sincro.far_lote SET far_lotecc= fila.far_lotecc, idarticulo= fila.idarticulo, idcentroarticulo= fila.idcentroarticulo, idcentrolote= fila.idcentrolote, idlote= fila.idlote, idubicacion= fila.idubicacion, lfechaelaboracion= fila.lfechaelaboracion, lfechamofificacion= fila.lfechamofificacion, lfechavencimiento= fila.lfechavencimiento, lstock= fila.lstock, lstockinicial= fila.lstockinicial WHERE idcentrolote= fila.idcentrolote AND idlote= fila.idlote AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_lote(far_lotecc, idarticulo, idcentroarticulo, idcentrolote, idlote, idubicacion, lfechaelaboracion, lfechamofificacion, lfechavencimiento, lstock, lstockinicial) VALUES (fila.far_lotecc, fila.idarticulo, fila.idcentroarticulo, fila.idcentrolote, fila.idlote, fila.idubicacion, fila.lfechaelaboracion, fila.lfechamofificacion, fila.lfechavencimiento, fila.lstock, fila.lstockinicial);
    END IF;
    RETURN fila;
    END;
    $function$
