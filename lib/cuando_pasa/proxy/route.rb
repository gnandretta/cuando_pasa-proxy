module CuandoPasa::Proxy
  # Namespace for routes.
  module Route
    # Ask the route for a given bus line. A route is just a list of stops. See
    # Parser for the returned information.
    def self.query(bus_line_id)
      Querier.new(Query.new(bus_line_id), Parser.new).execute
    end

    # This class is just a data structure with the information needed to ask
    # about a bus line route.
    class Query
      attr_reader :uri, :attributes

      def initialize(bus_line_id)
        @uri = URI('http://cuandopasa.efibus.com.ar/Paginas/Paginas/Recorridos.aspx/RecuperarRecorrido')
        @attributes = { codigoLineaGrupo: bus_line_id }
      end
    end

    # This class translates the HTTP response body of the real system for the
    # route into an array of maps which contain the number of the stop, it's
    # description and it's location (that is an array with the x and y
    # coordianates):
    #   [
    #     {
    #        "number"      => "22273",
    #        "description" => "PLAZA DEL SOLDADO",
    #        "location"    => [-60.709097, -31.649335]
    #     }, {
    #        "number"      => "30273",
    #        "description" => "SAN JERONIMO Y CRESPO",
    #        "location"    => [-60.706675, -31.640832]
    #     }, # ...
    #   ]
    class Parser
      def parse(response_body)
        stops = JSON.parse(response_body).fetch("d").map do |stop_data|
          translate_stop_data(stop_data)
        end
        stops.keep_if { |stop| valid?(stop) }
      end

      private

      # Transforms the data returned by the query into something easier to
      # understand and manipulate.
      def translate_stop_data(stop_data)
        number = stop_data["identificadorParada"]
        description = stop_data["descripcionParada"] || ""
        long = (stop_data["longitudParada"] || "").tr(',', '.').to_f
        lat = (stop_data["latitudParada"] || "").tr(',', '.').to_f
        location = [long, lat]
        { "number" => number, "description" => description, "location" => location }          
      end

      # The query returns a lot of data that doesn't seem to be about stops.
      # This method is used to recognize and then separate them.
      def valid?(stop)
        # TODO: Perform a less strict check. Understand what is the query
        # actually returning.
        stop["number"] =~ /\d+/ &&
          !stop["description"].empty? &&
          stop["location"].none?(&:zero?)
      end
    end
  end
end
