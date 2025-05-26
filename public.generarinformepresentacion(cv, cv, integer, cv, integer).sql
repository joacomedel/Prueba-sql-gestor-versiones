CREATE OR REPLACE FUNCTION public.generarinformepresentacion(character varying, character varying, integer, character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
    resultado BOOLEAN;
    fechahasta alias for $1;
    fechadesde alias for $2;
    idcentro alias for $3;
    porigen alias for $4;
    pvalor alias for $5;
    
BEGIN
if pvalor = 61 then
    select into resultado * from generarinformeamuc(fechahasta,fechadesde,idcentro,porigen);
else
    select into resultado * from generarinformepresentacionotras(fechahasta,fechadesde,idcentro,porigen,pvalor);
end if;

return resultado;
END;
$function$
