CREATE OR REPLACE FUNCTION public.darmovimientossinconciliar(character varying)
 RETURNS TABLE(elcomprobante character varying, fechacompr date, detalle character varying, monto double precision, observacion character varying, tablacomp character varying, clavecomp character varying, cbiimporte double precision)
 LANGUAGE plpgsql
AS $function$
DECLARE
	 rfiltros record ;
	 rbusq record;
	 eltipocomp varchar;
	 cadbusq varchar;
	 laoperacion varchar;
         tipomov varchar;
BEGIN
/**
***  LEERR !!! Si se desea realizar cualquier modificacion se debe eliminar la funcion y volver a crear.  ***
***  
*** Ejecutar antes de compilar  = >> DROP FUNCTION darmovimientossinconciliar (date, date);
*** MaLaPi 16-03-2018 Modificar Solo usando PgAdmin3
*/

 EXECUTE sys_dar_filtros($1) INTO rfiltros;
 SELECT INTO rbusq split_part(rfiltros.tipoComp , '|', 2);
 
 IF (FOUND AND rfiltros.tipoComp<>'')THEN
	RAISE NOTICE 'ENTROOOO AL IFFFF0F (%)',rfiltros.tipoComp;
     eltipocomp = split_part(rfiltros.tipoComp , '|', 1);
     cadbusq = split_part(rfiltros.tipoComp , '|', 2);
     laoperacion = split_part(rfiltros.tipoComp , '|', 3);	
 ELSE 
      RAISE NOTICE 'NOOOOOOOOOOOOOOOO ENTROOOO AL IFFFFF';
        eltipocomp = 'OPC';
        cadbusq = '';
        laoperacion ='SIN_OP';

 END IF;
  RAISE NOTICE 'eltipocomp(%)',eltipocomp;
  RAISE NOTICE 'cadbusq(%)',cadbusq;
  RAISE NOTICE 'laoperacion(%)',laoperacion;
