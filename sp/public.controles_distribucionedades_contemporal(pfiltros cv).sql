CREATE OR REPLACE FUNCTION public.controles_distribucionedades_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_controles_distribucionedades_contemporal 
AS (
	SELECT afiliado,rango,sexo,descrip as localidad,count(nrodoc) as cantidad
        ,'1-Tipo Afiliado#afiliado@2-Rango#rango@3-Genero#sexo@4-Localidad#localidad@4-Cantidad#cantidad'::text as mapeocampocolumna
	FROM (
	     SELECT 'beneficiarios'as afiliado,nrodoc,(extract(YEAR FROM age(fechanac)) :: integer / rfiltros.rango) * rfiltros.rango as rango,barra,sexo,idlocalidad
	     FROM persona
	     Natural JOIN benefsosunc
	     LEFT JOIN direccion USING(iddireccion,idcentrodireccion)
	     WHERE persona.fechafinos>=current_date
	     UNION
	     SELECT 'titulares' as afiliado,nrodoc,(extract(YEAR FROM age(fechanac)) :: integer / rfiltros.rango) * rfiltros.rango as rango,barra,sexo,idlocalidad
	     FROM persona
	     NATURAL JOIN afilsosunc
	     LEFT JOIN direccion USING(iddireccion,idcentrodireccion)
	     WHERE persona.fechafinos>=current_date
	) as t
        LEFT JOIN localidad USING(idlocalidad)
	GROUP BY afiliado,sexo,rango,descrip
	ORDER BY rango

);
  

return true;
END;
$function$
