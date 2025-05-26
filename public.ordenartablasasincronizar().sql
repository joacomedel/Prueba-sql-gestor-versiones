CREATE OR REPLACE FUNCTION public.ordenartablasasincronizar()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
	fila tablasasincronizar%ROWTYPE;
	ultimoorden integer;
	filamax text;
	cant integer;
begin
	ultimoorden:=1;
	update tablasasincronizar set orden = 0;
	select into cant count(*) from tablasasincronizar;
	for i in 1..cant loop
		filamax:='';
		for fila in select * from tablasasincronizar where orden = 0 order by orden loop
				if precede(fila.nombre, filamax) then
					filamax:=fila.nombre;
				end if;
		end loop;
		update tablasasincronizar set orden=ultimoorden where nombre=filamax;
		ultimoorden:=ultimoorden+1; 
	end loop;
return 'true';
end;
$function$
