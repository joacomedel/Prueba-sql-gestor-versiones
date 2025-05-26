CREATE OR REPLACE FUNCTION public.contabilidad_info10342(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       rfiltros record;
       info varchar;
       rinfo   record;
       rinfoaux   record;
	   rinfoaux_2 record;
       xnumeroregistro bigint;
       elnuemrorecibo bigint;
	   elcentro bigint;
	   xanio integer;
	   info_minuta record;
	   vnroordenpago bigint;
	   vidcentroordenpago INTEGER;
	
BEGIN
       /** Este mayor se utiliza para controlar los planes de pago */
      info ='Sin vincular';
   --   RAISE NOTICE 'En el sp 10342(%)',$1;
      EXECUTE sys_dar_filtros($1) INTO rfiltros;

      SELECT INTO rinfo *
      FROM asientogenericoitem
      NATURAL JOIN asientogenerico
      WHERE nrocuentac = rfiltros.nrocuentac
             and idasientogenericoitem = rfiltros.idasientogenericoitem
             and idcentroasientogenericoitem = rfiltros.idcentroasientogenericoitem
             and acid_h = rfiltros.acid_h
           --  and idasientogenericocomprobtipo = 5
             ;

      IF (FOUND)THEN
           	
			
			   IF( rinfo.idasientogenericocomprobtipo = 9 )THEN 
			              -- VAS 030223Se trata de una imputacion cuentacorrientedeudapago
						   -- Cuota prestamo por Plan pago cuenta corriente . Prestamo Nº 5007. Cuota Nº 4
						  -- 9 imputacionrecibo
						  SELECT INTO rinfoaux *
  						  FROM cuentacorrientedeudapago
  						  JOIN cuentacorrientedeuda USING (iddeuda,idcentrodeuda)
  						  JOIN prestamocuotas  ON ( idcomprobante = concat(idprestamocuotas::varchar,idcentroprestamocuota::varchar)::bigint)
						  JOIN prestamo USING (idprestamo,idcentroprestamo)
  						  JOIN persona p ON (p.nrodoc= prestamo.nrodoc)
                                                  WHERE iddeuda=split_part(rinfo.idcomprobantesiges, '|', 1) AND idcentrodeuda = split_part(rinfo.idcomprobantesiges, '|', 2)
        						AND idpago =  split_part(rinfo.idcomprobantesiges, '|', 3) AND idcentropago = split_part(rinfo.idcomprobantesiges, '|', 4) ;
						 
						  IF FOUND THEN	  
                         		info = concat(rinfoaux.nrodoc,' ',  rinfoaux.apellido,' ',rinfoaux.nombres ,'//',rinfoaux.idprestamo,'|',rinfoaux.idcentroprestamo);
						  END IF;
					END IF;


                     IF( rinfo.idasientogenericocomprobtipo = 4 )THEN 
			              -- VAS 030223   Se trata de una minuta de imputacion 
						   -- se trata de una minuta de imputacion 
						  -- 4 ordenpago
						  								 
						  SELECT INTO rinfoaux *
						  FROM cuentacorrientedeudapagoordenpago
						  JOIN cuentacorrientedeuda USING (iddeuda,idcentrodeuda)
						  JOIN prestamocuotas  ON ( idcomprobante = concat(idprestamocuotas::varchar,idcentroprestamocuota::varchar)::bigint)
						   JOIN prestamo USING (idprestamo,idcentroprestamo)
                                                  JOIN persona p ON (p.nrodoc= prestamo.nrodoc)
						  WHERE nroordenpago = split_part(rinfo.idcomprobantesiges, '|', 1)
      							AND idcentroordenpago = split_part(rinfo.idcomprobantesiges, '|', 2);	 

								 
						  IF FOUND THEN	  
                         		                   info = concat(rinfoaux.nrodoc,' ',  rinfoaux.apellido,' ',rinfoaux.nombres ,'//',rinfoaux.idprestamo,'|',rinfoaux.idcentroprestamo);
						  END IF;
					END IF;


			   IF (rinfo.idasientogenericocomprobtipo = 5) THEN /*Es una Factura de Venta vas 030223*/
			         ---  Se analiza a que tipo de informe de facturacion corresponde
					 ---  4 Solicitud Financiacion  
					 ---  3 Consumo Turismo
					 SELECT   INTO rinfoaux * 
					 FROM facturaventa 
 					 LEFT JOIN informefacturacion  USING(nrofactura,tipofactura,tipocomprobante,nrosucursal)
					 WHERE  nrofactura=split_part(rinfo.idcomprobantesiges, '|', 4)::bigint
					 		AND tipofactura=split_part(rinfo.idcomprobantesiges, '|', 1)
					 		AND tipocomprobante=split_part(rinfo.idcomprobantesiges, '|', 2)::bigint
					 		AND nrosucursal=split_part(rinfo.idcomprobantesiges, '|', 3)::bigint;
							
					 IF (rinfoaux.idinformefacturaciontipo = 4) THEN 
					          ---  030223   La factura se corresponde con un informe de facturacion de una 4 Solicitud Financiacion  		
							  SELECT  INTO rinfoaux_2 * 
					 		  FROM informefacturacion 
							  NATURAL JOIN informefacturacionsolicitudfinanciacion 
							  NATURAL JOIN solicitudfinanciacion 
                                                          JOIN persona p ON (p.nrodoc= solicitudfinanciacion.nrodoc)
							  WHERE nroinforme	= rinfoaux.nroinforme
							        AND idcentroinformefacturacion = rinfoaux.idcentroinformefacturacion;
							 IF (FOUND)THEN  
							        --- el factor comun del informe es la solicitud de financiacion
							        info = concat(rinfoaux_2.nrodoc,' ',  rinfoaux_2.apellido,' ',rinfoaux_2.nombres ,'//',rinfoaux_2.idprestamo,'|',rinfoaux_2.idcentroprestamo);
						     ELSE 
							        info = ' CASO 1';
							 END IF;
					 END IF;
					 IF (rinfoaux.idinformefacturaciontipo = 3 ) THEN 
							  ---  La factura se corresponde con un informe de facturacion   3 Consumo Turismo	
							  SELECT  INTO rinfoaux_2 * 
					 		  FROM informefacturacion 
							  NATURAL JOIN informefacturacionturismo
							  NATURAL JOIN consumoturismo 
 						          JOIN prestamo USING (idprestamo,idcentroprestamo)
                                                          JOIN persona p ON (p.nrodoc= prestamo.nrodoc)
							  WHERE nroinforme	= rinfoaux.nroinforme
							        AND idcentroinformefacturacion = rinfoaux.idcentroinformefacturacion;
							  IF (FOUND)THEN  
							        --- el factor comun del informe es el consumo de turismo
							        info =  concat(rinfoaux_2.nrodoc,' ',  rinfoaux_2.apellido,' ',rinfoaux_2.nombres ,'//',rinfoaux_2.idprestamo,'|',rinfoaux_2.idcentroprestamo);
									
							  ELSE 
							          info = ' CASO  2';
						      END IF;
					 END IF;
              END IF;
	         
			 
	  
			 
			 
			 
			  IF( rinfo.idasientogenericocomprobtipo = 8) THEN  --8 cobranza
				   	   -- se corresponde a una cobranza	
                       -- Si el asiento corresponde a un recibo 
						SELECT INTO rinfoaux  DISTINCT cuentacorrientepagos.nrodoc as nrodoc, 
                                                                               p.nombres as nombres , p.apellido as apellido ,
                                                                               idprestamo,idcentroprestamo 
						FROM cuentacorrientepagos
						NATURAL JOIN prestamoplandepago
						 JOIN persona p ON (p.nrodoc= cuentacorrientepagos.nrodoc)
						WHERE   idcomprobante= split_part(rinfo.idcomprobantesiges, '|', 1)::bigint AND  idcentropago = split_part(rinfo.idcomprobantesiges, '|', 2)::integer;
 						IF (FOUND)THEN  
							        --- el factor comun es el idprestamo
							        info = concat(rinfoaux.nrodoc,' ',  rinfoaux.apellido,' ',rinfoaux.nombres ,'//',rinfoaux.idprestamo,'|',rinfoaux.idcentroprestamo);
						 ELSE 
							          info = ' CASO  3';
						END IF;
						
                   END IF;
				   	  
	  
 END IF;
RETURN info;
END;
$function$
