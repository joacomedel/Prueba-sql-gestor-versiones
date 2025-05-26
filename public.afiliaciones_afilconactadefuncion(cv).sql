CREATE OR REPLACE FUNCTION public.afiliaciones_afilconactadefuncion(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/**/
DECLARE
    rparam RECORD;
    respuesta character varying;

    rcontrolcaja record; 

    idcajero integer;
    elidcontrolcaja  BIGINT;
    elcentroiddcontrolcaja  integer;

BEGIN
    respuesta = '';
    EXECUTE sys_dar_filtros($1) INTO rparam;
    
    CREATE TEMP TABLE temp_afiliaciones_afilconactadefuncion AS (

       SELECT concat(nrodoc, '-', barra) as nroafiliado, concat(apellido, ' ', nombres) as elafiliado, fechainios , fechafinos,  	adffechafallecio 	
       ,'1-Nro.Afiliado#nroafiliado@2-Afiliado#elafiliado@3-Fecha Inicio Adherencia#fechainios@4-Fecha Fin OS#fechafinos@5-Fallecimiento#adffechafallecio'::text as mapeocampocolumna
	 
       FROM actasdefun NATURAL JOIN persona 
--KR utilizo esta fecha ya que en la tabla actasdefun no tenemos x ahora guardada la fecha en que presento el acta. Lo hacemos esta semana si no hay dramas con la sincro.
        WHERE adffechafallecio BETWEEN rparam.fechadesde AND rparam.fechahasta AND CASE WHEN nullvalue(rparam.nrodoc) THEN true ELSE  nrodoc ilike concat('%',rparam.nrodoc,'%') END
      ); 
 
return respuesta;

end;

$function$
