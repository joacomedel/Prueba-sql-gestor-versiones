CREATE OR REPLACE FUNCTION public.expendio_asentarfacturaventa_global()
 RETURNS SETOF facturaventa
 LANGUAGE plpgsql
AS $function$declare

/*

CREATE TEMP TABLE temp_recibocliente (
    idrecibo bigint,
    centro INTEGER,
    nrodoc VARCHAR,
    tipodoc INTEGER
);

15-07-2019 MaLaPi: Modifico para que se pueda usar por el facturador de facturas online. Viene con la accion 'atogestion'. 
Ademas se le agregan a la tabla temp_recibocliente los campos idformapagotipos, idvalorescaja para saber que forma de pago se deben facturar y a que forma de pago se deben enviar
*/
   rtest RECORD;
   rfacturaventa public.facturaventa%rowtype;
 

BEGIN

SELECT INTO rtest * FROM temp_recibocliente LIMIT 1;

IF nullvalue(rtest.accion) OR rtest.accion = 'autogestion' THEN
	--RAISE EXCEPTION 'llamo a autogestion ';
	PERFORM expendio_asentarfacturaventa();
ELSE 
	--RAISE EXCEPTION 'llamo a informefacturacion ';
	PERFORM expendio_asentarfacturaventa_usandoinformefacturacion();
END IF;

FOR rfacturaventa in SELECT  facturaventa.* FROM tempfacturaventageneradas  JOIN facturaventa 
                                          USING (tipocomprobante, nrosucursal,nrofactura, tipofactura)
        loop
  return next rfacturaventa;
 END LOOP;


END;
$function$
