CREATE OR REPLACE FUNCTION public.cambiotipodoc()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
dato record;
datopersona record;
datoaux record;
datoaux2 record;

 datoref refcursor;
datopersonaref refcursor;
datoauxref refcursor;
datoaux2ref refcursor;


begin
open datopersonaref for select  * from persona
left join tafiliado 
on persona.nrodoc=tafiliado.nrodoc
where persona.nrodoc=tafiliado.nrodoc
and persona.tipodoc=1 and persona.tipodoc<>tafiliado.tipodoc;
FETCH datopersonaref INTO datopersona;
WHILE  found LOOP
update  tafiliado set tipodoc=datopersona.tipodoc where tafiliado.nrodoc= datopersona.nrodoc
and datopersona.nrodoc<>'04437228' and datopersona.nrodoc<>'05503225'
and datopersona.nrodoc<>'01441298' and datopersona.nrodoc<>'02318278'
and datopersona.nrodoc<>'04498591'
and datopersona.nrodoc<>'04532322';


FETCH datopersonaref INTO datopersona;
END LOOP;

open datoauxref for  select * from persona
left join cuentas 
on persona.nrodoc=cuentas.nrodoc
where persona.nrodoc=cuentas.nrodoc
and persona.tipodoc=1 and persona.tipodoc<>cuentas.tipodoc;
FETCH datoauxref INTO datoaux;
WHILE  found LOOP

update  cuentas set tipodoc=datoaux.tipodoc where cuentas.nrodoc= datoaux.nrodoc
and datoaux.nrodoc<>'04437228' and datoaux.nrodoc<>'05503225'
and datoaux.nrodoc<>'01441298' and datoaux.nrodoc<>'02318278'
and datoaux.nrodoc<>'04498591'
and datoaux.nrodoc<>'04532322';


FETCH datoauxref INTO datoaux;
end loop;


open datoaux2ref for   select  * from persona
left join reintegro 
on persona.nrodoc=reintegro.nrodoc
where persona.nrodoc=reintegro.nrodoc
and persona.tipodoc=1 and persona.tipodoc<>reintegro.tipodoc;

FETCH datoaux2ref INTO datoaux2;
WHILE  found LOOP
update  reintegro set tipodoc=datoaux2.tipodoc where reintegro.nrodoc= datoaux2.nrodoc
 and datoaux2.nrodoc<>'04437228' and datoaux2.nrodoc<>'05503225'
 and datoaux2.nrodoc<>'01441298'  and datoaux2.nrodoc<>'02318278'
 and datoaux2.nrodoc<>'04498591'
and datoaux2.nrodoc<>'04532322';

FETCH datoaux2ref INTO datoaux2;

end loop;


end;
$function$
