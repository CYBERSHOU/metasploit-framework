module SessionServlet

  def self.api_path
    '/api/v1/sessions'
  end

  def self.api_path_with_id
    "#{SessionServlet.api_path}/?:id?"
  end

  def self.registered(app)
    app.get SessionServlet.api_path_with_id, &get_session
    app.post SessionServlet.api_path, &report_session
  end

  #######
  private
  #######

  def self.get_session
    lambda {
      warden.authenticate!
      begin
        sanitized_params = sanitize_params(params)
        data = get_db.sessions(sanitized_params)
        includes = [:host]
        set_json_data_response(response: data, includes: includes)
      rescue => e
        set_json_error_response(error: e, code: 500)
      end
    }
  end

  def self.report_session
    lambda {
      warden.authenticate!
      begin
        job = lambda { |opts|
          if opts[:session_data]
            get_db.report_session_dto(opts)
          else
            get_db.report_session_host_dto(opts)
          end
        }
        exec_report_job(request, &job)
      rescue => e
        set_json_error_response(error: e, code: 500)
      end
    }
  end

end
