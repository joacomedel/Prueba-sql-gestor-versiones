CREATE OR REPLACE FUNCTION public.salvarsecuencias()
 RETURNS void
 LANGUAGE plpgsql
AS $function$declare
seq record;
val integer;
consulta text;


begin
delete from backupsecuencias;
For seq in select relname from pg_class where relkind='S' and relnamespace=2200 loop
         EXECUTE concat('SELECT last_value FROM "',seq.relname,'";') INTO val;
         consulta = concat('SELECT pg_catalog.setval(''"',seq.relname,'"'',',val,', TRUE);');
         insert into backupsecuencias values(consulta);
END loop;
end;
$function$
