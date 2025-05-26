CREATE OR REPLACE FUNCTION public.log_getcambios_public_practicavalores(viejo practicavalores, nuevo practicavalores, OUT campos character varying[], OUT valores character varying[])
 RETURNS record
 LANGUAGE plpgsql
AS $function$
declare indice integer:=1;
begin if viejo.idcapitulo <> nuevo.idcapitulo OR nullvalue(viejo.idcapitulo) OR nullvalue(nuevo.idcapitulo) then
	       campos[indice] = 'idcapitulo';
	       valores[indice] = viejo.idcapitulo;
	       indice:=indice+1;
	end if;if viejo.idsubcapitulo <> nuevo.idsubcapitulo OR nullvalue(viejo.idsubcapitulo) OR nullvalue(nuevo.idsubcapitulo) then
	       campos[indice] = 'idsubcapitulo';
	       valores[indice] = viejo.idsubcapitulo;
	       indice:=indice+1;
	end if;if viejo.idpractica <> nuevo.idpractica OR nullvalue(viejo.idpractica) OR nullvalue(nuevo.idpractica) then
	       campos[indice] = 'idpractica';
	       valores[indice] = viejo.idpractica;
	       indice:=indice+1;
	end if;if viejo.idsubespecialidad <> nuevo.idsubespecialidad OR nullvalue(viejo.idsubespecialidad) OR nullvalue(nuevo.idsubespecialidad) then
	       campos[indice] = 'idsubespecialidad';
	       valores[indice] = viejo.idsubespecialidad;
	       indice:=indice+1;
	end if;if viejo.importe <> nuevo.importe OR nullvalue(viejo.importe) OR nullvalue(nuevo.importe) then
	       campos[indice] = 'importe';
	       valores[indice] = viejo.importe;
	       indice:=indice+1;
	end if;if viejo.internacion <> nuevo.internacion OR nullvalue(viejo.internacion) OR nullvalue(nuevo.internacion) then
	       campos[indice] = 'internacion';
	       valores[indice] = viejo.internacion;
	       indice:=indice+1;
	end if;if viejo.idasocconv <> nuevo.idasocconv OR nullvalue(viejo.idasocconv) OR nullvalue(nuevo.idasocconv) then
	       campos[indice] = 'idasocconv';
	       valores[indice] = viejo.idasocconv;
	       indice:=indice+1;
	end if;if viejo.pvidusuario <> nuevo.pvidusuario OR nullvalue(viejo.pvidusuario) OR nullvalue(nuevo.pvidusuario) then
	       campos[indice] = 'pvidusuario';
	       valores[indice] = viejo.pvidusuario;
	       indice:=indice+1;
	end if;end;
$function$
