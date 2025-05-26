CREATE OR REPLACE FUNCTION public.far_normalizartablasventas()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE


BEGIN
     UPDATE far_vencab_net
     SET   desc_sobre_total = desc_sobre_total * 0.01,
           comision_total=comision_total * 0.01,
           venta_total =venta_total * 0.01 ,
           tot_centro_costo =tot_centro_costo * 0.01
     WHERE nullvalue(vnormalizado);
     UPDATE far_vencab_net SET vnormalizado=now()
     WHERE nullvalue(vnormalizado);


     UPDATE far_venitems_net
     SET   alic_iva = alic_iva* 0.01,
           importe_iva =imp_iva* 0.01,
           venta_total_item = venta_total_item* 0.01,
           descuento =descuento* 0.01,
           precio_unitario =precio_unitario*0.01
     WHERE nullvalue(vinormalizado);
     
     UPDATE far_venitems_net SET vinormalizado=now()
     WHERE nullvalue(vinormalizado);

      UPDATE far_ventpag_net
      SET venta_total_pagos = venta_total_pagos * 0.01
      WHERE nullvalue(vipnormalizado);
        UPDATE far_ventpag_net SET vipnormalizado=now()
     WHERE nullvalue(vipnormalizado);

return 'true';
END;
$function$
