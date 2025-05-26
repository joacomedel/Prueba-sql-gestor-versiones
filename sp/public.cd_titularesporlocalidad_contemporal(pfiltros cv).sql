CREATE OR REPLACE FUNCTION public.cd_titularesporlocalidad_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

--Cantidad de titulares por localidad
--el criterio de localidad hace referencia solicitado por MD es el del cargo
CREATE TEMP TABLE temp_cd_titularesporlocalidad_contemporal
AS (

	WITH UltimoCargo AS (
-- Busco todos los cargos y solo filtro por la mas reciente en caso de que tenga dos
   SELECT  nrodoc, iddepen, du.descrip AS descrip_depuni, fechainilab, fechafinlab, iddireccion, l.descrip AS descrip_loc,
       ROW_NUMBER() OVER (PARTITION BY nrodoc ORDER BY fechainilab DESC) as rn --Ordeno los cargos mas recientes primero
           FROM cargo
       NATURAL JOIN depuniversitaria du
       NATURAL JOIN direccion d
       LEFT JOIN localidad l USING (idlocalidad)
)
-- Busco todos los titulares (usando la direccion de cargo) y pensionados (uso la direccion de persona)
SELECT /*COUNT(*) AS */cantidad, tipobarra, descrip_loc,
	
	  '1-CantidadTitulares#cantidad@2-TipoBarra#tipobarra@3-Localidad#descrip_loc'::text as mapeocampocolumna 
	FROM (
   SELECT  COUNT(*) AS cantidad, bt.bttitulo AS tipobarra, descrip_loc
       FROM persona AS pe JOIN UltimoCargo AS uc ON (uc.nrodoc = pe.nrodoc)
       JOIN nrobarratipo AS nbt ON nbt.nrobarra = pe.barra
       NATURAL JOIN barratipo AS bt
   WHERE uc.rn = 1
       AND fechafinos >= now()
       AND (fechafinlab >= now() OR pe.barra = 35)
       AND bt.idbarratipo NOT IN (1, 2, 11, 12, 13)
   GROUP BY tipobarra, descrip_loc
       UNION
   SELECT COUNT(*) AS cantidad, bt.bttitulo AS tipobarra, l.descrip AS descrip_loc
       FROM persona AS pe
           JOIN nrobarratipo AS nbt ON nbt.nrobarra = pe.barra
           NATURAL JOIN barratipo AS bt
           JOIN direccion dp ON (pe.iddireccion = dp.iddireccion AND pe.idcentrodireccion = dp.idcentrodireccion)
           LEFT JOIN localidad l ON (dp.idlocalidad = l.idlocalidad)
       WHERE fechafinos >= now()
       AND bt.idbarratipo = 9
   GROUP BY tipobarra, l.descrip
) AS resultado ORDER BY tipobarra DESC

	
/* 
SELECT COUNT(*) AS cantidad, descrip,
	  '1-CantidadCargos#cantidad@2-Descripcion#descrip'::text as mapeocampocolumna 
		
   FROM UltimoCargo
   WHERE rn = 1  --Me quedo con los cargos más recientes
       GROUP BY iddepen, descrip
*/
  );

return true;
END;
$function$
