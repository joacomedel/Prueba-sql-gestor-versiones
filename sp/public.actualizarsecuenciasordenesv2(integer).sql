CREATE OR REPLACE FUNCTION public.actualizarsecuenciasordenesv2(integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Agrega Todos los datos de Convenios que se encuentren en las tablas temporales */
DECLARE
       resultado  boolean;
	idcentro integer;
	valorconsulta integer;
	valorconsulta2 integer;
	valorseq integer;
      valorseqrec bigint;
valorseqrec2 bigint;
valor bigint;
	

BEGIN

     --resultado = 'true';
      --reviso los valores orden

 select into valorconsulta max(nroreintegro) from reintegro where idcentroregional=$1;
SELECT into valor    setval('"public"."reintegro_nroreintegro_seq"',valorconsulta+1); 

select into valorconsulta max(idcomprobanteprestacion) from reintegrocomprobanteprestacion where idcentroregional=$1;
SELECT into valor    setval('reintegrocomprobanteprestacion_idcomprobanteprestacion_seq',valorconsulta+1); 



 
select into valorconsulta max(nroreintegro) from reintegroorden where idcentroregional=$1;
SELECT into valor    setval('reintegroorden_nroreintegro_seq',valorconsulta+1); 

  
select into valorconsulta max(nroreintegro) from reintegrorecetario where idcentroregional=$1;
SELECT into valor    setval('reintegrorecetario_nroreintegro_seq',valorconsulta+1); 


    
select into valorconsulta max(idcambioestado) from restados where idcentroregional=$1;
SELECT into valor    setval('restados_idcambioestado_seq',valorconsulta+1); 


select into valorconsulta max(idcambioestado) from fichamedica where idcentrofichamedica =$1;
SELECT into valor    setval('"public"."fichamedica_idfichamedica_seq"',valorconsulta+1); 

 
	
select into valorconsulta max(idfichamedicaitempendiente) from fichamedicaitempendiente where idcentrofichamedicaitempendiente=$1;
SELECT into valor    setval('fichamedicaitempendiente_idfichamedicaitempendiente_seq',valorconsulta+1); 



RETURN 'true';
END;
$function$
