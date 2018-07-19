module VulnAttemptServlet

  def self.api_path
    '/api/v1/vuln-attempts'
  end

  def self.api_path_with_id
    "#{VulnAttemptServlet.api_path}/?:id?"
  end

  def self.registered(app)
    app.get VulnAttemptServlet.api_path_with_id, &get_vuln_attempt
    app.post VulnAttemptServlet.api_path, &report_vuln_attempt
  end

  #######
  private
  #######

  def self.get_vuln_attempt
    lambda {
      warden.authenticate!
      begin
        sanitized_params = sanitize_params(params)
        data = get_db.vuln_attempts(sanitized_params)
        set_json_data_response(response: data)
      rescue => e
        set_json_error_response(error: e, code: 500)
      end
    }
  end

  def self.report_vuln_attempt
    lambda {
      warden.authenticate!
      begin
        job = lambda { |opts|
          vuln_id = opts.delete(:vuln_id)
          wspace = opts.delete(:workspace)
          vuln = get_db.vulns(id: vuln_id, workspace: wspace).first
          get_db.report_vuln_attempt(vuln, opts)
        }
        exec_report_job(request, &job)
      rescue => e
        set_json_error_response(error: e, code: 500)
      end
    }
  end
end