CREATE OR REPLACE FUNCTION public.tratardiscapacidades()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	afiliado RECORD;
	discapacidad CURSOR FOR SELECT * FROM discapacidades;
	disc RECORD;
	persona RECORD;
	resultado boolean;
	eltipodoc integer;
	elnrodoc varchar;
BEGIN

SELECT INTO afiliado * FROM afil;
if NOT FOUND
  then
      return 'false';
  else
    elnrodoc = afiliado.nrodoc ;
    eltipodoc = afiliado.tipodoc ;
    OPEN discapacidad;
    FETCH discapacidad into disc;
    WHILE  found LOOP
       
           SELECT INTO persona * FROM discpersona
             WHERE iddisc = disc.iddisc AND nrodoc = disc.nrodoc AND fechavtodisc = disc.vto AND tipodoc = disc.tipodoc ;
	       if NOT FOUND then
		      if disc.nuevo 	then
			          INSERT INTO discpersona VALUES(disc.nrodoc,disc.iddisc,disc.vto,disc.ente,disc.porcent,disc.tipodoc);
			       
              end if;
            else
		       if disc.nuevo then
			          UPDATE discpersona SET entemitecert = disc.ente, porcentdisc = disc.porcent
                      WHERE iddisc = disc.iddisc AND nrodoc = disc.nrodoc AND tipodoc = disc.tipodoc AND fechavtodisc = disc.vto;
                else
                      DELETE FROM discpersona WHERE nrodoc = disc.nrodoc AND tipodoc = disc.tipodoc AND iddisc = disc.iddisc AND fechavtodisc = disc.vto;
                      INSERT INTO discpersonaborradas VALUES(disc.nrodoc,disc.iddisc,disc.vto,disc.ente,disc.porcent,disc.tipodoc,disc.fecha);
	            end if;
            end if;
  
    fetch discapacidad into disc;
    END LOOP;
    --Igresar Persona Plan si corresponde
    SELECT INTO resultado * FROM ingresarpersonaplan(elnrodoc,eltipodoc,null,now()::date);
 
    close discapacidad;
return 'true';
end if;
END;
$function$
