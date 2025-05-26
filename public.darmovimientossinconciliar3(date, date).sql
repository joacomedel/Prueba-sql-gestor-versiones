CREATE OR REPLACE FUNCTION public.darmovimientossinconciliar3(date, date)
 RETURNS SETOF record
 LANGUAGE plpgsql
AS $function$
BEGIN
/**
***  LEERR !!! Si se desea realizar cualquier modificacion se debe eliminar la funcion y volver a crear.  ***
*/
 RETURN QUERY
 SELECT concat('OPC:',idordenpagocontable,'|',idcentroordenpagocontable)::varchar,
               opcfechaingreso::date ,
               opcobservacion::VARCHAR ,
               popmonto ::double precision as monto,
               popobservacion::VARCHAR,
               'pagoordenpagocontable'::VARCHAR,
              concat('idpagoordenpagocontable=',idpagoordenpagocontable,'|idcentropagoordenpagocontable=',idcentropagoordenpagocontable)::varchar
        FROM  pagoordenpagocontable
        NATURAL JOIN ordenpagocontableestado
        NATURAL JOIN ordenpagocontable
        LEFT JOIN conciliacionbancariaitempagoopc as cbi USING(idpagoordenpagocontable,idcentropagoordenpagocontable)
        WHERE  idvalorescaja = 45  -- forma pago transferencia
               AND opcfechaingreso>=$1 and opcfechaingreso<=$2  -- fecha movimientos a conciliar
               AND ( idordenpagocontableestado <> 6 and nullvalue(opcfechafin)) -- ordenes sin anular
               AND nullvalue(cbi.idpagoordenpagocontable) AND nullvalue(cbi.idcentropagoordenpagocontable);--no se encuentra vinculado a ninguna conciliacion;
END;
$function$
