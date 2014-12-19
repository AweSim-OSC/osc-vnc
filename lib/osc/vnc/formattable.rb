module OSC
  module Formattable
    def to_string()
      <<-EOF.gsub /^\s+/, ''
        Host: #{host}
        Port: #{port}
        Pass: #{password}
        Display: #{display}
      EOF
    end
  end
end
