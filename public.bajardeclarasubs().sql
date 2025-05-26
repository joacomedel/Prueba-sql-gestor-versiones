CREATE OR REPLACE FUNCTION public.bajardeclarasubs()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursordecl CURSOR FOR SELECT * FROM tempdeclarasubs;
	decl RECORD;
BEGIN

    OPEN cursordecl;
    FETCH cursordecl into decl;
    WHILE  found LOOP

        INSERT INTO declarasubs VALUES(decl.nrodoctitu,decl.nro,decl.apellido,decl.nrodoc,decl.vinculo,decl.tipodoctitu,decl.tipodoc,decl.nombres,decl.porcent);

    fetch cursordecl into decl;
    END LOOP;
    close cursordecl;

return 'true';
END;
$function$
