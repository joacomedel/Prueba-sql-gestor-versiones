CREATE OR REPLACE FUNCTION public.verificarcargospadron(documento character varying, tipo integer, fechacierre date, rangodias integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
         ccargo cursor for select fechainilab, fechafinlab + 90 as ffechafinlab from cargo where nrodoc=documento and tipodoc=tipo and (fechacierre-rangodias <= fechainilab or (fechacierre-rangodias <= fechafinlab and fechacierre-rangodias >= fechainilab)) order by fechainilab;
        rcargo record;
        tcargo record;
        resultado boolean;
begin
        resultado = false;
	open ccargo;
        fetch ccargo into rcargo;
        if FOUND and rcargo.fechainilab <= fechacierre - rangodias then
		tcargo = rcargo;
		fetch ccargo into rcargo;
		while FOUND and (tcargo.ffechafinlab >= rcargo.fechainilab) loop
			tcargo = rcargo;
			fetch ccargo into rcargo;
		end loop;
		if FOUND then
			resultado = false;
		else
			resultado = (tcargo.ffechafinlab >= fechacierre);
		end if;
	end if;
	close ccargo;
	return resultado;
end;
$function$
