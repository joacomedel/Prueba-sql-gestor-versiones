CREATE OR REPLACE FUNCTION public.listado_permisos_usuario_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

-- GK 16-05-2022 - Agrego fecha facturación
-- GK 17-10-2022 - Cambios solicitados por usuario importe total / unitario y diferentes coberturas
CREATE TEMP TABLE temp_listado_permisos_usuario_contemporal
AS (
	SELECT *,
	  --,'1-Edad#edad@2-Nombres#nombres@3-Apellido#apellido@4-Nrodoc#nrodoc@5-Nomenclador#idsubespecialidad@6-Capitulo#idcapitulo@7-SubCapitulo#idsubcapitulo@8-Practica#idpractica@4-Nombre#pdescripcion@4-Plan Cobertura#descripcion@4-Centro Regional#cregional@4-Asoc.#acdecripcion@4-Importe#importe@4-Cantidad#cantidad'::text as mapeocampocolumna 
	  '1-Principal#Principal@2-Modulo#Modulo@3-Submodulo#Submodulo@4-Item#Item'::text as mapeocampocolumna 
	FROM (
			SELECT  

smdescripcion as "Principal", descripcion as "Modulo", mdescripcion as "Submodulo", tdescripcion as "Item"

	FROM admitem
		NATURAL JOIN admmenu as am
		NATURAL JOIN modulo as m
		NATURAL JOIN admsupramenumodulo
		JOIN usuario_admitem USING(iditem)
                left join admsupramenu as sm on (admsupramenumodulo.idsupramenu = sm.idsupramenu)

		WHERE nullvalue(uaifechafin)
			AND (idusuario = rfiltros.idusuario)
--and sm.idsupramenu = 6

order by sm.idsupramenu, descripcion, morden, iorden  asc ) as tpermisos
	

);
  

return true;
END;$function$
