class Stoor::GithubAuth
  module Views
    class Sorry < Layout
      def self.template_file
        @template_file ||= File.join(File.dirname(__FILE__), 'sorry.mustache')
      end
    end
  end
end
