CREATE OR REPLACE FUNCTION public.far_traerinfocoberturas_final(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

       -- GK 2022-11-01 inlcuye que permite el calculo de coberturas y la cobertura parcial en base a las limitantes mensuales con cobertura

       --CREATE TEMP TABLE t_medicamentos (idplan integer, detalle VARCHAR, pagaplan DOUBLE PRECISION);

       rarticulo RECORD;
       rarticulocobertura RECORD;
       rrestricciones RECORD;

      ccobpami refcursor;
      rcobpami  RECORD;

      carticulo refcursor;
      carticulocobertura refcursor;

      porcentaje DOUBLE PRECISION;
      preciorestante DOUBLE PRECISION;
      preciototal DOUBLE PRECISION;
      preciocobertura DOUBLE PRECISION;
       precioconiva DOUBLE PRECISION;

      restante integer;
      vale integer;
      convale boolean;
      restanteAux integer;

      rparam RECORD;

      

      restantepreciototalSosunc DOUBLE PRECISION;

      control boolean;

begin

EXECUTE sys_dar_filtros($1) INTO rparam;  

CREATE TEMP TABLE t_medicamentos (
    mnroregistro VARCHAR,
    articulodetalle VARCHAR, 
    precio DOUBLE PRECISION, 
    canti integer, 
    total DOUBLE PRECISION,
    convale boolean,
    regalo boolean, 
    acodigobarra text,                              
    idarticulo bigint,
    idcentroarticulo bigint,
    importeiva bigint,
    porciva DOUBLE PRECISION,
    idiva bigint,
    picantidadentregada integer
    );

CREATE TEMP TABLE t_detallecobertura (canti integer,mnroregistro VARCHAR,articulodetalle VARCHAR,detallecob VARCHAR, porccob DOUBLE PRECISION, preciocob DOUBLE PRECISION,codautorizacion character varying,idafiliado bigint,idplancobertura bigint);

CREATE TEMP TABLE temp_control_ordenes_contemporal AS ( 
               SELECT *,cantidad as canti ,false as regalo 
               FROM far_traerinfocoberturasNUEVA($1)
               );

       IF centro()=1 THEN 
            restante=2000;
        ELSE
            restante = 10 - rparam.consumo;
        END IF;
 
  
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

    ----------------------------------------------------------------------------------------------------------------------------------------

    OPEN carticulo FOR SELECT mnroregistro,articulodetalle,precio,cantidad,acodigobarra,idarticulo,idcentroarticulo,porciva,idiva,lstock 
                       FROM temp_control_ordenes_contemporal 
                       GROUP BY mnroregistro,articulodetalle,precio,cantidad,acodigobarra,idarticulo,idcentroarticulo,porciva,idiva,lstock 
                       ORDER BY cantidad DESC;
    FETCH carticulo into rarticulo;
    WHILE FOUND LOOP

    --clave para su recupeacion mnroregistro
        IF rarticulo.cantidad!=0 THEN

            preciototal=(rarticulo.precio* rarticulo.cantidad); 
            preciototal = preciototal + (preciototal* rarticulo.porciva);
            preciototal = round(CAST( preciototal  as numeric) ,2);

            --restante=rarticulo.canti;
            -- Control Stock para vale automatico 

            IF 0 <= (rarticulo.lstock-rarticulo.cantidad) THEN
                vale=0;
                convale=false;
            ELSE
                IF rarticulo.lstock<0 THEN
                    vale =rarticulo.cantidad;
                ELSE
                    vale =rarticulo.cantidad-rarticulo.lstock ;
                END IF;
                convale=true;
            END IF;
            
            
            INSERT INTO t_medicamentos (mnroregistro,articulodetalle,precio,canti,total,convale,regalo,acodigobarra,idarticulo,idcentroarticulo,importeiva,porciva,idiva,picantidadentregada) 
            VALUES (
                    rarticulo.mnroregistro,
                    rarticulo.articulodetalle,
                    rarticulo.precio,
                    rarticulo.cantidad,
                    preciototal,
                    convale,
                    false,
                    rarticulo.acodigobarra,
                    rarticulo.idarticulo,
                    rarticulo.idcentroarticulo, 
                    (rarticulo.precio+(rarticulo.precio*rarticulo.porciva)),
                    rarticulo.porciva,
                    rarticulo.idiva,
                    vale
                    );

            

            preciorestante = preciototal;

            OPEN carticulocobertura FOR SELECT * FROM temp_control_ordenes_contemporal WHERE temp_control_ordenes_contemporal.mnroregistro=rarticulo.mnroregistro ORDER BY prioridad;
            FETCH carticulocobertura into rarticulocobertura;
            WHILE FOUND LOOP

                    -- CONSEGURO SOSUCN / OS SUSNC 

                    control=false;

                    IF rarticulocobertura.idplancobertura=63 OR rarticulocobertura.idplancobertura=59 AND preciorestante!=0 THEN 

                        IF restante>0 AND restante >= rarticulo.cantidad THEN

                                restantepreciototalSosunc = preciorestante/rarticulo.cantidad;
                                preciocobertura = round(CAST( ((restantepreciototalSosunc*rarticulo.cantidad)*rarticulocobertura.porccob) as numeric) ,2);
                                porcentaje =rarticulocobertura.porccob;
                                preciorestante = preciorestante - preciocobertura;
                                restante =restante-rarticulo.cantidad;
                                control=true;

                        ELSE 
                            -- Sin cobertura por superar cantidad maxima por mes
                            preciocobertura = 0;
                            porcentaje =0;
                            control=false;
                        END IF ;

                    END IF;

                    -- SIN cobertura

                    IF rarticulocobertura.idplancobertura=0 AND preciorestante!=0 THEN 

                        porcentaje =(( preciorestante * 100)/preciototal)/100;
                        porcentaje= round(CAST( porcentaje as numeric) ,2);
                        preciocobertura = preciorestante;
                        control=true;

                    END IF;

                    -- OBRA SOCIAL 

                    IF rarticulocobertura.idplancobertura!=59 AND rarticulocobertura.idplancobertura!=63 AND rarticulocobertura.idplancobertura!=0 AND preciorestante!=0 THEN 

                        precioconiva = rarticulocobertura.precio+(rarticulocobertura.precio* rarticulocobertura.porciva);
                        preciocobertura = ((rarticulo.cantidad*precioconiva)*rarticulocobertura.porccob);
                        porcentaje =rarticulocobertura.porccob;
                        preciorestante = preciorestante - preciocobertura;
                        control=true;

                    END IF;
                    -- 
                    If control THEN 

                        INSERT INTO t_detallecobertura (canti,mnroregistro,articulodetalle,detallecob,porccob,preciocob,codautorizacion,idafiliado,idplancobertura) 
                        VALUES (rarticulo.cantidad,rarticulocobertura.mnroregistro,rarticulocobertura.articulodetalle,rarticulocobertura.detallecob,porcentaje,preciocobertura,rarticulocobertura.codautorizacion,rarticulocobertura.idafiliado,rarticulocobertura.idplancobertura);
                    END IF;
                            

            FETCH carticulocobertura into rarticulocobertura;
            END loop;
            CLOSE carticulocobertura;
        END IF;    

    FETCH carticulo into rarticulo;
    END loop;
    CLOSE carticulo;

return true;
end;
$function$
