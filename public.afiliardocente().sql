CREATE OR REPLACE FUNCTION public.afiliardocente()
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
    SELECT INTO persona * FROM afilidoc WHERE nrodoc = afiliado.nrodoc AND tipodoc = afiliado.tipodoc;
    if NOT FOUND
       then
        INSERT INTO afilidoc (nrodoc,legajosiu,tipodoc) VALUES(afiliado.nrodoc,afiliado.legajosiu,afiliado.tipodoc);
       else
       	UPDATE afilidoc SET legajosiu = afiliado.legajosiu WHERE tipodoc = afiliado.tipodoc AND nrodoc = afiliado.nrodoc;
    end if;
    SELECT INTO resultado * FROM incorporarbarra(30,afiliado.nrodoc,afiliado.tipodoc);
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
