module Parsistence
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

      if method.to_s.include?("=")
        if relations.map {|r| "#{r}=".include?(method)}
          method = method.split("=")[0]
          return setRelation(method, args.first)
        elsif fields.map { |f| "#{f}=".include?(method)} 
          method = method.split("=")[0]
          return setField(method, args.first)
        elsif @PFObject.respond_to?(method)
          return @PFObject.send(method, *args, &block)
        else
          super
        end 
      elsif relations.include?(method)
        return getRelation(method)
      elsif fields.include?(method)
        return getField(method)
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
      raise "Parsistence Exception: Invalid field name #{field} for object #{self.class.to_s}"
    end

    def setField(field, value)
      return @PFObject.send("#{field}=", value) if RESERVED_KEYS.include?(field)
      return @PFObject[field] = value if fields.include? field.to_sym
      raise "Parsistence Exception: Invalid field name #{field} for object #{self.class.to_s}" unless fields.include? field.to_sym
    end

    def getRelation(field)
      return @PFObject.objectForKey(field) if relations.include? field.to_sym
      raise "Parsistence Exception: Invalid relation name #{field} for object #{self.class.to_s}"
    end

    def setRelation(field, value)
      value = value.PFObject if value.respond_to? :PFObject # unwrap object
      # return setRelation(field, value) # This SHOULD work
      
      relation = @PFObject.relationforKey(field)
      
      return relation.addObject(value) if relations.include? field.to_sym
      raise "Parsistence Exception: Invalid relation name #{field} for object #{self.class.to_s}" unless relations.include? relation.to_sym
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
        if v.respond_to?(:each) && !v.is_a?(PFObject)
          self.attributes = v
        elsif self.respond_to? "#{k}="
          self.send("#{k}=", v) 
        else
          setField(k, v) unless k.nil?
        end
      end
    end

    def save
      saved = false
      unless before_save == false
        self.attributes.each do |field, value|
          validateField field, value
        end

        if @errors && @errors.length > 0
          saved = false
        else
          saved = @PFObject.save
        end

        after_save if saved
      end
      saved
    end

    def before_save; end
    def after_save; end

    # Validations
    def presenceValidations
      self.class.send(:get_presence_validations)
    end

    def presenceValidationMessages
      self.class.send(:get_presence_validation_messages)
    end

    def validateField(field, value)
      @errors ||= {}
      if presenceValidations.include?(field) && value.nil? || value == ""
        messages = presenceValidationMessages
        if messages.include?(field) 
          @errors[field] = messages[field]
        else
          @errors[field] = "#{field} can't be blank" 
        end
      end
    end

    def errorForField(field)
      @errors[field] || false
    end

    def errors
      @errors || nil
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
        @relations ||= []
      end

      def validates_presence_of(field, opts={})
        @presenceValidationMessages ||= {}
        @presenceValidationMessages[field] = opts[:message] if opts[:message]
        validate_presence(field)
      end

      def get_presence_validations
        @presenceValidations ||= {}
      end
      
      def get_presence_validation_messages
        @presenceValidationMessages ||= {}
      end

      def validate_presence(field)
        @presenceValidations ||= []
        @presenceValidations << field
      end
    end
    
    def self.included(base)
      base.extend(ClassMethods)
    end

  end
end