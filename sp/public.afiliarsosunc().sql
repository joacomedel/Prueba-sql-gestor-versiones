CREATE OR REPLACE FUNCTION public.afiliarsosunc()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	afiliado RECORD;
	persona RECORD;
	resultado boolean;
	existetbarras integer;
BEGIN

SELECT INTO afiliado * FROM afil;
if NOT FOUND
  then
      return 'false';
  else
    SELECT INTO persona * FROM afilisos WHERE nrodoc = afiliado.nrodoc AND tipodoc = afiliado.tipodoc;
    if NOT FOUND
       then
        INSERT INTO afilisos (nrodoc,legajosiu,tipodoc) VALUES(afiliado.nrodoc,afiliado.legajosiu,afiliado.tipodoc);
       else
       	UPDATE afilisos SET legajosiu = afiliado.legajosiu WHERE tipodoc = afiliado.tipodoc AND nrodoc = afiliado.nrodoc;
    end if;
  SELECT INTO resultado * FROM incorporarbarra(32,afiliado.nrodoc,afiliado.tipodoc);
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
