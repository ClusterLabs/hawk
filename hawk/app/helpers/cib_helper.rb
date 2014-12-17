module CibHelper
  def current_cib
    @current_cib ||= begin
      Cib.new(
        params[:cib_id] || 'live',
        current_user,
        params[:debug] == 'file'
      )
    end
  end
end
