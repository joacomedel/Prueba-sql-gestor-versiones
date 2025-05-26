CREATE OR REPLACE FUNCTION public.sys_arreglarnumeracionfacturaventa(bigint, integer, character varying, integer, bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

-------------
	pnrofactura  alias for $1;
	pnrosucursal alias for $2;
	ptipofactura  alias for $3;
	ptipocomprobante  alias for $4;
        pnrofacturahasta  alias for $5;
-------------

       /*pnrofactura bigint;
       pnrosucursal integer;
       ptipofactura varchar;
       ptipocomprobante  integer;
       */
       elmayor bigint;
       estanfk boolean;
       respuestaeliminar boolean;
      ---------------
       cureliminarcomprobante refcursor;
       reliminar RECORD;
       curcambiarnumeracion refcursor; 
       rcambia RECORD;


BEGIN
     /*pnrofactura  =200061;
     pnrosucursal =4;
     ptipocomprobante =1;
     ptipofactura  ='FA';*/

      -- Antes que nada verifico que existan todas las FK que deben existir para garantizar la robustez y buen funcionamiento del SP
        SELECT INTO respuestaeliminar * FROM existefkey();
        IF (not respuestaeliminar) THEN return false; END IF ;
      -- Elimino las facturas que no tienen un numero asignado por el liquidador fiscal

 OPEN cureliminarcomprobante FOR SELECT tipocomprobante,nrosucursal,nrofactura,tipofactura,idusuario,nrofacturafiscal
				FROM facturaventausuario 
				WHERE nullvalue(nrofacturafiscal) AND nrosucursal = pnrosucursal 
				AND tipofactura = ptipofactura and tipocomprobante = ptipocomprobante
				AND nrofactura >=pnrofactura;
      FETCH cureliminarcomprobante INTO reliminar;
      WHILE  found LOOP 
	SELECT INTO respuestaeliminar far_eliminarcomprobantenoemitido(reliminar.nrofactura,reliminar.nrosucursal,reliminar.tipocomprobante,reliminar.tipofactura);
	IF respuestaeliminar THEN
		INSERT INTO configuraadminprocesosejecucion(idconfiguraadminprocesos,capedescripcion) 
		VALUES(99,concat('Elimino el comprobante ',reliminar.tipofactura,' ',reliminar.nrofactura,'-',reliminar.nrosucursal,'/',reliminar.tipocomprobante));
                --MaLapi 18-02-2019 Si se genero asiento contable, debe ser eliminado.
                DELETE FROM asientogenericoitem WHERE (idasientogenerico,idcentroasientogenerico) 
                         IN (SELECT idasientogenerico,idcentroasientogenerico 
                              FROM asientogenerico WHERE idasientogenericotipo = 6 AND idasientogenericocomprobtipo = 5 AND idcomprobantesiges = concat(reliminar.tipofactura,'|',reliminar.tipocomprobante,'|',reliminar.nrosucursal,'|',reliminar.nrofactura));
 
                DELETE FROM asientogenerico WHERE idasientogenericotipo = 6 AND idasientogenericocomprobtipo = 5 AND idcomprobantesiges = concat(reliminar.tipofactura,'|',reliminar.tipocomprobante,'|',reliminar.nrosucursal,'|',reliminar.nrofactura);
	END IF;
     FETCH cureliminarcomprobante INTO reliminar;
     END LOOP;
     CLOSE cureliminarcomprobante;


   -- Cambio la numeracion de los comprobantes teniendo en cuenta la tabla facturaventausuario
--KR 20-11-15 EL Orden es ASC o DESC según si se desplaza hacia arriba o hacia abajo respectivamente
--Malapi 06/01/2016 Ya no hay que cambiar el sp para ASC o DESC, se definen diferentes cursores. 
     OPEN curcambiarnumeracion FOR SELECT tipocomprobante,nrosucursal,nrofactura,tipofactura,idusuario
                                ,to_number(nrofacturafiscal, '9999999999') as  nrofacturafiscal
				FROM facturaventausuario 
				WHERE not nullvalue(nrofacturafiscal) AND nrosucursal = pnrosucursal 
				AND tipofactura = ptipofactura and tipocomprobante = ptipocomprobante
				AND nrofactura >=pnrofactura
                                AND nrofactura <> to_number(nrofacturafiscal, '9999999999')
                                AND to_number(nrofacturafiscal, '9999999999') > nrofactura  
				ORDER BY to_number(nrofacturafiscal, '9999999999') DESC;
      FETCH curcambiarnumeracion INTO rcambia;
      WHILE  found LOOP 
         
	 INSERT INTO configuraadminprocesosejecucion(idconfiguraadminprocesos,capedescripcion) 
	 VALUES(99,concat('Voy a cambiar el nro del comprobante ',rcambia.tipofactura,' ',rcambia.nrofactura,'-',rcambia.nrosucursal,'/',rcambia.tipocomprobante,' por el nro ',rcambia.nrofacturafiscal));
		
	 UPDATE facturaventa SET nrofactura = rcambia.nrofacturafiscal
         WHERE nrofactura =rcambia.nrofactura and nrosucursal= rcambia.nrosucursal and tipofactura =rcambia.tipofactura
                 and tipocomprobante = rcambia.tipocomprobante;

         --MaLaPi 18-02-2019 Modifico el asiento que se genero para el comprobante
         UPDATE asientogenerico SET idcomprobantesiges = concat(rcambia.tipofactura,'|',rcambia.tipocomprobante,'|',rcambia.nrosucursal,'|',rcambia.nrofacturafiscal)
                                ,agdescripcion =concat(agdescripcion,' Voy a cambiar el nro del comprobante ',rcambia.tipofactura,' ',rcambia.nrofactura,'-',rcambia.nrosucursal,'/',rcambia.tipocomprobante,' por el nro ',rcambia.nrofacturafiscal)
          WHERE idasientogenericotipo = 6 AND idasientogenericocomprobtipo = 5 
           AND idcomprobantesiges= concat(rcambia.tipofactura,'|',rcambia.tipocomprobante,'|',rcambia.nrosucursal,'|',rcambia.nrofactura);
        
                  

     FETCH curcambiarnumeracion INTO rcambia;
     END LOOP;
     CLOSE curcambiarnumeracion;

-- Malapi 06/01/2016 Para cuando el corrimiento es Ascendente

     OPEN curcambiarnumeracion FOR SELECT tipocomprobante,nrosucursal,nrofactura,tipofactura,idusuario
                                ,to_number(nrofacturafiscal, '9999999999') as  nrofacturafiscal
				FROM facturaventausuario 
				WHERE not nullvalue(nrofacturafiscal) AND nrosucursal = pnrosucursal 
				AND tipofactura = ptipofactura and tipocomprobante = ptipocomprobante
				AND nrofactura >=pnrofactura
                                AND nrofactura <> to_number(nrofacturafiscal, '9999999999')
                                AND to_number(nrofacturafiscal, '9999999999') < nrofactura
				ORDER BY to_number(nrofacturafiscal, '9999999999') ASC;
      FETCH curcambiarnumeracion INTO rcambia;
      WHILE  found LOOP 
         
	 INSERT INTO configuraadminprocesosejecucion(idconfiguraadminprocesos,capedescripcion) 
	 VALUES(99,concat('Voy a cambiar el nro del comprobante ',rcambia.tipofactura,' ',rcambia.nrofactura,'-',rcambia.nrosucursal,'/',rcambia.tipocomprobante,' por el nro ',rcambia.nrofacturafiscal));
		
	 UPDATE facturaventa SET nrofactura = rcambia.nrofacturafiscal
         WHERE nrofactura =rcambia.nrofactura and nrosucursal= rcambia.nrosucursal and tipofactura =rcambia.tipofactura
                 and tipocomprobante = rcambia.tipocomprobante;

         --MaLaPi 18-02-2019 Modifico el asiento que se genero para el comprobante
         UPDATE asientogenerico SET idcomprobantesiges = concat(rcambia.tipofactura,'|',rcambia.tipocomprobante,'|',rcambia.nrosucursal,'|',rcambia.nrofacturafiscal)
 ,agdescripcion =concat(agdescripcion,' Voy a cambiar el nro del comprobante ',rcambia.tipofactura,' ',rcambia.nrofactura,'-',rcambia.nrosucursal,'/',rcambia.tipocomprobante,' por el nro ',rcambia.nrofacturafiscal)

          WHERE idasientogenericotipo = 6 AND idasientogenericocomprobtipo = 5 
           AND idcomprobantesiges= concat(rcambia.tipofactura,'|',rcambia.tipocomprobante,'|',rcambia.nrosucursal,'|',rcambia.nrofactura); 
                  

     FETCH curcambiarnumeracion INTO rcambia;
     END LOOP;
     CLOSE curcambiarnumeracion;

    -- Arreglo el talonario 
	SELECT INTO elmayor max(nrofactura)
	FROM facturaventa
	WHERE nrosucursal=pnrosucursal
            and tipofactura = ptipofactura
            and tipocomprobante = ptipocomprobante;

      UPDATE talonario SET sgtenumero = elmayor + 1
      WHERE   nrosucursal=pnrosucursal and tipofactura = ptipofactura and tipocomprobante = ptipocomprobante ;


return 'true';
END;
$function$
