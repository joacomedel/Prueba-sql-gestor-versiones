CREATE OR REPLACE FUNCTION public.far_abmprecargapedido()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

   	cursorprecarga CURSOR FOR SELECT * FROM tmpprecargarpedido;
	relem RECORD;
	rprecarga RECORD;
       

BEGIN
    OPEN cursorprecarga;
    FETCH cursorprecarga into relem;
    WHILE  found LOOP
             SELECT INTO rprecarga * 
                         FROM far_precargarpedido 
                                WHERE idarticulo = relem.idarticulo
		          	 AND idcentroarticulo = relem.idcentroarticulo
		          	 AND idusuario = relem.idusuario
		          	 AND nullvalue(idpedidoitem); 
             IF NOT FOUND THEN 

                    INSERT INTO far_precargarpedido(idusuario,idarticulo,idcentroarticulo,pcpcantidad,pcppreciocompra,pcpprecioventasiniva,pcpprecioventaconiva)  
			VALUES(relem.idusuario,relem.idarticulo,relem.idcentroarticulo,relem.pcpcantidad,relem.pcppreciocompra,relem.pcpprecioventasiniva,relem.pcpprecioventaconiva);
						 

             ELSE 
			UPDATE far_precargarpedido SET pcpcantidad = pcpcantidad + relem.pcpcantidad,
		           pcppreciocompra = relem.pcppreciocompra,
                           pcpprecioventasiniva = relem.pcpprecioventasiniva,
                           pcpprecioventaconiva = relem.pcpprecioventaconiva
		          WHERE idarticulo = relem.idarticulo
		          	 AND idcentroarticulo = relem.idcentroarticulo
		          	 AND idusuario = relem.idusuario
		          	 AND nullvalue(idpedidoitem); 
                           
             END IF;
             --Elimino las pre cargar sin cantiddad
            	DELETE FROM far_precargarpedido 
			        WHERE idarticulo = relem.idarticulo
		          	 AND idcentroarticulo = relem.idcentroarticulo
		          	 AND idusuario = relem.idusuario
		          	 AND nullvalue(idpedidoitem)
                                 AND (nullvalue(pcpcantidad) OR pcpcantidad <= 0); 
		
           
            
             
             fetch cursorprecarga into relem;
    END LOOP;
    close cursorprecarga;

return 'true';
END;
$function$
