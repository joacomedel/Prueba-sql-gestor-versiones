CREATE OR REPLACE FUNCTION public.far_stockresetear(integer, character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

    elcentro  ALIAS FOR $1;
    elmotivo  ALIAS FOR $2;
    respuesta varchar;
    rusuario record;
    infousuario RECORD;
    cantidad INTEGER;
BEGIN

	SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
	IF NOT FOUND THEN 
		rusuario.idusuario = 25;
	END IF;

        SELECT INTO infousuario * FROM usuario where idusuario = rusuario.idusuario;
       
       respuesta = 'No hace falta Generar Comprobante!';

	IF iftableexistsparasp('temp_stockfarmacia') THEN
		DELETE FROM temp_stockfarmacia;
	ELSE
		CREATE TEMP TABLE temp_stockfarmacia (
			idarticulo bigint,
			idcentroarticulo integer,
			descripcionstockajuste character varying(100),
			acodigobarra character varying,
			cantidadajustada integer,
			operacion varchar,
                        cantidadvista integer,
                        idsigno integer			
		)WITH OIDS;

	END IF;
	
	INSERT INTO temp_stockfarmacia(idarticulo,idcentroarticulo,descripcionstockajuste,acodigobarra,cantidadajustada,idsigno) 
	(
		select fa.idarticulo,fa.idcentroarticulo,concat('Reseteo de Stock ' , infousuario.nombre , ' ' , infousuario.apellido  , ' \n. ' , elmotivo) as descripcionstockajuste,fa.acodigobarra,abs(CASE WHEN nullvalue(fl.idlote) THEN 0 ELSE  fl.lstock END) as cantidadajustada,CASE WHEN (CASE WHEN nullvalue(fl.idlote) THEN 0 ELSE  fl.lstock END) > 0 THEN -1 ELSE 1 END as idsigno 
		from far_articulo as fa
	        JOIN far_lote as fl on  fl.idcentrolote = elcentro
		AND fa.idarticulo = fl.idarticulo 
		AND fa.idcentroarticulo = fl.idcentroarticulo
		where not  nullvalue(fl.idlote)
                AND fl.lstock <> 0
	);
       SELECT INTO cantidad count(*) FROM temp_stockfarmacia;
      IF(cantidad > 0) THEN
		SELECT INTO respuesta * FROM far_stockajustedesdetemporal();
       END IF;

return respuesta;

END;
$function$
