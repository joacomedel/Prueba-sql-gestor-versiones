CREATE OR REPLACE FUNCTION public.far_guardarpreciocompradesdepedido(bigint, integer, bigint, double precision, double precision, double precision, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

	pidarticulo alias for $1;
	pidcentroarticulo alias for $2;
	pidprestador alias for $3;
	ppreciocompra alias for $4;
	pprecioventasiniva alias for $5;
	pprecioventaconiva alias for $6;
	pidusuario alias for $7;

	precio RECORD;
        

BEGIN

IF (not nullvalue(ppreciocompra) OR not nullvalue(pprecioventasiniva) OR not nullvalue(pprecioventaconiva)) THEN
/*Ma.La.Pi 11-06-2013 Por el momento no me interesan los precios de compras por prestador, solo por articulo
                pero igual se guardan para un futuro.*/

            SELECT INTO precio * FROM far_preciocompra
                 WHERE idarticulo = pidarticulo
                 AND idcentroarticulo = pidcentroarticulo
                 and nullvalue(pcfechafin);

                 IF FOUND THEN
                       if((not nullvalue(ppreciocompra) AND (nullvalue(precio.preciocompra) OR precio.preciocompra <>  ppreciocompra))
                       OR (not nullvalue(pprecioventasiniva) AND (nullvalue(precio.pcprecioventasinivasugerido) OR precio.pcprecioventasinivasugerido <> pprecioventasiniva))
                       OR (not nullvalue(pprecioventaconiva) AND (nullvalue(precio.pcprecioventaconivasugerido) OR precio.pcprecioventaconivasugerido <> pprecioventaconiva))
                       ) THEN
                              UPDATE far_preciocompra SET pcfechafin = now()
                                     WHERE idarticulo =pidarticulo
                                           and idcentroarticulo = pidcentroarticulo
                                           and nullvalue(pcfechafin);
                               INSERT INTO far_preciocompra(idarticulo,idcentroarticulo,idprestador,preciocompra,pcprecioventasinivasugerido,pcprecioventaconivasugerido,idusuariocarga)
                               VALUES(pidarticulo,pidcentroarticulo,pidprestador,ppreciocompra,pprecioventasiniva,pprecioventaconiva,pidusuario);

                          END IF;
                 ELSE
                          INSERT INTO far_preciocompra(idarticulo,idcentroarticulo,idprestador,preciocompra,pcprecioventasinivasugerido,pcprecioventaconivasugerido,idusuariocarga)
                               VALUES(pidarticulo,pidcentroarticulo,pidprestador,ppreciocompra,pprecioventasiniva,pprecioventaconiva,pidusuario);

                 END IF;
END IF; 
             
             
      

return 'true';
END;$function$
