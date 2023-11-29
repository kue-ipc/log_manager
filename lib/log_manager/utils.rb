# frozen_string_literal: true

require 'yaml'

require_relative 'error'

module LogManager
  module Utils
    module_function

    # Array#to_h ruby >= 2.1
    def array_to_hash(arr)
      return arr.to_h if arr.respond_to?(:to_h)

      arr.each_with_object({}) { |e, h| h[e[0]] = e[1] }
    end

    def hash_deep_merge(a, b, &block)
      a.merge(b) do |key, a_val, b_val|
        if a_val.is_a?(Hash) && b_val.is_a?(Hash)
          hash_deep_merge(a_val, b_val, &block)
        elsif block_given?
          block.call(key, a_val, b_val)
        else
          b_val
        end
      end
    end
  end
end
