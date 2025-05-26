CREATE OR REPLACE FUNCTION public.far_articulogenerarlog()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	rusuario  RECORD;
    BEGIN
	SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
	IF NOT FOUND THEN 
		rusuario.idusuario = 25;
	END IF;

	IF TG_OP = 'UPDATE' THEN 
		IF (OLD.aactivo <> NEW.aactivo) THEN
			INSERT INTO far_articulologs(idarticulo,idcentroarticulo,alactivo,alidusuario) 
			VALUES(NEW.idarticulo,NEW.idcentroarticulo,NEW.aactivo,rusuario.idusuario);
		END IF;
	ELSE
		INSERT INTO far_articulologs(idarticulo,idcentroarticulo,alactivo,alidusuario) 
		VALUES(NEW.idarticulo,NEW.idcentroarticulo,NEW.aactivo,rusuario.idusuario);
	END IF;

/*INSERT INTO cambiostemporalmalapi (
                nombre_disparador,
                tipo_disparador,
                nivel_disparador,
                comando,
                textocambio) 
        VALUES (               
                TG_NAME,
                TG_WHEN,
                TG_LEVEL,
                TG_OP,
                concat('NEW.idarticulo',NEW.idarticulo,' Nuevo ',NEW.aactivo) 
               );*/

    RETURN NEW;
    END;
    $function$
