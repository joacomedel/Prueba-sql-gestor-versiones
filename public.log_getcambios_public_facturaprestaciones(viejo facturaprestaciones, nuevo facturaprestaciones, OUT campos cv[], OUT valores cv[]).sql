CREATE OR REPLACE FUNCTION public.log_getcambios_public_facturaprestaciones(viejo facturaprestaciones, nuevo facturaprestaciones, OUT campos character varying[], OUT valores character varying[])
 RETURNS record
 LANGUAGE plpgsql
AS $function$
declare indice integer:=1;
begin if viejo.anio <> nuevo.anio OR nullvalue(viejo.anio) OR nullvalue(nuevo.anio) then
	       campos[indice] = 'anio';
	       valores[indice] = viejo.anio;
	       indice:=indice+1;
	end if;if viejo.nroregistro <> nuevo.nroregistro OR nullvalue(viejo.nroregistro) OR nullvalue(nuevo.nroregistro) then
	       campos[indice] = 'nroregistro';
	       valores[indice] = viejo.nroregistro;
	       indice:=indice+1;
	end if;if viejo.fidtipoprestacion <> nuevo.fidtipoprestacion OR nullvalue(viejo.fidtipoprestacion) OR nullvalue(nuevo.fidtipoprestacion) then
	       campos[indice] = 'fidtipoprestacion';
	       valores[indice] = viejo.fidtipoprestacion;
	       indice:=indice+1;
	end if;if viejo.importe <> nuevo.importe OR nullvalue(viejo.importe) OR nullvalue(nuevo.importe) then
	       campos[indice] = 'importe';
	       valores[indice] = viejo.importe;
	       indice:=indice+1;
	end if;if viejo.observacion <> nuevo.observacion OR nullvalue(viejo.observacion) OR nullvalue(nuevo.observacion) then
	       campos[indice] = 'observacion';
	       valores[indice] = viejo.observacion;
	       indice:=indice+1;
	end if;if viejo.debito <> nuevo.debito OR nullvalue(viejo.debito) OR nullvalue(nuevo.debito) then
	       campos[indice] = 'debito';
	       valores[indice] = viejo.debito;
	       indice:=indice+1;
	end if;if viejo.facturaprestacionescc <> nuevo.facturaprestacionescc OR nullvalue(viejo.facturaprestacionescc) OR nullvalue(nuevo.facturaprestacionescc) then
	       campos[indice] = 'facturaprestacionescc';
	       valores[indice] = viejo.facturaprestacionescc;
	       indice:=indice+1;
	end if;end;
$function$
