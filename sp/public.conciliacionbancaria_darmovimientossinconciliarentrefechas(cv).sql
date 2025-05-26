CREATE OR REPLACE FUNCTION public.conciliacionbancaria_darmovimientossinconciliarentrefechas(character varying)
 RETURNS TABLE(elcomprobante character varying, fechacompr date, detalle character varying, monto double precision, observacion character varying, tablacomp character varying, clavecomp character varying, impconc double precision)
 LANGUAGE plpgsql
AS $function$DECLARE
	 rfiltros record ;
	 rbusq record;
	 rconc record;
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
	--RAISE NOTICE 'ENTROOOO AL IFFFF0F (%)',rfiltros.tipoComp;
     eltipocomp = split_part(rfiltros.tipoComp , '|', 1);
     cadbusq = split_part(rfiltros.tipoComp , '|', 2);
     laoperacion = split_part(rfiltros.tipoComp , '|', 3);	
 ELSE 
      --RAISE NOTICE 'NOOOOOOOOOOOOOOOO ENTROOOO AL IFFFFF';
        eltipocomp = 'OPC';
        cadbusq = '';
        laoperacion ='SIN_OP';

 END IF;
  --RAISE NOTICE 'eltipocomp(%)',eltipocomp;
  --RAISE NOTICE 'cadbusq(%)',cadbusq;
  --RAISE NOTICE 'laoperacion(%)',laoperacion;
tipomov = 'tipomov=siges,';

SELECT INTO rconc * 
FROM conciliacionbancaria 
JOIN cuentabancariasosunc using(idcuentabancaria)
WHERE idconciliacionbancaria = rfiltros.idconciliacionbancaria 
      AND idcentroconciliacionbancaria = rfiltros.idcentroconciliacionbancaria ;

 IF (eltipocomp ='' OR eltipocomp = 'OPC' ) THEN
 RETURN QUERY
        SELECT * 
        FROM (
		SELECT concat('OPC:',idordenpagocontable,'|',idcentroordenpagocontable)::varchar,
			opcfechaingreso::date ,
			opcobservacion::VARCHAR ,
			popmonto ::double precision as monto,
			case when (trim(split_part(split_part(split_part(popobservacion, 'Estado', 1),'--INFO BANCA--',2),'NroOp.:',2 ))='') THEN
                             popobservacion
                        ELSE 
                             concat(trim(split_part(split_part(split_part(popobservacion, 'Estado', 1),'--INFO BANCA--',2),'NroOp.:',2 )),split_part(split_part(popobservacion, 'Estado', 2),'--INFO BANCA--',1))
                        END ::VARCHAR as observacion,
			'pagoordenpagocontable'::VARCHAR as tablacomp,
			concat('idpagoordenpagocontable=',idpagoordenpagocontable,'|idcentropagoordenpagocontable=',idcentropagoordenpagocontable)::varchar as clavecomp,
			popmonto - conciliacionbancaria_montoconciliado(concat('idpagoordenpagocontable=',idpagoordenpagocontable,'|idcentropagoordenpagocontable=',idcentropagoordenpagocontable),concat('{',tipomov,'idcbitipo=1',',tabla=pagoordenpagocontable}')::varchar) as impconc
	       
		FROM  pagoordenpagocontable
		NATURAL JOIN ordenpagocontableestado
		NATURAL JOIN ordenpagocontable
		WHERE  idvalorescaja = rconc.idvalorescajacuentab -- forma pago transferencia
			AND opcfechaingreso>=rfiltros.movfechadesde 
                        and opcfechaingreso<=rfiltros.movfechahasta  -- fecha movimientos a conciliar
			AND ( idordenpagocontableestadotipo <> 6 and nullvalue(opcfechafin)) 
        ) as T
	WHERE 
	      concat(opcobservacion,T.observacion) ilike concat('%',rfiltros.cadena,'%')
        ORDER BY observacion ASC; 
   END IF;

   IF (eltipocomp = 'LT' ) THEN
   RETURN QUERY SELECT concat('LT:',idliquidaciontarjeta,'|',idcentroliquidaciontarjeta)::varchar,
		       ltfechapago::date ,
			ltobservacion::VARCHAR ,
			ltimporteliquidaciontarjeta ::double precision as monto,
			ltobservacion::VARCHAR as observacion,
			'liquidaciontarjeta'::VARCHAR as tablacomp,
			concat('idliquidaciontarjeta=',idliquidaciontarjeta,'|idcentroliquidaciontarjeta=',idcentroliquidaciontarjeta)::varchar as clavecomp,
			ltimporteliquidaciontarjeta - 

