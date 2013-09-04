require 'cuando_pasa/proxy'

module CuandoPasa::Proxy
  class IntegrationTest < Test::Unit::TestCase
    def test_obtaining_a_session_cookie
      session_cookie = SessionCookie::Obtainer.new.obtain

      assert session_cookie.current?
      assert session_cookie.value =~ /^ASP\.NET_SessionId=\w+$/
    end

    def test_querying_arrival
      arrivals = Arrival.query("35174")

      assert !arrivals.empty?
      assert arrivals.all? { |arrival|
        ["9C", "16"].include?(arrival[:line_bus_id]) &&
          arrival[:message] =~ /(\d min\. aprox\.|arribando)$/i
      }, "Invalid arrivals #{arrivals}"
    end
  end
end
