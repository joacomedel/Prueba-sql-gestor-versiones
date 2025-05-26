CREATE OR REPLACE FUNCTION public.cd_facturacionturismo_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 --cantidad de consumos de turismo en cada administrador apartir de una fecha dada

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
CREATE TEMP TABLE temp_cd_facturacionturismo_contemporal
AS (
	SELECT *,
	  '1-IdPrestamo#idprestamo@2-IdConsumoTurismo#idconsumoturismo@3-FechaPrestamo#fechaprestamo@4-ImporteAfiliado#importeconsumoturismo@5-CantidadDias#cantdias@6-Destino#destino@7-Prestador#prestador@8-MinutaPago#nrominutapago@9-ImportePrestador#importeprestador'::text as mapeocampocolumna 
	FROM (
			
		select  
          idprestamo, idconsumoturismo,fechaprestamo,
          importeprestamo as importeconsumoturismo
		  , cantdias,pnombrefantasia as destino,pdescripcion as prestador 
		  ,nroordenpago as nrominutapago ,ctopimportepagado as importeprestador

		from consumoturismo
		natural join consumoturismoordenpago
		natural join  consumoturismoestado
		natural join prestamo
		natural join  ordenpago
		natural join  ordenpagoprestador
		join   prestador using(idprestador)

			where 
  			idconsumoturismoestadotipos<>3	and nullvalue(ctefechafin)
			and fechaprestamo>=rfiltros.fechaprestamo
		order by idprestador,fechaprestamo
	) as resumenfacturacion 
);
  

return true;
END;
$function$