conciliacionbancaria_montoconciliado(concat('idliquidaciontarjeta=',idliquidaciontarjeta,'|idcentroliquidaciontarjeta=',idcentroliquidaciontarjeta),concat('{',tipomov,'idcbitipo=2',',tabla=liquidaciontarjeta}')::varchar ) as impconc
			
		FROM  liquidaciontarjeta
		NATURAL JOIN cuentabancariasosunc
		NATURAL JOIN liquidaciontarjetaestado
		--LEFT JOIN conciliacionbancariaitemliquidaciontarjeta USING (idliquidaciontarjeta,idcentroliquidaciontarjeta)
		WHERE   
        /*comento Dani el 13082020 por q no traia por ejemplo movimientos de siges del centro=Viedma*/
        /*idbanco =191  --banco credicoop
		        AND */nrocuentac = rfiltros.nrocuentac
			AND ltfechapago>=rfiltros.movfechadesde and ltfechapago<=rfiltros.movfechahasta  -- fecha movimientos a conciliar
			AND ( idtipoestadoliquidaciontarjeta <> 1 and nullvalue(ltefechafin)) 
			AND ltobservacion ilike concat('%',rfiltros.cadena,'%')
		;

  END IF;
  

  IF (eltipocomp ='RE' ) THEN
   RETURN QUERY 
 SELECT concat('REC:',idrecibo,'|',centro)::varchar,
			fecharecibo::date ,
			imputacionrecibo::VARCHAR ,
			recibocupon.monto ::double precision as monto,
			/*imputacionrecibo::VARCHAR as observacion,*/
            
            concat(datosrecibo.nrocliente,' ',datosrecibo.denominacion,' ',substring(
split_part(imputacionrecibo,'-',1)::varchar,length(split_part(imputacionrecibo,'-',1)::varchar)-8,length(split_part(imputacionrecibo,'-',1)::varchar))
,' - ',imputacionrecibo) ::VARCHAR as observacion ,
		
			'recibocupon'::VARCHAR as tablacomp,
			concat('idrecibocupon=',idrecibocupon,'|idcentrorecibocupon=',idcentrorecibocupon)::varchar as clavecomp,
			recibocupon.monto - conciliacionbancaria_montoconciliado(concat('idrecibocupon=',idrecibocupon,'|idcentrorecibocupon=',idcentrorecibocupon),concat('{',tipomov,'idcbitipo=3',',tabla=recibocupon','}')::varchar) as impconc
		FROM recibo 
		NATURAL JOIN recibocupon
		/*LEFT JOIN ctactepagocliente  ON (idcomprobante = idrecibo and centro = idcentropago )
	       left  join clientectacte using(idclientectacte,idcentroclientectacte)
        left join cliente  on (cliente.nrocliente=clientectacte.nrocliente and cliente.barra=clientectacte.barra)*/
LEFT JOIN 
(select idcomprobante ,idcentropago,nrocliente ,barra,denominacion,idclientectacte,idcentroclientectacte
from ctactepagocliente natural join clientectacte natural join cliente
union
select idcomprobante ,idcentropago,nrodoc as nrocliente ,tipodoc as barra,denominacion,1 as idclientectacte,1 as idcentroclientectacte
from cuentacorrientepagos 
join cliente on (nrodoc=nrocliente and cliente.barra=cuentacorrientepagos.tipodoc)
) as datosrecibo
ON (idcomprobante = idrecibo and centro = idcentropago )

			WHERE fecharecibo::date >= rfiltros.movfechadesde and fecharecibo::date<=rfiltros.movfechahasta
			and idvalorescaja = rconc.idvalorescajacuentab 
			and nullvalue(reanulado)
			and (sys_generafiltroconvarchar(laoperacion,imputacionrecibo,concat('%',cadbusq,'%')) )
				 --or
				 and (not nullvalue (datosrecibo.idcomprobante) and datosrecibo.idclientectacte=1 
					  and idcentroclientectacte=1)	
			;
 
  END IF;

  
   IF (eltipocomp ='FA' ) THEN
   RETURN QUERY	SELECT concat(tipofactura,' ',nrofactura,'|',nrosucursal)::varchar,
			fechaemision::date ,
			denominacion::VARCHAR ,
			facturaventacupon.monto ::double precision as monto,
			denominacion::VARCHAR as observacion,
			'facturaventacupon'::VARCHAR as tablacomp,
			concat('idfacturacupon=',idfacturacupon,'|centro=',centro,'|nrofactura=',nrofactura,'|tipocomprobante=',tipocomprobante,'|nrosucursal=',nrosucursal,'|tipofactura=',tipofactura)::varchar as clavecomp,
			facturaventacupon.monto - 

