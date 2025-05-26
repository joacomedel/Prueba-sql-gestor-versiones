CREATE OR REPLACE FUNCTION public.duplicarvaloresfijosasociacion()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$declare
     aux record;
BEGIN
-- --89 -->NqN | 95 --> RN y NQN | 92 --> RN
ALTER SEQUENCE temppractconvval_id_seq RESTART WITH 1;

delete from temppractconvval;

INSERT INTO temppractconvval (idpractconvval, idasocconv,idsubcapitulo,idcapitulo,idpractica,idnomenclador,idtvh1,fijoh1,h1,idtvh2,fijoh2,h2,idtvh3,fijoh3,h3,idtvgs,fijogs,gasto,internacion
) (

SELECT  nextval('temppractconvval_id_seq') as idpractconvval,92 as idasocconv,idsubcapitulo,idcapitulo,idpractica,idnomenclador,idtvh1,fijoh1,h1,idtvh2,fijoh2,h2,idtvh3,fijoh3,h3,idtvgs,fijogs,gasto,internacion
 FROM practconvval where practconvval.idasocconv = 89
                                    AND practconvval.idnomenclador = '14'
                                    AND practconvval.tvvigente
                                    AND ((practconvval.fijoh1 AND practconvval.h1 <> 0) 
                                      OR (practconvval.fijoh2  AND practconvval.h2 <> 0 ) 
                                      OR (practconvval.fijoh3 AND practconvval.h3 <> 0)
                                      OR practconvval.fijogs AND practconvval.gasto <> 0)
);

SELECT INTO aux * FROM ampractconvval();

delete from temppractconvval where nullvalue(error);


return nextval('temppractconvval_id_seq');
END;
$function$
