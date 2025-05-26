CREATE OR REPLACE FUNCTION public.sp_far_plancoberturamedicamentoafiliado(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

        --RECORD


        rparam RECORD;
       

BEGIN
    IF  NOT iftableexists('temp_far_plancoberturamedicamentoafiliado') THEN
        CREATE TEMP TABLE temp_far_plancoberturamedicamentoafiliado (
            idobrasocial bigint,
            idplancobertura bigint,
            idafiliado bigint,
            mnroregistro character varying,
            prioridad integer,
            porccob double precision,
            montofijo double precision,
            pcdescripcion character varying,
            detalle character varying,
            codautorizacion character varying,
            idvalidacionitem integer,
            idcentrovalidacionitem integer
        );
    ELSE
        DELETE FROM temp_far_plancoberturamedicamentoafiliado;
    END IF;

    -- OBTENGO PARAMETROS 
    EXECUTE sys_dar_filtros($1) INTO rparam; 
    /*
    1 -vmnroregistro,
    2 -vidafiliadoos,
    3 -vidafiliadososunc,
    4 -vidafiliadoamuc,
    5 -vidvalidacionitem,
    6 -vidafiliadomutual,
    7 -vquemutual,
    8 -vidcentrovalidacion
    */


    INSERT INTO temp_far_plancoberturamedicamentoafiliado(
            SELECT  
                o.idobrasocial::bigint,
                ov.idvalorescaja::bigint,   
                far_afiliado.idafiliado::bigint as idafiliado,
                m.mnroregistro::text,
                3 as prioridad,
                multiplicadoramuc as porcCob,
                '0.0'::double precision as montoFijo,       
                o.osdescripcion as pdescripcion,    
                concat(ov.idvalorescaja , '-' , o.osdescripcion) as detalle,
                '0' as codautorizacion,
                rparam.vidvalidacionitem,
                rparam.vidcentrovalidacion
    
            FROM medicamento AS m
            NATURAL JOIN  manextra
            NATURAL JOIN plancoberturafarmacia
            CROSS JOIN (
                SELECT * 
                FROM far_obrasocial 
                WHERE idobrasocial = 3 
                    ) as o
            NATURAL JOIN far_afiliado
            NATURAL JOIN far_obrasocialvalorescaja AS ov --USING(idobrasocial)
            WHERE  
                idobrasocial = 3 
                AND mnroregistro = rparam.vmnroregistro
                AND nullvalue(fechafinvigencia)
                AND idafiliado = rparam.vidafiliadoamuc
                AND idfarmtipoventa <> 1 --MALAPI 04-11-2013 SOSUNC y AMUC no cubren los medicamentos de venta libre

            UNION

    --- La obra social con validaciones
            SELECT  
                o.idobrasocial::bigint,
                ov.idvalorescaja::bigint,   
                rparam.vidafiliadoos::bigint  as idafiliado,
                rparam.vmnroregistro::text as mnroregistro,
                1 as prioridad,
                CASE WHEN nullvalue(porcentajecobertura) THEN 0 ELSE porcentajecobertura*0.01 END::double precision as porcCob,     
                CASE WHEN nullvalue(impotecobertura) THEN 0 ELSE impotecobertura END::double precision as montoFijo,        
                ap.pdescripcion as pdescripcion,
                concat(3 , '-' , ap.pdescripcion) as detalle,
                codautorizacion::text as codautorizacion,
                idvalidacionitem,
                idcentrovalidacionitem
            FROM far_validacionitems as v
            LEFT JOIN medicamento as m ON (m.mcodbarra = v.Codbarras OR  codtroquel=mtroquel)
            LEFT JOIN far_articulo as a ON (a.acodigobarra = m.mcodbarra)
            JOIN far_validacion AS avr USING(idvalidacion)
            JOIN adesfa_prepagas AS ap ON(avr.fincodigo=ap.idadesfa_prepagas)
            JOIN far_obrasocial AS o USING(idobrasocial)
            JOIN far_obrasocialvalorescaja AS ov USING(idobrasocial)
            WHERE   
                (mnroregistro = rparam.vmnroregistro  OR (idarticulo = trim(split_part(rparam.vmnroregistro,'-',1))  AND idcentroarticulo = trim(split_part(rparam.vmnroregistro,'-',2)))) 
                AND idvalidacionitem = rparam.vidvalidacionitem
                AND avr.idcentrovalidacion= rparam.vidcentrovalidacion
               -- AND codrta=0


            UNION

                --- LAS OTRAS MUTUALES, siempre que la obra social asociada la cubra, la mutual lo cobre.

            SELECT  
                fosm.idobrasocial::bigint,
                ov.idvalorescaja::bigint,   
                rparam.vidafiliadomutual::bigint  as idafiliado,
                 rparam.vmnroregistro::text as mnroregistro,
                2 as prioridad,
                CASE WHEN nullvalue(osmmultiplicador) THEN 0 ELSE osmmultiplicador END::double precision as porcCob,        
                '0.0'::double precision as montoFijo,       
                fosm.osdescripcion as pdescripcion,
                concat(fosm.idobrasocial , '-' , fosm.osdescripcion) as detalle,
                codautorizacion::text as codautorizacion,
                idvalidacionitem,
                idcentrovalidacionitem
            FROM far_validacionitems as v
            LEFT JOIN medicamento as m ON (m.mcodbarra = v.Codbarras OR  codtroquel=mtroquel)
            LEFT JOIN far_articulo as a ON (a.acodigobarra = m.mcodbarra)
            JOIN far_validacion AS avr USING(idvalidacion)
            JOIN adesfa_prepagas AS ap ON(avr.fincodigo=ap.idadesfa_prepagas)
            JOIN far_obrasocial AS o USING(idobrasocial)
            JOIN far_obrasocialmutual as osm ON osm.idobrasocial = o.idobrasocial AND osm.idmutual = rparam.vquemutual
            JOIN far_afiliado as fa ON fa.idafiliado = rparam.vidafiliadomutual AND fa.idobrasocial = rparam.vquemutual
            JOIN far_obrasocialvalorescaja AS ov ON osm.idmutual = ov.idobrasocial
            JOIN far_obrasocial as fosm ON fosm.idobrasocial = osm.idmutual
            WHERE 
                (mnroregistro = rparam.vmnroregistro  OR (idarticulo = trim(split_part(rparam.vmnroregistro,'-',1))  AND idcentroarticulo = trim(split_part(rparam.vmnroregistro,'-',2)))) 
                AND idvalidacionitem = rparam.vidvalidacionitem 
                AND avr.idcentrovalidacion=rparam.vidcentrovalidacion
                --AND codrta=0

            UNION

                SELECT  

                    999::bigint as idobrasocial,
                    0::bigint as idplancobertura,
                    rparam.vidafiliadoos::bigint as idafiliado,
                    rparam.vmnroregistro::text as mnroregistro, 
                    99 as prioridad,    
                    1::double precision as porcCob,
                    0.0::double precision as montoFijo,
                    'A cargo del Afiliado' as pcdescripcion,
                    '0-A Cargo del Afiliado' as detalle,
                    '0' as codautorizacion,
                    rparam.vidvalidacionitem,
                    rparam.vidcentrovalidacion

            --ORDER BY prioridad;
        );

    

return true;

end;
$function$
