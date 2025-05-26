CREATE OR REPLACE FUNCTION public.sys_arreglarvalormedicamento()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       cvalorregistros refcursor;
       unvalorreg record;
       cvalormedicamento refcursor;
       unvalormed record;
       unvalormedanterior record;
       primero boolean;
      
BEGIN 
     OPEN cvalorregistros FOR 	SELECT mnroregistro,count(*) FROM medicamentosys
				LEFT JOIN valormedicamento USING(mnroregistro,vmfechaini,vmimporte)
				WHERE nullvalue(idvalor) AND ikfechainformacion = '2015-11-30' --AND mnroregistro = 50959
				GROUP BY mnroregistro
				HAVING count(*) > 1
				--LIMIT 500
                                ;

     FETCH cvalorregistros into unvalorreg;
     WHILE FOUND LOOP

	     primero = true;
	     OPEN cvalormedicamento FOR
		  SELECT * FROM (
			select idvalor,mnroregistro,vmfechaini,vmfechafin,vmimporte from valormedicamento where mnroregistro = unvalorreg.mnroregistro
			UNION 
			select null as idvalor,mnroregistro,vmfechaini,null as vmfechafin,vmimporte from medicamentosys where mnroregistro = unvalorreg.mnroregistro AND ikfechainformacion = '2015-11-30'
			) as t
		ORDER BY vmfechaini;

	     FETCH cvalormedicamento into unvalormed;
	     WHILE FOUND LOOP
		IF primero THEN
			IF (unvalormed.idvalor is null) THEN
				INSERT INTO valormedicamento(mnroregistro,vmfechaini,vmfechafin,vmimporte) 
				VALUES(unvalormed.mnroregistro,unvalormed.vmfechaini,null,unvalormed.vmimporte);
				SELECT INTO unvalormedanterior idvalor,mnroregistro,vmfechaini,vmfechafin,vmimporte FROM valormedicamento
				WHERE idvalor = currval(('"public"."valormedicamento_idvalor_seq"'::text)::regclass);
			ELSE
				unvalormedanterior=unvalormed;
			END IF;
			primero = false;
		ELSE 
			IF (unvalormed.idvalor is null) THEN
				IF(unvalormed.vmimporte <> unvalormedanterior.vmimporte) THEN
					UPDATE valormedicamento SET vmfechafin = unvalormed.vmfechaini WHERE idvalor = unvalormedanterior.idvalor;
					INSERT INTO valormedicamento(mnroregistro,vmfechaini,vmfechafin,vmimporte) 
					VALUES(unvalormed.mnroregistro,unvalormed.vmfechaini,unvalormedanterior.vmfechafin,unvalormed.vmimporte);

					SELECT INTO unvalormedanterior idvalor,mnroregistro,vmfechaini,vmfechafin,vmimporte FROM valormedicamento
					WHERE idvalor = currval(('"public"."valormedicamento_idvalor_seq"'::text)::regclass);

				END IF;
			ELSE 
				unvalormedanterior=unvalormed;
			END IF;
		END IF;
	
	     FETCH cvalormedicamento into unvalormed;
	     END LOOP;
	     close cvalormedicamento;

     FETCH cvalorregistros into unvalorreg;
     END LOOP;
     close cvalorregistros;
     return 'Listo';
END;
$function$
