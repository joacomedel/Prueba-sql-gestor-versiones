CREATE OR REPLACE FUNCTION public.expendio_tiene_ctacte(character varying, integer)
 RETURNS SETOF datosctactemutualcliente
 LANGUAGE plpgsql
AS $function$DECLARE
   rdatosctacte datosctactemutualcliente;

--VARIABLES    
  
    tieneamuc BOOLEAN;
    elidmutualpadron BIGINT;
--REGISTROS
    lapersona RECORD;
    tienemutualp RECORD;
BEGIN
-- Verifico si tiene AMUC
SELECT INTO tieneamuc * FROM expendio_tiene_amuc($1,$2);
  IF tieneamuc THEN 
    /*me fijo si la persona existe en mutualpadron*/
      SELECT INTO tienemutualp * FROM mutualpadron WHERE nrodoc = $1 AND tipodoc=$2;
      IF NOT FOUND THEN 
     /*busco los datos del cliente para guardarlo en mutualpadron, le pongo valores por defecto, y lo dejo en estado activo*/
         SELECT INTO lapersona * FROM cliente WHERE nrocliente =$1 AND barra =$2; 
         IF FOUND THEN 
            INSERT INTO mutualpadron (nrodoc,tipodoc,mpidafiliado,idobrasocial,  mpdenominacion,
                                  mpmontomaximo, idvalorescajafactura)
            VALUES ($1,$2,$1,3,lapersona.denominacion,500 ,11);
            elidmutualpadron = currval('mutualpadron_idmutualpadron_seq'::regclass);
    
            INSERT INTO mutualpadronestado (idmutualpadron,idcentromutualpadron,mpefechaini,idmutualpadronestadotipo)
            VALUES (elidmutualpadron,centro(),now(),1);
         END IF; 
      END IF;
  END IF;

FOR rdatosctacte in SELECT idmutualpadron,idcentromutualpadron,nrodoc,tipodoc,mpmontomaximo
                    ,expendio_mutual_importe_consumido(nrodoc, tipodoc, mp.idvalorescajafactura) AS montoconsumido
                    ,mpidafiliado,	mp.idobrasocial,	idvalorescajafactura,	mpdenominacion,descripcion, 	idformapagotipos,vcdescuento
FROM mutualpadron as mp 
JOIN far_configura_reporte AS fcr ON (mp.idvalorescajafactura=fcr.idvalorcajactacte             AND mp.idobrasocial=fcr.idobrasocial) 
NATURAL JOIN  mutualpadronestado
JOIN valorescaja as vc ON mp.idvalorescajafactura = vc.idvalorescaja
WHERE nrodoc=$1 AND tipodoc=$2 AND nullvalue(mpefechafin) AND idmutualpadronestadotipo=1
UNION --Corre por cuenta y riesgo de KA 
--Dani modifica el 05/05/2020 para q en farmacia el idvalorcaja  sea  60 cuando setean CtaCteFarmacia
SELECT 0 as idmutualpadron,0 as idcentromutualpadron,nrodoc,tipodoc,500 as mpmontomaximo
                    ,expendio_mutual_importe_consumido(nrodoc, tipodoc, 60) AS montoconsumido
                    ,nrodoc as mpidafiliado,	1 as idobrasocial ,60 as idvalorescajafactura,denominacion as	mpdenominacion,'Cta. Cte. Farmacia' as descripcion, 3 as	idformapagotipos,0 as vcdescuento
FROM afilsosunc as mp
JOIN cliente as c on c.nrocliente = mp.nrodoc AND c.barra = mp.tipodoc
WHERE  nrodoc=$1 AND tipodoc=$2 AND ctacteexpendio AND idestado <> 4
UNION --Corre por cuenta y riesgo de KA 
SELECT 0 as idmutualpadron,0 as idcentromutualpadron,nrodoc,tipodoc,0 as mpmontomaximo
                    ,0 AS montoconsumido
                    ,nrodoc as mpidafiliado,	1 as idobrasocial ,2 as idvalorescajafactura,denominacion as	mpdenominacion,'Es Afil. Sosunc' as descripcion, 2 as	idformapagotipos,0 as vcdescuento
FROM afilsosunc as mp
JOIN cliente as c on c.nrocliente = mp.nrodoc AND c.barra = mp.tipodoc
WHERE  nrodoc=$1 AND tipodoc=$2 AND idestado <> 4
UNION --KR 29-06-20 agrego cta cte cliente para clientes estan en la tabla clientectacte, falta definir como determinar quienes tienen dicha cta cte
select  0 as idmutualpadron,0 as idcentromutualpadron,nrocliente,barra,500 as mpmontomaximo
                    ,expendio_mutual_importe_consumido(nrocliente, barra::integer, 960) AS montoconsumido
                    ,nrocliente as mpidafiliado,	1 as idobrasocial ,960 as idvalorescajafactura,denominacion as	mpdenominacion,'Cta. Cte. Cliente' as descripcion, 3 as	idformapagotipos,0 as vcdescuento
from clientectacte NATURAL JOIN  cliente WHERE  nrocliente=$1  AND nullvalue(cccborrado)
loop
return next rdatosctacte;
end loop;


END;$function$
