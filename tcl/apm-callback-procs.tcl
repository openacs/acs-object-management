
ad_library {
    APM callback procedures.
    
    @creation-date 2011-03-27
    @author Don Baccus (dhogaza@pacifier.com)
    @cvs-id $Id$
}

namespace eval acs_object_management::apm {}

ad_proc -public acs_object_management::apm::after_install {} {
    After install callback.  Create acs_object_management views.
} {

    source [acs_package_root_dir acs-object-management]/tcl/cache-init.tcl

    object_view::new -object_view object -pretty_name Object -object_type acs_object

    db_1row q {select attribute_id
               from acs_attributes
               where object_type = 'acs_object'
                 and attribute_name = 'title'}
    object_view::attribute::copy -to_object_view object -attribute_id $attribute_id
    object_view::attribute::widget::register \
        -object_view object \
        -attribute_id $attribute_id \
        -widget text \
        -required_p t \
        -help_text ""

    object_view::new -object_view item -pretty_name Item -object_type content_item

    db_1row q {select attribute_id
               from acs_attributes
               where object_type = 'content_item'
                 and attribute_name = 'name'}
    object_view::attribute::copy -to_object_view item -attribute_id $attribute_id
    object_view::attribute::widget::register \
        -object_view item \
        -attribute_id $attribute_id \
        -widget text \
        -required_p t \
        -help_text ""

    object_view::new -object_view revision -pretty_name Revision -object_type content_revision

    db_1row q {select attribute_id
               from acs_attributes
               where object_type = 'content_revision'
                 and attribute_name = 'title'}
    object_view::attribute::copy -to_object_view revision -attribute_id $attribute_id
    object_view::attribute::widget::register \
        -object_view revision \
        -attribute_id $attribute_id \
        -widget text \
        -required_p t \
        -help_text ""

    db_1row q {select attribute_id
               from acs_attributes
               where object_type = 'content_revision'
                 and attribute_name = 'description'}
    object_view::attribute::copy -to_object_view revision -attribute_id $attribute_id
    object_view::attribute::widget::register \
        -object_view revision \
        -attribute_id $attribute_id \
        -widget text \
        -required_p f \
        -help_text ""

    db_1row q {select attribute_id
               from acs_attributes
               where object_type = 'content_revision'
                 and attribute_name = 'content'}
    object_view::attribute::copy -to_object_view revision -attribute_id $attribute_id
    object_view::attribute::widget::register \
        -object_view revision \
        -attribute_id $attribute_id \
        -widget richtext \
        -required_p t \
        -help_text ""

}
