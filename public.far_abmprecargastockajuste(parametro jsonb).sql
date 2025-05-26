CREATE OR REPLACE FUNCTION public.far_abmprecargastockajuste(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE

	--RECORD

	--CURSOR

    cstockajuste CURSOR FOR SELECT idstockajuste,idcentrostockajuste,psaiidusuario,idarticulo,idcentroarticulo,psaicantidadcontada,psaidescripcion,psaiinformado,psaistocksistema,count(*) as cantidad
                FROM temp_far_precargastockajusteitem
                GROUP BY idstockajuste,idcentrostockajuste,psaiidusuario,idarticulo,idcentroarticulo,psaicantidadcontada,psaidescripcion,psaiinformado,psaistocksistema;
    rstockajuste record;
    respuesta varchar;
    rusuario record;
    rexiste RECORD;
    rtemp record;
    resp boolean;
    -- VARIABLES 
    --far_precargastockajusteitem_idprecargastockajusteitem_seq
    seqidprecargastockajusteitem bigint;
BEGIN

	SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
	IF NOT FOUND THEN 
		rusuario.idusuario = 25;
	END IF;

	OPEN cstockajuste;
	FETCH cstockajuste into rstockajuste;
	WHILE  found LOOP
		SELECT INTO rexiste * 
		FROM far_precargastockajusteitem 
		LEFT JOIN far_articulocontrolvto USING(idarticulo,idcentroarticulo)
		WHERE idarticulo = rstockajuste.idarticulo
			AND idcentroarticulo = rstockajuste.idcentroarticulo
			AND psaiidusuario = rstockajuste.psaiidusuario
            AND nullvalue(idstockajuste) 
            AND far_precargastockajusteitem.idcentroprecargastockajusteitem=centro() 
            LIMIT 1;
            
        IF NOT FOUND THEN
			
			INSERT INTO far_precargastockajusteitem(psaiidusuario,idarticulo,idcentroarticulo,psaicantidadcontada,psaidescripcion,psaiinformado,psaistocksistema)
			VALUES(rstockajuste.psaiidusuario,rstockajuste.idarticulo,rstockajuste.idcentroarticulo,rstockajuste.psaicantidadcontada,rstockajuste.psaidescripcion,rstockajuste.psaiinformado, rstockajuste.psaistocksistema);

			seqidprecargastockajusteitem = currval('public.far_precargastockajusteitem_idprecargastockajusteitem_seq');

			IF rstockajuste.psaiinformado ilike '%idstockajusteiteminformetipo*1<%' THEN 
				INSERT INTO far_articulocontrolvto (idarticulo,idcentroarticulo,idprecargastockajusteitem,idcentroprecargastockajusteitem,facvactivo,fofechamodif,fechavto)
				VALUES(
					rstockajuste.idarticulo,
					rstockajuste.idcentroarticulo,
					seqidprecargastockajusteitem,
					centro(),
					true,
					now(),
					SPLIT_PART( SPLIT_PART( rstockajuste.psaiinformado,'po*1<fechavto:',2),'>',1)::date
					);
			END IF;
        
        ELSE
			-- UPDATE far_precargastockajusteitem 
			-- SET 
			-- 	psaiaifechaingreso = now()
			-- 	,psaiidusuario = rstockajuste.psaiidusuario
			-- 	,psaicantidadcontada = rstockajuste.psaicantidadcontada
			-- 	,psaidescripcion = rstockajuste.psaidescripcion
			-- 	,psaiinformado = rstockajuste.psaiinformado
            --     ,psaistocksistema =  rstockajuste.psaistocksistema
            --     ,psaiborrado = false
			-- WHERE 
			-- 	idarticulo = rstockajuste.idarticulo
			-- 	AND idcentroarticulo = rstockajuste.idcentroarticulo
			-- 	AND psaiidusuario = rstockajuste.psaiidusuario
            --     AND nullvalue(idstockajuste) 
            --     AND idcentroprecargastockajusteitem=centro();

            -- SL 09/08/24 - No hago mas update si existe el usuario y ahora simplemente almaceno todos los registros.
            INSERT INTO far_precargastockajusteitem(psaiidusuario,idarticulo,idcentroarticulo,psaicantidadcontada,psaidescripcion,psaiinformado,psaistocksistema)
			VALUES(rstockajuste.psaiidusuario,rstockajuste.idarticulo,rstockajuste.idcentroarticulo,rstockajuste.psaicantidadcontada,rstockajuste.psaidescripcion,rstockajuste.psaiinformado, rstockajuste.psaistocksistema);


            IF ( rexiste.facvactivo AND NOT rstockajuste.psaiinformado ilike '%idstockajusteiteminformetipo*1<%') THEN 

            	UPDATE far_articulocontrolvto 
            	SET facvactivo= false, fofechamodif=now()
				WHERE 
				idprecargastockajusteitem=rexiste.idprecargastockajusteitem
				AND idcentroprecargastockajusteitem = rexiste.idcentroprecargastockajusteitem
				AND idarticulo=rexiste.idarticulo
				AND idcentroarticulo= rexiste.idcentroarticulo;
			ELSE
				UPDATE far_articulocontrolvto 
            	SET facvactivo= true,
            	fechavto= (CASE WHEN SPLIT_PART( SPLIT_PART( rstockajuste.psaiinformado,'po*1<fechavto:',2),'>',1)::date < fechavto THEN SPLIT_PART( SPLIT_PART( rstockajuste.psaiinformado,'po*1<fechavto:',2),'>',1)::date ELSE fechavto END ), fofechamodif=now()
				WHERE 
				idprecargastockajusteitem=rexiste.idprecargastockajusteitem
				AND idcentroprecargastockajusteitem = rexiste.idcentroprecargastockajusteitem
				AND idarticulo=rexiste.idarticulo
				AND idcentroarticulo= rexiste.idcentroarticulo;

            END IF; 


		END IF;
	
       FETCH cstockajuste into rstockajuste;
    END LOOP;
    close cstockajuste;

   return 'true';

END;
$function$
