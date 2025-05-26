CREATE OR REPLACE FUNCTION public.afiliarversion2(integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	 verificacionbd RECORD;
        rafiliado RECORD;
	direct RECORD;
	rperso RECORD;
	persobd RECORD;
	clientebd RECORD;
	discapacidades CURSOR FOR SELECT * FROM discapacidades;
	disc RECORD;
	direcc RECORD;
	personas RECORD;
	rafilsosunc RECORD;
	identdireccion integer;
	ultimo bigint;
	siguiente integer;
	resultado boolean;
	tipoafiliado alias for $1;
	estado alias for $2;
	codigo alias for $3;
	iddir bigint;

	--comienzo afiliar ASI
	tafil RECORD;
    auxi RECORD;
    rtipoafil RECORD;
    connroasi RECORD;
	--fin afiliar ASI

--RECORD
  rerabenef RECORD;

rtemporal RECORD;


BEGIN
 




/*Inserto la Direccion */
SELECT INTO direct * FROM dire;
IF  direct.iddireccion = 0 then /*La direccion es nueva xq la persona no existe en la BBDD*/
		INSERT INTO direccion(barrio,
                              calle,
                              nro,
                              tira,
                              piso,
                              dpto,
                              idprovincia,
                              idlocalidad) VALUES(direct.barrio,direct.calle,direct.nro,direct.tira,direct.piso,direct.dpto,direct.idprovincia,direct.idlocalidad );
                              /*(SELECT barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad FROM dire);*/
	    SELECT currval('direccion_iddireccion_seq') INTO iddir;

else
	UPDATE direccion
		SET
			--iddireccion = direcT.iddireccion,
			barrio = direct.barrio,
			calle = direct.calle,
			nro = direct.nro,
			tira = direct.tira,
			piso = direct.piso,
			dpto = direct.dpto,
			idprovincia = direct.idprovincia,
			idlocalidad = direct.idlocalidad
		WHERE iddireccion = direct.iddireccion and idcentrodireccion = direct.idcentrodireccion;
END IF;





/*Inserto los datos de Persona*/
SELECT INTO rperso * FROM pers;


SELECT  INTO rtemporal attname, format_type(atttypid, atttypmod) AS type
FROM   pg_attribute
WHERE  attrelid = 'pers'::regclass
AND    attnum > 0
AND    NOT attisdropped
AND attname = 'nrodocreal'
ORDER  BY attnum;
IF NOT FOUND THEN 
   ALTER TABLE pers ADD COLUMN nrodocreal text;
   UPDATE pers SET nrodocreal = rperso.nrodoc;
   SELECT INTO rperso * FROM pers;
  
END IF;


SELECT INTO persobd * FROM persona WHERE nrodoc = rperso.nrodoc AND tipodoc = rperso.tipodoc;
IF NOT FOUND then /*La persona no Existe*/
	INSERT INTO persona (nrodoc,apellido,nombres,fechanac,sexo,estcivil,telefono,email,fechainios,fechafinos
    ,iddireccion,idcentrodireccion,tipodoc,carct,nrodocreal)
    VALUES(rperso.nrodoc,rperso.apellido,rperso.nombres,rperso.fechanac, rperso.sexo,rperso.estcivil,rperso.telefono,rperso.email,rperso.fechainios,rperso.fechafinos
    ,iddir,centro(),rperso.tipodoc,rperso.carct,rperso.nrodocreal);
    SELECT INTO clientebd * FROM cliente WHERE nrocliente = rperso.nrodoc;
    IF NOT FOUND then /*El cliente no Existe*/
         INSERT INTO cliente(nrocliente,barra,denominacion,idtipocliente,idcondicioniva,iddireccion,idcentrodireccion,telefono,email) VALUES
         (rperso.nrodoc, rperso.tipodoc,concat ( rperso.apellido , ', ' , rperso.nombres),1,1,iddir,centro(),rperso.telefono,rperso.email);
    END IF;
	INSERT INTO verificacion VALUES(codigo,rperso.nrodoc,3,tipoafiliado,rperso.fechainios);
	else /*Se actualizan los datos*/
		UPDATE persona
		SET
			apellido = rperso.apellido,
			nombres = rperso.nombres,
			fechanac = rperso.fechanac,
			sexo = rperso.sexo,
			estcivil = rperso.estcivil,
			telefono = rperso.telefono,
			email = rperso.email,
			fechainios = rperso.fechainios,
			fechafinos = rperso.fechafinos,
		--	iddireccion = persoT.iddireccion,
		--	idcentrodireccion= persoT.idcentrodireccion,
			carct = rperso.carct,
                         barra = tipoafiliado,
                         nrodocreal = rperso.nrodoc
	
		WHERE nrodoc = rperso.nrodoc AND tipodoc = rperso.tipodoc;
			

  /*actualizo datos de la tabla verificacion  hector */

              SELECT INTO verificacionbd * FROM verificacion WHERE nrodoc= rperso.nrodoc;
             IF NOT FOUND then /*la verificacion no Existe*/
                 INSERT INTO verificacion VALUES(codigo,rperso.nrodoc,3,tipoafiliado,rperso.fechainios);
             else  /*la verificacion  Existe*/
                 update verificacion set barra=tipoafiliado where   nrodoc= rperso.nrodoc;

             END IF;
   
          /*actualizo datos de la tabla cliente  hector */

             SELECT INTO clientebd * FROM cliente WHERE nrocliente = rperso.nrodoc;

             IF NOT FOUND then /*El cliente no Existe*/
                 INSERT INTO
            cliente(nrocliente,barra,denominacion,idtipocliente,idcondicioniva,iddireccion,idcentrodireccion,telefono,email)
                VALUES (rperso.nrodoc,rperso.tipodoc,concat ( rperso.apellido , ', ' , rperso.nombres),1,1,rperso.iddireccion,centro(),rperso.telefono,rperso.email);
             else  /*El cliente  Existe*/
                 update cliente set barra=rperso.tipodoc,denominacion = concat ( rperso.apellido , ', ' , rperso.nombres) where nrocliente= rperso.nrodoc;
             END IF;


         /*borro d la tabla barras anteriores */

          delete from barras where nrodoc= rperso.nrodoc;


END IF;
/*SELECT INTO resultado * FROM tratardiscapacidades();*/
if NOT resultado then
   return 'false';
end if;
/*Inserto los datos de afilsosunc*/
SELECT INTO rafiliado * FROM afil;
SELECT INTO rafilsosunc * FROM afilsosunc WHERE nrodoc = rperso.nrodoc AND tipodoc = rperso.tipodoc;
if NOT FOUND then /*Es nuevo*/
   INSERT INTO afilsosunc (nrodoc,nrocuilini,nrocuildni,nrocuilfin,nroosexterna,idosexterna,tipodoc,idestado,barra)
     VALUES(rafiliado.nrodoc,rafiliado.inicuil,rafiliado.mediocuil,rafiliado.fincuil,rafiliado.nroosexterna,rafiliado.osexterna,rafiliado.tipodoc,estado,tipoafiliado);
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


--KR 10-01-20 Verifico que el afiliado no exista como beneficiario, si es asi lo elimino de la tabla benefsosunc
  SELECT INTO rerabenef * FROM benefsosunc  WHERE nrodoc = rperso.nrodoc AND tipodoc = rperso.tipodoc;
  
  IF FOUND THEN 
      DELETE FROM benefsosunc WHERE nrodoc = rerabenef.nrodoc AND tipodoc= rerabenef.tipodoc;
  END IF;

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
	     if (tipoafiliado = 32) then
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
					  if (tipoafiliado = 37) then
					        SELECT INTO resultado * FROM afiliarautoridad();
						if NOT resultado then
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
 --Comienzo afiliar ASI
  SELECT INTO rtipoafil * FROM prioridadesafil WHERE prioridadesafil.barra = tipoafiliado;
 SELECT INTO auxi * FROM tafiliado WHERE nrodoc = rafiliado.nrodoc AND tipodoc = rafiliado.tipodoc;
 IF NOT FOUND THEN
    IF (tipoafiliado = 32) THEN
--Malapi 25-03-2015 El Nro asi no es mas una secuencia, es el nrodoc 
           INSERT INTO tafiliado (benef,nrodoc,tipodoc,barratemp,tipoafil,idafiliado)
           VALUES (FALSE,rafiliado.nrodoc,rafiliado.tipodoc,tipoafiliado,rtipoafil.descripcion,rafiliado.nrodoc);
     ELSE
           --Malapi 25-03-2015 El Nro asi no es mas una secuencia, es el nrodoc 
           INSERT INTO tafiliado (benef,nrodoc,tipodoc,barratemp,tipoafil,idafiliado)
           VALUES (FALSE,rafiliado.nrodoc,rafiliado.tipodoc,tipoafiliado,rtipoafil.descripcion,rafiliado.nrodoc);
     END IF;
 ELSE /*Puedes estar cargado pero sin numero de ASI*/
      SELECT INTO connroasi * FROM tafiliado WHERE nrodoc = rafiliado.nrodoc AND tipodoc = rafiliado.tipodoc AND nullvalue(tafiliado.idafiliado);
      IF FOUND THEN /*Quiere decir que la tupla existe, solo que no tiene el Nro Asi asignado*/
               --Malapi 25-03-2015 El Nro asi no es mas una secuencia, es el nrodoc 
               IF (tipoafiliado = 32) THEN
                     UPDATE tafiliado set idafiliado = rafiliado.nrodoc
                     WHERE nrodoc = rafiliado.nrodoc AND tipodoc = rafiliado.tipodoc;
               ELSE
                     UPDATE tafiliado set idafiliado = rafiliado.nrodoc
                     WHERE nrodoc = rafiliado.nrodoc AND tipodoc = rafiliado.tipodoc;
               END IF;
      ELSE /*Quiere decir que existe y ya tiene un Nro asi asignado*/
          IF auxi.benef THEN /*Si esta en tafiliado como un Beneficiario, hay que cambiarle el nro ASI*/
           IF (tipoafiliado = 32) THEN
                UPDATE tafiliado SET benef = false
                                     ,barratemp = tipoafiliado
                                     ,tipoafil =  rtipoafil.descripcion
                                     ,idafiliado = rafiliado.nrodoc
                WHERE nrodoc = rafiliado.nrodoc     AND tipodoc = rafiliado.tipodoc;
           ELSE
               UPDATE tafiliado SET benef = false
                                     ,barratemp = tipoafiliado
                                     ,tipoafil =  rtipoafil.descripcion
                                     ,idafiliado = rafiliado.nrodoc
                WHERE nrodoc = rafiliado.nrodoc     AND tipodoc = rafiliado.tipodoc;
           END IF;
          END IF;
      END IF;
      
      
 END IF;

 --Igresar Persona Plan si corresponde
    SELECT INTO resultado * FROM ingresarpersonaplan(rperso.nrodoc,rperso.tipodoc,null,now()::date);
--Fin afiliar ASI
    SELECT INTO resultado * FROM determinarregularidad(estado,rperso.tipodoc,rperso.nrodoc);
  return resultado;
END;
$function$
