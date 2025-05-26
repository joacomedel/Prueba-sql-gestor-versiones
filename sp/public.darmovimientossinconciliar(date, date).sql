CREATE OR REPLACE FUNCTION public.darmovimientossinconciliar(date, date)
 RETURNS TABLE(elcomprobante character varying, fechacompr date, detalle character varying, monto double precision, observacion character varying, tablacomp character varying, clavecomp character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
/**
***  LEERR !!! Si se desea realizar cualquier modificacion se debe eliminar la funcion y volver a crear.  ***
***  
*** Ejecutar antes de compilar  = >> DROP FUNCTION darmovimientossinconciliar (date, date);
*** MaLaPi 16-03-2018 Modificar Solo usando PgAdmin3
*/


 RETURN QUERY
 SELECT concat('OPC:',idordenpagocontable,'|',idcentroordenpagocontable)::varchar,
               opcfechaingreso::date ,
               opcobservacion::VARCHAR ,
               popmonto ::double precision as monto,
               popobservacion::VARCHAR,
               'pagoordenpagocontable'::VARCHAR as tablacomp,
              concat('idpagoordenpagocontable=',idpagoordenpagocontable,'|idcentropagoordenpagocontable=',idcentropagoordenpagocontable)::varchar as clavecomp
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
