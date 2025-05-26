CREATE OR REPLACE FUNCTION public.liquidaciontarjeta_generarcuponfactura()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
        rliqi record;
rliqtarjeta record;
 rusuario  record;
        elcomprobante record;
rlacuenta record;
        elidfacturaventacupon bigint;
        result boolean;
        xtipofactura varchar(2);
elidusuario integer;
nrocuenta_haber  	character varying ;
idvalorcaja integer;


BEGIN
     SELECT INTO rliqi * FROM tliquidaciontarjetaitem;
     SELECT INTO rliqtarjeta * FROM liquidaciontarjeta WHERE idliquidaciontarjeta = rliqi.idliquidacion AND idcentroliquidaciontarjeta = rliqi.idcentrolt ;


    --------------------------
    -- 1 Creo el comprobante
    --------------------------
     CREATE TEMP TABLE tempfacturaventa (
    centro INTEGER,
    tipocomprobante integer,
    tipofactura character varying(2),
    nrosucursal integer,
    nrodoc varchar,
fvfechaemision  	date,
    barra integer
    
    );

--CS 2018-12-07 para que los negativos se conviertan en comprobantes tipo NCredito (CC)
    IF (rliqi.monto<0) then 
         xtipofactura='CC';
         --- VAS 130223 tk = 5156   nrocuenta_haber = '40710';
        
         SELECT INTO rlacuenta DISTINCT nrocuentac 
         FROM "public"."valorescajacomercio"
         JOIN multivac.formapagotiposcuentafondos USING(idvalorescaja	)
         JOIN multivac.mapeocuentasfondos USING(idcuentafondos) 
         WHERE idvalorescaja = rliqi.idvalorescaja;
         --nrocuenta_haber = 10374;   -- O 10377 si se trata de MP
         nrocuenta_haber = rlacuenta.nrocuentac;
         -- VAS 130223  idvalorcaja =  rliqi.idvalorescaja;
         idvalorcaja =  970;-- VAS 130223 
    ELSE 
         xtipofactura='CU';
         --- VAS 130223 tk = 5156   nrocuenta_haber = '10374';
         nrocuenta_haber = '40710';
         --- VAS 130223    idvalorcaja =  970;
         idvalorcaja =  rliqi.idvalorescaja; --- VAS 130223  
   
    END IF;
-- ------------------------------------------------------------------------------------
  INSERT INTO tempfacturaventa(centro,tipocomprobante,tipofactura,nrosucursal,nrodoc,barra,fvfechaemision)   
  
    VALUES(centro(), 1 ,xtipofactura,1,'00001234',1,rliqtarjeta.ltfechapago);



    CREATE TEMP TABLE temitemfacturaventa (
    idconcepto   	character varying,
    descripcion  	character varying,
    idiva integer,
    cantidad integer,
    iditemcc integer,
    importe  	double precision,
    subtotal DOUBLE PRECISION, 
    ivaimporte DOUBLE PRECISION
    );
--CS 2018-12-07 Cuenta 40710 - Falla de caja confirmado por VNovoa
    INSERT INTO temitemfacturaventa(idconcepto,descripcion,idiva,cantidad,importe,iditemcc)
  --  VALUES('40710','x generacion cupon faltante',1,1,rliqi.monto,1);
  VALUES(nrocuenta_haber,'x generacion cupon faltante',1,1,rliqi.monto,1);



    CREATE TEMP TABLE tempfacturaventacupon (
    monto  	double precision,
    idvalorescaja integer,
    autorizacion  	character varying,
    nrotarjeta  	character varying,
    cuotas integer,
    nrocupon  	character varying
    );

   SELECT INTO elcomprobante * FROM  asentarcomprobantefacturacion() as (nrofactura bigint, tipocomprobante integer, nrosucursal integer, tipofactura varchar, seimprime boolean);
   IF nullvalue(rliqi.cuotas)
   THEN rliqi.cuotas =1; END IF;

--- VAS 270622 se almacena el monto > 0
   INSERT INTO facturaventacupon(monto,idvalorescaja,nrotarjeta,cuotas,nrocupon,nrofactura ,tipocomprobante,nrosucursal,tipofactura,autorizacion)
   VALUES( rliqi.monto , idvalorcaja , rliqi.nrotarjeta ,rliqi.cuotas ,rliqi.nrocupon,elcomprobante.nrofactura,elcomprobante.tipocomprobante,elcomprobante.nrosucursal,elcomprobante.tipofactura,'0');

   elidfacturaventacupon = currval('facturaventacupon_idfacturacupon_seq');
   
   ----------------------------------------
   -- 2  Ingreso los datos del comprobante en el lote
   ----------------------------------------


   INSERT INTO facturaventacuponlote (nrofactura ,tipocomprobante,nrosucursal,tipofactura,nrolote,idfacturacupon,centro)
   VALUES(elcomprobante.nrofactura,elcomprobante.tipocomprobante,elcomprobante.nrosucursal,elcomprobante.tipofactura, rliqi.nrolote,elidfacturaventacupon ,centro() );

   -----------------------------------------------
   -- 3 Actualizo la tabla temporal para continuar
   -- con el proceso de vinculacion del itema a la liquidacion
   -----------------------------------------------
   UPDATE tliquidaciontarjetaitem SET
   idfacturacupon = elidfacturaventacupon,
   centro = centro(),
   nrofactura = elcomprobante.nrofactura ,
   tipocomprobante = elcomprobante.tipocomprobante,
   nrosucursal = elcomprobante.nrosucursal,
   tipofactura  = elcomprobante.tipofactura,
   accion='cargarCupon';


  -------------------------------------------------
  -- 4- registro el usuario que  
  ------------------------------------------------

  /* Se guarda la informacion del usuario que genero el comprobante */
     SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
     IF not found THEN
             elidusuario = 25;
     ELSE
             elidusuario = rusuario.idusuario;
     END IF;
    
     INSERT INTO facturaventausuario (tipocomprobante,nrosucursal, nrofactura, tipofactura, idusuario, nrofacturafiscal )
     VALUES   (elcomprobante.tipocomprobante,elcomprobante.nrosucursal,elcomprobante.nrofactura, elcomprobante.tipofactura,elidusuario,elcomprobante.nrofactura);

RETURN concat(elcomprobante.nrofactura,'|',elcomprobante.tipocomprobante,'|',elcomprobante.nrosucursal,'|',elcomprobante.tipofactura);
END;$function$
