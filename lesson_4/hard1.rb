class SecurityLogger
  def create_log_entry
    # ... implementation omitted ...
  end
end

class SecretFile
  def initialize(secret_data, security_logger)
    @data = secret_data
    @logger = security_logger
  end

  def data
    @logger.create_log_entry
    @data
  end
end

