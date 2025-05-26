CREATE OR REPLACE FUNCTION public.actualizarpreciosporrubro(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	
	resultado RECORD;
	idusuario INTEGER;
	cursorarti refcursor;
	arti RECORD;
BEGIN
--"Luciana Carolina";1;"Rubilar":90
idusuario = $2;

OPEN cursorarti FOR SELECT idarticulo,idcentroarticulo 
		from far_preciocompra 
		natural join far_articulo 
		where  nullvalue(pcfechafin) 
                    AND not nullvalue(preciocompra)
		    and idrubro = $1  ;
FETCH cursorarti into arti;
WHILE  found LOOP

	SELECT INTO resultado far_guardarpreciodesdepedido(arti.idarticulo,arti.idcentroarticulo,idusuario);
fetch cursorarti into arti;
END LOOP;
close cursorarti;		

return 'true';
END;
$function$
