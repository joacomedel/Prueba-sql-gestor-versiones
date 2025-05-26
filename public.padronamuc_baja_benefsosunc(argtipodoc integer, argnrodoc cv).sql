CREATE OR REPLACE FUNCTION public.padronamuc_baja_benefsosunc(argtipodoc integer, argnrodoc character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
afil record;
novedades record;
begin
select into afil *, persona2.apellido as apellidotitu, persona2.nombres as nombrestitu from benefsosunc natural join persona join persona as persona2 on (benefsosunc.nrodoctitu=persona2.nrodoc and benefsosunc.tipodoctitu = persona2.tipodoc) where persona.nrodoc=argnrodoc and persona.tipodoc=argtipodoc;
if not afil.mutual then          

select into novedades * from amucnovedades where nrodoc=argnrodoc and tipodoc=argtipodoc and not annovedadalta;
          if not FOUND then
insert into amucnovedades(nrodoc, tipodoc, nrodoctitu, tipodoctitu, nromutu, annomapetitu, annomape, legajosiu, barramutu, anmesingreso, ananioingreso, annovedadalta, anprocesado,anusuario, anerror) values(argnrodoc, argtipodoc,afil.nrodoctitu, afil.tipodoctitu, afil.nromututitu,concat(afil.nombrestitu , ' ',afil.apellidotitu), concat(afil.nombres , ' ',afil.apellido), NULL, afil.barramutu, extract(month from CURRENT_DATE), extract(year from CURRENT_DATE), false,now(),'SIGES',null); end if;
else
          update benefsosunc set mutual=false where nrodoc=argnrodoc and tipodoc=argtipodoc;
           insert into padronamuc_resultadotempo(nrodoc,tipodoc,resultado,nrodoctitu,tipodoctitu) values(argnrodoc,argtipodoc,'BAJA',afil.nrodoctitu,afil.tipodoctitu);
          select into novedades * from amucnovedades where nrodoc=argnrodoc and tipodoc=argtipodoc and not annovedadalta and anmesingreso=extract(month from CURRENT_DATE) and ananioingreso=extract(year from CURRENT_DATE);
          if NOT FOUND then
                   insert into amucnovedades(nrodoc, tipodoc, nrodoctitu, tipodoctitu, nromutu, annomapetitu, annomape, legajosiu, barramutu, anmesingreso, ananioingreso, annovedadalta, anprocesado,anusuario, anerror) values(argnrodoc, argtipodoc,afil.nrodoctitu, afil.tipodoctitu, afil.nromututitu,concat(afil.nombrestitu , ' ',afil.apellidotitu), concat(afil.nombres , ' ',afil.apellido), NULL, afil.barramutu, extract(month from CURRENT_DATE), extract(year from CURRENT_DATE), false,now(),'SIGES',null);
          end if;
end if;
end;
$function$
