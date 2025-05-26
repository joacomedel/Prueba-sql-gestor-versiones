CREATE OR REPLACE FUNCTION public.insertarccasientogenerico_regenerar(fila asientogenerico_regenerar)
 RETURNS asientogenerico_regenerar
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.asientogenerico_regenerarcc:= current_timestamp;
    UPDATE sincro.asientogenerico_regenerar SET agrdescripcion= fila.agrdescripcion, agrfechaingreso= fila.agrfechaingreso, agrfecharesolucion= fila.agrfecharesolucion, agridcentro= fila.agridcentro, asientogenerico_regenerarcc= fila.asientogenerico_regenerarcc, idagr= fila.idagr, idasientogenericocomprobtipo= fila.idasientogenericocomprobtipo, idcomprobantesiges= fila.idcomprobantesiges WHERE agridcentro= fila.agridcentro AND idagr= fila.idagr AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.asientogenerico_regenerar(agrdescripcion, agrfechaingreso, agrfecharesolucion, agridcentro, asientogenerico_regenerarcc, idagr, idasientogenericocomprobtipo, idcomprobantesiges) VALUES (fila.agrdescripcion, fila.agrfechaingreso, fila.agrfecharesolucion, fila.agridcentro, fila.asientogenerico_regenerarcc, fila.idagr, fila.idasientogenericocomprobtipo, fila.idcomprobantesiges);
    END IF;
    RETURN fila;
    END;
    $function$
