CREATE OR REPLACE FUNCTION public.cd_cantusuariossouncmovilporlocalidad_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

--Cantidad de usaurios de sosunc movil por centro(del cargo)
CREATE TEMP TABLE temp_cd_cantusuariossouncmovilporlocalidad_contemporal
AS (
	
	 
 --SELECT COUNT(pe.nrodoc) AS cantidad, cr.crdescripcion AS localidad,
--'1-CantidadUsuarios#cantidad@2-Localidad#localidad'::text as mapeocampocolumna 


WITH UltimoCargo AS (
-- Busco todos los cargos y solo filtro por la mas reciente en caso de que tenga dos
 SELECT  nrodoc, iddepen, du.descrip AS descrip_depuni, fechainilab, fechafinlab, iddireccion, l.descrip AS descrip_loc,
     ROW_NUMBER() OVER (PARTITION BY nrodoc ORDER BY fechainilab DESC) as rn --Ordeno los cargos mas recientes primero
         FROM cargo
     NATURAL JOIN depuniversitaria du
     NATURAL JOIN direccion d
     LEFT JOIN localidad l USING (idlocalidad))
-- Busco todos los titulares (usando la direccion de cargo) y pensionados (uso la direccion de persona)






     SELECT COUNT(pe.nrodoc) AS cantidad, uc.descrip_loc as descrip,
'1-CantidadUsuarios#cantidad@2-Localidad#descrip'::text as mapeocampocolumna 

      FROM persona pe
      LEFT JOIN w_usuariorolwebsiges us ON pe.nrodoc = us.dni
      LEFT JOIN w_usuarioafiliado wa ON pe.nrodoc = wa.nrodoc
      JOIN UltimoCargo AS uc ON (uc.nrodoc = pe.nrodoc)
   --    JOIN direccion dp ON (pe.iddireccion = dp.iddireccion AND pe.idcentrodireccion = dp.idcentrodireccion)
   --    LEFT JOIN localidad l ON (dp.idlocalidad = l.idlocalidad)
      LEFT JOIN w_usuarioweb uw ON COALESCE(us.idusuarioweb, wa.idusuarioweb) = uw.idusuarioweb
WHERE  (us.idusuarioweb IS NOT NULL OR  wa.idusuarioweb IS NOT NULL) AND fechafinos >= now()
     AND uc.rn = 1
     AND fechafinos >= now()
     AND (fechafinlab >= now())
GROUP BY uc.descrip_loc
ORDER BY cantidad DESC


  );

return true;
END;
$function$
