CREATE OR REPLACE FUNCTION public.detallepedidoxprestador_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;


-- GK 16-05-2022 - Agrego fecha facturación
-- GK 17-10-2022 - Cambios solicitados por usuario importe total / unitario y diferentes cobertueas
CREATE TEMP TABLE temp_detallepedidoxprestador_contemporal
AS (
	SELECT *,
	  --,'1-Edad#edad@2-Nombres#nombres@3-Apellido#apellido@4-Nrodoc#nrodoc@5-Nomenclador#idsubespecialidad@6-Capitulo#idcapitulo@7-SubCapitulo#idsubcapitulo@8-Practica#idpractica@4-Nombre#pdescripcion@4-Plan Cobertura#descripcion@4-Centro Regional#cregional@4-Asoc.#acdecripcion@4-Importe#importe@4-Cantidad#cantidad'::text as mapeocampocolumna 
	     '1-Nro Factura#numfactura@2-MontoFactura#monto@3-numerofacturatext#numerofacturatext@4-pdescripcion#Descrip.Articulo@5-adescripcion#adescripcion@6-Cod.Barra#acodigobarra@7-rdescripcion#rdescripcion@8-Cantidad Pedida#picantidad@9-picantidadentregada#picantidadentregada@10-Fecha Pedido#pefechacreacion@11-Descrip.Pedido#pedescripcion@12-Usuariocierre#usuariocierre@13-Usuariocarga#usuariocarga@14-pcpcapreciocompra#pcpcapreciocompra@15-pcpapreciocompratotal#pcpapreciocompratotal'::text as mapeocampocolumna 
	     FROM (
	     		SELECT
	     				concat(tipocomprobantedesc,' - ', re.numfactura,' nroregistro:' ,re.numeroregistro, '-',re.anio) as numfactura,
	     				monto,
				      trim(numerofacturatext) as numerofacturatext,
				      pdescripcion,
				      adescripcion,
				      picantidad,
				      --idestadotipo,
				      picantidadentregada,
				      rdescripcion,
				      pefechacreacion,
				      acodigobarra,
				      pedescripcion,
				      usucierre.login as usuariocierre,
				      CASE WHEN nullvalue(usucarga.login) THEN 'Sin.Inf' ELSE usucarga.login END as usuariocarga,
				      CASE WHEN nullvalue(pc.pcpcapreciocompra) THEN 0 ELSE pcpcapreciocompra END as pcpcapreciocompra,
				      CASE WHEN nullvalue(pc.pcpcapreciocompra) THEN 0 ELSE pcpcapreciocompra*pcpcacantidad END as pcpapreciocompratotal
			

				FROM reclibrofact as re
				NATURAL JOIN tipocomprobante

				LEFT JOIN  (
                  SELECT
                        idusuario,
                        pcpcantidad,
                        pcppreciocompra,
                        idpedidoitem,
                        idcentropedido,
                        idpedido,
                        pcpprecioventasiniva,
                        idcentroprecargapedido,
                        pcpprecioventaconiva,
                        concat(tipofactura,' ',letra,' ',numfactura,' (',fechaemision,')' ) as numerofacturatext,
                        pcpcacantidad,
                        pcpcapreciocompra,
                        idprestador,
                        numfactura
                  FROM far_precargarpedido
                  LEFT JOIN far_precargarpedidocomprobante USING(idprecargarpedido,idcentroprecargapedido)
                  LEFT JOIN far_precargarpedidocomprobantearticulo as pcca USING(idprecargarpedido,idcentroprecargapedido,idprecargarpedidocompcatalogo,idcentroprecargarpedidocompcatalogo)
            ) as pc ON ( pc.idprestador=re.idprestador AND pc.numfactura like concat('%',re.numero,'%'))


				LEFT JOIN far_pedido  USING (idpedido,idcentropedido)
				LEFT JOIN far_pedidoitems USING (idpedidoitem)
				LEFT JOIN far_articulo ON (far_pedidoitems.idarticulo=far_articulo.idarticulo AND  far_pedidoitems.idcentroarticulo=far_articulo.idcentroarticulo)
				LEFT JOIN far_rubro USING (idrubro)
				LEFT JOIN far_pedidoestado as fpe ON  (fpe.idpedido= far_pedido.idpedido AND fpe.idcentropedido=far_pedido.idcentropedido)
				LEFT JOIN prestador ON  (prestador.idprestador=re.idprestador )
				LEFT JOIN usuario as usucierre on(pidusuariocarga=usucierre.idusuario)
				LEFT JOIN usuario as usucarga on(pc.idusuario=usucarga.idusuario)
				/*
				WHERE
			      re.idprestador=5711
			      AND pc.idpedido=11857 
			      AND pc.idcentropedido=99
			      AND '2023-10-01'<=re.fechaemision
			      AND re.fechaemision<= '2023-10-31'*/

				WHERE 
				 	(idestadotipo=3 OR nullvalue(idestadotipo))
				 	AND prestador.nrocuentac =20302 
					AND (re.idprestador=rfiltros.idprestador OR nullvalue(rfiltros.idprestador)) 
					AND (rfiltros.fechadesde  <= re.fechaemision  AND re.fechaemision <= rfiltros.fechahasta +1)


	) as pedidofacturados

	ORDER BY numfactura,acodigobarra

	

);
  

return true;
END;
$function$
