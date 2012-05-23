module Spree::ThinkingSphinx
  module IndexHelper
    extend self

    def sql
      Sql
    end

    def indexed_taxons
      Spree::Taxon.where("(rgt-lft-1)/2 != 0")
    end

    # [{:name => :age_from, :type => :integer}]
    def indexed_options
      []
    end

    # Method should return array of hashes like [{:field => :created_at, :options => {:as => :recency}}]
    def indexed_properties
      []
    end

  end
end
