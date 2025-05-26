CREATE OR REPLACE FUNCTION public.asientogenerico_regenerardesbalanceados()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
--CS 2019-02-01
-- Este SP se debe utilizar para regenerar masivamente (luego de corregir) los asientos desbalanceados o con diferencia por redondeo >1, que se registran en la tabla asientogenerico_regenerar luego de correr el SP asientogenerico_crear
DECLARE
	xidasiento bigint;
	curasiento refcursor;	
	regasiento RECORD;
BEGIN

OPEN curasiento FOR SELECT * FROM asientogenerico_regenerar;

FETCH curasiento INTO regasiento;
WHILE FOUND LOOP
	perform asientogenerico_regenerar(regasiento.idcomprobantesiges,regasiento.idasientogenericocomprobtipo);
        delete from asientogenerico_regenerar where idcomprobantesiges=regasiento.idcomprobantesiges and idasientogenericocomprobtipo=regasiento.idasientogenericocomprobtipo;
	FETCH curasiento INTO regasiento;
END LOOP;
CLOSE curasiento;

return 'true';

END;
$function$
