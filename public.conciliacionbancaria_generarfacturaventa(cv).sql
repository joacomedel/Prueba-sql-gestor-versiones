CREATE OR REPLACE FUNCTION public.conciliacionbancaria_generarfacturaventa(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

        rfiltros record;
        rconc  record;
        elcomprobante record;
        elidfacturaventacupon bigint;


BEGIN
    EXECUTE sys_dar_filtros($1) INTO rfiltros;

   SELECT INTO rconc split_part(  baidcliente,'/',1) as nrocliente ,  split_part(  baidcliente,'/',2)::integer as barra,* 
   FROM conciliacionbancaria 
   JOIN cuentabancariasosunc using(idcuentabancaria)
   JOIN banco using (idbanco)
   WHERE idconciliacionbancaria = rfiltros.idconciliacionbancaria 
      AND idcentroconciliacionbancaria = rfiltros.idcentroconciliacionbancaria ;

    --desccomprobanteventa=X, idtipofactura=RC, accion=guardarAcomp, monto=12345

    --------------------------
    -- 1 Creo el comprobante
    --------------------------
     CREATE TEMP TABLE tempfacturaventa (
    centro INTEGER,
    tipocomprobante integer,
    tipofactura character varying(2),
    nrosucursal integer,
    nrodoc varchar,
    barra integer
    );


    INSERT INTO tempfacturaventa(centro,tipocomprobante,tipofactura,nrosucursal,nrodoc,barra)
    VALUES(centro(),rfiltros.idtipo,rfiltros.idtipofactura,1,rconc.nrocliente,rconc.barra);



    CREATE TEMP TABLE temitemfacturaventa (
    idconcepto   	character varying,
    descripcion  	character varying,
    idiva integer,
    cantidad integer,
    iditemcc integer,
    importe  	double precision
    );
    INSERT INTO temitemfacturaventa(idconcepto,descripcion,idiva,cantidad,importe)
    VALUES(rfiltros.idconcepto,rfiltros.descripcion,1,1,rfiltros.monto);



    CREATE TEMP TABLE tempfacturaventacupon (
    monto  	double precision,
    idvalorescaja integer,
    autorizacion  	character varying,
    nrotarjeta  	character varying,
    cuotas integer,
    nrocupon  	character varying
    );

   SELECT INTO elcomprobante *
   FROM  asentarcomprobantefacturacion() as (nrofactura bigint, tipocomprobante integer, nrosucursal integer, tipofactura varchar, seimprime boolean);







   INSERT INTO facturaventacupon(monto,idvalorescaja,nrotarjeta,cuotas,nrocupon,nrofactura ,tipocomprobante,nrosucursal,tipofactura,autorizacion)
   VALUES(rfiltros.monto,rconc.idvalorescajacuentab,'0',0,'0',elcomprobante.nrofactura ,elcomprobante.tipocomprobante,elcomprobante.nrosucursal,elcomprobante.tipofactura,'0');

   elidfacturaventacupon = currval('facturaventacupon_idfacturacupon_seq');
    
    UPDATE facturaventa SET fechaemision = rfiltros.fechaemision
    WHERE nrofactura = elcomprobante.nrofactura 
          and tipocomprobante = elcomprobante.tipocomprobante 
          and nrosucursal = elcomprobante.nrosucursal
          and tipofactura = elcomprobante.tipofactura ;


RETURN concat(elcomprobante.nrofactura,'|',elcomprobante.tipocomprobante,'|',elcomprobante.nrosucursal,'|',elcomprobante.tipofactura);
END;
$function$
