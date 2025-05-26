CREATE OR REPLACE FUNCTION public.far_corregircopahueprecioarticulo()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
            
       cfar_articulo refcursor;
       rfar_articulo record;
       rtest RECORD;

      

BEGIN

     --Si existe un precioarticulo en public vigente para ese idarticulo entonces me quedo con el precio de public
     --Para verificar, solo tomo los articulos que estan en el esquema copahue, pues asi significa que es un articulo nuevo o modificado,
     --los otros no interesan pues tendran su precio en nqn. 
     --RECORDAR: esta funcion se debe correr luego de corregir los articulos. 

     OPEN cfar_articulo FOR SELECT  copahue.far_articulo.*
			    FROM copahue.far_articulo;
      FETCH cfar_articulo INTO rfar_articulo;
      WHILE  found LOOP
		SELECT INTO rtest * FROM public.far_precioarticulo 
			 WHERE idarticulo = rfar_articulo.idarticulo AND
                                idcentroarticulo = rfar_articulo.idcentroarticulo
                                AND nullvalue(pafechafin);
                IF FOUND THEN  
                --Si hay un precio en nqn, elimino los precios para ese articulo en el esquema de copahue
			DELETE FROM copahue.far_precioarticulo  
				WHERE idarticulo = rfar_articulo.idarticulo AND
					idcentroarticulo = rfar_articulo.idcentroarticulo;
                END IF;


              FETCH cfar_articulo into rfar_articulo;
      END LOOP;
      close cfar_articulo;


return 'true';
END;
$function$
