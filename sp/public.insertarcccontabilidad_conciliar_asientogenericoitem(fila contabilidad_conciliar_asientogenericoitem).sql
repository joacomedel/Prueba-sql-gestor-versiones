CREATE OR REPLACE FUNCTION public.insertarcccontabilidad_conciliar_asientogenericoitem(fila contabilidad_conciliar_asientogenericoitem)
 RETURNS contabilidad_conciliar_asientogenericoitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.contabilidad_conciliar_asientogenericoitemcc:= current_timestamp;
    UPDATE sincro.contabilidad_conciliar_asientogenericoitem SET ccifechacreacion= fila.ccifechacreacion, ccileyenda= fila.ccileyenda, contabilidad_conciliar_asientogenericoitemcc= fila.contabilidad_conciliar_asientogenericoitemcc, idasientogenericoitem= fila.idasientogenericoitem, idccasientogenericoitem= fila.idccasientogenericoitem, idcentroasientogenericoitem= fila.idcentroasientogenericoitem, idcentroccasientogenericoitem= fila.idcentroccasientogenericoitem WHERE idcentroccasientogenericoitem= fila.idcentroccasientogenericoitem AND idccasientogenericoitem= fila.idccasientogenericoitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.contabilidad_conciliar_asientogenericoitem(ccifechacreacion, ccileyenda, contabilidad_conciliar_asientogenericoitemcc, idasientogenericoitem, idccasientogenericoitem, idcentroasientogenericoitem, idcentroccasientogenericoitem) VALUES (fila.ccifechacreacion, fila.ccileyenda, fila.contabilidad_conciliar_asientogenericoitemcc, fila.idasientogenericoitem, fila.idccasientogenericoitem, fila.idcentroasientogenericoitem, fila.idcentroccasientogenericoitem);
    END IF;
    RETURN fila;
    END;
    $function$
