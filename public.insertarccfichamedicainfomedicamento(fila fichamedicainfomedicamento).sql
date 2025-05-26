CREATE OR REPLACE FUNCTION public.insertarccfichamedicainfomedicamento(fila fichamedicainfomedicamento)
 RETURNS fichamedicainfomedicamento
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicainfomedicamentocc:= current_timestamp;
    UPDATE sincro.fichamedicainfomedicamento SET idmonodroga= fila.idmonodroga, idfichamedicainfo= fila.idfichamedicainfo, idcentrofichamedicainfo= fila.idcentrofichamedicainfo, idfichamedicainfomedicamento= fila.idfichamedicainfomedicamento, fmimfechafin= fila.fmimfechafin, idcentrofichamedicainfomedicamento= fila.idcentrofichamedicainfomedicamento, idcentroarticulo= fila.idcentroarticulo, fmimcobertura= fila.fmimcobertura, fmimdosisdiaria= fila.fmimdosisdiaria, idplancoberturas= fila.idplancoberturas, idarticulo= fila.idarticulo, fmimmpresentacion= fila.fmimmpresentacion, fichamedicainfomedicamentocc= fila.fichamedicainfomedicamentocc WHERE idfichamedicainfomedicamento= fila.idfichamedicainfomedicamento AND idcentrofichamedicainfomedicamento= fila.idcentrofichamedicainfomedicamento AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.fichamedicainfomedicamento(idmonodroga, idfichamedicainfo, idcentrofichamedicainfo, idfichamedicainfomedicamento, fmimfechafin, idcentrofichamedicainfomedicamento, idcentroarticulo, fmimcobertura, fmimdosisdiaria, idplancoberturas, idarticulo, fmimmpresentacion, fichamedicainfomedicamentocc) VALUES (fila.idmonodroga, fila.idfichamedicainfo, fila.idcentrofichamedicainfo, fila.idfichamedicainfomedicamento, fila.fmimfechafin, fila.idcentrofichamedicainfomedicamento, fila.idcentroarticulo, fila.fmimcobertura, fila.fmimdosisdiaria, fila.idplancoberturas, fila.idarticulo, fila.fmimmpresentacion, fila.fichamedicainfomedicamentocc);
    END IF;
    RETURN fila;
    END;
    $function$
