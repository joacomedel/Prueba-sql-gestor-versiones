CREATE OR REPLACE FUNCTION public.far_guardarpreciodesdepedido(bigint, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

	pidarticulo alias for $1;
	pidcentroarticulo alias for $2;
	pidusuario alias for $3;

	timportesiniva float4;
        timporteconiva float4;
	timporteiva float4;

	precio RECORD;
	rartexistente RECORD;
	raux RECORD;
        

BEGIN
/* Malapi 15/04/2014: Para el caso en el que vigente existan los 2 precios, el de venta y el de compra solo se toma 
   como valido el precio de venta.
*/

SELECT INTO rartexistente  * 
FROM far_articulo as a
LEFT JOIN far_rubro USING(idrubro)
LEFT JOIN far_precioarticulo as pa ON pa.idarticulo = a.idarticulo 
	AND pa.idcentroarticulo = a.idcentroarticulo AND nullvalue(pafechafin)
WHERE  a.idarticulo = pidarticulo
AND a.idcentroarticulo = pidcentroarticulo;

IF FOUND THEN 

	--Verifico que no sea un producto con precio de Kairos
	IF NOT rartexistente.apreciokairos THEN
		SELECT INTO raux * FROM far_preciocompra
				WHERE idarticulo = rartexistente.idarticulo
				AND idcentroarticulo = rartexistente.idcentroarticulo
				AND nullvalue(pcfechafin);
		IF FOUND THEN
			--pavalor	
		 IF not nullvalue(raux.preciocompra) AND raux.preciocompra <> 0 THEN --Tomo el precio de compra
		   timportesiniva=round(CAST((raux.preciocompra * rartexistente.rporcentajeganacia) + raux.preciocompra AS numeric),2);
		   timporteiva=round(CAST(timportesiniva*0.21 AS NUMERIC),2);
		   timporteconiva = round(timportesiniva::numeric,2) + round(timporteiva::numeric,2); 
		 END IF;


		IF not nullvalue(raux.pcprecioventasinivasugerido) AND raux.pcprecioventasinivasugerido <> 0 THEN --Tomo el precio de venta
		   timportesiniva=raux.pcprecioventasinivasugerido;
		   timporteiva=round(CAST(timportesiniva*0.21 AS NUMERIC),2);
		   timporteconiva = round(timportesiniva::numeric,2) + round(timporteiva::numeric,2); 
		END IF;

                IF not nullvalue(raux.pcprecioventaconivasugerido) AND raux.pcprecioventaconivasugerido <> 0 THEN --Tomo el precio de venta con iva
		   timporteconiva=raux.pcprecioventaconivasugerido;
		   --timporteiva=round(CAST(timporteconiva*(1 + 0.21) AS NUMERIC),2);
		   --timportesiniva = round(timporteconiva::numeric,2) - round(timporteiva::numeric,2); 
                   timportesiniva = round(CAST(timporteconiva/(1 + 0.21) AS NUMERIC),2); 
		   timporteiva=round(timporteconiva::numeric,2) - round(timportesiniva::numeric,2); 
		END IF;
--Malapi 13/10/2016 Modifico para que no baje el precio de venta cuando viene desde pedido. 
		    --IF timporteconiva <> rartexistente.pvalorcompra 
                     IF timporteconiva > rartexistente.pvalorcompra 
			OR nullvalue(rartexistente.pvalorcompra) THEN 
		    /* Modifico el precio viegente si no es un articulo que tenga valor kairos*/
		     UPDATE far_precioarticulo SET pafechafin = now()
					   WHERE far_precioarticulo.idarticulo = rartexistente.idarticulo 
					    and idcentroarticulo =  rartexistente.idcentroarticulo
					    and nullvalue(far_precioarticulo.pafechafin);
			/* Inserto el nuevo valor */
			INSERT INTO far_precioarticulo (idarticulo,idcentroarticulo,pafechaini,pavalor,pimporteiva,pvalorcompra,idusuariocarga)  
			VALUES(rartexistente.idarticulo,rartexistente.idcentroarticulo,now(),round(timportesiniva::numeric,2),round(timporteiva::numeric,2),round(timporteconiva::numeric,2),pidusuario);
		    END IF;
	       END IF;
	 END IF;
 END IF;            
             
      

return 'true';
END;
$function$
