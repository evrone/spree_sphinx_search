Spree::Product.class_eval do

  def self.extend_index &options
    self.class.send :define_method, :extended_index do
      lambda { |base| options.call(base) }
    end
  end
  extend_index { |_| }

  define_index do |base|
    index_helper = Spree::ThinkingSphinx::IndexHelper

    indexes :name, :sortable => :insensitive
    indexes :description
    indexes :meta_description
    indexes :meta_keywords
    indexes index_helper.sql.taxons('name'), :as => :taxon_names

    has master(:price), :as => :price
    has index_helper.sql.is_active, :as => :is_active, :type => :boolean
    has index_helper.sql.taxons('id'), :as => :taxon, :type => :multi, :source => :field, :all_ints => true, :facet => true

    index_helper.indexed_taxons.each do |taxon|
      has index_helper.sql.taxons('id', taxon), :as => "#{taxon.id}_taxon_ids", :type => :multi
    end

    index_helper.indexed_properties.each do |prop|
      has index_helper.sql.property(prop[:name].to_s), :as => :"#{prop[:name]}_property", :type => prop[:type]
    end

    index_helper.indexed_options.each do |opt|
      has index_helper.sql.option(opt.to_s, source), :as => :"#{opt}_option", :source => :ranged_query, :type => :multi, :facet => true
    end

    group_by "spree_products.deleted_at"
    group_by :available_on

    source.model.extended_index.call(base)
  end
end
