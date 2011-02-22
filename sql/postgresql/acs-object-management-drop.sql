drop table acs_view_attribute_widget_params;
drop table acs_view_attribute_widgets;
drop table acs_form_widget_params;
drop table acs_form_default_widgets;
drop table acs_form_widgets cascade;
drop table acs_view_attributes;
drop table acs_views;

drop sequence acs_form_widget_param_seq;

drop function acs_datatype__date_output_function(text);
drop function acs_datatype__timestamp_output_function(text);
drop function acs_view__drop_sql_view (varchar);
drop function acs_view__create_sql_view (varchar);
drop function acs_object_type__refresh_view (varchar);
