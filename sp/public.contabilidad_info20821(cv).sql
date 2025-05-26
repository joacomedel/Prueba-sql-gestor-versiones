CREATE OR REPLACE FUNCTION public.contabilidad_info20821(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       rfiltros record;
       info varchar;
       rinfo_iva record;
       rinfo   record;
       xtipofactura varchar;
	xtipocomprobante integer;
	xnrosucursal integer;
	xnrofactura bigint;
BEGIN
       /** Este mayor se utiliza para controlar el iva ventas: lo que va a retornar es el id de la declaracion de iva en el que fue liquidado */
       info ='Sin vincular';
       RAISE NOTICE 'En el sp 20821(%)',$1;
      EXECUTE sys_dar_filtros($1) INTO rfiltros;
       
        SELECT INTO rinfo *
       FROM asientogenericoitem
       NATURAL JOIN asientogenerico
       WHERE nrocuentac = rfiltros.nrocuentac
             and idasientogenericoitem = rfiltros.idasientogenericoitem
             and idcentroasientogenericoitem = rfiltros.idcentroasientogenericoitem
             and acid_h = rfiltros.acid_h
             and idasientogenericocomprobtipo = 5;

       IF (FOUND)THEN
                    xtipofactura = split_part(rinfo.idcomprobantesiges, '|', 1);
                    xtipocomprobante = trim(split_part(rinfo.idcomprobantesiges, '|', 2))::integer;
                    xnrosucursal = split_part(rinfo.idcomprobantesiges, '|', 3)::integer;
                    xnrofactura = split_part(rinfo.idcomprobantesiges, '|', 4)::bigint; 

             SELECT INTO rinfo_iva *
             FROM facturaventa
             NATURAL JOIN contabilidad_periodofiscalfacturaventa
             NATURAL JOIN contabilidad_periodofiscal
             WHERE  concat(tipofactura,'|',tipocomprobante,'|',nrosucursal,'|',nrofactura) = rinfo.idcomprobantesiges;
             --WHERE tipofactura = xtipofactura AND tipocomprobante = xtipocomprobante AND  nrosucursal = xnrosucursal AND nrofactura= xnrofactura;
             IF (FOUND)THEN   -- si el comprobante esta en una liq de iva ventas
                  info = concat('Lic Iva(',rinfo_iva.pftipoiva, '):',rinfo_iva.idperiodofiscal);
             END IF;
      END IF;

       
RETURN info;
END;
$function$
