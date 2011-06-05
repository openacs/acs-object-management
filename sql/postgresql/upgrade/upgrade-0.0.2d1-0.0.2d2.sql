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
