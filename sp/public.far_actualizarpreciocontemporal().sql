CREATE OR REPLACE FUNCTION public.far_actualizarpreciocontemporal()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

	alta refcursor;
	arthijos refcursor;

	elem RECORD;
        rusuario RECORD;
        importesinivaconincremento double precision;
        importeiva double precision;
        importeventa double precision;
BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

 OPEN alta FOR SELECT * FROM far_tmp_precioarticulo
			NATURAL JOIN far_articulo a
                        JOIN tipoiva ti ON a.idiva = ti.idiva
			JOIN far_precioarticulo pa ON pa.idarticulo = a.idarticulo 
					AND a.idcentroarticulo = pa.idcentroarticulo 
					AND nullvalue(pafechafin);
FETCH alta INTO elem;
WHILE found LOOP

importesinivaconincremento = round(((elem.pavalor * elem.incremento) + elem.pavalor)::numeric , 2);
importeiva = round((importesinivaconincremento * elem.porcentaje )::numeric,2);
importeventa = importesinivaconincremento + importeiva;

 /* Modifico el precio viegente */
--UPDATE far_precioarticulo SET pafechafin = now() WHERE far_precioarticulo.idprecioarticulo = elem.idprecioarticulo and nullvalue(far_precioarticulo.pafechafin) ;
 /* Inserto el nuevo valor */
--INSERT INTO far_precioarticulo(idarticulo,idcentroarticulo,pafechaini,pavalor,pimporteiva,pvalorcompra,idusuariocarga)
--       VALUES(elem.idarticulo,elem.idcentroarticulo,now(),importesinivaconincremento,importeiva,importeventa,rusuario.idusuario);


--Malapi: Tener en cuenta que el campo pasvalorcompra en la tabla de precios guarda el precio de venta al publico
UPDATE far_precioarticulosugerido SET pasfechafin = now()
	        WHERE idarticulo = elem.idarticulo 
	        AND idcentroarticulo =elem.idcentroarticulo 
		AND nullvalue(pasfechafin);
INSERT INTO far_precioarticulosugerido(idarticulo,pasvaloranterior,pasvalor,pasimporteiva,pasvalorcompra,idcentroarticulo,pasidusuariocarga)
	    VALUES(elem.idarticulo,elem.pavalor,importesinivaconincremento,importeiva,importeventa
           ,elem.idcentroarticulo
           ,rusuario.idusuario);


fetch alta into elem;
END LOOP;
CLOSE alta;

--DELETE FROM temprecioarticulo;

return 'true';
END;$function$
