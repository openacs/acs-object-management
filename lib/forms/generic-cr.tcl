ad_page_contract {

    Includelet to handle generic add/edit operations for a content repository
    object with item type content_item_view and revision type content_revision_view..

    Adding a new object requires "create" on [ad_conn package_id].
    Editing an existing object requires "write" on the object.
    
} "
    ${content_item_view}_id:naturalnum,optional
"

ad_form -name $content_revision_view -export {return_url} \
  -form [content::form::form_part \
            -content_item_view $content_item_view \
            -content_revision_view $content_revision_view] \
  -select_query_name select_values \
  -on_request {
    if { ![content::type::is_content_type -object_type \
             [object_view::get_element -object_view $content_revision_view -element object_type]] } {
        ad_return_complaint 1 [_ object_view_not_content_type]
        ad_script_abort
    }
    if { [info exists ${content_item_view}_id] } {
        permission::require_permission \
            -party_id [ad_conn user_id] \
            -object_id [set ${content_item_view}_id] \
            -privilege write
    } else {
        permission::require_permission \
            -party_id [ad_conn user_id] \
            -object_id [ad_conn package_id] \
            -privilege create
    }
} -new_data {
    set item_id [content::form::new \
                    -content_item_view $content_item_view \
                    -content_revision_view $content_revision_view]
} -edit_data {
    set item_id [content::form::update \
                    -content_item_view $content_item_view \
                    -content_revision_view $content_revision_view]
} -after_submit {
    if { [info exists return_url] } {
        ad_returnredirect $return_url
        ad_script_abort
    }
}
