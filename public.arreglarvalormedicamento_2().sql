CREATE OR REPLACE FUNCTION public.arreglarvalormedicamento_2()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       cmedicamento refcursor;
       unmedicamento record;
BEGIN
     -- 1 - se buscan topdos los medicamentos que NO tienen un valor vigente
      OPEN cmedicamento FOR
          SELECT *
          FROM medicamento
          WHERE
                 --- mnroregistro = 47466  and
                 mnroregistro NOT IN (
                     SELECT mnroregistro
                     FROM valormedicamento
                     WHERE nullvalue(vmfechafin)
              
              );

     -- 2 se recorre cada uno de los medicamentos y se pone como vigente el ULTIMO VALOR encontrado
     FETCH cmedicamento into unmedicamento;
     WHILE FOUND LOOP
           UPDATE valormedicamento SET vmfechafin = null
           WHERE valormedicamento.mnroregistro = unmedicamento.mnroregistro
                 and idvalor IN (
                     SELECT MAX (idvalor)
                     FROM valormedicamento
                     WHERE mnroregistro = unmedicamento.mnroregistro
                     group by mnroregistro

             );

            FETCH cmedicamento into unmedicamento;
     END LOOP;
     close cmedicamento;
     return 'Listo';
END;
$function$
