CREATE OR REPLACE FUNCTION public.contabilidad_info10386(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       rfiltros record;
       info varchar;
       rinfo_iva record;
       rinfo   record;
       xnumeroregistro bigint;
	
	   xanio integer;
	
BEGIN
       /** Este mayor se utiliza para controlar el iva ventas: lo que va a retornar es el id de la declaracion de iva en el que fue liquidado */
      info ='Sin vincular';
      RAISE NOTICE 'En el sp 10386(%)',$1;
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
                    xnumeroregistro = split_part(rinfo.idcomprobantesiges, '|', 1)::bigint;
                    xanio = trim(split_part(rinfo.idcomprobantesiges, '|', 2))::integer;
             SELECT INTO rinfo_iva *
             FROM reclibrofact
             NATURAL JOIN contabilidad_periodofiscalreclibrofact
             NATURAL JOIN contabilidad_periodofiscal
             WHERE  concat(numeroregistro,'|',anio) = rinfo.idcomprobantesiges;
             --WHERE tipofactura = xtipofactura AND tipocomprobante = xtipocomprobante AND  nrosucursal = xnrosucursal AND nrofactura= xnrofactura;
             IF (FOUND)THEN   -- si el comprobante esta en una liq de iva ventas
                  info = concat('Lic Iva(',rinfo_iva.pftipoiva, '):',rinfo_iva.idperiodofiscal);
             END IF;
      END IF;

RETURN info;
END;
$function$
