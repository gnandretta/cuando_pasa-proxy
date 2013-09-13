require 'net/http'

module CuandoPasa::Proxy
  # A session cookie is needed in order to make requests to the "Cuando Pasa?"
  # service. We can't just obtain one an use it all the time because they
  # eventually expire.
  #
  # This class represents a session cookie and also provides a namespace for
  # the classes who are responsible for providing them. It has also two
  # shortcut methods (current and refresh) to perfrom the fundamental
  # operations of this module.
  class SessionCookie
    # Finds in the storage the most recent session cookie. Keep in mind that
    # the returned session cookie might not be really current (valid) and it
    # can even be nil.
    #
    # In order to prevent the previous scenarios, refresh must be called
    # periodically.
    def self.current
      Storage.new.current
    end

    # Obtains a new session cookie and stores it in the database to feed the
    # provider.
    def self.refresh
      Storage.new.store(Obtainer.new.obtain)
    end

    attr_reader :value

    def initialize(attributes)
      @value = attributes.fetch("value")
      @obtained_at = attributes.fetch("obtained_at")
    end

    # Indicates if the session cookie should be used in a request.
    # NOTE: I didn't any research/validation about the expiration time of the
    # session cookies (five minutes just seems good enough).
    def current?
      @obtained_at > Time.now - 5 * 60
    end

    def attributes
      { "value" => @value, "obtained_at" => @obtained_at }
    end

    # This class is in charge for obtaining a new (and current) session cookie
    # from the "Cuando Pasa?" service.
    class Obtainer
      # In order to obtain a new session cookie it makes a request and extracts
      # the set-cookie header.
      def obtain
        res = Net::HTTP.get_response(URI('http://cuandopasa.efibus.com.ar'))
        value = res.to_hash.fetch('set-cookie').first.split(";").first
        obtained_at = Time.now
        SessionCookie.new("value" => value, "obtained_at" => obtained_at)
      end
    end

    # This class is in charge for persisting the obtained session cookies and
    # retrieving them every time someone needs it.
    class Storage
      def initialize(db = DB.get)
        @db = db
      end

      # Returns the most recent stored session cookie or nil (if no session
      # cookie was stored).
      def current
        document = @db.max("session_cookies", "obtained_at")
        SessionCookie.new(document) unless document.nil?
      end

      # Stores a new session cookie for later retrieval.
      def store(session_cookie)
        @db.insert("session_cookies", session_cookie.attributes)
      end
    end
  end
end
