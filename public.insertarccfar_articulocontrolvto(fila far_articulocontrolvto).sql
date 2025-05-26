CREATE OR REPLACE FUNCTION public.insertarccfar_articulocontrolvto(fila far_articulocontrolvto)
 RETURNS far_articulocontrolvto
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_articulocontrolvtocc:= current_timestamp;
    UPDATE sincro.far_articulocontrolvto SET facvactivo= fila.facvactivo, far_articulocontrolvtocc= fila.far_articulocontrolvtocc, fechavto= fila.fechavto, fofechamodif= fila.fofechamodif, idarticulo= fila.idarticulo, idcentroarticulo= fila.idcentroarticulo, idcentroprecargastockajusteitem= fila.idcentroprecargastockajusteitem, idprecargastockajusteitem= fila.idprecargastockajusteitem WHERE idarticulo= fila.idarticulo AND idcentroarticulo= fila.idcentroarticulo AND idprecargastockajusteitem= fila.idprecargastockajusteitem AND idcentroprecargastockajusteitem= fila.idcentroprecargastockajusteitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_articulocontrolvto(facvactivo, far_articulocontrolvtocc, fechavto, fofechamodif, idarticulo, idcentroarticulo, idcentroprecargastockajusteitem, idprecargastockajusteitem) VALUES (fila.facvactivo, fila.far_articulocontrolvtocc, fila.fechavto, fila.fofechamodif, fila.idarticulo, fila.idcentroarticulo, fila.idcentroprecargastockajusteitem, fila.idprecargastockajusteitem);
    END IF;
    RETURN fila;
    END;
    $function$
