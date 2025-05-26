CREATE OR REPLACE FUNCTION public.inicializar()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
	sinc refcursor;
	t record;
begin
	open sinc for select nombretabla from sincronizacion;
	fetch sinc into t;
	while FOUND loop
		perform eliminartablasincronizable(t.nombretabla);
                perform agregarsincronizable(t.nombretabla);
		fetch sinc into t;
	end loop;
return 'true';
end;
$function$
