CREATE OR REPLACE FUNCTION public.insertardeclarasub()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
    rsubsidios RECORD;
	cpersona CURSOR FOR SELECT * FROM subsidiosv2;
	rpers RECORD;
	tnrodoctitu varchar;
	ttipodoctitu smallint;
BEGIN

SELECT INTO rpers * FROM subsidiosv2 LIMIT 1;
tnrodoctitu = rpers.nrodoctitu;
ttipodoctitu = rpers.tipodoctitu;

DELETE FROM declarasubs WHERE declarasubs.nrodoctitu = tnrodoctitu
                                  AND declarasubs.tipodoctitu = ttipodoctitu
                                  AND (declarasubs.nrodoc,declarasubs.tipodoc) Not In (Select subsidiosv2.nrodoc
                                                                                              ,subsidiosv2.tipodoc
                                                                                            FROM subsidiosv2);

    OPEN cpersona;
    FETCH cpersona into rpers;
    WHILE  found LOOP
   
    SELECT INTO rsubsidios * FROM declarasubs WHERE declarasubs.tipodoctitu = rpers.tipodoctitu
                                                    AND declarasubs.nrodoctitu = rpers.nrodoctitu
                                                    AND declarasubs.tipodoc = rpers.tipodoc
                                                    AND declarasubs.nrodoc = rpers.nrodoc;
	if NOT FOUND then
		  INSERT INTO declarasubs (nrodoctitu,nro,apellido,nrodoc,vinculo,tipodoctitu,tipodoc,nombres,porcent)
          VALUES(rpers.nrodoctitu,rpers.nro,rpers.apellido,rpers.nrodoc,rpers.vinculo,rpers.tipodoctitu,rpers.tipodoc,rpers.nombres,rpers.porcent);
	else
    	 	UPDATE declarasubs SET  apellido = rpers.apellido,
                                    nombres = rpers.nombres,
                                    vinculo = rpers.vinculo,
                                    porcent = rpers.porcent,
                                    nro = rpers.nro
                   WHERE nrodoctitu = rpers.nrodoctitu
                         AND tipodoctitu = rpers.tipodoctitu
                         AND nrodoc = rpers.nrodoc
                         AND tipodoc = rpers.tipodoc;
                  
    end if;
    fetch cpersona into rpers;
    END LOOP;
close cpersona;


return 'true';

END;
$function$