tipomov = 'tipomov =siges';
 IF (eltipocomp ='' OR eltipocomp ='OPC' ) THEN
 RETURN QUERY
	SELECT concat('OPC:',idordenpagocontable,'|',idcentroordenpagocontable)::varchar,
               opcfechaingreso::date ,
               opcobservacion::VARCHAR ,
               popmonto ::double precision as monto,
               popobservacion::VARCHAR,
               'pagoordenpagocontable'::VARCHAR as tablacomp,
               concat('idpagoordenpagocontable=',idpagoordenpagocontable,'|idcentropagoordenpagocontable=',idcentropagoordenpagocontable)::varchar as clavecomp,
	       conciliacionbancaria_montoconciliado(concat('{',tipomov,'idcbitipo=1','clave=',idpagoordenpagocontable,'|',idcentropagoordenpagocontable,'}')::varchar) as cbiimporte
	       
        FROM  pagoordenpagocontable
        NATURAL JOIN ordenpagocontableestado
        NATURAL JOIN ordenpagocontable
        --LEFT JOIN conciliacionbancariaitempagoopc as cbi USING(idpagoordenpagocontable,idcentropagoordenpagocontable)
        WHERE  idvalorescaja = 45  -- forma pago transferencia
               AND opcfechaingreso>=rfiltros.movfechadesde and opcfechaingreso<=rfiltros.movfechahasta  -- fecha movimientos a conciliar
               AND ( idordenpagocontableestado <> 6 and nullvalue(opcfechafin)) -- ordenes sin anular
               AND(idpagoordenpagocontable,idcentropagoordenpagocontable) NOT IN (SELECT idpagoordenpagocontable,idcentropagoordenpagocontable FROM conciliacionbancariaitempagoopc);
   END IF;

   IF (eltipocomp ='LT' ) THEN
   RETURN QUERY SELECT concat('LT:',idliquidaciontarjeta,'|',idcentroliquidaciontarjeta)::varchar,
		       ltfechapago::date ,
			ltobservacion::VARCHAR ,
			lttotalpagado ::double precision as monto,
			ltobservacion::VARCHAR,
			'liquidaciontarjeta'::VARCHAR as tablacomp,
			concat('idliquidaciontarjeta=',idliquidaciontarjeta,'|idcentroliquidaciontarjeta=',idcentroliquidaciontarjeta)::varchar as clavecomp,
			conciliacionbancaria_montoconciliado(concat('{',tipomov,'idcbitipo=2','clave=',idliquidaciontarjeta,'|',idcentroliquidaciontarjeta,'}')::varchar ) as cbiimporte
			
		FROM  liquidaciontarjeta
		NATURAL JOIN cuentabancariasosunc
		NATURAL JOIN liquidaciontarjetaestado
		LEFT JOIN conciliacionbancariaitemliquidaciontarjeta USING (idliquidaciontarjeta,idcentroliquidaciontarjeta)
		WHERE   idbanco =191  --banco credicoop
			AND ltfechapago>=rfiltros.movfechadesde and ltfechapago<=rfiltros.movfechahasta  -- fecha movimientos a conciliar
			AND ( idtipoestadoliquidaciontarjeta <> 1 and nullvalue(ltefechafin)) 
			AND nullvalue(conciliacionbancariaitemliquidaciontarjeta.idliquidaciontarjeta);

  END IF;
  

  IF (eltipocomp ='RE' ) THEN
   RETURN QUERY SELECT concat('REC:',idrecibo,'|',centro)::varchar,
			fecharecibo::date ,
			imputacionrecibo::VARCHAR ,
			recibocupon.monto ::double precision as monto,
			imputacionrecibo::VARCHAR,
			'recibocupon'::VARCHAR as tablacomp,
			concat('idrecibocupon=',idrecibocupon,'|idcentrorecibocupon=',idcentrorecibocupon)::varchar as clavecomp,
			conciliacionbancaria_montoconciliado(concat('{',tipomov,'idcbitipo=3','clave=',idrecibocupon,'|',idcentrorecibocupon,'}')::varchar) as cbiimporte
		FROM recibo 
		NATURAL JOIN recibocupon
		LEFT JOIN ctactepagocliente  ON (idcomprobante = idrecibo and centro = idcentropago )
		LEFT JOIN conciliacionbancariaitemrecibocupon as cbir USING (idrecibocupon,idcentrorecibocupon)
		WHERE fecharecibo::date >= rfiltros.movfechadesde and fecharecibo::date<=rfiltros.movfechahasta
			and idvalorescaja = 45 
			--and sys_generafiltroconvarchar(laoperacion,imputacionrecibo,concat('%',cadbusq,'%'))
			and nullvalue(cbir.idrecibocupon) 
			--and (nullvalue (ctactepagocliente.idcomprobante) or (not nullvalue (ctactepagocliente.idcomprobante) and ctactepagocliente.idclientectacte=1 and idcentroclientectacte=1))
			and (sys_generafiltroconvarchar(laoperacion,imputacionrecibo,concat('%',cadbusq,'%')) or (not nullvalue (ctactepagocliente.idcomprobante) and ctactepagocliente.idclientectacte=1 and idcentroclientectacte=1))			
			;

  END IF;



  
   IF (eltipocomp ='FA' ) THEN
   RETURN QUERY	SELECT concat('FA ',nrofactura,'|',nrosucursal)::varchar,
			fechaemision::date ,
			denominacion::VARCHAR ,
			facturaventacupon.monto ::double precision as monto,
			denominacion::VARCHAR,
			'facturaventacupon'::VARCHAR as tablacomp,
			concat('idfacturacupon=',idfacturacupon,'|centro=',centro,'|nrofactura=',nrofactura,'|tipocomprobante=',tipocomprobante,'|nrosucursal=',nrosucursal,'|tipofactura=',tipofactura)::varchar as clavecomp,
			conciliacionbancaria_montoconciliado(concat('{',tipomov,'idcbitipo=4','clave=',idfacturacupon,'|',centro,'|',nrofactura,'|',tipocomprobante,'|',nrosucursal,'|',tipofactura,'}')::varchar ) as impconc
		FROM facturaventa 
		NATURAL JOIN facturaventacupon 
                 LEFT JOIN conciliacionbancariaitemfacturaventacupon as cbifv USING (idfacturacupon,centro,nrofactura,tipocomprobante,nrosucursal,tipofactura) 
		JOIN cliente ON (nrocliente = nrodoc and facturaventa.barra = cliente.barra)
		WHERE fechaemision  >= rfiltros.movfechadesde and fechaemision<= rfiltros.movfechahasta
			and tipofactura ='FA'  
			and idvalorescaja = 45  and nullvalue(cbifv.nrofactura);
 END IF;
  
END
$function$
