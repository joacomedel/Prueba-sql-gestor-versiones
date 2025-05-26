CREATE OR REPLACE FUNCTION multivac.migrarfacturaventa(ptipofactura character varying, pnrosucursal integer, pnrofactura bigint, ptipocomprobante integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
rfacturaventatmp RECORD;
rs CURSOR FOR
   SELECT f.*
   from multivac.facturasventatotal as f
        left join multivac.facturaventa_migrada as m on (f.tipocomprobante=m.tipocomprobante and f.nrosucursal=m.nrosucursal
        and f.nrofactura=m.nrofactura and f.centro=m.centro and f.tipofactura=m.tipofactura and f.iditem=m.iditem)
   WHERE f.tipofactura=ptipofactura and f.nrosucursal=pnrosucursal and f.nrofactura=pnrofactura and f.tipocomprobante=ptipocomprobante;

aux record;
respuesta boolean;
rta2 boolean;

begin
-- Borra la tabla Temporal antes de comenzar la exportacion
delete from multivac.facturaventatmp
   WHERE tipofactura=ptipofactura and nrosucursal=pnrosucursal and nrofactura=pnrofactura and tipocomprobante=ptipocomprobante;

respuesta='true';
OPEN rs;
FETCH rs into aux;
while found loop

IF(aux.importe < 0
               or aux.importesosunc < 0
               or aux.importectacte < 0
               or aux.importeefectivo < 0
               or aux.importeamuc < 0
               or aux.importedebito < 0
               or aux.importecredito < 0) THEN

SELECT INTO rfacturaventatmp *  FROM multivac.facturaventatmp
       WHERE tipocomprobante = aux.tipocomprobante
       and nrosucursal = aux.nrosucursal
       and nrofactura = aux.nrofactura
       and centro = aux.centro
       and tipofactura = aux.tipofactura
       and iditem = aux.iditem
       and estaanulada = 1;

IF FOUND THEN
         UPDATE multivac.facturaventatmp SET importesosunc = importesosunc + aux.importesosunc,
               importectacte = importectacte + aux.importectacte,
               importeefectivo = importeefectivo + aux.importeefectivo,
               importeamuc = importeamuc +  aux.importeamuc,
               importedebito = importedebito +  aux.importedebito,
               importecredito = importecredito + aux.importecredito,
               importe = importe + aux.importe
         WHERE  tipocomprobante = aux.tipocomprobante
         and nrosucursal = aux.nrosucursal
         and nrofactura = aux.nrofactura
         and centro = aux.centro
         and tipofactura = aux.tipofactura
         and iditem = aux.iditem
         and estaanulada = 1;

       ELSE
/* Lo comento para evitar que las ordenes anuladas se carguen 2 veces. cristian
              insert into multivac.facturaventa_migrada(tipocomprobante,nrosucursal,nrofactura,centro,tipofactura,iditem,fechamigracion,estaanulada)
              values (aux.tipocomprobante,aux.nrosucursal,aux.nrofactura,aux.centro, aux.tipofactura,aux.iditem,CURRENT_TIMESTAMP,1);

              insert into multivac.facturaventatmp
              values (aux.tipocomprobante,aux.nrosucursal,aux.nrofactura,aux.nrodoc,aux.tipodoc,
              aux.ctacontable,aux.centro,aux.importeamuc,aux.importeefectivo,aux.importedebito,
              aux.importecredito,aux.importectacte,aux.importesosunc,aux.fechaemision,aux.formapago,
              aux.tipofactura,aux.anulada,aux.idconcepto,aux.cantidad,aux.importe,aux.descripcion,
              aux.idiva,aux.iditem,'','',aux.barra,1);
*/
      END IF;

ELSE -- Se va a insertar una Orden que no esta Anulada

SELECT INTO rfacturaventatmp * FROM multivac.facturaventatmp
       WHERE tipocomprobante = aux.tipocomprobante
       and nrosucursal = aux.nrosucursal
       and nrofactura = aux.nrofactura
       and centro = aux.centro
       and tipofactura = aux.tipofactura
       and iditem = aux.iditem
       and estaanulada = 0;

IF FOUND THEN
         UPDATE multivac.facturaventatmp SET importesosunc = importesosunc + aux.importesosunc,
               importectacte = importectacte + aux.importectacte,
               importeefectivo = importeefectivo + aux.importeefectivo,
               importeamuc = importeamuc +  aux.importeamuc,
               importedebito = importedebito +  aux.importedebito,
               importecredito = importecredito + aux.importecredito,
               importe = importe + aux.importe
         WHERE  tipocomprobante = aux.tipocomprobante
         and nrosucursal = aux.nrosucursal
         and nrofactura = aux.nrofactura
         and centro = aux.centro
         and tipofactura = aux.tipofactura
         and iditem = aux.iditem
         and estaanulada = 0;

       ELSE

           insert into multivac.facturaventa_migrada(tipocomprobante,nrosucursal,nrofactura,centro,tipofactura,iditem,fechamigracion)
           values (aux.tipocomprobante,aux.nrosucursal,aux.nrofactura,aux.centro, aux.tipofactura,aux.iditem,CURRENT_TIMESTAMP);


           insert into multivac.facturaventatmp
           values (aux.tipocomprobante,aux.nrosucursal,aux.nrofactura,aux.nrodoc,aux.tipodoc,
             aux.ctacontable,aux.centro,aux.importeamuc,aux.importeefectivo,aux.importedebito,
             aux.importecredito,aux.importectacte,aux.importesosunc,aux.fechaemision,aux.formapago,
             aux.tipofactura,aux.anulada,aux.idconcepto,aux.cantidad,aux.importe,aux.descripcion,
             aux.idiva,aux.iditem,'','',aux.barra);
      END IF;
END IF;

--      if found THEN
--         if aux.fechaemision>='2008/06/17' then
--                  select * into rta2 from multivac.marcarcomomigradafacturaventa(aux.tipofactura,aux.tipocomprobante,aux.nrosucursal,aux.nrofactura);
--         end if;
--      end if;
      fetch rs into aux;
end loop;
CLOSE rs;
return respuesta;
end;
$function$
