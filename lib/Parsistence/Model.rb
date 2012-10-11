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

      self
    end
    
    def method_missing(method, *args, &block)
      method = method.to_sym
      setter = false
      
      if method.to_s.include?("=")
        setter = true
        method = method.split("=")[0].to_sym
      end

      # Setters
      if RESERVED_KEYS.include?(method) && setter
        return self.PFObject.send("#{method}=", args)
      elsif relations.include?(method) && setter
        return setRelation(method, args.first)
      elsif fields.include?(method) && setter
        return setField(method, args.first)
      # Getters
      elsif RESERVED_KEYS.include?(method)
        return self.PFObject.send(method)
      elsif relations.include? method
        return getRelation(method)
      elsif fields.include? method
        return getField(method)
      elsif self.PFObject.respond_to?("#{method}=")
        return self.PFObject.send("#{method}=", *args, &block)
      elsif self.PFObject.respond_to?(method)
        return self.PFObject.send(method, *args, &block)
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
      if has_many.include?(field.to_sym)
        relation = @PFObject.objectForKey(field) if relations.include? field.to_sym
        # This is not implemented yet
        # return @relation[field] ||= begin
        #   r = Relation.new(relation)
        #   r.klass = self
        #   r.belongs_to = true
        #   r
        # end
        raise "Parsistence Exception: has_many relationships aren't implemented yet. Use a regular query instead."
      elsif belongs_to.include?(field.to_sym)
        return self.getField(field)
      else
        raise "Parsistence Exception: Invalid relation name #{field} for object #{self.class.to_s}"
      end
    end

    def setRelation(field, value)
      value = value.PFObject if value.respond_to? :PFObject # unwrap object
      if has_many.include?(field.to_sym)
        relation = @PFObject.relationforKey(field)
        return relation.addObject(value) if relations.include? field.to_sym
      elsif belongs_to.include?(field.to_sym)
        return setField(field, value)
      end
      
      raise "Parsistence Exception: Invalid relation name #{field} for object #{self.class.to_s}"
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
        self.validate

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

    def validate
      reset_errors
      self.attributes.each do |field, value|
        validateField field, value
      end
    end

    def is_valid?
      self.validate
      return false if @errors && @errors.length > 0
      true
    end

    def delete
      deleted = false
      unless before_delete == false
        deleted = @PFObject.delete
      end
      after_delete if deleted
      deleted
    end
    def before_delete; end
    def after_delete; end


    # Validations
    def presenceValidations
      self.class.send(:get_presence_validations)
    end

    def presenceValidationMessages
      self.class.send(:get_presence_validation_messages)
    end

    def has_many
      self.class.send(:get_has_many)
    end

    def belongs_to
      self.class.send(:get_belongs_to)
    end

    def validateField(field, value)
      @errors ||= {}
      if presenceValidations.include?(field) && (value.nil? || value == "")
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
      @errors
    end

    def valid?
      self.errors.nil? || self.errors.length == 0
    end

    def invalid?
      !self.valid?
    end

    def reset_errors
      @errors = nil
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
        @fields ||= []
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

      def has_many(field, args={})
        relation(field)

        @has_many ||= []
        @has_many << field
        @has_many.uniq!

        @has_many_attributes ||= {}
        @has_many_attributes[field] = args
      end

      def get_has_many
        @has_many ||= []
      end

      def belongs_to(field, args={})
        relation(field)

        @belongs_to ||= []
        @belongs_to << field
        @belongs_to.uniq!

        @belongs_to_attributes ||= {}
        @belongs_to_attributes[field] = args
      end

      def get_belongs_to
        @belongs_to ||= []
      end

      def get_belongs_to_attributes(field)
        @belongs_to_attributes[field] ||= { class_name: field }
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