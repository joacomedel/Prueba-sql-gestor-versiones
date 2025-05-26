CREATE OR REPLACE FUNCTION public.expendio_tiene_mutual(character varying, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE

        pnrodoc alias for $1;
        ptipodoc alias for $2;
        quemutual integer;
        rpersona RECORD;
        
BEGIN
              quemutual = 0;
               SELECT  INTO rpersona * FROM mutualpadron WHERE nrodoc=pnrodoc and tipodoc = ptipodoc;
               IF FOUND THEN
                  quemutual = rpersona.idobrasocial;
               END IF;
return quemutual;
END;
$function$
