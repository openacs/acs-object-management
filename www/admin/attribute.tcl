ad_page_contract {

    @author Don Baccus
    @creation-date 2009-07-22
    @cvs-id $Id$

} {
    attribute_id:optional
    object_type:notnull,sql_identifier
}

object_type::get -object_type $object_type -array type_info

if {[info exists attribute_id]} {
    set page_title "[_ acs-object-management.attribute_edit]"
} else {
    set page_title "[_ acs-object-management.attribute_add]"
}

set context [list [list [export_vars -base object-type {object_type}] $type_info(pretty_name)] $page_title]
set table_name $type_info(table_name)
set datatype_options [db_list_of_lists get_datatypes {}]

ad_form -name attribute_form -export {object_type} -form {
    {attribute_id:key}
}

if {[ad_form_new_p -key attribute_id]} {
    ad_form -extend -name attribute_form -form {
      {attribute_name:text {label "[_ acs-object-management.attribute_name]"} {html {size 30 maxlength 100}} {help_text "[_ acs-object-management.attribute_name_help]"}}
    }
} else {
    ad_form -extend -name attribute_form -form {
      {attribute_name:text(inform) {label "[_ acs-object-management.attribute_name]"}}
    }
}

ad_form -extend -name attribute_form -form {
    {pretty_name:text {label "[_ acs-object-management.pretty_name]"} {html {size 30 maxlength 100}} {help_text "[_ acs-object-management.attribute_pname_help]"}}
    {pretty_plural:text,optional {label "[_ acs-object-management.pretty_plural]"} {html {size 30 maxlength 100}} {help_text "[_ acs-object-management.attribute_pplural_help]"}}
}

if {[ad_form_new_p -key attribute_id]} {
    ad_form -extend -name attribute_form -form {
	{datatype:text(select) {label "[_ acs-object-management.datatype]"} {options $datatype_options} {help_text "[_ acs-object-management.datatype_help]"}}
        {default_value:text(textarea),optional {label "[_ acs-object-management.attribute_default]"} {html {rows 3 cols 40}} {help_text "[_ acs-object-management.attribute_default_help]"}}
    }
} else {
    ad_form -extend -name attribute_form -form {
	{datatype:text(inform) {label "[_ acs-object-management.datatype]"}}
        {default_value:text(inform),optional {label "[_ acs-object-management.attribute_default]"}}
    }
}

ad_form -extend -name attribute_form -form {} -new_request {
    set attribute_name ""
    set pretty_name ""
    set pretty_plural ""
    set datatype string
    set default_value ""
} -validate {
    {attribute_name 
        {([lsearch [db_list get_attributes {}] [string tolower $attribute_name]] == -1) ||
          ([string tolower $attribute_name] eq [db_string get_current_name {}])}
    "An attribute with the same name already exists. Attribute name must be unique"}
} -edit_request {
    db_1row attribute_data {}
} -on_submit {
    set default_locale [lang::system::site_wide_locale]
} -new_data {
    object_type::attribute::new \
	-attribute_name [string tolower $attribute_name] \
	-object_type $object_type \
	-datatype $datatype \
	-pretty_name $pretty_name \
	-pretty_plural $pretty_plural \
	-default_value $default_value \
        -create_column_p t
} -edit_data {
# Oh need to add an update function to the tcl API
    object_type::attribute::edit \
	-attribute_name [string tolower $attribute_name] \
	-object_type $object_type \
	-pretty_name $pretty_name \
	-pretty_plural $pretty_plural
} -after_submit {
    lang::message::register -update_sync $default_locale acs-translations "${object_type}_$attribute_name" $pretty_name
    lang::message::register -update_sync $default_locale acs-translations "${object_type}_${attribute_name}s" $pretty_plural

    ad_returnredirect [export_vars -base object-type {object_type}]
    ad_script_abort
}

ad_return_template
