CREATE OR REPLACE FUNCTION multivac.depurartmp()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
rfacturaventatmp RECORD;
rs CURSOR FOR
   SELECT *
   from multivac.facturaventatmp
   WHERE estaanulada=1;
aux record;
respuesta boolean;
rta2 boolean;

begin
respuesta='true';
OPEN rs;
FETCH rs into aux;
while found loop
      SELECT INTO rfacturaventatmp
       *  FROM multivac.facturaventatmp
       WHERE tipocomprobante = aux.tipocomprobante
       and nrosucursal = aux.nrosucursal
       and nrofactura = aux.nrofactura
       and centro = aux.centro
       and tipofactura = aux.tipofactura
       and iditem = aux.iditem
       and estaanulada = 0;
       if found then
         DELETE from multivac.facturaventatmp
         WHERE  tipocomprobante = aux.tipocomprobante
         and nrosucursal = aux.nrosucursal
         and nrofactura = aux.nrofactura
         and centro = aux.centro
         and tipofactura = aux.tipofactura
         and iditem = aux.iditem
         and estaanulada = 1;
         
         UPDATE multivac.facturaventatmp
         SET importesosunc = 0,
               importectacte = 0,
               importeefectivo = 0,
               importeamuc = 0,
               importedebito = 0,
               importecredito = 0,
               importe = 0,
               estaanulada = 1
         WHERE  tipocomprobante = aux.tipocomprobante
         and nrosucursal = aux.nrosucursal
         and nrofactura = aux.nrofactura
         and centro = aux.centro
         and tipofactura = aux.tipofactura
         and iditem = aux.iditem;
       end if;
      fetch rs into aux;
end loop;
CLOSE rs;
return respuesta;
end;
$function$
