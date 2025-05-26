CREATE OR REPLACE FUNCTION public.asientogenericofacturaventa_crear(pidoperacion character varying)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
	-- pidoperacion formato: 'FA|1|20|1894'
       xidasiento numeric;
       rgeneracontabilidad RECORD; 
       xnrosucursal integer;
   

BEGIN

xnrosucursal = split_part($1, '|', 3)::integer;
/* KR 16-09-19 SE COMENTA pq el SP se utiliza desde la transaccion TGenerarContabilidad_OffLine para generar la contabilidad de farmacia
SELECT INTO rgeneracontabilidad *  FROM contabilidadoffline
   WHERE  cotipo= 'facturaventa' AND conrosucursal = xnrosucursal AND nullvalue(cofechahasta);
IF NOT FOUND THEN 
*/

IF (iftableexists('tasientogenerico') ) THEN
    DROP TABLE tasientogenerico;
END IF;

CREATE TEMP TABLE tasientogenerico	(
            idoperacion varchar,
            idasientogenericocomprobtipo int DEFAULT 5,				
  	    idcentroperacion integer DEFAULT centro(),
	    operacion varchar,
	    fechaimputa date,
	    obs varchar,
	    centrocosto int,
            idasientogenerico bigint,
	    idcentroasientogenerico integer,
	    idmultivac varchar,
	    agerror varchar	,
            modificacomprobante boolean DEFAULT true
                        );

INSERT INTO tasientogenerico(idoperacion,idasientogenericocomprobtipo)
VALUES ($1,5);


select into xidasiento asientogenerico_crear();
--DELETE FROM tasientogenerico; --MaLaPi 15-06-2018 Limpio la tabla para que no quede basura, hay qeu ver de limpiarla antes de cada insert

-- CS 2018-06-14 ------------------------------------------------------
-- Esto es Temporal, solo durante el periodo de pruebas
-- KR 15-06-18 comento pq esta en el SP asientogenerico_crear el cambio de estado a 11.
--perform	cambiarestadoasientogenerico((xidasiento/100)::bigint,(xidasiento%100)::integer,11);
-- --------------------------------------------------------------------
---END IF;
return xidasiento;
END;
$function$
