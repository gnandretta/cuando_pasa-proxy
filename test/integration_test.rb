require 'cuando_pasa/proxy'

module CuandoPasa::Proxy
  # TODO: Find out if there's a more idiomatic way to do this.
  DB.start("mongodb://localhost:27017/cuando_pasa-proxy-test")
  at_exit { DB.stop }

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

    def test_session_cookie_storage
      db = DB.get
      db.remove("session_cookies")
      assert_equal 0, db.all("session_cookies").to_a.size
      SessionCookie::Provider.new.provide
      assert_equal 1, db.all("session_cookies").to_a.size
      SessionCookie::Provider.new.provide
      assert_equal 1, db.all("session_cookies").to_a.size
    end

    def test_stop_storage
      Stop.update_db
      assert DB.get.all("stops").to_a.size > 0
    end
  end
end
