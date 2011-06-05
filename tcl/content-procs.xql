<?xml version="1.0"?>
<queryset>

  <fullquery name="content::form::new.get_root_folder_id">
    <querytext>
      select c_root_folder_id as parent_id
      from content_item_globals
    </querytext>
  </fullquery>

  <fullquery name="content::form::new.update_item">
    <querytext>
      update cr_items
      set live_revision = :revision_id,
        latest_revision = :revision_id
      where item_id = :item_id
    </querytext>
  </fullquery>

</queryset>
