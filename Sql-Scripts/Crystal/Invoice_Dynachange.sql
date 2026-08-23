SELECT dynachange.base_class 
FROM dynachange 
INNER JOIN dynachange_config 
ON dynachange_config.dynachange_id =dynachange.dynachange_id 
WHERE dynachange.base_class ='n_cst_installment_plan_invoicing' AND dynachange_config.configuration_id =4585