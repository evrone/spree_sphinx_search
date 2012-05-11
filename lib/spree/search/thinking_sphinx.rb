module Spree::Search
  class ThinkingSphinx < Spree::Core::Search::Base

    def suggest
      return @suggest unless @suggest.nil?
      if products && products.suggestion? && products.suggestion.present?
        @suggest = products.suggestion
      end
    end

    protected

    # method should return AR::Relations with conditions {:conditions=> "..."} for Product model
    def get_products_conditions_for(base_scope,query)
      search_options = thinking_sphinx_options

      products_ids = Spree::Product.search_for_ids(query, search_options)
      facets = products_ids.facets

      @properties[:products] = products_ids
      @properties[:facets] = correct_facets(facets, query, search_options)

      Spree::Product.where(:id => products_ids)
    end

    # Use sphinx even if keywords is blank
    def get_base_scope
      base_scope = super
      base_scope = get_products_conditions_for(base_scope, keywords) if keywords.blank?
      base_scope
    end

    def prepare(params)
      super
      @properties[:manage_pagination] = true
      @properties[:filters] = params[:filters]

      Spree::Product.indexed_properties.each do |prop|
        indexed_name = [prop[:name], '_property'].join.to_sym
        @properties[indexed_name] = params[indexed_name]
      end

      @properties[:price_from] = params[:price_from].presence.try(:to_f)
      @properties[:price_to] = params[:price_to].presence.try(:to_f)

      if params[:price_delta].present?
        @properties[:price_from] *= (1 - params[:price_delta].to_f) if @properties[:price_from].present?
        @properties[:price_to] *= (1 + params[:price_delta].to_f) if @properties[:price_to].present?
      end
    end

    private

    def thinking_sphinx_options
      search_options = {:page => page, :per_page => per_page}
      with_opts = {:is_active => 1}

      if order_by_price
        sort_mode = order_by_price == 'descend' ? :desc : :asc
        search_options.merge!(:order => :price, :sort_mode => sort_mode)
      end

      taxon_ids = taxon ? taxon.id : Spree::Taxon.roots.pluck(:id)
      with_opts.merge!(:taxon => taxon_ids)

      with_opts.merge!(prepare_nested_filters)

      if price_from.present? && price_to.present?
        with_opts.merge!(:price => price_from.to_f..price_to.to_f)
      end

      search_options.merge!(:with => with_opts)
    end

    # filters = {'183' => ['174'], '2' => ['144', '145']}
    def prepare_nested_filters
      return {} if filters.blank?
      @parsed_filters = {}

      taxon_filters = Spree::Taxon.filters.to_a
      taxon_filters |= [taxon] if taxon && taxon.has_descendants?

      taxon_filters.inject({}) do |with_opts, filter|
        if filters[filter.id.to_s].present?
          parsed_filter_group = parse_filters(filters[filter.id.to_s])
          @parsed_filters[filter.id] = parsed_filter_group
          with_opts["#{filter.id}_taxon_ids"] = parsed_filter_group if parsed_filter_group.present?
        end
        with_opts
      end
    end

    # 'Flattens' filters hash of nested taxons
    # { 2 => [152, 147], 152 => [153], 153 => [281, 305] }
    # with base = [152, 147] becomes [147, 281, 305]
    def parse_filters(base)
      with = Array.wrap(base.clone)
      with.count.times do
        with.map! do |node|
          filters[node] || node
        end.flatten!
      end
      # Ugly fix for bigints
      with.uniq.select {|f| f.to_i.between? 1, 2**32}
    end

    # corrects facets for taxons
    def correct_facets(facets, query, search_options)
      return facets unless @parsed_filters.present?

      result = facets.clone

      @parsed_filters.each do |filter_taxon_id, taxon_ids|
        if taxon_ids.any?(&:present?)
          new_search_options = search_options.clone.merge(:facets => [:taxon])
          new_search_options[:with] = search_options[:with].clone
          new_search_options[:with].delete("#{filter_taxon_id}_taxon_ids")
          new_facets = Spree::Product.facets(query, new_search_options)
          root_taxon = Spree::Taxon.find_by_id(filter_taxon_id)
          correct_facets_by_root_taxon(root_taxon, result[:taxon], new_facets[:taxon]) if root_taxon
        end
      end

      result
    end

    def correct_facets_by_root_taxon(root_taxon, old_taxon_hash, new_taxon_hash)
      taxon_ids = root_taxon.descendants.pluck(:id)
      taxon_ids.each do |taxon_id|
        old_taxon_hash[taxon_id] = new_taxon_hash[taxon_id] if new_taxon_hash[taxon_id].present?
      end
    end

  end
end
