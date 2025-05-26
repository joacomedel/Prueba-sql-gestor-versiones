CREATE OR REPLACE FUNCTION public.cambioreintegro(integer, integer, integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
dato record;
datopersona record;
datoaux record;
datoreintegro record;
datocuentas record;

begin

select into datoreintegro * from reintegro
where nroreintegro=$1 and idcentroregional=$2 and anio=$3;



select into dato * from persona
left join tafiliado 
on persona.nrodoc=tafiliado.nrodoc
where persona.nrodoc=datoreintegro.nrodoc and  persona.nrodoc=tafiliado.nrodoc
 and persona.tipodoc<>tafiliado.tipodoc;
if  found then 
update  tafiliado set tipodoc=dato.tipodoc where tafiliado.nrodoc= dato.nrodoc;
end if;




select into datocuentas * from persona
left join cuentas 
on persona.nrodoc=cuentas.nrodoc
where persona.nrodoc=datoreintegro.nrodoc and  persona.nrodoc=cuentas.nrodoc
 and  persona.tipodoc<>cuentas.tipodoc;
if  found then 
update  cuentas set tipodoc=datocuentas.tipodoc where cuentas.nrodoc= datocuentas.nrodoc;
end if;

select into datoaux * from persona
left join reintegro 
on persona.nrodoc=reintegro.nrodoc
where persona.nrodoc=datoreintegro.nrodoc and  persona.nrodoc=reintegro.nrodoc
 and  persona.tipodoc<>reintegro.tipodoc;
if  found then 
update  reintegro set tipodoc=datoaux.tipodoc where reintegro.nrodoc= datoaux.nrodoc;
end if;


end;
$function$
