CREATE OR REPLACE FUNCTION public.ejecutarmodificacionesenesquema()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
  esq record;
begin
      for esq in select nombresp from modificacionesquema loop
              execute concat('select ',esq.nombresp,';');
      end loop;
delete from modificacionesquema;
return true;
end;
$function$
