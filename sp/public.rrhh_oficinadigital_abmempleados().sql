CREATE OR REPLACE FUNCTION public.rrhh_oficinadigital_abmempleados()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$/* Ingresa la informacion de un empleado a la estructura de oficina digital (uncoma) */

DECLARE 
--VARIABLES
  viduasuario BIGINT;
  vidcargo BIGINT;

--REGISTRO
  rempleado RECORD;
  rjefesector  RECORD;
BEGIN

 SELECT INTO rempleado ofa_stsusuario.idusuario, emlegajo::bigint, peemail, peapellido, penombre, emfechadesde, penrodoc, peemail, penrocuil, tdnombre, ca.sexo.sedescripcion as descripcionsexo, pefechanac, lodescripcion, petelefonofijo, petelefono, 'SOS' iddepen, ca.sector.sedescripcion as descripcionsector, emtarea, ca.sector.idsector
 FROM ca.persona JOIN ca.empleado USING(idpersona) JOIN ca.sector USING(idsector) JOIN ca.tipodocumento USING(idtipodocumento) LEFT JOIN ca.sexo USING(idsexo) LEFT JOIN ca.domicilio USING(iddomicilio) LEFT JOIN ca.localidad USING(idlocalidad) LEFT JOIN ofa_stsusuario ON (ca.empleado.emlegajo= idusuario)
  WHERE ca.persona.idpersona = NEW.idpersona;

 IF FOUND THEN 
 --Comienzo a insertar en la estructura que espera la oficina digital 
 --Según lo hablado el mail es el usuario, SELECT count(*) FROM "ca"."persona"c where nullvalue(peemail) 174 tienen mail nulo

  IF rempleado.idusuario is null and not nullvalue(rempleado.peemail) THEN 
--Lo doy de alta
    INSERT INTO ofa_stsusuario (idusuario , usuaname, nombcomp, estado, fecha_ingreso,usuapass ,admin , app) 
    VALUES(rempleado.emlegajo::bigint, rempleado.peemail, concat(rempleado.peapellido, ' ',rempleado.penombre),1,rempleado.emfechadesde, rempleado.penrodoc,0,0);
 
    INSERT INTO ofa_agentes(legajo, apellido, nombre, cuil, estado, tipodoc, nrodoc, sexo, fechanac,localidad, telefono, celular  , correo, fechaalt)
    VALUES(rempleado.emlegajo::integer,rempleado.peapellido,rempleado.penombre,rempleado.penrocuil,'Activo',rempleado.tdnombre, rempleado.penrodoc::integer, substring(rempleado.descripcionsexo, 1, 1), rempleado.pefechanac, rempleado.lodescripcion, rempleado.petelefonofijo, rempleado.petelefono, rempleado.peemail, rempleado.emfechadesde);

    INSERT INTO ofa_cargos(legajo, carfechalta, dependencia, catdesc, deddesc, escalafon, caracter) 
    VALUES (rempleado.emlegajo::integer, rempleado.emfechadesde, rempleado.iddepen, rempleado.descripcionsector, rempleado.emtarea,'NODO', 'ORDI');
   
    vidcargo = nextval('ofa_cargos_carnum_seq');

 --POR defecto pongo los permisos que todos los empleados tienen que son CERTIFICADO, LICENCIA
    INSERT INTO ofa_stsgrupusua(idsistema, idgrupo, idusuario) VALUES (10, 2, rempleado.emlegajo::integer), (13, 2, rempleado.emlegajo::integer);

--uso la tabla sectorempleadojefe
--BUSCO quien es el jefe del sector
    SELECT INTO rjefesector * FROM ca.sectorempleadojefe 
--NATURAL JOIN ca.persona  NATURAL JOIN ca.empleado  
--WHERE idsector = rempleado.idsector;
   JOIN ca.persona  
   using(idpersona)
   JOIN ca.empleado  using(idpersona)
    WHERE sectorempleadojefe.idsector = rempleado.idsector;

     IF NOT nullvalue(rjefesector.emlegajo ) THEN
                     INSERT INTO ofa_organigrama (legajo, dependencia, carnum, jefe, verificado) VALUES
  (rempleado.emlegajo::integer, rempleado.iddepen, vidcargo, rjefesector.emlegajo::integer, 0);
      END IF;    

  ELSE --EL empleado ya existe en la estructura de oficina digital

      UPDATE ofa_stsusuario SET nombcomp =  concat(rempleado.peapellido, ' ',rempleado.penombre),fecha_ingreso = rempleado.emfechadesde
		WHERE idusuario = rempleado.idusuario;
      UPDATE ofa_agentes SET apellido = rempleado.peapellido, nombre= rempleado.penombre, cuil= rempleado.penrocuil, sexo= substring(rempleado.descripcionsexo, 1, 1), fechanac = rempleado.pefechanac, localidad= rempleado.lodescripcion, telefono=rempleado.petelefonofijo, celular= rempleado.petelefono,correo= rempleado.peemail, fechaalt=rempleado.emfechadesde, fecha_ingreso =rempleado.emfechadesde
		WHERE legajo = rempleado.emlegajo;

      UPDATE ofa_cargos SET carfechalta =  rempleado.emfechadesde, dependencia= rempleado.iddepen, catdesc=rempleado.emtarea 
		WHERE legajo = rempleado.emlegajo;

      --se carga en la tabla ofa_organigrama los 2 jefes 
  END IF;
 END IF;

return NEW;
END;$function$
