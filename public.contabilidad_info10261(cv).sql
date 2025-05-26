CREATE OR REPLACE FUNCTION public.contabilidad_info10261(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       rfiltros record;
       info varchar;

       rinfo   record;
    
       rfactura record;	
	   elanio integer;
	   elnumeroregistro bigint;
	   
	   info_conciliacion  varchar;
	   rreversion record;
BEGIN
      
      info ='Sin vincular';
	  /*
	  *  El comprobante que conecta los movimientos del Debe y el Haber son las liquidaciones de tarjeta
	  *  se va a intentar retornar el ID de la LiqTarjeta como factor comun de la conciliacion
	  bancamovimiento
      reclibrofact
      pagoordenpagocontable
      liquidaciontarjeta
      ordenpago
      recibocupon
      facturaventacupon
	  */
	  
      -- RAISE NOTICE 'En el sp contabilidad_info10261(%)',$1;
      EXECUTE sys_dar_filtros($1) INTO rfiltros;

      SELECT INTO rinfo *
      FROM asientogenericoitem
      NATURAL JOIN asientogenerico
      WHERE nrocuentac = rfiltros.nrocuentac
             and idasientogenericoitem = rfiltros.idasientogenericoitem
             and idcentroasientogenericoitem = rfiltros.idcentroasientogenericoitem
             and acid_h = rfiltros.acid_h;
         
          
      IF FOUND THEN
	   			 --- Si es una reversion entonces devuelvo el idasientogenerico
           		 SELECT INTO rreversion *
           		 FROM asientogenerico 
           		 NATURAL JOIN asientogenericoitem 
           		 WHERE idasientogenericorevertido = rinfo.idasientogenerico AND idcentroasientogenericorevertido=rinfo.idcentroasientogenerico ;
           		 IF (FOUND) THEN
                    	info = concat(rinfo.idasientogenerico,'-',rinfo.idcentroasientogenerico);
           		 END IF;  
           		 --- Si esta revertido devuelvo el idasientorevertido
           		 IF(not nullvalue(rinfo.idasientogenericorevertido))THEN
                    	info = concat(rinfo.idasientogenericorevertido,'-',rinfo.idcentroasientogenericorevertido);
                   
           		 END IF;
	   
	  			IF( info ='Sin vincular' ) THEN
						SELECT INTO info concat(idconciliacionbancaria,'|',idcentroconciliacionbancaria ) 
						FROM conciliacionbancariaitem 
						WHERE idasientogenerico = rinfo.idasientogenerico AND idcentroasientogenerico = rinfo.idcentroasientogenerico;
				END IF;
				
				IF( info ='Sin vincular' AND rinfo.idasientogenericocomprobtipo = 8)THEN   
				 		--- es el asiento de un recibo
				 		SELECT INTO info concat(idconciliacionbancaria,'|',idcentroconciliacionbancaria ) 
						FROM conciliacionbancariaitem 
						WHERE cbicomsiges ilike concat('%',rinfo.idcomprobantesiges,'%') AND cbitablacomp='recibocupon';
				 
				 END IF; 
	  
	  			
	  			 IF( info ='Sin vincular' AND rinfo.idasientogenericocomprobtipo = 5)THEN  
						--- es el asiento de una factura
				 		SELECT INTO rfactura * 
						FROM facturaventacupon
						NATURAL JOIN facturaventa
						WHERE fechaemision = rinfo.agefechacontable
      							AND concat(tipofactura,'|',tipocomprobante,'|',nrosucursal,'|',nrofactura) ilike rinfo.idcomprobantesiges;
						IF FOUND THEN -- busco el item de la conciliacion
								SELECT INTO info_conciliacion concat(idconciliacionbancaria,'|',idcentroconciliacionbancaria ) 
								FROM conciliacionbancariaitem 
								WHERE cbicomsiges ilike concat('%',rinfo.idcomprobantesiges,'%') AND cbitablacomp='recibocupon';
						END IF;
				 
				 END IF; 
	  
                

                     
                  
      END IF;
     /* IF nullvalue(info) THEN    
	       info=concat('ERROR idasientogenericoitem=',rinfo.idasientogenericoitem,' idcentroasientogenericoitem=' ,rinfo.idcentroasientogenericoitem);
	  END IF;*/
RETURN info;
END;
$function$
