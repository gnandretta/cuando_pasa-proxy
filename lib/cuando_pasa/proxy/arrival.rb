require 'json'

module CuandoPasa::Proxy
  # Namespace for arrivals.
  module Arrival
    # Ask the next arrivals for a given stop. See Parser for the returned
    # information.
    def self.query(stop_id)
      Querier.new(Query.new(stop_id), Parser.new).execute
    end

    # This class is just a data structure with the information needed to ask
    # about the next arrivals.
    class Query
      attr_reader :uri, :attributes

      # Ask what are all the next arrivals for a given stop (for now at least).
      def initialize(stop_id)
        @uri = URI("http://cuandopasa.efibus.com.ar/default.aspx/RecuperarDatosDeParada")
        @attributes = { identificadorParada: stop_id }
      end
    end

    # This class translates the HTTP response body of the real system for the
    # arrivals into an array of maps which contain the line bus id and the
    # messasge with the waiting time:
    #   [
    #     { line_bus_id: "9C", message: "COLASTINE SUR CENTRO en 21 min. Aprox." }
    #     { line_bus_id: "9C", message: "COLAST NORTE CENTRO ARRIBANDO" }
    #     { line_bus_id: "16", message: "A CENTRO en 3 min. Aprox." }
    #   ]
    class Parser
      def parse(response_body)
        arrivals = JSON.parse(response_body).fetch("d").map do |arrival|
          line_bus_id, message = (arrival["datosMostrar"] || "").split("|").map(&:strip)
          { line_bus_id: line_bus_id, message: message }
        end # TODO: rescue KeyError.

        arrivals.reject do |arrival|
          arrival[:line_bus_id].nil? || arrival[:message].nil?
        end
      end
    end
  end
end
