CREATE OR REPLACE FUNCTION public.padronamuc_cargarpadron()
 RETURNS void
 LANGUAGE plpgsql
AS $function$declare
itempadron record;
itembajas record;
existe record;
padron cursor for select * from padronamuc_padron;
bajas cursor for select nrodoc, tipodoc from padronamuc_afiliadosamuc where padronamuc_afiliadosamuc.amuc and (tipodoc, nrodoc) not in (select tipodoc,nrodoc from padronamuc_padron);

begin
delete from padronamuc_resultadotempo;
--delete from padronamuc_bajastempo;



open padron;
fetch padron into itempadron;
while FOUND loop
   select into existe * from persona where nrodoc=itempadron.nrodoc and tipodoc=itempadron.tipodoc;
   if FOUND then
      perform padronamuc_alta_persona(itempadron.tipodoc, itempadron.nrodoc);
   else
       insert into padronamuc_resultadotempo(nrodoc,tipodoc,resultado) values(itempadron.nrodoc,itempadron.tipodoc,'NO EXISTE');
   end if;
   fetch padron into itempadron;
end loop;
close padron;

open bajas;
fetch bajas into itembajas;
while FOUND loop
   perform padronamuc_baja_persona(itembajas.tipodoc, itembajas.nrodoc);
   fetch bajas into itembajas;
end loop;
close bajas;

end;
$function$
