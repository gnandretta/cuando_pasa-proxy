require 'cuando_pasa/proxy'

module CuandoPasa::Proxy
  class IntegrationTest < Test::Unit::TestCase
    def test_obtaining_a_session_cookie
      session_cookie = SessionCookie::Obtainer.new.obtain

      assert session_cookie.current?
      assert session_cookie.value =~ /^ASP\.NET_SessionId=\w+$/
    end
  end
end
