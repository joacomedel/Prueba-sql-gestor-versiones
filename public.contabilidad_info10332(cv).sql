CREATE OR REPLACE FUNCTION public.contabilidad_info10332(character varying)
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
      RAISE NOTICE 'En el sp 10332(%)',$1;
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

       IF (rinfo.idasientogenericocomprobtipo = 5) THEN /*Es una Factura de Venta*/
         select  into rinfoaux * 
         from facturaventa
         natural join cliente
         where nrofactura=split_part(rinfo.idcomprobantesiges, '|', 4)::bigint
         and tipofactura=split_part(rinfo.idcomprobantesiges, '|', 1)
         and tipocomprobante=split_part(rinfo.idcomprobantesiges, '|', 2)::bigint
         and nrosucursal=split_part(rinfo.idcomprobantesiges, '|', 3)::bigint;
            
             IF (FOUND)THEN
                info = concat(rinfoaux.nrocliente,' ',rinfoaux.denominacion);
          
             END IF;

      END IF;
     
 END IF;
RETURN info;
END;
$function$
