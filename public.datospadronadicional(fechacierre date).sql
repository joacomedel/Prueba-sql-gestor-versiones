CREATE OR REPLACE FUNCTION public.datospadronadicional(fechacierre date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
dependenciaanterior varchar;    
personas cursor for SELECT DISTINCT nrodoc, tipodoc, barra, apellido, fechainios, nombres, cargo.descrip as localidaddesc, dependencia FROM persona
        natural join afilsosunc
	NATURAL JOIN (SELECT tipodoc,nrodoc,idlocalidad, localidad.descrip as descrip,depuniversitaria.descrip as dependencia, idprovincia,cargo.fechafinlab FROM cargo
                         NATURAL JOIN depuniversitaria
                        NATURAL JOIN direccion join localidad using(idlocalidad) where fechafinlab > fechacierre - 90) AS cargo
	where
--excluimos a los afiliados con actas de defuncion cargadas
           (nrodoc, tipodoc) not in (select nrodoc, tipodoc from actasdefun)
 AND (barra >= 30 and barra<100)
 AND
 (nrodoc, tipodoc) in (
select nrodoc, tipodoc from persona natural join
(select nrodoc, tipodoc, verificarcargoininterrumpido2(nrodoc,tipodoc, '2008-08-15',365) as aa from persona natural join afilsosunc where barra >=30 and barra <100) as dd left outer join
(select nrodoc, tipodoc, verificarcargoininterrumpido(nrodoc,tipodoc, '2008-08-15',365) as aa from persona natural join afilsosunc where barra >=30 and barra <100) as ee using(nrodoc, tipodoc) where dd.aa and not ee.aa
                        );
    padron cursor for select * from tpadronelectoral order by localidad, dependencia, claustro, apellido, nombres;
    votante record;
    pers RECORD;
    vclaustro integer;
    claustroanterior integer;
    numerolinea integer;
    veranio boolean;
    yaesta boolean;
    aux boolean;
BEGIN
delete from tpadronelectoral;
open personas;
fetch personas into pers;
WHILE FOUND loop
	vclaustro=0;
	--select into veranio * from verificaranioininterrumpido(pers.nrodoc, pers.tipodoc);
	if(pers.barra=30 or pers.barra=31) then
		select into veranio * from verificarcargoininterrumpido2(pers.nrodoc, pers.tipodoc, fechacierre, 365);
                if veranio then
                         vclaustro=pers.barra;
                end if;
	end if;
		if(pers.barra=32) then
			 if pers.fechainios <= fechacierre - 365 then
                                 vclaustro=31;
                         end if;
		end if;
		if(pers.barra=35) then
			--aca hay que chequear que tengan un año de aportes
                        select into veranio * from verificarjubiladopadron(pers.nrodoc, pers.tipodoc, fechacierre);
                        if veranio then
                               select into vclaustro verificarcargoanterior(pers.nrodoc, pers.tipodoc);
                        end if;
		end if;
                if(pers.barra=37) then
			select into veranio * from verificarcargoininterrumpido2(pers.nrodoc, pers.tipodoc, fechacierre, 365);
                        if veranio then
                                 select into vclaustro verificarcargoanterior(pers.nrodoc, pers.tipodoc);
                        end if;
		end if;
		if(pers.barra=34) then
			select into veranio * from verificarcargoininterrumpido2(pers.nrodoc, pers.tipodoc, fechacierre, 365);
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

--hago las correcciones
select into aux * from rectificarpadron();

--numero el padron
open padron;
numerolinea = 1;
--localidadanterior=null;
fetch padron into votante;
while found loop
        UPDATE tpadronelectoral SET idlinea=numerolinea WHERE nrodoc=votante.nrodoc and barra=votante.barra;
        numerolinea = numerolinea + 1;
        claustroanterior = votante.claustro;
        dependenciaanterior = votante.dependencia;
        fetch padron into votante;
        if FOUND and (votante.claustro<>claustroanterior or votante.dependencia<>dependenciaanterior ) then
                       numerolinea = 1;
        end if;
end loop;
close padron;
RETURN 'true';
END;
$function$
