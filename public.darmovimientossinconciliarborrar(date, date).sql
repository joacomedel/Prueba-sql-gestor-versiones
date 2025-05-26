CREATE OR REPLACE FUNCTION public.darmovimientossinconciliarborrar(date, date)
 RETURNS TABLE(elcomprobante character varying, fechacompr date, detalle character varying, monto double precision, observacion character varying, tipo character varying, elidpago character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
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
        --LEFT JOIN conciliacionbancariaitempagoopc as cbi USING(idpagoordenpagocontable,idcentropagoordenpagocontable)
        WHERE  idvalorescaja = 45  -- forma pago transferencia
               AND opcfechaingreso>=$1 and opcfechaingreso<=$2  -- fecha movimientos a conciliar
               AND ( idordenpagocontableestado <> 6 and nullvalue(opcfechafin)) -- ordenes sin anular
               AND(idpagoordenpagocontable,idcentropagoordenpagocontable) NOT IN (SELECT idpagoordenpagocontable,idcentropagoordenpagocontable FROM conciliacionbancariaitempagoopc);

END
$function$
