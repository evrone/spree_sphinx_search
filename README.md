Sphinx Search
=============

This gem extends beautiful [Spree](http://spreecommerce.com/) e-commerce platform with a power of the [Sphinx](http://sphinxsearch.com/) search engine via [Thinking Sphinx](http://pat.github.com/ts/en/).

### Installation

Install the latest available version of Sphinx. If you're working on Mac, it can be done with [homebrew](http://mxcl.github.com/homebrew/):

    brew install sphinx

Install [Aspell](http://aspell.net/) and at least one Aspell dictionary, which suits to a language you are using in your project.      

    Mac users:
      brew update
      brew install aspell --lang=en,ru

    Ubuntu:
      sudo apt-get install aspell libaspell-dev aspell-en

Include this gem to your Gemfile:

    gem 'spree_sphinx_search', github: 'evrone/spree-sphinx-search'

Copy config/sphinx.yml to RAILS_ROOT/config/sphinx.yml

### Usage

To perform the indexing:

    rake ts:index

To run Sphinx:

    rake ts:start
