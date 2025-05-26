CREATE OR REPLACE FUNCTION public.sys_asistencial_duplicarvalores_configurados(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE

--RECORD
  rfiltros RECORD;
  rasoc RECORD;
  
--CURSORES
  cursorasoc REFCURSOR;
 

--VARIABLES
  parametros varchar;
  rverifica RECORD;
  respuesta varchar;

   
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;


 OPEN cursorasoc FOR SELECT * FROM asocconvenio_igualavalores 
                   WHERE nullvalue(acivfechafin);
	FETCH cursorasoc into rasoc;
	WHILE found LOOP
	--Verifico que exista al menos 1 valor distinto
	SELECT INTO rverifica  idnomenclador,idcapitulo,idsubcapitulo,idpractica,pcvfechainicio,count(*) as cuantas
    FROM practconvval
    JOIN (
		select idsubespecialidad as idnomenclador,idcapitulo,idsubcapitulo,idpractica,importe
 		from practicavalores NATURAL JOIN asocconvenio where idasocconv = rasoc.idasocconvdestino 
		) as t USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)
		NATURAL JOIN practica
 		where idasocconv = rasoc.idasocconvorigen  AND tvvigente
		AND activo
		AND abs(importe - h1 ) > 1 
		GROUP BY idnomenclador,idcapitulo,idsubcapitulo,idpractica,pcvfechainicio;
	IF FOUND THEN	
		RAISE NOTICE 'Hay valores distintos en  : <%> (%)',rverifica.cuantas,rasoc.idasocconvdestino;
		parametros = concat('{ idasocconvorigen=',rasoc.idasocconvorigen,', idvaloricremento=0, idasocconvdestino=',rasoc.idasocconvdestino,' }');
		PERFORM ampractconvval_configura_duplica_valoresfijo(parametros);
		SELECT INTO respuesta * from ampractconvval_configura();
    	RAISE NOTICE 'Termine ampractconvval_configura :  (%)',respuesta;
	ELSE
		RAISE NOTICE 'NO Hay valores distintos en  : (%)',rasoc.idasocconvdestino;
	END IF;
	

fetch cursorasoc into rasoc;
END LOOP;
close cursorasoc;


parametros = concat('{ fechadesde=',current_timestamp,' }');

RAISE NOTICE 'Voy a correr calcularvalorespractica_masivo_completo :  (%)',parametros;
PERFORM calcularvalorespractica_masivo_completo(parametros);

RAISE NOTICE 'Termine :  (%)',parametros;

return respuesta;
END;
$function$
