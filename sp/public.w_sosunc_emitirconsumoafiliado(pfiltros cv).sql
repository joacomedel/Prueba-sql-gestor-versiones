CREATE OR REPLACE FUNCTION public.w_sosunc_emitirconsumoafiliado(pfiltros character varying)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$

DECLARE
    json jsonb;
    jsondatos jsonb;
    
    jsonitemstemp jsonb;
    respuestajson jsonb;
    jsonarchivostemp jsonb;
    rjsonitems record;
    rjsondatos record;
    rjsonarchivos record;
    rfiltros record;
    ritem record;

    cursoritem refcursor;

    jsonitems varchar;
    jsonarchivos varchar;
    respboolean boolean;
    importeamuc double precision DEFAULT 0.0; 
    importesosunc double precision DEFAULT 0.0; 
    importeaafil double precision DEFAULT 0.0; 
    rnroorden bigint;
    rcentro integer;
    cantidadflag integer;
    rformapago bigint;
    rdatosorden RECORD;
    rusuario RECORD;
/*
    auxcantidad varchar;
    auxidnomenclador varchar;
    auxidcapitulo varchar;
    auxidsubcapitulo varchar;
    auxidpractica varchar;
    auxpdescripcion varchar;
*/
begin
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

    SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
    IF NOT FOUND THEN
       rusuario.idusuario = 25;
    END IF;

    respuestajson='{}';

    IF (rfiltros.accionemision='auditada') THEN
        -- estado 2 es expendida
        SELECT INTO rdatosorden *                      
        FROM fichamedicaitempendiente                     
        NATURAL JOIN fichamedicaitempendienteestado                   
        NATURAL JOIN fichamedica                      
        NATURAL JOIN persona                      
        JOIN consumo ON(nroreintegro=nroorden AND idcentroregional=centro)                    
        NATURAL JOIN orden
        where nroorden=rfiltros.nroorden AND centro=rfiltros.centro;

        IF FOUND THEN
            -- Si tiene el item en fichamedicaitempendienteestado, lo va a tener en 1 ya que esta generado asi que le voy a tener que cambiar la fecha fin del item
            UPDATE fichamedicaitempendienteestado
            SET fmipfechafin = now()
            WHERE idfichamedicaitempendienteestado=rdatosorden.idfichamedicaitempendienteestado 
                    AND idcentrofichamedicaitempendienteestado=rdatosorden.idcentrofichamedicaitempendienteestado
                    AND nullvalue(fmipfechafin);

            INSERT INTO fichamedicaitempendienteestado (idfichamedicaitempendiente, idcentrofichamedicaitempendiente, idfichamedicaemisionestadotipo, fmipdescripcion, fmipidusuario) 
            VALUES (rdatosorden.idfichamedicaitempendiente, rdatosorden.idcentrofichamedicaitempendiente, 2, 'Estado modificado desde w_sosunc_emitirconsumoafiliado', rusuario.idusuario);

        END IF;

        --INSERT INTO ordenestados VALUES (rfiltros.nroorden, rfiltros.centro, now(), 5, sys_dar_usuarioactual(), now() );

        -- Luego de "expenderla" la coloca para facturar 
        json = concat('{"nroorden":', rfiltros.nroorden, ', "centro":', rfiltros.centro, '}');

        --PERFORM w_sosunc_emitirconsumoafiliado_hacerfacturacion( ,concat('''{"nroorden:"',rfiltros.nroorden,',','centro=',rfiltros.centro) );
        PERFORM w_sosunc_emitirconsumoafiliado_hacerfacturacion(json);

    END IF;


    IF (rfiltros.accionemision='crearjson') THEN
            --Creacion del Json
            SELECT INTO rjsondatos *
            FROM temporden
            LEFT JOIN persona USING (nrodoc) ;

        jsonitems='';

        OPEN cursoritem FOR SELECT *
                            FROM tempitems 
                            LEFT JOIN practica USING (idnomenclador,idcapitulo,idsubcapitulo,idpractica);

        FETCH cursoritem INTO ritem;
        WHILE FOUND LOOP
            cantidadflag=1;
            WHILE cantidadflag <= ritem.cantidad LOOP
    -- Para la cantidad concatenar las veces necesarias el item para que se cumpla
    --por ej si la cantidad dice 3, concatenar 3 veces todo lo siguiente con los datos de esa practica:
                jsonitemstemp = concat ('{"Cantidad":"',1,'",
                            "CodigoConvenio":"',concat(ritem.idnomenclador,'.',ritem.idcapitulo,'.',ritem.idsubcapitulo,'.',ritem.idpractica),'",
                            "DescripcionCodigoConvenio":"',REPLACE(ritem.pdescripcion,'"',''),'" 
                            }');
                jsonitems=concat(jsonitems,jsonitemstemp);
                cantidadflag=cantidadflag+1;
            END LOOP;
        FETCH cursoritem INTO ritem;
        END LOOP;
        CLOSE cursoritem;

        jsonitems = REPLACE(jsonitems::text, '}{', '},{');

    -- Elimino la tabla para que no me genere problemas en el agrupar/desagrupar
            IF iftableexists('tempitems') THEN
                DROP TABLE tempitems;
            END IF;
            IF iftableexists('temporden') THEN
                DROP TABLE temporden;
            END IF;

        IF iftableexists('temparchivos') THEN

            jsonarchivos =',"documento":[' ;

            OPEN cursoritem FOR SELECT * FROM temparchivos ;            

            FETCH cursoritem INTO rjsonarchivos;
            WHILE FOUND LOOP

            jsonarchivostemp = concat ('{"tipo":"url","valor":"https://www.sosunc.org.ar/sigesweb/uploaded_files/emitirconsumoafiliado/',rjsonarchivos.nombrearchivo,'"}');
            
            jsonarchivos=concat(jsonarchivos,jsonarchivostemp);

            FETCH cursoritem INTO rjsonarchivos;
            END LOOP;
            CLOSE cursoritem;
            jsonarchivos = REPLACE(jsonarchivos::text, '}{', '},{');
            jsonarchivos=concat (jsonarchivos,']');

            DROP TABLE temparchivos;

        END IF;

        -- El emisor es SOSUNC
        json=concat ('{"NroAfiliado":"',rjsondatos.nrodoc,'",
                    "NroDocTitu":null,
                    "Barra":"',rjsondatos.barra,'",
                    "contexto_atencion":"Ambulatorio",
                    "NroDocumento":"',rjsondatos.nrodoc,'",
                    "TipoDoc":"',rjsondatos.tipodoc,'",
                    "Track":null,
                    "ApellidoEfector":"",
                    "NombreEfector":"",
                    "CuilEfector":"30590509643",
                    "token":"exp_sc",
                    "info_consumio_token":"exp_sc",
                    "FechaConsumo":"',now(),'",
                    "Diagnostico":"",
                    "MatriculaEfector":"",
                    "CategoriaEfector":"",
                    "ConsumosWeb":[',jsonitems,'],
                    "uwnombre":"ususc"',jsonarchivos,',
                    "idusuario":',rusuario.idusuario,'}');

        -- ususc es usuario sosunc central

        -- Creo el JSON con el que voy a llamar al WS
        respuestajson=json;

        --    RAISE NOTICE 'json =   % ', json;

    END IF;

    IF (rfiltros.accionemision='emitidanoauditoria') THEN
    -- BelenA 21/02/25 agrego ya que cuando emito una que no requiere auditoria y se emite directo, me aparecia en las auditadas
        SELECT INTO rdatosorden *                      
        FROM fichamedicaitempendiente                     
        NATURAL JOIN fichamedicaitempendienteestado                   
        NATURAL JOIN fichamedica                      
        NATURAL JOIN persona                      
        JOIN consumo ON(nroreintegro=nroorden AND idcentroregional=centro)                    
        NATURAL JOIN orden
        where nroorden=rfiltros.nroorden AND centro=rfiltros.centro;

        IF FOUND THEN
            -- Si tiene el item en fichamedicaitempendienteestado, lo va a tener en 1 ya que esta generado asi que le voy a tener que cambiar la fecha fin del item
            UPDATE fichamedicaitempendienteestado
            SET fmipfechafin = now()
            WHERE idfichamedicaitempendienteestado=rdatosorden.idfichamedicaitempendienteestado 
                    AND idcentrofichamedicaitempendienteestado=rdatosorden.idcentrofichamedicaitempendienteestado
                    AND nullvalue(fmipfechafin);

            INSERT INTO fichamedicaitempendienteestado (idfichamedicaitempendiente, idcentrofichamedicaitempendiente, idfichamedicaemisionestadotipo, fmipdescripcion, fmipidusuario) 
            VALUES (rdatosorden.idfichamedicaitempendiente, rdatosorden.idcentrofichamedicaitempendiente, 2, 'Estado modificado desde w_sosunc_emitirconsumoafiliado', rusuario.idusuario);
        END IF;

    END IF;


    RETURN respuestajson;


end;
$function$
