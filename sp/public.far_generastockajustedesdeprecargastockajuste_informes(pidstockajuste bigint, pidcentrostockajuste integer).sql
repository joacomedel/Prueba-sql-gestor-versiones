CREATE OR REPLACE FUNCTION public.far_generastockajustedesdeprecargastockajuste_informes(pidstockajuste bigint, pidcentrostockajuste integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

    cstockajuste REFCURSOR;
    rstockajuste record;
    respuesta varchar;
    ptipoinforme varchar;
    rusuario record;
    rexiste RECORD;
    rtemp record;
    resp boolean;
    vobservacion text;
BEGIN

	SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
	IF NOT FOUND THEN 
		rusuario.idusuario = 25;
	END IF;

		
	respuesta = 'true';

        OPEN cstockajuste FOR SELECT idstockajusteitem,idcentrostockajusteitem,psaiinformado,concat(psaidescripcion,'') as saiiobservacion
				FROM far_stockajusteitem
				NATURAL JOIN (
						select psaiinformado
                                              ,idstockajuste
						,idcentrostockajuste
						,idarticulo
						,idcentroarticulo
						,psaidescripcion
						from far_precargastockajusteitem  as t
						WHERE not nullvalue(CASE WHEN psaiinformado = '' THEN null ELSE psaiinformado END)
						AND idstockajuste = pidstockajuste 
						AND idcentrostockajuste = pidcentrostockajuste
						) as precarga
						ORDER BY idstockajuste;
	FETCH cstockajuste into rstockajuste;
	WHILE  found LOOP
 --KR 26-01-18 Verifico que contenga la info. esperada ya que a veces contiene informacion no esperada y da error el proceso
		IF rstockajuste.psaiinformado ILIKE '%$%' THEN 
		 foreach ptipoinforme in array string_to_array(rstockajuste.psaiinformado,'$') loop
		 IF ptipoinforme <> '' AND not nullvalue(ptipoinforme) THEN
                            ptipoinforme = split_part(split_part(ptipoinforme,'*',2),'<',1);
			INSERT INTO far_stockajusteiteminformado(idstockajusteitem,idcentrostockajusteitem,idstockajusteiteminformetipo,saiiobservacion)
				VALUES (rstockajuste.idstockajusteitem
				,rstockajuste.idcentrostockajusteitem
				,ptipoinforme::integer
				,split_part(split_part(replace(rstockajuste.psaiinformado,'>$',''),'*',2),'<',2)
				);
                 END IF;
		--return next ptipoinforme;
		 end loop;
                END IF; 
   
		

       FETCH cstockajuste into rstockajuste;
    END LOOP;
    close cstockajuste;
   return respuesta;

END;$function$
