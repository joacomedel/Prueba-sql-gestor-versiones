CREATE OR REPLACE FUNCTION public.tesoreria_controlcaja_vincularcomprobante(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/****/
DECLARE

    rparam RECORD;
    rcontrol RECORD;
    respuesta character varying; 
--x convencion los nombres de record comienzan con r. Ademas de que es peligroso que se llame igual que la tabla
    rcontrolcaja record; 
--x convencion los nombres de cursor comienzan con c 
    unaCaja record;
    vtipocomprobante integer;
    vnrosucursal integer;
    vnrofactura bigint;
    vtipofactura varchar ;
    elidcontrolcaja  BIGINT;
    elcentroiddcontrolcaja  integer;
    vidrecibo BIGINT;
    vcentro integer;
    vidusuario integer;
    scontrol  varchar ;
BEGIN
        respuesta = '';
        EXECUTE sys_dar_filtros($1) INTO rparam;
        -- tipocomprobante -> 1 Factura 
        -- tipocomprobante -> 2 Recibo 
        vtipocomprobante =rparam.tipocomprobante;

        -- SELECT * FROM public.tipocomprobante;
        vidusuario = sys_dar_usuarioactual();
        IF vtipocomprobante = 0 THEN
            vidrecibo  =rparam.idrecibo;
            vcentro =rparam.centro;
        ELSE
            vnrofactura  =rparam.nrofactura;
            vnrosucursal =rparam.nrosucursal;
            vtipofactura  =rparam.tipofactura;
        END IF;

  -- Controlar que no existe una controlcaja vigente para el centro (0 Cerrada / 1 Abierta) 
/*En principio siempre habra solo un controlcaja abierto, luego vemos si mas de uno x diferentes usuarios (como comentaste)
*/

   SELECT INTO scontrol * FROM tesoreria_controlcaja_darcaja(concat('{ccidcajero = ',vidusuario,'}'));
   IF nullvalue(scontrol) THEN
       SELECT INTO scontrol * FROM tesoreria_controlcaja_darcaja(concat('{ccidcajero = ',25,'}')); 
   END IF;

    EXECUTE sys_dar_filtros(scontrol) INTO rcontrolcaja; 

 
  IF vtipocomprobante =0  THEN
       INSERT INTO controlcajarecibo(idcontrolcaja,idcentrocontrolcaja,idrecibo,centro)
                VALUES(rcontrolcaja.idcontrolcaja,rcontrolcaja.idcentrocontrolcaja,vidrecibo,vcentro);
  ELSE

       INSERT INTO controlcajafacturaventa(nrofactura,tipofactura,nrosucursal,tipocomprobante,idcontrolcaja,idcentrocontrolcaja)
                VALUES(vnrofactura,vtipofactura,vnrosucursal,vtipocomprobante,rcontrolcaja.idcontrolcaja,rcontrolcaja.idcentrocontrolcaja);
  END IF;

--por ahora ponemos esto. 
     respuesta = 'todook';
      
    
return respuesta;
END;
$function$
