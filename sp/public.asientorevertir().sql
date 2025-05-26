CREATE OR REPLACE FUNCTION public.asientorevertir()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/****/
DECLARE
   	casientosrev CURSOR FOR SELECT *
                            FROM multivac_cont_asientos_encabezados
                            JOIN asientorevertir2 using (nroasiento)
                            WHERE --nroasiento = 242163 and
                                  not generado and
                                  idmodulo = 3 and idejercicio=11;
    rasientorev record;
    curitem refcursor;
    regitem record;
    descriptconcepto varchar;
    xidasiento bigint;

BEGIN
     OPEN casientosrev;
     FETCH casientosrev INTO rasientorev;
     WHILE found LOOP
                    -- 1 Busco las cuentas afectadas por el asiento y sus respectivos importes
                   OPEN curitem for SELECT
                           nrocuentac,descripcionsiges,d_h as real,
                           monto as nuevomonto ,
                           CASE WHEN d_h='D' THEN 'H' ELSE 'D' END as letra
                    FROM  multivac_cont_asientos_renglones as r
                    JOIN  multivac.mapeocuentascontables  as c ON (c.idcuentacontablemultivac = r.idcuenta)
                    WHERE r.idasiento = rasientorev.idasiento;

                    descriptconcepto = concatenar (concatenar(concatenar('REV.DUP AS:',rasientorev.nroasiento::varchar), ': ' ) , rasientorev.concepto::varchar);

                    -- 2  Creo el asiento generico
                     INSERT INTO asientogenerico(idasientogenericotipo,idasientogenericocomprobtipo,agfechacontable,agdescripcion,idcomprobantesiges,agtipoasiento,idagquienmigra)
			        VALUES (6,6,rasientorev.fechacontable,descriptconcepto,'0|0','AS',3);
			
			        xidasiento=currval('asientogenerico_idasientocontable_seq');
                   	FETCH curitem INTO regitem;
                   	WHILE found LOOP
                           -- 3 Ingreso los items
                          INSERT INTO  asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                           VALUES (xidasiento,centro(),abs(regitem.nuevomonto),regitem.nrocuentac,descriptconcepto,regitem.letra);

                    FETCH curitem INTO regitem;
			        END LOOP;
			        CLOSE curitem;
	 perform	cambiarestadoasientogenerico(xidasiento,centro(),1);
	 UPDATE asientorevertir2 SET generado =true , idasientogenerico =xidasiento   WHERE asientorevertir = rasientorev.asientorevertir;
	 
     FETCH casientosrev INTO rasientorev;
     END LOOP;
     CLOSE casientosrev;
     RETURN true;

END;
$function$
