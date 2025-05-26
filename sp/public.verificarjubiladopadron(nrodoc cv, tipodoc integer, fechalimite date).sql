CREATE OR REPLACE FUNCTION public.verificarjubiladopadron(nrodoc character varying, tipodoc integer, fechalimite date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Verifica si el afiliado jubilado esta en condiciones de emitir el voto
siendo que el cierre de padrones fue fechalimite */

declare
anioaportes boolean;
tienecargos boolean;
tieneaportes boolean;
fechajub date;
fechaini date;

begin
select into anioaportes * from verificaraportesjub(nrodoc, CAST(tipodoc as smallint), fechalimite, 365);
if anioaportes then
    return 'true';
else
    select into fechaini max(fechainilab) from cargo where cargo.nrodoc=nrodoc and    cargo.tipodoc=tipodoc and fechainilab <= fechalimite - 365;
    if NOT FOUND then
        return 'false';
    else
        select into fechajub max(fechafinlab) from cargo where cargo.nrodoc=nrodoc and cargo.tipodoc=tipodoc;
        select into tienecargos * from verificarcargospadron(nrodoc, CAST(tipodoc as smallint), fechajub, fechajub - fechaini);
        if tienecargos then
            select into tieneaportes * from verificaraportesjub(nrodoc, CAST(tipodoc as smallint), fechalimite, fechalimite - fechajub);
            if tieneaportes then
                return 'true';
            else
                return 'false';
            end if;
        else
            return 'false';
        end if;
    end if;
end if;
end;
$function$
