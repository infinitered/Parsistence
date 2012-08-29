module ParseModel
  module Model
    module ClassMethods
      def query
        q = ParseModel::Query.new
        q.klass = self
      end

      def where(conditions = {}, &callback)
        q = query
        q.where(conditions, callback)
        q
      end
      def limit(offset, number = nil)
        q = ParseModel::Query.new
        q.limit(offset, number)
        q
      end
    end
  end

  class Query
    attr_accessor :klass

    def initialize
      @conditions = @negativeConditions = @ltConditions = @gtConditions = @lteConditions = @gteConditions = []
      @limit = @offset = nil
    end

    def fetch(&callback)
      query = PFQuery.queryWithClassName(self.klass.to_s)

      @conditions.each do |key, value|
        query.whereKey(key, equalTo: value)
      end
      @negativeConditions.each do |key, value|
        query.whereKey(key, notEqualTo: value)
      end
      @ltConditions.each do |key, value|
        query.whereKey(key, lessThan: value)
      end
      @gtConditions.each do |key, value|
        query.whereKey(key, greaterThan: value)
      end
      @lteConditions.each do |key, value|
        query.whereKey(key, lessThanOrEqualTo: value)
      end
      @gteConditions.each do |key, value|
        query.whereKey(key, greaterThanOrEqualTo: value)
      end
      first = true
      @order.each do |field, direction|
        if first
          query.orderByAscending(field) if direction && direction == :asc
          query.orderByDescending(field) if direction && direction == :desc
          first = false
        else
          query.addAscendingOrder(field) if direction && direction == :asc
          query.addDescendingOrder(field) if direction && direction == :desc
        end
      end

      query.limit = @limit if @limit
      query.skip = @offset if @offset

      if @limit == 1
        fetchOne(query, callback) 
      else
        fetchAll(query, callback)
      end
      
      self
    end

    def fetchAll(query, &callback)
      query.findObjectsInBackgroundWithBlock (lambda { |items, error|
        modelItems = items.map! { |item| self.klass.new(item) } if items
        callback.call modelItems, error
      })
    end

    def fetchOne(query, &callback)
      query.getFirstObjectInBackgroundWithBlock (lambda { |item, error|
        modelItem = self.klass.new(item) if item
        callback.call modelItem, error
      })
    end

    # Query methods
    def where(conditions = {}, &callback)
      conditions.each do |c, v|
        @conditions["#{c}"] = v
      end
      query(callback)
      self
    end

    def all(&callback)

      self
    end

    def first(&callback)

      self
    end

    # Query parameter methods

    def limit(offset, number = nil)
      if number.nil?
        number = offset
        offset = 0
      end
      @offset = offset
      @limit = number
      self
    end

    def order(fields)
      fields.each do |field, direction|
        @order["#{field}"] = direction
      end
      self
    end

    def eq(fields = {})
      fields.each do |field, value|
        @conditions["#{field}"] = value
      end
      self
    end

    def notEq(fields = {})
      fields.each do |field, value|
        @negativeConditions["#{field}"] = value
      end
      self
    end

    def lt(fields = {})
      fields.each do |field, value|
        @ltConditions["#{field}"] = value
      end
      self
    end

    def gt(fields = {})
      fields.each do |field, value|
        @gtConditions["#{field}"] = value
      end
      self
    end

    def lte(fields = {})
      fields.each do |field, value|
        @lteConditions["#{field}"] = value
      end
      self
    end

    def gte(fields = {})
      fields.each do |field, value|
        @gteConditions["#{field}"] = value
      end
      self
    end

  end
end