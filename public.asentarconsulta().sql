CREATE OR REPLACE FUNCTION public.asentarconsulta()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

consulta CURSOR FOR
                select *
                       from ttconsulta;
/*
idplancobertura
*/
nuevas CURSOR FOR
                 SELECT *
                        from ttordenesgeneradas;
nueva RECORD;

dato record;
respuesta boolean;

BEGIN
    respuesta = false;
--  Llama a asentarOrden()
    --  crea la tabla temporal TTOrdenesGeneradas
   
      IF NOT  iftableexistsparasp('ttordenesgeneradas') THEN 
              CREATE TEMP TABLE ttordenesgeneradas(
           nroorden   bigint,
           centro     int4
           ) WITHOUT OIDS;

        ELSE  DELETE FROM ttordenesgeneradas;
        END IF;

	select * into respuesta
           from asentarorden(); --guarda en ttordenesgeneradas
   open consulta;
   fetch consulta into dato;

   OPEN nuevas;
   fetch nuevas into nueva;

-- Asienta en Orden Consulta
   while found loop
         INSERT INTO ordconsulta(centro,nroorden,idplancovertura)
                VALUES (nueva.centro,nueva.nroorden,dato.idplancobertura);
          fetch nuevas into nueva;
   end loop;
   close nuevas;
   close consulta;
   respuesta = true;
   return respuesta;		
END;
$function$
