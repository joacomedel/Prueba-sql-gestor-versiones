CREATE OR REPLACE FUNCTION public.recibo_esposiblemodificarcomprobante(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
    rparam RECORD;
    srespuesta varchar;
    rliquidaciontarjeta RECORD;
BEGIN
    EXECUTE sys_dar_filtros($1) INTO rparam;

    -----  BelenA:  me fijo si esta dentro de una liquidacion de tarjeta

            SELECT INTO rliquidaciontarjeta *                
            FROM recibocupon    
                NATURAL JOIN recibo   
                NATURAL JOIN valorescaja
                LEFT JOIN liquidaciontarjetaitem AS lti on(recibocupon.idrecibocupon=lti.idrecibocupon AND recibocupon.idcentrorecibocupon=lti.idcentrorecibocupon)            
                LEFT JOIN liquidaciontarjetaestado as lte USING ( idliquidaciontarjeta, idcentroliquidaciontarjeta) 
            WHERE    
                idformapagotipos in (4,5) AND 
                nullvalue(reanulado)
                AND 'true'  AND 'true'  AND 'true'  AND  
                not nullvalue(lti.idrecibocupon)  AND
                idrecibo= rparam.idrecibo   AND 
                recibo.centro =  rparam.centro  AND 
                nullvalue(lte.ltefechafin);

    IF FOUND THEN
            
            IF ( (not nullvalue(rliquidaciontarjeta.idtipoestadoliquidaciontarjeta)) AND rliquidaciontarjeta.idtipoestadoliquidaciontarjeta=2) THEN
                -- Esta dentro de una liquidacion de tarjeta y la liquidacion de tarjeta esta cerrada
                srespuesta = concat('El Recibo se encuentra dentro de la liquidacion de tarjeta cerrada Nº ', rliquidaciontarjeta.idliquidaciontarjeta ) ;
            ELSE
                -- Esta dentro de una liquidacion de tarjeta y la liquidacion de tarjeta esta abierta, tiene que sacarlo de la liquidacion para poder anularlo
                srespuesta = concat('El Recibo se encuentra dentro de la liquidación de tarjeta abierta Nº ', rliquidaciontarjeta.idliquidaciontarjeta , E'\n' ,'Por favor quitar el recibo de la liquidación antes de querer eliminarlo ');
            END IF;

    END IF;

     
RETURN srespuesta;
END;
$function$
