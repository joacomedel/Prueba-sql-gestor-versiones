CREATE OR REPLACE FUNCTION public.aplicarconfiguraciones(integer, character varying, character varying, character varying, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
     

	plan alias for $1;
	nomenclador alias for $2;
	capitulo alias for $3;
	subcapitulo alias for $4;
	practica alias for $5;

BEGIN
       
        INSERT INTO practicaplanborradas
                (idpractica ,
 		idplancobertura ,
  		idnomenclador ,
 		auditoria,
  		cobertura ,
  		idcapitulo ,
  		idsubcapitulo,
  		idplancoberturas ,
  		ppccantpractica ,
  		ppcperiodo ,
  		ppccantperiodos ,
  		ppclongperiodo, 
  		ppcprioridad, 
  		idconfiguracion ,
  		serepite, 
  		ppcperiodoinicial,
  		ppcperiodofinal)
        SELECT
		idpractica ,
 		idplancobertura ,
  		idnomenclador ,
 		auditoria,
  		cobertura ,
  		idcapitulo ,
  		idsubcapitulo,
  		idplancoberturas ,
  		ppccantpractica ,
  		ppcperiodo ,
  		ppccantperiodos ,
  		ppclongperiodo, 
  		ppcprioridad ,
  		idconfiguracion ,
  		serepite ,
  		ppcperiodoinicial ,
  		ppcperiodofinal 
              
               FROM practicaplan
               NATURAL JOIN tempconfigs;

        DELETE FROM practicaplan WHERE (idpractica,idplancobertura,idnomenclador,idcapitulo,idsubcapitulo) 
                                    IN (SELECT idpractica,idplancobertura,idnomenclador,idcapitulo,idsubcapitulo
                                        FROM tempconfigs
                                         );
 

	INSERT INTO practicaplan
		(idpractica ,
		idplancobertura ,
		idnomenclador ,
		auditoria ,
		cobertura ,
		idcapitulo ,
		idsubcapitulo ,
		idplancoberturas ,
		ppccantpractica ,
		ppcperiodo ,
		ppccantperiodos ,	
		ppclongperiodo ,
		ppcprioridad ,	
		serepite ,
		ppcperiodoinicial ,
		ppcperiodofinal) 

 	SELECT
		idpractica ,
 		idplancobertura ,
  		idnomenclador ,
 		auditoria,
  		cobertura ,
  		idcapitulo ,
  		idsubcapitulo,
  		idplancoberturas ,
  		ppccantpractica ,
  		ppcperiodo ,
  		ppccantperiodos ,
  		ppclongperiodo, 
  		ppcprioridad ,	
		serepite ,
  		ppcperiodoinicial ,
  		ppcperiodofinal 
              
               FROM tempconfigs;

	RETURN TRUE;
END;
$function$
