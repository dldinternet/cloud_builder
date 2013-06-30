require 'cloud_builder/reference'

module CloudBuilder
  class Resource
    include ExposesRefs
    def initialize(stack, name, &block)
      @stack   = stack
      @type       = nil
      @properties = {}
      @metadata = {}
      @block = block
      
      # add metadata describing the brick we were defined in
      if @block.binding.eval('@type')
        metadata do 
          brick_name @block.binding.eval('@type')
        end
      end
      
      instance_eval(&block)
    end
    
    def type(value)
      @type = value
    end
    
    def version(value)
      @version = value
    end
    
    def properties
      old_map = @current_map
      @current_map = @properties
      yield
      @current_map = old_map
    end
    
    def metadata
      old_map = @current_map
      @current_map = @metadata
      yield
      @current_map = old_map
    end
    
    def brick
      @block.binding.eval('brick')
    end

    def globals 
      @stack.globals
    end
    
    def tags(tag_map, propagate = nil)
      list = @current_map[TAGS] ||= []
      tag_map = Hash[tag_map.map { |key, value| [key.to_s, value] }]
      tag_map.keys.sort.each do |key|
        if propagate.nil?
          list << {KEY => DSL.format(key), VALUE => DSL.jsonize(tag_map[key])}
        else
          list << {KEY => DSL.format(key), VALUE => DSL.jsonize(tag_map[key]), PROPAGATE_AT_LAUNCH => propagate }
        end
      end
    end
    
    def to_json_data
      if @version
        {TYPE => @type, "Version" => @version, METADATA => @metadata, PROPERTIES => @properties}
      else
        {TYPE => @type, METADATA => @metadata, PROPERTIES => @properties}
      end
    end
    
    def method_missing(field, *params)
      if @stack.reference_type(field.to_s) == :map
        Reference::Map.new(field)
      else
        @current_map[DSL.format(field)] = DSL.jsonize(params.first)
      end
    end
  end
end
