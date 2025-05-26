CREATE OR REPLACE FUNCTION public.arreglaraporteidcertpers(nrodoctem character varying, idcertperstem bigint, idaportetem bigint, idcentrotem bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	aux RECORD;
	
rtemporal RECORD;

	id bigint;
	
	
BEGIN


id =(select max(idcertpers) from certpersonal)+1 ;


update afiljub set idcertpers=$2 where nrodoc=$1;

update  aporte set   idcertpers= id,idlaboral=id, idcargo=id where
idaporte=$3 and idcentroregionaluso=$4;

RETURN true;
END;$function$
