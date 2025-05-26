CREATE OR REPLACE FUNCTION public.buscarcargos(integer, character varying, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	pers RECORD;
	resultado boolean;
	usuario alias for $4;
	rcargo CURSOR FOR SELECT * FROM cargo WHERE nrodoc = $2 AND tipodoc= $1;
	car RECORD;
	rbec refcursor;
	tipodisc varchar;
	rcategoria RECORD;
	dependencia varchar;
	tipoafil varchar;
	jub RECORD;
	pen RECORD;
	cert RECORD;
	resolucion RECORD;
	nohay boolean;
	
BEGIN
select into pers tiposdoc.descrip as tipodoc from afilsosunc,tiposdoc where afilsosunc.tipodoc = $1 and afilsosunc.nrodoc =$2 and afilsosunc.barra = $3 and afilsosunc.tipodoc=tiposdoc.tipodoc;
if FOUND
  then--existe el titular en sosunc con lo que podrÃ­a tener algun tipo de cargo
    DELETE FROM rlaborales WHERE idusuario = usuario;
    DELETE FROM rlabpen WHERE idusuario = usuario;
    DELETE FROM rlabjub WHERE idusuario = usuario;
    nohay = 'true';
	OPEN rcargo;
	FETCH rcargo INTO car;
	WHILE  found LOOP
	nohay ='false';
		  SELECT INTO rcategoria * FROM categoria WHERE idcateg = car.idcateg;
		  SELECT INTO dependencia descrip FROM depuniversitaria WHERE iddepen = car.iddepen;
		  if rcategoria.seaplica = 30
		  	then
		  		tipoafil = 'DOCENTE';
		  end if;
		  if rcategoria.seaplica = 31
		  	then
		  		tipoafil = 'NO DOCENTE';
		  end if;
		  if rcategoria.seaplica = 32
		  	then
		  		tipoafil = 'SOSUNC';
		  end if;
		  if rcategoria.seaplica = 33
		  	then
		  		tipoafil = 'RECURSOS PROPIOS';
		  end if;
		  if rcategoria.seaplica = 37
		  	then
		  		tipoafil = 'AUTORIDAD';
		  end if;
          INSERT INTO rlaborales VALUES ($2,car.legajosiu,car.idcargo,car.fechainilab,car.fechafinlab,rcategoria.descrip,dependencia,car.tellab,pers.tipodoc,usuario,tipoafil);
	      fetch rcargo into car;
	END LOOP;
	CLOSE rcargo;
	SELECT INTO car * FROM afilibec WHERE nrodoc = $2 and tipodoc =$1;
	if FOUND then
            nohay = 'false';
            OPEN rbec FOR SELECT * FROM afilibec
                         NATURAL JOIN resolbec
                         WHERE nrodoc = $2 and tipodoc =$1;
	        FETCH rbec INTO car;
	        WHILE  found LOOP
			SELECT INTO resolucion * FROM resolbec WHERE idresolbe=car.idresolbe;
			IF FOUND THEN
			   SELECT INTO rcategoria * FROM categoria WHERE idcateg=resolucion.idcateg;
			   SELECT INTO dependencia descrip FROM depuniversitaria WHERE iddepen = resolucion.iddepen;
			   tipoafil = 'BECARIO';
		       INSERT INTO rlaborales VALUES ($2,0,resolucion.idresolbe,resolucion.fechainilab,resolucion.fechafinlab,rcategoria.descrip,rcategoria.idcateg,dependencia,0,pers.tipodoc,usuario,tipoafil);
            END IF;
            fetch rbec into car;
            END LOOP;
	        CLOSE rbec;
	end if;
	SELECT INTO jub * FROM afiljub WHERE nrodoc = $2 and tipodoc=$1;
	if FOUND
		then
			SELECT INTO cert * FROM certpersonal WHERE idcertpers = jub.idcertpers;
			if FOUND
				then
					nohay='false';
					SELECT INTO rcategoria * FROM categoria WHERE idcateg=cert.idcateg;
					INSERT INTO rlabjub VALUES ($2,jub.trabaja,jub.trabajaunc,jub.ingreso,cert.cantaport,rcategoria.descrip,pers.tipodoc,usuario);
			end if;
	end if;
	SELECT INTO pen * FROM afilpen WHERE nrodoc = $2 and tipodoc=$1;
	if FOUND
		then
		 nohay='false';
		 INSERT INTO rlabpen VALUES ($2,pen.trabaja,pen.ingreso,pers.tipodoc,usuario);
	end if;
	if nohay
		then
		  resultado = 'false';
		else
		  resultado ='true';	 
	end if;
  else --no hay una persona con los datos especificados como parÃ¡metros
  	resultado = 'false';
end if;

return resultado;
END;
$function$
