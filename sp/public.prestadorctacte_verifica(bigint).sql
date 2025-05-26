CREATE OR REPLACE FUNCTION public.prestadorctacte_verifica(bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE

        rctacteprestador  record;
        elidprestadorctacte  bigint;
        elidprestador bigint;
BEGIN
     elidprestador = $1;
     elidprestadorctacte =0;

   --RAISE NOTICE 'Hola prestadorctacte_verifica xx : %', elidprestador;

     -- verifico si exite una configuracion de ctacteprestador para el prestador recibido por parametro
     SELECT INTO elidprestadorctacte idprestadorctacte  FROM prestadorctacte WHERE idprestador = elidprestador;
     IF NOT FOUND THEN           
/*KR 20-05-21 dio error con idprestador=1211 ya que ya existia Key (idprestadorctacte)=(1211) already exists. Por eso busco el maximo y mas 1*/  
 
              select into elidprestadorctacte  FROM prestadorctacte WHERE idprestadorctacte = elidprestador;
              if found then 
                   select into elidprestadorctacte max(idprestadorctacte)  from  prestadorctacte ;
                   INSERT INTO prestadorctacte(idprestador,idprestadorctacte)VALUES(elidprestador,(elidprestadorctacte)+1);
              else 
                   INSERT INTO prestadorctacte(idprestador,idprestadorctacte)VALUES(elidprestador,elidprestador);
              end if;
             
               -- MaLaPi 07-11-2018 Desde que esta tabla es sincronizable, ya no usa nro de sucuencia para el idprestadorctacte, se usa el idprestador. Hay que arreglar los replicados de otra forma
              --elidprestadorctacte = currval('prestadorctacte_idprestadorctacte_seq');
               elidprestadorctacte = elidprestador;
     
     END IF;
    RAISE NOTICE 'Hola prestadorctacte_verifica salio';

return elidprestadorctacte;
END;
$function$
