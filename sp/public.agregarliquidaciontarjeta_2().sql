CREATE OR REPLACE FUNCTION public.agregarliquidaciontarjeta_2()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$/*
*/
DECLARE
    rliq RECORD;
    idliq bigint;
    cliq CURSOR FOR
               select * from tliquidaciontarjeta;

    rusuario RECORD;
                          
BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;


     OPEN cliq;
     FETCH cliq INTO rliq;
     WHILE found LOOP
        idliq = rliq.idliquidacion;
        if (nullvalue(idliq)) then --Inserta
		begin
		insert into liquidaciontarjeta(nrocomercio,idcuentabancaria,ltfechaingreso,ltfechapago,ltobservacion,idusuario,idliquidaciontarjetacomercio,ltimporteliquidaciontarjeta)
		values (rliq.nrocomercio,rliq.idcuentabancaria,rliq.ltfechaingreso,rliq.ltfechacomprobante,rliq.ltobservacion,rusuario.idusuario,rliq.idvalorescaja,rliq.ltimporteliquidaciontarjeta);
             	idliq = currval('liquidaciontarjeta_idliquidacion_seq');
		end;
        else--Actualiza
          begin
             UPDATE liquidaciontarjeta
             SET 	nrocomercio=rliq.nrocomercio,
                        idcuentabancaria=rliq.idcuentabancaria,
			idliquidaciontarjetacomercio = rliq.idvalorescaja,
			ltfechaingreso=rliq.ltfechaingreso,
			ltfechapago=rliq.ltfechacomprobante,
			ltobservacion=rliq.ltobservacion,
                        lttotalcupones= rliq.lttotalcupones,
                        idusuario = rusuario.idusuario,
                        ltimporteliquidaciontarjeta = rliq.ltimporteliquidaciontarjeta
             WHERE idliquidaciontarjeta = idliq;
	  end;

        end if;
	FETCH cliq INTO rliq;
     END LOOP;
     CLOSE cliq;
     RETURN idliq;
END;
$function$
