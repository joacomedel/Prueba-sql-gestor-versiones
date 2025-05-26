CREATE OR REPLACE FUNCTION public.far_corregircopahueafiliados_ennqn()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
       seq_far_afiliado  bigint;
	idafiliadonuevo bigint;
       indice   bigint;

       cfar_afiliado refcursor;
       rfar_afiliado record;
       
       cfar_afiliado_existentes refcursor;
       rfar__existentes record;

BEGIN
     indice = 1;
     OPEN cfar_afiliado_existentes FOR SELECT far_afiliado.*
					FROM far_afiliado
					WHERE idcentroafiliado = 14;
      FETCH cfar_afiliado_existentes into rfar__existentes;
      WHILE  found LOOP

		idafiliadonuevo = indice;
		indice = indice + 1;

              UPDATE far_afiliado SET idafiliado = idafiliadonuevo
              WHERE  far_afiliado.idafiliado = rfar__existentes.idafiliado AND idcentroafiliado = 14;

              UPDATE far_ordenventa SET idafiliado = idafiliadonuevo,idcentroafiliado = 14
              WHERE  idafiliado = rfar__existentes.idafiliado AND idcentroordenventa = 14;

              UPDATE far_ordenventaitemimportes SET oviiidafiliadocobertura = idafiliadonuevo
              WHERE  far_ordenventaitemimportes.oviiidafiliadocobertura =rfar__existentes.idafiliado 
		AND idcentroordenventaitemimporte = 14;

             FETCH cfar_afiliado_existentes into rfar__existentes;
      END LOOP;
      close cfar_afiliado_existentes;
            
return 'true';
END;
$function$
