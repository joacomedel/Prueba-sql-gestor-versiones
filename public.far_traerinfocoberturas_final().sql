CREATE OR REPLACE FUNCTION public.far_traerinfocoberturas_final()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

       

       --CREATE TEMP TABLE t_medicamentos (idplan integer, detalle VARCHAR, pagaplan DOUBLE PRECISION);

       rarticulo RECORD;
       rarticulocobertura RECORD;
      carticulo refcursor;
      carticulocobertura refcursor;

      porcentaje DOUBLE PRECISION;
      preciorestante DOUBLE PRECISION;
      preciototal DOUBLE PRECISION;
      preciocobertura DOUBLE PRECISION;

begin

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
                troquel integer                   
                );

CREATE TEMP TABLE t_detallecobertura (mnroregistro VARCHAR,articulodetalle VARCHAR,detallecob VARCHAR,
 porccob DOUBLE PRECISION, preciocob DOUBLE PRECISION,codautorizacion character varying,idafiliado bigint,idplancobertura bigint);

CREATE TEMP TABLE temp_control_ordenes_contemporal
        AS ( SELECT *,cantidad as canti,false as convale ,false as regalo FROM far_traerinfocoberturasNUEVA());

    OPEN carticulo FOR SELECT mnroregistro,articulodetalle,precio,canti,convale,regalo,acodigobarra,idarticulo,idcentroarticulo,porciva,idiva,troquel FROM temp_control_ordenes_contemporal GROUP BY mnroregistro,articulodetalle,precio,canti,convale,regalo,acodigobarra,idarticulo,idcentroarticulo,porciva,idiva,troquel;
    FETCH carticulo into rarticulo;
    WHILE FOUND LOOP

    --clave para su recupeacion mnroregistro

            preciototal=(rarticulo.precio* rarticulo.canti); 
            preciototal = preciototal + (preciototal* rarticulo.porciva);

            INSERT INTO t_medicamentos (mnroregistro,articulodetalle,precio,canti,total,convale,regalo,acodigobarra,idarticulo,idcentroarticulo,importeiva,porciva,idiva,troquel) 
            VALUES (rarticulo.mnroregistro,rarticulo.articulodetalle,rarticulo.precio,rarticulo.canti,preciototal, rarticulo.convale,rarticulo.regalo,rarticulo.acodigobarra,rarticulo.idarticulo,rarticulo.idcentroarticulo, (rarticulo.precio+(rarticulo.precio*rarticulo.porciva)),rarticulo.porciva,rarticulo.idiva,rarticulo.troquel);

            

            preciorestante = preciototal;


            OPEN carticulocobertura FOR SELECT * FROM temp_control_ordenes_contemporal WHERE temp_control_ordenes_contemporal.mnroregistro=rarticulo.mnroregistro ORDER BY prioridad;
            FETCH carticulocobertura into rarticulocobertura;
            WHILE FOUND LOOP

                    IF rarticulocobertura.idplancobertura=63 THEN 

                        preciocobertura = round(CAST( (preciorestante*rarticulocobertura.porccob) as numeric) ,2);

                        porcentaje =rarticulocobertura.porccob;

                        preciorestante = preciorestante - preciocobertura;

                    ELSE
                        IF rarticulocobertura.idplancobertura=0 THEN 

                            porcentaje =(( preciorestante * 100)/preciototal)/100;
                            porcentaje= round(CAST( porcentaje as numeric) ,2);
                            preciocobertura = preciorestante;

                        ELSE

                            --preciocobertura = round(CAST( ((rarticulocobertura.canti*rarticulocobertura.precio)*rarticulocobertura.porccob) as numeric) ,2);

                            preciocobertura = ((rarticulocobertura.canti*rarticulocobertura.precio)*rarticulocobertura.porccob);

                            porcentaje =rarticulocobertura.porccob;

                            preciorestante = preciorestante - preciocobertura;

                        END IF;


                    END IF;

                    INSERT INTO t_detallecobertura (mnroregistro,articulodetalle,detallecob,porccob,preciocob,codautorizacion,idafiliado,idplancobertura) 
                    VALUES (rarticulocobertura.mnroregistro,rarticulocobertura.articulodetalle,rarticulocobertura.detallecob,porcentaje,preciocobertura,rarticulocobertura.codautorizacion,rarticulocobertura.idafiliado,rarticulocobertura.idplancobertura);
                            

            FETCH carticulocobertura into rarticulocobertura;
            END loop;
            CLOSE carticulocobertura;

    FETCH carticulo into rarticulo;
    END loop;
    CLOSE carticulo;


return true;
end;
$function$
