CREATE OR REPLACE FUNCTION public.aportesfaltantes(character varying, integer, date)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* Recibe como parametros el tipo y numero de documento
* Retorna la cantidad la cantidad de aportes faltantes a partir de la fecha deda en caso de que los hubiera,
* caso contrario, devuelve 0.
*/
DECLARE
       pnrodoc alias for $1;
       ptipodoc alias for $2;
       pfecha alias for $3;
       datoPersona RECORD;
       aportePersona RECORD;
       caru3meses integer;
       raporte RECORD;
       indice INTEGER;
begin
caru3meses=0;
/* Busco los datos de la persona*/
   SELECT INTO datoPersona *
   FROM public.persona WHERE persona.nrodoc=pnrodoc and persona.tipodoc=ptipodoc;
   IF FOUND THEN
          /* Busco el utimo aporte recibido del afiliado */
          FOR indice IN 0..3 LOOP
            SELECT INTO raporte * FROM
            aporte JOIN cargo ON aporte.idlaboral = cargo.idcargo
            WHERE cargo.nrodoc=datoPersona.nrodoc AND cargo.tipodoc=datoPersona.tipodoc
       --    AND ano = date_part('year',(pfecha-(30 * indice))::date)  AND mes = date_part('month',(pfecha-(30 * indice))::date);
         AND ano = date_part('year',(pfecha::date)-(30 * indice))  AND mes = date_part('month',(pfecha::date)-(indice))and importe<>0;
            IF NOT FOUND THEN
               caru3meses = caru3meses + 1;
            END IF;
           END LOOP;
    END IF;
return caru3meses;

end;
$function$