conciliacionbancaria_montoconciliado(concat('idfacturacupon=',idfacturacupon,'|centro=',centro,'|nrofactura=',nrofactura,'|tipocomprobante=',tipocomprobante,'|nrosucursal=',nrosucursal,'|tipofactura=',tipofactura),concat('{',tipomov,'idcbitipo=4',',tabla=facturaventacupon')::varchar ) as impconc
		FROM facturaventa 
		NATURAL JOIN facturaventacupon 
                -- LEFT JOIN conciliacionbancariaitemfacturaventacupon as cbifv USING (idfacturacupon,centro,nrofactura,tipocomprobante,nrosucursal,tipofactura) 
		JOIN cliente ON (nrocliente = nrodoc and facturaventa.barra = cliente.barra)
		WHERE fechaemision  >= rfiltros.movfechadesde and fechaemision<= rfiltros.movfechahasta
			AND (tipofactura ='FA'  or tipofactura ='DC' or tipofactura ='RC'  or tipofactura ='NC')
			AND idvalorescaja = rconc.idvalorescajacuentab  
			AND  nullvalue(anulada) 
			AND denominacion ilike concat('%',rfiltros.cadena,'%')	;
 END IF;
IF (eltipocomp ='NC' ) THEN
   RETURN QUERY	SELECT concat(tipofactura,' ',nrofactura,'|',nrosucursal)::varchar,
			fechaemision::date ,
			denominacion::VARCHAR ,
			facturaventacupon.monto ::double precision as monto,
			denominacion::VARCHAR as observacion,
			'facturaventacupon'::VARCHAR as tablacomp,
			concat('idfacturacupon=',idfacturacupon,'|centro=',centro,'|nrofactura=',nrofactura,'|tipocomprobante=',tipocomprobante,'|nrosucursal=',nrosucursal,'|tipofactura=',tipofactura)::varchar as clavecomp,
			facturaventacupon.monto - 

conciliacionbancaria_montoconciliado(concat('idfacturacupon=',idfacturacupon,'|centro=',centro,'|nrofactura=',nrofactura,'|tipocomprobante=',tipocomprobante,'|nrosucursal=',nrosucursal,'|tipofactura=',tipofactura),concat('{',tipomov,'idcbitipo=4',',tabla=facturaventacupon')::varchar ) as impconc
		FROM facturaventa 
		NATURAL JOIN facturaventacupon 
                -- LEFT JOIN conciliacionbancariaitemfacturaventacupon as cbifv USING (idfacturacupon,centro,nrofactura,tipocomprobante,nrosucursal,tipofactura) 
		JOIN cliente ON (nrocliente = nrodoc and facturaventa.barra = cliente.barra)
		WHERE fechaemision  >= rfiltros.movfechadesde and fechaemision<= rfiltros.movfechahasta
			AND ( tipofactura ='DC' or tipofactura ='RC' or tipofactura ='NC')
			AND idvalorescaja = rconc.idvalorescajacuentab  
			AND  nullvalue(anulada) 
			AND denominacion ilike concat('%',rfiltros.cadena,'%')	;
 END IF;

 IF (eltipocomp ='MIN' ) THEN
   RETURN QUERY SELECT concat('MIN:',nroordenpago,'|',idcentroordenpago)::varchar,
		       fechaingreso::date ,
		       replace(concepto,'Pago a otros:','')::VARCHAR ,
		       importetotal ::double precision as monto,
		       replace(concepto,'Pago a otros:','')::VARCHAR as observacion,
		      'ordenpago'::VARCHAR as tablacomp,
		       concat('nroordenpago=',nroordenpago,'|idcentroordenpago=',idcentroordenpago)::varchar as clavecomp,
		       importetotal - conciliacionbancaria_montoconciliado(concat('nroordenpago=',nroordenpago,'|idcentroordenpago=',idcentroordenpago),concat('{',tipomov,'tabla=ordenpago}')::varchar ) as impconc
			
	       FROM  ordenpago
	       JOIN ordenpagotipo using (idordenpagotipo) 
               NATURAL JOIN ordenpagoimputacion
               NATURAL JOIN cambioestadoordenpago
               WHERE (idordenpagotipo <>7 AND idordenpagotipo <> 2 )
		       AND (nrocuentac = rconc.nrocuentac or   ordenpago.nrocuentachaber = rconc.nrocuentac )
			   
		       AND fechaingreso>=rfiltros.movfechadesde and fechaingreso<=rfiltros.movfechahasta  -- fecha movimientos a conciliar
		       AND ( nullvalue(ceopfechafin)and idtipoestadoordenpago <>4	) 
		       AND concepto ilike concat('%',rfiltros.cadena,'%')
		;

  END IF;

  
END
$function$
