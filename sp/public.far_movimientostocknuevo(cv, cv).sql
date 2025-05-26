CREATE OR REPLACE FUNCTION public.far_movimientostocknuevo(character varying, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
    cmovimiento refcursor;
    unmovimiento record;
BEGIN
-- $1 contiene el nombre de la tabla en la que se encuentra el comprobante
-- $2 se encuentra el id del comprobante donde el caracter |
      -- delimita los valores de los campos claves en caso de ser mas de 1
      
IF NOT  iftableexists('comprobatetmp') THEN 
     CREATE TEMP TABLE comprobatetmp(nombretabla varchar ,id varchar);

ELSE

DELETE FROM comprobatetmp;

END IF;
     INSERT INTO comprobatetmp (nombretabla ,id)VALUES($1 ,$2);
     OPEN cmovimiento FOR
                  SELECT *
                  FROM far_movimientostocktmp ;

     FETCH cmovimiento into unmovimiento;
     WHILE  found LOOP
                   INSERT INTO far_movimientostock  (msdescripcion, msfecha, idmovimientostocktipo,msnombretabla,msidcomprobante)
                   VALUES(unmovimiento.msdescripcion,NOW(),unmovimiento.idmovimientostocktipo,$1,$2);
                   fetch cmovimiento into unmovimiento;
     END LOOP;
     close cmovimiento;
     return 'true';
END;
$function$
