CREATE OR REPLACE FUNCTION public.actualizarfechafinosbenefsegunedad()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
        cursorbenefsosunc cursor for select * from benefsosunc join afilsosunc on(benefsosunc.nrodoctitu=afilsosunc.nrodoc and benefsosunc.tipodoctitu=afilsosunc.tipodoc) where afilsosunc.idestado!=4;
        aux RECORD;
        registrobenefsosunc RECORD;
begin
select into aux * from logtp('Comenzo actualizarfechafinosbenefsegunedad()');
      open cursorbenefsosunc;
      fetch cursorbenefsosunc into registrobenefsosunc;
      while FOUND loop
       select into aux * from actualizarlafechadefinosbenefsosunc(registrobenefsosunc.nrodoc,registrobenefsosunc.tipodoc);
       fetch cursorbenefsosunc into registrobenefsosunc;
      end loop;
      close cursorbenefsosunc;
select into aux * from logtp('termino actualizarfechafinosbenefsegunedad()');
return 'true';
end;
$function$
