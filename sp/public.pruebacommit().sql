CREATE OR REPLACE FUNCTION public.pruebacommit()
 RETURNS text
 LANGUAGE plpgsql
AS $function$declare
begin


insert into pruebacommit values('1');
insert into pruebacommit values('2');

insert into pruebacommit values('3');
insert into pruebacommit values('4');
insert into pruebacommit values('5');
return DETAIL;


end;
$function$
