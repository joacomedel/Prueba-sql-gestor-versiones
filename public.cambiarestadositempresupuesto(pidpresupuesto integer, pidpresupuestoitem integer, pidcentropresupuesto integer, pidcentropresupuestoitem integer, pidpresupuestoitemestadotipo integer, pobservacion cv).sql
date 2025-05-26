CREATE OR REPLACE FUNCTION public.cambiarestadositempresupuesto(pidpresupuesto integer, pidpresupuestoitem integer, pidcentropresupuesto integer, pidcentropresupuestoitem integer, pidpresupuestoitemestadotipo integer, pobservacion character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--REGISTRO
elresumen record;

unitemestado record;

estadositempresupuesto refcursor;
resultado boolean;
aux RECORD;
  

estadopresupuestoitem INTEGER;




BEGIN

     resultado=false;

      SELECT INTO aux * FROM presupuestoitemestado      WHERE  idpresupuestoitem=$2 and
           idcentropresupuestoitem=$4   and nullvalue(pifechahasta);

       IF  Found THEN
                UPDATE presupuestoitemestado SET pifechahasta = current_date WHERE idpresupuestoitem=$2 and
                    idcentropresupuestoitem=$4    and nullvalue(pifechahasta);
                    
                      INSERT INTO presupuestoitemestado(idpresupuestoitem,idcentropresupuestoitem,idpresupuestoitemestadotipo,pifechadesde,pieobservacion)
VALUES($2,$4,$5,current_date,$6);


    else
      INSERT INTO presupuestoitemestado(idpresupuestoitem,idcentropresupuestoitem,idpresupuestoitemestadotipo,pifechadesde,pieobservacion)
VALUES($2,$4,$5,current_date,$6);

    end if;


return true;
END;$function$
