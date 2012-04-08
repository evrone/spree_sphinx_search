Spree::Taxon.class_eval do

  def self.filters
    # All taxons with children
    where("(rgt-lft-1)/2 != 0")
  end

  def filter_options
    descendants
  end

end
