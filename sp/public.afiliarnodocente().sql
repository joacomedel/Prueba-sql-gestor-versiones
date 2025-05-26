CREATE OR REPLACE FUNCTION public.afiliarnodocente()
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
if FOUND
  then
    SELECT INTO persona * FROM afilinodoc WHERE nrodoc = afiliado.nrodoc AND tipodoc = afiliado.tipodoc;
    if NOT FOUND
       then
        INSERT INTO afilinodoc (nrodoc,legajosiu,tipodoc) VALUES(afiliado.nrodoc,afiliado.legajosiu,afiliado.tipodoc);
       else
       	UPDATE afilinodoc SET legajosiu = afiliado.legajosiu WHERE tipodoc = afiliado.tipodoc AND nrodoc = afiliado.nrodoc;
    end if;
    SELECT INTO resultado * FROM incorporarbarra(31,afiliado.nrodoc,afiliado.tipodoc);
    SELECT INTO existetbarras * FROM tbarras WHERE nrodoctitu = afiliado.nrodoc AND tipodoctitu = afiliado.tipodoc;
    if NOT FOUND
        then
		  INSERT INTO tbarras VALUES (afiliado.nrodoc,afiliado.tipodoc,2);
    end if;
    resultado = 'true';
  else
     resultado = 'false';
end if;
return resultado;
END;
$function$
