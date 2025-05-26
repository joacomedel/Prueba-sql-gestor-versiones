CREATE OR REPLACE FUNCTION public.sys_arreglardatosfacturaventa(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD       
rcambia RECORD;
rfiltros record; 
elem RECORD;
respuestaeliminar  boolean;
--CURSOR 
cursorac REFCURSOR;

--VARIABLES
vnroinforme BIGINT;
vnrofactura bigint;
vnrosucursal INTEGER;
vcentro INTEGER;
vtipofactura varchar;
vtipocomprobante INTEGER;
elcomprobante varchar; 
elcomprobanteoriginal varchar; 
vmovconceptoantes varchar;
vmovconceptodespues varchar;
pmovconcepto varchar;

BEGIN
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
 
 -- Antes que nada verifico que existan todas las FK que deben existir para garantizar la robustez y buen funcionamiento del SP
SELECT INTO respuestaeliminar * FROM existefkey();
IF (not respuestaeliminar) THEN return false; END IF ;

SELECT INTO rcambia * FROM facturaventausuario WHERE nrofactura =rfiltros.nrofactura and nrosucursal= rfiltros.nrosucursal and tipofactura =rfiltros.tipofactura
                 and tipocomprobante = rfiltros.tipocomprobante;
IF FOUND THEN 
     
        RAISE NOTICE 'Entro a modificar con  Filtros (%)', rfiltros;
    
        
	vnrosucursal =case when  not nullvalue(rfiltros.nrosucursaldestino) then rfiltros.nrosucursaldestino 
			when  rcambia.nrofactura <> rcambia.nrofacturafiscal then rcambia.nrosucursal
		end;
	vtipofactura =case when  not nullvalue(rfiltros.tipofacturadestino) then rfiltros.tipofacturadestino 
			when  rcambia.nrofactura <> rcambia.nrofacturafiscal then rcambia.tipofactura
		end;
	vtipocomprobante = case when  not nullvalue(rfiltros.tipocomprobantedestino) then rfiltros.tipocomprobantedestino 
			when  rcambia.nrofactura <> rcambia.nrofacturafiscal then rcambia.tipocomprobante
		end;
        vcentro = centro();
         pmovconcepto = rfiltros.movconcepto; 
	IF nullvalue(rfiltros.nrofacturadestino) OR nullvalue(rfiltros.nrofacturadestino) THEN 
	         RAISE NOTICE 'No me envian el Nro de Factura rfiltros.nrofacturadestino(%)', rfiltros.nrofacturadestino;
		IF not nullvalue(rfiltros.usarsiguientetalonario) AND rfiltros.usarsiguientetalonario = 'si' THEN 
                        SELECT into elem * FROM devolvernrofactura(0,vtipocomprobante::integer,vtipofactura,vnrosucursal::integer);
                        IF FOUND THEN
                                vnrofactura = elem.sgtenumero;
                                vcentro = elem.centro;
                                RAISE NOTICE 'Voy a usar la siguiente del talonario (%)', elem.sgtenumero;
				
                        END IF;
		ELSE
			vnrofactura = rcambia.nrofacturafiscal::integer;
		END IF;
        ELSE 
		vnrofactura =  rfiltros.nrofacturadestino;
			
        END IF;    
	
	elcomprobante = concat(vtipofactura,'|',vtipocomprobante,'|',vnrosucursal,'|',vnrofactura);
	elcomprobanteoriginal = concat(rcambia.tipofactura,'|',rcambia.tipocomprobante,'|',rcambia.nrosucursal,'|',rcambia.nrofactura);
	 RAISE NOTICE 'El comprobante destino es (%)', elcomprobante; 

	INSERT INTO configuraadminprocesosejecucion(idconfiguraadminprocesos,capedescripcion) VALUES(99, case when nullvalue(pmovconcepto) then 
concat('Voy a cambiar el nro del comprobante ',elcomprobanteoriginal,' por el comprobante ',elcomprobante) else pmovconcepto  end);
        RAISE NOTICE ' configuraadminprocesosejecucion (%)',rcambia;
	             --FA B 1001-00007660
	
	UPDATE asientogenerico SET idcomprobantesiges = elcomprobante
                                ,agdescripcion =concat(replace(agdescripcion,concat(lpad(rcambia.nrosucursal,4,'0'),'-',lpad(rcambia.nrofactura,8,'0')),concat(lpad(vnrosucursal,4,'0'),'-',lpad(vnrofactura,8,'0'))),' Voy a cambiar el nro del comprobante ',rcambia.tipofactura,' ',rcambia.nrofactura,'-',rcambia.nrosucursal,'/',rcambia.tipocomprobante,' por el comprobante ',elcomprobante)
	WHERE idasientogenericotipo = 6 AND idasientogenericocomprobtipo = 5  AND idcomprobantesiges= elcomprobanteoriginal;
	IF NOT FOUND THEN
		RAISE NOTICE 'No habia contabilidad para (%)', elcomprobanteoriginal;
	END IF;
	
        vmovconceptoantes = concat('Genera Deuda por Emision de ',rcambia.tipofactura,' ',rcambia.nrosucursal,' ',rcambia.nrofactura);
        vmovconceptodespues = concat('Genera Deuda por Emision de ',vtipofactura,' ',vnrosucursal,' ',vnrofactura);

	UPDATE ctactedeudacliente set movconcepto = concat(replace(movconcepto,vmovconceptoantes,vmovconceptodespues),case when nullvalue(pmovconcepto) then  concat( ' Cambio el nro. del comprobante ' ,elcomprobanteoriginal,' por el Nro. ',elcomprobante) else pmovconcepto end 
)		
        FROM ( SELECT  (nroinforme*100)+idcentroinformefacturacion  as idcomprobante
			FROM informefacturacion 
			WHERE nrofactura =rcambia.nrofactura and nrosucursal= rcambia.nrosucursal and tipofactura =rcambia.tipofactura and tipocomprobante = rcambia.tipocomprobante
				) AS T
	WHERE ctactedeudacliente.idcomprobante = T.idcomprobante AND ctactedeudacliente.idcomprobantetipos=21 ;
	IF NOT FOUND THEN
		RAISE NOTICE 'No habia ctactedeudacliente para (%)', elcomprobanteoriginal;
	END IF;
       
	UPDATE ctactepagocliente set movconcepto = concat(replace(movconcepto,vmovconceptoantes,vmovconceptodespues),case when nullvalue(pmovconcepto) then  concat( ' Cambio el nro. del comprobante ' ,elcomprobanteoriginal,' por el Nro. ',elcomprobante) else pmovconcepto end 
)		
		FROM ( SELECT  ctactepagocliente.idpago, ctactepagocliente.idcentropago
			FROM ctactedeudacliente JOIN ctactedeudapagocliente USING(iddeuda, idcentrodeuda) JOIN ctactepagocliente USING(idpago, idcentropago) 
			 JOIN informefacturacion ON ctactedeudacliente.idcomprobante = (nroinforme*100)+idcentroinformefacturacion
			WHERE  nrofactura =rcambia.nrofactura and nrosucursal= rcambia.nrosucursal and tipofactura =rcambia.tipofactura and tipocomprobante = rcambia.tipocomprobante
				) AS T
	WHERE ctactepagocliente.idpago = T.idpago and ctactepagocliente.idcentropago = T.idcentropago ;
	IF NOT FOUND THEN
		RAISE NOTICE 'No habia ctactepagocliente para (%)', elcomprobanteoriginal;
	END IF;

 --Esto solo se hace cuando el comprobante es una NC
        --Emision de NC 1001 5060
        vmovconceptoantes = concat('Emision de ',rcambia.tipofactura,' ',rcambia.nrosucursal,' ',rcambia.nrofactura);
        vmovconceptodespues = concat('Emision de ',vtipofactura,' ',vnrosucursal,' ',vnrofactura);
	UPDATE ctactepagocliente set movconcepto = concat(replace(movconcepto,vmovconceptoantes,vmovconceptodespues),case when nullvalue(pmovconcepto) then  concat( ' Cambio el nro. del comprobante ' ,elcomprobanteoriginal,' por el Nro. ',elcomprobante) else pmovconcepto end 
)		
		FROM ( SELECT  (nroinforme*100)+idcentroinformefacturacion  as idcomprobante
			FROM informefacturacion 
			WHERE nrofactura =rcambia.nrofactura and nrosucursal= rcambia.nrosucursal and tipofactura =rcambia.tipofactura and tipocomprobante = rcambia.tipocomprobante
				) AS T
	WHERE rcambia.tipofactura = 'NC' AND ctactepagocliente.idcomprobante = T.idcomprobante AND ctactepagocliente.idcomprobantetipos=21 ;
	IF NOT FOUND THEN
		RAISE NOTICE 'No habia ctactepagocliente para (%)', elcomprobanteoriginal;
	END IF;

	UPDATE informefacturacion  SET	 nrofactura = vnrofactura::bigint,
					 tipocomprobante = vtipocomprobante::bigint,
					 nrosucursal = vnrosucursal::bigint ,
					 tipofactura = vtipofactura,
					 idtipofactura = vtipofactura
	WHERE nrofactura =rcambia.nrofactura and nrosucursal= rcambia.nrosucursal and tipofactura =rcambia.tipofactura and tipocomprobante = rcambia.tipocomprobante;

	IF NOT FOUND THEN
		RAISE NOTICE 'No habia informefacturacion para (%)', elcomprobanteoriginal;
	END IF;

	IF (not nullvalue(rfiltros.modificarfv) and rfiltros.modificarfv='si') THEN 
	  
          UPDATE facturaventa SET nrofactura = vnrofactura,
					nrosucursal= vnrosucursal,
					tipofactura = vtipofactura,
					tipocomprobante = vtipocomprobante,
					centro = vcentro 
	       WHERE nrofactura =rcambia.nrofactura and nrosucursal= rcambia.nrosucursal and tipofactura =rcambia.tipofactura and tipocomprobante = rcambia.tipocomprobante;
	       IF NOT FOUND THEN
		        RAISE NOTICE 'No habia facturaventa para (%)', elcomprobanteoriginal;
	       END IF;
		   --- actualizo la info de la tabla del afip 
		   UPDATE facturaventa_wsafip   
		   SET nrofactura = vnrofactura,
			   nrosucursal= vnrosucursal,
			   tipofactura = vtipofactura,
			   tipocomprobante = vtipocomprobante   
		  WHERE nrofactura =rcambia.nrofactura and nrosucursal= rcambia.nrosucursal and tipofactura =rcambia.tipofactura and tipocomprobante = rcambia.tipocomprobante;
	      IF NOT FOUND THEN
		        RAISE NOTICE 'No habia facturaventa_wsafip para (%)', elcomprobanteoriginal;
	       END IF; 
	ELSE
		RAISE NOTICE ' Cambio el Nro en FACTURAVENTA (%)',rfiltros.modificarfv;
        END IF;
    

END IF;                 

return '';
END;

$function$
