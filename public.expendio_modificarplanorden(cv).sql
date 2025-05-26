CREATE OR REPLACE FUNCTION public.expendio_modificarplanorden(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD                  
rfiltros RECORD;
rpractica RECORD;
rverifica RECORD;

--VARIABLES 
 
         
--cursores
cpracticas refcursor;    
             
BEGIN

EXECUTE sys_dar_filtros($1) INTO rfiltros;

IF iftableexists('temp_alta_modifica_ficha_medica ') THEN
     DELETE FROM temp_alta_modifica_ficha_medica ;
ELSE 
  CREATE TEMP TABLE temp_alta_modifica_ficha_medica (  
                                  nroorden bigint,    
				  centro integer,   
                                  iditem bigint, 
                                  cobertura double precision, 
                                  nrodoc varchar,     
				  tipodoc integer, 
                                  iierror varchar,
                                  idplancoberturas bigint
				   ) ;	
END IF;
--SOLO tomo los items que fueron auditados y aprobados o no requirieron auditoria

OPEN cpracticas FOR select * from iteminformacion natural join itemvalorizada iv natural join item WHERE nroorden = rfiltros.nroorden  and  centro=rfiltros.centro and  (iditemestadotipo=2 or iditemestadotipo=4);
  FETCH cpracticas INTO rpractica;
  WHILE  found LOOP
     SELECT INTO rverifica *   
			FROM practicaplan    
			WHERE (idnomenclador = rpractica.idnomenclador) 
						AND (idcapitulo = rpractica.idcapitulo or idcapitulo = '**') 
						AND (idsubcapitulo = rpractica.idsubcapitulo or idsubcapitulo = '**') 
						AND (idpractica = rpractica.idpractica or idpractica = '**') 
						AND idplancoberturas = rfiltros.idplancobertura;
    IF NOT FOUND THEN 
	RAISE EXCEPTION 'R-001, El plan seleccionado no tiene la configuracion para la practica.(Practicas%)',concat(rpractica.idnomenclador,'.',rpractica.idcapitulo ,'.',rpractica.idsubcapitulo,'.',rpractica.idpractica ) ;
    ELSE
       --updateo con el plan seleccionado desde el sistema
       UPDATE  itemvalorizada SET idplancovertura = rfiltros.idplancobertura  WHERE nroorden = rfiltros.nroorden  and  centro=rfiltros.centro and iditem  = rpractica.iditem;
       INSERT INTO temp_alta_modifica_ficha_medica (nroorden ,centro ,iditem ,cobertura ,nrodoc ,tipodoc, iierror ,idplancoberturas )  
		VALUES (rpractica.nroorden, rpractica.centro, rpractica.iditem, rpractica.cobertura, rfiltros.nrodoc, rfiltros.tipodoc, rfiltros.observacion,rfiltros.idplancobertura );
   
    END IF;

           
  FETCH cpracticas INTO rpractica;
  END LOOP;
CLOSE cpracticas;

PERFORM expendio_modificarimporteorden($1);
return 'todo ok';

END;$function$
