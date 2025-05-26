CREATE OR REPLACE FUNCTION public.insertarccconsumoturismo(fila consumoturismo)
 RETURNS consumoturismo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.consumoturismocc:= current_timestamp;
    UPDATE sincro.consumoturismo SET cantdias= fila.cantdias, consumoturismocc= fila.consumoturismocc, ctdescuento= fila.ctdescuento, ctfechasalida= fila.ctfechasalida, ctfehcingreso= fila.ctfehcingreso, ctinformacioncontacto= fila.ctinformacioncontacto, idcentroconsumoturismo= fila.idcentroconsumoturismo, idcentroprestamo= fila.idcentroprestamo, idconsumoturismo= fila.idconsumoturismo, idprestamo= fila.idprestamo, idturismounidad= fila.idturismounidad, nrocuentac= fila.nrocuentac WHERE idcentroconsumoturismo= fila.idcentroconsumoturismo AND idconsumoturismo= fila.idconsumoturismo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.consumoturismo(cantdias, consumoturismocc, ctdescuento, ctfechasalida, ctfehcingreso, ctinformacioncontacto, idcentroconsumoturismo, idcentroprestamo, idconsumoturismo, idprestamo, idturismounidad, nrocuentac) VALUES (fila.cantdias, fila.consumoturismocc, fila.ctdescuento, fila.ctfechasalida, fila.ctfehcingreso, fila.ctinformacioncontacto, fila.idcentroconsumoturismo, fila.idcentroprestamo, fila.idconsumoturismo, fila.idprestamo, fila.idturismounidad, fila.nrocuentac);
    END IF;
    RETURN fila;
    END;
    $function$
