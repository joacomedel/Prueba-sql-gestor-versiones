CREATE OR REPLACE FUNCTION public.asentarconsultamanual()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

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
rordconsulta RECORD;
respuesta boolean;

BEGIN
    respuesta = false;
--  Llama a asentarOrden()
    --  crea la tabla temporal TTOrdenesGeneradas
    CREATE TEMP TABLE ttordenesgeneradas(
           nroorden   bigint,
           centro     int4
           ) WITHOUT OIDS;

	select * into respuesta
           from asentarconsultarecetario(); --guarda en ttordenesgeneradas
   open consulta;
   fetch consulta into dato;

   OPEN nuevas;
   fetch nuevas into nueva;

-- Asienta en Orden Consulta
   while found loop
         --MaLaPi 16-01-2008 Para que verifique su existencia
         SELECT INTO rordconsulta * FROM ordconsulta WHERE nroorden = nueva.nroorden AND centro = nueva.centro;
         IF FOUND THEN
            UPDATE ordconsulta SET idplancovertura = dato.idplancobertura WHERE nroorden = nueva.nroorden AND centro = nueva.centro;
         ELSE
             INSERT INTO ordconsulta (centro,nroorden,idplancovertura)
                VALUES (nueva.centro,nueva.nroorden,dato.idplancobertura);
         END IF;
          fetch nuevas into nueva;
   end loop;
   close nuevas;
   close consulta;
   respuesta = true;
   return respuesta;		
END;
$function$
