CREATE OR REPLACE FUNCTION public.disparartareasprogramadas()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
	tareasprogramadas cursor for select * from tareaprogramada order by procedimiento;
	tarea record;
	sentencia text;
	horaactual integer;
	minutoactual integer;
	horaprog	integer;
	minutoprog integer;

begin
horaactual := extract(hour from CURRENT_TIMESTAMP);
minutoactual:= extract(minutes from CURRENT_TIMESTAMP);
raise notice 'HORA ACTUAL %',horaactual;
raise notice 'MINUTO ACTUAL %',minutoactual;
open tareasprogramadas;
fetch tareasprogramadas into tarea;
while FOUND loop
	horaprog := extract(hour from tarea.hora);
	minutoprog:= extract(minutes from tarea.hora);
        raise notice 'HORA TAREA %',horaprog;
        raise notice 'MINUTO TAREA %',minutoprog;
        raise notice 'TEST DE EJECUCION %', (((extract(day from (CURRENT_TIMESTAMP - tarea.ultimaejecucion)) = tarea.frecuencia) OR  			((tarea.frecuencia=0) and (CURRENT_DATE = tarea.fechaejecucion))) AND ((horaactual=horaprog) AND (minutoactual=minutoprog)));
	if (((extract(day from (CURRENT_TIMESTAMP - tarea.ultimaejecucion))+1 = tarea.frecuencia) OR  			((tarea.frecuencia=0) and (CURRENT_DATE = tarea.fechaejecucion))) AND ((horaactual=horaprog) AND (minutoactual=minutoprog))) and tarea.activa then
		sentencia := concat('SELECT ' , tarea.procedimiento , ';');
		execute sentencia;
		raise notice 'SE EJECUTA %', sentencia;
		update tareaprogramada set ultimaejecucion = CURRENT_TIMESTAMP where 			idtarea=tarea.idtarea;
	end if;
fetch tareasprogramadas into tarea;
end loop;
end;
$function$
