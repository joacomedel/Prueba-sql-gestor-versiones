CREATE OR REPLACE FUNCTION public.verificaranioininterrumpidojub(documento character varying, tipo smallint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare

        ccargo cursor for select fechainiaport, fechafinaport as ffechafinlab from aportejubpen where nrodoc=documento and tipodoc=tipo and (CURRENT_DATE-365 <= fechainiaport or (CURRENT_DATE-365 <= fechafinaport and CURRENT_DATE-365 >= fechainiaport)) order by fechainiaport;

        rcargo record;

        tcargo record;

        resultado boolean;

begin

        resultado = false;

        open ccargo;

        fetch ccargo into rcargo;

        if FOUND and rcargo.fechainiaport <= CURRENT_DATE - 365 then

                tcargo = rcargo;

                fetch ccargo into rcargo;

                while FOUND and (tcargo.ffechafinlab >= rcargo.fechainiaport) loop

                        tcargo = rcargo;

                        fetch ccargo into rcargo;

                end loop;
                if FOUND then

                        resultado = false;

                else

                        resultado = (tcargo.ffechafinlab >= CURRENT_DATE);

                end if;

        end if;
        close ccargo;
        return resultado;

end;

$function$
