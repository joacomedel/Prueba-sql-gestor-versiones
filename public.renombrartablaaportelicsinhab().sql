CREATE OR REPLACE FUNCTION public.renombrartablaaportelicsinhab()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
   res boolean;


BEGIN

	SELECT into res *  from eliminartablasincronizable('aportelicsinhab');
        ALTER TABLE aportelicsinhab RENAME TO aporteuniversidad;
        SELECT into res * FROM agregarsincronizable('aporteuniversidad');
   
return res;
END;
$function$
