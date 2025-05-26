CREATE OR REPLACE FUNCTION public.insertarccfar_precioarticulosugerido(fila far_precioarticulosugerido)
 RETURNS far_precioarticulosugerido
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_precioarticulosugeridocc:= current_timestamp;
    UPDATE sincro.far_precioarticulosugerido SET far_precioarticulosugeridocc= fila.far_precioarticulosugeridocc, idarticulo= fila.idarticulo, idcentroarticulo= fila.idcentroarticulo, idcentroprecioarticulosuerido= fila.idcentroprecioarticulosuerido, idprecioarticulosugerido= fila.idprecioarticulosugerido, pasfechafin= fila.pasfechafin, pasfechaini= fila.pasfechaini, pasidusuariocarga= fila.pasidusuariocarga, pasimporteiva= fila.pasimporteiva, pasmotivo= fila.pasmotivo, paspreciocompraprestador= fila.paspreciocompraprestador, pasvalor= fila.pasvalor, pasvaloranterior= fila.pasvaloranterior, pasvalorcompra= fila.pasvalorcompra WHERE idcentroprecioarticulosuerido= fila.idcentroprecioarticulosuerido AND idprecioarticulosugerido= fila.idprecioarticulosugerido AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_precioarticulosugerido(far_precioarticulosugeridocc, idarticulo, idcentroarticulo, idcentroprecioarticulosuerido, idprecioarticulosugerido, pasfechafin, pasfechaini, pasidusuariocarga, pasimporteiva, pasmotivo, paspreciocompraprestador, pasvalor, pasvaloranterior, pasvalorcompra) VALUES (fila.far_precioarticulosugeridocc, fila.idarticulo, fila.idcentroarticulo, fila.idcentroprecioarticulosuerido, fila.idprecioarticulosugerido, fila.pasfechafin, fila.pasfechaini, fila.pasidusuariocarga, fila.pasimporteiva, fila.pasmotivo, fila.paspreciocompraprestador, fila.pasvalor, fila.pasvaloranterior, fila.pasvalorcompra);
    END IF;
    RETURN fila;
    END;
    $function$
