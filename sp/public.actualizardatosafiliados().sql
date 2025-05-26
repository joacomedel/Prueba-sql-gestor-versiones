CREATE OR REPLACE FUNCTION public.actualizardatosafiliados()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* actualiza en la base SOSSIGES los datos ingresados x siges web
* actualiza los datos en la tabla persona y la tabla direccion y borra el registro en la base web
*/
DECLARE
--cursores
      cursortempaf CURSOR FOR SELECT * FROM tempafiliado;
      
--registros
      regafil RECORD;
      datoPersona RECORD;
      datoDir RECORD;
      escliente RECORD;
begin

/* Busco los datos de la persona*/
open cursortempaf;
FETCH cursortempaf INTO regafil;
   SELECT INTO datoPersona *
   FROM public.persona WHERE persona.nrodoc=regafil.nrodoc and persona.tipodoc=regafil.tipodoc;
   IF FOUND THEN
          UPDATE direccion
		  SET
		
			barrio = regafil.barrio,
			calle = regafil.calle,
			nro = regafil.nro,
			tira = regafil.tira,
			piso = regafil.piso,
			dpto = regafil.dpto,
			idprovincia = regafil.idprovincia,
			idlocalidad = regafil.idlocalidad
	    	WHERE iddireccion = datoPersona.iddireccion and idcentrodireccion = datoPersona.idcentrodireccion;

         UPDATE persona
		 SET
			apellido = regafil.apellido,
			nombres = regafil.nombres,
			fechanac = regafil.fechanac,
			sexo = regafil.sexo,
			estcivil = regafil.estcivil,
			telefono = regafil.telefono,
			email = regafil.email,
			carct = regafil.carct	
		WHERE nrodoc = regafil.nrodoc AND tipodoc = regafil.tipodoc;
			
        SELECT INTO escliente * FROM cliente  WHERE nrocliente = regafil.nrodoc;
        IF FOUND THEN
        	UPDATE cliente
            SET
			telefono = regafil.telefono,
			email = regafil.email
      		WHERE nrocliente = regafil.nrodoc;
 		END IF;

         if (regafil.barra = 30) then
    	    UPDATE afilidoc set mutu = regafil.mutu, nromutu= regafil.nromutu, legajosiu=regafil.legajosiu
    	    WHERE afilidoc.nrodoc= regafil.nrodoc AND afilidoc.tipodoc= regafil.tipodoc;
         else
	         if(regafil.barra  = 31) then
          	     UPDATE afilinodoc set mutu = regafil.mutu, nromutu= regafil.nromutu, legajosiu=regafil.legajosiu
    	         WHERE afilinodoc.nrodoc= regafil.nrodoc AND afilinodoc.tipodoc= regafil.tipodoc;
             else
                if (regafil.barra  = 32) then
	                 UPDATE afilisos set mutu = regafil.mutu, nromutu= regafil.nromutu, legajosiu=regafil.legajosiu
                     WHERE afilisos.nrodoc= regafil.nrodoc AND afilisos.tipodoc= regafil.tipodoc;
           		else
		            if (regafil.barra = 33) then  
		               UPDATE afilirecurprop set mutu = regafil.mutu, nromutu= regafil.nromutu, legajosiu=regafil.legajosiu
                       WHERE afilirecurprop.nrodoc= regafil.nrodoc AND afilirecurprop.tipodoc= regafil.tipodoc;
		            else
					  if (regafil.barra  = 37) then
					       UPDATE afiliauto set mutu = regafil.mutu, nromutu= regafil.nromutu, legajosiu=regafil.legajosiu
                           WHERE afiliauto.nrodoc= regafil.nrodoc AND afiliauto.tipodoc= regafil.tipodoc;
                      else
                          if (regafil.barra < 30) then --es benefsosunc
                              UPDATE benefsosunc set mutual = regafil.mutu, nromututitu= regafil.nromutu
                               WHERE benefsosunc.nrodoc= regafil.nrodoc AND benefsosunc.tipodoc= regafil.tipodoc;
                          end if;
					  end if;
		            end if;
                end if;
			end if;
		end if;
	    

    END IF;
CLOSE cursortempaf;
return true;
end;
$function$
