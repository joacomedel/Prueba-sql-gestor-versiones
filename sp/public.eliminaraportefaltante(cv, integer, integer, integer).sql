CREATE OR REPLACE FUNCTION public.eliminaraportefaltante(character varying, integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
eliminaraportefaltante(nrodoc,barra,mes,anio)
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
       
-- Borra a los Beneficiarios
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
           
      DELETE FROM public.infaportesfaltantes
             where (nrodoc=dato.nrodoc)
                   and (tipodoc=dato.tipodoc)
                   and (infaportesfaltantes.mes=m)
                   and (infaportesfaltantes.anio=a);
      INSERT into aportesfaltantesregularizados
             VALUES (tupla.tipoinforme,tupla.fechamodificacion,tupla.anio,tupla.mes,tupla.nrodoc,tupla.barra,
                    tupla.tipodoc,tupla.nrotipoinforme,current_date);
  end loop;

-- Borra al Titular
SELECT * INTO tupla
      FROM infaportesfaltantes
      where (nrodoc=nrod)
           and (tipodoc=tipod)
           and (infaportesfaltantes.mes=m)
           and (infaportesfaltantes.anio=a);
DELETE FROM public.infaportesfaltantes
       where   (nrodoc=nrod)
           and (tipodoc=tipod)
           and (infaportesfaltantes.mes=m)
           and (infaportesfaltantes.anio=a);
INSERT into aportesfaltantesregularizados
       VALUES (tupla.tipoinforme,tupla.fechamodificacion,tupla.anio,tupla.mes,tupla.nrodoc,tupla.barra,
             tupla.tipodoc,tupla.nrotipoinforme,current_date);
resp = true;

--ACTUALIZAR FECHA FIN OBRA SOCIAL PARA TODOS EL AFILIADO Y SUS beneficiarios
select * into resp2
       from actualizarfechafinobrasocial(nrod,bar);

return resp and resp2;
end;
$function$
