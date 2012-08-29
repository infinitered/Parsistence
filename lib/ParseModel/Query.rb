module ParseModel
  module Model
    module ClassMethods
      class Query
        def where(conditions = {}, &callback)
          query = PFQuery.queryWithClassName(self.to_s)

          conditions.each do |key, value|
            query.whereKey(key, equalTo: value)
          end

          query.findObjectsInBackgroundWithBlock (lambda { |items, error|
            class_items = items.map! { |item| self.new(item) }
            callback.call class_items, error
          })
        end
      end
    end
  end
end