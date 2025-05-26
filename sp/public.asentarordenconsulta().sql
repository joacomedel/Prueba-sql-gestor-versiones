CREATE OR REPLACE FUNCTION public.asentarordenconsulta()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE

datos CURSOR FOR
              SELECT *
              FROM tempconsulta;
/*
idplancobertura     varchar
centro              integer
*/
dato record;
norden bigint;

begin
norden=0;
select * into norden
       from asentarorden();
open datos;
fetch datos into dato;
INSERT INTO ordconsulta(centro,nroorden,idplancovertura)
	  VALUES (dato.centro,norden,dato.idplancobertura);
close datos;
return norden;
end;
$function$
