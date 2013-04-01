class Redis
  class Store < self
    module Strategy
      module Json
        class Error < StandardError
        end

        class SerializationError < Redis::Store::Strategy::Json::Error
          def initialize(object)
            super "Cannot correctly serialize object: #{object.inspect}"
          end
        end

        private
          SERIALIZABLE = [String, TrueClass, FalseClass, NilClass, Numeric, Date, Time]
          MARSHAL_INDICATORS = ["\x04", "\004", "\u0004"]

          def _dump(object)
            object = _marshal(object)
            JSON.generate(object)
          end

          def _load(string)
            object =
              string.start_with?(*MARSHAL_INDICATORS) ? ::Marshal.load(string) : JSON.parse(string, :symbolize_names => true)
            _unmarshal(object)
          end

          def _marshal(object)
            case object
            when Hash
              object.each { |k,v| object[k] = _marshal(v) }
            when Array
              object.each_with_index { |v, i| object[i] = _marshal(v) }
            when String
              object = object.to_json_raw_object if object.encoding == Encoding::ASCII_8BIT
              object
            when *SERIALIZABLE
              object
            else
              raise SerializationError.new(object)
            end
          end

          def _unmarshal(object)
            case object
            when Hash
              object.each { |k,v| object[k] = _unmarshal(v) }
            when Array
              object.each_with_index { |v, i| object[i] = _unmarshal(v) }
            when String
              object.start_with?(*MARSHAL_INDICATORS) ? ::Marshal.load(object) : object
            else
              object
            end
          end
      end
    end
  end
end
