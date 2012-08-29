module ParseModel
  module Model
    attr_accessor :PFObject
    
    RESERVED_KEYS = []

    def initialize
      @PFObject = PFObject.objectWithClassName(self.class.to_s)
    end
    
    def method_missing(method, *args, &block)
      if RESERVED_KEYS.include?(method)
        @PFObject.send(method)
      elsif RESERVED_KEYS.map {|f| "#{f}="}.include?("#{method}")
        @PFObject.send(method, args.first)
      elsif fields.include?(method)
        getField(method)
      elsif relations.map {|r| "#{r}=".include?("#{method}")}
        method = method.split("=")[0]
        setRelation(method, args.first)
      elsif fields.map {|f| "#{f}="}.include?("#{method}")
        method = method.split("=")[0]
        setField(method, args.first)
      elsif @PFObject.respond_to?(method)
        @PFObject.send(method, *args, &block)
      else
        super
      end
    end
    
    def fields
      self.class.send(:get_fields)
    end

    def relations
      self.class.send(:get_relations)
    end

    def presence_validations
      self.class.send(:get_presence_validations)
    end

    def getField(field)
      return @PFObject.objectForKey(field) if fields.include? field
      raise "Invalid field name #{field} for object #{self.class.to_s}"
    end

    def setField(field, value)
      return false if value.nil?
      return @PFObject.setObject(value, forKey:field) if fields.include? field
      raise "Invalid field name #{field} for object #{self.class.to_s}"
    end

    def setRelation(field, value)
      return false if value.nil? 
      value = value.PFObject if value.respond_to? :PFObject
      return @PFObject.setObject(value, forKey:field) # if relations.include? field # Not working same code as ^^
      raise "Invalid relation name #{field} for object #{self.class.to_s}"
    end

    def attributes
      return @attributes if @attributes
      
      @attributes = {}
      fields.each do |f|
        @attributes[f] = getField(f)
      end
      @attributes
    end

    def attributes=(hashValue)
      hashValue.each do |k, v|
        setField(k, v)
      end
    end

    def save
      # before_save

      #  should be presence_validations.each ...
      self.attributes.each do |field, value|
        raise "#{field} can't be nil" if presence_validations.include?(field) && value.nil? || value == ""
      end
      @PFObject.save
      # after_save
    end

    module ClassMethods
      def fields(*args)
        args.each {|arg| field(arg)}
      end
    
      def field(name)
        @fields ||= []
        @fields << name
      end
      
      def get_fields
        @fields
      end

      def relations(*args)
        args.each { |arg| relation(arg)}
      end

      def relation(name)
        @relations ||= []
        @relations << name
      end

      def get_relations
        @relations
      end

      def validates_presence_of(*args)
        args.each {|arg| validate_presence(arg)}
      end

      def get_presence_validations
        @presence_validations
      end

      def validate_presence(field)
        @presence_validations ||= []
        @presence_validations << field
      end

      def where(conditions = {}, &callback)
        query = PFQuery.queryWithClassName(self.to_s)

        conditions.each do |key, value|
          query.whereKey(key, equalTo: value)
        end

        query.findObjectsInBackgroundWithBlock (lambda { |items, error|
          class_items = classifyAll(items)
          callback.call class_items, error
        })
      end

      def classifyAll(pf_items)
        class_items = []
        pf_items.each do |item|
          class_items << self.classify(item)
        end
        class_items
      end

      def classify(item)
        i = self.new
        i.PFObject = item
        i
      end

      def method_missing(method, *args, &block)
        # TODO: Make this handle more than one "find_by" condition.
        if method.start_with?("find_by_")
          attribute = method.gsub("find_by_", "")
          conditions = {}
          conditions[attribute] = *args.first
          self.where(conditions, block)
        elsif method.start_with?("find_all_by_")
          attribute = method.gsub("find_all_by_", "")
          conditions = {}
          conditions[attribute] = *args.first
          self.where(conditions, block)
        else
          super
        end
      end
    end
    
    def self.included(base)
      base.extend(ClassMethods)
    end

  end
end