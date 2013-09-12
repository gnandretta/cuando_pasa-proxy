module CuandoPasa::Proxy
  # Namespace for stops.
  module Stop
    # Updates the db with fresh stop information from the "Cuándo Pasa?"
    # system.
    def self.update_db(db = DB.get)
      # TODO: This is far from ideal, but we may get away with it.
      db.remove("stops")
      Obtainer.new.obtain.each { |stop| db.insert("stops", stop) }
    end

    # Finds in the database the stops who are near to the given location.
    def self.near(location, db = DB.get)
      db.near("stops", { "location" => location })
    end

    # This class is in charge for obtaining the data for all the stops from the
    # "Cuando Pasa?" service.
    class Obtainer
      # Each element of the array is also an array with the id (of the real
      # system) and the name of every bus line.
      #
      # I don't think that scraping them is reliable.
      BUS_LINES = [
                    ["9001", "1"],
                    ["1121", "2"],
                    ["10001", "3"],
                    ["26023", "4"],
                    ["77023", "5"],
                    ["19023", "5A"],
                    ["27023", "8"],
                    ["12001", "9"],
                    ["14001", "9C"],
                    ["53023", "10"],
                    ["2023", "11"],
                    ["28023", "13"],
                    ["29023", "14"],
                    ["13001", "15"],
                    ["30023", "16"],
                    ["31023", "18"],
                    ["34023", "Ronda B"]
                  ]

      # We can't just ask the "Cuándo Pasa?" system for all the stops. We need
      # to ask for the route, or set of stops, for every bus line, and then
      # consolidate that information.
      def obtain
        collection = Collection.new
        BUS_LINES.each do |bus_line_id, bus_line_name|
          Route.query(bus_line_id).each do |stop|
            collection.consolidate(bus_line_name, stop)
          end
        end
        collection.to_a
      end
    end

    # Builds a collection of stops from the stops for particular bus lines.
    # Create a new instance and start adding them with consolidate. When you
    # are done, obtain the stop collection with to_a.
    #
    # You'll need to create a new instance if you want to build another
    # collection.
    class Collection
      def initialize
        @collection = {}
      end

      # Given a stop for a given bus line, it will:
      #   - Add it to the collection when the stop hasn't been consolidated
      #     yet for any other bus line.
      #   - Add the bus line to the stop when the stop has already been
      #     consolidated for another bus line.
      #   - Complain when the stop when the stop has already been consolidated
      #     for another bus line but the new stop information doesn't match
      #     exactly with the old one.
      def consolidate(bus_line_name, stop)
        # TODO: Improve this implementation extracting some methods in order to
        # make it clear what the algorithm is doing. That being said, I want
        # all at the same level of abstraction without making it too hard to
        # understand what it's actually going on. If that is not possible, I
        # rather keep this.
        if @collection.has_key?(stop["number"])
          if stop == @collection[stop["number"]].reject { |k, v| k == "bus_lines" }
            unless @collection[stop["number"]]["bus_lines"].include?(bus_line_name)
              @collection[stop["number"]]["bus_lines"] << bus_line_name
            end
          else
            raise "inconsistent stop #{stop}"
          end
        else
          @collection[stop["number"]] = stop.merge("bus_lines" => [bus_line_name])
        end
      end

      # What we actually want is a list of the stops, regardless of the
      # convenient data structure used to build it.
      def to_a
        @collection.values
      end
    end
  end
end
