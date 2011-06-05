
-- New tables to model object-based views.  Since view names must be unique in SQL
-- we force them to be unique in our datamodel, too (rather than only unique to the
-- object type). 

create table acs_views (
  object_view    text
                 constraint acs_views_object_view_pk
                 primary key,
  object_type    text
                 constraint acs_views_object_type_fk
                 references acs_object_types
                 on delete cascade,
  pretty_name    text
                 constraint acs_views_pretty_name_nn
                 not null,
  root_view_p    boolean default 'f'
                 constraint acs_views_root_view_p_nn
                 not null
);

comment on table acs_views is '
  Track information on object type-based views, including the initial view created for
  an object type
';

comment on column acs_views.object_view is '
  The name of the view.  The initial view for an object type is given the name
  "object_type_name_v".  If the object type the view references is deleted, the acs_view
  will be dropped, too.
';

comment on column acs_views.object_type is '
  The object type this view is built from.
';

comment on column acs_views.pretty_name is '
  Pretty name for this view
';

create table acs_view_attributes (
  attribute_id   integer
                 constraint acs_view_attributes_attribute_id_fk
                 references acs_attributes
                 on delete cascade,
  view_attribute       text,
  object_view    text
                 constraint acs_view_attributes_object_view_fk
                 references acs_views(object_view)
                 on delete cascade,
  pretty_name    text
                 constraint acs_views_pretty_name_nn
                 not null,
  sort_order     integer
                 constraint acs_views_sort_order
                 not null,
  col_expr       text
                 constraint acs_view_attributes_type_col_spec_nn
                 not null,
  constraint acs_view_attributes_pk primary key (object_view, attribute_id)
);

comment on table acs_view_attributes is '
  Track information on view attributes.  This extends the acs_attributes table with
  view-specific attribute information.  If the view or object type attribute referenced
  by the view attribute is deleted, the view attribute will be, too.
';

comment on column acs_view_attributes.attribute_id is '
  The acs_attributes row we are augmenting with view-specific information.  This is not
  used as the primary key because multiple views might use the same acs_attribute.
';

comment on column acs_view_attributes.view_attribute is '
  The name assigned to this column in the view.  Usually it is the acs_attribute name,
  but if multiple attributes have the same name, they are disambiguated with suffixes
  of the form _N.
';

comment on column acs_view_attributes.object_view is '
  The name of the view this attribute is being declared for.
';

comment on column acs_view_attributes.pretty_name is '
  The pretty name of the view.
';

comment on column acs_view_attributes.sort_order is '
  The order of display when shown to a user.  A bit odd to have it here, but
  the original object attributes have a sort_order defined, so for consistency we will
  do the same for view attributes.
';

comment on column acs_view_attributes.col_expr is '
  The expression used to build the column.  Usually just the acs_attribute name, but certain
  datatypes might call a function on the attribute value (i.e. "to_char()" for timestamp
  types).
';

select define_function_args('acs_view__drop_sql_view','object_view');

create or replace function acs_view__drop_sql_view (varchar)
returns integer as '
declare
  p_view                               alias for $1;  
begin
  if table_exists(p_view) then
    execute ''drop view '' || p_view;
  end if;
  return 0;
end;' language 'plpgsql';

select define_function_args('acs_view__create_sql_view','object_view');

create or replace function acs_view__create_sql_view (varchar)
returns integer as '
declare
  p_view                               alias for $1;  
  v_cols                               varchar; 
  v_tabs                               varchar; 
  v_joins                              varchar;
  v_first_p                            boolean;
  v_join_rec                           record;
  v_attr_rec                           record;
  v_tree_sortkey_found_p               boolean;
