ad_page_contract {

    Includelet to handle generic add/edit operations for a non-content repository
    object object_view.

    Adding a new object requires "create" on [ad_conn package_id].
    Editing an existing object requires "write" on the object.
    
} "
    ${object_view}_id:naturalnum,optional
"

ad_form -name $object_view -export {return_url} \
  -form [object::form::form_part -object_view $object_view] \
  -select_query_name select_values \
  -on_request {
    if { [content::type::is_content_type -object_type \
             [object_view::get_element -object_view $object_view -element object_type]] } {
        ad_return_complaint 1 [_ object_view_content_type]
        ad_script_abort
    }
    if { [info exists ${object_view}_id] } {
        permission::require_permission \
            -party_id [ad_conn user_id] \
            -object_id [set ${object_view}_id] \
            -privilege write
    } else {
        permission::require_permission \
            -party_id [ad_conn user_id] \
            -object_id [ad_conn package_id] \
            -privilege create
    }
} -new_data {
    object::form::new -object_view $object_view 
} -edit_data {
    object::form::update -object_view $object_view
} -after_submit {
    if { [info exists return_url] } {
        ad_returnredirect $return_url
        ad_script_abort
    }
}
