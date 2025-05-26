CREATE OR REPLACE FUNCTION public.far_eliminartuplasespureasfacturaventa(timestamp without time zone, integer, integer, character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

     pcc alias for $1;
     pfacturadesde alias for $2;
     pfacturahasta alias for $3;
     pesquema alias for $4;
     pnrosucursal alias for $5;

BEGIN

IF pesquema = 'public' THEN 
	/*DELETE FROM facturaventa 
	WHERE nrofactura >=199331 and nrofactura <=199836 and nrosucursal = 4 and tipofactura = 'FA' and tipocomprobante = 1 
	AND (tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,importeamuc,importeefectivo,importedebito,importecredito,importectacte,importesosunc,fechaemision,formapago,tipofactura,anulada,barra,fechacreacion,facturaventacc) NOT IN (
	select tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,importeamuc,importeefectivo,importedebito,importecredito,importectacte,importesosunc,fechaemision,formapago,tipofactura,anulada,barra,fechacreacion,facturaventacc 
	from facturaventa 
	where nrofactura >=199331 and nrofactura <=199836 and nrosucursal = 4 and tipofactura = 'FA' and tipocomprobante = 1 
	and facturaventacc = '2015-08-27 07:05:48.410897'
	);*/
ELSE 
	DELETE FROM sincro.facturaventa 
	WHERE nrofactura >=pfacturadesde and nrofactura <=pfacturahasta and nrosucursal = pnrosucursal and tipofactura = 'FA' and tipocomprobante = 1 
	AND (tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,importeamuc,importeefectivo,importedebito,importecredito,importectacte,importesosunc,fechaemision,formapago,tipofactura,anulada,barra,fechacreacion,facturaventacc) NOT IN (
	select tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,importeamuc,importeefectivo,importedebito,importecredito,importectacte,importesosunc,fechaemision,formapago,tipofactura,anulada,barra,fechacreacion,facturaventacc 
	from sincro.facturaventa 
	where nrofactura >=pfacturadesde and nrofactura <=pfacturahasta and nrosucursal = pnrosucursal and tipofactura = 'FA' and tipocomprobante = 1 
	and facturaventacc = pcc
	);
END IF;

IF pesquema = 'public' THEN 
	/*DELETE FROM facturaorden 
	WHERE nrofactura >=199331 and nrofactura <=199836 and nrosucursal = 4 and tipofactura = 'FA' and tipocomprobante = 1 
	AND (nrosucursal,nrofactura,nroorden,centro,tipocomprobante,tipofactura,idcomprobantetipos,facturaordencc) NOT IN (
	SELECT nrosucursal,nrofactura,nroorden,centro,tipocomprobante,tipofactura,idcomprobantetipos,facturaordencc
	FROM facturaorden 
	where nrofactura >=199331 and nrofactura <=199836 and nrosucursal = 4 and tipofactura = 'FA' and tipocomprobante = 1 
	and facturaordencc = '2015-08-27 07:05:48.410897'
	);*/
ELSE 

	DELETE FROM sincro.facturaorden 
	WHERE nrofactura >=pfacturadesde and nrofactura <=pfacturahasta and nrosucursal = pnrosucursal and tipofactura = 'FA' and tipocomprobante = 1 
	AND (nrosucursal,nrofactura,nroorden,centro,tipocomprobante,tipofactura,idcomprobantetipos,facturaordencc) NOT IN (
	SELECT nrosucursal,nrofactura,nroorden,centro,tipocomprobante,tipofactura,idcomprobantetipos,facturaordencc
	FROM sincro.facturaorden 
	where nrofactura >=pfacturadesde and nrofactura <=pfacturahasta and nrosucursal = pnrosucursal and tipofactura = 'FA' and tipocomprobante = 1 
	and facturaordencc = pcc
	);
END IF;

IF pesquema = 'public' THEN 
	/*DELETE FROM itemfacturaventa 
	WHERE (nrosucursal,nrofactura,idconcepto,cantidad,importe,descripcion,idiva,iditem,tipocomprobante,tipofactura,itemfacturaventacc)
	IN 
	(
	SELECT nrosucursal,nrofactura,idconcepto,cantidad,importe,descripcion,idiva,iditem,tipocomprobante,tipofactura,itemfacturaventacc 
	from itemfacturaventa 
	natural join facturaventa 
	where nrofactura >=199331 and nrofactura <=199836 and nrosucursal = 4 and tipofactura = 'FA' and tipocomprobante = 1  
	AND (nrosucursal,nrofactura,idconcepto,cantidad,importe,descripcion,idiva,iditem,tipocomprobante,tipofactura,itemfacturaventacc)  
	NOT IN 
	( select nrosucursal,nrofactura,idconcepto,cantidad,importe,descripcion,idiva,iditem,tipocomprobante,tipofactura,itemfacturaventacc
	from itemfacturaventa 
	natural join facturaventa 
	where nrofactura >=199331 and nrofactura <=199836 and nrosucursal = 4 and tipofactura = 'FA' and tipocomprobante = 1 
	and itemfacturaventacc = '2015-08-27 07:05:48.410897' )
	);*/
ELSE 

	DELETE FROM sincro.itemfacturaventa 
	WHERE (nrosucursal,nrofactura,idconcepto,cantidad,importe,descripcion,idiva,iditem,tipocomprobante,tipofactura,itemfacturaventacc)
	IN 
	(
	SELECT nrosucursal,nrofactura,idconcepto,cantidad,importe,descripcion,idiva,iditem,tipocomprobante,tipofactura,itemfacturaventacc 
	from sincro.itemfacturaventa 
	natural join sincro.facturaventa 
	where nrofactura >=pfacturadesde and nrofactura <=pfacturahasta and nrosucursal = pnrosucursal and tipofactura = 'FA' and tipocomprobante = 1  
	AND (nrosucursal,nrofactura,idconcepto,cantidad,importe,descripcion,idiva,iditem,tipocomprobante,tipofactura,itemfacturaventacc)  
	NOT IN 
	( select nrosucursal,nrofactura,idconcepto,cantidad,importe,descripcion,idiva,iditem,tipocomprobante,tipofactura,itemfacturaventacc
	from sincro.itemfacturaventa 
	natural join sincro.facturaventa 
	where nrofactura >=pfacturadesde and nrofactura <=pfacturahasta and nrosucursal = pnrosucursal and tipofactura = 'FA' and tipocomprobante = 1 
	and itemfacturaventacc = pcc )
	);
END IF;

IF pesquema = 'public' THEN

	/*DELETE FROM far_ordenventaitemitemfacturaventa
	WHERE (idordenventaitem,idcentroordenventaitem,iditem,nrofactura,nrosucursal,tipocomprobante,tipofactura,ovcantdevueltas,far_ordenventaitemitemfacturaventacc)
	IN (
	SELECT idordenventaitem,idcentroordenventaitem,iditem,nrofactura,nrosucursal,tipocomprobante,tipofactura,ovcantdevueltas,far_ordenventaitemitemfacturaventacc
	FROM far_ordenventaitemitemfacturaventa 
	NATURAL JOIN facturaventa 
	WHERE nrofactura >=199331 and nrofactura <=199836 and nrosucursal = 4 and tipofactura = 'FA' and tipocomprobante = 1 AND 
	(idordenventaitem,idcentroordenventaitem,iditem,nrofactura,nrosucursal,tipocomprobante,tipofactura,ovcantdevueltas,far_ordenventaitemitemfacturaventacc)
	NOT IN (
	SELECT idordenventaitem,idcentroordenventaitem,iditem,nrofactura,nrosucursal,tipocomprobante,tipofactura,ovcantdevueltas,far_ordenventaitemitemfacturaventacc
	FROM far_ordenventaitemitemfacturaventa 
	NATURAL JOIN facturaventa 
	WHERE nrofactura >=199331 and nrofactura <=199836 and nrosucursal = 4 and tipofactura = 'FA' and tipocomprobante = 1 
	and far_ordenventaitemitemfacturaventacc = '2015-08-27 07:05:48.410897'
	));*/
ELSE
	DELETE FROM sincro.far_ordenventaitemitemfacturaventa
	WHERE (idordenventaitem,idcentroordenventaitem,iditem,nrofactura,nrosucursal,tipocomprobante,tipofactura,ovcantdevueltas,far_ordenventaitemitemfacturaventacc)
	IN (
	SELECT idordenventaitem,idcentroordenventaitem,iditem,nrofactura,nrosucursal,tipocomprobante,tipofactura,ovcantdevueltas,far_ordenventaitemitemfacturaventacc
	FROM sincro.far_ordenventaitemitemfacturaventa 
	NATURAL JOIN sincro.facturaventa 
	WHERE nrofactura >=pfacturadesde and nrofactura <=pfacturahasta and nrosucursal = pnrosucursal and tipofactura = 'FA' and tipocomprobante = 1 AND 
	(idordenventaitem,idcentroordenventaitem,iditem,nrofactura,nrosucursal,tipocomprobante,tipofactura,ovcantdevueltas,far_ordenventaitemitemfacturaventacc)
	NOT IN (
	SELECT idordenventaitem,idcentroordenventaitem,iditem,nrofactura,nrosucursal,tipocomprobante,tipofactura,ovcantdevueltas,far_ordenventaitemitemfacturaventacc
	FROM sincro.far_ordenventaitemitemfacturaventa 
	NATURAL JOIN sincro.facturaventa 
	WHERE nrofactura >=pfacturadesde and nrofactura <=pfacturahasta and nrosucursal = pnrosucursal and tipofactura = 'FA' and tipocomprobante = 1 
	and far_ordenventaitemitemfacturaventacc = pcc
	));

END IF;

IF pesquema = 'public' THEN
	/*DELETE FROM facturaventacupon 
	WHERE nrofactura >=199331 and nrofactura <=199836 and nrosucursal = 4 and tipofactura = 'FA' and tipocomprobante = 1 AND 
	(idfacturacupon,centro,nrofactura,tipocomprobante,nrosucursal,tipofactura,idvalorescaja,autorizacion,nrotarjeta,monto,cuotas,nrocupon,fvcporcentajedto,facturaventacuponcc)
	NOT IN (
	select idfacturacupon,centro,nrofactura,tipocomprobante,nrosucursal,tipofactura,idvalorescaja,autorizacion,nrotarjeta,monto,cuotas,nrocupon,fvcporcentajedto,facturaventacuponcc from facturaventacupon 
	where nrofactura >=199331 and nrofactura <=199836 and nrosucursal = 4 and tipofactura = 'FA' and tipocomprobante = 1 
	and facturaventacuponcc = '2015-08-27 07:05:48.410897');*/
ELSE

	DELETE FROM sincro.facturaventacupon 
	WHERE nrofactura >=pfacturadesde and nrofactura <=pfacturahasta and nrosucursal = pnrosucursal and tipofactura = 'FA' and tipocomprobante = 1 AND 
	(idfacturacupon,centro,nrofactura,tipocomprobante,nrosucursal,tipofactura,idvalorescaja,autorizacion,nrotarjeta,monto,cuotas,nrocupon,fvcporcentajedto,facturaventacuponcc)
	NOT IN (
	select idfacturacupon,centro,nrofactura,tipocomprobante,nrosucursal,tipofactura,idvalorescaja,autorizacion,nrotarjeta,monto,cuotas,nrocupon,fvcporcentajedto,facturaventacuponcc 
	from sincro.facturaventacupon 
	where nrofactura >=pfacturadesde and nrofactura <=pfacturahasta and nrosucursal = pnrosucursal and tipofactura = 'FA' and tipocomprobante = 1 
	and facturaventacuponcc = pcc);
END IF;

IF pesquema = 'public' THEN

	/*DELETE FROM facturaventausuario 
	WHERE nrofactura >=199331 and nrofactura <=199836 and nrosucursal = 4 and tipofactura = 'FA' and tipocomprobante = 1 
	AND (tipocomprobante,nrosucursal,nrofactura,tipofactura,idusuario,nrofacturafiscal,facturaventausuariocc) NOT IN (
	SELECT tipocomprobante,nrosucursal,nrofactura,tipofactura,idusuario,nrofacturafiscal,facturaventausuariocc
	FROM facturaventausuario 
	WHERE nrofactura >=199331 and nrofactura <=199836 and nrosucursal = 4 and tipofactura = 'FA' and tipocomprobante = 1 
	and facturaventausuariocc = '2015-08-27 07:05:48.410897');*/

ELSE

	DELETE FROM sincro.facturaventausuario 
	WHERE nrofactura >=pfacturadesde and nrofactura <=pfacturahasta and nrosucursal =pnrosucursal and tipofactura = 'FA' and tipocomprobante = 1 
	AND (tipocomprobante,nrosucursal,nrofactura,tipofactura,idusuario,nrofacturafiscal,facturaventausuariocc) NOT IN (
	SELECT tipocomprobante,nrosucursal,nrofactura,tipofactura,idusuario,nrofacturafiscal,facturaventausuariocc
	FROM sincro.facturaventausuario 
	WHERE nrofactura >=pfacturadesde and nrofactura <=pfacturahasta and nrosucursal = pnrosucursal and tipofactura = 'FA' and tipocomprobante = 1 
	and facturaventausuariocc = pcc );

END IF;

IF pesquema = 'public' THEN
	/*DELETE FROM facturaventanofiscal
	WHERE nrofactura >=199331 and nrofactura <=199836 and nrosucursal = 4 and tipofactura = 'FA' and tipocomprobante = 1 
	     AND  (tipocomprobante,nrosucursal,nrofactura,tipofactura,fvnffechaemision,facturaventanofiscalcc) NOT IN (
		SELECT tipocomprobante,nrosucursal,nrofactura,tipofactura,fvnffechaemision,facturaventanofiscalcc 
		FROM facturaventanofiscal 
		WHERE nrofactura >=199331 and nrofactura <=199836 and nrosucursal = 4 and tipofactura = 'FA' and tipocomprobante = 1 
		AND facturaventanofiscalcc = '2015-08-27 07:05:48.410897');*/
ELSE
	DELETE FROM sincro.facturaventanofiscal
	WHERE nrofactura >=pfacturadesde and nrofactura <=pfacturahasta and nrosucursal = pnrosucursal and tipofactura = 'FA' and tipocomprobante = 1 
	     AND  (tipocomprobante,nrosucursal,nrofactura,tipofactura,fvnffechaemision,facturaventanofiscalcc) NOT IN (
		SELECT tipocomprobante,nrosucursal,nrofactura,tipofactura,fvnffechaemision,facturaventanofiscalcc 
		FROM sincro.facturaventanofiscal 
		WHERE nrofactura >=pfacturadesde and nrofactura <=pfacturahasta and nrosucursal = pnrosucursal and tipofactura = 'FA' and tipocomprobante = 1 
		AND facturaventanofiscalcc = pcc );
END IF;

return 'true';
END;
$function$
