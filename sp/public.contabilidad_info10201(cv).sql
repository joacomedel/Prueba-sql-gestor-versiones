CREATE OR REPLACE FUNCTION public.contabilidad_info10201(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       rfiltros record;
	   rreversion  record;
       info varchar;
       rinfo   record;
       rinfoaux   record;
       xnumeroregistro bigint;
       elid  bigint;
       elcentro integer;
       xanio integer;
	
/*Ejemplo ...........SELECT contabilidad_info10333('{idasientogenericoitem=1627868,idcentroasientogenericoitem=1,nrocuentac=10201,acid_h=D}') */
BEGIN
       /** Este mayor se utiliza para conciliar la cuenta puente cobranza de afiliados
	   */
      info ='Sin vincular';
    --  RAISE NOTICE 'En el sp 10201(%)',$1;
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
	  	        --- Si es una reversion entonces devuelvo el idasientogenerico
           	 	SELECT INTO rreversion *
           	 	FROM asientogenerico 
           	 	NATURAL JOIN asientogenericoitem 
           	 	WHERE idasientogenericorevertido = rinfo.idasientogenerico 
                       AND idcentroasientogenericorevertido=rinfo.idcentroasientogenerico ;
           	 
                IF (FOUND) THEN
                    	info = concat(rinfo.idasientogenerico,'-',rinfo.idcentroasientogenerico);
           	 	END IF;  
           	 
                 --- Si esta revertido devuelvo el idasientorevertido
           	 	IF(not nullvalue(rinfo.idasientogenericorevertido))THEN
                    	info = concat(rinfo.idasientogenericorevertido,'-',rinfo.idcentroasientogenericorevertido);
                END IF;  
				 
				IF ( info ='Sin vincular' AND rinfo.idasientogenericocomprobtipo = 4) THEN /*Es una minuta Imputacion   23-02-23*/
	
						SELECT into rinfoaux *   
						FROM cuentacorrientedeudapagoordenpago
						JOIN cuentacorrientepagos USING (idpago,idcentropago)
						WHERE nroordenpago = split_part(rinfo.idcomprobantesiges, '|',1 ) AND idcentroordenpago = split_part(rinfo.idcomprobantesiges, '|',2 );
						IF (FOUND)THEN   -- guardo en info al recibo 
                 				info = concat(rinfoaux.idpago,'|',rinfoaux.idcentropago)  ;
                       			--RAISE NOTICE '>>>>>>>>entro por el id de una cobranza %',rinfoaux;
            			END IF;
				END IF;
	  
	            IF ( info ='Sin vincular' AND rinfo.idasientogenericocomprobtipo = 9) THEN /*Es una Imputacion   23-02-23*/
				    --- El asiento que va a bajar la cuenta es el asiento de la minuta de imputacion o el de la imputacion si no existe minuta
					--- el factor comun entre la imputacion y un recibo es el recibo
		   	        SELECT  into rinfoaux *   
					FROM cuentacorrientedeudapago
					JOIN cuentacorrientepagos USING (idpago,idcentropago)
					--JOIN recibo ON (idcomprobante = idrecibo AND centro=idcentropago)
					WHERE  iddeuda = split_part(rinfo.idcomprobantesiges, '|', 1)::bigint AND idcentrodeuda =split_part(rinfo.idcomprobantesiges, '|', 2)::integer
      						AND idpago = split_part(rinfo.idcomprobantesiges, '|', 3)::bigint AND idcentropago = split_part(rinfo.idcomprobantesiges, '|', 4)::integer;
										
             		IF (FOUND)THEN   -- guardo en info al recibo 
                 		info = concat(rinfoaux.idpago,'|',rinfoaux.idcentropago)  ;
                       	--RAISE NOTICE '>>>>>>>>entro por el id de una cobranza %',rinfoaux;
            		END IF;
       			END IF; 

                 IF (info ='Sin vincular' AND rinfo.idasientogenericocomprobtipo = 8) THEN /*Es una Cobranza  23-02-23 */
                       -- el asiento se corresponde con un recibo 
						SELECT into rinfoaux *
						FROM recibo
						JOIN cuentacorrientepagos ON (idcomprobante = idrecibo AND centro=idcentropago) 
	 				    WHERE  idrecibo = split_part(rinfo.idcomprobantesiges, '|', 1)::bigint
						       AND centro = split_part(rinfo.idcomprobantesiges, '|', 2)::integer ;
  					    IF (FOUND)THEN   -- si el comprobante es un Recibo
								-- RAISE NOTICE '>>>>>>>>entro por el id de un recibo  %',rinfoaux;
							   info = concat(rinfoaux.idpago,'|',rinfoaux.idcentropago)  ;
						 END IF;
    			 END IF;
				 
	                 IF ( info ='Sin vincular' AND rinfo.idasientogenericocomprobtipo = 5) THEN /*Es una NC 5 = facturaventa*/
				    
 		   	                         SELECT  into rinfoaux *   
						 FROM facturaventa fv
						 JOIN informefacturacion USING(tipofactura,nrosucursal,tipocomprobante,nrofactura)
						 LEFT join cuentacorrientepagos as dp ON(concat(nroinforme*100+idcentroinformefacturacion) = idcomprobante)
						 WHERE  fv.tipofactura = split_part(rinfo.idcomprobantesiges, '|',1 )
      						       AND fv.tipocomprobante = split_part(rinfo.idcomprobantesiges, '|',2 )
      						       AND fv.nrosucursal = split_part(rinfo.idcomprobantesiges, '|', 3)
      						       AND fv.nrofactura = split_part(rinfo.idcomprobantesiges, '|',4 );
										
             			 IF (FOUND)THEN   -- guardo en info al recibo 
                 				info = concat(rinfoaux.idpago,'|',rinfoaux.idcentropago)  ;
                       	                        --RAISE NOTICE '>>>>>>>>entro por el id de una cobranza %',rinfoaux;
            			 END IF;
       			END IF; 

				 

END IF;
RETURN info;
END;
$function$
