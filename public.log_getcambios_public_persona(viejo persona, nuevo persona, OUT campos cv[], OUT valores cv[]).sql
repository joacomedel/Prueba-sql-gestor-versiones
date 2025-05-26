CREATE OR REPLACE FUNCTION public.log_getcambios_public_persona(viejo persona, nuevo persona, OUT campos character varying[], OUT valores character varying[])
 RETURNS record
 LANGUAGE plpgsql
AS $function$
declare indice integer:=1;
begin if viejo.nrodoc <> nuevo.nrodoc OR nullvalue(viejo.nrodoc) OR nullvalue(nuevo.nrodoc) then
	       campos[indice] = 'nrodoc';
	       valores[indice] = viejo.nrodoc;
	       indice:=indice+1;
	end if;if viejo.apellido <> nuevo.apellido OR nullvalue(viejo.apellido) OR nullvalue(nuevo.apellido) then
	       campos[indice] = 'apellido';
	       valores[indice] = viejo.apellido;
	       indice:=indice+1;
	end if;if viejo.nombres <> nuevo.nombres OR nullvalue(viejo.nombres) OR nullvalue(nuevo.nombres) then
	       campos[indice] = 'nombres';
	       valores[indice] = viejo.nombres;
	       indice:=indice+1;
	end if;if viejo.fechanac <> nuevo.fechanac OR nullvalue(viejo.fechanac) OR nullvalue(nuevo.fechanac) then
	       campos[indice] = 'fechanac';
	       valores[indice] = viejo.fechanac;
	       indice:=indice+1;
	end if;if viejo.sexo <> nuevo.sexo OR nullvalue(viejo.sexo) OR nullvalue(nuevo.sexo) then
	       campos[indice] = 'sexo';
	       valores[indice] = viejo.sexo;
	       indice:=indice+1;
	end if;if viejo.estcivil <> nuevo.estcivil OR nullvalue(viejo.estcivil) OR nullvalue(nuevo.estcivil) then
	       campos[indice] = 'estcivil';
	       valores[indice] = viejo.estcivil;
	       indice:=indice+1;
	end if;if viejo.telefono <> nuevo.telefono OR nullvalue(viejo.telefono) OR nullvalue(nuevo.telefono) then
	       campos[indice] = 'telefono';
	       valores[indice] = viejo.telefono;
	       indice:=indice+1;
	end if;if viejo.email <> nuevo.email OR nullvalue(viejo.email) OR nullvalue(nuevo.email) then
	       campos[indice] = 'email';
	       valores[indice] = viejo.email;
	       indice:=indice+1;
	end if;if viejo.fechainios <> nuevo.fechainios OR nullvalue(viejo.fechainios) OR nullvalue(nuevo.fechainios) then
	       campos[indice] = 'fechainios';
	       valores[indice] = viejo.fechainios;
	       indice:=indice+1;
	end if;if viejo.fechafinos <> nuevo.fechafinos OR nullvalue(viejo.fechafinos) OR nullvalue(nuevo.fechafinos) then
	       campos[indice] = 'fechafinos';
	       valores[indice] = viejo.fechafinos;
	       indice:=indice+1;
	end if;if viejo.iddireccion <> nuevo.iddireccion OR nullvalue(viejo.iddireccion) OR nullvalue(nuevo.iddireccion) then
	       campos[indice] = 'iddireccion';
	       valores[indice] = viejo.iddireccion;
	       indice:=indice+1;
	end if;if viejo.tipodoc <> nuevo.tipodoc OR nullvalue(viejo.tipodoc) OR nullvalue(nuevo.tipodoc) then
	       campos[indice] = 'tipodoc';
	       valores[indice] = viejo.tipodoc;
	       indice:=indice+1;
	end if;if viejo.carct <> nuevo.carct OR nullvalue(viejo.carct) OR nullvalue(nuevo.carct) then
	       campos[indice] = 'carct';
	       valores[indice] = viejo.carct;
	       indice:=indice+1;
	end if;if viejo.barra <> nuevo.barra OR nullvalue(viejo.barra) OR nullvalue(nuevo.barra) then
	       campos[indice] = 'barra';
	       valores[indice] = viejo.barra;
	       indice:=indice+1;
	end if;if viejo.contcarencia <> nuevo.contcarencia OR nullvalue(viejo.contcarencia) OR nullvalue(nuevo.contcarencia) then
	       campos[indice] = 'contcarencia';
	       valores[indice] = viejo.contcarencia;
	       indice:=indice+1;
	end if;if viejo.idcentrodireccion <> nuevo.idcentrodireccion OR nullvalue(viejo.idcentrodireccion) OR nullvalue(nuevo.idcentrodireccion) then
	       campos[indice] = 'idcentrodireccion';
	       valores[indice] = viejo.idcentrodireccion;
	       indice:=indice+1;
	end if;if viejo.nrodocreal <> nuevo.nrodocreal OR nullvalue(viejo.nrodocreal) OR nullvalue(nuevo.nrodocreal) then
	       campos[indice] = 'nrodocreal';
	       valores[indice] = viejo.nrodocreal;
	       indice:=indice+1;
	end if;if viejo.personacc <> nuevo.personacc OR nullvalue(viejo.personacc) OR nullvalue(nuevo.personacc) then
	       campos[indice] = 'personacc';
	       valores[indice] = viejo.personacc;
	       indice:=indice+1;
	end if;end;
$function$
