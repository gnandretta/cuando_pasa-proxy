require 'net/http'

module CuandoPasa::Proxy
  # A session cookie is needed in order to make requests to the "Cuando Pasa?"
  # service. We can't just obtain one an use it all the time because they
  # eventually expire.
  #
  # This class represents a session cookie and also provides a namespace for
  # the classes who are responsible for providing them (Provider#provide is the
  # entry point of that functionality).
  class SessionCookie
    attr_reader :value

    def initialize(attributes)
      @value = attributes.fetch(:value)
      @obtained_at = attributes.fetch(:obtained_at)
    end

    # Indicates if the session cookie should be used in a request.
    # NOTE: I didn't any research/validation about the expiration time of the
    # session cookies (five minutes just seems good enough).
    def current?
      @obtained_at > Time.now - 5 * 60
    end

    # This class is in charge for providing a current session cookie without
    # resorting to make a new request every time the session cookie is needed.
    # See #provide for more details.
    class Provider
      # In order to do it's job it needs two collaborators: a storage and a
      # obtainer. See Storage and Obtainer for more details.
      def initialize(collaborators = {})
        @storage = collaborators[:storage] || Storage.new
        @obtainer = collaborators[:obtainer] || Obtainer.new

        @session_cookie = @storage.current
      end

      # Returns the most recent stored session cookie provided it is still
      # current. Otherwise obtains, stores and returns a new one.
      def provide
        if @session_cookie.nil? || !@session_cookie.current?
          @session_cookie = @obtainer.obtain
          @storage.store(@session_cookie)
        end

        @session_cookie
      end
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
        SessionCookie.new(value: value, obtained_at: obtained_at)
      end
    end

    # This class is in charge for persisting the obtained session cookies and
    # retrieving it every time someone needs it.
    class Storage
      # Returns the most recent stored session cookie or nil (if no session
      # cookie was stored).
      def current
        # TODO: implement.
      end

      # Stores a new session cookie for later retrieval.
      def store(session_cookie)
        # TODO: implement.
      end
    end
  end
end
