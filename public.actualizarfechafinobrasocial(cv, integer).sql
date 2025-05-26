CREATE OR REPLACE FUNCTION public.actualizarfechafinobrasocial(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
actualizarfechafinobrasocial(nrodoc,barra,fechafinObraSocial)
*/

declare
resp boolean;
nrod alias for $1;
bar alias for $2;
tipod integer;
dato record;
fecha date;
/*
benefs CURSOR FOR
     SELECT
           public.benefsosunc.nrodoc,
           public.benefsosunc.tipodoc
     FROM
           public.benefsosunc
     WHERE (public.benefsosunc.nrodoctitu=nrod)
           AND (public.benefsosunc.tipodoctitu=tipod);
*/
begin
resp = false;
SELECT MAX(public.cargo.fechafinlab) into fecha
  FROM public.cargo
       INNER JOIN public.persona ON (public.cargo.tipodoc=public.persona.tipodoc)
       AND (public.cargo.nrodoc=public.persona.nrodoc)
  WHERE
       (public.persona.barra = bar) AND
       (public.persona.nrodoc = nrod);
fecha = fecha + 90;
select into tipod
       persona.tipodoc
       from persona
       where persona.nrodoc=nrod;
/*
open benefs;
fetch benefs into dato;
while found loop
  UPDATE persona
         set fechafinos = fecha
         where (nrodoc=dato.nrodoc)
           and (tipodoc=dato.tipodoc);
  fetch benefs into dato;
end loop;
close benefs;
*/
UPDATE persona
     set fechafinos=fecha
     where (nrodoc=nrod)
           and (tipodoc=tipod);
resp = true;
return resp;
end;
$function$
