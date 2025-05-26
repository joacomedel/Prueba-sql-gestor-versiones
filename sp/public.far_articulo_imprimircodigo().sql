CREATE OR REPLACE FUNCTION public.far_articulo_imprimircodigo()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
cursorarticulos CURSOR FOR SELECT *
                           FROM far_articulo_configuracion_temp;
                          
        rarticulo RECORD;
	resp boolean;
        rexiste RECORD;
	rusuario RECORD;
        indice INTEGER;
  
BEGIN

SELECT INTO rexiste * FROM far_articulo_configuracion_temp LIMIT 1;
DELETE FROM far_articulo_configuracion_temp_codigos;
IF rexiste.accion = 'generarcodigos' THEN
	IF iftableexistsparasp('far_articulo_configuracion_temp_codigos') THEN 
		--DELETE FROM far_articulo_configuracion_temp_codigos;
	ELSE 
		/*CREATE TEMP TABLE far_articulo_configuracion_temp_codigos AS (
		    SELECT idarticulo,idcentroarticulo FROM far_articulo_configuracion LIMIT 0
		);*/
	END IF;
END IF;

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

                   
OPEN cursorarticulos;
FETCH cursorarticulos into rarticulo;
WHILE  found LOOP
	IF rarticulo.accion = 'configurar' THEN
		UPDATE far_articulo_configuracion SET acrequiereimprimir = rarticulo.acrequiereimprimir
					,accantidadimpresiones = rarticulo.accantidadimpresiones
					,acseimprimieron = null
					,acidusuarioimprimio = null
		WHERE idarticulo = rarticulo.idarticulo AND idcentroarticulo = rarticulo.idcentroarticulo;
		IF NOT FOUND THEN
			INSERT INTO far_articulo_configuracion (idarticulo,idcentroarticulo,accantidadimpresiones,acrequiereimprimir) 
			VALUES (rarticulo.idarticulo,rarticulo.idcentroarticulo,rarticulo.accantidadimpresiones,rarticulo.acrequiereimprimir);
		END IF;
		-- MaLaPi 21-11-2017 Marco como impresos los que tienen en cantidad Null o cero.
		UPDATE far_articulo_configuracion SET acseimprimieron = now()
					,acidusuarioimprimio = rusuario.idusuario
                                        ,accantidadimpresiones = 0
		WHERE idarticulo = rarticulo.idarticulo AND idcentroarticulo = rarticulo.idcentroarticulo 
			AND (accantidadimpresiones = 0 OR nullvalue(accantidadimpresiones));

	END IF;

	IF rarticulo.accion = 'marcarimpresos' THEN
		UPDATE far_articulo_configuracion SET acseimprimieron = now()
					,acidusuarioimprimio = rusuario.idusuario
                                        ,accantidadimpresiones = 0
		WHERE idarticulo = rarticulo.idarticulo AND idcentroarticulo = rarticulo.idcentroarticulo;
	END IF;
       
	IF rarticulo.accion = 'generarcodigos' 
                   AND (rarticulo.accantidadimpresiones > 0 
                       OR not nullvalue(rarticulo.accantidadimpresiones))THEN
		FOR indice IN 1..rarticulo.accantidadimpresiones LOOP
			INSERT INTO far_articulo_configuracion_temp_codigos(idarticulo,idcentroarticulo) 
			VALUES (rarticulo.idarticulo,rarticulo.idcentroarticulo);
		END LOOP;
		
	END IF;

fetch cursorarticulos into rarticulo;
END LOOP;
close cursorarticulos;

return true;

END;
$function$
