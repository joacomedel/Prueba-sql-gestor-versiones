CREATE OR REPLACE FUNCTION public.far_actualizarplancoberturamedicamento_otras(pmnroregistro character varying, pidafiliado bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$

DECLARE

/*crear una funcion far_actualizarplancoberturamedicamento_otras que haga lo que actualmente 

hace far_actualizarplancoberturamedicamento pero en lugar de usar plancoberturafarmacia

tiene que usar las tablas far_planboertura */

  	cursorarticulos CURSOR FOR

            SELECT * FROM far_afiliado 

			NATURAL JOIN far_plancobertura

			NATURAL JOIN far_plancoberturaafiliado

			where idafiliado = pidafiliado;

	rarticulo RECORD;

	rta RECORD;

	rplan RECORD;

	resp boolean;

--3544

--SELECT * FROM far_plancoberturamedicamento WHERE idplancobertura = 3544 AND mnroregistro =48136

--SELECT * FROM far_temp_coberturas WHERE idplan = 3544 AND mnroregistro =48136

--far_temp_coberturas

--idafiliado issn 5400

BEGIN

    OPEN cursorarticulos;

    FETCH cursorarticulos into rarticulo;

    WHILE  found LOOP

	--Verifico que el medicamento este en algun plan de cobertura del afiliado

		SELECT INTO rta * FROM far_plancoberturamedicamento 

			WHERE idplancobertura = rarticulo.idplancobertura 

			AND mnroregistro =pmnroregistro;

		IF NOT FOUND THEN 

			--Verifico si es que en realidad no se migro, busco en las tablas temporales

			SELECT INTO rta * FROM far_temp_coberturas 

				WHERE idplan = rarticulo.idplancobertura 

					AND mnroregistro =pmnroregistro;

			IF FOUND THEN 

			-- Lo inserto en nuestras tablas

				INSERT INTO far_plancoberturamedicamento(idplancobertura,mnroregistro,pcmporcentaje,pcmmontofijo,pcmcomentario)

				VALUES(rta.idplan,rta.mnroregistro,rta.coporcentaje,rta.comontofijo,rta.cocomentario);

			END IF;

		ELSE --Esta en plancoberturamedicamento, solo verifico que no cambio

				SELECT INTO rplan * FROM far_temp_coberturas 

				WHERE idplan = rarticulo.idplancobertura 

					AND mnroregistro =pmnroregistro;

			IF (rta.pcmporcentaje <> (rplan.coporcentaje/100)) THEN

			 BEGIN

			      update far_plancoberturamedicamento set pcmfechafin=now()

			      where mnroregistro=pmnroregistro AND idplancobertura = rarticulo.idplancobertura;

			      insert into far_plancoberturamedicamento(idplancobertura,mnroregistro,pcmporcentaje,pcmmontofijo,pcmcomentario)

			      values(rarticulo.idplancobertura,pmnroregistro::integer,rplan.coporcentaje/100,rplan.comontofijo,rplan.cocomentario);

			 END;

		       END IF;

               END IF;

    fetch cursorarticulos into rarticulo;

    END LOOP;

    close cursorarticulos;

return 'true';

END;

$function$
