CREATE OR REPLACE FUNCTION public.w_controlinventario(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* {"idusuarioweb": 5538, "accion": "stock", "codigobarra": "7798140257363"}  Obtiene los datos del producto
* {"idusuarioweb": 5538, "accion": "ubicacion", "codigobarra": "7798140257363"}  Busca la ubicacion del producto
* {"idusuarioweb": 5538, "accion": "verificarpicadas" } Busca datos de monitoreo de los items 
* {"idusuarioweb": 5538, "accion": "precarga_ajuste", "arrayitems": [{ "idarticulo": 104362, "idcentroarticulo": 1, "cantidadcontada": '2' }]} Realiza la precarga del control de inventario
*/
DECLARE
    --Declaro variables
    respuestajson jsonb;
    itemduplicado jsonb;
    contadasarticulo RECORD;
    arrayitems jsonb[];
    item jsonb;
    vaccion CHARACTER VARYING;
    vdescripcion CHARACTER VARYING;
    resultadoprecarga boolean;
    vcantstock INTEGER;
    descripcionescaner CHARACTER VARYING := '';
    
    rdatos RECORD;
    rpicadas RECORD;
begin
    IF nullvalue(parametro->>'idusuarioweb') OR nullvalue(parametro->>'accion') THEN 
        RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
    END IF;
    vaccion = parametro->>'accion';

    CASE vaccion
        WHEN 'stock' 
            THEN
                IF nullvalue(parametro->>'codigobarra') THEN
                    RAISE EXCEPTION 'R-002, Todos los parametros deben estar completos.  %',parametro;
                END IF; 

                --Busco el item con el codigo de barra
                SELECT INTO rdatos CASE WHEN nullvalue(idagrupador) THEN 1 ELSE idagrupador END as idagrupador,far_darcantidadarticulostock(far_articulo.idarticulo,far_articulo.idcentroarticulo) AS acantidadactual,far_articulo.*,pafechaini, pafechaini, pavalor, pimporteiva, pvalorcompra, pamodificacion, case when (not(apreciokairos) and (pafechaini<current_date-15)) THEN 'idstockajusteiteminformetipo*2$' ELSE '' END as seinformaitem,concat (ovvale.vale, ' Cantidad: ', cantvale) as ainfoarticulo
                    FROM far_articulo LEFT JOIN far_articuloagrupador USING(idarticulo,idcentroarticulo)
                        LEFT JOIN far_precioarticulo  ON (far_articulo.idarticulo=far_precioarticulo.idarticulo  AND far_articulo.idcentroarticulo=far_precioarticulo.idcentroarticulo 		and nullvalue(far_precioarticulo.pafechafin)) 	
                        LEFT JOIN (
                            SELECT idarticulo,idcentroarticulo, CASE WHEN not nullvalue(oviv.idordenventaitemoriginal) THEN 'Tiene vale. ' END AS vale, SUM(ovicantidad) as cantvale
                                FROM far_ordenventaitem as ovi 
                                NATURAL JOIN far_ordenventa as o 
                                JOIN far_ordenventaitemvale as oviv ON (oviv.idordenventaitemoriginal = ovi.idordenventaitem AND oviv.idcentroordenventaitemoriginal = ovi.idcentroordenventaitem) 
                            WHERE ovfechaemision >=current_date - 7 AND not nullvalue(oviv.idordenventaitemoriginal)
                            GROUP BY idarticulo,idcentroarticulo, idordenventaitemoriginal
                        ) AS ovvale ON (far_articulo.idarticulo=ovvale.idarticulo  AND far_articulo.idcentroarticulo=ovvale.idcentroarticulo) 
                WHERE nullvalue(aafechafin) AND aactivo AND acodigobarra ilike parametro->>'codigobarra';

                --ds 03-10-24 Verifico si el producto no fue cargado con anterioridad
                SELECT INTO itemduplicado array_to_json(array_agg(row_to_json(t)))
                    FROM (
                        -- Registros donde psaidescripcion contiene 'PF_', agrupados
                        SELECT nombre, apellido, dni, 
                            SUM(psaicantidadcontada) AS psaicantidadcontada, 
                            MAX(psaiaifechaingreso) AS psaiaifechaingreso,
                            'PF' AS descripcionpf, 	idprecargastockajusteitem	
                        FROM far_precargastockajusteitem 
                        JOIN usuario ON (psaiidusuario = idusuario)
                        WHERE idarticulo = rdatos.idarticulo 
                        AND idcentroarticulo = rdatos.idcentroarticulo 
                        AND psaiaifechaingreso >= CURRENT_DATE
                        AND psaidescripcion ILIKE '%PF_%'
                        and not psaiborrado
                        GROUP BY nombre, apellido, dni, idprecargastockajusteitem

                        UNION 

                        -- Registros donde psaidescripcion NO contiene 'PF_', sin agrupar
                        SELECT nombre, 
                            apellido, 
                            dni, 
                            psaicantidadcontada, 
                            psaiaifechaingreso,
                            '-' AS descripcionpf, idprecargastockajusteitem
                        FROM far_precargastockajusteitem 
                        JOIN usuario ON (psaiidusuario = idusuario)
                        WHERE idarticulo = rdatos.idarticulo 
                        AND idcentroarticulo = rdatos.idcentroarticulo 
                        AND psaiaifechaingreso >= CURRENT_DATE
                        and not psaiborrado
                        AND psaidescripcion NOT ILIKE '%PF_%'
                    ) AS t;


                IF rdatos IS NULL THEN 
                    RAISE EXCEPTION 'R-003, No se encuentra el producto.  %',parametro;
                ELSE
                    respuestajson = row_to_json(rdatos);
                    respuestajson = jsonb_build_object('articulo', rdatos, 'articuloduplicado', itemduplicado);
                END IF;                

        WHEN 'ubicacion' 
            THEN
                IF nullvalue(parametro->>'codigobarra') THEN
                    RAISE EXCEPTION 'R-003, Todos los parametros deben estar completos.  %',parametro;
                END IF; 

                --Busco el item con el codigo de barra
                SELECT INTO rdatos * FROM far_articulo WHERE acodigobarra = parametro->>'codigobarra';
                IF FOUND THEN
                    SELECT INTO rdatos far_articulo.idarticulo, far_articulo.idcentroarticulo, concat( far_articulo.idarticulo,' - ', far_articulo.idcentroarticulo) as elarticulo, 	adescripcion, 	acodigobarra,lstock, uddescripcion, false as dardebajaub,idarticuloubicacionsucursal, idcentroarticuloubicacionsucursal ,ausfechaini,	ausfechafin			
                    FROM far_articulo LEFT JOIN far_articuloubicacionsucursal USING(idarticulo,idcentroarticulo) 			
                        LEFT JOIN far_ubicacionsucursal USING(idubicacionsucursal,idcentroubicacionsucursal)			
                        LEFT JOIN far_lote ON (far_articulo.idarticulo=far_lote.idarticulo and far_articulo.idcentroarticulo=far_lote.idcentroarticulo 		and  far_lote.idcentrolote=centro())  			
                    WHERE nullvalue(ausfechafin) AND far_articulo.idarticulo = rdatos.idarticulo;
                ELSE
                    RAISE EXCEPTION 'R-004, No se encuentra el producto.';
                END IF;

                IF rdatos IS NULL THEN 
                    RAISE EXCEPTION 'R-003, No se encuentra el producto.  %',parametro;
                ELSE
                    respuestajson = row_to_json(rdatos);
                END IF;
        WHEN 'eliminar' THEN

            UPDATE far_precargastockajusteitem
                SET psaiborrado = TRUE, psaiinformado = concat('Dado de baja desde APP por el usuario ', parametro->>'idusuarioweb')
            WHERE idprecargastockajusteitem = (parametro->>'idprecargastockajusteitem')::integer;

        WHEN 'verificarpicadas' 
            THEN
                SELECT INTO rdatos sum(cantartpicados) as picados, sum(cantartconstock) as cantartconstock,sum(cantartsinstock) as cantartsinstock, sum(cantidadarticulosdiferencia) as cantidadarticulosdiferencia, sum(cantidadarticulos) as cantidatotal
                FROM (
                    SELECT *,case when nullvalue(cantidadcontada) THEN 0 ELSE 1 END as cantartpicados   
                    ,case when cantidad > 0 THEN 1 ELSE 0 END as cantartconstock   
                    ,case when cantidad <= 0 THEN 1 ELSE 0 END as cantartsinstock  
                    ,case when cantidad <> cantidadcontada THEN 1 ELSE 0 END as cantidadarticulosdiferencia
                    ,1 as cantidadarticulos   
                        FROM (
                            select idarticulo,idcentroarticulo,far_darcantidadarticulostock(idarticulo,idcentroarticulo) as cantidad,cantidadcontada,cantidadfilas
                            FROM far_articulo 
                            LEFT JOIN (
                                    SELECT idarticulo,idcentroarticulo,sum(psaicantidadcontada) as cantidadcontada,count(*) as cantidadfilas 
                                    FROM far_precargastockajusteitem 
                                    WHERE nullvalue(idstockajuste) and not psaiborrado
                                    GROUP BY idarticulo,idcentroarticulo 
                                ) as articulospicados USING(idarticulo,idcentroarticulo) 
                            WHERE far_darcantidadarticulostock(idarticulo,idcentroarticulo) <> 0
                    ) as t
                ) as resumen;

                --Verifico si el producto no fue cargado con anterioridad
                SELECT INTO rpicadas array_to_json(array_agg(row_to_json(t)))
                    FROM ( 
                        SELECT nombre, apellido, dni, acodigobarra, psaicantidadcontada, psaiaifechaingreso, adescripcion, far_darcantidadarticulostock (idarticulo, idcentroarticulo) as acantidadactual,--, acodigobarra,
                        '' AS descripcionpf
                        FROM far_precargastockajusteitem 
                        JOIN usuario ON (psaiidusuario = idusuario)
                        JOIN far_articulo USING(idarticulo, idcentroarticulo)
                        WHERE 
                        idstockajuste IS NULL
                        AND NOT psaiborrado
                        AND psaicantidadcontada IS NOT NULL
                        AND psaiaifechaingreso >= CURRENT_DATE
                        AND psaicantidadcontada > 0
                        AND NOT (psaidescripcion ILIKE '%PF_%')
                        --AND far_darcantidadarticulostock (idarticulo, idcentroarticulo) <> 0
                    
                        UNION

                        SELECT nombre, apellido, dni, acodigobarra, SUM(psaicantidadcontada) AS psaicantidadcontada,   
                        MAX(psaiaifechaingreso) AS psaiaifechaingreso, adescripcion, 
                        far_darcantidadarticulostock (idarticulo, idcentroarticulo) as acantidadactual,
                        'PF' AS descripcionpf
                        FROM far_precargastockajusteitem 
                        JOIN usuario ON (psaiidusuario = idusuario)
                        JOIN far_articulo USING(idarticulo, idcentroarticulo)
                        WHERE 
                        psaiaifechaingreso >= CURRENT_DATE
                        AND psaidescripcion ILIKE '%PF_%'
                        AND psaicantidadcontada > 0
                        AND psaicantidadcontada IS NOT NULL
                        AND NOT psaiborrado
                        AND idstockajuste IS NULL
                        --AND  far_darcantidadarticulostock (idarticulo, idcentroarticulo)  <> 0
                        GROUP BY nombre, apellido, dni, adescripcion, idarticulo, idcentroarticulo, acodigobarra
                ) as t;

                IF rdatos IS NULL THEN 
                    RAISE EXCEPTION 'R-003, No se encuentra el producto.  %',parametro;
                ELSE
                    --respuestajson = row_to_json(rdatos);
                    --respuestajson = jsonb_build_object('picadas', rdatos, 'picadasduplicado', rpicadas);

                    --respuestajson = row_to_json(rdatos);
                    respuestajson = jsonb_build_object('picadascontadas', row_to_json(rdatos), 'picadas', rpicadas.array_to_json);
                END IF;

        WHEN 'precarga_ajuste' 
            THEN
                IF nullvalue(parametro->>'idusuarioweb') OR nullvalue(parametro->>'arrayitems') THEN
                    RAISE EXCEPTION 'R-005, Todos los parametros deben estar completos.  %',parametro;
                END IF; 

                IF  iftableexists('temp_far_precargastockajusteitem') THEN
                    DELETE FROM temp_far_precargastockajusteitem;
                END IF;
                
                CREATE TEMP TABLE temp_far_precargastockajusteitem AS (SELECT * FROM far_precargastockajusteitem LIMIT 0);
                
                --Busco al usuario
                SELECT INTO rdatos idusuario, nombre, apellido
                FROM w_usuariorolwebsiges
                NATURAL JOIN usuario
                WHERE idusuarioweb = parametro->>'idusuarioweb'
                LIMIT 1;

                --Preparo la descripcion
                vdescripcion := 'Agrupador:  Cierre de Inventario. Generado usando SosuncMovil. Horario: ' || to_char(now(), 'DD-MM-YYYY HH24:MI:SS') || '. Controlo:' || rdatos.nombre || ' ' || rdatos.apellido;

                -- Transformo el JSON en array para poder recorrerlo en un FOREACH
				arrayitems := ARRAY(SELECT jsonb_array_elements_text(parametro->'arrayitems'));

         

				--Inserto en la tabla 
				FOREACH item IN ARRAY arrayitems
				LOOP
                    --Busco la cantidad de stock en sistema
                    vcantstock := far_darcantidadarticulostock(CAST(item->>'idarticulo' AS INTEGER),CAST(item->>'idcentroarticulo' AS INTEGER));

                    -- ds 19/12/23 si el articulo tiene psaiinformado lo guardo
                    IF (item->>'descripcionescaner' IS NOT NULL) THEN 
                        vdescripcion = item->>'descripcionescaner' || ' - ' || vdescripcion;
                    END IF;

                    --Realizar foreach para almacenar en la temporal todos los registros enviados desde el param
                    INSERT INTO temp_far_precargastockajusteitem (idstockajuste,idcentrostockajuste,psaiidusuario,idarticulo,idcentroarticulo,psaicantidadcontada,psaidescripcion,psaiinformado,psaistocksistema) VALUES  
                    ('0',
                        0,
                        rdatos.idusuario, 
                        CAST(item->>'idarticulo' AS INTEGER), 
                        CAST(item->>'idcentroarticulo' AS INTEGER), 
                        CAST(item->>'cantidadcontada' AS INTEGER),
                        vdescripcion,
                        '',
                        vcantstock
                    ); 


                --ds 03/10/24 devuelve la cantidad contada por articulo del usuario que está picando
                    SELECT INTO contadasarticulo 
                        nombre, 
                        apellido, 
                        dni, 
                        SUM(CASE 
                                WHEN psaicantidadcontada IS NULL THEN 0 
                                ELSE psaicantidadcontada 
                            END) + 1 AS totalcantidadcontada, 
                        'PF' AS descripcionpf
                    FROM far_precargastockajusteitem 
                    JOIN usuario ON (psaiidusuario = idusuario)
                    WHERE idarticulo = item->>'idarticulo'
                    AND idcentroarticulo = item->>'idcentroarticulo'
                    AND psaiidusuario = rdatos.idusuario
                    AND psaidescripcion ILIKE '%PF_%'
                    AND NOT (psaiborrado)
                    AND psaiaifechaingreso >= CURRENT_DATE
                    GROUP BY nombre, apellido, dni;

				END LOOP;

                --Ejecuto proceso que carga los datos de la tabla temporal en far_precargastockajusteitem
                SELECT INTO resultadoprecarga * FROM far_abmprecargastockajuste();
                
                IF resultadoprecarga THEN
                     respuestajson = jsonb_build_object('mensaje', 'Datos cargados correctamente.', 'articulocontado', contadasarticulo);
                ELSE 
                    RAISE EXCEPTION 'R-006, Error al cargar los datos.';
                END IF;
        ELSE 
    END CASE;

    return respuestajson;
end;
$function$
