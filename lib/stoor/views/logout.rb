class Stoor::GithubAuth
  module Views
    class Logout < Layout
      def self.template_file
        @template_file ||= File.join(File.dirname(__FILE__), 'logout.mustache')
      end
    end
  end
end
