CREATE OR REPLACE FUNCTION public.w_validarordensosunc(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$



/* Saco del xml
	- Credencial -> numero ( numero doc)
	-Fecha receta 
	- items 
		- CodBarras 
		- CantidadSolicitada
*/
/*
*{
"NroAfiliado":null,
"Barra":null,
"NroDocumento":"05204709",
"TipoDocumento":"DNI",




"articulos":[
	{
	"cantidadsolicitada":1,
	"codbarras":"7792086000038"
	},
	{
	"cantidadsolicitada":1,
	"codbarras":"7798017285178"
	},
	{
	"cantidadsolicitada":1,
	"codbarras":"7798140251101"
	}

	] 
}
*/
DECLARE
       respuestajson jsonb;
       respuestajson_info jsonb;
       jsonafiliado jsonb;
       jsonconsumo jsonb;
       carticulo refcursor;


       carticulo2 RECORD;
       ccoberturas refcursor;
       ccoberturas2 refcursor;
       rcobertura RECORD;
       elem RECORD;

	
       vidplancoberturas INTEGER;
	
BEGIN

	SELECT INTO jsonafiliado * FROM w_determinarelegibilidadafiliado(parametro);

	DROP TABLE IF EXISTS tfar_coberturas;

	IF NOT  iftableexists('tfar_coberturas') THEN
		CREATE TEMP TABLE 
		tfar_coberturas (
			idiva INTEGER,
			lstock INTEGER,
			precio BIGINT,
			idrubro VARCHAR,
			porccob VARCHAR,
			porciva INTEGER,
			troquel BIGINT,
			cantidad VARCHAR,
			astockmax VARCHAR,
			astockmin VARCHAR,
			monodroga VARCHAR,
			montofijo INTEGER,
			prioridad INTEGER,
			adescuento INTEGER,
			detallecob VARCHAR,
			idafiliado INTEGER,
			idarticulo VARCHAR,
			acomentario VARCHAR,
			idmonodroga INTEGER,
			laboratorio VARCHAR,
			acodigobarra VARCHAR,
			adescripcion VARCHAR,
			idobrasocial INTEGER,
			mnroregistro VARCHAR,
			presentacion VARCHAR,
			rdescripcion VARCHAR,
			idlaboratorio INTEGER,
			pcdescripcion VARCHAR,
			acodigointerno VARCHAR,
			articulodetalle VARCHAR,
			codautorizacion VARCHAR,
			idplancobertura INTEGER,
			idcentroarticulo INTEGER

	);
	--ELSE
	--	DELETE FROM tfar_articulo;
	END IF;
	

	/*OPEN carticulo FOR 
		SELECT * 
		FROM jsonb_to_recordset(parametro->'articulos') as x
		(
			"Cantidad" int, 
			"mnroregistro" text,
			"idarticulo" bigint,
			"idcentroarticulo" int,
			"idafiliado" text,
			"idcentroafiliado" int,
			"idobrasocial" int

		);*/
	OPEN carticulo FOR 
		SELECT * 
		FROM jsonb_to_recordset(parametro->'articulos') as x
		(
			"codbarras" text,
			"cantidadsolicitada" int


		);


	RAISE NOTICE ' Por entrar al loop';

	/*FETCH carticulo INTO elem;
	WHILE  found LOOP
                RAISE NOTICE 'elem (%)',elem;

                INSERT INTO tfar_articulo(mnroregistro,idarticulo,idcentroarticulo, idafiliado,idcentroafiliado, idobrasocial,idvalidacion, idcentrovalidacion)	    
		  VALUES(
		  		elem.mnroregistro,
		  		elem.idarticulo,
		  		elem.idcentroarticulo ,
		  		elem.idafiliado ,
		  		elem.idcentroafiliado ,
		  		elem.idobrasocial ,
		  		null,
		  		null

		  	);

       	fetch carticulo into elem;
	END LOOP;*/



	FETCH carticulo INTO elem;
	WHILE  found LOOP
              RAISE NOTICE 'elem (%)',elem;

              SELECT INTO carticulo2 * FROM 
              	(SELECT
				fm.mnroregistro,
				fm.idarticulo,
				fm.idcentroarticulo,
				idafiliado,
				idcentroafiliado,
				idobrasocial,
				elem.cantidadsolicitada
				FROM far_medicamento as fm
				NATURAL JOIN far_articulo
				LEFT JOIN far_afiliado ON ( nrodoc ilike parametro->>'NroDocumento' AND  idobrasocial=1)
				WHERE true 
					AND acodigobarra=elem.codbarras) as articulo;
              RAISE NOTICE 'Articulo (%)',carticulo2;

              IF NOT  iftableexists('tfar_articulo') THEN
			CREATE TEMP TABLE 
			tfar_articulo (			
				mnroregistro VARCHAR,			
				idarticulo BIGINT,			
				idcentroarticulo BIGINT,			
				convale BOOLEAN,			
				idafiliado VARCHAR,			
				idcentroafiliado INTEGER,			
				idobrasocial INTEGER,			
				cantvendida INTEGER,			
				picantidadentregada INTEGER,			
				idvalidacion INTEGER,			
				idcentrovalidacion INTEGER,			
				idvalidacionitem INTEGER			
			);
		--ELSE
		--	DELETE FROM tfar_articulo;
		END IF;

              INSERT INTO tfar_articulo(mnroregistro,idarticulo,idcentroarticulo, idafiliado,idcentroafiliado, idobrasocial,idvalidacion, idcentrovalidacion)	    
			 VALUES(
		  		carticulo2.mnroregistro,
		  		carticulo2.idarticulo,
		  		carticulo2.idcentroarticulo ,
		  		carticulo2.idafiliado ,
		  		carticulo2.idcentroafiliado ,
		  		carticulo2.idobrasocial ,
		  		null,
		  		null

		  	);


		--SELECT * INTO rcobertura FROM far_traerinfocoberturas();
		OPEN ccoberturas FOR SELECT *  FROM far_traerinfocoberturas();
		FETCH ccoberturas INTO rcobertura;
			WHILE  found LOOP


			INSERT INTO tfar_coberturas ( 
				idiva ,
				lstock ,
				precio ,
				idrubro ,
				porccob ,
				porciva ,
				troquel ,
				cantidad ,
				astockmax ,
				astockmin ,
				monodroga ,
				montofijo ,
				prioridad ,
				adescuento ,
				detallecob ,
				idafiliado ,
				idarticulo ,
				acomentario ,
				idmonodroga ,
				laboratorio ,
				acodigobarra ,
				adescripcion ,
				idobrasocial ,
				mnroregistro ,
				presentacion ,
				rdescripcion ,
				idlaboratorio ,
				pcdescripcion ,
				acodigointerno ,
				articulodetalle ,
				codautorizacion ,
				idplancobertura ,
				idcentroarticulo ) 
			VALUES (
				rcobertura.idiva ,
				rcobertura.lstock ,
				rcobertura.precio ,
				rcobertura.idrubro ,
				rcobertura.porccob ,
				rcobertura.porciva ,
				rcobertura.troquel ,
				elem.cantidadsolicitada ,
				rcobertura.astockmax ,
				rcobertura.astockmin ,
				rcobertura.monodroga ,
				rcobertura.montofijo ,
				rcobertura.prioridad ,
				rcobertura.adescuento ,
				rcobertura.detallecob ,
				rcobertura.idafiliado ,
				rcobertura.idarticulo ,
				rcobertura.acomentario ,
				rcobertura.idmonodroga ,
				rcobertura.laboratorio ,
				rcobertura.acodigobarra ,
				rcobertura.adescripcion ,
				rcobertura.idobrasocial ,
				rcobertura.mnroregistro ,
				rcobertura.presentacion ,
				rcobertura.rdescripcion ,
				rcobertura.idlaboratorio ,
				rcobertura.pcdescripcion ,
				rcobertura.acodigointerno ,
				rcobertura.articulodetalle ,
				rcobertura.codautorizacion ,
				rcobertura.idplancobertura ,
				rcobertura.idcentroarticulo);
		fetch ccoberturas into rcobertura;
	 	END LOOP;
	 	close ccoberturas;


		DROP TABLE IF EXISTS tfar_articulo;


        	fetch carticulo into elem;
 	END LOOP;

--OPEN ccoberturas FOR SELECT * FROM tfar_coberturas;

	SELECT INTO respuestajson_info array_to_json(array_agg(row_to_json(t)))
	FROM (SELECT * FROM tfar_coberturas) as t;
	

	/*FETCH ccoberturas INTO elem;
	WHILE  found LOOP

		RAISE NOTICE 'Entre Coberturas (%)',elem;

		respuestajson = respuestajson::jsonb || row_to_json(elem)::jsonb;
		--SELECT INTO respuestajson w_ordenrecibo_informacion_json(respuestajson);

	fetch ccoberturas into elem;
 	END LOOP;*/
	respuestajson=respuestajson_info;



	return respuestajson;

END;
$function$
