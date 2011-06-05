ad_library {

    Supporting procs for ACS Content Repository Objects.  Unlike the object type and view
    metadata procs, these don't cache at the moment.

    @author Don Baccus (dhogaza@pacifier.com)
    @creation-date March 27, 2011
    @cvs-id $Id$

}

namespace eval content {}
namespace eval content::form {}

ad_proc content::form::form_part {
    {-content_item_view:required content_item_v}
    -content_revision_view:required
    {-extend:boolean "f"}
} {

    Returns an ad_form snippet meant to be embedded in the "-form" part of the call.

    @param content_item_view The content item view for the CR object, usually content_item.
    @param content_reviwion_view The content revision view for the CR object, usually custom.
    @param extend Extend an existing form.

} {
    set form_part [list]
    if {!$extend_p} {
        lappend form_part [list ${content_item_view}_id:key(acs_object_id_seq)]
    }
    lappend form_part [list content_item_view:text(hidden) [list value $content_item_view]]
    lappend form_part [list content_revision_view:text(hidden) [list value $content_revision_view]]
    foreach attribute_id [object_view::get_attribute_ids -object_view $content_item_view] {
        lappend form_part [form::element \
                              -object_view $content_item_view \
                              -attribute_id $attribute_id]
    }
    foreach attribute_id [object_view::get_attribute_ids -object_view $content_revision_view] {
        lappend form_part [form::element \
                              -object_view $content_revision_view \
                              -attribute_id $attribute_id]
    }
ns_log Notice "Huh? form_part: $form_part"
    return $form_part
}

ad_proc content::form::new {
    -content_item_view:required
    -content_revision_view:required
    -item_id
    -parent_id
    -form
} {
} {

    if { ![info exists form] } {
        set form $content_revision_view
    }

    if { ![info exists item_id] } {
        set item_id [template::element::get_value $form \
                          [template::element::get_value $form __key]]
    }

    if { ![info exists parent_id] } {
        db_1row get_root_folder_id {}
    }

    set content_item_type [object_view::get_element \
                        -object_view $content_item_view \
                        -element object_type]

    set attributes(creation_user) [ad_conn user_id]
    set attributes(creation_ip) [ad_conn peeraddr]
    set attributes(object_type) $content_item_type

    form::get_attributes \
        -object_view $content_item_view \
        -array attributes \
        -form $content_revision_view

    db_transaction {
        object::new_inner \
            -object_type $content_item_type \
            -object_id $item_id \
            -parent_id $parent_id \
            -attributes [array get attributes]
    }

    array unset attributes

    set content_revision_type [object_view::get_element \
                        -object_view $content_revision_view \
                        -element object_type]

    set attributes(creation_user) [ad_conn user_id]
    set attributes(creation_ip) [ad_conn peeraddr]
    set attributes(object_type) $content_revision_type
    set attributes(item_id) $item_id

    form::get_attributes \
        -object_view $content_revision_view \
        -array attributes \
        -form $content_revision_view

    db_transaction {
        set revision_id [object::new_inner \
                            -object_type $content_revision_type \
                            -object_id "" \
                            -item_id $item_id \
                            -attributes [array get attributes]]
    }

    db_dml update_item {}

    return $item_id
}

ad_proc content::form::update {
    -content_item_view:required
    -content_revision_view:required
    -item_id
    -form
} {
} {
# not done!
    if { ![info exists form] } {
        set form $object_view
    }

    if { ![info exists object_id] } {
        set object_id [template::element::get_value $form \
                          [template::element::get_value $form __key]]
    }

    form::get_attributes \
        -object_view $object_view \
        -form $form \
        -array attributes

    set object_type [object_view::get_element \
                        -object_view $object_view \
                        -element object_type]

    set attributes(modifying_user) "[ad_conn user_id]"
    set attributes(modifying_ip) "[ad_conn peeraddr]"

    db_transaction {
        object::update_inner \
            -object_id $object_id \
            -object_type $object_type \
            -attributes [array get attributes]
    }
}
