module ParseModel
  module Model
    attr_accessor :PFObject, :errors
    
    RESERVED_KEYS = [:objectId]

    def initialize(pf=nil)
      if pf
        self.PFObject = pf
      else
        self.PFObject = PFObject.objectWithClassName(self.class.to_s)
      end

      # setupRelations unless pf

      self
    end

    # This code is to correct for a bug where relations aren't initialized when creating a new instance
    # def setupRelations
    #   relations.each do |r|
    #     self.send("#{r}=", @PFObject.relationforKey(r))
    #   end
    # end
    
    def method_missing(method, *args, &block)
      method = method.to_sym
      if fields.include?(method)
        return getField(method)
      elsif relations.include?(method)
        return getRelation(method)
      elsif relations.map {|r| "#{r}=".include?(method)}
        method = method.split("=")[0]
        return setRelation(method, args.first)
      elsif fields.map {|f| "#{f}="}.include?(method)
        method = method.split("=")[0]
        return setField(method, args.first)
      elsif @PFObject.respond_to?(method)
        return @PFObject.send(method, *args, &block)
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

    def getField(field)
      field = field.to_sym
      return @PFObject.send(field) if RESERVED_KEYS.include?(field)
      return @PFObject[field] if fields.include? field
      raise "ParseModel Exception: Invalid field name #{field} for object #{self.class.to_s}"
    end

    def setField(field, value)
      return @PFObject.send("#{field}=", value) if RESERVED_KEYS.include?(field)
      return @PFObject[field] = value if fields.include? field.to_sym
      raise "ParseModel Exception: Invalid field name #{field} for object #{self.class.to_s}"
    end

    def getRelation(field)
      return @PFObject.objectForKey(field) if relations.include? field.to_sym
      raise "ParseModel Exception: Invalid relation name #{field} for object #{self.class.to_s}"
    end

    def setRelation(field, value)
      value = value.PFObject if value.respond_to? :PFObject # unwrap object
      # return setField(field, value) # This SHOULD work
      
      relation = @PFObject.relationforKey(field)
      
      return relation.addObject(value) if relations.include? field.to_sym
      raise "ParseModel Exception: Invalid relation name #{field} for object #{self.class.to_s}"
    end

    def attributes
      attributes = {}
      fields.each do |f|
        attributes[f] = getField(f)
      end
      @attributes = attributes
    end

    def attributes=(hashValue)
      hashValue.each do |k, v|
        setField(k, v)
      end
    end

    def save
      saved = false
      unless before_save == false
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

    # Validations
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