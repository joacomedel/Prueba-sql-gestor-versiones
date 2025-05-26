CREATE OR REPLACE FUNCTION public.insertarccsolicitudauditoriaitem(fila solicitudauditoriaitem)
 RETURNS solicitudauditoriaitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.solicitudauditoriaitemcc:= current_timestamp;
    UPDATE sincro.solicitudauditoriaitem SET idarticulo= fila.idarticulo, idcentroarticulo= fila.idcentroarticulo, idcentrofichamedicainfomedicamento= fila.idcentrofichamedicainfomedicamento, idcentrosolicitudauditoria= fila.idcentrosolicitudauditoria, idcentrosolicitudauditoriaitem= fila.idcentrosolicitudauditoriaitem, idfichamedicainfomedicamento= fila.idfichamedicainfomedicamento, idmonodroga= fila.idmonodroga, idplancoberturas= fila.idplancoberturas, idsolicitudauditoria= fila.idsolicitudauditoria, idsolicitudauditoriaitem= fila.idsolicitudauditoriaitem, saicobertura= fila.saicobertura, saidosisdiaria= fila.saidosisdiaria, saipresentacion= fila.saipresentacion, solicitudauditoriaitemcc= fila.solicitudauditoriaitemcc WHERE idsolicitudauditoriaitem= fila.idsolicitudauditoriaitem AND idcentrosolicitudauditoriaitem= fila.idcentrosolicitudauditoriaitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.solicitudauditoriaitem(idarticulo, idcentroarticulo, idcentrofichamedicainfomedicamento, idcentrosolicitudauditoria, idcentrosolicitudauditoriaitem, idfichamedicainfomedicamento, idmonodroga, idplancoberturas, idsolicitudauditoria, idsolicitudauditoriaitem, saicobertura, saidosisdiaria, saipresentacion, solicitudauditoriaitemcc) VALUES (fila.idarticulo, fila.idcentroarticulo, fila.idcentrofichamedicainfomedicamento, fila.idcentrosolicitudauditoria, fila.idcentrosolicitudauditoriaitem, fila.idfichamedicainfomedicamento, fila.idmonodroga, fila.idplancoberturas, fila.idsolicitudauditoria, fila.idsolicitudauditoriaitem, fila.saicobertura, fila.saidosisdiaria, fila.saipresentacion, fila.solicitudauditoriaitemcc);
    END IF;
    RETURN fila;
    END;
    $function$
