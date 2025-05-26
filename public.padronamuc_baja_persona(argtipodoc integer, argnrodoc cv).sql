CREATE OR REPLACE FUNCTION public.padronamuc_baja_persona(argtipodoc integer, argnrodoc character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
afil record;
novedades record;
begin
   select into afil * from persona where nrodoc=argnrodoc and tipodoc=argtipodoc;
   if afil.barra=30 then
         perform padronamuc_baja_afilidoc(argtipodoc, argnrodoc);
   else if afil.barra=31 then
         perform padronamuc_baja_afilinodoc(argtipodoc, argnrodoc);
   else if afil.barra=32 then
         perform padronamuc_baja_afilisos(argtipodoc, argnrodoc);
   else if afil.barra=37 then
         perform padronamuc_baja_afiliauto(argtipodoc, argnrodoc);
   else if afil.barra=33 then
         perform padronamuc_baja_afilirecurprop(argtipodoc, argnrodoc);
   else if afil.barra<30 then
         perform padronamuc_baja_benefsosunc(argtipodoc, argnrodoc);
   end if;
   end if;
   end if;
   end if;
   end if;
   end if;
end;
$function$
