CREATE OR REPLACE FUNCTION public.contabilidad_info20502(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       rfiltros record;
       rsalida record;
       info varchar;
       rinfo   record;
       cad_desde  integer;
       cad_hasta integer;
elid bigint;
 elcentro integer;     
BEGIN
       /** Este mayor se utiliza para controlar comprobantes de compras + y las minutas - */
      info ='';
      RAISE NOTICE 'En el sp contabilidad_info60120(%)',$1;
      EXECUTE sys_dar_filtros($1) INTO rfiltros;

      -- buesco el asiento que se esta poniendo en el mayor de la cuenta
      SELECT INTO rinfo *
      FROM asientogenericoitem
      NATURAL JOIN asientogenerico
      WHERE nrocuentac = rfiltros.nrocuentac
             and idasientogenericoitem = rfiltros.idasientogenericoitem
             and idcentroasientogenericoitem = rfiltros.idcentroasientogenericoitem ;

      IF (FOUND)THEN
                elid = split_part(rinfo.idcomprobantesiges, '|', 1)::bigint;
                elcentro = split_part(rinfo.idcomprobantesiges, '|', 2)::integer;
          
              RAISE NOTICE 'ENTRO IF(%)',rinfo.idasientogenericocomprobtipo ;
            IF (rinfo.idasientogenericocomprobtipo = 1) THEN -- 1 OPC Busco la minuta asociada 
                  SELECT INTO rsalida  *   
                  FROM 
                  ordenpagocontableordenpago 
                  WHERE idordenpagocontable = elid and  idcentroordenpagocontable = elcentro ;

                  IF FOUND THEN
                         info = concat('[',rsalida.nroordenpago,'|',rsalida.idcentroordenpago,'] ');
                  END IF;
               
            END  IF;

            IF (rinfo.idasientogenericocomprobtipo = 4) THEN -- minuta de pago  busco el afiliado del reintegro
                            
                  info = concat('[',elid,'|',elcentro,'] ');
              
            END IF;

       END  IF;    
    
            
     

RETURN info;
END;
$function$
