CREATE OR REPLACE FUNCTION public.contabilidad_info50797(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       rfiltros record;
       info varchar;
       rinfo_iva record;
       rinfo_d   record;
       rinfo_h   record;
         rinfo   record;
       xnumeroregistro bigint;
       rfactura record;	
      
	   xanio integer;
	
BEGIN
       /** Este mayor se utiliza para controlar comprobantes de compras + y las minutas - */
      info ='';
      RAISE NOTICE 'En el sp 50797(%)',$1;
      EXECUTE sys_dar_filtros($1) INTO rfiltros;

/*
	idcomprobantesiges=148359|2019|CantApariciones_D =

*/

      -- buesco el asiento que se esta poniendo en el mayor de la cuenta
      SELECT INTO rinfo *
      FROM asientogenericoitem
      NATURAL JOIN asientogenerico
      WHERE nrocuentac = rfiltros.nrocuentac
             and idasientogenericoitem = rfiltros.idasientogenericoitem
             and idcentroasientogenericoitem = rfiltros.idcentroasientogenericoitem
             and acid_h = rfiltros.acid_h ;

      IF (FOUND)THEN
              --- Si lo encuentro me fijo cuantos asientos hay para el comprobante siges al que esta haciendo referencia
            SELECT INTO rinfo_d idcomprobantesiges,count(*) as cant
            FROM asientogenerico
            NATURAL JOIN asientogenericoitem
            WHERE nrocuentac = 50797 
                  and acid_h = 'D' and idcomprobantesiges=rinfo.idcomprobantesiges
            GROUP BY idcomprobantesiges;

            IF NOT FOUND THEN
               rinfo_d.cant=0;
            END IF;
            
            SELECT INTO rinfo_h idcomprobantesiges, count(*) as cant
            FROM asientogenerico
            NATURAL JOIN asientogenericoitem
            WHERE nrocuentac = 50797 
                  and acid_h = 'H' and idcomprobantesiges=rinfo.idcomprobantesiges
            GROUP BY idcomprobantesiges;
            IF NOT FOUND THEN
                   rinfo_h.cant=0;
            END IF;

      --      info = concat (rinfo_d.idcomprobantesiges,'|CantApariciones_D = ',case WHEN nullvalue(rinfo_d.cant) THEN '0' ELSE rinfo_d.cant END,'|CantApariciones_D = ',case WHEN nullvalue(rinfo_h.cant) THEN '0' ELSE rinfo_h.cant END);
            info = concat (rinfo_d.idcomprobantesiges,' / ( ',case WHEN nullvalue(rinfo_d.cant) THEN '0' ELSE rinfo_d.cant END,',',case WHEN nullvalue(rinfo_h.cant) THEN '0' ELSE rinfo_h.cant END,')');
      


      END IF;

RETURN info;
END;
$function$
