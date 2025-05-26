CREATE OR REPLACE FUNCTION public.insertarccfar_ordenventa(fila far_ordenventa)
 RETURNS far_ordenventa
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventacc:= current_timestamp;
    UPDATE sincro.far_ordenventa SET idafiliado= fila.idafiliado, idordenventa= fila.idordenventa, idcentroordenventa= fila.idcentroordenventa, ovnombrecliente= fila.ovnombrecliente, ovobservacion= fila.ovobservacion, nrocliente= fila.nrocliente, idvendedor= fila.idvendedor, ovfechaemision= fila.ovfechaemision, barra= fila.barra, idcentroafiliado= fila.idcentroafiliado, idordenventatipo= fila.idordenventatipo, idcentrovalidacion= fila.idcentrovalidacion, far_ordenventacc= fila.far_ordenventacc, idvalidacion= fila.idvalidacion WHERE idcentroordenventa= fila.idcentroordenventa AND idordenventa= fila.idordenventa AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_ordenventa(idafiliado, idordenventa, idcentroordenventa, ovnombrecliente, ovobservacion, nrocliente, idvendedor, ovfechaemision, barra, idcentroafiliado, idordenventatipo, idcentrovalidacion, far_ordenventacc, idvalidacion) VALUES (fila.idafiliado, fila.idordenventa, fila.idcentroordenventa, fila.ovnombrecliente, fila.ovobservacion, fila.nrocliente, fila.idvendedor, fila.ovfechaemision, fila.barra, fila.idcentroafiliado, fila.idordenventatipo, fila.idcentrovalidacion, fila.far_ordenventacc, fila.idvalidacion);
    END IF;
    RETURN fila;
    END;
    $function$
