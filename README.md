# Fuzzily - fuzzy string matching for ActiveRecord

This version of fuzzily contains experimental extensions to the [original gem](https://github.com/mezis/fuzzily). Unless you seriously want some of the extensions - further described below - please use the original gem.

[![Gem Version](https://badge.fury.io/rb/fuzzily.png)](http://badge.fury.io/rb/fuzzily)
[![Build Status](https://travis-ci.org/mezis/fuzzily.png?branch=master)](https://travis-ci.org/mezis/fuzzily)
[![Dependency Status](https://gemnasium.com/mezis/fuzzily.png)](https://gemnasium.com/mezis/fuzzily)
[![Code Climate](https://codeclimate.com/github/mezis/fuzzily.png)](https://codeclimate.com/github/mezis/fuzzily)
[![Coverage Status](https://coveralls.io/repos/mezis/fuzzily/badge.png?branch=coveralls)](https://coveralls.io/r/mezis/fuzzily?branch=coveralls)

> Show me photos of **Marakech** !
>
> Here aresome photos of **Marrakesh**, Morroco.
> Did you mean **Martanesh**, Albania, **Marakkanam**, India, or **Marasheshty**, Romania?

Fuzzily finds misspelled, prefix, or partial needles in a haystack of
strings. It's a fast, [trigram](http://en.wikipedia.org/wiki/N-gram)-based, database-backed [fuzzy](http://en.wikipedia.org/wiki/Approximate_string_matching) string search/match engine for Rails.
Loosely inspired from an [old blog post](http://unirec.blogspot.co.uk/2007/12/live-fuzzy-search-using-n-grams-in.html).

Tested with ActiveRecord (2.3, 3.0, 3.1, 3.2, 4.0) on various Rubies (1.8.7, 1.9.2, 1.9.3, 2.0.0) and the most common adapters (SQLite3, MySQL, and PostgreSQL).

If your dateset is big, if you need yet more speed, or do not use ActiveRecord,
check out [blurrily](http://github.com/mezis/blurrily), another gem (backed with a C extension)
with the same intent.  


## Installation

Add this line to your application's Gemfile:

    gem 'fuzzily'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fuzzily

## Usage

You'll need to setup 2 things:

- a trigram model (your search index) and its migration
- the model you want to search for

Create and ActiveRecord model in your app (this will be used to store a "fuzzy index" of all the models and fields you will be indexing):

```ruby
class Trigram < ActiveRecord::Base
  include Fuzzily::Model
end
```

Create a migration for it:

```ruby
class AddTrigramsModel < ActiveRecord::Migration
  extend Fuzzily::Migration
end
```

Instrument your model:

```ruby
class MyStuff < ActiveRecord::Base
  # assuming my_stuffs has a 'name' attribute
  fuzzily_searchable :name
end
```

Index your model (will happen automatically for new/updated records):

```ruby
MyStuff.bulk_update_fuzzy_name
```

Search!

```ruby
MyStuff.find_by_fuzzy_name('Some Name', :limit => 10)
# => records
```

You can force an update on a specific record with

```ruby
MyStuff.find(123).update_fuzzy_name!
```

## Indexing more than one field

Just list all the field you want to index, or call `fuzzily_searchable` more than once: 

```ruby
class MyStuff < ActiveRecord::Base
  fuzzily_searchable :name_fr, :name_en
  fuzzily_searchable :name_de
end
```

## Custom name for the index model

If you want or need to name your index model differently (e.g. because you already have a class called `Trigram`):

```ruby
class CustomTrigram < ActiveRecord::Base
  include Fuzzily::Model
end

class AddTrigramsModel < ActiveRecord::Migration
  extend Fuzzily::Migration
  self.trigrams_table_name = :custom_trigrams
end

class MyStuff < ActiveRecord::Base
  fuzzily_searchable :name, :class_name => 'CustomTrigram'
end
```

## Speeding things up

For large data sets (millions of rows to index), the "compatible" storage
used by default will typically no longer be enough to keep the index small
enough.

Users have reported **major improvements** (2 order of magnitude) when turning
the `owner_type` and `fuzzy_field` columns of the `trigrams` table from
`VARCHAR` (the default) into `ENUM`. This is particularly efficient with
MySQL and pgSQL.

This is not the default in the gem as ActiveRecord does not suport `ENUM`
columns in any version.

## UUID's

When using Rails 4 with UUID's, you will need to change the `owner_id` column type to `UUID`.

```ruby
class AddTrigramsModel < ActiveRecord::Migration
  extend Fuzzily::Migration
  trigrams_owner_id_column_type = :uuid
end
```

## Model primary key (id) is VARCHAR

If you set your Model primary key (id) AS `VARCHAR` instead of `INT`, you will need to change the `owner_id` column type from `INT` to `VARCHAR` in the trigrams table.

## Searching virtual attributes

Your searchable fields do not have to be stored, they can be dynamic methods
too. Just remember to add a virtual change method as well.
For instance, if you model has `first_name` and `last_name` attributes, and you
want to index a compound `name` dynamic attribute: 

```ruby
class Employee < ActiveRecord::Base
  fuzzily_searchable :name
  def name
    "#{first_name} #{last_name}"
  end

  def name_changed?
    first_name_changed? || last_name_changed?
  end
end
```

## Limit the returned matches using the Jaro-Winkler distance

The basic trigram fuzzy search returns a list of the best trigram matches. You can set the number of returned matches using the :limit
parameter (defaults to 10). However it may very well be the case that some of the returned results, say number 9 and 10, have very
little ressemblance with the search pattern. We therefore add a set of distance filters that allow you to filter out any item whose
ressemblance with the pattern falls below a given threshold. For this we rely on the Jaro-Winkler distance, as implemented by the
fuzzy-string-match gem.

In order to allow best flexibility, the Jaro-Winkler distance threshold may be measured against one or several attributes of the
model, which do not have to be the same attribute as the one used for the trigram matching. A useful example to explain this is when
your (person/user) model has attributes 'firstname' and 'lastname' and you also have a virtual attribute 'name' which is the concatenation
of the other two. In your person/user model you could do:

```ruby
fuzzily_searchable :name
```

then to perform a search you could do:

```ruby
Person.find\_by\_fuzzy\_name("John Smith",
          {:distance_filter =>[["lastname", "Smith", 0.6], ["firstname", "John", 0.5]]})
```
In this case, the results returned would exclude any person where the Jaro-Winkler measure is below 0.6 for the lastname or 0.5 for
the firstname (The Jaro-Winkler measure is a floating point number between 0 and 1, where 0 means no match and 1 perfect match).

## Extensions provided compared to the original gem

This version of fuzzily contains experimental extensions to the [original gem](https://github.com/mezis/fuzzily). Unless you seriously want some of the extensions - further described below - please use the original gem.

- Branch mass\_assignment: Avoid problems related to mass-assignment (this feature is now merged into the original gem)
- Branch apply\_on\_scope: same as mass\_assignment + makes it possible to apply find\_by\_fuzzy on a relation/scope, like for example:
    Person.where('country = ?', "France").find_by_fuzzy_name(the_name, :limit => 20)
- Branch distance: same as apply\_on\_scope + limit the returned matches to those that satisfy aditing distance conditions, using the Jaro-Winkler distance algorithm. 
- Branch limit_by_distance: boolean. If true, the limit option (which defaults to 10) is not used, only the distance conditions. Default: false
- Branch master: all extensions



## License

MIT licence. Quite permissive if you ask me.

Copyright (c) 2013 HouseTrip Ltd.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


Thanks to @bclennox, @fdegiuli, @nickbender, @Shanison, @rickbutton for pointing out
and/or helping on various issues.
