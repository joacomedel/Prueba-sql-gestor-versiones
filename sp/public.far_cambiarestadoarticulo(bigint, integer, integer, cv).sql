CREATE OR REPLACE FUNCTION public.far_cambiarestadoarticulo(bigint, integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

   	elidarticulo integer;
   	elidcentroarticulo integer;
   	elidestado integer;
        ladescripcion varchar;
        rusuario record;

BEGIN
	elidarticulo =  $1;
	elidcentroarticulo =  $2;
	elidestado = $3;
	ladescripcion  = $4;

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

	UPDATE far_articuloestado  SET aefechafin = now(), aedescripcion = ladescripcion
	WHERE idarticulo =elidarticulo AND idcentroarticulo = elidcentroarticulo AND nullvalue(aefechafin);

	INSERT INTO far_articuloestado(idarticulo, idcentroarticulo, idarticuloestadotipo,aeidusuario, aedescripcion)
		VALUES (elidarticulo, elidcentroarticulo, elidestado, rusuario.idusuario, concat('Nuevo estado desde ',ladescripcion));

 
return 'true';
END;
$function$
