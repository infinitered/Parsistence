# About

Parsistence provides an Active Record pattern to your Parse models on RubyMotion. 
It's an early fork from ParseModel but goes a different direction with its 
implementation

## Usage

Create a model:

```ruby
class Post
  include Parsistence::Model

  fields :title, :body, :author
end
```

Create an instance:

```ruby
p = Post.new
p.title = "Why RubyMotion Is Better Than Objective-C"
p.author = "Josh Symonds"
p.body = "trololol"
p.saveEventually
```

`Parsistence::Model` objects will `respond_to?` to all methods available to [`PFObject`](https://parse.com/docs/ios/api/Classes/PFObject.html) in the Parse iOS SDK. You can also access the `PFObject` instance directly with, you guessed it, `Parsistence::Model#PFObject`.

### Users

```ruby
class User
  include Parsistence::User
end

user = User.new
user.username = "adelevie"
user.email = "adelevie@gmail.com"
user.password = "foobar"
user.signUp

users = User.all
users.map {|u| u.objectId}.include?(user.objectId) #=> true
```

`Parsistence::User` delegates to `PFUser` in a very similar fashion as `Parsistence::Model` delegates to `PFOBject`. `Parsistence::User` includes `Parsistence::Model`, in fact.

### Queries

Queries use a somewhat different pattern than ActiveRecord but are relatively familiar. They are most like persistence.js.

```ruby
Car.eq(license: "ABC-123", model: "Camry").order(year: :desc).limit(25).fetch do |cars, error|
  if cars
    cars.each do |car|
      # `car` is an instance of your `Car` model here.
    end
  end
end
```

Chain multiple conditions together, even the same condition type multiple times, then run `fetch` to execute the query. Pass in a block with two fields to receive the data.

####Available Conditions
(note: each condition can take multiple comma-separated fields and values)

**eq:** Check if equal the passed in values.

**notEq:** Check if NOT equal to the passed in values.

**gt:** Check if greater than the passed in values.

**lt:** Check if less than the passed in values.

**gte:** Check if greater or equal to than the passed in values.

**lte:** Check if less than or equal to the passed in values.

**order:** Order by one or more fields. Specify :asc or :desc.

**limit:** Limit is slightly different...it takes either one argument (limit) or two (offset, limit).

### Relationships

Define your relationships in the Parse.com dashboard and also in your models.

```ruby
class Post
  include Parsistence::Model

  fields :title, :body, :author

  relations :author
end

Author.where(name: "Jamon Holmgren").fetchOne do |fetchedAuthor, error|
  p = Post.new
  p.title = "Awesome Readme"
  p.body = "Read this first!"
  p.author = fetchedAuthor
  p.save
end
```


## Installation

Either `gem install Parsistence` then `require 'Parsistence'` in your `Rakefile`, OR

`gem "Parsistence"` in your Gemfile. ([Instructions for Bundler setup with Rubymotion)](http://thunderboltlabs.com/posts/using-bundler-with-rubymotion)

Somewhere in your code, such as `app/app_delegate.rb` set your API keys:

```ruby
Parse.setApplicationId("1234567890", clientKey:"abcdefghijk")
```

To install the Parse iOS SDK in your RubyMotion project, read [this](http://www.rubymotion.com/developer-center/guides/project-management/#_using_3rd_party_libraries) and  [this](http://stackoverflow.com/a/10453895/94154).

## License

See LICENSE.txt