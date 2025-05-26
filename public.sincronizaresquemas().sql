CREATE OR REPLACE FUNCTION public.sincronizaresquemas()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
       esquemas CURSOR FOR select * from esquemasasincronizar WHERE essesincroniza;
	   esquema RECORD;
	   sinc boolean;
           res text;
begin
delete from logsincro;
	open esquemas;
	fetch esquemas into esquema;
	while FOUND loop
        begin
          select into sinc * from sincronizartablas(esquema.nombre);
  	      INSERT INTO fechassincronizacion VALUES(esquema.nombre,CURRENT_DATE); --agregar mas informacion en otra tabla
--              INSERT INTO logsincro(descripcionlogsincro) values(concat('Se termino de procesar ',esquema.nombre));
              if(sinc) then
                 res:= 'OK';
              else
                 res:= 'FALLO';
                 raise exception 'si dejo que se ejecute se pueden perder datos';
              end if;
               INSERT INTO logsincro(descripcionlogsincro) values(concat('RESULTADO DE SINCRONIZAR ', esquema.nombre ,': ',res));
	      fetch esquemas into esquema;
--        exception when others then
--              INSERT INTO logsincro(descripcionlogsincro) values(concat('Se termino de procesar ',esquema.nombre , ' pero ocurrieron --errores'));
              -- el insert en la tabla de log con el centro que no se pudo sincronizar.
--              fetch esquemas into esquema;
        end;
	end loop;
return 'true';
end;
$function$
