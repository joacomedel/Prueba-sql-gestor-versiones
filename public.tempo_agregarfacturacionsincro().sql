CREATE OR REPLACE FUNCTION public.tempo_agregarfacturacionsincro()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
aux record;

begin
select into aux * from agregarsincronizable('factura');
select into aux * from agregarsincronizable('festados');
select into aux * from agregarsincronizable('facturaprestaciones');
select into aux * from agregarsincronizable('facturacionfechas');
select into aux * from agregarsincronizable('debitofacturaprestador');
--select into aux * from agregarsincronizable('facturaprestacionescentrocosto');
select into aux * from agregarsincronizable('tipoprestacion');
--select into aux * from agregarsincronizable('centrocosto');
return true;
end;
$function$
