CREATE OR REPLACE FUNCTION public.far_traerinfocoberturas(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

       carticulo CURSOR FOR SELECT *
                           FROM tfar_articulo;

       rarticulo RECORD;
       rverificalote RECORD;
       rmed RECORD;
       rpersona RECORD;
       rafiliado RECORD;
       rafil RECORD;
       rparam RECORD;

       elafiliado bigint;
       vnrodoc varchar;
       vtipodoc integer;
       vidafiliadoos bigint;
       vidafiliadososunc bigint;
       vidafiliadoamuc bigint;
       vidvalidacion integer;
       vmnroregistro varchar;
       vidsolicitudauditoria varchar;
       --re boolean;
       --tieneamuc boolean;

       rafiltitular RECORD;
       rtitular RECORD;
       restante integer;
       alerta boolean;

BEGIN
    --	  RAISE NOTICE 'ENTRO AL SP >> far_traerinfocoberturas';
    -- Si no existe creo la temporar para luego generar el xml con las coberturas 
    IF NOT  iftableexists('temp_control_coberturas') THEN

        CREATE TEMP TABLE temp_control_coberturas (
            idobrasocial bigint,
            idplancobertura bigint,
            idafiliado bigint,
            mnroregistro character varying,
            prioridad integer,
            porccob double precision,
            montofijo double precision,
            pcdescripcion character varying,
            detallecob character varying,
            codautorizacion character varying,
            cantidadaprobada integer,
            cantidadvendida integer,
            idarticulo bigint,
            idcentroarticulo bigint,
            idrubro integer,
            adescripcion character varying,
            precio double precision,
            rdescripcion character varying,
            astockmin double precision,
            astockmax double precision,
            acomentario text,
            idiva bigint,
            adescuento double precision,
            acodigointerno bigint,
            acodigobarra text,
            articulodetalle text,
            lstock bigint,
            troquel integer,
            presentacion character varying,
            laboratorio character varying,
            idlaboratorio integer,
            monodroga character varying,
            idmonodroga integer,
            porciva double precision,
            idvalidacionitem double precision,
            regalo boolean
        );
    END IF;

 -- OBTENGO PARAMETROS 
    EXECUTE sys_dar_filtros($1) INTO rparam; 

    -- GK quito esto lo paso a w_validar_orden_sosunc
    /*
    --OBTENER RESTANTES 
    restante = 10 - rparam.consumo;

    --inicializo control disparo alerta
    alerta=true;

    -- Si ya supero el maximo de 10
    IF restante < 0 THEN 
        restante =0;
        alerta=false;
    END IF;
    */
    ---------------------------------------

    OPEN carticulo;
    FETCH carticulo into rarticulo;

    WHILE  found LOOP

        --Verifico que el artÃ­culo estÃ© en far_articulo, sino esta lo inserto
        vmnroregistro = rarticulo.mnroregistro;
        vidafiliadososunc = rarticulo.idafiliado;
        vidsolicitudauditoria =rparam.idsolicitudauditoria;
 RAISE NOTICE 'far_traercoberturasarticuloafiliado_validador(%,null,%,null,null,%)', vmnroregistro,vidafiliadososunc,vidsolicitudauditoria;

 --COBERTURAS OS 
        INSERT INTO temp_control_coberturas
        ( 
            idobrasocial ,
            idplancobertura ,
            idafiliado ,
            mnroregistro ,
            prioridad ,
            porccob ,
            montofijo  ,
            pcdescripcion  ,
            detallecob  ,
            codautorizacion  ,
            cantidadaprobada ,
            cantidadvendida ,
            idarticulo ,
            idcentroarticulo ,
            idrubro ,
            adescripcion  ,
            precio  ,
            rdescripcion  ,
            astockmin  ,
            astockmax  ,
            acomentario ,
            idiva ,
            adescuento  ,
            acodigointerno ,
            acodigobarra ,
            articulodetalle ,
            lstock ,
            troquel ,
            presentacion  ,
            laboratorio  ,
            idlaboratorio ,
            monodroga  ,
            idmonodroga ,
            porciva,  
           -- idvalidacionitem
           regalo
            )  
        
            

                SELECT  idobrasocial,
                  idplancobertura ,
                  idafiliado ,
                  coberturas.mnroregistro,
                  prioridad ,
                  porccob,
                 -- porccob ,
                  montofijo ,
                  pcdescripcion ,
                  coberturas.detalle as detallecob ,
                  coberturas.codautorizacion ,
                  /*
                  CASE WHEN (idobrasocial=1 AND restante < rarticulo.cantidadsolicitada ) THEN 
                                        restante
                                    ELSE  
                                        CASE WHEN restante < rarticulo.cantidadsolicitada THEN 
                                            rarticulo.cantidadsolicitada-restante 
                                        ELSE 
                                            rarticulo.cantidadsolicitada
                                        END 
                                    END  as cantidadaprobada,
*/  
                   0 as cantidadaprobada,
                  rarticulo.cantidadsolicitada as cantidadsolicitada,
                  idarticulo ,
                  idcentroarticulo ,
                  idrubro ,
                  adescripcion ,
                  precio ,
                  rdescripcion ,
                  astockmin ,
                  astockmax ,
                  acomentario ,
                  idiva ,
                  adescuento ,
                  acodigointerno ,
                  acodigobarra ,
                  f.detalle ,
                  lstock ,
                  troquel ,
                  presentacion ,
                  laboratorio ,
                  idlaboratorio ,
                  monodroga ,
                  idmonodroga ,
                  porciva,
                 false as regalo
            FROM far_traercoberturasarticuloafiliado_validador(vmnroregistro,null,vidafiliadososunc,null,null,vidsolicitudauditoria) as coberturas
            JOIN far_buscarinfomedicamentosteniendoclave_validador(vmnroregistro) as f
                 ON f.mnroregistro = coberturas.mnroregistro OR (f.idarticulo = trim(split_part(coberturas.mnroregistro,'-',1))  AND f.idcentroarticulo = trim(split_part(coberturas.mnroregistro,'-',2)))
            ;

  --  RAISE NOTICE 'vmnroregistro: % ,null, vidafiliadososunc % ,null,null,vidsolicitudauditoria %:',vmnroregistro,vidafiliadososunc,vidsolicitudauditoria;

    --RAISE NOTICE 'cantvendida %:',rarticulo.cantidadsolicitada;

	
/*
    IF (restante - rarticulo.cantidadsolicitada)<=0 THEN
        -- Disparo Alerta
        IF (alerta) THEN
            RAISE NOTICE 'nro doc %:',vnrodoc;
            PERFORM generar_alerta_consumo_sp(concat('nrodoc=',vnrodoc));
        END IF;

        restante = 0;
        alerta=false;
    ELSE
        restante=restante - rarticulo.cantidadsolicitada;
        RAISE NOTICE 'restante %',restante;
    END IF;
*/
FETCH carticulo into rarticulo;
END LOOP;
CLOSE carticulo;

return true;

end;
$function$
