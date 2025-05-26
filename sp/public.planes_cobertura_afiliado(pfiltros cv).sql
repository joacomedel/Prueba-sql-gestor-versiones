CREATE OR REPLACE FUNCTION public.planes_cobertura_afiliado(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$

DECLARE

    rfiltros record;
    rafiliado record;
    respboolean boolean;
    
    /*Ejemplo:
        SELECT * FROM planes_cobertura_afiliado( 
        '{"nrodoc"=27091730,"tipodoc"=1}'
        );
    */
BEGIN


    EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

    respboolean=false;

        SELECT INTO rafiliado *
        FROM persona
        NATURAL JOIN plancobpersona
        NATURAL JOIN plancobertura

        WHERE nrodoc = rfiltros.nrodoc AND tipodoc=rfiltros.tipodoc
        AND idplancobertura IN (28,2,11,13);

        IF FOUND THEN
            respboolean = true;
        END IF;
    
    RETURN respboolean;
    --RAISE EXCEPTION 'respboolean  %', respboolean;
END;
$function$
