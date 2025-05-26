CREATE OR REPLACE FUNCTION public.sys_revertir_incremento_valores_practicas(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$declare
     rfiltros RECORD;
	 rfechacambios RECORD;
	 rcontrol RECORD;
     vidnomenclador varchar;
	 practicavaloresxcategoria_count INTEGER;
	 practicavaloresxcategoriahistorico_count INTEGER;
	 practicavaloresmodificados_count INTEGER;
	 practicavalores_count INTEGER;
	 respuesta varchar;
BEGIN
--select sys_revertir_incremento_valores_practicas('{ idasocconv=129, codigo=14.**.**.**, solover=true }');
--select sys_revertir_incremento_valores_practicas('{ idasocconv=129, codigo=14.**.**.**, solover=false }');
--MaLaPi 01-11-2021 No eliminar en practconval, eso hay que hacerlo a mano usar el campo pcvsis

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
--{ idasocconv=129, codigo=14.**.**.**, solover= true }

vidnomenclador = split_part(rfiltros.codigo,'.',1);

--Para saber el Timeestamp en el que se generaron los cambios
Select INTO rfechacambios *  from practicavaloresxcategoriahistorico 
							 where idasocconv = rfiltros.idasocconv  AND nullvalue(pvxchfechafin) 
							 AND idsubespecialidad = vidnomenclador 
							 ORDER BY pvxchfechaini DESC
							 LIMIT 1;
							 
--Select pvxchfechaini  from practicavaloresxcategoriahistorico where idasocconv = 129  AND nullvalue(pvxchfechafin) AND idsubespecialidad = '14';							 
--pvxchfechaini

RAISE NOTICE 'La fecha de cambio en Timestamp es % y el nomenclador % de la asociacion %.',rfechacambios.pvxchfechaini,vidnomenclador,rfiltros.idasocconv;

respuesta = concat(respuesta,'* ','La fecha de cambio en Timestamp es ',rfechacambios.pvxchfechaini,' y el nomenclador ',vidnomenclador,' de la asociacion ',rfiltros.idasocconv,'. ');

SELECT INTO rcontrol COUNT(*) as cantidad FROM practicavaloresxcategoria 
WHERE importe > 0.01 AND (idcapitulo,idsubcapitulo,idpractica,idsubespecialidad,idasocconv,pcategoria,internacion) IN 
(SELECT idcapitulo,idsubcapitulo,idpractica,idsubespecialidad,idasocconv,pcategoria,internacion
FROM practicavaloresxcategoriahistorico
WHERE idasocconv = rfiltros.idasocconv and idsubespecialidad = vidnomenclador 
	  AND importe > 0.01 AND pvxchfechaini=rfechacambios.pvxchfechaini
);

RAISE NOTICE 'Voy a Modificar en practicavaloresxcategoria % tuplas.',rcontrol.cantidad;
respuesta = concat(respuesta,'* ','Voy a Modificar en practicavaloresxcategoria ',rcontrol.cantidad,' tuplas.','. ');

IF (not rfiltros.solover) THEN 
--Para que quede vigente el de Categorias
	UPDATE practicavaloresxcategoria SET importe= t.importe, pvxcfechaini = t.pvxchfechaini ,pvxcfechainivigencia = t.pvxchfechainivigencia
	FROM (SELECT pvxchfechaini,idcapitulo,idsubcapitulo,idpractica,idsubespecialidad,importe,idasocconv,pcategoria,internacion,pvxchfechainivigencia
	FROM practicavaloresxcategoriahistorico
	WHERE idasocconv = rfiltros.idasocconv and idsubespecialidad = vidnomenclador 
	  	AND importe > 0.01 AND pvxchfechaini=rfechacambios.pvxchfechaini
	 	) as t
	WHERE practicavaloresxcategoria.importe > 0.01 
	    AND practicavaloresxcategoria.idcapitulo = t.idcapitulo 
		AND practicavaloresxcategoria.idsubcapitulo = t.idsubcapitulo 
		AND practicavaloresxcategoria.idpractica= t.idpractica 
		AND practicavaloresxcategoria.idsubespecialidad = t.idsubespecialidad
		AND practicavaloresxcategoria.idasocconv = t.idasocconv 
		AND practicavaloresxcategoria.pcategoria = t.pcategoria 
		AND practicavaloresxcategoria.internacion = t.internacion;
	
	GET DIAGNOSTICS practicavaloresxcategoria_count = ROW_COUNT;
	
RAISE NOTICE 'Entre y Mofifique en practicavaloresxcategoria % tuplas.',practicavaloresxcategoria_count;

respuesta = concat(respuesta,'* ','Entre y Mofifique en practicavaloresxcategoria ',practicavaloresxcategoria_count,' tuplas','. ');

END IF;

--Para que quede vigente el de expendio
SELECT INTO rcontrol COUNT(*) as cantidad 
FROM practicavalores 
WHERE importe > 0.01 AND (idcapitulo,idsubcapitulo,idpractica,idsubespecialidad,idasocconv,internacion) IN 
(SELECT idcapitulo,idsubcapitulo,idpractica,idsubespecialidad,idasocconv,internacion
FROM practicavaloresxcategoriahistorico
WHERE idasocconv = rfiltros.idasocconv and idsubespecialidad = vidnomenclador 
	  AND importe > 0.01 AND pvxchfechaini=rfechacambios.pvxchfechaini
);

RAISE NOTICE 'Voy a Modificar en practicavalores  % tuplas.',rcontrol.cantidad;
respuesta = concat(respuesta,'* ','Voy a Modificar en practicavalores ',rcontrol.cantidad,' tuplas.','. ');

IF (not rfiltros.solover) THEN 
	UPDATE practicavalores SET importe= t.importe, pvfechainivigencia = t.pvxchfechainivigencia
	FROM (SELECT pvxchfechaini,idcapitulo,idsubcapitulo,idpractica,idsubespecialidad,importe,idasocconv,pcategoria,internacion,pvxchfechainivigencia
	FROM practicavaloresxcategoriahistorico
	WHERE idasocconv = rfiltros.idasocconv and idsubespecialidad = vidnomenclador  
	  	AND importe > 0.01 AND pvxchfechaini=rfechacambios.pvxchfechaini AND pcategoria = 'A'
 	) as t
	WHERE practicavalores.importe > 0.01 
		AND practicavalores.idcapitulo = t.idcapitulo 
		AND practicavalores.idsubcapitulo = t.idsubcapitulo 
		AND practicavalores.idpractica= t.idpractica 
		AND practicavalores.idsubespecialidad = t.idsubespecialidad 
		AND practicavalores.idasocconv = t.idasocconv 
		AND  practicavalores.internacion = t.internacion;

GET DIAGNOSTICS practicavalores_count = ROW_COUNT;
	
RAISE NOTICE 'Entre y Mofifique en practicavalores % tuplas.',practicavalores_count;
respuesta = concat(respuesta,'* ','Entre y Mofifique en practicavalores ',practicavalores_count,' tuplas','. ');

END IF;

SELECT INTO rcontrol count(*) as cantidad 
		FROM practicavaloresxcategoriahistorico
		WHERE idasocconv = rfiltros.idasocconv and idsubespecialidad = vidnomenclador 
				AND importe > 0.01 AND pvxchfechaini=rfechacambios.pvxchfechaini 
				AND nullvalue(pvxchfechafin);
	
	RAISE NOTICE 'Voy a eliminar en practicavaloresxcategoriahistorico  % tuplas.',rcontrol.cantidad;
	respuesta = concat(respuesta,'* ','Voy a eliminar en practicavaloresxcategoriahistorico ',rcontrol.cantidad,' tuplas.','. ');

IF (not rfiltros.solover) THEN 
	--Se elimina el incremento que no va
		DELETE from practicavaloresxcategoriahistorico 
			WHERE idasocconv = rfiltros.idasocconv and idsubespecialidad = vidnomenclador 
				AND importe > 0.01 AND pvxchfechaini=rfechacambios.pvxchfechaini 
				AND nullvalue(pvxchfechafin);
	--Quedan como vigentes en el historio los anteriores
		UPDATE practicavaloresxcategoriahistorico SET pvxchfechafin = null 
			WHERE idasocconv = rfiltros.idasocconv and idsubespecialidad = vidnomenclador  AND importe > 0.01  
			AND pvxchfechafin = rfechacambios.pvxchfechaini;
	

		GET DIAGNOSTICS practicavaloresxcategoriahistorico_count = ROW_COUNT;
		RAISE NOTICE 'Entre y Mofifique en practicavaloresxcategoriahistorico % tuplas.',practicavalores_count;
        respuesta = concat(respuesta,'* ','Entre y Mofifique en practicavaloresxcategoriahistorico ',practicavaloresxcategoriahistorico_count,' tuplas','. ');
END IF;

	SELECT INTO rcontrol count(*) as cantidad 
		FROM practicavaloresmodificados
		where idasocconv = rfiltros.idasocconv and idsubespecialidad = vidnomenclador 
			AND importe > 0.01  AND fechamodif = rfechacambios.pvxchfechaini;
	
	RAISE NOTICE 'Voy a eliminar en practicavaloresmodificados  % tuplas.',rcontrol.cantidad;
	respuesta = concat(respuesta,'* ','Voy a eliminar en practicavaloresmodificados ',rcontrol.cantidad,' tuplas.','. ');	
		
IF (not rfiltros.solover) THEN 
		DELETE from practicavaloresmodificados 
			where idasocconv = rfiltros.idasocconv and idsubespecialidad = vidnomenclador 
			AND importe > 0.01  AND fechamodif = rfechacambios.pvxchfechaini;

		GET DIAGNOSTICS practicavaloresmodificados_count = ROW_COUNT;
		RAISE NOTICE 'Entre y Mofifique en practicavaloresmodificados % tuplas.',practicavaloresmodificados_count;
		respuesta = concat(respuesta,'* ','Entre y Mofifique en practicavaloresmodificados ',practicavaloresmodificados_count,' tuplas','. ');
END IF;


return respuesta;
END;
$function$
