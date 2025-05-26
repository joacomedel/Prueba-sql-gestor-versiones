CREATE OR REPLACE FUNCTION public.insertarccasientogenerico(fila asientogenerico)
 RETURNS asientogenerico
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.asientogenericocc:= current_timestamp;
    UPDATE sincro.asientogenerico SET agdescripcion= fila.agdescripcion, agerror= fila.agerror, agfechacontable= fila.agfechacontable, agfechacreacion= fila.agfechacreacion, agidusuario= fila.agidusuario, agnumeroasiento= fila.agnumeroasiento, agtipoasiento= fila.agtipoasiento, asientogenericocc= fila.asientogenericocc, idagquienmigra= fila.idagquienmigra, idasientogenerico= fila.idasientogenerico, idasientogenericocomprobtipo= fila.idasientogenericocomprobtipo, idasientogenericorevertido= fila.idasientogenericorevertido, idasientogenericotipo= fila.idasientogenericotipo, idcentroasientogenerico= fila.idcentroasientogenerico, idcentroasientogenericorevertido= fila.idcentroasientogenericorevertido, idcentroorigenasiento= fila.idcentroorigenasiento, idcomprobantesiges= fila.idcomprobantesiges, idejerciciocontable= fila.idejerciciocontable, idmultivac= fila.idmultivac WHERE idasientogenerico= fila.idasientogenerico AND idcentroasientogenerico= fila.idcentroasientogenerico AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.asientogenerico(agdescripcion, agerror, agfechacontable, agfechacreacion, agidusuario, agnumeroasiento, agtipoasiento, asientogenericocc, idagquienmigra, idasientogenerico, idasientogenericocomprobtipo, idasientogenericorevertido, idasientogenericotipo, idcentroasientogenerico, idcentroasientogenericorevertido, idcentroorigenasiento, idcomprobantesiges, idejerciciocontable, idmultivac) VALUES (fila.agdescripcion, fila.agerror, fila.agfechacontable, fila.agfechacreacion, fila.agidusuario, fila.agnumeroasiento, fila.agtipoasiento, fila.asientogenericocc, fila.idagquienmigra, fila.idasientogenerico, fila.idasientogenericocomprobtipo, fila.idasientogenericorevertido, fila.idasientogenericotipo, fila.idcentroasientogenerico, fila.idcentroasientogenericorevertido, fila.idcentroorigenasiento, fila.idcomprobantesiges, fila.idejerciciocontable, fila.idmultivac);
    END IF;
    RETURN fila;
    END;
    $function$
