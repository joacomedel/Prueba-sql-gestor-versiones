CREATE OR REPLACE FUNCTION public.far_arreglar_preciosugerido()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
cursorarticulos CURSOR FOR SELECT * FROM facturaventa 
WHERE (tipocomprobante,nrosucursal,nrofactura,tipofactura) IN (
select tipocomprobante,nrosucursal,nrofactura,tipofactura
from facturaventausuario 
where  facturaventausuariocc = '2015-01-29 12:09:46.714128'
ORDER BY nrofactura::integer
)
ORDER BY nrofactura::integer
;



/*SELECT pas.* 
			FROM far_pedido NATURAL JOIN far_pedidoitems NATURAL JOIN far_articulo
			NATURAL JOIN far_precioarticulosugerido as pas
			WHERE idpedido=1917;*/
                          
        rarticulo RECORD;
	rartexistente record;
	rprecioventa record;
	rprecioventasugerido record;
	elidarticulo bigint;
	rprecioventavalor double precision;
        elidajuste bigint;
        resp boolean;
        existelote record;
        rtipoiva RECORD;
        rprecioarticulopadre RECORD;
	vporcentaje double precision;
	vporcentajemasuno double precision;
	precio RECORD;
	rusuario RECORD;
                          
BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;
                           
OPEN cursorarticulos;
FETCH cursorarticulos into rarticulo;
WHILE  found LOOP
/* 

	 --Malapi: Tener en cuenta que el campo pasvalorcompra en la tabla de precios guarda el precio de venta al publico
	    UPDATE far_precioarticulosugerido SET pasfechafin = now()
	    WHERE idarticulo = rarticulo.idarticulo 
	    AND idcentroarticulo =rarticulo.idcentroarticulo 
	    AND nullvalue(pasfechafin);

	    
	    INSERT INTO far_precioarticulosugerido(idarticulo,pasvaloranterior,pasvalor,pasimporteiva,
		pasvalorcompra,idcentroarticulo,pasidusuariocarga,paspreciocompraprestador)
	    VALUES(rarticulo.idarticulo,rarticulo.pasvaloranterior,rarticulo.pasvalor,rarticulo.pasimporteiva
           ,rarticulo.pasvalorcompra
           ,rarticulo.idcentroarticulo
           ,25
           ,rarticulo.paspreciocompraprestador);
*/

UPDATE  facturaventa SET nrofactura = nrofactura::integer -1
WHERE nrofactura =rarticulo.nrofactura 
 and nrosucursal= rarticulo.nrosucursal 
 and tipofactura =rarticulo.tipofactura and tipocomprobante = rarticulo.tipocomprobante;

	


fetch cursorarticulos into rarticulo;
END LOOP;
close cursorarticulos;

return true;

END;$function$
