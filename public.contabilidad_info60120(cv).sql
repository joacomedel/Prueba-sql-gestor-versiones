CREATE OR REPLACE FUNCTION public.contabilidad_info60120(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
        rfiltros record;
        rsalida record;
        info varchar;
        rinfo   record;
        cad_desde  integer;
        cad_desde_2  integer;
        cad_hasta integer;
        elid bigint;
        elcentro integer;     
        rreversion record;
BEGIN
       /** Este mayor se utiliza para controlar comprobantes de compras + y las minutas - */
      info ='';
     --- RAISE NOTICE 'En el sp contabilidad_info60120(%)',$1;
      EXECUTE sys_dar_filtros($1) INTO rfiltros;

      -- buesco el asiento que se esta poniendo en el mayor de la cuenta
      SELECT INTO rinfo *
      FROM asientogenericoitem
      NATURAL JOIN asientogenerico
      WHERE nrocuentac = rfiltros.nrocuentac
             and idasientogenericoitem = rfiltros.idasientogenericoitem
             and idcentroasientogenericoitem = rfiltros.idcentroasientogenericoitem ;

      IF (FOUND)THEN
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


                elid = split_part(rinfo.idcomprobantesiges, '|', 1)::bigint;
                elcentro = split_part(rinfo.idcomprobantesiges, '|', 2)::integer;
            --- busco el afiliado del reintegro
             -- RAISE NOTICE 'ENTRO IF(%)',rinfo.idasientogenericocomprobtipo ;
            IF (rinfo.idasientogenericocomprobtipo = 1) THEN -- 1 OPC Busco la minuta asociada 
                  SELECT INTO rsalida concat (descrip,' ',nrodoc,' | ',apellido ,' ',nombres ) as afil, *   
                  FROM reintegro
                  NATURAL JOIN persona
                  NATURAL JOIN tiposdoc
                  NATURAL JOIN ordenpagocontableordenpago 
                  WHERE idordenpagocontable = elid and  idcentroordenpagocontable = elcentro ;

                  IF FOUND THEN
                         info = concat('[',rsalida.nroordenpago,'|',rsalida.idcentroordenpago,'] ', rsalida.afil,'@ R',rsalida.idcentroregional,'-',rsalida.nroreintegro,'-',rsalida.anio);
                  --- ELSE info = rinfo.idcomprobantesiges;  
                  END IF;
               
            END  IF;

            IF (rinfo.idasientogenericocomprobtipo = 4) THEN -- minuta de pago  busco el afiliado del reintegro
             --  RAISE NOTICE 'ENTRO IF';
               SELECT INTO rsalida concat (descrip,' ',nrodoc,' | ',apellido ,' ',nombres ) as afil, * 
               FROM reintegro
               NATURAL JOIN persona
               NATURAL JOIN tiposdoc
               WHERE  nroordenpago = elid and  idcentroordenpago = elcentro ;
              
               IF FOUND THEN
                       info = concat('[',elid,'|',elcentro,'] ', rsalida.afil,'@ R',rsalida.idcentroregional,'-',rsalida.nroreintegro,'-',rsalida.anio);
              --- ELSE info = rinfo.idcomprobantesiges;  
              
               END IF;

            END  IF;    
      /*      IF(info='') THEN
                  cad_desde =  position(upper('afiliado') in upper(rinfo.agdescripcion)) ;
                  cad_desde_2 =  position('AF' in upper( rinfo.agdescripcion) ) ;
                  cad_hasta = position('. ' in rinfo.agdescripcion);
                  IF(cad_desde >0  and cad_hasta > cad_desde )THEN
                         SELECT INTO rsalida substring( rinfo.agdescripcion 
                                         from cad_desde
                                         for (cad_hasta - cad_desde)
                               ) as info;
                        IF FOUND THEN 
                            info = replace(  rsalida.info, '.', '');
                        END IF;
                 ELSE 
                        IF(cad_desde_2 >0  and cad_hasta > cad_desde_2 )THEN
                                SELECT INTO rsalida substring( rinfo.agdescripcion 
                                         from cad_desde_2
                                         for (cad_hasta - cad_desde_2)
                               ) as info;
                               IF FOUND THEN 
                                  info = replace(  rsalida.info, '.', '');
                              END IF;

                        END IF;      
                 END IF;
                 info = concat(info,' | ', rinfo.idcomprobantesiges); 
            END IF; 
            */
      END IF;

RETURN info;
END;
$function$
