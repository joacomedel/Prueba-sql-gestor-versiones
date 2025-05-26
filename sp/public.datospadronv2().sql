CREATE OR REPLACE FUNCTION public.datospadronv2()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
    personas cursor for SELECT DISTINCT nrodoc, tipodoc, barra, apellido, fechainios, nombres, cargo.descrip as localidaddesc, dependencia FROM persona
        natural join afilsosunc  
	NATURAL JOIN (SELECT tipodoc,nrodoc,idlocalidad, localidad.descrip as descrip,depuniversitaria.descrip as dependencia, idprovincia,cargo.fechafinlab FROM cargo
                         NATURAL JOIN depuniversitaria
                        NATURAL JOIN direccion join localidad using(idlocalidad) where fechafinlab > CURRENT_DATE - 90) AS cargo
	where           
--excluimos a los afiliados con actas de defuncion cargadas
           (nrodoc, tipodoc) not in (select nrodoc, tipodoc from actasdefun)
 AND (barra >= 30 and barra<100);
    padron cursor for select * from tpadronelectoral order by localidad, dependencia, claustro, apellido, nombres;
    votante record;
    pers RECORD;
    vclaustro integer;
    claustroanterior integer;
    numerolinea integer;
    veranio boolean;
    yaesta boolean;
BEGIN
delete from tpadronelectoral;
open personas;
fetch personas into pers;
WHILE FOUND loop
	vclaustro=0;
	--select into veranio * from verificaranioininterrumpido(pers.nrodoc, pers.tipodoc);
	if(pers.barra=30 or pers.barra=31) then 
		select into veranio * from verificaranioininterrumpido(pers.nrodoc, pers.tipodoc);
                if veranio then
                         vclaustro=pers.barra;
                end if;
	end if;
		if(pers.barra=32) then 
			 if pers.fechainios <= CURRENT_DATE - 365 then
                                 vclaustro=31;
                         end if;
		end if;
		if(pers.barra=35) then
			--aca hay que chequear que tengan un año de aportes
                        select into veranio * from verificaranioininterrumpidojub(pers.nrodoc, pers.tipodoc);
                        if veranio then
                               select into vclaustro verificarcargoanterior(pers.nrodoc, pers.tipodoc);
                        end if;
		end if;
                if(pers.barra=37) then
			select into veranio * from verificaranioininterrumpido(pers.nrodoc, pers.tipodoc);
                        if veranio then
                                 select into vclaustro verificarcargoanterior(pers.nrodoc, pers.tipodoc);
                        end if;
		end if;
		if(pers.barra=34) then 
			select into veranio * from verificaranioininterrumpido(pers.nrodoc, pers.tipodoc);
                        if veranio then
                              vclaustro=30;
                        end if;                       
		end if;
		if(vclaustro!=0) then
			select into yaesta exists(select * from tpadronelectoral where nrodoc=pers.nrodoc and barra=pers.barra);
			if not yaesta then
			insert into tpadronelectoral(nrodoc, barra, apellido, nombres, localidad, dependencia, claustro) values
				(pers.nrodoc, pers.barra, pers.apellido, pers.nombres, pers.localidaddesc, pers.dependencia, vclaustro);
                        
			end if;
		end if;
	--end;
	fetch personas into pers;
end loop;
close personas;

--numero el padron
open padron;
numerolinea = 1;
fetch padron into votante;
while found loop
        UPDATE tpadronelectoral SET idlinea=numerolinea WHERE nrodoc=votante.nrodoc and barra=votante.barra;
        numerolinea = numerolinea + 1;
        claustroanterior = votante.claustro;
        fetch padron into votante;
        if FOUND and votante.claustro<>claustroanterior then
                       numerolinea = 1;
        end if;
end loop;
close padron;
RETURN 'true';
END;
$function$
