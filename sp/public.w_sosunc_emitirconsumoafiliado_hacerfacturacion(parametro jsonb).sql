CREATE OR REPLACE FUNCTION public.w_sosunc_emitirconsumoafiliado_hacerfacturacion(parametro jsonb)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$

DECLARE

    rfiltros record;
    datosorden record; 
    respboolean boolean;
    auxboolean boolean;
    --respboolean jsonb;
    nroordenintaux character varying;
    centroordenintaux character varying;

begin

--EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

respboolean='false';
auxboolean=true;
--respboolean=null;

--RAISE EXCEPTION '(parametro->>detallepracticas)  %', (parametro->>'detallepracticas');
--EjecutarSelect: ERROR ERROR: (parametro->>detallepracticas)  [{"centro": 1, "cantidad": 1, "idrecibo": 1236288, "nroorden": 1563463, "cobertura": 0, "erroritem": "La practica requiere autorizacion.", "codigoconvenio": "07.66.99.9913", "importeunitario": 47013.31, "iditemestadotipo": 1, "descripcioncodigoconvenio": "VITAMINA D3 (25-HIDROXICALCIFEROL O COLECALCIFEROL) "}, {"centro": 1, "cantidad": 1, "idrecibo": 1236288, "nroorden": 1563463, "cobertura": 0, "erroritem": "La practica requiere autorizacion.", "codigoconvenio": "07.66.67.6734", "importeunitario": 20330.08, "iditemestadotipo": 1, "descripcioncodigoconvenio": "INFLUENZA A, Ac. IgG Anti-"}, {"centro": 1, "cantidad": 1, "idrecibo": 1236288, "nroorden": 1563463, "cobertura": 70, "erroritem": "La practica tiene cobertura diferenciada para el afiliado en el plan PREVENTIVO CANCER DE UTERO", "codigoconvenio": "07.66.20.2003", "importeunitario": 1270.63, "iditemestadotipo": 1, "descripcioncodigoconvenio": "ACTO BIOQUÍMICO ADMINISTRATIVO POR VALIDACIÓN - PROCESO de AUDITORÍA - AUTORIZACIÓN DE LA ORDEN"}]


    SELECT EXISTS (
        -- Tengo problemas con la practica 07.66.20.2003
        SELECT 1
        FROM jsonb_array_elements((parametro->>'detallepracticas')::jsonb) AS detallepractica
        WHERE (detallepractica->>'iditemestadotipo')::integer = 1 
        --FROM jsonb_array_elements(respuestajson->>'detallepracticas') AS detallepractica
        --FROM jsonb_array_elements(pfiltros->>'detallepracticas') AS detallepractica
        /*WHERE detallepractica->>'erroritem' = 'La practica requiere autorizacion.' OR 
        detallepractica->>'erroritem' = 'La practica se emitio mas de una vez.' */
        --OR (detallepractica->>'erroritem')::integer ilike '%cobertura diferenciada%' 

    ) INTO auxboolean;

    --RAISE EXCEPTION 'auxboolean  %', auxboolean;

    IF (not nullvalue(parametro->>'ordenInternacion') ) THEN
        -- BelenA 21/02/25 Si le mando orden de internacion se la tengo que asociarlo a la orden
        nroordenintaux = SPLIT_PART(parametro->>'ordenInternacion', '-', 1);
        centroordenintaux = SPLIT_PART(SPLIT_PART(parametro->>'ordenInternacion', '-', 2), '|', 1);

        UPDATE orden
        SET nroordeninter=nroordenintaux::bigint, centroordeninter = centroordenintaux::integer
        WHERE nroorden=(parametro->>'nroorden')::bigint AND centro=(parametro->>'centro')::integer;
    END IF;


    IF NOT auxboolean THEN
    
        UPDATE orden
        SET tipo=2
        WHERE nroorden=(parametro->>'nroorden')::bigint AND centro=(parametro->>'centro')::integer;


        IF NOT  iftableexists('ttordenesgeneradas') THEN
            CREATE TEMP TABLE ttordenesgeneradas(
           nroorden   bigint,
           centro     int4
           ) WITHOUT OIDS;
        ELSE
            DELETE FROM ttordenesgeneradas;
        END IF;

        
        INSERT INTO ttordenesgeneradas(nroorden,centro) VALUES ((parametro->>'nroorden')::bigint , (parametro->>'centro')::integer); 


        IF NOT  iftableexists('temporden') THEN
            CREATE TEMP TABLE temporden(nroorden bigint ,   centro integer, autogestion BOOLEAN) WITHOUT OIDS;
        ELSE
            DROP TABLE temporden;
            CREATE TEMP TABLE temporden(nroorden bigint ,   centro integer, autogestion BOOLEAN) WITHOUT OIDS;
        END IF;

        
        INSERT INTO temporden(nroorden,centro, autogestion)
        (
            SELECT nroorden, centro, false
            FROM orden
            NATURAL JOIN importesorden
            WHERE nroorden=(parametro->>'nroorden')::bigint AND centro=(parametro->>'centro')::integer
            AND idformapagotipos=2 AND importe<>0 --Siempre es forma 2 porque las ordenes del expendio online salen por caja
        );

        SELECT INTO datosorden 
        FROM temporden;

        IF FOUND THEN
            SELECT INTO auxboolean * FROM expendio_facturarexpendioorden();
            respboolean=auxboolean::character varying;
            DROP TABLE temporden;
        END IF;

    END IF;
    
    RETURN respboolean;
    --RAISE EXCEPTION 'respboolean  %', respboolean;
end;
$function$
