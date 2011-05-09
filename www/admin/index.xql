<?xml version="1.0"?>

<queryset>

<fullquery name="select_object_types">
  <querytext>

    select object_type, pretty_name, dynamic_p
    from acs_object_types
    $orderby_clause

  </querytext>
</fullquery>

</queryset>
