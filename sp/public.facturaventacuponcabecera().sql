CREATE OR REPLACE FUNCTION public.facturaventacuponcabecera()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$/* New function body */

DECLARE
       elnuevoreg record;
       elimporteefectivo DOUBLE PRECISION;
       elimportectacte DOUBLE PRECISION;

BEGIN
  elnuevoreg = null;
  IF (TG_OP ='DELETE')  THEN
        elnuevoreg = OLD;
  ELSE 
         elnuevoreg = NEW;
        
  END IF;
       elimporteefectivo=0;
       elimportectacte =0;


  SELECT INTO  elimporteefectivo case when nullvalue(SUM(monto)) then 0 else SUM(monto) end as elimporteefectivo 
  FROM facturaventacupon
  NATURAL JOIN valorescaja
  WHERE   idformapagotipos <> 3
          and nrosucursal = elnuevoreg.nrosucursal
          and nrofactura = elnuevoreg.nrofactura
          and tipofactura = elnuevoreg.tipofactura
          and tipocomprobante = elnuevoreg.tipocomprobante
  group BY nrosucursal,nrofactura,tipofactura,tipocomprobante ;
if not found then  elimporteefectivo=0;
end if;
  
  SELECT INTO   elimportectacte case when nullvalue(SUM(monto)) then 0 else SUM(monto) end as elimportectacte 
  FROM facturaventacupon
  NATURAL JOIN valorescaja
  WHERE   idformapagotipos = 3
          and nrosucursal = elnuevoreg.nrosucursal
          and nrofactura = elnuevoreg.nrofactura
          and tipofactura = elnuevoreg.tipofactura
          and tipocomprobante = elnuevoreg.tipocomprobante
  group BY nrosucursal,nrofactura,tipofactura,tipocomprobante ;
  if not found then  elimportectacte =0;
end if;
  -- actualizo la cabecera
  
  UPDATE facturaventa  SET importectacte = elimportectacte , importeefectivo = elimporteefectivo
  WHERE  nrosucursal = elnuevoreg.nrosucursal
         and nrofactura = elnuevoreg.nrofactura
         and tipofactura = elnuevoreg.tipofactura
         and tipocomprobante = elnuevoreg.tipocomprobante ;

 
RETURN elnuevoreg;
END;
$function$
