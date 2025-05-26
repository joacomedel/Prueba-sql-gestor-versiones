CREATE OR REPLACE FUNCTION public.rellenarconcaracter(character varying, character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
--EJEMPLO DE LLAMADO

--VARCHAR resultado = rellenarconcaracter(concat('{entrada=' ,dato.entrada, ',cantcaracteresagregar=' ,dato.caracteres, ',caracteragregar=' ,dato.caracteragregar, ',dondeagregar=' ,dato.dondeagregar,'}'));

--VARCHAR resultado = rellenarconcaracter(dato.entrada,concat('{cantcaracteresagregar=' ,dato.caracteres, ',caracteragregar=' ,dato.caracteragregar, ',dondeagregar=' ,dato.dondeagregar,'}'));

--RECORD
    rvariables RECORD;

--VARIABLES
    cantcaracteresagregar BIGINT;
    recursivo BIGINT;
    entrada varchar;    
    caracteragregar varchar;
    resultado varchar;

BEGIN

    EXECUTE sys_dar_filtros($2) INTO rvariables;
    resultado='';
    --RAISE NOTICE 'rvariables =   % ', rvariables;
    --RAISE NOTICE 'rvariables.entrada =   % ', rvariables.entrada::varchar;
    entrada = $1;
    --RAISE NOTICE 'entrada =   % ', entrada;
    cantcaracteresagregar = rvariables.cantcaracteresagregar - LENGTH(entrada);
    --RAISE NOTICE 'cantcaracteresagregar =   % ', cantcaracteresagregar;
    caracteragregar=rvariables.caracteragregar::varchar;

    recursivo=0;

    --RAISE NOTICE 'LENGTH(entrada) =   % ', LENGTH(entrada);

    IF (rvariables.dondeagregar = 'I') THEN
    -- Si quiere que agregue a la izquierda
        WHILE ( recursivo<cantcaracteresagregar ) LOOP
            entrada = concat (caracteragregar , entrada);
            recursivo=recursivo+1;
        END LOOP;
    ELSE
        WHILE ( recursivo<cantcaracteresagregar ) LOOP
            entrada = concat ( entrada, caracteragregar );
            recursivo=recursivo+1;
        END LOOP;
    END IF;


    IF POSITION('?' IN entrada) > 0 THEN
            entrada = REPLACE(entrada, '?', '0');
    ELSE
            entrada = REPLACE(entrada, '¿', ' ');
    END IF;


    resultado=entrada;
    
    --RAISE NOTICE 'resultado desde rellenarconcaracter =   % ', resultado;

return resultado;
END;
$function$
