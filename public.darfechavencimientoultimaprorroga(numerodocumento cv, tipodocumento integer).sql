CREATE OR REPLACE FUNCTION public.darfechavencimientoultimaprorroga(numerodocumento character varying, tipodocumento integer)
 RETURNS date
 LANGUAGE plpgsql
AS $function$
declare
fecha date;
begin

                SELECT INTO fecha fechavto FROM (SELECT MAX(prorroga.idprorr) as idprorr FROM prorroga
                                              WHERE nrodoc = numerodocumento AND prorroga.tipodoc = tipodocumento) as ultimaprorroga
                                              NATURAL JOIN prorroga
                                              WHERE prorroga.tipoprorr = 18 OR prorroga.tipoprorr = 21;
return fecha;
end;$function$
