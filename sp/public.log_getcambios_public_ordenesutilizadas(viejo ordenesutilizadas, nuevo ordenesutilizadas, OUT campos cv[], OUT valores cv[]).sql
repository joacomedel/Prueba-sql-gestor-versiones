CREATE OR REPLACE FUNCTION public.log_getcambios_public_ordenesutilizadas(viejo ordenesutilizadas, nuevo ordenesutilizadas, OUT campos character varying[], OUT valores character varying[])
 RETURNS record
 LANGUAGE plpgsql
AS $function$
declare indice integer:=1;
begin if viejo.nroorden <> nuevo.nroorden OR nullvalue(viejo.nroorden) OR nullvalue(nuevo.nroorden) then
	       campos[indice] = 'nroorden';
	       valores[indice] = viejo.nroorden;
	       indice:=indice+1;
	end if;if viejo.centro <> nuevo.centro OR nullvalue(viejo.centro) OR nullvalue(nuevo.centro) then
	       campos[indice] = 'centro';
	       valores[indice] = viejo.centro;
	       indice:=indice+1;
	end if;if viejo.idosreci <> nuevo.idosreci OR nullvalue(viejo.idosreci) OR nullvalue(nuevo.idosreci) then
	       campos[indice] = 'idosreci';
	       valores[indice] = viejo.idosreci;
	       indice:=indice+1;
	end if;if viejo.idprestador <> nuevo.idprestador OR nullvalue(viejo.idprestador) OR nullvalue(nuevo.idprestador) then
	       campos[indice] = 'idprestador';
	       valores[indice] = viejo.idprestador;
	       indice:=indice+1;
	end if;if viejo.fechauso <> nuevo.fechauso OR nullvalue(viejo.fechauso) OR nullvalue(nuevo.fechauso) then
	       campos[indice] = 'fechauso';
	       valores[indice] = viejo.fechauso;
	       indice:=indice+1;
	end if;if viejo.importe <> nuevo.importe OR nullvalue(viejo.importe) OR nullvalue(nuevo.importe) then
	       campos[indice] = 'importe';
	       valores[indice] = viejo.importe;
	       indice:=indice+1;
	end if;if viejo.fechaauditoria <> nuevo.fechaauditoria OR nullvalue(viejo.fechaauditoria) OR nullvalue(nuevo.fechaauditoria) then
	       campos[indice] = 'fechaauditoria';
	       valores[indice] = viejo.fechaauditoria;
	       indice:=indice+1;
	end if;if viejo.nromatricula <> nuevo.nromatricula OR nullvalue(viejo.nromatricula) OR nullvalue(nuevo.nromatricula) then
	       campos[indice] = 'nromatricula';
	       valores[indice] = viejo.nromatricula;
	       indice:=indice+1;
	end if;if viejo.malcance <> nuevo.malcance OR nullvalue(viejo.malcance) OR nullvalue(nuevo.malcance) then
	       campos[indice] = 'malcance';
	       valores[indice] = viejo.malcance;
	       indice:=indice+1;
	end if;if viejo.mespecialidad <> nuevo.mespecialidad OR nullvalue(viejo.mespecialidad) OR nullvalue(nuevo.mespecialidad) then
	       campos[indice] = 'mespecialidad';
	       valores[indice] = viejo.mespecialidad;
	       indice:=indice+1;
	end if;if viejo.idplancobertura <> nuevo.idplancobertura OR nullvalue(viejo.idplancobertura) OR nullvalue(nuevo.idplancobertura) then
	       campos[indice] = 'idplancobertura';
	       valores[indice] = viejo.idplancobertura;
	       indice:=indice+1;
	end if;if viejo.nrodocuso <> nuevo.nrodocuso OR nullvalue(viejo.nrodocuso) OR nullvalue(nuevo.nrodocuso) then
	       campos[indice] = 'nrodocuso';
	       valores[indice] = viejo.nrodocuso;
	       indice:=indice+1;
	end if;if viejo.tipodocuso <> nuevo.tipodocuso OR nullvalue(viejo.tipodocuso) OR nullvalue(nuevo.tipodocuso) then
	       campos[indice] = 'tipodocuso';
	       valores[indice] = viejo.tipodocuso;
	       indice:=indice+1;
	end if;if viejo.tipo <> nuevo.tipo OR nullvalue(viejo.tipo) OR nullvalue(nuevo.tipo) then
	       campos[indice] = 'tipo';
	       valores[indice] = viejo.tipo;
	       indice:=indice+1;
	end if;if viejo.ordenesutilizadascc <> nuevo.ordenesutilizadascc OR nullvalue(viejo.ordenesutilizadascc) OR nullvalue(nuevo.ordenesutilizadascc) then
	       campos[indice] = 'ordenesutilizadascc';
	       valores[indice] = viejo.ordenesutilizadascc;
	       indice:=indice+1;
	end if;end;
$function$
