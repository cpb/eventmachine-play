require 'yajl'

module EventmachinePlay
  module YajlProtocol
    include EM::P::ObjectProtocol

    def serializer
      Yajl
    end
  end
end
