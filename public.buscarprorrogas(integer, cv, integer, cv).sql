CREATE OR REPLACE FUNCTION public.buscarprorrogas(integer, character varying, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	pers RECORD;
	resultado boolean;
	usuario alias for $4;
	prorroga CURSOR FOR SELECT * FROM prorroga WHERE nrodoc = $2 AND tipodoc= $1;
	pro RECORD;
	tipodisc varchar;
BEGIN
resultado=false;
select into pers benefsosunc.nrodoc, tiposdoc.descrip as tipodoc from benefsosunc,tiposdoc where benefsosunc.tipodoc = $1 and benefsosunc.nrodoc =$2 and benefsosunc.tipodoc=tiposdoc.tipodoc;
if FOUND
  then--existe el beneficiario con lo que podria prorrogas
	OPEN prorroga;
	FETCH prorroga INTO pro;
	WHILE  found LOOP
	  resultado='true';    
          DELETE FROM rprorroga WHERE idusuario = usuario;
          INSERT INTO rprorroga VALUES ($2,pro.tipoprorr,pro.fechaemision,pro.fechavto,pro.certestudio,pro.declarajurada,pers.tipodoc,usuario);
	      fetch prorroga into pro;
	END LOOP;
	CLOSE prorroga;	 
  else --no hay una persona con los datos especificados como parÃ¡metros
  	resultado = 'false';
end if;

return resultado;
END;
$function$
