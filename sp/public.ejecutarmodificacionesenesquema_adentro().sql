CREATE OR REPLACE FUNCTION public.ejecutarmodificacionesenesquema_adentro()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
     resp RECORD;
     resp1 RECORD;
begin
     --SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(200,20,'NC',1,null); 
     --SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(54420,20,'FA',1,null); 
     --la siguiente linea se coloca el  2021-10-14    
     -- SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(57900,20,'FA',1,null); 
     --la siguiente linea se coloca el  2021-11-02 
     --SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(59000,20,'FA',1,null); 
     --la siguiente linea se coloca el  2021-11-09 
     --SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(60000,20,'FA',1,null); 
     --la siguiente linea se coloca el  2022-03-11
     --SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(2200,20,'NC',1,null); 
     --la siguiente linea se coloca el  2022-03-16
      --SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(2325,20,'NC',1,null); 
       --    SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(66000,20,'FA',1,null); 

      --KR la siguiente linea se coloca el  2022-07-19
      --SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(2610,20,'NC',1,null);    

      --Dani la siguiente linea se coloca el 2022-10-04
  --    SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(79860,20,'FA',1,null);    
     --Dani la siguiente linea se coloca el 2022-12-19
    --  SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(84450,20,'FA',1,null);    
  --Dani la siguiente linea se coloca el 2023-02-11
    --  SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(2800,20,'NC',1,null);    
 
 --Dani la siguiente linea se coloca el 2023-04-09
  --    SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(2900,20,'NC',1,null);    
 
   --Dani la siguiente linea se coloca el 2023-04-16
    -- SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(3000,20,'NC',1,null);    
  
    
     
 --Dani la siguiente linea se coloca el 2023-04-20
 --    SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(90280,20,'FA',1,null);   


 --Dani la siguiente linea se coloca el 2023-06-07
  --  SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(93249,20,'FA',1,null);   
 --Dani la siguiente linea se coloca el 2023-08-18
--   SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(3100,20,'NC',1,null);   
  
  --Dani la siguiente linea se coloca el 2023-08-23
 --   SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(3130,20,'NC',1,null);   
  
  --  SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(91700,20,'FA',1,null);   

    --Dani la siguiente linea se coloca el 2024-01-21

 --   SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(104300,20,'FA',1,null);
  
    --Dani la siguiente linea se coloca el 2024-01-22

  --  SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(104380,20,'FA',1,null);
     --Dani la siguiente linea se coloca el 2024-03-12

    --  SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(106100,20,'FA',1,null);
    --Dani la siguiente linea se coloca el 2024-11-28

 
--SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(3542,20,'NC',1,null);
   
     --Dani la siguiente linea se coloca el 2025-01-30

 
--SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(3590,20,'NC',1,null);
  --Dani la siguiente linea se coloca el 2025-04-01

--SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(120000,20,'FA',1,null);
     --Dani la siguiente linea se coloca el 2025-04-03
SELECT INTO resp1 * FROM sys_arreglarnumeracionfacturaventa(121400,20,'FA',1,null);

 
      

return true;
end;
$function$
