CREATE OR REPLACE FUNCTION public.sleep(integer)
 RETURNS time without time zone
 LANGUAGE plpgsql
AS $function$
declare
seconds alias for $1;
later time;
thetime time;
begin
thetime := timeofday()::timestamp;
later := thetime + (concat(seconds::text , ' seconds'))::interval;
loop
if thetime >= later then
exit;
else
thetime := timeofday()::timestamp;
end if;
end loop;

return later;
end;
$function$
