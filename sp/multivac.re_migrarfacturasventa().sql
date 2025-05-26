CREATE OR REPLACE FUNCTION multivac.re_migrarfacturasventa()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
rs2 CURSOR FOR
   SELECT *
   from multivac.tmp_fac
   where multivac.tmp_fac.tipocomprobante<>0;

aux record;
respuesta boolean;

begin
respuesta='true';
OPEN rs2;
FETCH rs2 into aux;
while found loop
      -- Desmarco la Factura Migrada
      perform multivac.desmarcarfacturaventamigrada(aux.tipofactura,aux.nrosucursal,aux.nrofactura,aux.tipocomprobante);
      -- Vuelvo a Migrar el comprobante
      perform multivac.migrarfacturaventa(aux.tipofactura,aux.nrosucursal,aux.nrofactura,aux.tipocomprobante);

      fetch rs2 into aux;
end loop;
CLOSE rs2;
return respuesta;
end;
$function$
