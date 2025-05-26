CREATE OR REPLACE FUNCTION public.far_traerinfocoberturas_convalidador(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        --CURSOR
        carticulo CURSOR FOR SELECT * FROM tfar_articulo where cantvendida!=0;

        --RECORD

        rarticulo RECORD;
        rmed RECORD;
        rpersona RECORD;
        rafiliado RECORD;
        rafil RECORD;
        rafiloso RECORD;
        rmutual RECORD;
        rafilmutu RECORD;
        rverif RECORD;
        rparam RECORD;
       
        --VARIABLES
        elafiliado bigint;
        vidafiliadomutual bigint;
        vquemutual integer;
        vnrodoc varchar;
        vtipodoc integer;
        vidafiliadoos bigint;
        vidafiliadososunc bigint;
        vidafiliadoamuc bigint;
        vidvalidacion integer;
        vidvalidacionitem integer;
        vidcentrovalidacion integer;
        vmnroregistro varchar;
        re boolean;
        tieneamuc boolean;
        restante integer;
        alerta boolean;

       

       

BEGIN
IF  iftableexists('temp_control_ordenes_contemporal') THEN
    DROP TABLE temp_control_ordenes_contemporal;
END IF;

    CREATE TEMP TABLE temp_control_ordenes_contemporal (
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
    
    -- OBTENGO PARAMETROS 
    EXECUTE sys_dar_filtros($1) INTO rparam; 

    --OBTENER RESTANTES 
    restante = 10 - rparam.consumo;

    --inicializo control disparo alerta
    alerta=true;

    -- Si ya supero el maximo de 10
    IF restante < 0 THEN 
        restante =0;
        alerta=false;
    END IF;

    OPEN carticulo;
    FETCH carticulo into rarticulo;

    WHILE  found LOOP

        vmnroregistro = rarticulo.mnroregistro;
        --Verifico que el articulo en far_articulo, sino esta lo inserto
        SELECT * INTO rmed FROM far_medicamento WHERE mnroregistro=rarticulo.mnroregistro;

        IF NOT FOUND THEN

            SELECT * INTO rmed FROM far_articulo WHERE idarticulo=rarticulo.idarticulo AND idcentroarticulo = rarticulo.idcentroarticulo;
            
            IF FOUND THEN

                  SELECT * INTO rverif FROM medicamento WHERE mcodbarra=rmed.acodigobarra; 
                  
                  IF FOUND THEN  --Cargo en far_medicamento
                      INSERT INTO far_medicamento(idarticulo,idcentroarticulo,mnroregistro,nomenclado) values(rmed.idarticulo,rmed.idcentroarticulo,rarticulo.mnroregistro::integer,rverif.nomenclado);
                      --vmnroregistro = rarticulo.mnroregistro; 
                      vmnroregistro =concat(rmed.idarticulo,'-',rmed.idcentroarticulo);
                  ELSE 
                      vmnroregistro =concat(rmed.idarticulo,'-',rmed.idcentroarticulo);
                  END IF;
            ELSE
                  SELECT * INTO  re FROM far_cargarmedicamento(rarticulo.mnroregistro::integer);

                  SELECT * INTO rmed FROM far_medicamento WHERE mnroregistro=rarticulo.mnroregistro;

                  vmnroregistro =concat(rmed.idarticulo,'-',rmed.idcentroarticulo);

            END IF;
        END IF;

        ----------------------------------------------------------------------

        IF (rarticulo.idobrasocial = 1) THEN
            IF length(rarticulo.idafiliado) > 8  THEN
                --Me envian un nrodoc + tipodoc
                --Es un afiliado de Sosunc, puede no estar cargado en far_afiliado
                vnrodoc = substring(rarticulo.idafiliado from 1 for 8 );
                vtipodoc = substring(rarticulo.idafiliado from 9 for 1 )::integer;
            ELSE
                --Envian el Idafiliado de alguna obra social
                
                SELECT into rafil * from far_afiliado WHERE idafiliado=rarticulo.idafiliado  limit 1;
                IF FOUND THEN
                    vnrodoc = rafil.nrodoc;
                    vtipodoc = rafil.tipodoc;
                    vidafiliadoos = rarticulo.idafiliado;
                END IF;
            END IF;
        ELSE

            -- No es Afiliado de SOSUNC, debe estar cargado en far_afiliado
            SELECT into rafil * 
            FROM far_afiliado 
            LEFT JOIN excepciones_afiliado as ea ON (far_afiliado.nrodoc=ea.nrodoc AND  far_afiliado.tipodoc= ea.tipodoc AND idtipoexcepcionesafiliado=1)
            WHERE 
                idafiliado=rarticulo.idafiliado 
                AND idcentroafiliado=rarticulo.idcentroafiliado 
                AND (   idobrasocial!= 1 OR ( nullvalue(eafechahasta) OR NOT current_date <= eafechahasta))
                AND (   idobrasocial!= 1 OR ( nullvalue(eafechadesde) OR NOT eafechadesde <= current_date))
            LIMIT 1;
        
            IF FOUND THEN --Busco el IDAfiliado de la obra social que me envian
                vnrodoc = rafil.nrodoc;
                vtipodoc = rafil.tipodoc;
                
                SELECT into rafiloso * from far_afiliado WHERE nrodoc=vnrodoc AND idobrasocial = rarticulo.idobrasocial;
                
                IF FOUND THEN
                    vidafiliadoos = rafiloso.idafiliado;
                ELSE
                    SELECT into rafiloso * from far_afiliado WHERE idafiliado=rarticulo.idafiliado AND idobrasocial = rarticulo.idobrasocial;
                    
                    IF FOUND THEN
                        vnrodoc = rafiloso.nrodoc;
                        vtipodoc = rafiloso.tipodoc;
                    END IF;
                    
                    vidafiliadoos = rarticulo.idafiliado;
                END IF;
            END IF;
            
            ----------------------------------------OTRA  MUTUAL ------------------------------------------------------------------------
            --Verifico si la obra social que me envian, tiene alguna mutual asociada y si la persona es afiliado de dicha obras social.
            SELECT INTO rmutual * 
            FROM expendio_tiene_mutual(vnrodoc,vtipodoc) as tm
            JOIN far_obrasocialmutual as osm ON osm.idmutual = tm
            JOIN mutualpadron mp ON  mp.idobrasocial = osm.idmutual
            LEFT JOIN mutualpadronestado mpe  ON  (mp.idmutualpadron = mpe.idmutualpadron AND mp.idcentromutualpadron = mpe.idcentromutualpadron)
            WHERE 
                osm.idobrasocial = rarticulo.idobrasocial 
                AND nrodoc = vnrodoc
                AND (idmutualpadronestadotipo=1 AND nullvalue(mpefechafin));
                            
            IF FOUND THEN --La persona tiene una mutual, tengo que recuperar su idafiliado en la mutual
                SELECT INTO rafilmutu * FROM far_afiliado where nrodoc = vnrodoc AND tipodoc=vtipodoc AND idobrasocial = rmutual.idmutual;
            
                IF FOUND THEN --La persona ya esta como afiliado en la mutual
                    elafiliado =rafilmutu.idafiliado;
                
                ELSE --Hay que cargar a la persona como afiliada de la mutual
                    INSERT INTO far_afiliado(idobrasocial,aidafiliadoobrasocial,aapellidoynombre,iddireccion,nrocliente,barra,tipodoc,nrodoc)
                    VALUES(rmutual.idmutual,rmutual.mpidafiliado,rmutual.mpdenominacion,rafiloso.iddireccion,rafiloso.nrocliente,rafiloso.barra,rafiloso.tipodoc,rafiloso.nrodoc);
                    
                    elafiliado = currval('far_afiliado_idafiliado_seq');
                END IF;
        
            ELSE --No es afiliado de una mutual
                elafiliado = null;
            END IF;
        
            vidafiliadomutual = elafiliado;
            vquemutual = rmutual.idmutual;
        
        

        END IF;
        
         /*Malapi 17-02-2014 Comento la busqueda por tipodoc pues me da errores cuando en Siges el tipodoc esta mal cargado o desactualizado
         Malapi 21-05-2014 Elimino la ventana de los 30 dias adicionales para las coberturas con validacion 
        */

        -- GK 18/10/2022 Control lista negra afiliados 
        -- PASAR CONTROL DE AFILIADO SOSUNC 
        
        SELECT INTO rpersona *,cliente.barra as barracli 
        FROM persona
        LEFT JOIN excepciones_afiliado as ea ON (persona.nrodoc=ea.nrodoc AND  persona.tipodoc= ea.tipodoc AND idtipoexcepcionesafiliado=1)
        LEFT JOIN benefsosunc  ON (persona.nrodoc=benefsosunc.nrodoc AND  persona.tipodoc= benefsosunc.tipodoc)
        LEFT JOIN cliente ON cliente.nrocliente = persona.nrodoc OR cliente.nrocliente = benefsosunc.nrodoctitu
        WHERE  
            persona.nrodoc = vnrodoc 
            AND fechafinos >=  current_date /*- 30::integer*/
            AND ( nullvalue(eafechahasta) OR NOT current_date <= eafechahasta)
            AND ( nullvalue(eafechadesde) OR NOT eafechadesde <= current_date);
        

        IF FOUND THEN
            -- Es Afiliado de SOSUNC
            SELECT into rafil * from far_afiliado WHERE nrodoc = vnrodoc AND tipodoc = vtipodoc and idobrasocial=1;
            
            IF NOT FOUND then  -- NO esta cargado en far_afiliado para SOSUNC
                INSERT INTO far_afiliado(idobrasocial,aidafiliadoobrasocial,aapellidoynombre,iddireccion,nrocliente,barra,tipodoc,nrodoc)
                VALUES(1,rarticulo.idafiliado,concat(rpersona.nombres, ' ' , rpersona.apellido),rpersona.iddireccion,rpersona.nrocliente,rpersona.barracli,rpersona.tipodoc,rpersona.nrodoc);
            
                elafiliado = currval('far_afiliado_idafiliado_seq');
            ELSE
                elafiliado = rafil.idafiliado;
            END IF;
        ELSE --La persona no tiene sosunc
            elafiliado = null;
        END IF;

        vidafiliadososunc = elafiliado;

        IF nullvalue(vidafiliadoos) and not nullvalue(vidafiliadososunc) THEN
            vidafiliadoos =vidafiliadososunc;
        END IF;
        
        -------------------------- AMUC
        tieneamuc = expendio_tiene_amuc(vnrodoc,vtipodoc);

        IF tieneamuc then
            SELECT into rafil * from far_afiliado  WHERE nrodoc = vnrodoc AND tipodoc = vtipodoc and idobrasocial=3;
            
            IF NOT FOUND then
            -- NO esta cargado en far_afiliado para AMUC o el plan no esta vigente
                INSERT INTO far_afiliado(idobrasocial,aidafiliadoobrasocial,aapellidoynombre,iddireccion,nrocliente,barra,tipodoc,nrodoc)
                VALUES(3,rarticulo.idafiliado,concat(rpersona.nombres,' ' , rpersona.apellido),rpersona.iddireccion,rpersona.nrocliente,rpersona.barracli,rpersona.tipodoc,rpersona.nrodoc);
            
                elafiliado = currval('far_afiliado_idafiliado_seq');
            ELSE
                -- Alguna vez estuvo en far_afiliado para AMUC, entonces solo recupero el idafiliado
                elafiliado = rafil.idafiliado;
            END if;

        ELSE --NO TIENE AMUC
            elafiliado = null;

        END if;

        vidafiliadoamuc = elafiliado;
        -------------------------- AMUC

        --vmnroregistro = rarticulo.mnroregistro;
        vidvalidacionitem = rarticulo.idvalidacionitem;
        vidcentrovalidacion = rarticulo.idcentrovalidacion;

        IF (rarticulo.idobrasocial = 9) THEN -- Se vende sin obra social

            vidafiliadososunc = null;
            vidafiliadomutual = null;
            vquemutual = null;
            vidafiliadoamuc = null;
            vidvalidacion = null;
            vidcentrovalidacion = null;
        END IF;
        

         RAISE NOTICE 'Value: %', concat('vmnroregistro=',vmnroregistro,','
                             'vidafiliadoos=',vidafiliadoos,','
                             'vidafiliadososunc=',vidafiliadososunc,','
                             'vidafiliadoamuc=',vidafiliadoamuc,','
                             'vidvalidacionitem=',vidvalidacionitem,','
                             'vidafiliadomutual=',vidafiliadomutual,','
                             'vquemutual=',vquemutual,','
                             'vidcentrovalidacion=',vidcentrovalidacion
                             );       

    
        -- 2023-01-11
        PERFORM sp_far_plancoberturamedicamentoafiliado
                     (concat('vmnroregistro=',vmnroregistro,','
                             'vidafiliadoos=',vidafiliadoos,','
                             'vidafiliadososunc=',vidafiliadososunc,','
                             'vidafiliadoamuc=',vidafiliadoamuc,','
                             'vidvalidacionitem=',vidvalidacionitem,','
                             'vidafiliadomutual=',vidafiliadomutual,','
                             'vquemutual=',vquemutual,','
                             'vidcentrovalidacion=',vidcentrovalidacion
                             )
                     );

        RAISE NOTICE 'Value: %', concat('vmnroregistro=',vmnroregistro,','
                             'vidafiliadoos=',vidafiliadoos,','
                             'vidafiliadososunc=',vidafiliadososunc,','
                             'vidafiliadoamuc=',vidafiliadoamuc,','
                             'vidvalidacionitem=',vidvalidacionitem,','
                             'vidafiliadomutual=',vidafiliadomutual,','
                             'vquemutual=',vquemutual,','
                             'vidcentrovalidacion=',vidcentrovalidacion
                             );           

        --for rcobinfomedi in 

        --COBERTURAS OS 
        INSERT INTO temp_control_ordenes_contemporal
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
           idvalidacionitem,
           regalo
            )  
        
            

                SELECT 
                    idobrasocial,
                    idplancobertura ,
                    idafiliado ,
                    coberturas.mnroregistro,
                    prioridad ,
                    porccob ,
                    montofijo ,
                    pcdescripcion ,
                    coberturas.detalle as detallecob ,
                    coberturas.codautorizacion ,
                    /*
                    CASE WHEN (idobrasocial=1 ) THEN
                        CASE WHEN  restante < vi.cantidadaprobada ) THEN 
                            restante
                        ELSE
                            vi.cantidadaprobada-restante 
                    ELSE  
                        CASE WHEN restante < vi.cantidadaprobada THEN 
                            vi.cantidadaprobada-restante 
                        ELSE 
                            vi.cantidadaprobada 
                        END 
                    END*/

                    vi.cantidadaprobada   as cantidadaprobada,

                    rarticulo.cantvendida as cantidadvendida,--solicitada
                    idarticulo ,
                    idcentroarticulo ,
                    idrubro ,
                    adescripcion ,
                    -- alba y facu 281024 precio,
           CASE WHEN (idobrasocial=1001) THEN importeunitario 
                ELSE precio 
            END as precio,   
            ---- 281024 Alba y Facu solo cuando es PAMI obtenemos el precio dado en la validacion
                    rdescripcion ,
                    astockmin ,
                    astockmax ,
                    acomentario ,
                    idiva ,
                    adescuento ,
                    acodigointerno ,
                    acodigobarra ,
                    f.detalle as articulodetalle ,
                    lstock ,
                    troquel ,
                    presentacion ,
                    laboratorio ,
                    idlaboratorio ,
                    monodroga ,
                    idmonodroga ,
                    porciva,
                    vi.idvalidacionitem,
                    false as regalo
                FROM temp_far_plancoberturamedicamentoafiliado as coberturas
    
                JOIN far_buscarinfomedicamentosteniendoclave(vmnroregistro) as f
                    ON f.mnroregistro = coberturas.mnroregistro OR (f.idarticulo = trim(split_part(coberturas.mnroregistro,'-',1))  AND f.idcentroarticulo = trim(split_part(coberturas.mnroregistro,'-',2)))
               -- LEFT JOIN far_validacionitems as vi  ON  (f.acodigobarra = vi.codbarras /*AND idvalidacion = vidvalidacion*/ AND  vi.idvalidacionitem=coberturas.idvalidacionitem)
                LEFT JOIN far_validacionitems as vi  ON  (vi.idvalidacionitem=coberturas.idvalidacionitem AND coberturas.idcentrovalidacionitem=vi.idcentrovalidacionitem)
            ;

/*

    IF (restante - rarticulo.cantvendida)<0 THEN
        restante = 0;
    END IF;*/

    IF (restante - rarticulo.cantvendida)<0 THEN
        -- Disparo Alerta
        IF (alerta) THEN
            RAISE NOTICE 'nro doc %:',vnrodoc;
            PERFORM generar_alerta_consumo_sp(concat('nrodoc=',vnrodoc));
        END IF;

        restante = 0;
        alerta=false;
    ELSE
        restante=restante - rarticulo.cantvendida;
        RAISE NOTICE 'restante %',restante;
    END IF;

FETCH carticulo into rarticulo;
END LOOP;
CLOSE carticulo;

return true;

end;
$function$
