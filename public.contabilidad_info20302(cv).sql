CREATE OR REPLACE FUNCTION public.contabilidad_info20302(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       rfiltros record;
       info varchar;
   rinfoaux record;
       rinfo   record;
     
BEGIN

      info ='Sin Vincular';
     --- RAISE NOTICE 'En el sp 20302(%)',$1;
      EXECUTE sys_dar_filtros($1) INTO rfiltros;

      SELECT INTO rinfo *
      FROM asientogenericoitem
      NATURAL JOIN asientogenerico
      WHERE nrocuentac = rfiltros.nrocuentac
             and idasientogenericoitem = rfiltros.idasientogenericoitem
             and idcentroasientogenericoitem = rfiltros.idcentroasientogenericoitem
             and acid_h = rfiltros.acid_h;


     IF (FOUND)THEN
                IF( rinfo.idasientogenericocomprobtipo = 7) THEN  --- factura compra
                    SELECT INTO rinfoaux *
                    FROM reclibrofact
                    NATURAL JOIN prestador
                    WHERE  concat(numeroregistro,'|',anio) = rinfo.idcomprobantesiges;
                    IF (FOUND)THEN   -- si el comprobante .....
                         info = concat(rinfoaux.pcuit,' @ ',rinfoaux.pdescripcion, ' @ ');
                              
                    END IF;
               END IF;
               IF( rinfo.idasientogenericocomprobtipo = 1) THEN  --- ordenpagocontable
                   
                    SELECT INTO rinfoaux *
                    FROM ordenpagocontable 
                    NATURAL JOIN prestador
                    WHERE concat(idordenpagocontable,'|',idcentroordenpagocontable)  = rinfo.idcomprobantesiges;

                    IF (FOUND)THEN   -- si el comprobante .....
                         info = concat(rinfoaux.pcuit,' @ ',rinfoaux.pdescripcion, ' @ ');
                              
                    END IF;
               END IF;
      END IF;

RETURN info;
END;
$function$
