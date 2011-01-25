require 'mustache'

module Contriburator
  module Views

    module Helpers
      def formatted_date(date, time = true, year = true)
        f_date = date.strftime("%d.%m.#{year ? '%Y' : ''}")
        f_date += " - <span class='time'>#{date.strftime('%H:%M')}</span>" if time
        f_date
      end

      def formatted_time(time)
        hours   = (time / 3600).to_i
        minutes = (time / 60 - hours * 60).to_i
        seconds = (time - (minutes * 60 + hours * 3600))

        "%02d:%02d:%02d" % [hours, minutes, seconds]
      end
    end # module Helpers

    class Home < Mustache

      include Views::Helpers

      self.template_file = Pathname(__FILE__).dirname.join('templates/home.html')

    end

  end # module Views
end # module Contriburator
