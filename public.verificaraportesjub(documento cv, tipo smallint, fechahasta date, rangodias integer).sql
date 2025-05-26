CREATE OR REPLACE FUNCTION public.verificaraportesjub(documento character varying, tipo smallint, fechahasta date, rangodias integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
        ccargo cursor for select fechainiaport, fechafinaport as ffechafinlab from aportejubpen where nrodoc=documento and tipodoc=tipo and (fechahasta-rangodias <= fechainiaport or (fechahasta-rangodias <= fechafinaport and fechahasta-rangodias >= fechainiaport)) order by fechainiaport;
        rcargo record;
        tcargo record;
        resultado boolean;
begin
        resultado = false;
        open ccargo;
        fetch ccargo into rcargo;
        if FOUND and rcargo.fechainiaport <= fechahasta - rangodias then
                tcargo = rcargo;
                fetch ccargo into rcargo;
                while FOUND and (tcargo.ffechafinlab >= rcargo.fechainiaport) loop
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
