# From https://gist.github.com/177780

class PerRequestCache #THIS IS TOTALLY NOT THREAD SAFE!!!!!!!

  class << self
    def open_the_cache
      @cache = {}
    end

    def clear_the_cache
      @cache = nil
    end

    def fetch(key, &block)
      return yield if @cache.nil?
      @cache[key] ||= yield
    end
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    self.class.open_the_cache
    @app.call(env)
  ensure
    self.class.clear_the_cache
  end
end