begin

  if length(p_view) > 64 then
    raise exception ''View name "%" cannot be longer than 64 characters.'',p_type;
  end if;

  if not exists (select 1
                 from acs_views
                 where object_view = p_view) then
    raise exception ''No object type named "%" exists'',p_view;
  end if;

  v_tabs := '''';
  v_joins := '''';
  v_first_p := ''t'';
  v_tree_sortkey_found_p := ''f'';
  v_cols := ''acs_objects.object_id as '' || p_view || ''_id'';

  for v_join_rec in select ot2.object_type, ot2.table_name, ot2.id_column,
                    tree_level(ot2.tree_sortkey) as level
                  from acs_object_types ot1, acs_object_types ot2, acs_views ov
                  where ov.object_view = p_view
                    and ot1.object_type = ov.object_type
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                  order by ot2.tree_sortkey desc
  loop
    if v_join_rec.table_name is not null and table_exists(v_join_rec.table_name) then

      if not v_tree_sortkey_found_p and column_exists(v_join_rec.table_name, ''tree_sortkey'') then
        v_cols := v_cols || '','' || v_join_rec.table_name || ''.tree_sortkey'';
        v_tree_sortkey_found_p := ''t'';
      end if;

      if not v_first_p then
        v_tabs := v_tabs || '', '';
      end if;
      v_tabs := v_tabs || v_join_rec.table_name;

      
      if v_join_rec.table_name <> ''acs_objects'' then
        if not v_first_p then
          v_joins := v_joins || '' and '';
        end if;
        v_joins := v_joins || '' acs_objects.object_id = '' || v_join_rec.table_name ||
                   ''.'' || v_join_rec.id_column;
      end if;

      v_first_p := ''f'';

    end if;
  end loop;

  for v_attr_rec in select view_attribute, col_expr
                    from acs_view_attributes
                    where object_view = p_view
                    order by sort_order
  loop
    v_cols := v_cols || '','' || v_attr_rec.col_expr || '' as '' || v_attr_rec.view_attribute;
  end loop;

  if v_joins <> '''' then
    v_joins := '' where '' || v_joins;
  end if;

  if table_exists(p_view) then
    execute ''drop view '' || p_view;
  end if;

  execute ''create or replace view '' || p_view || '' as select '' || 
    v_cols || '' from '' || v_tabs || v_joins;

  return 0; 
end;' language 'plpgsql';

-- Create the attributes select view for a type.  The view is given the type's table
-- name appended with "v".  The only id column returned is object_id, which avoids duplicate
-- column name issues.

select define_function_args('acs_object_type__refresh_view','object_type');

-- Need to create the view and view attribute metadata ...

create or replace function acs_object_type__refresh_view (varchar)
returns integer as '
declare
  p_type                               alias for $1;  
  v_attr_rec                           record;
  v_type_rec                           record;
  v_dupes                              integer;
  v_view_attribute                           text;
  v_col_expr                           text;
  v_sort_order                         integer;
  v_view                               text;
begin

  if not exists (select 1
                 from acs_object_types
                 where object_type = p_type) then
    raise exception ''No object type named "%" exists'',p_type;
  end if;

  v_view := replace(p_type, '':'', ''_'') || ''_v'';

  delete from acs_views where object_view = v_view;

  insert into acs_views
    (object_view, object_type, pretty_name, root_view_p)
  select v_view, p_type, pretty_name, ''t''
  from acs_object_types
  where object_type = p_type;

  v_sort_order := 1;

  for v_type_rec in select ot2.object_type, ot2.table_name, ot2.id_column,
                    tree_level(ot2.tree_sortkey) as level
                  from acs_object_types ot1, acs_object_types ot2
                  where ot1.object_type = p_type
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                  order by ot2.tree_sortkey desc
  loop

    for v_attr_rec in select a.attribute_name, d.column_output_function, a.attribute_id,
                        a.pretty_name
                      from acs_attributes a, acs_datatypes d
                      where a.object_type = v_type_rec.object_type
                        and a.storage = ''type_specific''
                        and a.table_name is null
                        and a.datatype = d.datatype
    loop

      v_view_attribute := v_attr_rec.attribute_name;
      v_col_expr := v_type_rec.table_name || ''.'' || v_view_attribute;

      if v_attr_rec.column_output_function is not null then
        execute ''select '' || v_attr_rec.column_output_function || ''('''''' || v_col_expr ||
                '''''')'' into v_col_expr;
      end if;

      -- The check for dupes could be rolled into the select above but it is far more
      -- readable when broken out, I think.

      v_dupes := count(*)
                 from acs_attributes
                 where attribute_name = v_attr_rec.attribute_name
                   and object_type in (select ot2.object_type
                                       from acs_object_types ot1, acs_object_types ot2
                                       where ot1.object_type = v_type_rec.object_type
                                         and ot1.tree_sortkey
                                           between tree_left(ot2.tree_sortkey)
                                           and tree_right(ot2.tree_sortkey));
       if v_dupes > 0 then
         v_view_attribute := v_view_attribute || ''_'' || substr(to_char(v_dupes, ''9''),2,1);
       end if;

       insert into acs_view_attributes
         (attribute_id, view_attribute, object_view, pretty_name, sort_order, col_expr)
       values
         (v_attr_rec.attribute_id, v_view_attribute, v_view, v_attr_rec.pretty_name, v_sort_order,
          v_col_expr);

       v_sort_order := v_sort_order + 1;

    end loop;
  end loop;

  perform acs_view__create_sql_view(replace(p_type, '':'', ''_'') || ''_v'');

  for v_type_rec in select object_type
                    from acs_object_types
                    where supertype = p_type
  loop
    perform acs_object_type__refresh_view(v_type_rec.object_type);
  end loop;

  return 0; 
end;' language 'plpgsql';

select acs_object_type__refresh_view('acs_object');

