module Parsistence
  module Model
    module ClassMethods
      QUERY_STUBS = [ :where, :first, :limit, :order, :eq, :notEq, :lt, :gt, :lte, :gte, :in ] # :limit is different

      def fetchAll(&block)
        q = Parsistence::Query.new
        q.klass = self
        return q.fetchAll &block
      end

      def fetchOne(&block)
        q = Parsistence::Query.new
        q.klass = self
        q.limit(1).fetchAll &block
      end

      def all(&block)
        fetchAll(&block)
      end

      def method_missing(method, *args, &block)
        if method == :limit && args.length == 2
          q = Parsistence::Query.new
          q.klass = self
          return q.send(method, args[0], args[1])
        elsif QUERY_STUBS.include? method.to_sym && args.length == 0
          q = Parsistence::Query.new
          q.klass = self
          return q.send(method, &block) if block_given?
          return q.send(method)
        elsif QUERY_STUBS.include? method.to_sym
          q = Parsistence::Query.new
          q.klass = self
          return q.send(method, args.first, &block) if block_given?
          return q.send(method, args.first)
        elsif method.start_with?("find_by_")
          # attribute = method.gsub("find_by_", "")
          # cond[attribute] = args.first
          # return self.limit(1).where(cond, block)
        elsif method.start_with?("find_all_by_")
          # attribute = method.gsub("find_all_by_", "")
          # cond[attribute] = args.first
          # return self.where(cond, block)
        else
        end
      end
    end
  end

  class Query
    attr_accessor :klass

    def initialize
      @conditions = {}
      @negativeConditions = {}
      @ltConditions = {}
      @gtConditions = {}
      @lteConditions = {}
      @gteConditions = {}
      @inConditions = {}
      @order = {}
      @limit = nil
      @offset = nil
      @includes = []
    end

    def checkKey(key)
      # TODO: Sanity check for mis-entered keys.
      # tmp = self.klass.new
      # $stderr.puts tmp
      # unless tmp.respond_to?(key.to_sym)
      #   $stderr.puts "Parsistence Warning: No field '#{key}' found for #{self.klass.to_s} query."
      # end
    end

    def createQuery
      query = PFQuery.queryWithClassName(self.klass.to_s)
      @includes.each do |include|
        query.includeKey(include)
      end
      
      @conditions.each do |key, value|
        checkKey key
        value = value.PFObject if value.respond_to?(:PFObject)
        query.whereKey(key, equalTo: value)
      end
      @inConditions.each do |key, value|
        checkKey key
        value = value.PFObject if value.respond_to?(:PFObject)
        query.whereKey(key, containedIn: value)
      end
      @negativeConditions.each do |key, value|
        checkKey key
        value = value.PFObject if value.respond_to?(:PFObject)
        query.whereKey(key, notEqualTo: value)
      end
      @ltConditions.each do |key, value|
        checkKey key
        value = value.PFObject if value.respond_to?(:PFObject)
        query.whereKey(key, lessThan: value)
      end
      @gtConditions.each do |key, value|
        checkKey key
        value = value.PFObject if value.respond_to?(:PFObject)
        query.whereKey(key, greaterThan: value)
      end
      @lteConditions.each do |key, value|
        checkKey key
        value = value.PFObject if value.respond_to?(:PFObject)
        query.whereKey(key, lessThanOrEqualTo: value)
      end
      @gteConditions.each do |key, value|
        checkKey key
        value = value.PFObject if value.respond_to?(:PFObject)
        query.whereKey(key, greaterThanOrEqualTo: value)
      end
      first = true
      @order.each do |field, direction|
        checkKey field
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

      query
    end

    def count(&callback)
      query = createQuery
      
      myKlass = self.klass
      query.countObjectsInBackgroundWithBlock (lambda { |item_count, error|
        callback.call item_count, error
      })
    end

    def fetch(&callback)
      if @limit && @limit == 1
        fetchOne(&callback) 
      else
        fetchAll(&callback)
      end
      
      self
    end

    def fetchAll(&callback)
      query = createQuery
      
      myKlass = self.klass
      query.findObjectsInBackgroundWithBlock (lambda { |items, error|
        modelItems = items.map! { |item| myKlass.new(item) } if items
        callback.call modelItems, error
      })
    end

    def fetchOne(&callback)
      limit(0, 1)
      query = createQuery
      
      myKlass = self.klass
      query.getFirstObjectInBackgroundWithBlock (lambda { |item, error|
        modelItem = myKlass.new(item) if item
        callback.call modelItem, error
      })
    end

    # Query methods
    def where(*conditions, &callback)
      eq(conditions.first)
      fetch(&callback)
      nil
    end

    def all(&callback)
      fetchAll(&callback)
      nil
    end

    def first(&callback)
      fetchOne(&callback)
      nil
    end
    
    def showQuery
      $stderr.puts "Conditions: #{@conditions.to_s}"
      $stderr.puts "negativeConditions: #{@negativeConditions.to_s}"
      $stderr.puts "ltConditions: #{@ltConditions.to_s}"
      $stderr.puts "gtConditions: #{@gtConditions.to_s}"
      $stderr.puts "lteConditions: #{@lteConditions.to_s}"
      $stderr.puts "gteConditions: #{@gteConditions.to_s}"
      $stderr.puts "inConditions: #{@inConditions.to_s}"
      $stderr.puts "order: #{@order.to_s}"
      $stderr.puts "limit: #{@limit.to_s}"
      $stderr.puts "offset: #{@offset.to_s}"
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

    def order(*fields)
      fields.each do |field|
        @order.merge! field
      end
      self
    end

    def eq(*fields)
      fields.each do |field|
        @conditions.merge! field
      end
      self
    end

    def notEq(*fields)
      fields.each do |field|
        @negativeConditions.merge! field
      end
      self
    end

    def lt(*fields)
      fields.each do |field|
        @ltConditions.merge! field
      end
      self
    end

    def gt(*fields)
      fields.each do |field|
        @gtConditions.merge! field
      end
      self
    end

    def in(*fields)
      fields.each do |field|
        @inConditions.merge! field
      end
      self
    end

    def lte(*fields)
      fields.each do |field|
        @lteConditions.merge! field
      end
      self
    end

    def gte(*fields)
      fields.each do |field|
        @gteConditions.merge! field
      end
      self
    end

    def includes(*fields)
      fields.each do |field|
        @includes << field
      end
      self
    end
  end
end