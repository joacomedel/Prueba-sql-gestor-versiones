CREATE OR REPLACE FUNCTION public.temp_agregarcamposareintegros()
 RETURNS void
 LANGUAGE plpgsql
AS $function$DECLARE
 auxiliar RECORD;
begin
--select INTO auxiliar eliminartablasincronizable('recreintegro');
--select INTO auxiliar eliminartablasincronizable('reintegro');
--select INTO auxiliar agregarsincronizable('recreintegro');
--select INTO auxiliar agregarsincronizable('reintegro');
select INTO auxiliar agregarsincronizable('benefreci');
select INTO auxiliar agregarsincronizable('beneficiariosborrados');
select INTO auxiliar agregarsincronizable('beneficiariosreciborrados');
end;
$function$
