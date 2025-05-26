CREATE OR REPLACE FUNCTION public.tesoreria_crear_controlcaja(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/****/
DECLARE

    rparam RECORD;
    respuesta character varying; 

    idcajero integer;
    elidcontrolcaja  BIGINT;
    elcentroiddcontrolcaja  integer;

BEGIN
        respuesta = '';
        EXECUTE sys_dar_filtros($1) INTO rparam;
        -- tipocomprobante -> 1 Factura 
        -- tipocomprobante -> 2 Recibo 
        idcajero =rparam.ccidcajero;
  
    INSERT INTO controlcaja (ccidcajero,ccobservacion)VALUES(idcajero,'SP tesoreria_crear_controlcaja');
                elidcontrolcaja = currval('public.idcontrolcaja_seq');
                elcentroiddcontrolcaja = centro() ;

    INSERT INTO controlcajaestado (idcontrolcaja, idcentrocontrolcaja,ccidusuario, idtipoestadoliquidaciontarjeta,ccedescripcion)
        VALUES(elidcontrolcaja ,centro(),sys_dar_usuarioactual(),0,'SP tesoreria_controlcaja_vincularcomprobante');


--por ahora ponemos esto. 
     respuesta = 'todook';
      
    
return respuesta;
END;
$function$
