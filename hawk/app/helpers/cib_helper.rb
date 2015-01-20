module CibHelper
  def production_cib
    'live'
  end

  def simulator_cib
    'hawk-hacluster'
  end

  def current_cib
    @current_cib ||= begin
      Cib.new(
        params[:cib_id] || production_cib,
        current_user,
        params[:debug] == 'file'
      )
    end
  end
end
