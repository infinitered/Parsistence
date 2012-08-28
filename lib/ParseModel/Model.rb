module ParseModel
  module Model
    attr_accessor :PFObject
    
    def initialize
      @PFObject = PFObject.objectWithClassName(self.class.to_s)
    end
    
    def method_missing(method, *args, &block)
      if fields.include?(method)
        @PFObject.objectForKey(method)
      elsif fields.map {|f| "#{f}="}.include?("#{method}")
        method = method.split("=")[0]
        @PFObject.setObject(args.first, forKey:method)
      elsif @PFObject.respond_to?(method)
        @PFObject.send(method, *args, &block)
      else
        super
      end
    end
        
    def fields
      self.class.send(:get_fields)
    end

    module ClassMethods
      # def new(pfobject = nil)
      #   instance = super.new
      #   instance.PFObject = pfobject if pfobject
      #   instance
      # end

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

      def where(conditions = {}, &callback)
        query = PFQuery.queryWithClassName(self.to_s)

        conditions.each do |key, value|
          query.whereKey(key, equalTo: value)
        end

        query.findObjectsInBackgroundWithBlock (lambda { |items, error|
          class_items = map_to_class(items)
          callback.call class_items, error
        })
      end

      def map_to_class(pf_items)
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
    end
    
    def self.included(base)
      base.extend(ClassMethods)
    end

  end
end