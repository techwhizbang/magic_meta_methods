module ActiveRecord

  module MagicMetaMethods

    def self.included(base)
      base.extend(ClassMethods)
      class << base
        attr_accessor :meta_methods_column
        attr_accessor :meta_methods_declarations
      end
      base.send(:before_create, :init_meta_methods)
    end

    module ClassMethods
      def magic_meta_methods(methods=[], options={})
    
        column_name = options[:column].blank? ? :magic_meta_methods : options[:column].to_sym
        self.meta_methods_column = column_name
        self.meta_methods_declarations = methods
        self.meta_methods_declarations.each do |attribute|
          if attribute.is_a?(Array)
            name = attribute[0]
            type = attribute[1]
          else
            #default to string since its the most common usage
            name = attribute
            type = :string
          end

          serialize column_name
          define_method(name.to_sym) { self.get_meta_value(name, type)}
          define_method((name.to_s + '=').to_sym) {|val| self.set_meta_value(name, val, type)}
        end
      end
    end
    
    def init_meta_methods
      self[self.class.meta_methods_column] = {} unless self[self.class.meta_methods_column].kind_of?(Hash)
    end

    def set_meta_value(method_name, val, type)
      init_meta_methods #should never happen, but a failsafe
      self[self.class.meta_methods_column][method_name] = convert_to_type(val, type)
    end

    def get_meta_value(method_name, type)
      return nil unless self[self.class.meta_methods_column].kind_of?(Hash)
      convert_to_type(self[self.class.meta_methods_column][method_name], type)
    end

    def convert_to_type (val, type)
      return nil if val.nil? or (val.is_a?(String) and val.blank?)
      converted_value = nil
      case type
      when :string
        converted_value = val.to_s
      when :integer
        converted_value = val.to_i
      when :float
        converted_value = val.to_f
      when :date
        converted_value = val.is_a?(Date) ? val : Date.parse(val.to_s, true)
      when :time
        converted_value = val.is_a?(Time) ? val : Time.parse(val.to_s, true)
      when :datetime
        converted_value = val.is_a?(DateTime) ? val : DateTime.parse(val.to_s)
      when :indifferent_hash
        converted_value = val.is_a?(HashWithIndifferentAccess) ? val : (raise InvalidMetaTypeError.new("Invalid HashWithIndifferentAccess #{val}"))
      when :hash
        converted_value = val.is_a?(Hash) ? val : (raise InvalidMetaTypeError.new("Invalid Hash #{val}"))
      when :array
        converted_value = val.is_a?(Array) ? val : [val]
      when val.is_a?(type)
        converted_value = val
      else
        raise InvalidMetaTypeError.new("Invalid type #{type.name}")
      end
      converted_value
    end
  end
end

class InvalidMetaTypeError < ArgumentError; end

ActiveRecord::Base.send(:include, ActiveRecord::MagicMetaMethods)