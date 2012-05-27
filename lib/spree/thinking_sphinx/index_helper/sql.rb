module Spree::ThinkingSphinx::IndexHelper
  module Sql
    extend self

    def option_sql option_name, context
      <<-sql
        SELECT DISTINCT p.id, ov.id
        FROM spree_option_values AS ov
        LEFT JOIN spree_option_types AS ot ON (ov.option_type_id = ot.id)
        LEFT JOIN spree_option_values_variants AS ovv ON (ovv.option_value_id = ov.id)
        LEFT JOIN spree_variants AS v ON (ovv.variant_id = v.id)
        LEFT JOIN spree_products AS p ON (v.product_id = p.id)
        WHERE (ot.name = '#{option_name}' AND p.id>=$start AND p.id<=$end);
        #{context.to_sql_query_range}
      sql
    end

    def property_sql property_name
      <<-sql
        (SELECT spp.value
        FROM spree_product_properties AS spp
        INNER JOIN spree_properties AS sp ON sp.id = spp.property_id
        WHERE sp.name = '#{property_name}' AND spp.product_id = spree_products.id)
      sql
    end

    # Query for whole product taxons branches from real product taxon to root
    def taxons_sql attribute, taxon=nil
      <<-sql
        (SELECT GROUP_CONCAT(ancestors.#{attribute})
          FROM spree_taxons AS taxons
          LEFT JOIN spree_products_taxons AS spt ON taxons.id = spt.taxon_id
          LEFT JOIN spree_taxons AS ancestors ON ancestors.lft <= taxons.lft AND ancestors.rgt >= taxons.rgt
          WHERE spt.product_id = spree_products.id)
      sql
    end

    def is_active_sql
      "(spree_products.deleted_at IS NULL AND spree_products.available_on <= NOW() #{'AND (spree_products.count_on_hand > 0)' unless Spree::Config[:allow_backorders]} )"
    end

    def method_missing method, *args, &block
      sql_method = "#{method}_sql"
      if respond_to? sql_method
        send(sql_method, *args).gsub("\n", ' ').gsub('  ', '')
      else
        super
      end
    end

  end
end
