CREATE OR REPLACE FUNCTION public.tratardiscapacidadesbenef()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$

DECLARE
	discapacidades CURSOR FOR SELECT * FROM discapacidades;
	disc RECORD;
	persona RECORD;


BEGIN


    OPEN discapacidades;
    FETCH discapacidades into disc;
    WHILE  found LOOP
    	SELECT INTO persona * FROM discpersona WHERE iddisc = disc.iddisc AND nrodoc = disc.nrodoc AND tipodoc = disc.tipodoc AND fechavtodisc = disc.vto;
	if NOT FOUND
		then
		 if disc.nuevo
			then
			  INSERT INTO discpersona VALUES(disc.nrodoc,disc.iddisc,disc.vto,disc.ente,disc.porcent,disc.tipodoc);
			 end if;
		else
		 if disc.nuevo
		 	then
			 	UPDATE discpersona SET  entemitecert = disc.ente, porcentdisc = disc.porcent WHERE fechavtodisc = disc.vto AND  iddisc = disc.iddisc AND nrodoc = disc.nrodoc AND tipodoc = disc.tipodoc;
			else
				 DELETE FROM discpersona WHERE fechavtodisc = disc.vto AND nrodoc = disc.nrodoc AND tipodoc = disc.tipodoc AND iddisc = disc.iddisc;
			 	INSERT INTO discpersonaborradas VALUES(disc.nrodoc,disc.iddisc,disc.vto,disc.ente,disc.porcent,disc.tipodoc,disc.fecha);
		 	end if;
     end if;
      fetch discapacidades into disc;
    END LOOP;
    close discapacidades;
RETURN  'true';
END;
$function$
