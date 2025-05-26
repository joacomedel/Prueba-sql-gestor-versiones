CREATE OR REPLACE FUNCTION public.obtenerdatosfichamedicaauditada_masvalores_2(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
    rtemp type_fichamedicaauditadamasvalores;
	rfiltros RECORD;
	rorden RECORD;
	rconsulta RECORD;
	vparam VARCHAR;
BEGIN
--$1 nroorden, $2 centro, $3 idasocconv,$4 categoria, $5 categoriaapagar,$6 esOdonto
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

vparam = '';
IF iftableexistsparasp('temp_practicavaloresxcategoriahistorico') THEN 
   DELETE FROM temp_practicavaloresxcategoriahistorico;
ELSE 
	CREATE TEMP TABLE temp_practicavaloresxcategoriahistorico AS ( SELECT * FROM practicavaloresxcategoriahistorico LIMIT 0);
	ALTER TABLE temp_practicavaloresxcategoriahistorico ADD COLUMN nroorden bigint;
	ALTER TABLE temp_practicavaloresxcategoriahistorico ADD COLUMN centro INTEGER;
	ALTER TABLE temp_practicavaloresxcategoriahistorico ADD COLUMN iditempractica bigint;
	ALTER TABLE temp_practicavaloresxcategoriahistorico ADD COLUMN idcentroitempractica INTEGER;
	
	

END IF;
SELECT INTO rorden * FROM orden 
					LEFT JOIN itemvalorizada USING(nroorden,centro)
					LEFT JOIN item USING(iditem,centro)
					LEFT JOIN recetario as r ON (nroorden = nrorecetario AND r.centro = orden.centro)
					WHERE orden.nroorden= rfiltros.nroorden AND orden.centro =  rfiltros.centro;
IF FOUND THEN 
	IF nullvalue(rorden.iditem) THEN --No es una orden valorizada

		IF rfiltros.esmedicamento THEN --Es un recetario

			INSERT INTO temp_practicavaloresxcategoriahistorico (idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,iditempractica,idcentroitempractica,nroorden,centro)(

SELECT 	case when not nullvalue(fmpa.idnomenclador) then fmpa.idnomenclador ELSE '98' END as idnomenclador
			,case when not nullvalue(fmpa.idcapitulo) then fmpa.idcapitulo ELSE '01' END as idcapitulo 
			,case when not nullvalue(fmpa.idsubcapitulo) then fmpa.idsubcapitulo ELSE '01' END as idsubcapitulo
			,case when not nullvalue(fmpa.idpractica) then fmpa.idpractica ELSE '01' END as idpractica
			,idrecetarioitem,centro,nroorden,centro
			FROM recetario
            LEFT JOIN recetarioitem USING(nrorecetario,centro) 
			LEFT JOIN orden ON (nrorecetario = orden.nroorden AND recetario.centro = orden.centro)
			LEFT JOIN fichamedicapreauditadaitemrecetario USING(idrecetarioitem,centro) 
			LEFT JOIN fichamedicapreauditada as fmpa USING(idfichamedicapreauditada,idcentrofichamedicapreauditada)
			WHERE nrorecetario = rfiltros.nroorden AND recetario.centro =  rfiltros.centro

			
			);
		
		ELSE -- Es una orden de consulta
		
			SELECT INTO rconsulta * FROM orden 
				LEFT JOIN  fichamedicapreauditadaitemconsulta USING(nroorden,centro) 
				LEFT JOIN fichamedicapreauditada as a USING(idfichamedicapreauditada,idcentrofichamedicapreauditada)
				WHERE orden.nroorden= rfiltros.nroorden AND orden.centro =  rfiltros.centro;
		
		
			IF not nullvalue(rconsulta.idnomenclador) THEN --Si ya esta auditada ya se selecciono la practica
				INSERT INTO temp_practicavaloresxcategoriahistorico (idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,nroorden,centro)
				VALUES(rconsulta.idnomenclador,rconsulta.idcapitulo,rconsulta.idsubcapitulo,rconsulta.idpractica,rfiltros.nroorden,rfiltros.centro);
		
				ELSE
	
					IF rfiltros.esodonto THEN
						INSERT INTO temp_practicavaloresxcategoriahistorico (idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,nroorden,centro)
						VALUES('14','01','01','00',rfiltros.nroorden,rfiltros.centro);
					ELSE
						IF ( nullvalue(rfiltros.categoriaapagar) OR rfiltros.categoriaapagar = '' ) THEN 
							INSERT INTO temp_practicavaloresxcategoriahistorico (idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,nroorden,centro)
							VALUES('12','42','01','01',rfiltros.nroorden,rfiltros.centro);
						ELSE
							INSERT INTO temp_practicavaloresxcategoriahistorico (idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,nroorden,centro)(
								SELECT 	idnomenclador,idcapitulo,idsubcapitulo,idpractica,rfiltros.nroorden,rfiltros.centro
								FROM practica_consultas WHERE  codigoanterior = '12.42.01.01' AND pcategoria = rfiltros.categoriaapagar
								);
						END IF;

					END IF;
		END IF;
		
		
		END IF;
	
	ELSE --Es una orden valorizada
		INSERT INTO temp_practicavaloresxcategoriahistorico (idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,iditempractica,idcentroitempractica,nroorden,centro)(
SELECT DISTINCT
case when not nullvalue(fmpa.idnomenclador) then fmpa.idnomenclador when not nullvalue(pc.idnomenclador) then pc.idnomenclador ELSE i.idnomenclador END as idnomenclador
,case when not nullvalue(fmpa.idcapitulo) then fmpa.idcapitulo when not nullvalue(pc.idcapitulo) then pc.idcapitulo ELSE i.idcapitulo END as idcapitulo 
,case when not nullvalue(fmpa.idsubcapitulo) then fmpa.idsubcapitulo when not nullvalue(pc.idsubcapitulo) then pc.idsubcapitulo ELSE i.idsubcapitulo END as idsubcapitulo
,case when not nullvalue(fmpa.idpractica) then fmpa.idpractica  when not nullvalue(pc.idpractica) then pc.idpractica ELSE i.idpractica END as idpractica
			,iditem,centro,nroorden,centro
			FROM  orden 
			LEFT JOIN itemvalorizada USING(nroorden,centro)
			LEFT JOIN item as i USING(iditem,centro)
                        LEFT JOIN practica_consultas as pc ON codigoanterior = concat(i.idnomenclador,'.',i.idcapitulo,'.',i.idsubcapitulo,'.',i.idpractica) AND pcategoria = rfiltros.categoriaapagar
			LEFT JOIN fichamedicapreauditadaitem USING(iditem,centro,nroorden)
			LEFT JOIN fichamedicapreauditada as fmpa USING(idcentrofichamedicapreauditada,idfichamedicapreauditada) 
			WHERE orden.nroorden= rfiltros.nroorden AND orden.centro =  rfiltros.centro

);
	END IF;

END IF;

UPDATE temp_practicavaloresxcategoriahistorico SET idasocconv = rfiltros.idasocconv;

IF rfiltros.convigencia THEN
    vparam = concat('{cuantos=1, vigencia =',rorden.fechaemision,'}');
	--PERFORM obtenerdatosfichamedicaauditada_masvalores_histo('{cuantos=4,vigencia = ',rorden.fechaemision,'}'); --Siempre trae el actual y los siguientes cuentos - 1
ELSE 
	vparam = concat('{cuantos=4, vigencia=null}');
	--PERFORM obtenerdatosfichamedicaauditada_masvalores_histo('{cuantos=4}'); --Siempre trae el actual y los siguientes cuentos - 1

END IF;

RAISE NOTICE 'Llamo  a obtenerdatosfichamedicaauditada_masvalores_histo con (%)',vparam;
PERFORM obtenerdatosfichamedicaauditada_masvalores_histo(vparam); 
--No borro mas aqui, borro solo si inserto el valor
--DELETE FROM temp_practicavaloresxcategoriahistorico WHERE nullvalue(importe); --Limpio la tupla que se inserto para buscar los historicos


    RETURN pfiltros;
END
$function$
