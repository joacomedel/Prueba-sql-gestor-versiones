CREATE OR REPLACE FUNCTION public.sys_dar_filtros(filtros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE 
        arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
        vfiltrovalor varchar;
        vfiltrocampo varchar;
BEGIN

IF /*nullvalue*/(filtros)is null  OR filtros = '' THEN 

ELSE 
	--'{caminoFotito=http://192.9.200.209/reportes/imagenes/fotito.jpg, ctfehcingreso=2017-01-01, idturismoadmin=5, ctfechasalida=2018-04-12, tipoemision=O}'
	select INTO arr string_to_array(replace(replace(filtros,'{',''),'}',''),',');
	array_len := array_upper(arr, 1);
	  FOR i IN 1 .. array_len LOOP
		IF (isnumeric(split_part(trim(arr[i]),'=', 2))  -- es un numero
                    AND 
                        (left(split_part(trim(arr[i]),'=', 2),1)<>0 OR  -- VAS 18/09/24 es un numero y no comienza con 0
                           ( split_part(trim(arr[i]),'=', 2)>= 0 AND  split_part(trim(arr[i]),'=', 2)<1) --  VAS 18/09/24 es 0
                             
                        )
                 )THEN  
			vfiltrovalor = concat('',split_part(trim(arr[i]),'=', 2),'');
			vfiltrocampo = split_part(trim(arr[i]),'=', 1);
			IF (vfiltrocampo ILIKE '%nrodoc%') THEN -- Es el nro de documento, debe ser varchar
			   vfiltrovalor = concat('''',split_part(trim(arr[i]),'=', 2),'''::varchar');
			END IF;
			
		ELSE ---  VAS 18/09/24 puede ser un '070942501255'
		    IF (isnumeric(split_part(trim(arr[i]),'=', 2)) AND left(split_part(trim(arr[i]),'=', 2),1)= 0  )THEN   --- es numero pero comienza con 0 lo trato como string
		           vfiltrovalor = concat('''',trim(replace(split_part(trim(arr[i]),'=', 2),'^','')),'''::varchar');
		ELSE 
				IF isdate(split_part(trim(arr[i]),'=', 2)) AND strpos(split_part(trim(arr[i]),'=', 2),'@') = 0  THEN --MaLaPi 20-10-2022 Agrego esto porque con 120 @ 143 me da que es una fecha
					vfiltrovalor = concat('''',split_part(trim(arr[i]),'=', 2),'''::date');
				ELSE
					IF split_part(trim(arr[i]),'=', 2)='null' THEN
				    	 vfiltrovalor = concat('''','','''::varchar');
					ELSE
				     	IF split_part(trim(arr[i]),'=', 2)='true' OR split_part(trim(arr[i]),'=', 2)='false' THEN
							vfiltrovalor = concat('',split_part(trim(arr[i]),'=', 2),'');
				     	ELSE
							vfiltrovalor = concat('''',trim(replace(split_part(trim(arr[i]),'=', 2),'^','')),'''::varchar');
				     	END IF;
					END IF;
				END IF;
			 END IF;
		END IF;
		
		--RAISE NOTICE 'another_func(%)',isnumeric(split_part(trim(arr[i]),'=', 2));
		vfiltrocampo = split_part(trim(arr[i]),'=', 1);
		vquery = concat(vquery,vfiltrovalor,' as ',vfiltrocampo,',');
		
	   END LOOP;
END IF;
	vquery = replace(vquery,'''''::varchar','null::text');
        vquery = concat('SELECT ',vquery,' true as nada');
	--- VAS 030223 RAISE NOTICE 'another_func(%)',vquery;
         
RETURN vquery;
END;$function$
