require 'net/http'

module CuandoPasa::Proxy
  # Every query made to the proxy needs to be redirected to the real system,
  # but before doing that, the query has to be translated into a format the
  # system can understand. Similarly the system response has to be translated
  # too.
  #
  # This class handles the parts of this process that are common to every
  # query. The specifics are delegated.
  class Querier
    # In order to query the real system, a query object who respond to uri and
    # attributes is needed as well as a parser, who will transform the system's
    # response into a data structure that is easier to manipulate.
    def initialize(query, parser, session_cookie_provider = SessionCookie)
      @query = query
      @parser = parser
      @session_cookie_provider = session_cookie_provider
    end

    # Sends a request to the real system and parses the response.
    def execute
      res = Net::HTTP.start(@query.uri.hostname, @query.uri.port) do |http|
        req = Net::HTTP::Post.new(@query.uri)
        req['Cookie'] = @session_cookie_provider.current.value
        req['Content-Type'] = "application/json; charset=utf-8"
        req.body = build_body(@query.attributes)

        http.request(req)
      end
      # TODO: handle invalid responses
      @parser.parse(res.body)
    end

    private

    # Translate the query attributes into JSON which will be the request body.
    def build_body(attributes)
      "{" + attributes.map { |k, v| %Q("#{k}":"#{v}") }.join(",") + "}"
    end
  end
end
