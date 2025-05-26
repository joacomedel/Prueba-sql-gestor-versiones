CREATE OR REPLACE FUNCTION public.asientogenerico_modificarasientoaporte(character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* Funcion que realiza la imputación  entre deudas y pagos
*/
DECLARE
       rdata record;
       c_aporte refcursor;
       r_aporte_asiento record;
       cant integer;
       imp_diferencia double precision;
BEGIN
         EXECUTE sys_dar_filtros($1) INTO rdata;
         cant = 0;
         -- 1 busco los asientos correspondientes a la bonificacion de los aportes
         OPEN c_aporte FOR SELECT *
                       FROM aporte
                       JOIN asientogenerico ON (idcomprobantesiges=concat(idaporte,'|',idcentroregionaluso) )
                       JOIN asientogenericoitem using(idasientogenerico,idcentroasientogenerico)
                       WHERE  --idasientogenerico=193440 and
                              agfechacontable >='2019-01-01' and  agfechacontable <='2019-10-01'

                              and idasientogenericocomprobtipo = 3
                          --    and not ( mes= 9 and ano=2019)
                              and asientogenericoitem.nrocuentac = 50842 ;
         FETCH c_aporte INTO r_aporte_asiento;
         WHILE FOUND LOOP
               imp_diferencia = (abs(r_aporte_asiento.acimonto)*1.105)-abs(r_aporte_asiento.acimonto);
               -- 1- modifico el numero de cuenta 50842 por la cuenta 50758
               UPDATE asientogenericoitem
               SET acimonto = abs(r_aporte_asiento.acimonto) + imp_diferencia , acidescripcion = 'IVA Afrontado por SOSUNC' , nrocuentac=50758
               WHERE idasientogenericoitem = r_aporte_asiento.idasientogenericoitem
                     and idcentroasientogenericoitem = r_aporte_asiento.idcentroasientogenericoitem;
               
               -- 2 Inserto un nuevo item al asiento
               insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
			   values(r_aporte_asiento.idasientogenerico,r_aporte_asiento.idcentroasientogenerico
                       ,imp_diferencia
                       ,20821,'Iva Debito','H');		
               cant = cant + 1;
               FETCH c_aporte INTO r_aporte_asiento;
        END LOOP;
        CLOSE c_aporte;
RETURN cant;
END;
$function$
