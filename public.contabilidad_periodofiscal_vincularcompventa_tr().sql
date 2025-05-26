CREATE OR REPLACE FUNCTION public.contabilidad_periodofiscal_vincularcompventa_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
   rtfvliquidacioniva RECORD;
BEGIN
   
  SELECT INTO rtfvliquidacioniva * 
  FROM tipofacturaventa
  WHERE idtipofactura = NEW.tipofactura;--AND tfvliquidacioniva;
--KR 15-06-21 cambio pq tfvliquidacioniva tienen false para DI y OT
  IF FOUND THEN
    IF rtfvliquidacioniva.tfvliquidacioniva THEN
                perform contabilidad_periodofiscal_vincularcomprobante ( concat('{fechaemicioncomp=',NEW.fechaemision, ',pftipoiva=V ,nrofactura=',NEW.nrofactura,', tipocomprobante=',NEW.tipocomprobante,' ,nrosucursal=',NEW.nrosucursal,',tipofactura=',NEW.tipofactura,'}'));
    END IF;
    IF rtfvliquidacioniva.tfvcontrolcaja THEN
                    perform tesoreria_controlcaja_vincularcomprobante ( concat('{fechaemicioncomp=',NEW.fechaemision, ',nrofactura=',NEW.nrofactura,', tipocomprobante=',NEW.tipocomprobante,' ,nrosucursal=',NEW.nrosucursal,',tipofactura=',NEW.tipofactura,'}'));
    END IF;
  END IF;
  RETURN NEW;
END;
$function$
