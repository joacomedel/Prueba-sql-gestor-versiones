CREATE OR REPLACE FUNCTION public.amtablavaloresv2()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Ingresa o Actualiza la tabla de valores de un convenio
amtablavalores()
*/
DECLARE
	
	elem RECORD;
        alta refcursor; 
	resultado boolean;
        aux RECORD;
        vtipodato varchar;
        vidconvenio varchar;
	
BEGIN

IF NOT existecolumtemp('temptablavalores','idtablavalor') THEN
    ALTER TABLE temptablavalores ADD COLUMN idtablavalor BIGINT;
END IF;

SELECT INTO vtipodato pg_typeof("idconvenio")  from temptablavalores limit 1;

IF vtipodato ilike '%character varying%' THEN

ALTER TABLE temptablavalores ALTER COLUMN idconvenio TYPE INTEGER USING idconvenio::integer;

END IF;
OPEN alta FOR SELECT * FROM temptablavalores 
                       ORDER BY temptablavalores.idconvenio,
                             temptablavalores.idtipounidad;
FETCH alta INTO elem;
WHILE  found LOOP

vidconvenio = elem.idconvenio;

--RAISE NOTICE 'amtablavaloresv2: voy a procesar (%)',elem;  

IF elem.valor::double precision	<> 0 THEN 

    IF elem.pcategoria = 'A' THEN 
       IF (elem.accion = 'Eliminar' ) THEN
             /*Se debe dar de baja el valor ingresado*/
                       UPDATE tablavalores SET tvfinvigencia = CURRENT_DATE
                                              WHERE  tablavalores.idtablavalor = elem.idtablavalor
                                                    AND idtipounidad = elem.idtipounidad
                                              AND nullvalue(tablavalores.tvfinvigencia);
       END IF;
       
       IF (elem.accion = 'Modificar' OR elem.accion = 'Agregar') THEN

            --RAISE NOTICE 'amtablavaloresv2: Accion es Agregar o modificar (%)',elem;  
             SELECT INTO aux * FROM tablavalores 
                               WHERE tablavalores.idtablavalor = elem.idtablavalor
                               AND idtipounidad = elem.idtipounidad
                                   AND nullvalue(tablavalores.tvfinvigencia);
          IF NOT FOUND OR aux.idtipovalor <> elem.valor::double precision THEN 

              -- RAISE NOTICE 'amtablavaloresv2: el valor de aux es distinto (%)',aux; 
              UPDATE tablavalores SET tvfinvigencia = CURRENT_DATE
                                   WHERE  tablavalores.idtablavalor = elem.idtablavalor
                                   AND idtipounidad = elem.idtipounidad
                                   AND nullvalue(tablavalores.tvfinvigencia);
              INSERT INTO tablavalores (idconvenio,idtablavalor,idtipounidad,idtipovalor,tvinivigencia)
              VALUES (elem.idconvenio,nextval('tablavalores_idtablavalor_seq'),elem.idtipounidad,elem.valor::double precision,elem.fechainiciovigencia::date);
             
               UPDATE temptablavalores SET idtablavalor = currval('tablavalores_idtablavalor_seq') 
                                      WHERE  idtipounidad = elem.idtipounidad;

              RAISE NOTICE 'amtablavaloresv2: Inserto el idtablavalor (%)',currval('tablavalores_idtablavalor_seq');  

          END IF; /*aux.idtipovalor <> elem.idtipovalor*/
      END IF; /*(elem.accion = 'Modificar' )*/ 
 
--IF (elem.accion = 'Agregar' ) THEN
--              INSERT INTO tablavalores (idconvenio,idtablavalor,idtipounidad,idtipovalor,tvinivigencia)
--              VALUES (elem.idconvenio::integer,nextval('tablavalores_idtablavalor_seq'),elem.idtipounidad,elem.valor::double precision,elem.fechainiciovigencia::date);
--              UPDATE temptablavalores SET idtablavalor = currval('tablavalores_idtablavalor_seq')
--                                       WHERE (idtablavalor = elem.idtablavalor OR nullvalue(elem.idtablavalor))
--                                            AND idtipounidad = elem.idtipounidad;
--      END IF; --(elem.accion = 'Agregar' )

    END IF; /*elem.pcategoria = 'A'*/ 
    
END IF; /*FOUND AND elem.idtipovalor <> 0*/

--MaLaPi 13-01-2023 Modifico para ir guardando un historico en practconvval cuando se cambia el valor de una unidad
--MaLaPi 19-07-2023 lo comento, pues cuando se actualizan las unidades de todas las practicas se rompe la configuracion historica. 
--Lo dejo en el SP convenios_migrarnomencladoryvalores_valoresunida para que se corra luego de actualizar el valor de todas
--PERFORM amtablavaloresv2_practconvval(concat('{ idconvenio=',vidconvenio,' }'));


FETCH alta INTO elem;
END LOOP;
CLOSE alta;

SELECT INTO resultado * FROM amtablavaloresxcategoria();


--MaLaPi 13-01-2023 Modifico para ir guardando un historico en practconvval cuando se cambia el valor de una unidad
--PERFORM amtablavaloresv2_practconvval(concat('{ idconvenio=',vidconvenio,' }'));

--MaLaPi 18-11-2021 Modifico la vigencia en las tablas que usan las unidades

--UPDATE practconvval SET pcvfechamodifica = now(),pcvfechainicio = t.fechainiciovigencia
--FROM (
--SELECT fechainiciovigencia::date ,p.*  
--FROM tablavalores
--JOIN temptablavalores USING(idconvenio,idtipounidad,idtablavalor)
--NATURAL JOIN convenio
--NATURAL JOIN asocconvenio as ac
--JOIN practconvval as p ON p.idasocconv = ac.idasocconv  AND p.tvvigente 
--                    AND (not p.fijoh1 AND p.h1 = tablavalores.idtipounidad OR not p.fijoh2 AND p.h2 = tablavalores.idtipounidad OR not p.fijoh3 AND p.h3 = --tablavalores.idtipounidad
--OR not p.fijoh3 AND p.h3 = tablavalores.idtipounidad 
--OR not p.fijogs AND p.gasto = tablavalores.idtipounidad
--OR not p.fijogasto2 AND p.gasto2 = tablavalores.idtipounidad
--OR not p.fijogasto3 AND p.gasto3 = tablavalores.idtipounidad
--OR not p.fijogasto4 AND p.gasto4 = tablavalores.idtipounidad
--OR not p.fijogasto5 AND p.gasto5 = tablavalores.idtipounidad
--)
--WHERE fechainiciovigencia <> p.pcvfechainicio
--                               AND (nullvalue(convenio.cfinvigencia) OR convenio.cfinvigencia > CURRENT_DATE)
--                               AND (nullvalue(ac.acfechafin) OR ac.acfechafin > CURRENT_DATE)
--                               AND (nullvalue(tablavalores.tvfinvigencia) OR tablavalores.tvfinvigencia > CURRENT_DATE)
--) as t
--WHERE practconvval.idpractconvval = t.idpractconvval 
--     AND practconvval.idasocconv = t.idasocconv 
--     AND practconvval.idsubcapitulo = t.idsubcapitulo
--     AND practconvval.idcapitulo = t.idcapitulo 
--     AND practconvval.idpractica = t.idpractica 
--     AND practconvval.idnomenclador = t.idnomenclador 	;

RETURN resultado;
END;$function$
