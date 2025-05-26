CREATE OR REPLACE FUNCTION public.w_consumoafiliado_guardarinfoextra(pentrada jsonb, psalida jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*

*/
DECLARE
--VARIABLES 

--RECORD
      respuestajson jsonb;
      rrespuesta  RECORD;
      rverifica RECORD;
begin
      
       IF nullvalue(psalida->>'resultado') THEN 
		IF  nullvalue(psalida->>'nroorden') OR nullvalue(psalida->>'centro') THEN
                    RAISE EXCEPTION 'R-001, El nroorden y centro deben estar completos.  %',psalida; 
                END IF;
	ELSE
		SELECT INTO psalida jsonb_array_elements_text(((psalida)->>'resultado')::jsonb);
       END IF;
	IF  nullvalue(psalida->>'nroorden') OR nullvalue(psalida->>'centro') THEN
		--No se puede hacer nada, pues no me envian el nro de orden, por las dudas no envio un error, lo dejo pasar.
		respuestajson = psalida;
	ELSE 
        --Verifico si ya exsite la informacion, solo la completo
        SELECT INTO rverifica * FROM ordenonlineinfoextra WHERE nroorden = psalida->>'nroorden' AND centro = psalida->>'centro';
        IF FOUND THEN 
		UPDATE ordenonlineinfoextra SET 
		ooliecontexto = trim(pentrada->>'contexto_atencion')
		,categoriaefector = trim(pentrada->>'CategoriaEfector')
		,apellidoefector = pentrada->>'ApellidoEfector'
		,nombreefector = pentrada->>'NombreEfector'
		,cuilefector = pentrada->>'CuilEfector'
	       ,diagnostico = pentrada->>'Diagnostico'
	       ,matriculaefector = pentrada->>'MatriculaEfector'
	       ,ooienombreprescriptor = pentrada->>'NombrePrescriptor'
	       ,ooieapellidoprescriptor = pentrada->>'ApellidoPrescriptor'
	       ,ooiecuil = pentrada->>'CuilEfector'
	       ,ooiecuilprescriptor = pentrada->>'CuilPrescriptor'
	       ,ooiematprovincialprescriptor = trim(pentrada->>'MatriculaProvincialPrescriptor') 
	       ,ooiematnacionalprescriptor = trim(pentrada->>'MatriculaNacionalPrescriptor')
	       ,ooieespecialidadprescriptor = pentrada->>'EspecialidadPrescriptor'
	       ,ooiecodigoprestador = pentrada->>'codigo_consumo_prestador'
	       ,ooiecontextoatencion = pentrada->>'contexto_atencion'
	       ,ooiepuntoatencionid = pentrada->>'punto_atencion_id'
	       ,ooiepuntoatencion = pentrada->>'punto_atencion'
	       ,ooiepuntoatencioncuit = pentrada->>'punto_atencion_CUIT'
		WHERE nroorden = trim(psalida->>'nroorden')::bigint AND centro = trim(psalida->>'centro')::integer;
		
        ELSE
	INSERT INTO ordenonlineinfoextra(nroorden, centro, ooliecontexto, categoriaefector, apellidoefector, nombreefector, cuilefector
	, diagnostico, matriculaefector, ooienombreprescriptor, ooieapellidoprescriptor, ooiecuil, ooiecuilprescriptor, ooiematprovincialprescriptor
	, ooiematnacionalprescriptor, ooieespecialidadprescriptor, ooiecodigoprestador, ooiecontextoatencion, ooiepuntoatencionid, ooiepuntoatencion
	, ooiepuntoatencioncuit) 
	VALUES(trim(psalida->>'nroorden')::bigint,trim(psalida->>'centro')::integer,trim(pentrada->>'contexto_atencion'),trim(pentrada->>'CategoriaEfector'),pentrada->>'ApellidoEfector',pentrada->>'NombreEfector',pentrada->>'CuilEfector'
	       ,pentrada->>'Diagnostico',pentrada->>'MatriculaEfector',pentrada->>'NombrePrescriptor',pentrada->>'ApellidoPrescriptor',pentrada->>'CuilEfector',pentrada->>'CuilPrescriptor',trim(pentrada->>'MatriculaProvincialPrescriptor')
	       ,trim(pentrada->>'MatriculaNacionalPrescriptor'),pentrada->>'EspecialidadPrescriptor',pentrada->>'codigo_consumo_prestador',pentrada->>'contexto_atencion',pentrada->>'punto_atencion_id',pentrada->>'punto_atencion'
	       ,pentrada->>'punto_atencion_CUIT');

        END IF;
	
	SELECT INTO rrespuesta * FROM ordenonlineinfoextra WHERE nroorden = psalida->>'nroorden' AND centro = psalida->>'centro';
       respuestajson = row_to_json(rrespuesta);
       END IF;
      return respuestajson;

end;
$function$
