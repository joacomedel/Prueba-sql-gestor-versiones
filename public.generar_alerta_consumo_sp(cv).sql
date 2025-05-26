CREATE OR REPLACE FUNCTION public.generar_alerta_consumo_sp(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
    --GK 24-11-2022 creado para generar alertas de consumo en auditoria 
    --
    rparam RECORD;

BEGIN
    
    EXECUTE sys_dar_filtros($1) INTO rparam; 

    IF iftableexists('temp_afiliaciones_gestionalertasafiliado') THEN
        DROP TABLE temp_afiliaciones_gestionalertasafiliado;
    END IF;

        CREATE TEMP TABLE 
            temp_afiliaciones_gestionalertasafiliado AS  
            ( 
                SELECT * 
                FROM infoafiliado 
                NATURAL JOIN infoafiliado_dondemostra 
                LIMIT 0
            );

    RAISE NOTICE 'temp_afiliaciones_gestionalertasafiliado%:',rparam.nrodoc;

    INSERT INTO 
        temp_afiliaciones_gestionalertasafiliado (
                idinfoafiliado,
                idcentroinfoafiliado,
                nrodoc,
                idinfoafiliadoquienmuestra,
                infoafiliadocc,
                infoafiliado_dondemostracc,
                iaidusuario,
                iagrupofamiliar,
                iatexto,
                iafechaini,
                iafechafin,
                tipodoc 
        )  VALUES(
            NULL,
            NULL,
            rparam.nrodoc,
            11,
            NULL,
            NULL,
            NULL,
            'false',
            concat('Afiliado supero tope validaciones FARMACIA',now()),
            (concat(extract(year from  current_date),'-',extract(MONTH from  current_date),'-',extract(DAY from  current_date)))::date,
            (date_trunc('month', current_date::date) + interval '1 month' - interval '1 day')::date,

            NULL
            );
    
    PERFORM afiliaciones_gestionalertasafiliado();


    RETURN true;


END;
$function$
