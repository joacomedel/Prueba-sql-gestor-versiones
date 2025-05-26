CREATE OR REPLACE FUNCTION public.w_emitirconsumoafiliado_agrupar(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    respuestajson jsonb;
    jsonafiliado jsonb;
    jsonconsumo jsonb;
    jsonitemaud jsonb;
    --CURSOR
    cpracticas refcursor;
    --RECORD
    rpersona RECORD;
    rpractica RECORD;
    elem RECORD;
    ritems RECORD;
    rasocconv RECORD;
    --VARIABLES
    vcantidad integer;
    vidtempitem integer;
begin
vidtempitem = 0;
IF NOT  iftableexists('tempitemsaprobar') THEN
	CREATE TEMP TABLE tempitemsaprobar(idtemitems integer, tierror text,cantidadsolicitada int4,cantidadaprobada int4,importeunitario float,idnomenclador varchar,idcapitulo varchar,idsubcapitulo varchar,idpractica varchar,idplancob varchar,idasocconv bigint,auditada boolean,porcentaje integer,porcentajesugerido integer,amuc FLOAT4 ,afiliado FLOAT4,sosunc FLOAT4,idplancoberturas INTEGER,coberturaamuc DOUBLE PRECISION, idconfiguracion bigint) WITHOUT OIDS;
ELSE
	DELETE FROM tempitemsaprobar;
END IF;
        RAISE NOTICE 'ConsumosWeb (%)',parametro->'ConsumosWeb'; 
	OPEN cpracticas FOR select * from jsonb_to_recordset(parametro->'ConsumosWeb') as x("Cantidad" int, "CodigoConvenio" text,"DescripcionCodigoConvenio" text,"IdPlan" int);
	FETCH cpracticas INTO elem;
	WHILE  found LOOP
        ----VAS RAISE EXCEPTION 'prueba, C: %',elem."Cantidad";
                RAISE NOTICE 'parametro (%)',parametro; 
        -- SL 15/04/25 - Agrego condicion para evitar error en los casos que "Cantidad" sea nulo
        IF elem."Cantidad" IS NULL THEN
            vcantidad = 1;
        ELSE
            vcantidad = elem."Cantidad"::integer;
        END IF;

        -- SL 26/12/24 - Agrego condicion para verificar que contenga puntos el codigo de convenio
        IF elem."CodigoConvenio" NOT LIKE '%.%' THEN
            RAISE EXCEPTION 'R-201, El código de la práctica no respeta el formato, "XX.XX.XX.XX". (Código Práctica: %)',elem."CodigoConvenio";
        END IF;
                SELECT INTO rpractica split_part(elem."CodigoConvenio",'.',1) as idnomenclador,split_part(elem."CodigoConvenio",'.',2) as idcapitulo,split_part(elem."CodigoConvenio",'.',3) as idsubcapitulo,split_part(elem."CodigoConvenio",'.',4) as idpractica;
		RAISE NOTICE 'rpractica (%)',rpractica;
		  
		SELECT INTO ritems * FROM tempitemsaprobar WHERE idnomenclador = rpractica.idnomenclador
            AND idcapitulo = rpractica.idcapitulo
            AND idsubcapitulo=rpractica.idsubcapitulo
            AND idpractica = rpractica.idpractica; 
		-- RAISE NOTICE 'ritems (%)',ritems;
		IF FOUND THEN 
			---- VAS 030425 UPDATE tempitemsaprobar SET cantidadsolicitada = cantidadsolicitada + 1 WHERE idtemitems = ritems.idtemitems;
            ----Cantidad 
            UPDATE tempitemsaprobar SET cantidadsolicitada = cantidadsolicitada + vcantidad WHERE idtemitems = ritems.idtemitems;
		ELSE 
			vidtempitem = vidtempitem + 1;
            --MaLaPi 28-10-2019 Le agrego para que tome las asocconvenio que se marcan como online
            SELECT INTO rasocconv * FROM asocconvenio NATURAL JOIN convenio NATURAL JOIN w_usuariowebprestador NATURAL JOIN w_usuarioweb JOIN  practconvval ON practconvval.idasocconv = asocconvenio.idasocconv 
            WHERE uwnombre =  parametro->>'uwnombre' AND acfechafin >= current_date AND tvvigente  AND aconline AND concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica) = concat(rpractica.idnomenclador,'.',rpractica.idcapitulo,'.',rpractica.idsubcapitulo,'.',rpractica.idpractica)
            LIMIT 1;
			INSERT INTO tempitemsaprobar(idtemitems,cantidadsolicitada,idnomenclador,idcapitulo,idsubcapitulo,idpractica,idasocconv,idplancoberturas) 
			VALUES(vidtempitem,vcantidad::integer,rpractica.idnomenclador,rpractica.idcapitulo,rpractica.idsubcapitulo,rpractica.idpractica,rasocconv.idasocconv,1);
--- 030425 VAS cambio elem."Cantidad"::integer por 1
		
		END IF;
	fetch cpracticas into elem;
	END LOOP;
	CLOSE cpracticas;

      return respuestajson;

end;$function$
