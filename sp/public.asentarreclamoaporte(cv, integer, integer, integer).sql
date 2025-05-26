CREATE OR REPLACE FUNCTION public.asentarreclamoaporte(character varying, integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
asentarreclamoaporte(nrodoc,barra,mes,anio)
*/

declare
resp boolean;
resp2 boolean;
nrod alias for $1;
bar alias for $2;
tipod integer;
m alias for $3;
a alias for $4;
dato record;
tupla record;

begin
resp = false;
resp2 = false;
select into tipod
       persona.tipodoc
       from persona
       where persona.nrodoc=nrod;

-- Actualiza a los Beneficiarios
for dato in
     SELECT
           public.benefsosunc.nrodoc,
           public.benefsosunc.tipodoc
           FROM  public.benefsosunc
           WHERE (public.benefsosunc.nrodoctitu=nrod)
                 AND (public.benefsosunc.tipodoctitu=tipod)
  loop
      SELECT * INTO tupla
             FROM infaportesfaltantes
             where (nrodoc=dato.nrodoc)
                   and (tipodoc=dato.tipodoc)
                   and (infaportesfaltantes.mes=m)
                   and (infaportesfaltantes.anio=a);

      UPDATE public.infaportesfaltantes
             SET fechareclamo = current_date
             where (nrodoc=dato.nrodoc)
                   and (tipodoc=dato.tipodoc)
                   and (infaportesfaltantes.mes=m)
                   and (infaportesfaltantes.anio=a);
  end loop;

-- Actualiza al Titular
SELECT * INTO tupla
      FROM infaportesfaltantes
      where (nrodoc=nrod)
           and (tipodoc=tipod)
           and (infaportesfaltantes.mes=m)
           and (infaportesfaltantes.anio=a);
UPDATE public.infaportesfaltantes
       set fechareclamo = current_date
       where   (nrodoc=nrod)
           and (tipodoc=tipod)
           and (infaportesfaltantes.mes=m)
           and (infaportesfaltantes.anio=a);
resp = true;
return resp;
end;
$function$
