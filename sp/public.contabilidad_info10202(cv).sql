CREATE OR REPLACE FUNCTION public.contabilidad_info10202(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       rfiltros record;
       info varchar;
       rinfo   record;
       rinfoaux   record;
       xnumeroregistro bigint;
	   xanio integer;
	
BEGIN
       /** Este mayor se utiliza para controlar el iva ventas: lo que va a retornar es el id de la declaracion de iva en el que fue liquidado */
      info ='Sin vincular';
     -- RAISE NOTICE 'En el sp 10202(%)',$1;
      EXECUTE sys_dar_filtros($1) INTO rfiltros;

      SELECT INTO rinfo *
      FROM asientogenericoitem
      NATURAL JOIN asientogenerico
      WHERE nrocuentac = rfiltros.nrocuentac
             and idasientogenericoitem = rfiltros.idasientogenericoitem
             and idcentroasientogenericoitem = rfiltros.idcentroasientogenericoitem
             and acid_h = rfiltros.acid_h
             ;
      info = rinfo.idcomprobantesiges; -- por defecto a info le asignamos el idcomprobantesiges
      IF (FOUND)THEN

       IF (rinfo.idasientogenericocomprobtipo = 8) THEN /*Cobranza ..... Es un recibo */
         select  into rinfoaux * 
         FROM ctactepagocliente 
         WHERE idcomprobante = split_part(rinfo.idcomprobantesiges, '|', 1) 
               and idcentropago = split_part(rinfo.idcomprobantesiges, '|', 2);
               ---idcomprobantesiges
            
             IF (FOUND)THEN
                  info = concat('COM: ',rinfoaux.idcomprobante, ' Pago:',  rinfoaux.idpago,'|',rinfoaux.idcentropago);   
             END IF;

      END IF;
     IF (rinfo.idasientogenericocomprobtipo = 4) THEN /*Es una minuta de Imputacion */
	 
	 	SELECT into rinfoaux *
		FROM ctactedeudapagoclienteordenpago
		NATURAL JOIN ctactedeudapagocliente 
		NATURAL JOIN ctactepagocliente  
		WHERE nroordenpago =  split_part(rinfo.idcomprobantesiges, '|', 1)   
      			AND idcentroordenpago =  split_part(rinfo.idcomprobantesiges, '|', 2);

         IF (FOUND)THEN   -- si el comprobante es un Recibo
                 info = concat('COM: ',rinfoaux.idcomprobante, ' Pago:',  rinfoaux.idpago,'|',rinfoaux.idcentropago);
            END IF;
      END IF;
      IF (rinfo.idasientogenericocomprobtipo = 5) THEN /*Es un informefacturacion */
	        SELECT  into rinfoaux *
		FROM ctactepagocliente
		JOIN informefacturacion ON(concat(nroinforme*100+idcentroinformefacturacion) = idcomprobante)
		WHERE concat(tipofactura,'|',nrosucursal,'|',tipocomprobante,'|',nrofactura) =rinfo.idcomprobantesiges ;

         IF (FOUND)THEN   -- si el comprobante es una NC
                 info = concat('COM: ',rinfoaux.idcomprobante, ' Pago:',  rinfoaux.idpago,'|',rinfoaux.idcentropago);
            END IF;
      END IF;

 END IF;
RETURN info;
END;
$function$
