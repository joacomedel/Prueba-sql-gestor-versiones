CREATE OR REPLACE FUNCTION public.contabilidad_info40716(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       rfiltros record;
       info varchar;
       rinfo record;
       rinfoaux record;
       xnumeroregistro bigint;
       xordenpago bigint;
       rfactura record;	
       xanio integer;
       xcentroordenpago integer;
       info_prestador record;
       xtipofactura varchar;
       xtipocomprobante integer;
       xnrosucursal integer;
       xnrofactura bigint;
	
BEGIN
       /** Este mayor se utiliza para controlar comprobantes de compras + y las minutas - */
      info ='';
      RAISE NOTICE 'En el sp 40716(%)',$1;
      EXECUTE sys_dar_filtros($1) INTO rfiltros;

      SELECT INTO rinfo *
      FROM asientogenericoitem
      NATURAL JOIN asientogenerico
      WHERE nrocuentac = rfiltros.nrocuentac
             and idasientogenericoitem = rfiltros.idasientogenericoitem
             and idcentroasientogenericoitem = rfiltros.idcentroasientogenericoitem
             and acid_h = rfiltros.acid_h;

      IF (FOUND)THEN
            IF(rinfo.idasientogenericocomprobtipo =5 ) THEN  -- Si se trata del asiento de una factura de venta  5-ND
                   xtipofactura = split_part(rinfo.idcomprobantesiges, '|', 1);
                   xtipocomprobante = trim(split_part(rinfo.idcomprobantesiges, '|', 2))::integer;
                   xnrosucursal = split_part(rinfo.idcomprobantesiges, '|', 3)::integer;
                   xnrofactura = split_part(rinfo.idcomprobantesiges, '|', 4)::bigint;  
                  
                  SELECT INTO rinfoaux  CASE WHEN  nullvalue(prestador.idcolegio) THEN concat(prestador.pcuit ,' @ ', prestador.pdescripcion,' @ ')
                                    ELSE  concat(loagrupa.pcuit ,' @ ', loagrupa.pdescripcion,' @ ') END as elprestador
  
                  from informefacturacion
                  natural join informefacturacionnotadebito
                  natural join facturaventa
                  natural join debitofacturaprestador
                  join  factura using(nroregistro,anio)
                   NATURAL JOIN prestador
                  LEFT join prestador as loagrupa ON (prestador.idcolegio=loagrupa.idprestador)
                  WHERE
                  concat(tipofactura,'|',tipocomprobante,'|',nrosucursal,'|',
                  facturaventa.nrofactura) = rinfo.idcomprobantesiges;


             IF (FOUND)THEN   
                         info = rinfoaux.elprestador;  
             END IF;
                   
            END IF;

            IF(rinfo.idasientogenericocomprobtipo = 4 ) THEN  -- Si se trata del asiento de una minuta   4-orden pago

                        xordenpago = split_part(rinfo.idcomprobantesiges, '|', 1)::bigint;
                        xcentroordenpago = trim(split_part(rinfo.idcomprobantesiges, '|', 2))::integer;
                       
                        SELECT INTO rinfoaux  CASE WHEN  nullvalue(prestador.idcolegio) THEN concat(prestador.pcuit ,' @ ', prestador.pdescripcion,' @ ')
                                    ELSE  concat(loagrupa.pcuit ,' @ ', loagrupa.pdescripcion,' @ ') END as elprestador
                        FROM factura
                        JOIN prestador USING (idprestador)
                        LEFT JOIN prestador as loagrupa ON (prestador.idcolegio=loagrupa.idprestador)
                        WHERE nroordenpago = xordenpago and idcentroordenpago =xcentroordenpago; 
                        IF FOUND THEN  
                                info = rinfoaux.elprestador;     
                        END IF;                 
                
                     
            END IF;

            IF(rinfo.idasientogenericocomprobtipo = 7 ) THEN  -- Si se trata del asiento de un comprobante de compra  7-reclibrofact
                   xnumeroregistro = split_part(rinfo.idcomprobantesiges, '|', 1)::bigint;
                   xanio = trim(split_part(rinfo.idcomprobantesiges, '|', 2))::integer;
                   -- Busco la minuta de pago en la que se pago el comprobante
                  SELECT INTO rinfoaux CASE WHEN  nullvalue(prestador.idcolegio) THEN concat(prestador.pcuit ,' @ ', prestador.pdescripcion,' @ ') ELSE  concat(loagrupa.pcuit ,' @ ', loagrupa.pdescripcion,' @ ') END as elprestador  
                  FROM reclibrofact
                  NATURAL JOIN prestador
                  LEFT JOIN prestador as loagrupa ON (prestador.idcolegio=loagrupa.idprestador)
                  WHERE numeroregistro = xnumeroregistro and anio = xanio;
                  IF FOUND THEN                         
                             info = rinfoaux.elprestador;     
                  END IF;
                   
            END IF;
           
      END IF;

RETURN info;
END;
$function$
