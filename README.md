# About

ParseModel provides an Active Record pattern to your Parse models on RubyMotion.

## Usage

Create a model:

```ruby
class Post
  include ParseModel::Model

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

`ParseModel::Model` objects will `respond_to?` to all methods available to [`PFObject`](https://parse.com/docs/ios/api/Classes/PFObject.html) in the Parse iOS SDK. You can also access the `PFObject` instance directly with, you guessed it, `ParseModel::Model#PFObject`.

### Users

```ruby
class User
  include ParseModel::User
end

user = User.new
user.username = "adelevie"
user.email = "adelevie@gmail.com"
user.password = "foobar"
user.signUp

users = User.all # for more User query methods, see: https://parse.com/questions/why-does-querying-for-a-user-create-a-second-user-class 
users.map {|u| u.objectId}.include?(user.objectId) #=> true
```

`ParseModel::User` delegates to `PFUser` in a very similar fashion as `ParseModel::Model` delegates to `PFOBject`.

### Queries

Queries use a somewhat different pattern than ActiveRecord but are relatively familiar.

```ruby
Car.eq(license: "ABC-123", model: "Camry").gt(year: 2005, horsepower: 100).order(year: :desc, model: :asc).limit(0, 25).fetch do |cars, error|
  if cars
    cars.each do |car|
      # You have an instance of "Car" here. If you want to access the PFObject, just do `car.PFObject` like normal.
    end
  end
end
```

Chain multiple conditions together, even the same condition type multiple times, then run `fetch` to execute the query. Pass in a block with two fields to receive the data.

**Available Conditions:**
(note: each condition can take multiple comma-separated fields and values)

**eq:** Check if equal the passed in values.
**notEq:** Check if NOT equal to the passed in values.
**gt:** Check if greater than the passed in values.
**lt:** Check if less than the passed in values.
**gte:** Check if greater or equal to than the passed in values.
**lte:** Check if less than or equal to the passed in values.
**order:** Order by one or more fields. Specify :asc or :desc.
**limit:** Limit is slightly different...it takes either one argument (limit) or two (offset, limit).

```ruby
results.map! {|result| Post.new(result)}
```

### Relationships

Define your relationships in the Parse.com dashboard and also in your models.

```ruby
class Post
  include ParseModel::Model

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

Either `gem install ParseModel` then `require 'ParseModel'` in your `Rakefile`, OR

`gem "ParseModel"` in your Gemfile. ([Instructions for Bundler setup with Rubymotion)](http://thunderboltlabs.com/posts/using-bundler-with-rubymotion)

Somewhere in your code, such as `app/app_delegate.rb` set your API keys:

```ruby
Parse.setApplicationId("1234567890", clientKey:"abcdefghijk")
```

To install the Parse iOS SDK in your RubyMotion project, read [this](http://www.rubymotion.com/developer-center/guides/project-management/#_using_3rd_party_libraries) and  [this](http://stackoverflow.com/a/10453895/94154).

## License

See LICENSE.txt