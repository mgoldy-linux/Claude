SELECT
   ship_to.ship_to_id,
   address.name,
   ship_to.invoice_type,
   ship_to.pick_ticket_type,
   ship_to.company_id,
   ship_to.delete_flag,
   ship_to.include_non_alloc_on_pick_tix,
   ship_to.exclude_canceld_from_pick_tix,
   ship_to.include_non_alloc_on_pack_list,
   ship_to.exclude_canceld_from_pack_list,
   ship_to.print_packinglist_in_shipping,
   ship_to.print_prices_on_packinglist,
   crm_contact_information.last_hard_touch_date,
   crm_contact_information.activity_trans_no,
   ship_to.customer_id
FROM
   ship_to
   INNER JOIN customer ON (ship_to.company_id = customer.company_id)
   and (ship_to.customer_id = customer.customer_id)
   INNER JOIN address ON (ship_to.ship_to_id = address.id)
   LEFT JOIN crm_contact_information ON (
      crm_contact_information.company_id = ship_to.company_id
      AND crm_contact_information.entity_link_id_dec = ship_to.ship_to_id
      AND crm_contact_information.entity_type_cd = 1417
   )
WHERE
   (customer.company_id = 1)
   AND (customer.customer_id = 13107)
   AND (ship_to.delete_flag = 'N')
ORDER BY
   address.name ASC