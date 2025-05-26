CREATE OR REPLACE FUNCTION public.temp_agregartablaasincro()
 RETURNS void
 LANGUAGE plpgsql
AS $function$DECLARE
 auxiliar RECORD;
begin


select INTO auxiliar agregarsincronizable('plancobpersona');

CREATE OR REPLACE FUNCTION "public"."amplancobpersona" () RETURNS trigger AS
$body$
DECLARE
auxiliar RECORD;   
 BEGIN
    NEW:= insertarccplancobpersona(NEW);
    SELECT INTO auxiliar agregaaplancobpersona();
        return NEW;
    END;
$body$
LANGUAGE 'plpgsql' VOLATILE CALLED ON NULL INPUT SECURITY INVOKER;

end;
$function$
