CREATE OR REPLACE FUNCTION public.agregarliquidaciontarjeta()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
*/
DECLARE
    rliq RECORD;
    idliq bigint;    
    cliq CURSOR FOR
               select * from tliquidaciontarjeta;
    
BEGIN
     OPEN cliq;
     FETCH cliq INTO rliq;
     WHILE found LOOP
        idliq = rliq.idliquidacion;
        if (nullvalue(idliq)) then --Inserta
		begin
		insert into liquidaciontarjeta(idcuentabancaria,idvalorescaja,ltfechaingreso,ltfechacomprobante,ltobservacion,ltimporteliquidaciontarjeta) 
		values (rliq.idcuentabancaria,rliq.idvalorescaja,rliq.ltfechaingreso,rliq.ltfechacomprobante,rliq.ltobservacion,rliq.ltimporteliquidaciontarjeta);
             	idliq = currval('liquidaciontarjeta_idliquidacion_seq');
		end;      
        else--Actualiza
          begin
             UPDATE liquidaciontarjeta
             SET 	idcuentabancaria=rliq.idcuentabancaria,
			idvalorescaja=rliq.idvalorescaja,
			ltfechaingreso=rliq.ltfechaingreso,
			ltfechacomprobante=rliq.ltfechacomprobante,
			ltobservacion=rliq.ltobservacion,
                        lttotalcupones= rliq.lttotalcupones ,
                        ltimporteliquidaciontarjeta = rliq.ltimporteliquidaciontarjeta
             WHERE idliquidacion=idliq;
	  end;

        end if;
	FETCH cliq INTO rliq;
     END LOOP;
     CLOSE cliq;


     RETURN TRUE;
END;
$function$
