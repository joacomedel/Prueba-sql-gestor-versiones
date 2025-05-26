CREATE OR REPLACE FUNCTION public.expendio_verificar_consumo(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       
       
--RECORD 
         rparam RECORD;
         rcobertura RECORD;
         rpendientes RECORD;
--VARIABLES
      
        vidsubcapitulo varchar;
        vidnomenclador  varchar;
        vidcapitulo varchar;
        vidpractica  varchar;
        
       
 

BEGIN
  EXECUTE sys_dar_filtros($1) INTO rparam; 


       IF $1 ilike '%codigopractica%' THEN
               vidnomenclador = split_part(rparam.codigopractica,'.',1);
               vidcapitulo = split_part(rparam.codigopractica,'.',2);
               vidsubcapitulo = split_part(rparam.codigopractica,'.',3);
               vidpractica = split_part(rparam.codigopractica,'.',4);
                              
       ELSE 
       
              IF not nullvalue(rparam.idcapitulo) AND LENGTH(rparam.idcapitulo) < 2 THEN 
	           vidcapitulo = lpad(rparam.idcapitulo,2,'0');
              ELSE 
	          vidcapitulo = rparam.idcapitulo;
              END IF;

              IF not nullvalue(rparam.idnomenclador) AND LENGTH(rparam.idnomenclador) < 2 THEN 
	              vidnomenclador   = lpad(rparam.idnomenclador,2,'0');
              ELSE 
	              vidnomenclador  = rparam.idnomenclador;
              END IF;

             IF not nullvalue(rparam.idsubcapitulo) AND LENGTH(rparam.idsubcapitulo) < 2 THEN 
           	   vidsubcapitulo = lpad(rparam.idsubcapitulo,2,'0');
             ELSE 
	           vidsubcapitulo = rparam.idsubcapitulo;
             END IF;
 
           IF not nullvalue(rparam.idpractica) AND LENGTH(rparam.idpractica) < 2 THEN 
	        vidpractica  = lpad(rparam.idpractica,2,'0');
           ELSE 
	        IF LENGTH(rparam.idpractica) > 2 AND LENGTH(rparam.idpractica) < 4 THEN 
		    vidpractica  = lpad(rparam.idpractica,4,'0');
	        ELSE
		    vidpractica= rparam.idpractica;
	        END IF;
          END IF;
 
END IF;

  IF not (rparam.esAuditoriaPrevia) THEN 
        PERFORM expendio_verificar_consumo(vidnomenclador,vidcapitulo,vidsubcapitulo ,vidpractica
                 ,rparam.idplancobertura, rparam.nrodoc,rparam.tipodoc,rparam.idasocconv); 
  ELSE 

       PERFORM expendio_verificar_consumo(vidnomenclador,vidcapitulo,vidsubcapitulo ,vidpractica
                 ,rparam.idplancobertura, rparam.nrodoc,rparam.tipodoc,rparam.idasocconv); 

         
       PERFORM buscarrdatosfichamedicapendiente(rparam.nrodoc,rparam.tipodoc);
       SELECT INTO rpendientes *	FROM ttfichamedicaemisionpendiente 
               WHERE idnomenclador = vidnomenclador AND idcapitulo = vidcapitulo AND idsubcapitulo = vidsubcapitulo AND idpractica = vidpractica;
       IF FOUND THEN 

           IF $1 ilike '%cantidad%' THEN
                  UPDATE esposibleelconsumo SET rcantidadrestante = rparam.cantidad ;
           ELSE 
                  UPDATE esposibleelconsumo SET rcantidadrestante = rpendientes.cantresta ;
           END IF;
       END IF;

           

        
   END IF;

return 'todook';
END;$function$
