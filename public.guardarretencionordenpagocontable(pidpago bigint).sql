CREATE OR REPLACE FUNCTION public.guardarretencionordenpagocontable(pidpago bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       retencion record;
       xfecha date;
       resultado boolean;
       retenciones cursor for
              select * FROM tretencionprestador natural join tiporetencion natural join regimenretencion ;
BEGIN
     resultado = false;

-- CS 2017-10-10: La fecha de la Retencion es la misma que la de la OPC
     select into xfecha opcfechaingreso::date from ordenpagocontable where idordenpagocontable=pidpago and idcentroordenpagocontable=centro();
-----------------------------------------------------------------------
     OPEN retenciones;
     FETCH retenciones INTO retencion;
     WHILE  found LOOP
     
        -- Ingreso la informacion del pago
        INSERT INTO pagoordenpagocontable
            (idordenpagocontable, idcentroordenpagocontable, popmonto, popobservacion,idvalorescaja)
        VALUES (pidpago,centro(),retencion.rpmontototal,retencion.rrdescripcion,retencion.idvalorescaja);
     
        -- Ingreso los datos de la Retencion
        INSERT INTO retencionprestador(rpfecha,idtiporetencion,idprestador,rpmontofijo,rpmontoporc,rpmontototal,rpmontobase,rpmontoretanteriores,idordenpagocontable,idcentroordenpagocontable)
        VALUES (
            xfecha,
            retencion.idtiporetencion,
            retencion.idprestador,
            retencion.rpmontofijo,
            retencion.rpmontoporc,
            retencion.rpmontototal,
            retencion.rpmontobase,
            retencion.rpmontoretanteriores,
            pidpago,
            centro());
       resultado=true;
       FETCH retenciones INTO retencion;
       end loop;
     close retenciones;
     return resultado;
END;
$function$
