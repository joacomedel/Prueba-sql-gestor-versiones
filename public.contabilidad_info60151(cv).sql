CREATE OR REPLACE FUNCTION public.contabilidad_info60151(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       rfiltros record;
       info varchar;
       
       rinfo   record;
	   rreversion record;
       info_op record;
       rinfoaux record;
       elid bigint;
       elcentro integer;
       
	    
BEGIN
       /** Se va devolver en la columna observacion el nombre del prestador agupador si el compobante corresponde a un agrupado
          o el nombre del prestador si no esta agrupado el prestador del comprobante
        */
      info ='';
   ---   RAISE NOTICE 'En el sp contabilidad_info60151(%)',$1;
      EXECUTE sys_dar_filtros($1) INTO rfiltros;

      SELECT INTO rinfo *
      FROM asientogenericoitem
      NATURAL JOIN asientogenerico
      WHERE nrocuentac = rfiltros.nrocuentac
             and idasientogenericoitem = rfiltros.idasientogenericoitem
             and idcentroasientogenericoitem = rfiltros.idcentroasientogenericoitem
             and acid_h = rfiltros.acid_h;
          
          
      IF FOUND THEN
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
				
                IF( info ='' AND rinfo.idasientogenericocomprobtipo = 4)THEN
                       -- Si el asiento corresponde a una minuta de pago
                        elid = split_part(rinfo.idcomprobantesiges, '|', 1)::bigint;
                        elcentro = split_part(rinfo.idcomprobantesiges, '|', 2)::integer;
                        SELECT INTO info_op * 
                        FROM ordenpago
                        WHERE nroordenpago = elid and idcentroordenpago = elcentro;
                        IF (FOUND)THEN
                               info = concat(info_op.nroordenpago,'|',info_op.idcentroordenpago);
                        END IF;
				
               
                END IF;
                IF(info ='' AND  rinfo.idasientogenericocomprobtipo = 1)THEN
                   -- Si el comprobante se corresponde con una OPC
                        elid = split_part(rinfo.idcomprobantesiges, '|', 1)::bigint;
                        elcentro = split_part(rinfo.idcomprobantesiges, '|', 2)::integer;
                        SELECT INTO info_op * 
                        FROM ordenpagocontableordenpago
                        WHERE idordenpagocontable = elid and idcentroordenpagocontable = elcentro;
						
						IF (FOUND)THEN
                               info = concat(info_op.nroordenpago,'|',info_op.idcentroordenpago);
                        END IF;
                       
                END IF;
      END IF;

RETURN info;
END;
$function$
