CREATE OR REPLACE FUNCTION public.insertarccasientogenericoestado(fila asientogenericoestado)
 RETURNS asientogenericoestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.asientogenericoestadocc:= current_timestamp;
    UPDATE sincro.asientogenericoestado SET agefechafin= fila.agefechafin, agefechaini= fila.agefechaini, ageobservacion= fila.ageobservacion, asientogenericoestadocc= fila.asientogenericoestadocc, idasientogenerico= fila.idasientogenerico, idasientogenericoestado= fila.idasientogenericoestado, idcentroasientogenerico= fila.idcentroasientogenerico, idcentroasientogenericoestado= fila.idcentroasientogenericoestado, tipoestadofactura= fila.tipoestadofactura WHERE idasientogenericoestado= fila.idasientogenericoestado AND idcentroasientogenericoestado= fila.idcentroasientogenericoestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.asientogenericoestado(agefechafin, agefechaini, ageobservacion, asientogenericoestadocc, idasientogenerico, idasientogenericoestado, idcentroasientogenerico, idcentroasientogenericoestado, tipoestadofactura) VALUES (fila.agefechafin, fila.agefechaini, fila.ageobservacion, fila.asientogenericoestadocc, fila.idasientogenerico, fila.idasientogenericoestado, fila.idcentroasientogenerico, fila.idcentroasientogenericoestado, fila.tipoestadofactura);
    END IF;
    RETURN fila;
    END;
    $function$
