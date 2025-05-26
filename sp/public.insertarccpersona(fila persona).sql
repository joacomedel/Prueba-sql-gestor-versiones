CREATE OR REPLACE FUNCTION public.insertarccpersona(fila persona)
 RETURNS persona
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.personacc:= current_timestamp;
    UPDATE sincro.persona SET apellido= fila.apellido, barra= fila.barra, carct= fila.carct, contcarencia= fila.contcarencia, email= fila.email, estcivil= fila.estcivil, fechafinos= fila.fechafinos, fechainios= fila.fechainios, fechanac= fila.fechanac, idcentrodireccion= fila.idcentrodireccion, iddireccion= fila.iddireccion, nombres= fila.nombres, nrodoc= fila.nrodoc, nrodocreal= fila.nrodocreal, personacc= fila.personacc, sexo= fila.sexo, telefono= fila.telefono, tipodoc= fila.tipodoc WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.persona(apellido, barra, carct, contcarencia, email, estcivil, fechafinos, fechainios, fechanac, idcentrodireccion, iddireccion, nombres, nrodoc, nrodocreal, personacc, sexo, telefono, tipodoc) VALUES (fila.apellido, fila.barra, fila.carct, fila.contcarencia, fila.email, fila.estcivil, fila.fechafinos, fila.fechainios, fila.fechanac, fila.idcentrodireccion, fila.iddireccion, fila.nombres, fila.nrodoc, fila.nrodocreal, fila.personacc, fila.sexo, fila.telefono, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
