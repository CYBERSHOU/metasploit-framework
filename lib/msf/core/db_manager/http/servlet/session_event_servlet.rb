module SessionEventServlet

  def self.api_path
    '/api/v1/session-events'
  end

  def self.api_path_with_id
    "#{SessionEventServlet.api_path}/?:id?"
  end

  def self.registered(app)
    app.get SessionEventServlet.api_path_with_id, &get_session_event
    app.post SessionEventServlet.api_path, &report_session_event
  end

  #######
  private
  #######

  def self.get_session_event
    lambda {
      warden.authenticate!
      begin
        sanitized_params = sanitize_params(params)
        data = get_db.session_events(sanitized_params)
        set_json_data_response(response: data)
      rescue => e
        set_json_error_response(error: e, code: 500)
      end
    }
  end

  def self.report_session_event
    lambda {
      warden.authenticate!
      begin
        job = lambda { |opts|
          get_db.report_session_event(opts)
        }
        exec_report_job(request, &job)
      rescue => e
        set_json_error_response(error: e, code: 500)
      end
    }
  end
end