CREATE OR REPLACE FUNCTION public.verificarcargoanterior(documento character varying, tipo integer)
 RETURNS smallint
 LANGUAGE plpgsql
AS $function$declare
cur1 cursor for select * from cargo where nrodoc=documento and tipodoc=tipo order by fechafinlab, fechainilab;
cur2 cursor for select * from cargo where nrodoc=documento and tipodoc=tipo order by fechafinlab, fechainilab;
reg record;
reg2 record;
resultado smallint;
barraper integer;
car text;
begin
	open cur1;
	open cur2;
	fetch cur1 into reg;
        fetch cur2 into reg2;
        select into barraper barra from persona where nrodoc=documento and tipodoc=tipo;
        if barraper = 35 then 
               select into car idcateg from cargo where nrodoc = documento and tipodoc=tipo and fechafinlab in (select max(fechafinlab) from cargo where nrodoc=documento and tipodoc = tipo);
               select into resultado seaplica from categoria natural join cargo where idcateg=car;
        else
	fetch cur2 into reg2;
	while FOUND loop
		fetch cur2 into reg2;
		if FOUND then
			fetch cur1 into reg;
		end if;
	end loop;
	select into resultado seaplica from categoria where idcateg = reg.idcateg;
end if;
	close cur2;
	close cur1;
	return resultado;
end;
$function$
