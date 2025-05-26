CREATE OR REPLACE FUNCTION public.modificarcargoafilsosunc()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        rcargo record;
        cordenventaitem  refcursor;
        rordenventaitem record;

        resp boolean;
      

BEGIN

SELECT INTO rcargo *  FROM tcargo;

IF FOUND THEN 
		IF(not nullvalue(rcargo.idcargo) AND rcargo.fechafinlab<> 'null'  AND legajosiu<> 'null') THEN
			UPDATE cargo SET fechafinlab = rcargo.fechafinlab
			WHERE idcargo = rcargo.idcargo;
                END IF;

 END IF;

return 'true';
END;$function$
