class Stoor::GithubAuth
  module Views
    class Unauthorized < Layout
      def self.template_file
        @template_file ||= File.join(File.dirname(__FILE__), 'unauthorized.mustache')
      end
    end
  end
end
