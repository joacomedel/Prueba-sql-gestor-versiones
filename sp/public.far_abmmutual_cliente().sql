CREATE OR REPLACE FUNCTION public.far_abmmutual_cliente()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE

        rmutualc RECORD;
        rmutualpa RECORD;
        elultimoestado RECORD;
--VARIABLES 
        elidmutualpadron BIGINT;

BEGIN

SELECT INTO rmutualc * FROM temp_mutualpadron;

SELECT INTO rmutualpa  * FROM mutualpadron WHERE nrodoc= rmutualc.nrodoc AND tipodoc= rmutualc.tipodoc AND idobrasocial=rmutualc.idobrasocial
                           AND idvalorescajafactura=rmutualc.idvalorescajafactura; 

IF FOUND THEN  
     UPDATE mutualpadron SET mpidafiliado = rmutualc.mpidafiliado , idobrasocial = rmutualc.idobrasocial , mpdenominacion =rmutualc.mpdenominacion
             , mpmontomaximo=rmutualc.mpmontomaximo,  idvalorescajafactura = rmutualc.idvalorescajafactura
      WHERE nrodoc= rmutualc.nrodoc AND tipodoc= rmutualc.tipodoC AND idobrasocial=rmutualc.idobrasocial AND idvalorescajafactura=rmutualc.idvalorescajafactura;
    
     SELECT INTO elultimoestado * FROM mutualpadronestado 
         WHERE idmutualpadron= rmutualc.idmutualpadron AND idcentromutualpadron=  rmutualc.idcentromutualpadron AND nullvalue(mpefechafin);
     
     IF (FOUND AND elultimoestado.idmutualpadronestadotipo<>rmutualc.idmutualpadronestadotipo) THEN 
         UPDATE mutualpadronestado SET mpefechafin=now() WHERE idmutualpadron= rmutualc.idmutualpadron AND idcentromutualpadron=  rmutualc.idcentromutualpadron;
     
        INSERT INTO mutualpadronestado (idmutualpadron,idcentromutualpadron,mpefechaini,idmutualpadronestadotipo)
        VALUES (rmutualc.idmutualpadron,rmutualc.idcentromutualpadron,now(),rmutualc.idmutualpadronestadotipo);
    ELSE 
       IF NOT FOUND THEN
        INSERT INTO mutualpadronestado (idmutualpadron,idcentromutualpadron,mpefechaini,idmutualpadronestadotipo)
        VALUES (rmutualc.idmutualpadron,rmutualc.idcentromutualpadron,now(),rmutualc.idmutualpadronestadotipo);
       END IF;
    END IF;

ELSE 
    INSERT INTO mutualpadron (nrodoc,tipodoc,mpidafiliado,idobrasocial,  mpdenominacion,mpmontomaximo, idvalorescajafactura)
      VALUES (rmutualc.nrodoc,rmutualc.tipodoc,rmutualc.mpidafiliado,rmutualc.idobrasocial,rmutualc.mpdenominacion,
         rmutualc.mpmontomaximo ,rmutualc.idvalorescajafactura);

     elidmutualpadron = currval('mutualpadron_idmutualpadron_seq'::regclass);
    
      INSERT INTO mutualpadronestado (idmutualpadron,idcentromutualpadron,mpefechaini,idmutualpadronestadotipo)
      VALUES (elidmutualpadron,centro(),now(),rmutualc.idmutualpadronestadotipo);
END IF;



 return true;

END;$function$
