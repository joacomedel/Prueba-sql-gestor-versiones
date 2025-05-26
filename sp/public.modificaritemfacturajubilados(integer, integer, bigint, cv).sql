CREATE OR REPLACE FUNCTION public.modificaritemfacturajubilados(integer, integer, bigint, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE


--VARIABLES
tipocomprobantep alias for $1;
nrosucursalp alias for $2;
nrofacturap alias for $3;
tipofacturap alias for $4;
sumimporte DOUBLE PRECISION;
totaliva DOUBLE PRECISION;
rverificacorresponde RECORD;
undato RECORD;

BEGIN
/* karina 16/10/2013 para utilizarlo independientemente de que exista un informe
SELECT INTO reginfo * FROM informefacturacion
WHERE informefacturacion.nroinforme=nroinfo AND informefacturacion.idcentroinformefacturacion=idcentro;
*/
/*Malapi: 05-04-2011 Hay que modificar los items de la Factura de Venta, para que tengan el IdIva que corresponde
  el IdIva, es 3 - 10,5%
  krozas: 22-07-2014 El idiva se pasa desde la aplicacion

UPDATE itemfacturaventa SET idiva = 3
WHERE itemfacturaventa.nrosucursal = nrosucursalp
AND itemfacturaventa.nrofactura =nrofacturap
AND itemfacturaventa.tipofactura=tipofacturap
AND itemfacturaventa.tipocomprobante=tipocomprobantep;
*/

--MaLaPi 04-01-2018 Hay que arreglar los conceptos de bonificacion solo si existen en la factura o si corresponde por conf. del concepto. 
SELECT INTO rverificacorresponde * FROM itemfacturaventa 
				   LEFT JOIN cuentascontables ON idconcepto = cuentascontables.nrocuentac
				   WHERE itemfacturaventa.nrosucursal = nrosucursalp
					AND itemfacturaventa.nrofactura =nrofacturap
					AND itemfacturaventa.tipofactura=tipofacturap
					AND itemfacturaventa.tipocomprobante=tipocomprobantep 
                                        AND not nullvalue(cuentascontables.nrocuentac) 
                                        AND cuentascontables.sebonificaiva 
				    LIMIT 1;
IF FOUND THEN  -- Al menos uno de los items se bonifica el iva

	DELETE FROM itemfacturaventa WHERE itemfacturaventa.nrosucursal = nrosucursalp
	AND itemfacturaventa.nrofactura =nrofacturap
	AND itemfacturaventa.tipofactura=tipofacturap
	AND itemfacturaventa.tipocomprobante=tipocomprobantep AND (idconcepto='20821' OR idconcepto='50840');


	SELECT INTO sumimporte sum(importe) FROM itemfacturaventa
	WHERE tipocomprobante=tipocomprobantep AND nrosucursal=nrosucursalp AND nrofactura=nrofacturap AND tipofactura=tipofacturap;

	--calculo el iva del 10.5%
	SELECT INTO totaliva (sumimporte * tipoiva.porcentaje)  FROM tipoiva WHERE tipoiva.idiva=3;

	totaliva = round(CAST(totaliva  AS numeric),3);
			
	--inserto dos nuevos items para la factura, el IVA y la bonificacion
	INSERT INTO itemfacturaventa (tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
	VALUES(tipocomprobantep,nrosucursalp,tipofacturap,nrofacturap,'20821',1,totaliva,'Iva Debito del 10.5%',3);

	-- CS 2017-02-10 queda sin efecto, Victor

	-- select into undato *
	--	FROM persona 
	--	JOIN ca.persona ON (penrodoc=nrodoc and idtipodocumento =tipodoc )
	--	join facturaventa using(tipodoc,nrodoc)
	--	NATURAL JOIN ca.grupoliquidacionempleado
	--	WHERE  	idgrupoliquidaciontipo = 2 and tipocomprobante=tipocomprobantep AND nrosucursal=nrosucursalp AND nrofactura=nrofacturap AND tipofactura=tipofacturap;

	-- if not found then

		INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
		VALUES(tipocomprobantep,nrosucursalp,tipofacturap,nrofacturap,'50840',1,totaliva * (-1),'Descuentos y Bonificaciones ',3);

	-- end if;
END IF; 
	
return true;
END;$function$
