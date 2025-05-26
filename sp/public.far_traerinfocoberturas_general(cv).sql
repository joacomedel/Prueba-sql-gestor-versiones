CREATE OR REPLACE FUNCTION public.far_traerinfocoberturas_general(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
    
    
    --RECORD
    rarticulo RECORD;
    rarticulocobertura RECORD;
    rarticulocoberturaSOSUNC RECORD;
    --rrestricciones RECORD;
    rparam RECORD;
   rcobpami  RECORD;
    
    --REFCURSOR
    carticulo refcursor;
    carticulocobertura refcursor;

    ccobpami refcursor;
   

    --VARIABLES  
    porcentaje DOUBLE PRECISION;
    preciorestante DOUBLE PRECISION;
    preciototal DOUBLE PRECISION;
    preciocobertura DOUBLE PRECISION;
    precioconiva DOUBLE PRECISION;

    --restante integer;
    vale integer;
    convale boolean;
    --restanteAux integer;
    restantepreciototalSosunc DOUBLE PRECISION;

    --CONTROLES BOOLEAN 
    control boolean;
    controlSOSUNC boolean;

BEGIN

    EXECUTE sys_dar_filtros($1) INTO rparam;  

    CREATE TEMP TABLE t_medicamentos (
        mnroregistro VARCHAR,
        articulodetalle VARCHAR, 
        precio DOUBLE PRECISION, 
        canti integer, 
        cantidadsolicitada integer,
        total DOUBLE PRECISION,
        convale boolean,
        regalo boolean, 
        acodigobarra text,                              
        idarticulo bigint,
        idcentroarticulo bigint,
        importeiva bigint,
        porciva DOUBLE PRECISION,
        idiva bigint,
        picantidadentregada integer,
        control boolean --para controlar si se aprobaron todos los articulos
        ,troquel integer
  
    );

    CREATE TEMP TABLE t_detallecobertura (
        canti integer,
        mnroregistro VARCHAR,
        articulodetalle VARCHAR,
        detallecob VARCHAR, 
        porccob DOUBLE PRECISION, 
        preciocob DOUBLE PRECISION,
        codautorizacion character varying,
        idafiliado bigint,
        idplancobertura bigint
        
    );

    --BUSCO COBERTURAS OS / A CARGO DE AFILIADO 
    PERFORM far_traerinfocoberturas_convalidador($1);

---- 28102024  Alba y Facu  corroboro si si es una receta de PAMI
 --- obtener info cobertura PAMI 
 
      OPEN ccobpami FOR SELECT * 
                        FROM temp_control_ordenes_contemporal 
                        WHERE idobrasocial= 1001;

      FETCH ccobpami into rcobpami;
      WHILE FOUND LOOP

             UPDATE temp_control_ordenes_contemporal 
             SET   precio = rcobpami.precio,  -- el precio lo debo tomar de la validacion 
                   articulodetalle = CONCAT(rcobpami.adescripcion,' $ ', rcobpami.precio)     -- mantengo el formato de la descripcion del medicamento

             WHERE mnroregistro = rcobpami.mnroregistro;

             FETCH ccobpami into rcobpami;
      END loop;
      CLOSE ccobpami;

    ----------------------------------------------------------------------------------------------------------------

    -- COSEGUROS 
    PERFORM far_traerinfocoberturas_coseguro($1);

    OPEN carticulo FOR 
    SELECT mnroregistro,articulodetalle,precio,cantidadaprobada,cantidadvendida,acodigobarra,idarticulo,idcentroarticulo,porciva,idiva,lstock,troquel
    FROM temp_control_ordenes_contemporal 
    WHERE idplancobertura!=63
    GROUP BY mnroregistro,articulodetalle,precio,cantidadaprobada,cantidadvendida,acodigobarra,idarticulo,idcentroarticulo,porciva,idiva,lstock,troquel
    ORDER BY cantidadaprobada DESC;

    FETCH carticulo into rarticulo;
    WHILE FOUND LOOP

        --clave para su recupeacion mnroregistro
        IF rarticulo.cantidadaprobada!=0 THEN

            preciototal = (rarticulo.precio* rarticulo.cantidadaprobada); 
            -- PRECIO TOTAL CON IVA
            preciototal = preciototal + (preciototal* rarticulo.porciva);

            -- Control de stock para general vale automatico 
            IF 0 <= (rarticulo.lstock-rarticulo.cantidadaprobada) THEN
                -- SIN VALE
                vale=0;
                convale=false;
            ELSE
                -- CON VALE
                IF rarticulo.lstock<0 THEN
                    vale =rarticulo.cantidadaprobada;
                ELSE
                    vale =rarticulo.cantidadaprobada-rarticulo.lstock ;
                END IF;

                convale=true;
            END IF;
            
            -- INGRESO MEDICAMENTO CUBIERTO 
            INSERT INTO t_medicamentos (mnroregistro,articulodetalle,precio,canti,cantidadsolicitada,total,convale,regalo,acodigobarra,idarticulo,idcentroarticulo,importeiva,porciva,idiva,picantidadentregada,control,troquel) 
            VALUES (
                    rarticulo.mnroregistro,
                    rarticulo.articulodetalle,
                    rarticulo.precio,
                    rarticulo.cantidadaprobada,
                    rarticulo.cantidadvendida,
                    preciototal,
                    convale,
                    false,
                    rarticulo.acodigobarra,
                    rarticulo.idarticulo,
                    rarticulo.idcentroarticulo, 
                    (rarticulo.precio+(rarticulo.precio*rarticulo.porciva)),
                    rarticulo.porciva,
                    rarticulo.idiva,
                    vale,
                    (CASE WHEN rarticulo.cantidadaprobada<>rarticulo.cantidadvendida THEN false ELSE true END)
                    ,rarticulo.troquel
                    );

            
            -- AUXILIAR PARA CALCULAR PROCENTAJES DE LAS FORMAS DE PAGO 
            preciorestante = preciototal;

            --SI TIENE COBERTURA DE SOSUNC 59 NO APLICA COSEGUROS 63
            controlSOSUNC=true;

            OPEN carticulocobertura FOR SELECT * FROM temp_control_ordenes_contemporal WHERE temp_control_ordenes_contemporal.mnroregistro=rarticulo.mnroregistro ORDER BY prioridad;
            FETCH carticulocobertura into rarticulocobertura;
            WHILE FOUND LOOP

                    

                    -- NUEVA FORMA DE COBERTURA/PAGO 
                    control=false;

                    -- CONSEGURO 
                    IF preciorestante!=0 THEN
                        IF controlSOSUNC AND  rarticulocobertura.idplancobertura=63 AND rarticulocobertura.cantidadaprobada!=0  THEN 

                            
                            SELECT * INTO rarticulocoberturaSOSUNC FROM temp_control_ordenes_contemporal WHERE mnroregistro=rarticulocobertura.mnroregistro AND idplancobertura=63;

                            restantepreciototalSosunc = preciorestante/rarticulocobertura.cantidadaprobada;

                            preciocobertura = round(CAST( ((restantepreciototalSosunc*rarticulocoberturaSOSUNC.cantidadaprobada)*rarticulocobertura.porccob) as numeric) ,2);

                            -- PROCENTAJE DE COBERTURA 
                            porcentaje =rarticulocobertura.porccob;

                            -- RESTANTE POR CUBRIR 
                            preciorestante = preciorestante - preciocobertura;

                            --restante =restante-rarticulocoberturaSOSUNC.cantidadaprobada;
                            control=true;

                        END IF;

                        --SOSUNC
                        IF preciorestante!=0 AND rarticulocobertura.cantidadaprobada!=0 AND rarticulocobertura.idplancobertura=59 THEN 

                            --restantepreciototalSosunc = preciorestante/rarticulocobertura.cantidadaprobada;
                            precioconiva = rarticulocobertura.precio+(rarticulocobertura.precio* rarticulocobertura.porciva);

                            preciocobertura = ((precioconiva*rarticulocobertura.cantidadaprobada)*rarticulocobertura.porccob);

                            porcentaje =rarticulocobertura.porccob;

                            preciorestante = preciorestante - preciocobertura;

                            --restante =restante-rarticulocobertura.cantidadaprobada;
                            control=true;
                            controlSOSUNC=false;

                        END IF;

                        -- SIN cobertura

                        IF preciorestante!=0 AND rarticulocobertura.idplancobertura=0 THEN 

                            porcentaje =(( preciorestante * 100)/preciototal)/100;
                            porcentaje= round(CAST( porcentaje as numeric) ,2);

                            

                            preciocobertura = preciorestante;
                            preciorestante = preciorestante - preciocobertura;
                            control=true;

                        END IF;

                        -- OBRA SOCIAL 

                        IF preciorestante!=0  AND rarticulocobertura.idplancobertura!=59 AND rarticulocobertura.idplancobertura!=63 AND rarticulocobertura.idplancobertura!=0 THEN 

                            precioconiva = rarticulocobertura.precio+(rarticulocobertura.precio* rarticulocobertura.porciva);

                            preciocobertura = ((rarticulo.cantidadaprobada*precioconiva)*rarticulocobertura.porccob);

                            porcentaje =rarticulocobertura.porccob;

                            preciorestante = preciorestante - preciocobertura;
                            control=true;

                        END IF;
                        -- 
                        If control THEN 

                            
                            INSERT INTO t_detallecobertura (canti,mnroregistro,articulodetalle,detallecob,porccob,preciocob,codautorizacion,idafiliado,idplancobertura) 
                            VALUES (
                                rarticulo.cantidadaprobada,
                                rarticulocobertura.mnroregistro,
                                rarticulocobertura.articulodetalle,
                                rarticulocobertura.detallecob,
                                porcentaje,
                                preciocobertura,
                                rarticulocobertura.codautorizacion,
                                rarticulocobertura.idafiliado,
                                rarticulocobertura.idplancobertura

                            );
                        
                        END IF;

                    END IF;
                            

            FETCH carticulocobertura into rarticulocobertura;
            END loop;
            CLOSE carticulocobertura;
        END IF;    

    FETCH carticulo into rarticulo;
    END loop;
    CLOSE carticulo;

    RETURN true;
END;
$function$
