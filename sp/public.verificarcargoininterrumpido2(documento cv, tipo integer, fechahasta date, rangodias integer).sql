CREATE OR REPLACE FUNCTION public.verificarcargoininterrumpido2(documento character varying, tipo integer, fechahasta date, rangodias integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
        ccargo cursor for select fechainilab, fechafinlab + 90 as ffechafinlab from cargo where nrodoc=documento and tipodoc=tipo and (fechahasta-rangodias <= fechainilab or (fechahasta-rangodias <= fechafinlab and fechahasta-rangodias >= fechainilab)) order by fechainilab;
        rcargo record;
        tcargo record;
        resultado boolean;
begin
    resultado = false;
	open ccargo;
        fetch ccargo into rcargo;
        if FOUND and rcargo.fechainilab <= fechahasta-rangodias then
        if rcargo.ffechafinlab >= fechahasta THEN
               close ccargo;
               return true;
        end if;
        tcargo = rcargo;
		fetch ccargo into rcargo;
		while FOUND and (tcargo.ffechafinlab + 1 >= rcargo.fechainilab) loop
			if rcargo.ffechafinlab >= fechahasta THEN
               close ccargo;
               return true;
             end if;
            tcargo = rcargo;
			fetch ccargo into rcargo;
		end loop;
		if FOUND then
			resultado = false;
		else
			resultado = (tcargo.ffechafinlab >= fechahasta);
		end if;
	end if;
	close ccargo;
	return resultado;
end;
$function$
