CREATE OR REPLACE FUNCTION public.expendio_tiene_ctacte_sosunc(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

  resp boolean;
  rdatos RECORD;
  
BEGIN

resp = false;

SELECT INTO rdatos * FROM afilsosunc WHERE ctacteexpendio AND (nrodoc,tipodoc) IN 
(
SELECT nrodoc,tipodoc FROM afilsosunc WHERE nrodoc=$1 and tipodoc=$2
UNION 
SELECT nrodoctitu,tipodoctitu FROM benefsosunc WHERE nrodoc=$1 and tipodoc=$2
);

IF FOUND THEN 
	resp = true;
END IF;

return resp;

END;
$function$
