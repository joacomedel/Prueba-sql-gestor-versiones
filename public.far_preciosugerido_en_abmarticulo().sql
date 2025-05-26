CREATE OR REPLACE FUNCTION public.far_preciosugerido_en_abmarticulo()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
cursorarticulos CURSOR FOR SELECT *
                           FROM far_articulo_temp WHERE accion <> 'modificacodigobarra';
          
--RECORD                
        rarticulo RECORD;
	rartexistente RECORD;
	rprecioventa RECORD;
	rprecioventasugerido RECORD;
        existelote RECORD;
        rtipoiva RECORD;
        rprecioarticulopadre RECORD;
        precio RECORD;
	rusuario RECORD;
        rarchivo RECORD;
--VARIABLES
	elidarticulo bigint;
	rprecioventavalor double precision;
        elidajuste bigint;
        resp boolean;       
	vporcentaje double precision;
	vporcentajemasuno double precision;
	rfactorcor double precision;
        elidprecioarticulosugerido BIGINT;
                          
BEGIN


                     
 OPEN cursorarticulos;
 FETCH cursorarticulos into rarticulo;
 WHILE  found LOOP

 SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
 IF NOT FOUND THEN 
   rusuario.idusuario = 25;
 END IF;

-- Malapi 16/12/2016 modifico para que si se envia el idusuario desde la transaccion se use ese. 
 IF not nullvalue(rarticulo.idusuario) THEN
      rusuario.idusuario = rarticulo.idusuario;

 END IF;
 SELECT INTO rtipoiva * FROM tipoiva WHERE idiva = rarticulo.idiva;
 vporcentaje =  rtipoiva.porcentaje;
 vporcentajemasuno = 1.0 + rtipoiva.porcentaje;

 SELECT INTO rfactorcor CASE WHEN nullvalue(rarticulo.afactorcorreccion) THEN rarticulo.afraccion 
                          ELSE  rarticulo.afactorcorreccion END; 

 IF not nullvalue(rarticulo.idarticulopadre) THEN
    SELECT INTO rprecioarticulopadre *
       FROM far_precioarticulo
       WHERE idarticulo =rarticulo.idarticulopadre AND idcentroarticulo =rarticulo.idcentroarticulopadre AND  nullvalue(pafechafin);
       IF FOUND THEN
	  rarticulo.aprecioventa = CASE WHEN nullvalue(rprecioarticulopadre.pvalorcompra) THEN rprecioarticulopadre.pavalor ELSE rprecioarticulopadre.pvalorcompra 
 END;
       END IF;
 END IF;
      
 SELECT INTO rprecioventa * FROM far_precioarticulo WHERE idarticulo = rarticulo.idarticulo 
							    AND idcentroarticulo =rarticulo.idcentroarticulo 
                                                            AND nullvalue(pafechafin);

 SELECT INTO rprecioventasugerido * FROM far_precioarticulosugerido 
                                   WHERE idarticulo = rarticulo.idarticulo 
				    AND idcentroarticulo =rarticulo.idcentroarticulo 
                                    AND nullvalue(pasfechafin);
 IF FOUND THEN

         
	 rprecioventavalor=round (((rarticulo.aprecioventa/rfactorcor)/vporcentajemasuno)::numeric,2);
	 
         IF rprecioventasugerido.pasvalor <> rprecioventavalor THEN 
	  --Malapi: Tener en cuenta que el campo pasvalorcompra en la tabla de precios guarda el precio de venta al publico
	    UPDATE far_precioarticulosugerido SET pasfechafin = now()
	        WHERE idarticulo = rarticulo.idarticulo 
		AND idcentroarticulo =rarticulo.idcentroarticulo 
		AND nullvalue(pasfechafin);

	    
	    INSERT INTO far_precioarticulosugerido(idarticulo,pasvaloranterior,pasvalor,pasimporteiva,pasvalorcompra,idcentroarticulo,pasidusuariocarga,paspreciocompraprestador)
	    VALUES(rarticulo.idarticulo,rprecioventa.pavalor,round(((rarticulo.aprecioventa/rfactorcor)/vporcentajemasuno)::numeric,2)
           ,round ((((rarticulo.aprecioventa/rfactorcor)/vporcentajemasuno)*vporcentaje)::numeric,2)
           ,rarticulo.aprecioventa/rfactorcor
           ,rarticulo.idcentroarticulo
           ,rusuario.idusuario
           ,rarticulo.apreciocompra);
            elidprecioarticulosugerido  = currval('far_precioarticulosugerido_idprecioarticulosugerido_seq');
	 END IF;
 ELSE --Existe el articulo pero no el precio de venta vigente
	   INSERT INTO far_precioarticulosugerido(idarticulo,pasvaloranterior,pasvalor,pasimporteiva,pasvalorcompra,idcentroarticulo,pasidusuariocarga,paspreciocompraprestador)
	    VALUES(rarticulo.idarticulo,rprecioventa.pavalor,round(((rarticulo.aprecioventa/rfactorcor)/vporcentajemasuno)::numeric,2)
           ,round ((((rarticulo.aprecioventa/rfactorcor)/vporcentajemasuno)*vporcentaje)::numeric,2)
           ,rarticulo.aprecioventa/rfactorcor
           ,rarticulo.idcentroarticulo
           ,rusuario.idusuario
           ,rarticulo.apreciocompra);
            elidprecioarticulosugerido  = currval('far_precioarticulosugerido_idprecioarticulosugerido_seq');
 END IF;

    UPDATE far_articulo_temp SET idprecioarticulosugerido = elidprecioarticulosugerido , idcentroprecioarticulosuerido =centro() WHERE idarticulo=rarticulo.idarticulo AND idcentroarticulo= rarticulo.idcentroarticulo;

