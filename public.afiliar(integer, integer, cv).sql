CREATE OR REPLACE FUNCTION public.afiliar(integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	rafiliado RECORD;
	discapacidades CURSOR FOR SELECT * FROM discapacidades;
	disc RECORD;
	direcc RECORD;
	personas RECORD;
	rafilsosunc RECORD;
	identdireccion integer;
	ultimo BIGINT;
	siguiente integer;
	resultado boolean;
	tipoafiliado alias for $1;
	estado alias for $2;
	codigo alias for $3;

BEGIN

SELECT INTO rafiliado * FROM afil;
if NOT FOUND
  then
      return 'false';
  else
   SELECT INTO direcc * FROM direccion WHERE iddireccion = rafiliado.iddireccion;
   if NOT FOUND
      then
        SELECT INTO ultimo MAX(iddireccion)+1 FROM direccion;
       	INSERT INTO direccion (iddireccion,barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad)
           VALUES (ultimo,rafiliado.barrio,rafiliado.calle,rafiliado.nrocalle,rafiliado.tira,rafiliado.piso,rafiliado.dpto,rafiliado.provincia,rafiliado.localidad);
       	   identdireccion = ultimo;
      else
        UPDATE direccion SET barrio = rafiliado.barrio, calle = rafiliado.calle, nro = rafiliado.nrocalle, tira = rafiliado.tira, piso = rafiliado.piso, dpto = rafiliado.dpto, idprovincia = rafiliado.provincia, idlocalidad = rafiliado.localidad WHERE iddireccion = rafiliado.iddireccion;
        identdireccion = rafiliado.iddireccion;
   end if;

    SELECT INTO personas * FROM persona WHERE tipodoc = rafiliado.tipodoc AND nrodoc = rafiliado.nrodoc;
    if NOT FOUND THEN
       INSERT INTO persona (nrodoc,apellido,nombres,fechanac,sexo,estcivil,telefono,email,fechainios,fechafinos
       ,iddireccion,tipodoc,carct)
       VALUES(rafiliado.nrodoc,rafiliado.apellido,rafiliado.nombres,rafiliado.fechanac, rafiliado.sexo,rafiliado.estcivil,rafiliado.telefono,rafiliado.mail,rafiliado.fechainios,rafiliado.fechafinos
       ,identdireccion,rafiliado.tipodoc,rafiliado.carct);
       INSERT INTO verificacion VALUES(codigo,rafiliado.nrodoc,3,rafiliado.barra,rafiliado.fechainios);
    ELSE
        UPDATE persona SET apellido = rafiliado.apellido,nombres = rafiliado.nombres,fechanac = rafiliado.fechanac,sexo = rafiliado.sexo, estcivil = rafiliado.estcivil,telefono = rafiliado.telefono,email = rafiliado.mail, fechainios = rafiliado.fechainios,fechafinos = rafiliado.fechafinos,iddireccion = identdireccion,carct = rafiliado.carct
               WHERE tipodoc = rafiliado.tipodoc AND nrodoc = rafiliado.nrodoc;
    end if;
end if;

    SELECT INTO resultado * FROM tratardiscapacidades();
    if NOT resultado
        then
	   return 'false';
    end if;

    SELECT INTO rafilsosunc * FROM afilsosunc WHERE nrodoc = rafiliado.nrodoc AND tipodoc = rafiliado.tipodoc;
    if NOT FOUND
     then
         INSERT INTO afilsosunc (nrodoc,nrocuilini,nrocuildni,nrocuilfin,nroosexterna,idosexterna,tipodoc,idestado)
         VALUES(rafiliado.nrodoc,rafiliado.inicuil,rafiliado.mediocuil,rafiliado.fincuil,rafiliado.nroosexterna,rafiliado.osexterna,rafiliado.tipodoc,estado);
	 else
	 	 UPDATE afilsosunc SET nrocuilini = rafiliado.inicuil, nrocuildni = rafiliado.mediocuil, nrocuilfin = rafiliado.fincuil, nroosexterna = rafiliado.nroosexterna, idosexterna = rafiliado.osexterna, idestado = estado WHERE nrodoc = rafiliado.nrodoc AND tipodoc = rafiliado.tipodoc;
    end if;

   if (tipoafiliado = 30)
	then
    	  SELECT INTO resultado * FROM afiliardocente();
    	  if NOT resultado
       		then
                 return 'false';
    	  end if;
	else
	 if(tipoafiliado = 31)
	   then
	     SELECT INTO resultado * FROM afiliarnodocente();
	     if NOT resultado
	        then
		  return 'false';
	     end if;
	   else
	     if (tipoafiliado = 32)
	        then
		   SELECT INTO resultado * FROM afiliarsosunc();
		   if NOT resultado
		      then
		         return 'false';
		   end if;
		else
		   if (tipoafiliado = 33)
		      then
		         SELECT INTO resultado * FROM afiliarrecursospropios();
			 if NOT resultado
			    then
			      return 'false';
			 end if;
		      else
		         if(tipoafiliado = 34)
			    then
			       SELECT INTO resultado * FROM afiliarbecario();
			       if NOT resultado
			          then
				     return 'false';
			       end if;
			    else
			       if(tipoafiliado = 35)
			          then
				     SELECT INTO resultado * FROM afiliarjubilado();
				     if NOT resultado
				        then
					  return 'false';
				     end if;
				  else
				     if (tipoafiliado =  36)
				        then
					   SELECT INTO resultado * FROM afiliarpensionado();
					   if NOT resultado
					      then
					         return 'false';
					   end if;
					else
					  if (tipoafiliado = 37)
					     then
					        SELECT INTO resultado * FROM afiliarautoridad();
						if NOT resultado
						    then
						       return 'false';
						end if;
				      else
				       return 'false';
					  end if;
				     end if;
			       end if;
			 end if;
		   end if;
	     end if;
	 end if;
    end if;

  SELECT INTO resultado * FROM tratarcargos();
  SELECT INTO resultado * FROM determinarregularidad(estado,rafiliado.tipodoc,rafiliado.nrodoc);
  return resultado;
END;
$function$
