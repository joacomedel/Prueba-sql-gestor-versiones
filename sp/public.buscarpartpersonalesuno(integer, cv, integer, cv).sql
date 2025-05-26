CREATE OR REPLACE FUNCTION public.buscarpartpersonalesuno(integer, character varying, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	tipodocumento alias for $1;
        numerodocumento alias for $2;
        barra alias for $3;


pers RECORD;
        datos RECORD;
	resultado boolean;
	usuario alias for $4;
BEGIN

SELECT INTO pers persona.nrodoc,persona.apellido,persona.nombres,persona.fechanac,persona.sexo,persona.estcivil,persona.email,persona.carct,persona.telefono,tiposdoc.descrip  as tipodoc,  persona.tipodoc as tipodocu,persona.nrodoc as nrodocu, persona.barra FROM persona, tiposdoc WHERE persona.tipodoc = tipodocumento  AND persona.nrodoc =numerodocumento  AND persona.barra = barra  and persona.tipodoc  = tiposdoc.tipodoc;
if FOUND
  then--existe una persona y sera cargada en la tabla para reportes rpersonalesuno
	DELETE FROM rpersonalesuno WHERE idusuario = usuario;
  	INSERT INTO rpersonalesuno VALUES(pers.nrodoc,pers.apellido,pers.nombres,pers.fechanac,pers.sexo,pers.estcivil,pers.email,pers.carct,pers.telefono,'true',pers.tipodoc,pers.barra,usuario);
        select into datos * from  benefsosunc join persona
        on(benefsosunc.nrodoctitu=persona.nrodoc AND benefsosunc.tipodoctitu=                persona.tipodoc)
         where  (benefsosunc.nrodoc=numerodocumento and    benefsosunc.tipodoc=tipodocumento);

         if (datos.nrodoctitu is null) THEN
                 select into datos * from  benefreci join persona
                  on(benefreci.nrodoctitu=persona.nrodoc AND benefreci.tipodoctitu=persona.tipodoc)
         where  (benefreci.nrodoc=numerodocumento and    benefreci.tipodoc=tipodocumento);
         end if;
          UPDATE rpersonalesuno  set
          -- estitu='false',
           nrodoctitu=datos.nrodoctitu,
           tipodoctitu=datos.tipodoctitu
           where (pers.nrodoc=rpersonalesuno.nrodoc and   pers.tipodoc=rpersonalesuno.tipodoc);

  	resultado ='true';
  else --no hay una persona con los datos especificados como parÃÂ¡metros
  	resultado = 'false';
end if;

return resultado;
END;
$function$