--Ma.La.Pi 20-11-2013  : Si se manda el precio de compra lo guarda como un precio de compra
 IF (not nullvalue(rarticulo.apreciocompra)) THEN
 /*Ma.La.Pi 11-06-2013 Por el momento no me interesan los precios de compras por prestador, solo por articulo
   pero igual se guardan para un futuro.*/

            SELECT INTO precio * FROM far_preciocompra
                 WHERE idarticulo = rarticulo.idarticulo AND idcentroarticulo = rarticulo.idcentroarticulo
                 and nullvalue(pcfechafin);
                 
                 IF FOUND THEN
                       if(precio.preciocompra <>  rarticulo.apreciocompra) THEN
                              UPDATE far_preciocompra SET pcfechafin = now()
                                     WHERE idarticulo =rarticulo.idarticulo AND idcentroarticulo = rarticulo.idcentroarticulo
                                           and nullvalue(pcfechafin);
                               INSERT INTO far_preciocompra(idarticulo,idprestador,preciocompra,idusuariocarga,idcentroarticulo)
                               VALUES(rarticulo.idarticulo,null,rarticulo.apreciocompra,rarticulo.idusuario,rarticulo.idcentroarticulo);

                          END IF;
                 ELSE
                         INSERT INTO far_preciocompra(idarticulo,idprestador,preciocompra,idusuariocarga,idcentroarticulo)
                         VALUES(rarticulo.idarticulo,null,rarticulo.apreciocompra,rarticulo.idusuario,rarticulo.idcentroarticulo);

                 END IF;
              END IF; -- not nullvalue(rarticulo.preciocompra)

 fetch cursorarticulos into rarticulo;
 END LOOP;
 close cursorarticulos;
 
/*KR 08-04-22 si el precio viene de un archivo lo guardo */
 IF (existecolumtemp('far_articulo_temp','idfilename')) THEN
    SELECT INTO rarchivo * FROM far_articulo_temp WHERE not nullvalue(idfilename);
    
    IF FOUND THEN 
      PERFORM sys_procesararchivodroguerias('');
    END IF;
 END IF;

return true;
END;$function$
