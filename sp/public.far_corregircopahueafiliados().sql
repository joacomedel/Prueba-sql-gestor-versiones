CREATE OR REPLACE FUNCTION public.far_corregircopahueafiliados()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
       seq_far_afiliado  bigint;
nada bigint;
       indice   bigint;

       cfar_afiliado refcursor;
       rfar_afiliado record;
       
       cfar_afiliado_existentes refcursor;
       rfar__existentes record;

BEGIN
     
     ----------- Actualizo los idafiliados que sondiferentes en public y en copahue
     --- prevalece idafiliado de public
     
     OPEN cfar_afiliado_existentes FOR SELECT  public.far_afiliado.* , copahue.far_afiliado.idafiliado as idafilcopahue
          FROM copahue.far_afiliado
          JOIN public.far_afiliado using (idobrasocial, tipodoc, nrodoc)
          WHERE copahue.far_afiliado.idafiliado <> public.far_afiliado.idafiliado;
     
      FETCH cfar_afiliado_existentes into rfar__existentes;
      WHILE  found LOOP
              UPDATE copahue.far_afiliado SET idafiliado = rfar__existentes.idafiliado
              WHERE  copahue.far_afiliado.idafiliado =rfar__existentes.idafilcopahue;

              UPDATE copahue.far_ordenventa SET idafiliado = rfar__existentes.idafiliado
              WHERE  copahue.far_ordenventa.idafiliado =rfar__existentes.idafilcopahue;

              UPDATE copahue.far_ordenventaitemimportes SET oviiidafiliadocobertura = rfar__existentes.idafiliado
              WHERE  copahue.far_ordenventaitemimportes.oviiidafiliadocobertura =rfar__existentes.idafilcopahue;

             FETCH cfar_afiliado_existentes into rfar__existentes;
      END LOOP;
      close cfar_afiliado_existentes;
       
       
     -- Obtener el valor de la secuencia de far_afiliado en public
     seq_far_afiliado = nextval('far_afiliado_idafiliado_seq');
     
     indice = seq_far_afiliado;
     /* buesco si hay afiliados de copahue que se cargaron posteriormente en nqn*/
     OPEN cfar_afiliado FOR
                            SELECT  copahue.far_afiliado.*
                            FROM copahue.far_afiliado
                            LEFT JOIN public.far_afiliado using (idobrasocial, tipodoc, nrodoc)
                            WHERE nullvalue(public.far_afiliado.nrodoc) ;

     FETCH cfar_afiliado into rfar_afiliado;
     WHILE  found LOOP

            --<inicio> recorrer cada uno de los registros anteriores
                       -- actualizar el idafiliado con el del asecuencia e incrementar
                       -- actualizar cada tabla que contiene el inicial  idafiliado y actualizarlo con el nuevo
            --<fin>
            UPDATE copahue.far_afiliado SET idafiliado = indice
            WHERE  copahue.far_afiliado.idafiliado =rfar_afiliado.idafiliado;

            UPDATE copahue.far_ordenventa SET idafiliado = indice
            WHERE  copahue.far_ordenventa.idafiliado =rfar_afiliado.idafiliado;
            
            UPDATE copahue.far_ordenventaitemimportes SET oviiidafiliadocobertura = indice
            WHERE  copahue.far_ordenventaitemimportes.oviiidafiliadocobertura =rfar_afiliado.idafiliado;

            indice = indice +1 ;
            FETCH cfar_afiliado into rfar_afiliado;
      END LOOP;

      close cfar_afiliado;
      SELECT INTO nada * FROM  setval('far_afiliado_idafiliado_seq', indice-1);
      -- actualizar el valor de la secuencia con el valor que quedo la variable contador;
      
      DELETE FROM copahue.cliente
      WHERE (copahue.cliente.nrocliente, copahue.cliente.barra) IN  (
                  SELECT nrocliente , barra
                  FROM public.cliente
      );
      
      DELETE FROM copahue.direccion
      WHERE (copahue.direccion.iddireccion,copahue.direccion.idcentrodireccion )
            IN ( SELECT iddireccion ,idcentrodireccion
                 FROM copahue.cliente
                 WHERE  (copahue.cliente.nrocliente, copahue.cliente.barra) IN  (
                        SELECT nrocliente , barra
                        FROM public.cliente
                        )
                );
      
return 'true';
END;
$function$
