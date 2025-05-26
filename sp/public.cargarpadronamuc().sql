CREATE OR REPLACE FUNCTION public.cargarpadronamuc()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
padron cursor for select * from amucpadron;
itempadron record;
afil record;
personabajas refcursor;
itembajas record;
begin
open padron;
fetch padron into itempadron;
while FOUND loop
    select into afil * from afilidoc where nrodoc=itempadron.nrodoc and tipodoc=itempadron.tipodoc;
    if FOUND then
         if not afil.mutu then
              update afilidoc set mutu=true where nrodoc=itempadron.nrodoc and tipodoc=itempadron.tipodoc;
              insert into amucpadronaltastempo(nrodoc,tipodoc) values(itempadron.nrodoc,itempadron.tipodoc);
         end if;
    end if;
    select into afil * from afilinodoc where nrodoc=itempadron.nrodoc and tipodoc=itempadron.tipodoc;
    if FOUND then
      if not afil.mutu then
           update afilinodoc set mutu=true where nrodoc=itempadron.nrodoc and tipodoc=itempadron.tipodoc;
           insert into amucpadronaltastempo(nrodoc,tipodoc) values(itempadron.nrodoc,itempadron.tipodoc);
      end if;
    end if;
    select into afil * from afiliauto where nrodoc=itempadron.nrodoc and tipodoc=itempadron.tipodoc;
    if FOUND then
      if not afil.mutu then
           update afiliauto set mutu=true where nrodoc=itempadron.nrodoc and tipodoc=itempadron.tipodoc;
           insert into amucpadronaltastempo(nrodoc,tipodoc) values(itempadron.nrodoc,itempadron.tipodoc);
      end if;
    end if;
    select into afil * from afilirecurprop where nrodoc=itempadron.nrodoc and tipodoc=itempadron.tipodoc;
    if FOUND then
      if not afil.mutu then
           update afilirecurprop set mutu=true where nrodoc=itempadron.nrodoc and tipodoc=itempadron.tipodoc;
           insert into amucpadronaltastempo(nrodoc,tipodoc) values(itempadron.nrodoc,itempadron.tipodoc);
      end if;
    end if;
    select into afil * from afilisos where nrodoc=itempadron.nrodoc and tipodoc=itempadron.tipodoc;
    if FOUND then
      if not afil.mutu then
           update afilisos set mutu=true where nrodoc=itempadron.nrodoc and tipodoc=itempadron.tipodoc;
           insert into amucpadronaltastempo(nrodoc,tipodoc) values(itempadron.nrodoc,itempadron.tipodoc);
      end if;
    end if;
    fetch padron into itempadron;
    end loop;
close padron;

open personabajas for 
select nrodoc,tipodoc,barra from persona where
(nrodoc, tipodoc,barra) in (select * from (
(select nrodoc,tipodoc,barra from persona natural join afilidoc where mutu)
union 
(select nrodoc,tipodoc,barra from persona natural join afilinodoc where mutu)
union
(select nrodoc,tipodoc,barra from persona natural join afiliauto where mutu)
union
(select nrodoc,tipodoc,barra from persona natural join afilirecurprop where mutu)
union
(select nrodoc,tipodoc,barra from persona natural join afilisos where mutu)
) as foogen)

and (nrodoc,tipodoc) not in (select nrodoc,tipodoc from amucpadrontempo);

fetch personabajas into itembajas;
while FOUND loop
    if itembajas.barra=30 then
       update afilidoc set mutu=true where nrodoc=itembajas.nrodoc and tipodoc=itembajas.tipodoc;
    end if;
    if itembajas.barra=31 then
       update afilinodoc set mutu=true where nrodoc=itembajas.nrodoc and tipodoc=itembajas.tipodoc;
    end if;
    if itembajas.barra=32 then
       update afilisos set mutu=true where nrodoc=itembajas.nrodoc and tipodoc=itembajas.tipodoc;
    end if;
    if itembajas.barra=33 then
       update afilirecurprop set mutu=true where nrodoc=itembajas.nrodoc and tipodoc=itembajas.tipodoc;
    end if;
    insert into amucpadronbajastempo(nrodoc, tipodoc) values(itembajas.nrodoc, itembajas.tipodoc);
    fetch personabajas into itembajas;
end loop;


end;
$function$
