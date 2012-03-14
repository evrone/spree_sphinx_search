Spree::Product.class_eval do
  class_attribute :indexed_options, :indexed_properties
  self.indexed_options = []
  self.indexed_properties = []

  def self.sphinx_search_options &rules
    Spree::Search::ThinkingSphinx.send :define_method, :custom_options, rules
  end

  define_index do
    is_active_sql = "(spree_products.deleted_at IS NULL AND spree_products.available_on <= NOW() #{'AND (spree_products.count_on_hand > 0)' unless Spree::Config[:allow_backorders]} )"
    option_sql = lambda do |option_name|
      sql = <<-eos
        SELECT DISTINCT p.id, ov.id
        FROM spree_option_values AS ov
        LEFT JOIN spree_option_types AS ot ON (ov.option_type_id = ot.id)
        LEFT JOIN spree_option_values_variants AS ovv ON (ovv.option_value_id = ov.id)
        LEFT JOIN spree_variants AS v ON (ovv.variant_id = v.id)
        LEFT JOIN spree_products AS p ON (v.product_id = p.id)
        WHERE (ot.name = '#{option_name}' AND p.id>=$start AND p.id<=$end);
        #{source.to_sql_query_range}
      eos
      sql.gsub("\n", ' ').gsub('  ', '')
    end

    property_sql = lambda do |property_name|
      sql = <<-eos
          (SELECT spp.value
          FROM spree_product_properties AS spp
          INNER JOIN spree_properties AS sp ON sp.id = spp.property_id
          WHERE sp.name = '#{property_name}' AND spp.product_id = spree_products.id)
      eos
      sql.gsub("\n", ' ').gsub('  ', '')
    end

    indexes :name, :sortable => :insensitive
    indexes :description
    indexes :meta_description
    indexes :meta_keywords

    indexes taxons.name, :as => :taxon, :facet => true
    has taxons(:id), :as => :taxon_ids
    Spree::Taxon.filters.pluck(:id).each do |filter_id|
      has taxons(:id), :as => "#{filter_id}_taxon_ids"
    end

    has master(:price), :as => :price

    group_by "spree_products.deleted_at"
    group_by :available_on
    has is_active_sql, :as => :is_active, :type => :boolean
    source.model.indexed_properties.each do |prop|
      has property_sql.call(prop[:name].to_s), :as => :"#{prop[:name]}_property", :type => prop[:type]
    end
    source.model.indexed_options.each do |opt|
      has option_sql.call(opt.to_s), :as => :"#{opt}_option", :source => :ranged_query, :type => :multi, :facet => true
    end
  end
end
