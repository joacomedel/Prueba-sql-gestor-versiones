CREATE OR REPLACE FUNCTION public.insertarccctasctesmontosdescuento(fila ctasctesmontosdescuento)
 RETURNS ctasctesmontosdescuento
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ctasctesmontosdescuentocc:= current_timestamp;
    UPDATE sincro.ctasctesmontosdescuento SET anioingreso= fila.anioingreso, ccmdfechafin= fila.ccmdfechafin, ccmdfechainicio= fila.ccmdfechainicio, ccmdimporte= fila.ccmdimporte, ccmdmontoconsumido= fila.ccmdmontoconsumido, ccmdvigenciafin= fila.ccmdvigenciafin, ccmdvigenciainicio= fila.ccmdvigenciainicio, ctasctesmontosdescuentocc= fila.ctasctesmontosdescuentocc, idcentroctasctesmontosdescuento= fila.idcentroctasctesmontosdescuento, idctasctesmontosdescuento= fila.idctasctesmontosdescuento, mesingreso= fila.mesingreso, nrodoc= fila.nrodoc, tipodoc= fila.tipodoc WHERE idctasctesmontosdescuento= fila.idctasctesmontosdescuento AND idcentroctasctesmontosdescuento= fila.idcentroctasctesmontosdescuento AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ctasctesmontosdescuento(anioingreso, ccmdfechafin, ccmdfechainicio, ccmdimporte, ccmdmontoconsumido, ccmdvigenciafin, ccmdvigenciainicio, ctasctesmontosdescuentocc, idcentroctasctesmontosdescuento, idctasctesmontosdescuento, mesingreso, nrodoc, tipodoc) VALUES (fila.anioingreso, fila.ccmdfechafin, fila.ccmdfechainicio, fila.ccmdimporte, fila.ccmdmontoconsumido, fila.ccmdvigenciafin, fila.ccmdvigenciainicio, fila.ctasctesmontosdescuentocc, fila.idcentroctasctesmontosdescuento, fila.idctasctesmontosdescuento, fila.mesingreso, fila.nrodoc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
