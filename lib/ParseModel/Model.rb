module ParseModel
  module Model
    attr_accessor :PFObject, :errors
    
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
      elsif relations.include?(method)
        getRelation(method)
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

    def presenceValidations
      self.class.send(:get_presenceValidations)
    end

    def validateField(field, value)
      @errors ||= {}
      @errors[field] = "#{field} can't be blank" if presenceValidations.include?(field) && value.nil? || value == ""
    end

    def errorForField(field)
      @errors[field] || false
    end

    def getField(field)
      return @PFObject.objectForKey(field) if fields.include? field.to_sym
      raise "ParseModel Exception: Invalid field name #{field} for object #{self.class.to_s}"
    end

    def setField(field, value)
      return @PFObject.setObject(value, forKey:field) if fields.include? field.to_sym
      raise "ParseModel Exception: Invalid field name #{field} for object #{self.class.to_s}"
    end

    def getRelation(field)
      return @PFObject.objectForKey(field) if relations.include? field.to_sym
      raise "ParseModel Exception: Invalid relation name #{field} for object #{self.class.to_s}"
    end

    def setRelation(field, value)
      value = value.PFObject if value.respond_to? :PFObject # unwrap object
      
      relation = @PFObject.relationforKey(field)
      
      return relation.addObject(value) if relations.include? field.to_sym
      raise "ParseModel Exception: Invalid relation name #{field} for object #{self.class.to_s}"
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
      saved = false
      unless before_save == false
        #  should be presenceValidations.each ...
        self.attributes.each do |field, value|
          validateField field, value
        end
        saved = @PFObject.save
        after_save if saved
      end
      saved
    end

    def before_save; end
    def after_save; end

    module ClassMethods
      def fields(*args)
        args.each {|arg| field(arg)}
      end
    
      def field(name)
        @fields ||= [:objectId]
        @fields << name.to_sym
        @fields.uniq!
      end
      
      def get_fields
        @fields
      end



      def relations(*args)
        args.each { |arg| relation(arg)}
      end

      def relation(name)
        @relations ||= []
        @relations << name.to_sym
        @relations.uniq!
      end

      def get_relations
        @relations
      end

      def validates_presence_of(*args)
        args.each {|arg| validate_presence(arg)}
      end

      def get_presenceValidations
        @presenceValidations
      end

      def validate_presence(field)
        @presenceValidations ||= []
        @presenceValidations << field
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