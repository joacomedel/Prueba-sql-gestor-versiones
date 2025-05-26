CREATE OR REPLACE FUNCTION public.insertarccasientogenericoitem(fila asientogenericoitem)
 RETURNS asientogenericoitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.asientogenericoitemcc:= current_timestamp;
    UPDATE sincro.asientogenericoitem SET nrocuentac= fila.nrocuentac, asientogenericoitemcc= fila.asientogenericoitemcc, idcentroasientogenericoitem= fila.idcentroasientogenericoitem, acid_h= fila.acid_h, acimontoconformato= fila.acimontoconformato, acidescripcion= fila.acidescripcion, idcentroasientogenerico= fila.idcentroasientogenerico, acimonto= fila.acimonto, idasientogenerico= fila.idasientogenerico, idasientogenericoitem= fila.idasientogenericoitem, acicentrocosto= fila.acicentrocosto WHERE idcentroasientogenericoitem= fila.idcentroasientogenericoitem AND idasientogenericoitem= fila.idasientogenericoitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.asientogenericoitem(nrocuentac, asientogenericoitemcc, idcentroasientogenericoitem, acid_h, acimontoconformato, acidescripcion, idcentroasientogenerico, acimonto, idasientogenerico, idasientogenericoitem, acicentrocosto) VALUES (fila.nrocuentac, fila.asientogenericoitemcc, fila.idcentroasientogenericoitem, fila.acid_h, fila.acimontoconformato, fila.acidescripcion, fila.idcentroasientogenerico, fila.acimonto, fila.idasientogenerico, fila.idasientogenericoitem, fila.acicentrocosto);
    END IF;
    RETURN fila;
    END;
    $function$
