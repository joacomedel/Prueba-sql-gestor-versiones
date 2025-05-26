CREATE OR REPLACE FUNCTION public.sys_modifcar_coberturas_medicamento(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE 
/********************************************************************************************************************************/
/****************    OJO en la tabla medicamento_modificar_cobertura manuevomultiplicador DEBE SER INTEGER si es 0.4 PONER 40 */
/********************************************************************************************************************************/




        -- 1 - Busco las monodrogas vinculadas a los medicamentos informados
  	cursormono CURSOR FOR SELECT DISTINCT 
 idmonodroga,monnombre,multiplicador,mafechaproceso,round((manuevomultiplicador/100.0)::numeric,2) as nuevacobertura 
--idmonodroga,monnombre,drogas_mas_asociaciones,droga,nombre_comercial,multiplicador,mafechaproceso,round((manuevomultiplicador/100.0)::numeric,2) as nuevacobertura 
					FROM (SELECT idmonodroga,monnombre,drogas_mas_asociaciones,droga,nombre_comercial,manuevomultiplicador,mafechaproceso
					      FROM medicamento_modificar_cobertura
					      JOIN medicamento ON codalfabeta = mnroregistro
					      JOIN manextra USING (mnroregistro)
					      JOIN monodroga USING (idmonodroga)
                                              WHERE  nullvalue(mafechaproceso)
					) as paracambiar
					LEFT JOIN (SELECT * 
                                                   FROM plancoberturafarmacia 
                                                   WHERE nullvalue(fechafinvigencia)
                                        ) as plancoberturafarmacia USING(idmonodroga)
					WHERE multiplicador <> round((manuevomultiplicador/100.0)::numeric,2);

	rmono RECORD;
        rverifica RECORD;
	rfiltros RECORD;

BEGIN  

        -- recupero los parameros si modo = verificar y hay medicamentos que tienen como monodroga alguna de las informadas en los medicamentos para actualizar su cobertura, y el medicamento NO  se informo se produce una excepcion
         -- si el modo = procesar no se produce la excepcion y se actualiza la cobertura de todos los medicamentos que tienen como monodroga alguna de las informadas
         EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
  -- Para enviar a quien solicito la actualizacion de la cobertura que hay otros medicamentos que tambien seran modificados
       IF FOUND AND NOT rfiltros.procesar THEN 

         --MaLaPi 27-01-2023 Verifico que no quede ningun medicamento con igual monodroga y distinta cobertura sin informar, si queda alguno, hay que solicitar que se verifique
         -- La siguiente consulta retorna los medicamentos vinculados a algunas de las monodrogas de los medicamentos informados pero que no se encontraban en la planilla original.
         SELECT  INTO rverifica mnroregistro,nomenclado,idmonodroga,monnombre as droga_siges,idlaboratorio,mtroquel,mcodbarra,concat(mnombre,' ',mpresentacion) as nombrecomercial_siges,vdescripcion,fdescripcion
,multiplicador
         FROM manextra 
         NATURAL JOIN medicamento
         NATURAL JOIN vias
         NATURAL JOIN formas
         NATURAL JOIN monodroga
         JOIN plancoberturafarmacia USING(idmonodroga)
         LEFT JOIN (SELECT codalfabeta::integer as mnroregistro 
                    FROM medicamento_modificar_cobertura 
                    WHERE nullvalue(mafechaproceso)
         ) as medicamento_modificar_cobertura  USING(mnroregistro)
         WHERE  NOT nullvalue(mcodbarra) --VAS se agrega la condicion 15-05-2023
                AND nullvalue(fechafinvigencia) 
                AND nullvalue(medicamento_modificar_cobertura.mnroregistro)
                AND idmonodroga IN (SELECT idmonodroga
				    FROM (	SELECT idmonodroga,monnombre,drogas_mas_asociaciones,droga,nombre_comercial,manuevomultiplicador,mafechaproceso
						FROM medicamento_modificar_cobertura
						JOIN medicamento ON codalfabeta = mnroregistro
						JOIN manextra USING (mnroregistro)
						JOIN monodroga USING (idmonodroga)
                                                WHERE  nullvalue(mafechaproceso)
		                     ) as paracambiar
                                     LEFT JOIN (SELECT * 
                                                FROM plancoberturafarmacia 
                                                WHERE nullvalue(fechafinvigencia)
                                     ) as plancoberturafarmacia USING(idmonodroga)
				     WHERE multiplicador <> round((manuevomultiplicador/100.0)::numeric,2)
                                     )
         ORDER BY idmonodroga;
      
                    RAISE EXCEPTION 'R-001, Existe al menos 1 medicamento que hay que controlar, sacar el excel usando la consulta.  %',rverifica;

          END IF;
 
         --MaLaPi 25-01-2023 Siempre que se tocan las coberturas, lo mejor es limpiar la tabla base que se usa para observer

         DELETE FROM sys_cobertura_farmacia;

         UPDATE medicamento_modificar_cobertura 
         SET mafechaproceso = now(),maerror=' Error, No se encontro la monodroga para el medicamento ' 
         WHERE (nullvalue(codalfabeta) OR codalfabeta = 'NULL') AND  nullvalue(mafechaproceso);

         UPDATE  medicamento_modificar_cobertura 
         SET idmonodrogaalfabeta = idmonodroga 
         FROM ( SELECT idmonodroga,mnroregistro,monnombre,drogas_mas_asociaciones,droga,nombre_comercial,manuevomultiplicador,mafechaproceso
                FROM medicamento_modificar_cobertura
                JOIN medicamento ON codalfabeta = mnroregistro
                JOIN manextra USING (mnroregistro)
                JOIN monodroga USING (idmonodroga)
         ) as t
          WHERE t.mnroregistro = medicamento_modificar_cobertura.codalfabeta
                AND nullvalue(idmonodrogaalfabeta)
                AND  nullvalue(medicamento_modificar_cobertura.mafechaproceso);

    OPEN cursormono;
    FETCH cursormono INTO rmono;
    WHILE  found LOOP
	
	    IF rmono.nuevacobertura = rmono.multiplicador THEN --- Analizo si hay un cambio de cobertura en el medicamento
			UPDATE medicamento_modificar_cobertura 
                        SET mafechaproceso = now(),maerror=' Error, No esta cambiando la Cobertura, es la misma' 
			WHERE idmonodrogaalfabeta = rmono.idmonodroga AND nullvalue(mafechaproceso); 
	    ELSE
                        -- Registro el cambio en la cobertura de la monodroga 
			UPDATE plancoberturafarmacia SET fechafinvigencia = now() 
			WHERE idmonodroga = rmono.idmonodroga AND nullvalue(fechafinvigencia);
           	        -- Ingreso la nueva cobertura de la monodroga
                        INSERT INTO plancoberturafarmacia(idmonodroga,fechafinvigencia,multiplicador)
           	        VALUES (rmono.idmonodroga,null,rmono.nuevacobertura);
			
                        -- Registro como actualizado el medicamento informado 
			UPDATE medicamento_modificar_cobertura SET mafechaproceso = now() 
                        WHERE idmonodrogaalfabeta = rmono.idmonodroga AND nullvalue(mafechaproceso); 
		END IF;	
          
    FETCH cursormono into rmono;
    END LOOP;
    close cursormono;

return 'true';
END;
$function$
