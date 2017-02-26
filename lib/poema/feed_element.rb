module Poema
  class FeedElement
    attr_accessor :sort_value

    def initialize(wrapped)
      @wrapped = wrapped
    end

    def method_missing(name, *args)
      @wrapped.send(name, *args)
    end

    def wrapped
      @wrapped
    end

    def grouped_count
      grouped_elements.count
    end

    def grouped_elements
      @grouped_elements || []
    end

    def grouped_elements_trimmed(number)
      return grouped_elements if grouped_count <= number
      grouped_elements.reverse.slice(0, number-1).reverse
    end

    def grouped_elements=(element)
      @grouped_elements = [] if @grouped_elements.nil?
      @grouped_elements.push(element)
    end

    def sort_value
      @sort_value.nil? ? wrapped.created_at : @sort_value
    end
  end
end
