CREATE OR REPLACE FUNCTION public.planes_tarjeta_sp(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/****/
DECLARE

    rparam RECORD;
    respuesta character varying; 

    rplan_tarjeta record;
    vaccion character varying;

	cplanes_nuevos CURSOR FOR SELECT * FROM tempplantarjeta;
	cplanes CURSOR FOR SELECT * FROM tempplantarjetavigente;
BEGIN
    respuesta = '';

    --EXECUTE sys_dar_filtros($1) INTO rparam;
    --vaccion = rparam.accion;
    
    DELETE FROM planes_tarjeta WHERE ptfechadesde > TO_DATE(to_char(now(),'YYYY-MM-DD'),'YYYY-MM-DD');

    -- Cargo nueva lista

  	open cplanes_nuevos;
    FETCH cplanes_nuevos into rplan_tarjeta;
    WHILE FOUND LOOP
            INSERT INTO planes_tarjeta ( ptcuotas, ptfactorfinanciero, ptarancel,ptposnet, ptfechadesde, ptfechahasta,ptidusuario,ptidrubro,idvalorescaja,ptidusuarioultmodif,ptfechamodif)
            VALUES (rplan_tarjeta.ptcuotas, 
                    rplan_tarjeta.ptfactorfinanciero,
                    rplan_tarjeta.ptarancel,
                    rplan_tarjeta.ptposnet,
                    rplan_tarjeta.ptfechadesde,
                    rplan_tarjeta.ptfechahasta,
                    rplan_tarjeta.ptidusuario,
                    5,
                    rplan_tarjeta.idvalorescaja,
                    rplan_tarjeta.ptidusuario,
                    now());        
            FETCH cplanes_nuevos into rplan_tarjeta;
    END LOOP;
    CLOSE cplanes_nuevos;


	open cplanes;
    FETCH cplanes into rplan_tarjeta;
    WHILE FOUND LOOP
            UPDATE planes_tarjeta 
            SET ptfechahasta = rplan_tarjeta.ptfechahasta
                ,  ptidusuarioultmodif=rplan_tarjeta.ptidusuario
                , ptfechamodif=now()
            WHERE idplantarjeta=rplan_tarjeta.idplantarjeta;
            FETCH cplanes into rplan_tarjeta;
	END LOOP;
	CLOSE cplanes;


     respuesta = 'todook';
      
    
return respuesta;
END;
$function$
