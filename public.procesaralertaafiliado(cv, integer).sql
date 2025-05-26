CREATE OR REPLACE FUNCTION public.procesaralertaafiliado(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--RECORDS
	elem record;
        rafiliado record;
        talerta text;
        rusuario record;
BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
   rusuario.idconexion = current_timestamp;
END IF;
     
	IF iftableexistsparasp('info_generaluno') THEN --Se esta usando la nueva funcionalidad de traer grupo familiar
		SELECT INTO elem text_concatenar(concat('<li>',iatexto,' de ',login,'</li>')) as iatexto
		  FROM ( --07-11-2017 MaLapi Modifico para que solo se muestren las alertas configuradas para una transaccion en particular
			SELECT infoafiliado.*
			FROM infoafiliado
			NATURAL JOIN infoafiliado_dondemostra
			NATURAL JOIN infoafiliado_quienmuestra
			JOIN (SELECT referencia,idconexion FROM log_tconexiones WHERE not nullvalue(referencia) AND idconexion =rusuario.idconexion) as conexion 
			ON trim(referencia) ilike concat('%',trim(split_part(iaqmmetodo,'()',1)),'%')  
			WHERE  (nullvalue(iafechafin) OR iafechafin > now()) AND (iafechaini<=current_date) 
			) as ia
                  JOIN info_generaluno ON ((nrodociniciaproceso = ia.nrodoc AND tipodociniciaproceso = ia.tipodoc) OR ia.nrodoc = nrodoctitular AND ia.tipodoc = tipodoctitular AND iagrupofamiliar)
		  LEFT JOIN usuario ON iaidusuario = idusuario
		  WHERE (nullvalue(iafechafin) OR iafechafin > now()) AND (iafechaini<=current_date) ;
		  --GROUP BY ia.nrodoc,ia.tipodoc;
		IF FOUND AND not nullvalue(elem.iatexto) THEN 
		   talerta = concat('<html><ul>',elem.iatexto,'</ul></html>');
		   UPDATE info_generaluno SET textoalerta = talerta;
		END IF;
		
	ELSE  -- Se carga el grupo familiar de otra forma.

	       SELECT INTO elem text_concatenar(concat('<li>',iatexto,' de ',login,'</li>')) as iatexto
		  FROM ( --07-11-2017 MaLapi Modifico para que solo se muestren las alertas configuradas para una transaccion en particular
			SELECT infoafiliado.*
			FROM infoafiliado
			NATURAL JOIN infoafiliado_dondemostra
			NATURAL JOIN infoafiliado_quienmuestra
			JOIN (SELECT referencia,idconexion FROM log_tconexiones WHERE not nullvalue(referencia) AND idconexion =rusuario.idconexion) as conexion 
			ON trim(referencia) ilike concat('%',trim(split_part(iaqmmetodo,'()',1)),'%')  
			WHERE  (nullvalue(iafechafin) OR iafechafin > now()) and (iafechaini<=current_date)

		  ) as ia
		  LEFT JOIN usuario ON iaidusuario = idusuario
		  WHERE ia.nrodoc = $1 
		     AND ia.tipodoc = $2 AND (nullvalue(iafechafin) OR iafechafin > now()) AND (iafechaini<=current_date)

		  GROUP BY ia.nrodoc,ia.tipodoc;
	     IF FOUND AND not nullvalue(elem.iatexto) THEN 
		   talerta = concat('<html><ul>',elem.iatexto,'</ul></html>');
		 IF EXISTS ( select * from information_schema.columns
		    where table_name='afiliado'  ) THEN
			IF NOT existecolumtemp('afiliado','textoalerta') THEN
			   ALTER TABLE afiliado ADD COLUMN textoalerta  VARCHAR;
			END IF;
			UPDATE afiliado SET textoalerta = talerta WHERE nrodoc = $1 AND tipodoc = $2;
		 ELSE
		       CREATE TEMP TABLE afiliado ( nrodoc varchar, tipodoc int, textoalerta  VARCHAR) WITHOUT OIDS;
		       INSERT INTO afiliado (nrodoc,tipodoc,textoalerta) VALUES( $1 , $2,talerta);
		END IF;
	     END IF;
	 END IF; -- FIN de Se carga el grupo familiar de otra forma.
     RETURN true;
END;
$function$
