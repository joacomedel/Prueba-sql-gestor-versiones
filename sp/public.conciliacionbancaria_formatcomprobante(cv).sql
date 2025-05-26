CREATE OR REPLACE FUNCTION public.conciliacionbancaria_formatcomprobante(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/****/
DECLARE
    rparam RECORD;
    rmovconciliado RECORD;
    laclave varchar;
    salida varchar;
  
BEGIN
     EXECUTE sys_dar_filtros($1) INTO rparam;
     SELECT INTO rmovconciliado *
     FROM conciliacionbancariaitem
     WHERE idcentroconciliacionbancariaitem = rparam.idcentroconciliacionbancariaitem
           and idconciliacionbancariaitem = rparam.idconciliacionbancariaitem;

     --- El comprobante de Siges es una OPC
     salida = 'S/C';
     IF (rmovconciliado.cbitablacomp = 'pagoordenpagocontable') THEN
        SELECT INTO salida opcobservacion::VARCHAR as observacion,concat('OPC: ',idordenpagocontable,'-',idcentroordenpagocontable,' $ ',round((popmonto)::numeric,2))
        FROM pagoordenpagocontable
 NATURAL JOIN ordenpagocontableestado
        NATURAL JOIN ordenpagocontable 
        WHERE idpagoordenpagocontable = split_part(split_part(rmovconciliado.cbiclavecompsiges,'|',1),'=',2)::bigint
              AND idcentroordenpagocontable = split_part(split_part(rmovconciliado.cbiclavecompsiges,'|',2),'=',2)::integer
   AND ( idordenpagocontableestado <> 6 and nullvalue(opcfechafin)) ;
     END IF;
   IF (rmovconciliado.cbitablacomp = 'liquidaciontarjeta') THEN
        SELECT INTO salida  ltobservacion::VARCHAR as observacion,concat('LT: ',idliquidaciontarjeta,'-',idcentroliquidaciontarjeta,'$ ',round((lttotalpagado)::numeric,2))
        FROM liquidaciontarjeta
 NATURAL JOIN cuentabancariasosunc
		NATURAL JOIN liquidaciontarjetaestado
		 
        WHERE idliquidaciontarjeta = split_part(split_part(rmovconciliado.cbiclavecompsiges,'|',1),'=',2)::bigint
              AND idcentroliquidaciontarjeta = split_part(split_part(rmovconciliado.cbiclavecompsiges,'|',2),'=',2)::integer
 AND ( idtipoestadoliquidaciontarjeta <> 1 and nullvalue(ltefechafin))  ;
     END IF;

    IF (rmovconciliado.cbitablacomp = 'ordenpago') THEN
        SELECT INTO salida  concepto::varchar as observacion,concat('OP: ',nroordenpago,'-',idcentroordenpago,' $ ' ,round((importetotal)::numeric,2))
        FROM ordenpago  	
        WHERE nroordenpago = split_part(split_part(rmovconciliado.cbiclavecompsiges,'|',1),'=',2)::bigint
              AND idcentroordenpago = split_part(split_part(rmovconciliado.cbiclavecompsiges,'|',2),'=',2)::integer;
     END IF;

     IF (rmovconciliado.cbitablacomp = 'facturaventacupon') THEN
        SELECT INTO salida  denominacion::varchar as observacion,concat(tipofactura,' ',nrosucursal,'-',nrofactura,' $ ',round((monto)::numeric,2))
        FROM facturaventacupon  
 NATURAL JOIN facturaventa  
                 LEFT JOIN conciliacionbancariaitemfacturaventacupon as cbifv USING (idfacturacupon,centro,nrofactura,tipocomprobante,nrosucursal,tipofactura) 
		JOIN cliente ON (nrocliente = nrodoc and facturaventa.barra = cliente.barra)
			 
        WHERE idfacturacupon = split_part(split_part(rmovconciliado.cbiclavecompsiges,'|',1),'=',2)::bigint
              AND centro = split_part(split_part(rmovconciliado.cbiclavecompsiges,'|',2),'=',2)::integer
              AND nrofactura  = split_part(split_part(rmovconciliado.cbiclavecompsiges,'|',3),'=',2)::integer
              AND tipocomprobante = split_part(split_part(rmovconciliado.cbiclavecompsiges,'|',4),'=',2)::integer
              AND nrosucursal = split_part(split_part(rmovconciliado.cbiclavecompsiges,'|',5),'=',2)::integer
              AND tipofactura = split_part(split_part(rmovconciliado.cbiclavecompsiges,'|',6),'=',2);
     END IF;


  IF (rmovconciliado.cbitablacomp = 'recibocupon') THEN
        SELECT INTO salida  concat(cliente.nrocliente,' ',cliente.denominacion,' ',substring(
split_part(imputacionrecibo,'-',1)::varchar,length(split_part(imputacionrecibo,'-',1)::varchar)-8,length(split_part(imputacionrecibo,'-',1)::varchar))
,' - ',imputacionrecibo) ::VARCHAR as observacion ,concat('REC: ',idrecibo,'-', idcentrorecibocupon,' $ ',round((monto)::numeric,2))
        FROM recibocupon  	
 NATURAL JOIN recibo 
		LEFT JOIN ctactepagocliente  ON (idcomprobante = idrecibo and centro = idcentropago )
		 left  join clientectacte using(idclientectacte,idcentroclientectacte)
        left join cliente  on (cliente.nrocliente=clientectacte.nrocliente and cliente.barra=clientectacte.barra)
        WHERE idrecibocupon = split_part(split_part(rmovconciliado.cbiclavecompsiges,'|',1),'=',2)::bigint
              AND idcentrorecibocupon = split_part(split_part(rmovconciliado.cbiclavecompsiges,'|',2),'=',2)::integer
 /*and nullvalue(cbir.idrecibocupon) */
			 ;
     END IF;
 /*    SELECT INTO salida CASE rmovconciliado.cbitablacomp WHEN 'pagoordenpagocontable'
          THEN  concat('OPC: ',split_part(split_part(rmovconciliado.cbiclavecompsiges,'|',1),'=',2),'-',split_part(split_part(rmovconciliado.cbiclavecompsiges,'|',2),'=',2))
     ELSE 'S/C'  END;-- sin clasificar */

return salida;
END;
$function$
