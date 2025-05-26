CREATE OR REPLACE FUNCTION public.w_app_verdisponibleordenes(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
/*
* SELECT w_app_verdisponibleordenes('{"nrodoc": "43947118", "practicas": [{"idnomenclador": "12", "idcapitulo":"42", "idsubcapitulo":"01", "idpractica":"01"}, {"idnomenclador": "12", "idcapitulo":"46", "idsubcapitulo":"00", "idpractica":"01"}]}')
*/
	respuestajson jsonb := '[]';
	practica jsonb;
	rasociacion RECORD;
	rseconsume RECORD;
	rpersona RECORD;
	rplancob RECORD;
	vcantrestantes VARCHAR;
	vidnomenclador VARCHAR;
    vidcapitulo VARCHAR;
    vidsubcapitulo VARCHAR;
    vidpractica VARCHAR;
begin
	-- Verifico parametros
	IF(parametro->>'nrodoc' IS NULL OR parametro->>'practicas' IS NULL ) THEN
		RAISE EXCEPTION 'R-001 (vdo), Al Menos uno de los parametros deben estar completos.  %',parametro;
	END IF;

	--Verifico que el convenio sea valido o este vigente.
	SELECT INTO rasociacion * 
	FROM asocconvenio 
		NATURAL JOIN convenio 
		NATURAL JOIN w_usuariowebprestador 
		NATURAL JOIN w_usuarioweb
	WHERE uwnombre = 'ususm' AND acfechafin >= current_date AND aconline ORDER BY idasocconv LIMIT 1;
    
    -- -- Verifico la barra de la persona
    -- SELECT INTO rpersona * 
    -- FROM persona 
    -- WHERE nrodoc = parametro->>'nrodoc';

    -- IF FOUND AND rpersona.barra > 100 THEN
    SELECT INTO rplancob * 
    FROM plancobpersona 
    where idplancoberturas IN (1,12,29)  --Solo se pueden usar el General/Reciprocidad/Rec Coseguro
        AND  (nullvalue(pcpfechafin) OR pcpfechafin > current_date) 
        AND nrodoc = parametro->>'nrodoc'
    ORDER BY idplancoberturas LIMIT 1;

    IF FOUND THEN
        -- Recorrer el arreglo de "practicas"
        FOR practica IN
            SELECT jsonb_array_elements(parametro->'practicas') AS practica
        LOOP
            -- Extraer los valores de la práctica
            vidnomenclador := practica->>'idnomenclador';
            vidcapitulo := practica->>'idcapitulo';
            vidsubcapitulo := practica->>'idsubcapitulo';
            vidpractica := practica->>'idpractica';
                    
            IF NOT  iftableexists('esposibleelconsumo') THEN
                CREATE TEMP TABLE esposibleelconsumo (idpractica character varying,       idplancobertura character varying,        idnomenclador character varying,        auditoria boolean,        cobertura integer,      idcapitulo character varying,         idsubcapitulo character varying,         idplancoberturas bigint,        ppccantpractica integer,      ppcperiodo character varying,         ppccantperiodos integer,         ppclongperiodo integer,         ppcprioridad integer,         idconfiguracion bigint,        serepite boolean,      ppcperiodoinicial integer,        ppcperiodofinal integer,        rcantidadconsumida integer,        rcantidadrestante integer,        nivel integer,        fechadesde date,        fechahasta date
            ,      pimportepractica double precision,        pimporteamuc double precision,        pimporteafiliado double precision,        pimportesosunc double precision,        coberturaamuc double precision,      nrocuentac character varying,        idesposibleelconsumo integer,    coberturasosunc double precision,    esreintegro boolean);       
            ELSE
                DELETE FROM esposibleelconsumo;
            END IF;
            
            --Busco los consumos
            PERFORM expendio_verificar_consumo(vidnomenclador,vidcapitulo,vidsubcapitulo,vidpractica,rplancob.idplancobertura::BIGINT,rplancob.nrodoc,rplancob.tipodoc::INTEGER,rasociacion.idasocconv::BIGINT);

            --Traigo datos del proceso
            SELECT INTO rseconsume * FROM esposibleelconsumo   as e 
                            WHERE e.rcantidadrestante >= 1  AND e.fechadesde <= current_date   
                            AND e.fechahasta >= current_date  ORDER BY nivel DESC,ppcprioridad LIMIT 1;

            --Verifico si tiene disponible
            IF rseconsume.auditoria THEN
                vcantrestantes = '0';
            ELSE
                vcantrestantes = rseconsume.rcantidadrestante;
            END IF;
            

            respuestajson = respuestajson ||  jsonb_build_array(json_build_object('practica', CONCAT(vidnomenclador, '-', vidcapitulo, '-', vidsubcapitulo, '-', vidpractica), 'cantidadRest', vcantrestantes));			

        END LOOP;
    ELSE
        RAISE EXCEPTION 'R-005, No se encontro el plan de cobertura para el afiliado.';
    END IF;

	return respuestajson;
end;
$function$
