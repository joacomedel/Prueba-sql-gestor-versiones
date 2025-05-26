CREATE OR REPLACE FUNCTION public.buscardiscapacidades(integer, character varying, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	pers RECORD;
	resultado boolean;
	usuario alias for $4;
	discap CURSOR FOR SELECT * FROM discpersona WHERE nrodoc = $2 AND tipodoc= $1;
	dis RECORD;
	tipodisc varchar;
BEGIN
select into pers persona.nombres, persona.apellido, tiposdoc.descrip as tipodoc from persona, tiposdoc where persona.tipodoc = $1 and persona.nrodoc =$2 and persona.barra= $3 and persona.tipodoc = tiposdoc.tipodoc;
if FOUND
  then--existe el titular con lo que podria tener discapacidades declaradas
	OPEN discap;
	FETCH discap INTO dis;
	resultado ='false';	 
	WHILE  found LOOP
	      SELECT INTO tipodisc discapacidad.descrip from discapacidad WHERE iddisc = dis.iddisc;
	      DELETE FROM rdiscapacidad WHERE idusuario = usuario;
              INSERT INTO rdiscapacidad VALUES ($2,tipodisc,dis.fechavtodisc,dis.entemitecert,dis.porcentdisc,pers.tipodoc,usuario);
	      fetch discap into dis;
	      resultado ='true';	 
	END LOOP;
	CLOSE discap;
  else --no hay una persona con los datos especificados como parÃ¡metros
  	resultado = 'false';
end if;

return resultado;
END;
$function$
