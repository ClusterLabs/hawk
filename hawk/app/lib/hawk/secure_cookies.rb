module Hawk
  class SecureCookies

    COOKIE_SEPARATOR = "\n".freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)

      if headers['Set-Cookie'].present?
        cookies = headers['Set-Cookie'].split(COOKIE_SEPARATOR)

        # cookies might be 2-D array in the rack-3 / sprockets-4.2
        cookies.each do |cookie|
          next if cookie.blank?

          # no matter what, always add Secure + HttpOnly
          if not cookie.kind_of?(Array)
            cookie << '; Secure ; HttpOnly'
          else
            cookie.each do |cookie_atom|
              next if cookie_atom.blank?
              cookie_atom << '; Secure ; HttpOnly'
            end
          end
        end

        headers['Set-Cookie'] = cookies.join(COOKIE_SEPARATOR)
      end

      [status, headers, body]
    end

  end
end
