CREATE OR REPLACE FUNCTION public.w_determinarelegibilidadprestador(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*{""NroAfiliado":"17345841","Barra":"149","NroDocumento":"17345841","TipoDocumento":"DNI","Track":null,"ApellidoEfector":null,"NombreEfector":null,"Diagnostico":"","token":"suap1234","info_consumio_token":"suap","FechaConsumo":"2024-11-20 00:00:00","CuilEfector":"27294297230","MatriculaEfector":"6189","CategoriaEfector":"B","ApellidoPrescriptor":null,"NombrePrescriptor":null


,"CuilPrescriptor":"27294297230","MatriculaNacionalPrescriptor":null,"MatriculaProvincialPrescriptor":"6189","EspecialidadPrescriptor":null,"codigo_consumo_prestador":"COPAC2155293","marcadetiempo":"2024-11-20T11:45:49-03:00","timeout":"80","contexto_atencion":"Ambulatorio","punto_atencion_id":"1004","punto_atencion":"Consultorios RC","punto_atencion_CUIT":"27329091134"}
*/
DECLARE
--VARIABLES 
    respuestajson jsonb;
--RECORD
      
begin


/*
CUIT: 27-23194071-0   LEIVA MABEL CECILIA
CUIT: 23-16391132-9  ZARATE ROLANDO MARTIN
Ver correo a DTIC con asunto : Fwd: EXCLUSION DR. ZARATE Y DRA LEIVA (COLEGIO MÉDICO DE NEUQUÉN)
*/
     
       IF (parametro->>'CuilPrescriptor'='23163911329' OR parametro->>'CuilPrescriptor'='27231940710'  )  THEN 
		RAISE EXCEPTION 'P-001, no es un prescriptor habilitado (w_determinarelegibilidadprestador)  %',parametro;
	END IF;

      return parametro;

end;$function$
