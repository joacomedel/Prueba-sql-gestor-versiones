CREATE OR REPLACE FUNCTION public.cambiarestadoconfechafinos(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Verifica que el estado se corresponda con el que deberia tener segun su fechafinos, en caso de no se
un esdo valido, se actualiza al estado valido.
Se recibe como parámetro las condiciones que debe cumplir las personas que seran analizados sus estados
Por ejemplo
      SELECT * FROM cambiarestadoconfechafinos('nrodoc=''28272137'' or nrodoc=''27091730''');

*/
DECLARE
    
    unapersona RECORD;
    --persona.nrodoc = '01468738' AND persona.tipodoc = 1;
    -- persona.barra=32;
    --> 29 and persona.barra < 100;
    
 
    fechain date;
BEGIN
set search_path=public;

raise notice 'Parametro % ----- % ',  $1, CURRENT_TIMESTAMP;
 for unapersona IN EXECUTE concat( 'SELECT  * FROM public.persona WHERE ' , $1) LOOP
          if(unapersona.barra >=130) THEN
                       UPDATE persona SET fechafinos = fechavtoreci
                       FROM afilreci
                        WHERE persona.nrodoc= unapersona.nrodoc AND persona.tipodoc = unapersona.tipodoc
                        AND afilreci.nrodoc = persona.nrodoc AND afilreci.tipodoc = persona.tipodoc;
          ELSE
                raise notice 'cambiarestadotitularv2 %,% ----- % ',  unapersona.nrodoc,unapersona.tipodoc, CURRENT_TIMESTAMP;
                SELECT INTO fechain * FROM cambiarestadotitularv2(unapersona.nrodoc,unapersona.tipodoc,CURRENT_DATE-30);
                IF NOT nullvalue(fechain) THEN
                        UPDATE persona SET fechafinos =fechain
                        WHERE nrodoc= unapersona.nrodoc AND tipodoc = unapersona.tipodoc;
                END IF;
          END IF;

      END LOOP;

   return 'true';
set search_path=ca,public;
end;
$function$
