Spree::Taxon.class_eval do

  def self.filters
    roots
  end

  def filter_options
    descendants
  end

end
