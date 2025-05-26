CREATE OR REPLACE FUNCTION public.sp_circuitodocumento_archivos(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare



-- RECORD 
rparam RECORD;
elem RECORD;


--VARIABLES 
exito boolean;
xidgestionarchivos bigint;

BEGIN 
    EXECUTE sys_dar_filtros($1) INTO rparam; 



    --Chequeo que no exita otro archivo con el mismo nombre 
    /*SELECT into elem * FROM gestionarchivos
    WHERE gaarchivonombre=rparam.gaarchivonombre;*/

    --IF NOT FOUND THEN 

        --INSERT INTO gestionarchivos(gaarchivonombre,gaarchivodescripcion,gaarchivo) VALUES (rparam.gaarchivonombre,rparam.gaarchivodescripcion,rparam.gaarchivo::bytea);

        --xidgestionarchivos=currval('gestionarchivos_idgestionarchivos_seq'); 


        INSERT INTO circuitodocumento_archivos (
            archivodescripcion,
            archivonombre

        )VALUES (
        rparam.gaarchivodescripcion,
        concat(md5(currval('circuitodocumento_archivos_id_seq')+1),'.',rparam.tipo)
        );



    --ELSE
     --   return false;
    --END IF;  


   return true; 
END;
$function$
