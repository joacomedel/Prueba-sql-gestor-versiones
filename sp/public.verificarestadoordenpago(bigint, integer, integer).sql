CREATE OR REPLACE FUNCTION public.verificarestadoordenpago(bigint, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
    
     


--REGISTROS
	restadominuta RECORD;

--VARIABLES
	rta BOOLEAN;
BEGIN


  /* Antes de cambiar el estado de la minuta verifico SI todas sus OPC estan anuladas y que el estado de la MP sea el mandado por parametro o nulo si no me importa el estado de la minuta*/
	 SELECT INTO  restadominuta * 
--select *
		FROM ordenpagocontableordenpago NATURAL JOIN ordenpago NATURAL JOIN  cambioestadoordenpago 
		LEFT JOIN ordenpagocontableestado USING(idordenpagocontable,idcentroordenpagocontable) 
		WHERE nroordenpago =  $1 AND idcentroordenpago=$2  and nullvalue(ceopfechafin) and nullvalue(opcfechafin)
		AND (idtipoestadoordenpago<>$3 OR NULLVALUE($3)) AND idordenpagocontableestadotipo<>6;


	rta = true; 
	IF FOUND THEN 		
		rta = false;
		RAISE EXCEPTION 'La minuta o alguna de sus OPC vinculadas estan en un estado que imposibilita el proceso que desea realizar. MP % % ',$1,$2;
	END IF; 

	--MaLaPi28-02-2019 Verifico que si el estado actual de la minuta es 2 (Liquidable) no tenga OPC que la paguen por un monto superior o igual. Si es asi la vambio de estado.
	IF ($3 = 2) THEN 
		SELECT  INTO restadominuta nroordenpago,idcentroordenpago,ordenpago.importetotal,sum(ordenpagocontable.opcmontototal) as montopagado  
		FROM ordenpagocontableordenpago
		NATURAL JOIN ordenpagocontable 
		NATURAL JOIN ordenpago 
		NATURAL JOIN  cambioestadoordenpago 
		JOIN ordenpagocontableestado USING(idordenpagocontable,idcentroordenpagocontable) 
		WHERE nroordenpago =  $1 AND idcentroordenpago=$2 and nullvalue(ceopfechafin) and nullvalue(opcfechafin)
		 AND idordenpagocontableestadotipo<>6 AND idtipoestadoordenpago = 2
		GROUP BY nroordenpago,idcentroordenpago,importetotal;
		IF FOUND THEN 
			IF  round(restadominuta.importetotal::numeric, 2)  <= round(restadominuta.montopagado::numeric,2) THEN --La Minuta deberia estar liquidada (3)
				rta = false;
				--nroordenpago,idtipoestadoordenpago,motivo,idcentroordenpago
				--$1,$3,$4,$2
				perform cambiarestadoordenpago($1,$2,3,'Al verificar el estado de la minuta, cambio automatico');
			END IF;

		END IF;
	END IF;
	
return rta;
END;

$function$
