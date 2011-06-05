<?xml version="1.0"?>

<queryset>

<fullquery name="select_values">
  <querytext>
    select *
    from ${cr_item_view}
    where ${cr_item_view}_id = [set ${cr_item_view}_id]
    union
    select *
    from ${object_view}
    where ${object_view}_id = [set ${object_view}_id]
  </querytext>
</fullquery>

</queryset>
