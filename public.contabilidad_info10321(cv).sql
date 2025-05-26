CREATE OR REPLACE FUNCTION public.contabilidad_info10321(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       rfiltros record;
       info varchar;
       rinfo   record;
       rinfoaux   record;
       xnumeroregistro bigint;
	rreversion  record;
	   xanio integer;
	
BEGIN
       /** Este mayor se utiliza para controlar el iva ventas: lo que va a retornar es el id de la declaracion de iva en el que fue liquidado */
      info ='Sin vincular';
    --  RAISE NOTICE 'En el sp 10386(%)',$1;
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
          		WHERE idasientogenericorevertido = rinfo.idasientogenerico AND idcentroasientogenericorevertido=rinfo.idcentroasientogenerico ;
           		IF (FOUND) THEN
                    info = concat(rinfo.idasientogenerico,'-',rinfo.idcentroasientogenerico);
           		END IF;  
           		--- Si esta revertido devuelvo el idasientorevertido
           		IF(not nullvalue(rinfo.idasientogenericorevertido))THEN
                    info = concat(rinfo.idasientogenericorevertido,'-',rinfo.idcentroasientogenericorevertido);
                  
           		END IF;
		   

       	  	IF (info ='Sin vincular' AND  rinfo.idasientogenericocomprobtipo = 5) THEN /* 070923 Es una Factura de Venta*/

                  
          	SELECT INTO rinfoaux  nrodoc, barra , apellido, nombres  , text_concatenar(concat(imputacion ,' '))  as imputacion
	        FROM (
  		       SELECT   afil.nrodoc,afil.barra  , afil.apellido, afil.nombres,
                                CASE WHEN not nullvalue ( dpa.iddeuda ) THEN  concat(dpa.iddeuda,'|',dpa.idcentrodeuda,'|',dpa.idpago,'|',dpa.idcentropago)
				     WHEN not nullvalue ( dpc.iddeuda ) THEN concat(dpc.iddeuda,'|',dpc.idcentrodeuda,'|',dpc.idpago,'|',dpc.idcentropago)
				     ELSE '' END imputacion 
					 
         	
			FROM facturaventa f
         		JOIN cliente c ON(f.nrodoc=c.nrocliente AND f.tipodoc=c.barra )
                        LEFT JOIN persona as afil ON (afil.nrodoc =c.nrocliente  AND afil.tipodoc = c.barra)
			LEFT JOIN informefacturacion USING (nrofactura,tipofactura,tipocomprobante,nrosucursal)
			LEFT JOIN cuentacorrientedeuda da ON (da.idcomprobante = ( nroinforme * 100) + idcentroinformefacturacion	) 
			LEFT JOIN cuentacorrientedeudapago dpa ON  (da.iddeuda = dpa.iddeuda AND da.idcentrodeuda	= dpa.idcentrodeuda ) 
			LEFT JOIN ctactedeudacliente  dc ON (dc.idcomprobante = ( nroinforme * 100) + idcentroinformefacturacion	) 
			LEFT JOIN ctactedeudapagocliente dpc ON  (dc.iddeuda = dpc.iddeuda AND dc.idcentrodeuda	= dpc.idcentrodeuda ) 
         		 WHERE nrofactura=split_part(rinfo.idcomprobantesiges, '|', 4)::bigint
               		       and tipofactura=split_part(rinfo.idcomprobantesiges, '|', 1)
               		       and tipocomprobante=split_part(rinfo.idcomprobantesiges, '|', 2)::bigint
               		       and nrosucursal=split_part(rinfo.idcomprobantesiges, '|', 3)::bigint
	            )  as T				   
	            GROUP BY 	nrodoc, barra  , apellido, nombres ;		

          	   	 
        
          IF (FOUND)THEN   -- si el comprobante es una factura
                 info = concat(rinfoaux.nrodoc,'-',rinfoaux.barra,' @ ',rinfoaux.apellido,' ',rinfoaux.nombres,' @ ',rinfoaux.imputacion);  
               --   info = concat(rinfoaux.nrodoc,'-',rinfoaux.barra,' @ ',rinfoaux.denominacion,' @ ',rinfoaux.imputacion);
          END IF;
       END IF;

  /*   IF (rinfo.idasientogenericocomprobtipo = 9) THEN /*Es una Imputacion de Recibo  de un afiliado*/
         SELECT INTO rinfoaux *
         FROM cuentacorrientedeuda
         LEFT JOIN recibo on(idcomprobante/100=idrecibo  and centro=idcomprobante%100) 
         LEFT JOIN orden  on(nroorden=idcomprobante/100 and orden.centro=idcomprobante%100)
         LEFT JOIN consumo on(consumo.nroorden=orden.nroorden and consumo.centro=orden.centro)
         LEFT JOIN persona on(persona.nrodoc=cuentacorrientedeuda.nrodoc  and   persona.tipodoc=cuentacorrientedeuda.tipodoc )
         WHERE iddeuda=split_part(rinfo.idcomprobantesiges, '|', 1)::bigint
         		and idcentrodeuda=split_part(rinfo.idcomprobantesiges, '|', 2)::bigint;                

             IF (FOUND)THEN   -- si el comprobante es un Recibo
                 info =concat(rinfoaux.nrodoc,'-',rinfoaux.barra,' @ ',rinfoaux.apellido,' ',rinfoaux.nombres,' @ ',rinfoaux.nroorden,'-',rinfoaux.centro);
            END IF;
      END IF;

      IF (info ='Sin vincular' AND rinfo.idasientogenericocomprobtipo = 9) THEN /*Es una Imputacion de Recibo  de un cliente*/

        SELECT into rinfoaux nrodoc  ,cli.barra as barra, apellido, nombres,
				CASE WHEN not nullvalue(dp_cli.idctactedeudapagocliente) THEN concat(idctactedeudapagocliente,'|',idcentroctactedeudapagocliente) ELSE '' END as imputacion

        FROM ctactedeudacliente 
        LEFT JOIN clientectacte USING (idclientectacte ,idcentroclientectacte)
        LEFT JOIN persona as cli ON (nrodoc = nrocliente  AND tipodoc = clientectacte.barra)
		LEFT JOIN ctactedeudapagocliente as dp_cli USING (idctactedeudapagocliente, idcentroctactedeudapagocliente)
        WHERE  iddeuda= split_part(rinfo.idcomprobantesiges, '|', 1)::bigint     
               and idcentrodeuda=  split_part(rinfo.idcomprobantesiges, '|', 2)::bigint;    
       
         IF (FOUND)THEN   -- si el comprobante es un Recibo
                 info =concat(rinfoaux.nrodoc,'-',rinfoaux.barra,' @ ',rinfoaux.apellido,' ',rinfoaux.nombres,' @ ',rinfoaux.imputacion);
         END IF;

     END IF;
 */

       IF (rinfo.idasientogenericocomprobtipo =4 ) THEN /* 070923 Puede ser una minuta de imputacion */
       		SELECT INTO rinfoaux nrodoc,barra,  apellido, nombres ,  imputacion
  		FROM (
         		SELECT   CASE WHEN nullvalue(dpop_afil.nroordenpago) THEN  cli.nrodoc ELSE afil.nrodoc END as nrodoc, 
						 CASE WHEN nullvalue(dpop_afil.nroordenpago) THEN  cli.barra ELSE afil.barra END as barra, 
						 CASE WHEN nullvalue(dpop_afil.nroordenpago) THEN  cli.apellido ELSE afil.apellido END as apellido, 
						 CASE WHEN nullvalue(dpop_afil.nroordenpago) THEN  cli.nombres ELSE afil.nombres END as nombres,
						 CASE WHEN not nullvalue(dpop_afil.iddeuda) THEN concat(dpop_afil.iddeuda,'|',dpop_afil.idcentrodeuda,'|',dpop_afil.idpago,'|',dpop_afil.idcentropago,' ')
							  WHEN not nullvalue(dp_cli.iddeuda) THEN concat(dp_cli.iddeuda,'|',dp_cli.idcentrodeuda,'|',dp_cli.idpago,'|',dp_cli.idcentropago,' ')
							  ELSE '' END imputacion
    
				  FROM  ordenpago 
				  LEFT JOIN cuentacorrientedeudapagoordenpago as dpop_afil USING(nroordenpago,idcentroordenpago)
				  LEFT JOIN cuentacorrientedeuda as ctaafil USING(iddeuda,idcentrodeuda)
				  LEFT JOIN persona as afil ON (afil.nrodoc =ctaafil.nrodoc  AND afil.tipodoc = ctaafil.tipodoc)

				  LEFT JOIN ctactedeudapagoclienteordenpago as dpop_cli USING(nroordenpago,idcentroordenpago)
				  LEFT JOIN ctactedeudapagocliente as dp_cli USING (idctactedeudapagocliente, idcentroctactedeudapagocliente)
				  LEFT JOIN ctactedeudacliente as ctad_cli  ON(ctad_cli.iddeuda  = dp_cli.iddeuda AND ctad_cli.idcentrodeuda = dp_cli.idcentrodeuda) 
				  LEFT JOIN clientectacte as cta_cli ON (cta_cli.idclientectacte = ctad_cli.idclientectacte  AND cta_cli.idcentroclientectacte = ctad_cli.idcentroclientectacte)

				  LEFT JOIN persona as cli ON (cli.nrodoc = cta_cli.nrocliente  AND cli.tipodoc = cta_cli.barra)
				  WHERE nroordenpago = split_part(rinfo.idcomprobantesiges, '|', 1)::bigint
						AND idcentroordenpago = split_part(rinfo.idcomprobantesiges, '|', 2)::bigint
	 		 ) as T;
					   
          IF (FOUND)THEN   -- si el comprobante es un Recibo
                 info = concat(rinfoaux.nrodoc,'-',rinfoaux.barra,' @ ',rinfoaux.apellido,' ',rinfoaux.nombres,' @ ',rinfoaux.imputacion);
          END IF;
       END IF;

   /*

   IF (rinfo.idasientogenericocomprobtipo = 8 ) THEN /* Se trata de una cobranza*/
        SELECT   into rinfoaux
        CASE WHEN nullvalue(pa.nrodoc)THEN pc.apellido ELSE pa.apellido END as apellido,
        CASE WHEN nullvalue(pa.nrodoc)THEN pc.nombres ELSE pa.nombres END as nombres,
        CASE WHEN nullvalue(pa.nrodoc)THEN pc.nrodoc ELSE pa.nrodoc END as nrodoc,
        CASE WHEN nullvalue(pa.barra)THEN pc.barra ELSE pa.barra END as barra    
        FROM recibo
        left join cuentacorrientepagos as p on(p.idcomprobante = idrecibo  and centro=p.idcentropago)
        left join persona as pa ON (pa.nrodoc=p.nrodoc AND pa.tipodoc = p.tipodoc) 
        left join ctactepagocliente on(ctactepagocliente.idcomprobante = idrecibo  and centro=ctactepagocliente.idcentropago)
        left join clientectacte USING(idclientectacte, idcentroclientectacte)
        left join cliente ON (cliente.nrocliente = clientectacte.nrocliente  AND cliente.barra = clientectacte.barra)
        left join persona as pc ON (pc.nrodoc=cliente.nrocliente AND pc.tipodoc = cliente.barra) 
        WHERE  idrecibo = split_part(rinfo.idcomprobantesiges, '|', 1) 
               and centro = split_part(rinfo.idcomprobantesiges, '|', 2)  ;
        IF (FOUND)THEN   -- si el comprobante es recibo
                 info = concat(rinfoaux.nrodoc,'-',rinfoaux.barra,' @ ',rinfoaux.apellido,' ',rinfoaux.nombres,' @ ',rinfo.idcomprobantesiges);
        END IF;
   END IF;
   */
 IF (rinfo.idasientogenericocomprobtipo = 1 ) THEN /* Se trata de una ordenpago contable */
        SELECT into rinfoaux * 
        FROM ordenpagocontable 
        NATURAL JOIN ordenpagocontablereintegro
        NATURAL JOIN reintegro
        NATURAL JOIN persona
        WHERE idordenpagocontable = split_part(rinfo.idcomprobantesiges, '|', 1)  
                 AND idcentroordenpagocontable = split_part(rinfo.idcomprobantesiges, '|', 2); 
        IF (FOUND)THEN   -- si el comprobante es recibo
                 info = concat(rinfoaux.nrodoc,'-',rinfoaux.barra,' @ ',rinfoaux.apellido,' ',rinfoaux.nombres,' @ ',rinfoaux.nroreintegro,'-', rinfoaux.idcentroregional );
        END IF;

    END IF;

 END IF;
RETURN info;
END;
$function$
