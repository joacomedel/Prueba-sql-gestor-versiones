CREATE OR REPLACE FUNCTION public.ingresarmedicamentosnonomenclados()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       losmedicamentos refcursor;
       unmedicamento record;
       elidupotenci integer;
       elidmonodro integer;
       elidmedicamento integer;
      elvalormedicamento integer;
      elvalorfarmtipounid integer;
BEGIN
       SELECT INTO elidupotenci (MAX(idupotenci)+1 ) FROM  upotenci;
       SELECT  INTO elidmonodro (MAX(idmonodroga)+1 ) FROM  monodroga;
       SELECT  INTO elidmedicamento (MAX(mnroregistro)+1 ) FROM  manextra;
       SELECT  INTO elvalormedicamento (MAX(mnroregistro)+1 ) FROM  valormedicamento;
        SELECT  INTO elvalorfarmtipounid (MAX(idfarmtipounid)+1 ) FROM  farmtipounid;
       
      
        OPEN losmedicamentos FOR SELECT  * FROM medicamentosnonomenclados WHERE not procesado;
       FETCH losmedicamentos INTO unmedicamento;
       WHILE FOUND LOOP
             
             INSERT INTO farmtipounid (idfarmtipounid, ftudescripcion) VALUES (elvalorfarmtipounid,unmedicamento.ftudescripcion);
             INSERT INTO upotenci(idupotenci,updescripcion)VALUES(elidupotenci, unmedicamento.updescripcion);
             INSERT INTO monodroga (idmonodroga,monnombre)VALUES(elidmonodro,unmedicamento.monnombre);
             INSERT INTO medicamento (mnroregistro,idlaboratorio,mtroquel,mpresentacion,mnombre,idfarmtipoventa)
 VALUES(elidmedicamento, unmedicamento.idlaboratorio,unmedicamento.mtroquel,unmedicamento.mpresentacion,unmedicamento.mnombre,unmedicamento.idfarmtipoventa);
             INSERT INTO valormedicamento (mnroregistro, vmimporte,  vmfechaini,  idvalor)VALUES
             (elidmedicamento,unmedicamento.vmimporte,now(),elvalormedicamento);
             INSERT INTO manextra(mnroregistro,idvias,idfarmtipounid,idupotenci,idformas,idmonodroga,idacciofar,idtamanos)
VALUES(elidmedicamento,unmedicamento.idvias,elvalorfarmtipounid ,elidupotenci,unmedicamento.idformas,elidmonodro,unmedicamento.idacciofar,unmedicamento.idtamanos);
             
             update medicamentosnonomenclados set procesado=true WHERE idmedicamentosnonomenclados= unmedicamento.idmedicamentosnonomenclados;
           elidupotenci = elidupotenci +1;
           elidmonodro = elidmonodro +1;
           elidmedicamento = elidmedicamento +1;
           elvalormedicamento = elvalormedicamento +1;
           elvalorfarmtipounid = elvalormedicamento +1;

        FETCH losmedicamentos INTO unmedicamento;
        END LOOP;
        CLOSE losmedicamentos;
       
return true;
END;
$function$
