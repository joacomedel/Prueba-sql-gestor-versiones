CREATE OR REPLACE FUNCTION public.asentarordeninternacion()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE

datos CURSOR FOR
              SELECT *
              FROM tempinternacion;
/*
idprestador        integer
idplancobertura    varchar
malcance           varchar
nromatricular      integer
mespecialidad      varchar
*/

begin
end;
$function$
