CREATE OR REPLACE FUNCTION public.actualizacionosexterna_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$

DECLARE

  rfiltros record;
  dfechadesde date;

BEGIN

    EXECUTE sys_dar_filtros($1) INTO rfiltros;

    dfechadesde=rfiltros.fecha;

  CREATE TEMP TABLE temp_actualizacionOSExterna_contemporal
    AS (
        SELECT afilsosunccc as modificado,nrodoc,barra,nombres,apellido,CASE WHEN nullvalue(descrip) then 'NO' else descrip end as obrasocial,
        '1-Modificado#modificado@2-NroDoc#nrodoc@3-Barra#barra@4-Nombres#nombres@5-Apellido#apellido@6-OS#obrasocial'::text as mapeocampocolumna
        FROM persona 
        NATURAL JOIN afilsosunc 
        LEFT JOIN osexterna USING(idosexterna)  
        WHERE afilsosunccc >= dfechadesde 

        ORDER BY modificado
    );
     

return true;
END;
$function$
