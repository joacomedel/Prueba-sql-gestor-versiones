CREATE OR REPLACE FUNCTION public.far_ingresar_medciamento_inst(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE


--Busco padre articulo INSTITUCIONAL 

exito boolean;
--CURSORES

-- RECORD 
rparam RECORD;

padrekairo RECORD;

medinstcontrol RECORD;

medinst RECORD;

maxnroregistro RECORD;

BEGIN
	EXECUTE sys_dar_filtros($1) INTO rparam;  
	exito=false;

	SELECT INTO maxnroregistro  max(mnroregistro)+1 as mnroregistroinst
	FROM medicamento;

	SELECT INTO medinst * 
	FROM far_articulo
	WHERE acodigobarra=rparam.mcodbarra;

	IF FOUND THEN 
		
		SELECT INTO medinstcontrol * 
		FROM medicamento
		LEFT JOIN manextra USING (mnroregistro,nomenclado)
		WHERE mcodbarra=rparam.mcodbarra AND nomenclado=false;

		IF NOT FOUND THEN 

			SELECT INTO padrekairo * 
			FROM medicamento
			LEFT JOIN manextra USING (mnroregistro,nomenclado)
			WHERE mnroregistro=rparam.mnroregistrokairo AND nomenclado=true;

			IF FOUND THEN

				INSERT INTO medicamento (mnroregistro,idlaboratorio,mtroquel,mcodbarra,mpresentacion,mnombre,idfarmtipoventa,nomenclado) 
				VALUES (
					maxnroregistro.mnroregistroinst,
					padrekairo.idlaboratorio,
					concat(padrekairo.mtroquel,'3')::int,
					rparam.mcodbarra,
					padrekairo.mpresentacion,
					concat (padrekairo.mnombre, ' INST'),
					padrekairo.idfarmtipoventa,
					false
					);

				INSERT INTO manextra (mnroregistro,idvias,idfarmtipounid,idupotenci,idformas,idmonodroga,idacciofar,idtamanos,mepotencia,nomenclado)
				VALUES (
					maxnroregistro.mnroregistroinst,
					padrekairo.idvias,
					padrekairo.idfarmtipounid,
					padrekairo.idupotenci,
					padrekairo.idformas,
					padrekairo.idmonodroga,
					padrekairo.idacciofar,
					padrekairo.idtamanos,
					padrekairo.mepotencia,
					false
					);

				INSERT INTO far_medicamento(mnroregistro,idarticulo,idcentroarticulo,nomenclado) 
				VALUES (
					maxnroregistro.mnroregistroinst
					,medinst.idarticulo
					,medinst.idcentroarticulo
					,false
					);
				exito=true;
			END IF;
		END IF;
	END IF;

return exito;
END;
$function$
