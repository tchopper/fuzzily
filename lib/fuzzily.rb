require "fuzzily/version"
require "fuzzily/searchable"
require "fuzzily/migration"
require "fuzzily/model"
require "active_record"
require 'fuzzystringmatch'


ActiveRecord::Base.send :include, Fuzzily::Searchable