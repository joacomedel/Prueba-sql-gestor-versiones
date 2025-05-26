CREATE OR REPLACE FUNCTION public.tesoreria_controlcaja_darcaja(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/**/
DECLARE

    rparam RECORD;
    respuesta character varying;

    rcontrolcaja record; 

    idcajero integer;
    elidcontrolcaja  BIGINT;
    elcentroiddcontrolcaja  integer;

BEGIN
    respuesta = '';
    EXECUTE sys_dar_filtros($1) INTO rparam;

    idcajero =rparam.ccidcajero;

    SELECT INTO rcontrolcaja  cce.idcontrolcaja,cce.idcentrocontrolcaja 
    FROM controlcaja as cc NATURAL JOIN controlcajaestado as cce
    WHERE idcentrocontrolcajaestado = centro() AND idtipoestadoliquidaciontarjeta=0 AND ccidcajero=idcajero
    AND ccfechainicio <= CURRENT_DATE 
    AND (ccfechafin IS NULL);

    IF NOT FOUND THEN 
      IF idcajero = 25 THEN 
        -- Creo la caja asignada a siges si no exite 
        INSERT INTO controlcaja (ccidcajero,ccobservacion)VALUES('25','SP tesoreria_controlcaja_vincularcomprobante');
                    elidcontrolcaja = currval('public.idcontrolcaja_seq');
                    elcentroiddcontrolcaja = centro() ;

        INSERT INTO controlcajaestado (idcontrolcaja, idcentrocontrolcaja,ccidusuario, idtipoestadoliquidaciontarjeta,ccedescripcion)
            VALUES(elidcontrolcaja ,centro(),sys_dar_usuarioactual(),0,'SP tesoreria_controlcaja_vincularcomprobante');

        respuesta = concat('{ idcontrolcaja = ',elidcontrolcaja,' , idcentrocontrolcaja = ',elcentroiddcontrolcaja,' }');
      ELSE 
          respuesta = NULL;
      END IF;
    ELSE 
           respuesta = concat('{ idcontrolcaja = ',rcontrolcaja.idcontrolcaja,' , idcentrocontrolcaja = ',rcontrolcaja.idcentrocontrolcaja,' }');    
           
    END IF;


return respuesta;
END;
$function$
