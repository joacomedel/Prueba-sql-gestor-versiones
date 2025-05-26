CREATE OR REPLACE FUNCTION public.verificaranioaportesjub(documento character varying, tipo smallint, fechahasta date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
        ccargo cursor for select fechainiaport, fechafinaport as ffechafinlab from aportejubpen where nrodoc=documento and tipodoc=tipo and (fechahasta-365 <= fechainiaport or (fechahasta-365 <= fechafinaport and fechahasta-365 >= fechainiaport)) order by fechainiaport;
        rcargo record;
        tcargo record;
        resultado boolean;
begin
        resultado = false;
        open ccargo;
        fetch ccargo into rcargo;
        if FOUND and rcargo.fechainiaport <= fechahasta - 365 then
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
