CREATE OR REPLACE FUNCTION public.arreglar_tabla_far_afiliado()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  ccursorfar_afiliado refcursor;
  rfar_afiliado RECORD;
  elidafiliado BIGINT;
  regafiliado RECORD;

BEGIN

OPEN ccursorfar_afiliado FOR SELECT idafiliado,count(*)
                              FROM far_afiliado 
                              GROUP BY idafiliado
                              having count(*) > 1;

 FETCH ccursorfar_afiliado into rfar_afiliado;
 WHILE  found LOOP
         SELECT INTO elidafiliado nextval('far_afiliado_idafiliado_seq');
         SELECT INTO regafiliado  far_afiliado.idobrasocial, far_afiliado.tipodoc, 
             far_afiliado.nrodoc,  far_afiliado.nrocliente,far_afiliado.barra,direccion.iddireccion,              
             direccion.idcentrodireccion FROM  far_afiliado LEFT JOIN direccion USING(iddireccion) 
         WHERE idafiliado=rfar_afiliado.idafiliado LIMIT 1; 
         
         UPDATE far_afiliado SET idafiliado = elidafiliado   , idcentrodireccion=regafiliado.idcentrodireccion
         WHERE idafiliado=rfar_afiliado.idafiliado AND nrodoc= regafiliado.nrodoc AND  tipodoc= regafiliado.tipodoc
                                AND idobrasocial= regafiliado.idobrasocial; 

         UPDATE far_ordenventa SET idafiliado =elidafiliado WHERE nrocliente= regafiliado.nrocliente AND  barra= regafiliado.barra 
                AND idafiliado =rfar_afiliado.idafiliado;

     FETCH ccursorfar_afiliado into rfar_afiliado;
 END LOOP;

 CLOSE ccursorfar_afiliado;

RAISE NOTICE 'Listos los far_afiliado';

return true;
END;
$function$
