CREATE OR REPLACE FUNCTION public.abmtitular()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
cursortitulares CURSOR FOR SELECT *
                           FROM titular_temp;
                          
        rtitular RECORD;
	rtitularexistente record;
        rpersona record;
        rafilsosunc record;

        resp boolean;        
        rusuario RECORD;
                          
BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;
                           
OPEN cursortitulares;
FETCH cursortitulares into rtitular;
WHILE  found LOOP

    SELECT INTO rpersona * FROM persona WHERE nrodoc = rtitular.nrodoc AND tipodoc = rtitular.tipodoc;

IF FOUND THEN
--- El titular no existe y es nuevo
-----------------------------------------------------------------------
      INSERT INTO persona(nrodoc,apellido,nombres,fechanac,sexo,estcivil,telefono,email,fechainios,fechafinos,iddireccion,tipodoc,carct
,idcentrodireccion,nrodocreal)VALUES (rtitular.nrodoc,rtitular.apellido,rtitular.nombres,rtitular.fechanac,rtitular.sexo,rtitular.estcivil,rtitular.telefono,
rtitular.email,rtitular.fechainios,rtitular.fechafinos,rtitular.iddireccion,rtitular.tipodoc,rtitular.caract,
rtitular.idcentrodireccion,rtitular.nrodocreal);

        SELECT INTO rafilsosunc * FROM afilsosunc WHERE nrodoc = rperso.nrodoc AND tipodoc = rperso.tipodoc;
        if NOT FOUND then /*Es nuevo*/

          INSERT INTO afilsosunc (nrodoc,nrocuilini,nrocuildni,nrocuilfin,nroosexterna,idosexterna,tipodoc,idestado,barra)
      VALUES(rtitular.nrodoc,rtitular.inicuil,rtitular.mediocuil,rtitular.fincuil,rtitular.nroosexterna,rtitular.osexterna,
rtitular.tipodoc,rtitular.idestado,rtitular.barra);
 else
 	 UPDATE afilsosunc SET nrocuilini = rafiliado.inicuil
                       , nrocuildni = rafiliado.mediocuil
                       , nrocuilfin = rafiliado.fincuil
                       , nroosexterna = rafiliado.nroosexterna
                       , idosexterna = rafiliado.osexterna
                       , idestado = estado
                       , barra=tipoafiliado
   WHERE nrodoc = rperso.nrodoc AND tipodoc = rperso.tipodoc;
end if;

        
   
---------------------------------------------------
ELSE
    IF (rtitular.accion = 'Eliminar') THEN
    --Existe y tengo que eliminarlo, solo puedo eliminarlo desactivarlo. La FK me bloquea el borrado.
       UPDATE  persona set pactivo='false' WHERE  nrodoc = rtitular.nrodoc AND tipodoc = rtitular.tipodoc;

       
       
     ELSE
     --El titular existe y hay que actualizarlo.
       
      UPDATE  persona set pactivo=false WHERE  nrodoc = rtitular.nrodoc AND tipodoc = rtitular.tipodoc;

END IF;



END IF;

fetch cursortitulares into rtitular;
END LOOP;
close cursortitulares;

 
return true;

END;
$function$
