CREATE OR REPLACE FUNCTION public.log_getcambios_public_contabilidad_periodofiscal(viejo contabilidad_periodofiscal, nuevo contabilidad_periodofiscal, OUT campos character varying[], OUT valores character varying[])
 RETURNS record
 LANGUAGE plpgsql
AS $function$
declare indice integer:=1;
begin if viejo.idperiodofiscal <> nuevo.idperiodofiscal OR nullvalue(viejo.idperiodofiscal) OR nullvalue(nuevo.idperiodofiscal) then
	       campos[indice] = 'idperiodofiscal';
	       valores[indice] = viejo.idperiodofiscal;
	       indice:=indice+1;
	end if;if viejo.pffechadesde <> nuevo.pffechadesde OR nullvalue(viejo.pffechadesde) OR nullvalue(nuevo.pffechadesde) then
	       campos[indice] = 'pffechadesde';
	       valores[indice] = viejo.pffechadesde;
	       indice:=indice+1;
	end if;if viejo.pffechahasta <> nuevo.pffechahasta OR nullvalue(viejo.pffechahasta) OR nullvalue(nuevo.pffechahasta) then
	       campos[indice] = 'pffechahasta';
	       valores[indice] = viejo.pffechahasta;
	       indice:=indice+1;
	end if;if viejo.pfcerrado <> nuevo.pfcerrado OR nullvalue(viejo.pfcerrado) OR nullvalue(nuevo.pfcerrado) then
	       campos[indice] = 'pfcerrado';
	       valores[indice] = viejo.pfcerrado;
	       indice:=indice+1;
	end if;if viejo.pftipoiva <> nuevo.pftipoiva OR nullvalue(viejo.pftipoiva) OR nullvalue(nuevo.pftipoiva) then
	       campos[indice] = 'pftipoiva';
	       valores[indice] = viejo.pftipoiva;
	       indice:=indice+1;
	end if;if viejo.pffechacreacion <> nuevo.pffechacreacion OR nullvalue(viejo.pffechacreacion) OR nullvalue(nuevo.pffechacreacion) then
	       campos[indice] = 'pffechacreacion';
	       valores[indice] = viejo.pffechacreacion;
	       indice:=indice+1;
	end if;end;
$function$
