CREATE OR REPLACE FUNCTION public.padronamuc_baja_afilidoc(argtipodoc integer, argnrodoc character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
afil record;
novedades record;

begin
select into afil * from afilidoc natural join persona where nrodoc=argnrodoc and tipodoc=argtipodoc;
if not afil.mutu then
          select into novedades * from amucnovedades where nrodoc=argnrodoc and tipodoc=argtipodoc and not annovedadalta;
          if not FOUND then
               insert into amucnovedades(nrodoc, tipodoc, nrodoctitu, tipodoctitu, nromutu, annomapetitu, annomape, legajosiu, barramutu, anmesingreso, ananioingreso, annovedadalta, anprocesado,anusuario, anerror) values(argnrodoc, argtipodoc,NULL, NULL, afil.nromutu, NULL,concat(afil.nombres , ' ',afil.apellido), afil.legajosiu, NULL, extract(month from CURRENT_DATE), extract(year from CURRENT_DATE), false,now(),'SIGES',null);
          end if;
else
          update afilidoc set mutu=false where nrodoc=argnrodoc and tipodoc=argtipodoc;
           insert into padronamuc_resultadotempo(nrodoc,tipodoc,resultado) values(argnrodoc,argtipodoc,'BAJA');
          select into novedades * from amucnovedades where nrodoc=argnrodoc and tipodoc=argtipodoc and not annovedadalta and anmesingreso=extract(month from CURRENT_DATE) and ananioingreso=extract(year from CURRENT_DATE);
          if NOT FOUND then
                   insert into amucnovedades(nrodoc, tipodoc, nrodoctitu, tipodoctitu, nromutu, annomapetitu, annomape, legajosiu, barramutu, anmesingreso, ananioingreso, annovedadalta, anprocesado,anusuario, anerror) values(argnrodoc, argtipodoc,NULL, NULL, afil.nromutu, NULL,concat(afil.nombres , ' ',afil.apellido), afil.legajosiu, NULL, extract(month from CURRENT_DATE), extract(year from CURRENT_DATE), false,now(),'SIGES',null);
          end if;
end if;
end;
$function$
