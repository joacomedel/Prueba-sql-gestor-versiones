CREATE OR REPLACE FUNCTION public.temp_modificacionturismo()
 RETURNS void
 LANGUAGE plpgsql
AS $function$declare 
tem record;
begin
--select into tem * from pg_class where relname='informefacturacionturismo';
--if found then

select into tem *  from agregarsincronizable('informefacturacionaporte');
select into tem * from agregarsincronizable('informefacturacionturismo');
select into tem * from agregarsincronizable('grupoacompaniante');
select into tem * from agregarsincronizable('informefacturacionestado');
select into tem * from agregarsincronizable('consumoturismo');

update informefacturacionaporte set idaporte=idaporte;
update grupoacompaniante set nrodoc=nrodoc;
update informefacturacionestado set idcentroinformefacturacion=idcentroinformefacturacion;
update consumoturismo set idconsumoturismo=idconsumoturismo;
update informefacturacionturismo set nroinforme=nroinforme;
end;
$function$
