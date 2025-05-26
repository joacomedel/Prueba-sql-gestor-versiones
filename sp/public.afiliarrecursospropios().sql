CREATE OR REPLACE FUNCTION public.afiliarrecursospropios()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	afiliado RECORD;
	persona RECORD;
	resultado boolean;
	existetbarras RECORD;
BEGIN

SELECT INTO afiliado * FROM afil;
if NOT FOUND
  then
      return 'false';
  else
    SELECT INTO persona * FROM afilirecurprop WHERE nrodoc = afiliado.nrodoc AND tipodoc = afiliado.tipodoc;
    if NOT FOUND
       then
        INSERT INTO afilirecurprop (nrodoc,legajosiu,tipodoc) VALUES(afiliado.nrodoc,afiliado.legajosiu,afiliado.tipodoc);
       else
       	UPDATE afilirecurprop SET legajosiu = afiliado.legajosiu WHERE tipodoc = afiliado.tipodoc AND nrodoc = afiliado.nrodoc;
    end if;
    SELECT INTO resultado * FROM incorporarbarra(33,afiliado.nrodoc,afiliado.tipodoc);
     SELECT INTO existetbarras * FROM tbarras WHERE nrodoctitu = afiliado.nrodoc AND tipodoctitu = afiliado.tipodoc;
    if NOT FOUND
        then
		  INSERT INTO tbarras VALUES (afiliado.nrodoc,afiliado.tipodoc,2);
		  resultado = 'true';
    end if;
    return resultado;
end if;
END;
$function$
