CREATE OR REPLACE FUNCTION public.devolversolonro(centro integer, tipoc integer, tipof character varying, nrosucursal integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
declare
    elem RECORD;
begin
      SELECT into elem nrosucursal, sgtenumero as nrofactura FROM devolvernrofactura(centro,tipoc,tipof,nrosucursal);

 return elem.nrofactura;

end;
$function$
