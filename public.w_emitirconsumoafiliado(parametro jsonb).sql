CREATE OR REPLACE FUNCTION public.w_emitirconsumoafiliado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
 SELECT * FROM w_emitirconsumoafiliado('{"NroAfiliado":"28262936","Barra":"1","NroDocumento":"28262936","TipoDocumento":"DNI","Track":null,"ApellidoEfector":"","NombreEfector":"","Diagnostico":"deseo de fertilidad","token":"suap1234","info_consumio_token":"suap","FechaConsumo":"2021-09-06 00:00:00","CuilEfector":"30654752636","MatriculaEfector":"137","CategoriaEfector":"","ApellidoPrescriptor":null,"NombrePrescriptor":null,"CuilPrescriptor":"27229445966","MatriculaNacionalPrescriptor":"","MatriculaProvincialPrescriptor":"4036","EspecialidadPrescriptor":"","codigo_consumo_prestador":"NQN1988774","contexto_atencion":"Ambulatorio","punto_atencion_id":"111","punto_atencion":"LACHYBS S.A. - CLINICA DR. ROBERTO RAu00d1A","punto_atencion_CUIT":"30654752636","ConsumosWeb":[{"CodigoConvenio":"07.66.27.2790"},{"CodigoConvenio":"07.66.26.2675"},{"CodigoConvenio":"07.66.99.9913"},{"CodigoConvenio":"07.66.83.8315"}],"uwnombre":"usucbn"}')

*/
DECLARE
       respuestajson jsonb;
       jsontoken jsonb;
       jsonafiliado jsonb;
       jsonparamnotif jsonb;
--RECORD
       rconsumo RECORD;
 
       
begin
 

   --MaLaPi 13-06-2019 Genera el agrupamiento de las practicas para que se puedan verificar 
   --     PERFORM w_emitirconsumoafiliado_agrupar(parametro);

--Verifico si el token esta activo
    IF (not(parametro->>'info_consumio_token'  = 'evweb')) AND (not(parametro->>'info_consumio_token'  = 'suap')) THEN  
          ----- 061123 al emitir se vuelve a invocar a esta funcion... analizar de quitar la invocacion en este punto w_consumir_token_afiliado
	SELECT INTO jsontoken * FROM w_consumir_token_afiliado(parametro);
    END IF;   
       SELECT INTO jsonafiliado * FROM w_determinarelegibilidadafiliado(parametro);
	--MaLaPi 01/09/2021 Si esta todo bien hay que 
	--Si el consumo existe hay que retornar una orden ya emitida SELECT w_retornar_orden_consumoafiliado('data');	
	--KR 06-09-21 pongo en prd el cambio que comento ML el 01-09-21
       SELECT INTO rconsumo *, (nroorden*100+centro) as codigo FROM ordenonlineinfoextra where ooiecodigoprestador = parametro->>'codigo_consumo_prestador';
       IF FOUND THEN 
            SELECT INTO respuestajson *  FROM w_retornar_orden_consumoafiliado(concat('{','"codigo":', rconsumo.codigo ,'}')::jsonb);
       ELSE 
            SELECT INTO respuestajson *  FROM w_generar_orden_consumoafiliado(parametro);
			SELECT INTO jsonparamnotif parametro || respuestajson AS parametro;
                        --SL 11/04/24 - Agrego notificacion via APP cuando se realiza un consumo
			PERFORM w_app_enviarnotifconsumo(jsonparamnotif);
       END IF;
       
  return respuestajson;

end;$function$
