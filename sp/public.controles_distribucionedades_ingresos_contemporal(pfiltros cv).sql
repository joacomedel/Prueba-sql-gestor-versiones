CREATE OR REPLACE FUNCTION public.controles_distribucionedades_ingresos_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_controles_distribucionedades_ingresos_contemporal 
AS (
	SELECT afiliado,rango,sexo,count(nrodoc) as cantidad,idcateg,sum(importe) as aportes
        ,'1-Tipo Afiliado#afiliado@2-Rango#rango@3-Genero#sexo@4-Cantidad#cantidad@5-Categ.#idcateg@6-Monto Aportes#aportes'::text as mapeocampocolumna
	FROM (
	     SELECT 'beneficiarios'as afiliado,nrodoc,(extract(YEAR FROM age(fechanac)) :: integer / rfiltros.rango) * rfiltros.rango as rango,barra,sexo,'Beneficirio' as idcateg,0 as importe
	     FROM persona
	     Natural JOIN benefsosunc
	     WHERE persona.fechafinos>=current_date
	     UNION
	     SELECT 'titulares' as afiliado,nrodoc,(extract(YEAR FROM age(fechanac)) :: integer / rfiltros.rango) * rfiltros.rango as rango,barra,sexo,CASE WHEN nullvalue(idcateg) THEN 'Sin Aportes' ELSE idcateg END,importe
	     FROM persona
	     NATURAL JOIN afilsosunc
	     LEFT JOIN (SELECT idcateg,importe,nrodoc,tipodoc
			FROM cargo JOIN dh21 ON idcargo = nrocargo 
			WHERE mesingreso >= extract('MONTH' FROM current_date - 30::integer ) 
			AND anioingreso >= extract('YEAR' FROM current_date - 30::integer ) 
			AND (nroconcepto = 311 OR  nroconcepto = 202) 
			) as infoaporte USING(nrodoc,tipodoc)
	     --WHERE persona.fechafinos>=current_date - 30::integer
	) as t
	GROUP BY afiliado,idcateg,sexo,rango
	ORDER BY rango
--;

);
  

return true;
END;
$function$
